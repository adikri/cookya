import SwiftUI
import Combine

@MainActor
final class RecipeViewModel: ObservableObject {
    @Published var ingredientInput: String = ""
    @Published var ingredients: [Ingredient] = []
    @Published var selectedDifficulty: Difficulty = .easy
    @Published var isLoading: Bool = false
    @Published var generatedRecipe: Recipe?
    @Published var generationError: String?

    private let recipeService: RecipeGeneratingService

    init(recipeService: RecipeGeneratingService) {
        self.recipeService = recipeService
    }

    convenience init() {
        self.init(recipeService: OpenAIRecipeService())
    }

    func addIngredient() {
        let trimmed = ingredientInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let ingredient = Ingredient(name: trimmed)
        ingredients.append(ingredient)
        ingredientInput = ""
    }

    func removeIngredients(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }

    func generateRecipe() {
        guard !ingredients.isEmpty else {
            generationError = "Please add at least one ingredient."
            return
        }

        generationError = nil
        isLoading = true

        let currentIngredients = ingredients
        let difficulty = selectedDifficulty

        Task {
            do {
                let recipe = try await recipeService.generateRecipe(
                    ingredients: currentIngredients,
                    difficulty: difficulty
                )
                generatedRecipe = recipe
            } catch {
                generationError = mapErrorMessage(error)
            }

            isLoading = false
        }
    }

    private func mapErrorMessage(_ error: Error) -> String {
        if let recipeError = error as? RecipeGenerationError {
            return recipeError.errorDescription ?? "Recipe generation failed."
        }

        return "Recipe generation failed. Please try again."
    }
}
