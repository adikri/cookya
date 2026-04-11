import Foundation

enum KnownInventoryItemNormalizer {
    nonisolated static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

enum KnownItemSource: String, Codable, Hashable {
    case pantry
    case grocery
}

struct KnownInventoryItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var normalizedName: String
    var defaultCategory: InventoryCategory
    var lastQuantityText: String
    var lastSource: KnownItemSource
    var lastUsedAt: Date
    var usageCount: Int

    init(
        id: UUID = UUID(),
        name: String,
        defaultCategory: InventoryCategory,
        lastQuantityText: String,
        lastSource: KnownItemSource,
        lastUsedAt: Date = .now,
        usageCount: Int = 1
    ) {
        self.id = id
        self.name = name
        self.normalizedName = KnownInventoryItemNormalizer.normalize(name)
        self.defaultCategory = defaultCategory
        self.lastQuantityText = lastQuantityText
        self.lastSource = lastSource
        self.lastUsedAt = lastUsedAt
        self.usageCount = usageCount
    }
}
