import Foundation

// Shared error type for all store sync services.
enum StoreSyncError: LocalizedError {
    case notAuthenticated
    case networkError
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return nil
        case .networkError:     return "Could not sync data. Changes are saved locally."
        case .decodingFailed:   return "Could not decode synced data."
        }
    }
}

protocol SavedRecipeSyncing {
    func fetchSavedRecipes() async throws -> [SavedRecipe]
    func upsertSavedRecipe(_ recipe: SavedRecipe) async throws
    func deleteSavedRecipe(id: UUID) async throws
}

protocol CookedMealSyncing {
    func fetchRecords() async throws -> [CookedMealRecord]
    func upsertRecord(_ record: CookedMealRecord) async throws
    func deleteRecord(id: UUID) async throws
}

protocol ProfileSyncing {
    func fetchProfile() async throws -> UserProfile?
    func upsertProfile(_ profile: UserProfile) async throws
}

protocol WeeklyPlanSyncing {
    func fetchMeals() async throws -> [PlannedMeal]
    func upsertMeal(_ meal: PlannedMeal) async throws
    func deleteMeal(id: UUID) async throws
    func clearAllMeals() async throws
}
