import SwiftUI

private struct ExtraIngredientResolution {
    enum Destination: String {
        case pantry = "Added to Pantry"
        case grocery = "Added to Grocery"
        case ignored = "Ignored for inventory"
    }

    let destination: Destination
    let pantryItem: PantryItem?

    var rawValue: String {
        destination.rawValue
    }
}

struct RecipeResultView: View {
    @EnvironmentObject private var recipeStore: RecipeStore
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var inventoryStore: InventoryStore
    @EnvironmentObject private var cookedMealStore: CookedMealStore
    let recipe: Recipe
    var selectedPantrySelections: [PantryRecipeSelection] = []
    var manualExtraIngredients: [Ingredient] = []
    var cachedAt: Date?
    var reopenedFromMemory: Bool = false
    var onGenerateAnother: (() -> Void)?

    @State private var isShowingCompletionSheet = false
    @State private var completionMessage: String?
    @State private var hasLoggedCooking = false
    @State private var trackedExtraIngredients: [UUID: ExtraIngredientResolution] = [:]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if reopenedFromMemory {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Recipe memory", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                            .font(.subheadline.weight(.semibold))
                        Text(memoryDescription)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                }

                Text(recipe.title)
                    .font(.title)
                    .fontWeight(.bold)

                HStack(spacing: 12) {
                    Label(recipe.difficulty.rawValue.capitalized, systemImage: "flame")
                    Label("\(recipe.calories) kcal", systemImage: "bolt.heart")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if let onGenerateAnother {
                    Button {
                        AppLogger.action(
                            "generate_another_recipe_tapped",
                            screen: "RecipeResult",
                            metadata: [
                                "recipeTitle": recipe.title,
                                "fromMemory": reopenedFromMemory ? "true" : "false"
                            ]
                        )
                        onGenerateAnother()
                    } label: {
                        Label("Generate Another Recipe", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    recipeStore.saveRecipe(recipe, for: profileStore.activeProfile)
                    AppLogger.action(
                        "recipe_saved",
                        screen: "RecipeResult",
                        metadata: [
                            "recipeTitle": recipe.title,
                            "profile": profileStore.activeProfile?.name ?? "Guest"
                        ]
                    )
                } label: {
                    Label(
                        recipeStore.isSaved(recipe, for: profileStore.activeProfile) ? "Saved" : "Save Recipe",
                        systemImage: recipeStore.isSaved(recipe, for: profileStore.activeProfile) ? "bookmark.fill" : "bookmark"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(recipeStore.isSaved(recipe, for: profileStore.activeProfile))

                if !selectedPantrySelections.isEmpty || !manualExtraIngredients.isEmpty {
                    Button {
                        guard !hasLoggedCooking else { return }
                        if hasUnresolvedExtraIngredients {
                            AppLogger.action(
                                "cooked_this_blocked_unresolved_extras",
                                screen: "RecipeResult",
                                metadata: [
                                    "recipeTitle": recipe.title,
                                    "unresolvedCount": String(unresolvedExtraIngredients.count)
                                ]
                            )
                            completionMessage = "Resolve each extra ingredient first by choosing Add to Pantry, Add to Grocery, or Ignore for inventory."
                        } else {
                            AppLogger.action(
                                "cooked_this_proceeding",
                                screen: "RecipeResult",
                                metadata: [
                                    "recipeTitle": recipe.title,
                                    "manualExtraCount": String(manualExtraIngredients.count)
                                ]
                            )
                            isShowingCompletionSheet = true
                        }
                    } label: {
                        Label(
                            hasLoggedCooking ? "Pantry Updated" : "Cooked This",
                            systemImage: hasLoggedCooking ? "checkmark.circle.fill" : "fork.knife.circle"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(hasLoggedCooking)
                }

                if !manualExtraIngredients.isEmpty {
                    sectionTitle("Track Extra Ingredients")
                    Text("Extra ingredients are temporary until you explicitly track them.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    ForEach(manualExtraIngredients) { ingredient in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(ingredient.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            if let trackedState = trackedExtraIngredients[ingredient.id]?.rawValue {
                                Text(trackedState)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                HStack(spacing: 12) {
                                    Button("Add to Pantry") {
                                        trackExtraIngredient(ingredient, destination: "pantry")
                                    }
                                    .buttonStyle(.bordered)

                                    Button("Add to Grocery") {
                                        trackExtraIngredient(ingredient, destination: "grocery")
                                    }
                                    .buttonStyle(.bordered)

                                    Button("Ignore") {
                                        trackExtraIngredient(ingredient, destination: "ignore")
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                sectionTitle("Ingredients")
                ForEach(recipe.ingredients) { ingredient in
                    HStack {
                        Text("• \(ingredient.name)")
                        if !ingredient.quantity.isEmpty {
                            Text("(\(ingredient.quantity))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                sectionTitle("Instructions")
                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, step in
                    Text("\(index + 1). \(step)")
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AppLogger.screen("RecipeResult", metadata: ["recipeTitle": recipe.title])
        }
        .sheet(isPresented: $isShowingCompletionSheet) {
            RecipeCompletionView(pantrySelections: completionPantrySelections) { consumptions in
                Task {
                    let result = await inventoryStore.consumePantryItems(consumptions)
                    let warnings = result.warnings
                    guard result.applied else {
                        completionMessage = warnings.joined(separator: "\n")
                        AppLogger.log("Recipe marked cooked blocked at apply time", metadata: ["recipeTitle": recipe.title, "warnings": warnings.joined(separator: " | ")])
                        return
                    }
                    cookedMealStore.addRecord(
                        recipe: recipe,
                        consumptions: consumptions,
                        warnings: warnings,
                        profile: profileStore.activeProfile
                    )
                    hasLoggedCooking = true
                    if warnings.isEmpty {
                        completionMessage = "Pantry updated from what you cooked."
                        AppLogger.log("Recipe marked cooked", metadata: ["recipeTitle": recipe.title, "result": "pantry updated"])
                    } else {
                        completionMessage = warnings.joined(separator: "\n")
                        AppLogger.log("Recipe marked cooked with warnings", metadata: ["recipeTitle": recipe.title, "warnings": warnings.joined(separator: " | ")])
                    }
                    AppLogger.action(
                        "cooked_history_created",
                        screen: "RecipeResult",
                        metadata: [
                            "recipeTitle": recipe.title,
                            "profile": profileStore.activeProfile?.name ?? "Guest",
                            "warningCount": String(warnings.count)
                        ]
                    )
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

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .padding(.top, 4)
    }

    private var memoryDescription: String {
        if let cachedAt {
            return "This recipe was reopened from memory. It was first generated on \(cachedAt.formatted(date: .abbreviated, time: .shortened))."
        }

        return "This recipe was reopened from memory because your cooking inputs matched a previous request."
    }

    private var unresolvedExtraIngredients: [Ingredient] {
        manualExtraIngredients.filter { trackedExtraIngredients[$0.id] == nil }
    }

    private var hasUnresolvedExtraIngredients: Bool {
        !unresolvedExtraIngredients.isEmpty
    }

    private var completionPantrySelections: [PantryRecipeSelection] {
        let pantryExtras = manualExtraIngredients.compactMap { ingredient -> PantryRecipeSelection? in
            guard trackedExtraIngredients[ingredient.id]?.destination == .pantry else { return nil }
            let pantryItem = trackedExtraIngredients[ingredient.id]?.pantryItem
            return PantryRecipeSelection(
                pantryItem: pantryItem ?? PantryItem(
                    id: ingredient.id,
                    name: ingredient.name,
                    quantityText: ingredient.quantity,
                    category: .pantry,
                    updatedAt: .now
                ),
                selectedQuantityText: ingredient.quantity
            )
        }

        return selectedPantrySelections + pantryExtras
    }

    private func trackExtraIngredient(_ ingredient: Ingredient, destination: String) {
        let trimmedName = ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        AppLogger.action(
            "extra_ingredient_tracking_selected",
            screen: "RecipeResult",
            metadata: [
                "ingredient": trimmedName,
                "destination": destination,
                "recipeTitle": recipe.title
            ]
        )

        Task {
            switch destination {
            case "pantry":
                if let existingPantryItem = inventoryStore.findUsablePantryItem(named: trimmedName) {
                    trackedExtraIngredients[ingredient.id] = ExtraIngredientResolution(
                        destination: .pantry,
                        pantryItem: existingPantryItem
                    )
                } else {
                    let pantryItem = PantryItem(
                        name: trimmedName,
                        quantityText: ingredient.quantity,
                        category: .pantry,
                        updatedAt: .now
                    )
                    await inventoryStore.savePantryItem(pantryItem)
                    trackedExtraIngredients[ingredient.id] = ExtraIngredientResolution(
                        destination: .pantry,
                        pantryItem: pantryItem
                    )
                }
            case "grocery":
                await inventoryStore.saveGroceryItem(
                    GroceryItem(
                        name: trimmedName,
                        quantityText: ingredient.quantity,
                        category: .pantry,
                        source: .extraIngredient,
                        reasonRecipes: [recipe.title],
                        createdAt: .now
                    )
                )
                trackedExtraIngredients[ingredient.id] = ExtraIngredientResolution(
                    destination: .grocery,
                    pantryItem: nil
                )
            case "ignore":
                trackedExtraIngredients[ingredient.id] = ExtraIngredientResolution(
                    destination: .ignored,
                    pantryItem: nil
                )
            default:
                break
            }

            AppLogger.action(
                "extra_ingredient_tracked",
                screen: "RecipeResult",
                metadata: [
                    "ingredient": trimmedName,
                    "destination": destination,
                    "recipeTitle": recipe.title
                ]
            )
        }
    }
}

struct RecipeResultView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleIngredients = [
            Ingredient(name: "Eggs"),
            Ingredient(name: "Spinach"),
            Ingredient(name: "Tomato")
        ]

        let sampleRecipe = Recipe(
            title: "Eggs & Spinach Easy Bowl",
            ingredients: sampleIngredients,
            instructions: [
                "Prep ingredients.",
                "Saute and cook for 12 minutes.",
                "Serve warm."
            ],
            calories: 320,
            difficulty: .easy
        )

        return NavigationStack {
            RecipeResultView(recipe: sampleRecipe)
                .environmentObject(RecipeStore())
                .environmentObject(ProfileStore())
                .environmentObject(InventoryStore())
                .environmentObject(CookedMealStore())
        }
    }
}
