import Foundation

enum InventoryCategory: String, CaseIterable, Codable, Hashable {
    case produce
    case dairy
    case protein
    case grains
    case spices
    case beverages
    case frozen
    case canned
    case bakery
    case pantry
    case snacks
    case other

    var displayName: String {
        rawValue.capitalized
    }
}

struct PantryQuantity: Hashable {
    let value: Double
    let unit: String
}

struct PantryItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var quantityText: String
    var category: InventoryCategory
    var expiryDate: Date?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        quantityText: String = "",
        category: InventoryCategory = .pantry,
        expiryDate: Date? = nil,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.quantityText = quantityText
        self.category = category
        self.expiryDate = expiryDate
        self.updatedAt = updatedAt
    }

    var ingredient: Ingredient {
        Ingredient(name: name, quantity: quantityText)
    }

    var structuredQuantity: StructuredQuantity? {
        StructuredQuantity.parse(quantityText)
    }

    var parsedQuantity: PantryQuantity? {
        if let structuredQuantity {
            return PantryQuantity(value: structuredQuantity.amount, unit: structuredQuantity.unit.rawValue)
        }
        return Self.parseQuantity(quantityText)
    }

    func daysUntilExpiry(referenceDate: Date = .now) -> Int? {
        guard let expiryDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: referenceDate), to: Calendar.current.startOfDay(for: expiryDate)).day
    }

    var isExpiringSoon: Bool {
        guard let daysUntilExpiry else { return false }
        return (0...3).contains(daysUntilExpiry)
    }

    var isExpired: Bool {
        guard let daysUntilExpiry else { return false }
        return daysUntilExpiry < 0
    }

    private var daysUntilExpiry: Int? {
        daysUntilExpiry(referenceDate: .now)
    }

    func applyingConsumption(_ usedQuantityText: String) -> PantryConsumptionOutcome {
        let trimmedUsed = usedQuantityText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsed.isEmpty else {
            return .unchanged
        }

        guard let currentQuantity = parsedQuantity else {
            return .warning("Could not update \(name) automatically because its pantry quantity is not a numeric amount.")
        }

        guard let usedQuantity = Self.parseQuantity(trimmedUsed, fallbackUnit: currentQuantity.unit) else {
            return .warning("Could not update \(name) because the used amount '\(trimmedUsed)' could not be understood.")
        }

        guard currentQuantity.unit.caseInsensitiveCompare(usedQuantity.unit) == .orderedSame else {
            return .warning("Could not update \(name) because '\(trimmedUsed)' does not use the same unit as '\(quantityText)'.")
        }

        guard usedQuantity.value <= currentQuantity.value else {
            return .warning("Could not update \(name) because the used amount is greater than what is currently in pantry.")
        }

        let remaining = currentQuantity.value - usedQuantity.value
        if remaining <= 0.0001 {
            return .remove
        }

        var updated = self
        updated.quantityText = Self.formatQuantity(value: remaining, unit: currentQuantity.unit)
        updated.updatedAt = .now
        return .updated(updated)
    }

    static func parseQuantity(_ text: String, fallbackUnit: String? = nil) -> PantryQuantity? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let pattern = #"^\s*(\d+(?:\.\d+)?)\s*([A-Za-z]+(?:\s*[A-Za-z]+)?)?\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
        guard let match = regex.firstMatch(in: trimmed, options: [], range: range),
              match.numberOfRanges >= 2,
              let valueRange = Range(match.range(at: 1), in: trimmed),
              let value = Double(trimmed[valueRange])
        else {
            return nil
        }

        let unit: String
        if match.range(at: 2).location != NSNotFound,
           let unitRange = Range(match.range(at: 2), in: trimmed) {
            unit = trimmed[unitRange]
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
        } else if let fallbackUnit, !fallbackUnit.isEmpty {
            unit = fallbackUnit.lowercased()
        } else {
            unit = "count"
        }

        return PantryQuantity(value: value, unit: unit)
    }

    static func formatQuantity(value: Double, unit: String) -> String {
        let roundedValue = (value * 10).rounded() / 10
        let formattedNumber: String
        if roundedValue == floor(roundedValue) {
            formattedNumber = String(Int(roundedValue))
        } else {
            formattedNumber = String(format: "%.1f", roundedValue)
        }
        return "\(formattedNumber) \(unit)"
    }
}

enum PantryConsumptionOutcome {
    case unchanged
    case updated(PantryItem)
    case remove
    case warning(String)
}
