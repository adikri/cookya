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
    private let syncService: (any WeeklyPlanSyncing)?

    init(
        userDefaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        syncService: (any WeeklyPlanSyncing)? = nil
    ) {
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
        self.syncService = syncService
        load()
    }

    func contains(savedRecipeId: UUID) -> Bool {
        meals.contains { $0.savedRecipeId == savedRecipeId }
    }

    func add(_ savedRecipe: SavedRecipe) {
        guard !isFull, !contains(savedRecipeId: savedRecipe.id) else { return }
        let meal = PlannedMeal(savedRecipe: savedRecipe)
        meals.append(meal)
        persist()
        AppLogger.action(
            "weekly_plan_meal_added",
            metadata: ["recipeTitle": savedRecipe.recipe.title, "count": String(meals.count)]
        )
        Task { try? await syncService?.upsertMeal(meal) }
    }

    func remove(_ meal: PlannedMeal) {
        meals.removeAll { $0.id == meal.id }
        persist()
        AppLogger.action("weekly_plan_meal_removed", metadata: ["recipeTitle": meal.recipeTitle])
        Task { try? await syncService?.deleteMeal(id: meal.id) }
    }

    func remove(at offsets: IndexSet) {
        let toDelete = offsets.map { meals[$0] }
        meals.remove(atOffsets: offsets)
        persist()
        Task { for meal in toDelete { try? await syncService?.deleteMeal(id: meal.id) } }
    }

    func clearAll() {
        meals = []
        persist()
        AppLogger.action("weekly_plan_cleared")
        Task { try? await syncService?.clearAllMeals() }
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
