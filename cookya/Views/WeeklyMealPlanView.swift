import SwiftUI

struct WeeklyMealPlanView: View {
    @EnvironmentObject private var weeklyPlanStore: WeeklyPlanStore
    @EnvironmentObject private var recipeStore: RecipeStore
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var inventoryStore: InventoryStore

    @State private var isShowingAddSheet = false
    @State private var groceryAddedMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if weeklyPlanStore.meals.isEmpty {
                    ContentUnavailableView(
                        "No Meals Planned",
                        systemImage: "calendar",
                        description: Text("Add up to \(weeklyPlanStore.maxMeals) saved recipes to plan your week.")
                    )
                } else {
                    List {
                        Section {
                            ForEach(weeklyPlanStore.meals) { meal in
                                PlannedMealRow(
                                    meal: meal,
                                    savedRecipe: savedRecipe(for: meal),
                                    readiness: readiness(for: meal)
                                )
                            }
                            .onDelete { offsets in
                                weeklyPlanStore.remove(at: offsets)
                            }
                        } header: {
                            Text("This Week · \(weeklyPlanStore.meals.count)/\(weeklyPlanStore.maxMeals) meals")
                        } footer: {
                            Text("Swipe left to remove a meal from the plan.")
                        }

                        missingIngredientsSection
                    }
                }
            }
            .navigationTitle("Meal Plan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !weeklyPlanStore.isFull {
                        Button {
                            isShowingAddSheet = true
                        } label: {
                            Label("Add Meal", systemImage: "plus")
                        }
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !weeklyPlanStore.meals.isEmpty {
                        Button("Clear", role: .destructive) {
                            weeklyPlanStore.clearAll()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .sheet(isPresented: $isShowingAddSheet) {
                AddMealSheet()
            }
            .alert("Grocery Updated", isPresented: Binding(
                get: { groceryAddedMessage != nil },
                set: { if !$0 { groceryAddedMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(groceryAddedMessage ?? "")
            }
            .onAppear {
                AppLogger.screen("WeeklyMealPlan", metadata: ["mealCount": String(weeklyPlanStore.meals.count)])
            }
        }
    }

    @ViewBuilder
    private var missingIngredientsSection: some View {
        let missing = allMissingIngredients
        Section {
            if missing.isEmpty {
                Label("All ingredients are available in pantry", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                ForEach(missing, id: \.name) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.subheadline)
                        Text(item.recipes.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
                Button("Add All to Grocery") {
                    addAllMissingToGrocery(missing)
                }
                .frame(maxWidth: .infinity)
            }
        } header: {
            Text("Missing Ingredients")
        } footer: {
            if !missing.isEmpty {
                Text("These ingredients are needed across your planned meals but are not currently in pantry.")
            }
        }
    }

    private struct MissingIngredient {
        let name: String
        let quantity: String
        let recipes: [String]
    }

    private var allMissingIngredients: [MissingIngredient] {
        var byName: [String: MissingIngredient] = [:]

        for meal in weeklyPlanStore.meals {
            guard let saved = savedRecipe(for: meal) else { continue }
            let checks = inventoryStore.availabilityChecks(for: saved.recipe.ingredients)
            let missing = zip(saved.recipe.ingredients, checks).filter { $0.1.isMissing }

            for (ingredient, _) in missing {
                let normalized = ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if var existing = byName[normalized] {
                    if !existing.recipes.contains(meal.recipeTitle) {
                        existing = MissingIngredient(
                            name: existing.name,
                            quantity: existing.quantity,
                            recipes: existing.recipes + [meal.recipeTitle]
                        )
                        byName[normalized] = existing
                    }
                } else {
                    byName[normalized] = MissingIngredient(
                        name: ingredient.name,
                        quantity: ingredient.quantity,
                        recipes: [meal.recipeTitle]
                    )
                }
            }
        }

        return byName.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func addAllMissingToGrocery(_ missing: [MissingIngredient]) {
        Task {
            for item in missing {
                await inventoryStore.saveGroceryItem(
                    GroceryItem(
                        name: item.name,
                        quantityText: item.quantity,
                        category: .pantry,
                        source: .savedRecipe,
                        reasonRecipes: item.recipes,
                        createdAt: .now
                    )
                )
            }
            AppLogger.action(
                "weekly_plan_grocery_generated",
                metadata: ["itemCount": String(missing.count)]
            )
            groceryAddedMessage = "\(missing.count) missing ingredient(s) added to Grocery."
        }
    }

    private func savedRecipe(for meal: PlannedMeal) -> SavedRecipe? {
        recipeStore.savedRecipes.first { $0.id == meal.savedRecipeId }
    }

    private func readiness(for meal: PlannedMeal) -> PlanReadiness {
        guard let saved = savedRecipe(for: meal) else { return .unknown }
        let issues = inventoryStore.availabilityIssues(for: saved.recipe.ingredients)
        return issues.isEmpty ? .ready : .missing(issues.count)
    }
}

private enum PlanReadiness {
    case ready
    case missing(Int)
    case unknown

    var label: String {
        switch self {
        case .ready: return "Ready"
        case .missing(let n): return n == 1 ? "Missing 1" : "Missing \(n)"
        case .unknown: return "Removed"
        }
    }

    var color: Color {
        switch self {
        case .ready: return .green
        case .missing: return .orange
        case .unknown: return .secondary
        }
    }
}

private struct PlannedMealRow: View {
    let meal: PlannedMeal
    let savedRecipe: SavedRecipe?
    let readiness: PlanReadiness

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Text(meal.recipeTitle)
                    .font(.headline)
                Spacer(minLength: 12)
                Text(readiness.label)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(readiness.color.opacity(0.12), in: Capsule())
                    .foregroundStyle(readiness.color)
            }
            if let recipe = savedRecipe?.recipe {
                Text(metaLine(recipe))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func metaLine(_ recipe: Recipe) -> String {
        var parts = ["\(recipe.difficulty.rawValue.capitalized)", "\(recipe.calories) kcal"]
        if recipe.protein > 0 {
            parts.append("~\(recipe.protein)g protein")
        }
        return parts.joined(separator: " • ")
    }
}

private struct AddMealSheet: View {
    @EnvironmentObject private var weeklyPlanStore: WeeklyPlanStore
    @EnvironmentObject private var recipeStore: RecipeStore
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var inventoryStore: InventoryStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if availableRecipes.isEmpty {
                    ContentUnavailableView(
                        "Nothing to Add",
                        systemImage: "bookmark",
                        description: Text("All saved recipes are already in your plan, or you have no saved recipes yet.")
                    )
                } else {
                    List {
                        Section {
                            ForEach(availableRecipes) { saved in
                                Button {
                                    weeklyPlanStore.add(saved)
                                    if weeklyPlanStore.isFull { dismiss() }
                                } label: {
                                    AddMealRow(saved: saved, readiness: readiness(for: saved))
                                }
                                .buttonStyle(.plain)
                            }
                        } footer: {
                            Text("Tap a recipe to add it. Up to \(weeklyPlanStore.maxMeals) meals total.")
                        }
                    }
                }
            }
            .navigationTitle("Add a Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var availableRecipes: [SavedRecipe] {
        recipeStore.recipes(for: profileStore.activeProfile)
            .filter { !weeklyPlanStore.contains(savedRecipeId: $0.id) }
            .sorted { lhs, rhs in
                let lr = readiness(for: lhs)
                let rr = readiness(for: rhs)
                if lr.sortPriority != rr.sortPriority {
                    return lr.sortPriority < rr.sortPriority
                }
                if lhs.isFavorite != rhs.isFavorite {
                    return lhs.isFavorite
                }
                return lhs.savedAt > rhs.savedAt
            }
    }

    private func readiness(for saved: SavedRecipe) -> PlanReadiness {
        let issues = inventoryStore.availabilityIssues(for: saved.recipe.ingredients)
        return issues.isEmpty ? .ready : .missing(issues.count)
    }
}

extension PlanReadiness {
    var sortPriority: Int {
        switch self {
        case .ready: return 0
        case .missing: return 1
        case .unknown: return 2
        }
    }
}

private struct AddMealRow: View {
    let saved: SavedRecipe
    let readiness: PlanReadiness

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if saved.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                    Text(saved.recipe.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                Text(metaLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Text(readiness.label)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(readiness.color.opacity(0.12), in: Capsule())
                .foregroundStyle(readiness.color)
        }
        .padding(.vertical, 2)
    }

    private var metaLine: String {
        var parts = [saved.recipe.difficulty.rawValue.capitalized, "\(saved.recipe.calories) kcal"]
        if saved.recipe.protein > 0 {
            parts.append("~\(saved.recipe.protein)g protein")
        }
        return parts.joined(separator: " • ")
    }
}
