//
//  SavedRecipesView.swift
//  cookya
//
//  Created by adi on 05/03/26.
//

import SwiftUI

struct SavedRecipesView: View {
    @EnvironmentObject private var recipeStore: RecipeStore
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var inventoryStore: InventoryStore
    @EnvironmentObject private var cookedMealStore: CookedMealStore

    var body: some View {
        NavigationStack {
            Group {
                if filteredRecipes.isEmpty {
                    ContentUnavailableView(
                        "No Saved Recipes",
                        systemImage: "bookmark",
                        description: Text("Generate a recipe and save it for the current profile to find it here.")
                    )
                } else {
                    List {
                        Section {
                            ForEach(sortedRecipes) { saved in
                                NavigationLink {
                                    SavedRecipeDetailView(saved: saved)
                                } label: {
                                    SavedRecipeRow(
                                        saved: saved,
                                        readiness: readiness(for: saved)
                                    )
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    favoriteButton(for: saved)
                                }
                            }
                            .onDelete(perform: removeFilteredRecipes)
                        } header: {
                            Text(profileStore.activeProfile?.name ?? "Guest")
                        }
                    }
                }
            }
            .navigationTitle("Saved")
            .onAppear {
                AppLogger.screen("SavedRecipes", metadata: ["profile": profileStore.activeProfile?.name ?? "Guest", "count": String(filteredRecipes.count)])
            }
        }
    }

    private var filteredRecipes: [SavedRecipe] {
        recipeStore.recipes(for: profileStore.activeProfile)
    }

    private var sortedRecipes: [SavedRecipe] {
        filteredRecipes.sorted { lhs, rhs in
            if lhs.isFavorite != rhs.isFavorite {
                return lhs.isFavorite && !rhs.isFavorite
            }

            let leftReadiness = readiness(for: lhs)
            let rightReadiness = readiness(for: rhs)

            if leftReadiness.priority != rightReadiness.priority {
                return leftReadiness.priority < rightReadiness.priority
            }

            if leftReadiness.missingCount != rightReadiness.missingCount {
                return leftReadiness.missingCount < rightReadiness.missingCount
            }

            return lhs.savedAt > rhs.savedAt
        }
    }

    private func readiness(for saved: SavedRecipe) -> SavedRecipeReadiness {
        RecipePlanningState(
            recipe: saved.recipe,
            checks: inventoryStore.availabilityChecks(for: saved.recipe.ingredients)
        ).readiness
    }

    private func removeFilteredRecipes(at offsets: IndexSet) {
        let allRecipes = recipeStore.savedRecipes
        let filtered = sortedRecipes
        let mappedOffsets = IndexSet(offsets.compactMap { filteredIndex in
            let id = filtered[filteredIndex].id
            return allRecipes.firstIndex { $0.id == id }
        })
        recipeStore.removeRecipes(at: mappedOffsets)
    }

    @ViewBuilder
    private func favoriteButton(for saved: SavedRecipe) -> some View {
        Button(saved.isFavorite ? "Unfavorite" : "Favorite") {
            recipeStore.updateFavoriteState(for: saved.id, isFavorite: !saved.isFavorite)
            AppLogger.action(
                saved.isFavorite ? "saved_recipe_unfavorited" : "saved_recipe_favorited",
                screen: "SavedRecipes",
                metadata: ["recipeTitle": saved.recipe.title]
            )
        }
        .tint(.yellow)
    }
}

private struct SavedRecipeRow: View {
    let saved: SavedRecipe
    let readiness: SavedRecipeReadiness

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                HStack(spacing: 6) {
                    if saved.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                    }

