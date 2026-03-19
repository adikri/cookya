import Foundation

struct GroceryItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var quantityText: String
    var category: InventoryCategory
    var note: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        quantityText: String = "",
        category: InventoryCategory = .pantry,
        note: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.quantityText = quantityText
        self.category = category
        self.note = note
        self.createdAt = createdAt
    }

    var structuredQuantity: StructuredQuantity? {
        StructuredQuantity.parse(quantityText)
    }
}
