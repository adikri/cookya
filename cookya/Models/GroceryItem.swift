import Foundation

enum GroceryItemSource: String, Codable, Hashable {
    case manual
    case savedRecipe
    case cookedRecipe
    case extraIngredient

    var displayName: String {
        switch self {
        case .manual: return "Added manually"
        case .savedRecipe: return "Needed for saved recipe"
        case .cookedRecipe: return "Needed to cook again"
        case .extraIngredient: return "Tracked from recipe extra"
        }
    }
}

struct GroceryItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var quantityText: String
    var category: InventoryCategory
    var note: String?
    var source: GroceryItemSource
    var reasonRecipes: [String]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        quantityText: String = "",
        category: InventoryCategory = .pantry,
        note: String? = nil,
        source: GroceryItemSource = .manual,
        reasonRecipes: [String] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.quantityText = quantityText
        self.category = category
        self.note = note
        self.source = source
        self.reasonRecipes = reasonRecipes
        self.createdAt = createdAt
    }

    var structuredQuantity: StructuredQuantity? {
        StructuredQuantity.parse(quantityText)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case quantityText
        case category
        case note
        case source
        case reasonRecipes
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        quantityText = try container.decodeIfPresent(String.self, forKey: .quantityText) ?? ""
        category = try container.decodeIfPresent(InventoryCategory.self, forKey: .category) ?? .pantry
        note = try container.decodeIfPresent(String.self, forKey: .note)
        source = try container.decodeIfPresent(GroceryItemSource.self, forKey: .source) ?? .manual
        reasonRecipes = try container.decodeIfPresent([String].self, forKey: .reasonRecipes) ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
    }
}
