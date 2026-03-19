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
        let checks = inventoryStore.availabilityChecks(for: saved.recipe.ingredients)
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
        List {
            Section("Recipe") {
                Text(saved.recipe.title)
                    .font(.headline)
                Text("\(saved.recipe.difficulty.rawValue.capitalized) • \(saved.recipe.calories) kcal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Saved on \(saved.savedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if availabilityChecks.isEmpty {
                Section("Availability") {
                    Text("This recipe does not have enough ingredient data for a pantry check yet.")
                        .foregroundStyle(.secondary)
                }
            } else if availabilityIssues.isEmpty {
                Section("Availability") {
                    Label("Everything needed is available in pantry.", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Section {
                    Button("Cook Again") {
                        AppLogger.action(
                            "saved_recipe_cook_again_tapped",
                            screen: "SavedRecipeDetail",
                            metadata: ["recipeTitle": saved.recipe.title, "result": "available"]
                        )
                        isShowingCompletionSheet = true
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                Section("Availability") {
                    ForEach(availabilityIssues, id: \.self) { issue in
                        Text(issue)
                            .foregroundStyle(.orange)
                    }
                }

                if !missingIngredients.isEmpty {
                    Section {
                        Button("Add Missing Items to Grocery") {
                            addMissingItemsToGrocery()
                        }
                        .frame(maxWidth: .infinity)
                    } footer: {
                        Text("Only ingredients that are completely missing from pantry are added to Grocery.")
                    }
                }
            }

            Section("Ingredients") {
                ForEach(saved.recipe.ingredients) { ingredient in
                    Text(ingredient.quantity.isEmpty ? ingredient.name : "\(ingredient.name) (\(ingredient.quantity))")
                }
            }

            Section("Instructions") {
                ForEach(Array(saved.recipe.instructions.enumerated()), id: \.offset) { index, step in
                    Text("\(index + 1). \(step)")
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
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

    private var availabilityIssues: [String] {
        availabilityChecks.compactMap(\.issue)
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

#Preview {
        SavedRecipesView()
        .environmentObject(RecipeStore())
        .environmentObject(ProfileStore())
        .environmentObject(InventoryStore())
        .environmentObject(CookedMealStore())
}
