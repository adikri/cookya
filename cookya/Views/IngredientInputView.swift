import SwiftUI

struct IngredientInputView: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var inventoryStore: InventoryStore
    @StateObject private var viewModel = RecipeViewModel()
    @State private var matchingPantryItemForExtra: PantryItem?
    @State private var pendingExtraIngredientName = ""

    var body: some View {
        List {
            Section {
                if availablePantryItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(inventoryStore.sortedPantryItems.isEmpty ? "Your pantry is empty" : "No usable pantry items right now")
                            .font(.headline)
                        Text(inventoryStore.sortedPantryItems.isEmpty
                             ? "Add pantry items first, or type manual extras below for a one-off recipe."
                             : "Expired pantry items are excluded from cooking suggestions. Update or discard them from Pantry, or type manual extras below.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        NavigationLink("Manage Pantry") {
                            PantryView()
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    ForEach(availablePantryItems) { item in
                        VStack(alignment: .leading, spacing: 10) {
                            Button {
                                AppLogger.action("cook_now_pantry_row_tapped", screen: "CookNow", metadata: ["item": item.name, "selected": viewModel.isSelected(item) ? "false" : "true"])
                                viewModel.togglePantrySelection(for: item)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: viewModel.isSelected(item) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(viewModel.isSelected(item) ? Color.accentColor : Color.secondary)
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(item.name)
                                                .fontWeight(.semibold)
                                            if item.isExpiringSoon {
                                                Text("Use soon")
                                                    .font(.caption2)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.orange.opacity(0.15), in: Capsule())
                                                    .foregroundStyle(.orange)
                                            }
                                        }
                                        Text(item.quantityText.isEmpty ? item.category.displayName : "\(item.quantityText) • \(item.category.displayName)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)

                            if viewModel.isSelected(item) {
                                QuantityInputView(
                                    title: "How much of \(item.name) should this recipe use?",
                                    quantityText: viewModel.bindingForSelectedQuantity(itemID: item.id)
                                )
                                .font(.subheadline)
                            }
                        }
                    }
                }
            } header: {
                Text("Choose from Pantry")
            } footer: {
                Text("Select what you want to use right now. If you leave quantity blank, Cookya will use servings as the main scaling signal.")
            }

            if !expiredPantryItems.isEmpty {
                Section {
                    ForEach(expiredPantryItems) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(item.name)
                                        .fontWeight(.semibold)
                                    Text("Expired")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.red.opacity(0.14), in: Capsule())
                                        .foregroundStyle(.red)
                                }
                                Text(item.quantityText.isEmpty ? item.category.displayName : "\(item.quantityText) • \(item.category.displayName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let expiryDate = item.expiryDate {
                                Text(expiryDate, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    NavigationLink("Review expired pantry items") {
                        PantryView()
                    }
                } header: {
                    Text("Expired in Pantry")
                } footer: {
                    Text("Expired items are excluded from recipe generation until you update or remove them from Pantry.")
                }
            }

            Section("Add Extra Ingredients") {
                HStack {
                    TextField("Enter ingredient", text: $viewModel.ingredientInput)
                        .textFieldStyle(.roundedBorder)

                    Button("Add") {
                        addExtraIngredient()
                    }
                }

                ForEach(viewModel.ingredients) { item in
                    Text(item.name)
                }
                .onDelete(perform: viewModel.removeIngredients)
            }

            Section("Difficulty") {
                Picker("Difficulty", selection: $viewModel.selectedDifficulty) {
                    ForEach(Difficulty.allCases, id: \.self) { difficulty in
                        Text(difficulty.rawValue.capitalized).tag(difficulty)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Servings") {
                Stepper(value: $viewModel.servings, in: 1 ... 8) {
                    Text(viewModel.servings == 1 ? "Cooking for 1 person" : "Cooking for \(viewModel.servings) people")
                }
            }

            if let error = viewModel.generationError {
                Section {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    viewModel.generateRecipe(
                        profile: profileStore.activeProfile,
                        pantryItems: inventoryStore.pantryItems
                    )
                } label: {
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                            Text("Generating...")
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("Generate Recipe")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading || (viewModel.selectedPantryItemIDs.isEmpty && viewModel.ingredients.isEmpty))
            }
        }
        .navigationTitle("Cook Now")
        .navigationDestination(isPresented: $viewModel.shouldShowGeneratedRecipe) {
            if let recipe = viewModel.generatedRecipe {
                RecipeResultView(
                    recipe: recipe,
                    selectedPantrySelections: viewModel.generatedPantrySelections,
                    manualExtraIngredients: viewModel.ingredients,
                    cachedAt: viewModel.generatedRecipeCachedAt,
                    reopenedFromMemory: viewModel.reopenedFromMemory,
                    onGenerateAnother: {
                        viewModel.generateRecipe(
                            profile: profileStore.activeProfile,
                            pantryItems: inventoryStore.pantryItems,
                            forceRefresh: true
                        )
                    }
                )
            }
        }
        .task {
            AppLogger.screen("CookNow", metadata: ["profile": profileStore.activeProfile?.name ?? "Guest"])
            await inventoryStore.refreshIfNeededFromView()
        }
        .confirmationDialog(
            "Use pantry item instead?",
            isPresented: Binding(
                get: { matchingPantryItemForExtra != nil },
                set: { if !$0 { clearPendingExtraIngredientMatch() } }
            ),
            titleVisibility: .visible
        ) {
            if let pantryMatch = matchingPantryItemForExtra {
                Button("Use \(pantryMatch.name) from Pantry") {
                    AppLogger.action(
                        "extra_ingredient_matched_existing_pantry",
                        screen: "CookNow",
                        metadata: ["item": pantryMatch.name, "resolution": "use_pantry"]
                    )
                    if !viewModel.isSelected(pantryMatch) {
                        viewModel.togglePantrySelection(for: pantryMatch)
                    }
                    viewModel.ingredientInput = ""
                    clearPendingExtraIngredientMatch()
                }

                Button("Keep as Extra Ingredient") {
                    AppLogger.action(
                        "extra_ingredient_matched_existing_pantry",
                        screen: "CookNow",
                        metadata: ["item": pantryMatch.name, "resolution": "keep_extra"]
                    )
                    _ = viewModel.addIngredient(named: pendingExtraIngredientName)
                    clearPendingExtraIngredientMatch()
                }
            }

            Button("Cancel", role: .cancel) {
                clearPendingExtraIngredientMatch()
            }
        } message: {
            if let pantryMatch = matchingPantryItemForExtra {
                Text("\(pantryMatch.name) is already in your pantry as \(pantryMatch.quantityText.isEmpty ? pantryMatch.category.displayName : pantryMatch.quantityText). Do you want to use that item instead of adding a duplicate extra ingredient?")
            }
        }
    }

    private var availablePantryItems: [PantryItem] {
        inventoryStore.usablePantryItems
    }

    private var expiredPantryItems: [PantryItem] {
        inventoryStore.expiredPantryItems
    }

    private func addExtraIngredient() {
        let trimmed = viewModel.ingredientInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let pantryMatch = inventoryStore.findUsablePantryItem(named: trimmed) {
            pendingExtraIngredientName = trimmed
            matchingPantryItemForExtra = pantryMatch
        } else {
            _ = viewModel.addIngredient(named: trimmed)
        }
    }

    private func clearPendingExtraIngredientMatch() {
        matchingPantryItemForExtra = nil
        pendingExtraIngredientName = ""
    }
}

struct IngredientInputView_Previews: PreviewProvider {
    static var previews: some View {
        IngredientInputView()
            .environmentObject(ProfileStore())
            .environmentObject(InventoryStore())
    }
}
