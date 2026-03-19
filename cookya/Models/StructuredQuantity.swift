import Foundation

enum QuantityUnit: String, CaseIterable, Codable, Hashable {
    case count
    case g
    case kg
    case ml
    case l
    case tsp
    case tbsp
    case cup
    case slice
    case loaf
    case piece
    case pack

    nonisolated var displayName: String { rawValue }

    nonisolated static func from(_ raw: String) -> QuantityUnit? {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "", "count", "counts":
            return .count
        case "g", "gram", "grams":
            return .g
        case "kg", "kilogram", "kilograms":
            return .kg
        case "ml", "milliliter", "milliliters":
            return .ml
        case "l", "liter", "liters":
            return .l
        case "tsp", "teaspoon", "teaspoons":
            return .tsp
        case "tbsp", "tablespoon", "tablespoons":
            return .tbsp
        case "cup", "cups":
            return .cup
        case "slice", "slices":
            return .slice
        case "loaf", "loaves":
            return .loaf
        case "piece", "pieces":
            return .piece
        case "pack", "packs", "packet", "packets":
            return .pack
        default:
            return nil
        }
    }
}

struct StructuredQuantity: Codable, Hashable {
    let amount: Double
    let unit: QuantityUnit

    nonisolated var displayText: String {
        "\(formattedAmount) \(unit.displayName)"
    }

    nonisolated var formattedAmount: String {
        if amount == floor(amount) {
            return String(Int(amount))
        }
        return String(format: "%.1f", amount)
    }

    nonisolated static func parse(_ text: String) -> StructuredQuantity? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let pattern = #"^\s*(\d+(?:\.\d+)?)\s*([A-Za-z]+(?:\s*[A-Za-z]+)?)?\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
        guard let match = regex.firstMatch(in: trimmed, options: [], range: range),
              let valueRange = Range(match.range(at: 1), in: trimmed),
              let amount = Double(trimmed[valueRange])
        else {
            return nil
        }

        let unitText: String
        if match.range(at: 2).location != NSNotFound,
           let unitRange = Range(match.range(at: 2), in: trimmed) {
            unitText = String(trimmed[unitRange])
        } else {
            unitText = "count"
        }

        guard let unit = QuantityUnit.from(unitText) else { return nil }
        return StructuredQuantity(amount: amount, unit: unit)
    }
}