                    Text(saved.recipe.title)
                        .font(.headline)
                }

                Spacer(minLength: 12)

                Text(readiness.label)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(readiness.badgeColor.opacity(0.12), in: Capsule())
                    .foregroundStyle(readiness.badgeColor)
            }

            Text(readiness.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("\(saved.recipe.difficulty.rawValue.capitalized) • \(saved.recipe.calories) kcal • \(saved.profileNameSnapshot)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private enum SavedRecipeReadiness {
    case readyNow(String)
    case missingItems(count: Int, summary: String)
    case needsReview(String)

    var priority: Int {
        switch self {
        case .readyNow:
            return 0
        case let .missingItems(count, _):
            return 1 + min(count, 8)
        case .needsReview:
            return 20
        }
    }

    var missingCount: Int {
        switch self {
        case .readyNow, .needsReview:
            return 0
        case let .missingItems(count, _):
            return count
        }
    }

    var label: String {
        switch self {
        case .readyNow:
            return "Ready Now"
        case let .missingItems(count, _):
            return count == 1 ? "Missing 1" : "Missing \(count)"
        case .needsReview:
            return "Review"
        }
    }

    var summary: String {
        switch self {
        case let .readyNow(summary), let .needsReview(summary):
            return summary
        case let .missingItems(_, summary):
            return summary
        }
    }

    var badgeColor: Color {
        switch self {
        case .readyNow:
            return .green
        case .missingItems:
            return .orange
        case .needsReview:
            return .red
        }
    }
}

private struct SavedRecipeDetailView: View {
    @EnvironmentObject private var recipeStore: RecipeStore
    @EnvironmentObject private var inventoryStore: InventoryStore
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var cookedMealStore: CookedMealStore

    let saved: SavedRecipe

    @State private var isShowingCompletionSheet = false
    @State private var completionMessage: String?

    private var isFavorite: Bool {
        recipeStore.savedRecipes.first(where: { $0.id == saved.id })?.isFavorite ?? saved.isFavorite
    }

    var body: some View {
        RecipePlanningView(
            recipe: saved.recipe,
            headerFootnote: "Saved on \(saved.savedAt.formatted(date: .abbreviated, time: .shortened))",
            primaryReadyActionTitle: "Cook This",
            onCook: {
                AppLogger.action(
                    "saved_recipe_cook_again_tapped",
                    screen: "SavedRecipeDetail",
                    metadata: ["recipeTitle": saved.recipe.title, "result": "available"]
                )
                isShowingCompletionSheet = true
            },
            onAddMissingToGrocery: addMissingItemsToGrocery
        )
        .navigationTitle("Saved Recipe")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    recipeStore.updateFavoriteState(for: saved.id, isFavorite: !isFavorite)
                    AppLogger.action(
                        isFavorite ? "saved_recipe_unfavorited" : "saved_recipe_favorited",
                        screen: "SavedRecipeDetail",
                        metadata: ["recipeTitle": saved.recipe.title]
                    )
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundStyle(isFavorite ? Color.yellow : Color.primary)
                }
            }
        }
        .onAppear {
            AppLogger.screen("SavedRecipeDetail", metadata: ["recipeTitle": saved.recipe.title])
        }
        .sheet(isPresented: $isShowingCompletionSheet) {
            RecipeCompletionView(pantrySelections: replaySelections) { consumptions in
                Task {
                    let result = await inventoryStore.consumePantryItems(consumptions)
                    let warnings = result.warnings
                    guard result.applied else {
                        completionMessage = warnings.joined(separator: "\n")
                        AppLogger.action(
                            "saved_recipe_marked_cooked_blocked",
                            screen: "SavedRecipeDetail",
                            metadata: [
                                "recipeTitle": saved.recipe.title,
                                "warningCount": String(warnings.count)
                            ]
                        )
                        return
                    }
                    cookedMealStore.addRecord(
                        recipe: saved.recipe,
                        consumptions: consumptions,
                        warnings: warnings,
                        profile: profileStore.activeProfile
                    )
                    AppLogger.action(
                        "saved_recipe_marked_cooked",
                        screen: "SavedRecipeDetail",
                        metadata: [
                            "recipeTitle": saved.recipe.title,
                            "warningCount": String(warnings.count)
                        ]
                    )
                    if warnings.isEmpty {
                        completionMessage = "Pantry updated from what you cooked."
                    } else {
                        completionMessage = warnings.joined(separator: "\n")
                    }
                }
            }
        }
        .alert("Cooking Update", isPresented: Binding(
            get: { completionMessage != nil },
            set: { if !$0 { completionMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(completionMessage ?? "")
        }
    }

    private var availabilityChecks: [PantryAvailabilityCheck] {
        inventoryStore.availabilityChecks(for: saved.recipe.ingredients)
    }

    private var replaySelections: [PantryRecipeSelection] {
        inventoryStore.replaySelections(for: saved.recipe.ingredients)
    }

    private var missingIngredients: [Ingredient] {
        zip(saved.recipe.ingredients, availabilityChecks)
            .compactMap { ingredient, check in
                check.isMissing ? ingredient : nil
            }
    }

    private func addMissingItemsToGrocery() {
        Task {
            for ingredient in missingIngredients {
                await inventoryStore.saveGroceryItem(
                    GroceryItem(
                        name: ingredient.name,
                        quantityText: ingredient.quantity,
                        category: .pantry,
                        source: .savedRecipe,
                        reasonRecipes: [saved.recipe.title],
                        createdAt: .now
                    )
                )
            }

            AppLogger.action(
                "saved_recipe_missing_items_added_to_grocery",
                screen: "SavedRecipeDetail",
                metadata: [
                    "recipeTitle": saved.recipe.title,
                    "count": String(missingIngredients.count)
                ]
            )
            completionMessage = "Missing items were added to Grocery."
        }
    }
}

private struct RecipePlanningView: View {
    @EnvironmentObject private var inventoryStore: InventoryStore

    let recipe: Recipe
    let headerFootnote: String?
    let primaryReadyActionTitle: String
    let onCook: () -> Void
    let onAddMissingToGrocery: () -> Void

    private var planningState: RecipePlanningState {
        RecipePlanningState(
            recipe: recipe,
            checks: inventoryStore.availabilityChecks(for: recipe.ingredients)
        )
    }

    var body: some View {
        List {
            Section {
                Text(recipe.title)
                    .font(.headline)
                Text("\(recipe.difficulty.rawValue.capitalized) • \(recipe.calories) kcal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let headerFootnote, !headerFootnote.isEmpty {
                    Text(headerFootnote)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Recipe")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(planningState.readiness.label)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(planningState.readiness.badgeColor.opacity(0.12), in: Capsule())
                            .foregroundStyle(planningState.readiness.badgeColor)
                        Spacer()
                    }

                    Text(planningState.readiness.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if planningState.hasReviewIssues {
                        Text("Some ingredients exist in pantry, but the stored quantity or unit needs review before the app can trust the recipe is ready.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Readiness")
            }

            if !planningState.availableIngredients.isEmpty {
                Section {
                    ForEach(planningState.availableIngredients) { ingredient in
                        RecipePlanningIngredientRow(ingredient: ingredient, tint: .green)
                    }
                } header: {
                    Text("Available")
                }
            }

            if !planningState.missingIngredients.isEmpty {
                Section {
                    ForEach(planningState.missingIngredients) { ingredient in
                        RecipePlanningIngredientRow(ingredient: ingredient, tint: .orange)
                    }
                } header: {
                    Text("Missing")
                }
            }

            if !planningState.reviewIngredients.isEmpty {
                Section {
                    ForEach(planningState.reviewIngredients) { ingredient in
                        VStack(alignment: .leading, spacing: 4) {
                            RecipePlanningIngredientRow(ingredient: ingredient.ingredient, tint: .red)
                            Text(ingredient.issue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Needs Review")
                }
            }

            Section {
                if planningState.isReadyToCook {
                    Button(primaryReadyActionTitle, action: onCook)
                        .frame(maxWidth: .infinity)
                } else if !planningState.missingIngredients.isEmpty {
                    Button("Add Missing Items to Grocery", action: onAddMissingToGrocery)
                        .frame(maxWidth: .infinity)
                }
            } footer: {
                if !planningState.missingIngredients.isEmpty {
                    Text("Only ingredients that are completely missing from pantry are added to Grocery.")
                }
            }

            Section {
                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, step in
                    Text("\(index + 1). \(step)")
                        .fixedSize(horizontal: false, vertical: true)
                }
            } header: {
                Text("Instructions")
            }
        }
    }
}

private struct RecipePlanningIngredientRow: View {
    let ingredient: Ingredient
    let tint: Color

    var body: some View {
        Text(ingredient.quantity.isEmpty ? ingredient.name : "\(ingredient.name) (\(ingredient.quantity))")
            .foregroundStyle(tint)
    }
}

private struct RecipePlanningReviewIngredient: Identifiable {
    let ingredient: Ingredient
    let issue: String

    var id: UUID { ingredient.id }
}

private struct RecipePlanningState {
    let recipe: Recipe
    let checks: [PantryAvailabilityCheck]

    var readiness: SavedRecipeReadiness {
        guard !checks.isEmpty else {
            return .needsReview("Needs pantry review")
        }

        let issues = checks.compactMap(\.issue)
        if issues.isEmpty {
            return .readyNow("Everything needed is in pantry")
        }

        let missingChecks = checks.filter(\.isMissing)
        if !missingChecks.isEmpty {
            let missingCount = missingChecks.count
            if missingCount == 1, let first = missingChecks.first {
                return .missingItems(
                    count: missingCount,
                    summary: "Missing 1 item: \(first.itemName)"
                )
            }

            return .missingItems(
                count: missingCount,
                summary: "Missing \(missingCount) items"
            )
        }

        return .needsReview("Needs pantry review")
    }

    var availableIngredients: [Ingredient] {
        zip(recipe.ingredients, checks)
            .compactMap { ingredient, check in
                check.issue == nil ? ingredient : nil
            }
    }

    var missingIngredients: [Ingredient] {
        zip(recipe.ingredients, checks)
            .compactMap { ingredient, check in
                check.isMissing ? ingredient : nil
            }
    }

    var reviewIngredients: [RecipePlanningReviewIngredient] {
        zip(recipe.ingredients, checks)
            .compactMap { ingredient, check in
                guard let issue = check.issue, !check.isMissing else { return nil }
                return RecipePlanningReviewIngredient(ingredient: ingredient, issue: issue)
            }
    }

    var isReadyToCook: Bool {
        checks.isEmpty == false && checks.allSatisfy { $0.issue == nil }
    }

    var hasReviewIssues: Bool {
        reviewIngredients.isEmpty == false
    }
}

#Preview {
        SavedRecipesView()
        .environmentObject(RecipeStore())
        .environmentObject(ProfileStore())
        .environmentObject(InventoryStore())
        .environmentObject(CookedMealStore())
}
