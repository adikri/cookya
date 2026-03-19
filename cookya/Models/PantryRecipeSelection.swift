import Foundation

struct PantryRecipeSelection: Identifiable, Codable, Hashable {
    let id: UUID
    let pantryItem: PantryItem
    var selectedQuantityText: String

    init(pantryItem: PantryItem, selectedQuantityText: String = "") {
        self.id = pantryItem.id
        self.pantryItem = pantryItem
        self.selectedQuantityText = selectedQuantityText
    }

    var ingredient: Ingredient {
        Ingredient(
            name: pantryItem.name,
            quantity: selectedQuantityText.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
