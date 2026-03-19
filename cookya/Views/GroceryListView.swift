import SwiftUI

struct GroceryListView: View {
    @EnvironmentObject private var inventoryStore: InventoryStore
    @EnvironmentObject private var recipeStore: RecipeStore
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var cookedMealStore: CookedMealStore

    @State private var editorItem: GroceryItem?
    @State private var isAddingItem = false
    @State private var purchaseItem: GroceryItem?
    @State private var purchaseFeedbackMessage: String?

    var body: some View {
        List {
            if !nearMissRecipes.isEmpty {
                Section("You're Close To Cooking") {
                    ForEach(nearMissRecipes) { suggestion in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(suggestion.saved.recipe.title)
                                .font(.headline)
                            Text("Missing \(suggestion.missingIngredients.count) item(s): \(suggestion.missingIngredients.map(\.name).joined(separator: ", "))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Button("Add Missing Items") {
                                addMissingItems(for: suggestion)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if inventoryStore.sortedGroceryItems.isEmpty {
                ContentUnavailableView(
                    "No Grocery Items",
                    systemImage: "cart",
                    description: Text("Add groceries you need, then mark them purchased to move them into the pantry.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(inventoryStore.sortedGroceryItems) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(item.quantityText.isEmpty ? item.category.displayName : "\(item.quantityText) • \(item.category.displayName)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(groceryReasonText(for: item))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let note = item.note, !note.isEmpty {
                                    Text(note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Button("Purchased") {
                                AppLogger.action("purchase_tapped", screen: "GroceryList", metadata: ["item": item.name])
                                purchaseItem = item
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editorItem = item
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task { await inventoryStore.deleteGroceryItem(item) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Grocery List")
        .onAppear {
            AppLogger.screen("GroceryList", metadata: ["itemCount": String(inventoryStore.groceryItems.count)])
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddingItem = true
                } label: {
                    Label("Add Grocery Item", systemImage: "plus")
                }
            }
        }
        .refreshable {
            await inventoryStore.refresh()
        }
        .sheet(isPresented: $isAddingItem) {
            GroceryItemEditorView(item: nil) { item in
                Task { await inventoryStore.saveGroceryItem(item) }
            }
        }
        .sheet(item: $editorItem) { item in
            GroceryItemEditorView(item: item) { updated in
                Task { await inventoryStore.saveGroceryItem(updated) }
            }
        }
        .sheet(item: $purchaseItem) { item in
            PurchaseExpirySheet(item: item) { quantityText, category, expiryDate in
                Task {
                    let unavailableSavedRecipeIDsBefore = Set(
                        recipeStore.recipes(for: profileStore.activeProfile)
                            .filter { !inventoryStore.availabilityIssues(for: $0.recipe.ingredients).isEmpty }
                            .map(\.id)
                    )
                    let unavailableCookAgainTitlesBefore = Set(
                        cookedMealStore.records(for: profileStore.activeProfile)
                            .filter { !inventoryStore.availabilityIssues(for: $0.consumptions).isEmpty }
                            .map(\.recipeTitle)
                    )

                    await inventoryStore.markPurchased(
                        item,
                        quantityText: quantityText,
                        category: category,
                        expiryDate: expiryDate
                    )

                    purchaseFeedbackMessage = newlyReadyFeedbackMessage(
                        unavailableSavedRecipeIDsBefore: unavailableSavedRecipeIDsBefore,
                        unavailableCookAgainTitlesBefore: unavailableCookAgainTitlesBefore
                    )
                }
            }
        }
        .alert("Pantry Updated", isPresented: Binding(
            get: { purchaseFeedbackMessage != nil },
            set: { if !$0 { purchaseFeedbackMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseFeedbackMessage ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        GroceryListView()
            .environmentObject(InventoryStore())
            .environmentObject(RecipeStore())
            .environmentObject(ProfileStore())
            .environmentObject(CookedMealStore())
    }
}

private struct GroceryNearMissSuggestion: Identifiable {
    let id = UUID()
    let saved: SavedRecipe
    let missingIngredients: [Ingredient]
}

private extension GroceryListView {
    var nearMissRecipes: [GroceryNearMissSuggestion] {
        recipeStore.recipes(for: profileStore.activeProfile)
            .compactMap { saved in
                let checks = inventoryStore.availabilityChecks(for: saved.recipe.ingredients)
                let missingIngredients = zip(saved.recipe.ingredients, checks)
                    .compactMap { ingredient, check in
                        check.isMissing ? ingredient : nil
                    }
                guard !missingIngredients.isEmpty, missingIngredients.count <= 2 else { return nil }
                return GroceryNearMissSuggestion(saved: saved, missingIngredients: missingIngredients)
            }
            .prefix(3)
            .map { $0 }
    }

    func groceryReasonText(for item: GroceryItem) -> String {
        if !item.reasonRecipes.isEmpty {
            let reasons = item.reasonRecipes.joined(separator: ", ")
            return "\(item.source.displayName): \(reasons)"
        }
        return item.source.displayName
    }

    func addMissingItems(for suggestion: GroceryNearMissSuggestion) {
        Task {
            for ingredient in suggestion.missingIngredients {
                await inventoryStore.saveGroceryItem(
                    GroceryItem(
                        name: ingredient.name,
                        quantityText: ingredient.quantity,
                        category: .pantry,
                        source: .savedRecipe,
                        reasonRecipes: [suggestion.saved.recipe.title],
                        createdAt: .now
                    )
                )
            }

            AppLogger.action(
                "near_miss_missing_items_added",
                screen: "GroceryList",
                metadata: [
                    "recipeTitle": suggestion.saved.recipe.title,
                    "count": String(suggestion.missingIngredients.count)
                ]
            )
        }
    }

    func newlyReadyFeedbackMessage(
        unavailableSavedRecipeIDsBefore: Set<UUID>,
        unavailableCookAgainTitlesBefore: Set<String>
    ) -> String? {
        if let newlyReadySaved = recipeStore.recipes(for: profileStore.activeProfile)
            .first(where: { saved in
                unavailableSavedRecipeIDsBefore.contains(saved.id)
                && inventoryStore.availabilityIssues(for: saved.recipe.ingredients).isEmpty
            }) {
            return "\(newlyReadySaved.recipe.title) is now ready to cook."
        }

        if let newlyReadyCookAgain = cookedMealStore.records(for: profileStore.activeProfile)
            .first(where: { record in
                unavailableCookAgainTitlesBefore.contains(record.recipeTitle)
                && inventoryStore.availabilityIssues(for: record.consumptions).isEmpty
            }) {
            return "\(newlyReadyCookAgain.recipeTitle) is now ready to cook again."
        }

        return "Added to Pantry."
    }
}
