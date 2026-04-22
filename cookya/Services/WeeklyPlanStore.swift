import SwiftUI
import Combine

@MainActor
final class WeeklyPlanStore: ObservableObject {
    @Published private(set) var meals: [PlannedMeal] = []

    let maxMeals = 7

    var isFull: Bool { meals.count >= maxMeals }

    private let storageKey = AppPersistenceKey.weeklyMealPlan
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        userDefaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
        load()
    }

    func contains(savedRecipeId: UUID) -> Bool {
        meals.contains { $0.savedRecipeId == savedRecipeId }
    }

    func add(_ savedRecipe: SavedRecipe) {
        guard !isFull, !contains(savedRecipeId: savedRecipe.id) else { return }
        meals.append(PlannedMeal(savedRecipe: savedRecipe))
        persist()
        AppLogger.action(
            "weekly_plan_meal_added",
            metadata: ["recipeTitle": savedRecipe.recipe.title, "count": String(meals.count)]
        )
    }

    func remove(_ meal: PlannedMeal) {
        meals.removeAll { $0.id == meal.id }
        persist()
        AppLogger.action("weekly_plan_meal_removed", metadata: ["recipeTitle": meal.recipeTitle])
    }

    func remove(at offsets: IndexSet) {
        meals.remove(atOffsets: offsets)
        persist()
    }

    func clearAll() {
        meals = []
        persist()
        AppLogger.action("weekly_plan_cleared")
    }

    func reloadFromDisk() {
        load()
    }

    private func load() {
        guard let data = userDefaults.data(forKey: storageKey) else { return }
        guard PersistencePayloadValidator.matchesExpectedTopLevel(data, shape: .array) else {
            meals = []
            AppLogger.action(
                "persistence_decode_failed",
                screen: "WeeklyPlanStore",
                metadata: ["key": storageKey, "entity": "weeklyMealPlan", "error": "Unexpected top-level JSON shape"]
            )
            return
        }
        do {
            meals = try decoder.decode([PlannedMeal].self, from: data)
        } catch {
            meals = []
            AppLogger.action(
                "persistence_decode_failed",
                screen: "WeeklyPlanStore",
                metadata: ["key": storageKey, "entity": "weeklyMealPlan", "error": String(describing: error)]
            )
        }
    }

    private func persist() {
        do {
            let data = try encoder.encode(meals)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            AppLogger.action(
                "persistence_encode_failed",
                screen: "WeeklyPlanStore",
                metadata: ["key": storageKey, "entity": "weeklyMealPlan", "error": String(describing: error)]
            )
            assertionFailure("Failed to persist weekly meal plan: \(error)")
        }
    }
}
