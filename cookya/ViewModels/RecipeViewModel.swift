import SwiftUI
import Combine

@MainActor
final class RecipeViewModel: ObservableObject {
    @Published var ingredientInput: String = ""
    @Published var ingredients: [Ingredient] = []
    @Published var selectedPantryItemIDs: Set<UUID> = []
    @Published var selectedPantryQuantities: [UUID: String] = [:]
    @Published var selectedDifficulty: Difficulty = .easy
    @Published var servings: Int = 1
    @Published var isLoading: Bool = false
    @Published var generatedRecipe: Recipe?
    @Published var generatedPantrySelections: [PantryRecipeSelection] = []
    @Published var generatedRecipeCachedAt: Date?
    @Published var reopenedFromMemory: Bool = false
    @Published var shouldShowGeneratedRecipe: Bool = false
    @Published var generationError: String?

    private let recipeService: RecipeGeneratingService
    private let recipeStore: RecipeStore
    init(
        recipeService: RecipeGeneratingService,
        recipeStore: RecipeStore
    ) {
        self.recipeService = recipeService
        self.recipeStore = recipeStore
    }

    convenience init() {
        self.init(recipeService: BackendRecipeService(), recipeStore: .shared)
    }

    @discardableResult
    func addIngredient(named rawName: String? = nil) -> Bool {
        let trimmed = (rawName ?? ingredientInput).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let normalized = Self.normalizeIngredientName(trimmed)
        guard !ingredients.contains(where: { Self.normalizeIngredientName($0.name) == normalized }) else {
            ingredientInput = ""
            AppLogger.log("Manual ingredient duplicate ignored", metadata: ["ingredient": trimmed])
            return false
        }

        let ingredient = Ingredient(name: trimmed)
        ingredients.append(ingredient)
        ingredientInput = ""
        AppLogger.log("Manual ingredient added", metadata: ["ingredient": trimmed])
        return true
    }

    func addIngredient() {
        _ = addIngredient(named: ingredientInput)
    }

    func removeIngredients(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }

    func togglePantrySelection(for item: PantryItem) {
        if selectedPantryItemIDs.contains(item.id) {
            selectedPantryItemIDs.remove(item.id)
            selectedPantryQuantities[item.id] = nil
            AppLogger.log("Pantry item deselected", metadata: ["item": item.name, "quantity": item.quantityText])
        } else {
            selectedPantryItemIDs.insert(item.id)
            AppLogger.log("Pantry item selected", metadata: ["item": item.name, "quantity": item.quantityText])
        }
    }

    func isSelected(_ item: PantryItem) -> Bool {
        selectedPantryItemIDs.contains(item.id)
    }

    func bindingForSelectedQuantity(itemID: UUID) -> Binding<String> {
        Binding(
            get: { self.selectedPantryQuantities[itemID] ?? "" },
            set: { self.selectedPantryQuantities[itemID] = $0 }
        )
    }

    func generateRecipe(profile: UserProfile?, pantryItems: [PantryItem], nutritionGap: NutritionGap? = nil, forceRefresh: Bool = false) {
        let selectedPantrySelections = currentPantrySelections(from: pantryItems)
        let selectedPantryItems = selectedPantrySelections.map(\.pantryItem)

        guard !selectedPantryItems.isEmpty || !ingredients.isEmpty else {
            generationError = "Choose pantry items or add manual ingredients first."
            return
        }

        generationError = nil

        let request = currentRequest(profile: profile, pantrySelections: selectedPantrySelections, nutritionGap: nutritionGap)

        if !forceRefresh, let cachedRecipe = recipeStore.cachedGeneratedRecipe(for: request) {
            showGeneratedRecipe(
                cachedRecipe,
                pantrySelections: selectedPantrySelections,
                cachedAt: recipeStore.cachedGeneratedDate(for: request),
                reopenedFromMemory: true
            )
            AppLogger.log(
                "Reopened existing generated recipe",
                metadata: generationMetadata(
                    recipeTitle: cachedRecipe.title,
                    pantrySelections: selectedPantrySelections,
                    extra: ["requestMatch": "normalized_persistent_cache"]
                )
            )
            return
        }

        isLoading = true

        Task {
            if forceRefresh {
                AppLogger.log(
                    "Recipe regeneration requested",
                    metadata: generationMetadata(
                        pantrySelections: selectedPantrySelections,
                        profile: profile,
                        extra: ["cacheBypassed": "true"]
                    )
                )
            } else {
                AppLogger.log(
                    "Recipe generation requested",
                    metadata: generationMetadata(
                        pantrySelections: selectedPantrySelections,
                        profile: profile
                    )
                )
            }
            do {
                let recipe = try await recipeService.generateRecipe(request: request)
                recipeStore.cacheGeneratedRecipe(recipe, for: request)
                showGeneratedRecipe(
                    recipe,
                    pantrySelections: selectedPantrySelections,
                    cachedAt: recipeStore.cachedGeneratedDate(for: request),
                    reopenedFromMemory: false
                )
                AppLogger.log("Recipe generation succeeded", metadata: ["recipeTitle": recipe.title])
            } catch {
                generationError = mapErrorMessage(error)
                AppLogger.log("Recipe generation failed", metadata: ["error": mapErrorMessage(error)])
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

    private func currentPantrySelections(from pantryItems: [PantryItem]) -> [PantryRecipeSelection] {
        pantryItems
            .filter { selectedPantryItemIDs.contains($0.id) }
            .map {
                PantryRecipeSelection(
                    pantryItem: $0,
                    selectedQuantityText: selectedPantryQuantities[$0.id]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                )
            }
    }

    private func currentRequest(profile: UserProfile?, pantrySelections: [PantryRecipeSelection], nutritionGap: NutritionGap?) -> RecipeGenerationRequest {
        RecipeGenerationRequest(
            pantrySelections: pantrySelections,
            manualIngredients: ingredients,
            difficulty: selectedDifficulty,
            servings: servings,
            profile: profile,
            prioritizedIngredients: pantrySelections.map(\.pantryItem).filter(\.isExpiringSoon),
            nutritionGap: nutritionGap
        )
    }

    private func showGeneratedRecipe(
        _ recipe: Recipe,
        pantrySelections: [PantryRecipeSelection],
        cachedAt: Date?,
        reopenedFromMemory: Bool
    ) {
        generatedRecipe = recipe
        generatedPantrySelections = pantrySelections
        generatedRecipeCachedAt = cachedAt
        self.reopenedFromMemory = reopenedFromMemory
        shouldShowGeneratedRecipe = true
    }

    private func generationMetadata(
        recipeTitle: String? = nil,
        pantrySelections: [PantryRecipeSelection],
        profile: UserProfile? = nil,
        extra: [String: String] = [:]
    ) -> [String: String] {
        var metadata: [String: String] = [
            "difficulty": selectedDifficulty.rawValue,
            "servings": String(servings),
            "pantryItems": pantrySelections.map { "\($0.pantryItem.name)=\($0.selectedQuantityText)" }.joined(separator: ", "),
            "manualIngredients": ingredients.map(\.name).joined(separator: ", "),
            "profile": profile?.name ?? "Guest",
            "manualIngredientCount": String(ingredients.count),
            "pantryCount": String(pantrySelections.count)
        ]

        if let recipeTitle {
            metadata["recipeTitle"] = recipeTitle
        }

        for (key, value) in extra {
            metadata[key] = value
        }

        return metadata
    }

    nonisolated private static func normalizeIngredientName(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
