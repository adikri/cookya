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
            try? await Task.sleep(nanoseconds: 700_000_000)
            let recipe = Self.buildMockRecipe(from: currentIngredients, difficulty: difficulty)
            generatedRecipe = recipe
            isLoading = false
        }
    }

    private static func buildMockRecipe(from ingredients: [Ingredient], difficulty: Difficulty) -> Recipe {
        let ingredientNames = ingredients.map { $0.name.lowercased() }
        let title = suggestedTitle(for: ingredientNames, difficulty: difficulty)

        let instructions = instructionsForDifficulty(difficulty, ingredientNames: ingredientNames)
        let estimatedCalories = estimateCalories(ingredientCount: ingredients.count, difficulty: difficulty)

        return Recipe(
            title: title,
            ingredients: ingredients,
            instructions: instructions,
            calories: estimatedCalories,
            difficulty: difficulty
        )
    }

    private static func suggestedTitle(for ingredientNames: [String], difficulty: Difficulty) -> String {
        let lead = ingredientNames.prefix(2).map { $0.capitalized }.joined(separator: " & ")
        let difficultyLabel = difficulty.rawValue.capitalized

        if lead.isEmpty {
            return "\(difficultyLabel) Home Recipe"
        }

        return "\(lead) \(difficultyLabel) Bowl"
    }

    private static func instructionsForDifficulty(_ difficulty: Difficulty, ingredientNames: [String]) -> [String] {
        let ingredientLine = ingredientNames.isEmpty
            ? "Prepare your ingredients."
            : "Wash and prep: \(ingredientNames.joined(separator: ", "))."

        switch difficulty {
        case .easy:
            return [
                ingredientLine,
                "Heat a pan with a little oil and saute onions or aromatics for 2 minutes.",
                "Add remaining ingredients, season with salt and pepper, and cook 10-12 minutes.",
                "Serve warm in a single bowl."
            ]
        case .medium:
            return [
                ingredientLine,
                "Build base flavors with oil, garlic, and spices for 4-5 minutes.",
                "Add ingredients in batches and cook covered for 20-25 minutes, stirring occasionally.",
                "Adjust seasoning and finish with herbs before serving."
            ]
        case .hard:
            return [
                ingredientLine,
                "Create a layered base with aromatics, spices, and a short reduction.",
                "Cook ingredients in stages, allowing each stage to develop texture and flavor.",
                "Simmer for 35-40 minutes, then plate with garnish for final presentation."
            ]
        }
    }

    private static func estimateCalories(ingredientCount: Int, difficulty: Difficulty) -> Int {
        let base = max(ingredientCount, 1) * 70

        switch difficulty {
        case .easy:
            return base + 80
        case .medium:
            return base + 140
        case .hard:
            return base + 220
        }
    }
}
