import SwiftUI

struct DishSearchView: View {
    @EnvironmentObject private var inventoryStore: InventoryStore
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var cookedMealStore: CookedMealStore
    @StateObject private var viewModel = RecipeViewModel()
    @State private var dishName = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        List {
            Section {
                TextField("e.g. Dal Makhani, Pasta, Chicken Curry…", text: $dishName)
                    .focused($fieldFocused)
                    .font(.headline)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
            } header: {
                Text("What do you want to make?")
            }

            Section {
                if usablePantryItems.isEmpty {
                    Text("Your pantry is empty — the recipe will list everything needed.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Cookya will reference your \(usablePantryItems.count) pantry item(s) and use what fits this dish naturally.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Pantry context")
            }

            Section {
                Button {
                    generate()
                } label: {
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                            Text("Generating…")
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("Generate Recipe")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(trimmedDishName.isEmpty || viewModel.isLoading)
            }

            if let error = viewModel.generationError {
                Section {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Cook a dish")
        .navigationDestination(isPresented: $viewModel.shouldShowGeneratedRecipe) {
            if let recipe = viewModel.generatedRecipe {
                RecipeResultView(
                    recipe: recipe,
                    selectedPantrySelections: viewModel.generatedPantrySelections,
                    manualExtraIngredients: [],
                    cachedAt: viewModel.generatedRecipeCachedAt,
                    reopenedFromMemory: viewModel.reopenedFromMemory,
                    onGenerateAnother: { generate(forceRefresh: true) }
                )
            }
        }
        .onAppear {
            fieldFocused = true
            AppLogger.screen("DishSearch", metadata: ["profile": profileStore.activeProfile?.name ?? "Guest"])
        }
    }

    private var trimmedDishName: String {
        dishName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var usablePantryItems: [PantryItem] {
        inventoryStore.usablePantryItems
    }

    private func generate(forceRefresh: Bool = false) {
        viewModel.targetDish = trimmedDishName
        viewModel.selectAllPantry(usablePantryItems)
        let nutritionGap = cookedMealStore.nutritionGap(for: profileStore.activeProfile)
        viewModel.generateRecipe(
            profile: profileStore.activeProfile,
            pantryItems: usablePantryItems,
            nutritionGap: nutritionGap,
            forceRefresh: forceRefresh
        )
        AppLogger.action("dish_search_generate", screen: "DishSearch", metadata: ["dish": trimmedDishName])
    }
}
