import Foundation

struct PantryConsumption: Identifiable, Codable, Hashable {
    let id: UUID
    let pantryItemId: UUID
    let pantryItemName: String
    let currentQuantityText: String
    var usedQuantityText: String

    init(item: PantryItem, usedQuantityText: String = "") {
        self.id = item.id
        self.pantryItemId = item.id
        self.pantryItemName = item.name
        self.currentQuantityText = item.quantityText
        self.usedQuantityText = usedQuantityText
    }
}
