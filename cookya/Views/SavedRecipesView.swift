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
                            ForEach(filteredRecipes) { saved in
                                NavigationLink {
                                    SavedRecipeDetailView(saved: saved)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(saved.recipe.title)
                                            .font(.headline)
                                        Text("\(saved.recipe.difficulty.rawValue.capitalized) • \(saved.recipe.calories) kcal")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Text("Profile: \(saved.profileNameSnapshot)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 4)
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

    private func removeFilteredRecipes(at offsets: IndexSet) {
        let allRecipes = recipeStore.savedRecipes
        let filtered = filteredRecipes
        let mappedOffsets = IndexSet(offsets.compactMap { filteredIndex in
            let id = filtered[filteredIndex].id
            return allRecipes.firstIndex { $0.id == id }
        })
        recipeStore.removeRecipes(at: mappedOffsets)
    }
}

private struct SavedRecipeDetailView: View {
    @EnvironmentObject private var inventoryStore: InventoryStore
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var cookedMealStore: CookedMealStore

    let saved: SavedRecipe

    @State private var isShowingCompletionSheet = false
    @State private var completionMessage: String?

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
