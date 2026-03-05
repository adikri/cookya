import SwiftUI
import Combine

@MainActor
final class RecipeStore: ObservableObject {
    @Published private(set) var savedRecipes: [Recipe] = []

    func saveRecipe(_ recipe: Recipe) {
        guard !isSaved(recipe) else { return }
        savedRecipes.insert(recipe, at: 0)
    }

    func removeRecipes(at offsets: IndexSet) {
        savedRecipes.remove(atOffsets: offsets)
    }

    func isSaved(_ recipe: Recipe) -> Bool {
        savedRecipes.contains { $0.id == recipe.id }
    }
}
