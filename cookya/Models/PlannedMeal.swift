import Foundation

struct PlannedMeal: Identifiable, Codable, Hashable {
    let id: UUID
    let savedRecipeId: UUID
    let recipeTitle: String
    let addedAt: Date

    init(id: UUID = UUID(), savedRecipe: SavedRecipe) {
        self.id = id
        self.savedRecipeId = savedRecipe.id
        self.recipeTitle = savedRecipe.recipe.title
        self.addedAt = .now
    }
}
