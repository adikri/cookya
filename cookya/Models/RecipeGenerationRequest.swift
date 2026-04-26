import Foundation

struct RecipeGenerationRequest: Hashable {
    var pantrySelections: [PantryRecipeSelection]
    var manualIngredients: [Ingredient]
    var difficulty: Difficulty
    var servings: Int
    var profile: UserProfile?
    var prioritizedIngredients: [PantryItem]
    var targetDish: String = ""
    // Not included in fingerprint — changes daily and should not bust the recipe cache
    var nutritionGap: NutritionGap?

    var pantryItems: [PantryItem] {
        pantrySelections.map(\.pantryItem)
    }

    var allIngredients: [Ingredient] {
        pantrySelections.map(\.ingredient) + manualIngredients
    }

    var normalizedFingerprint: String {
        let pantryPart = pantrySelections
            .map { selection in
                "\(selection.pantryItem.id.uuidString.lowercased())=\(Self.normalize(selection.selectedQuantityText))"
            }
            .sorted()
            .joined(separator: "|")

        let manualPart = manualIngredients
            .map { ingredient in
                "\(Self.normalize(ingredient.name))=\(Self.normalize(ingredient.quantity))"
            }
            .sorted()
            .joined(separator: "|")

        let prioritizedPart = prioritizedIngredients
            .map { $0.id.uuidString.lowercased() }
            .sorted()
            .joined(separator: "|")

        let profilePart = profile?.id.uuidString.lowercased() ?? "guest"

        let dishPart = Self.normalize(targetDish)

        return [
            "pantry:\(pantryPart)",
            "manual:\(manualPart)",
            "difficulty:\(difficulty.rawValue)",
            "servings:\(servings)",
            "profile:\(profilePart)",
            "priority:\(prioritizedPart)",
            "dish:\(dishPart)"
        ].joined(separator: ";")
    }

    private static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    static func == (lhs: RecipeGenerationRequest, rhs: RecipeGenerationRequest) -> Bool {
        lhs.normalizedFingerprint == rhs.normalizedFingerprint
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(normalizedFingerprint)
    }
}
