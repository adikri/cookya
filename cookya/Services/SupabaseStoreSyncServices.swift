import Foundation
import Supabase

// MARK: - SavedRecipe

struct SupabaseSavedRecipeSyncService: SavedRecipeSyncing {
    private let client: SupabaseClient
    init(client: SupabaseClient) { self.client = client }

    func fetchSavedRecipes() async throws -> [SavedRecipe] {
        do {
            let rows: [SavedRecipeRow] = try await client.from("saved_recipes").select().execute().value
            return rows.map(\.domain)
        } catch { throw storeSyncError(error) }
    }

    func upsertSavedRecipe(_ recipe: SavedRecipe) async throws {
        do {
            try await client.from("saved_recipes")
                .upsert(SavedRecipeRow(recipe, userId: try userId(client))).execute()
        } catch let e as StoreSyncError { throw e
        } catch { throw storeSyncError(error) }
    }

    func deleteSavedRecipe(id: UUID) async throws {
        do {
            try await client.from("saved_recipes").delete().eq("id", value: id.uuidString).execute()
        } catch { throw storeSyncError(error) }
    }
}

// MARK: - CookedMealRecord

struct SupabaseCookedMealSyncService: CookedMealSyncing {
    private let client: SupabaseClient
    init(client: SupabaseClient) { self.client = client }

    func fetchRecords() async throws -> [CookedMealRecord] {
        do {
            let rows: [CookedMealRow] = try await client.from("cooked_meal_records").select().execute().value
            return rows.map(\.domain)
        } catch { throw storeSyncError(error) }
    }

    func upsertRecord(_ record: CookedMealRecord) async throws {
        do {
            try await client.from("cooked_meal_records")
                .upsert(CookedMealRow(record, userId: try userId(client))).execute()
        } catch let e as StoreSyncError { throw e
        } catch { throw storeSyncError(error) }
    }

    func deleteRecord(id: UUID) async throws {
        do {
            try await client.from("cooked_meal_records").delete().eq("id", value: id.uuidString).execute()
        } catch { throw storeSyncError(error) }
    }
}

// MARK: - Profile

struct SupabaseProfileSyncService: ProfileSyncing {
    private let client: SupabaseClient
    init(client: SupabaseClient) { self.client = client }

    func fetchProfile() async throws -> UserProfile? {
        do {
            let rows: [ProfileRow] = try await client.from("profiles").select().execute().value
            return rows.first?.domain
        } catch { throw storeSyncError(error) }
    }

    func upsertProfile(_ profile: UserProfile) async throws {
        do {
            try await client.from("profiles")
                .upsert(ProfileRow(profile, userId: try userId(client)), onConflict: "user_id").execute()
        } catch let e as StoreSyncError { throw e
        } catch { throw storeSyncError(error) }
    }
}

// MARK: - WeeklyPlan

struct SupabaseWeeklyPlanSyncService: WeeklyPlanSyncing {
    private let client: SupabaseClient
    init(client: SupabaseClient) { self.client = client }

    func fetchMeals() async throws -> [PlannedMeal] {
        do {
            let rows: [PlannedMealRow] = try await client.from("weekly_plan_meals").select().execute().value
            return rows.map(\.domain)
        } catch { throw storeSyncError(error) }
    }

    func upsertMeal(_ meal: PlannedMeal) async throws {
        do {
            try await client.from("weekly_plan_meals")
                .upsert(PlannedMealRow(meal, userId: try userId(client))).execute()
        } catch let e as StoreSyncError { throw e
        } catch { throw storeSyncError(error) }
    }

    func deleteMeal(id: UUID) async throws {
        do {
            try await client.from("weekly_plan_meals").delete().eq("id", value: id.uuidString).execute()
        } catch { throw storeSyncError(error) }
    }

    func clearAllMeals() async throws {
        do {
            try await client.from("weekly_plan_meals")
                .delete().eq("user_id", value: try userId(client).uuidString).execute()
        } catch let e as StoreSyncError { throw e
        } catch { throw storeSyncError(error) }
    }
}

// MARK: - Shared helpers

private func userId(_ client: SupabaseClient) throws -> UUID {
    guard let user = client.auth.currentUser else { throw StoreSyncError.notAuthenticated }
    return user.id
}

private func storeSyncError(_ error: Error) -> StoreSyncError {
    if let e = error as? StoreSyncError { return e }
    return .networkError
}

// MARK: - DTOs
// camelCase fields → snake_case columns via SupabaseManager's convertToSnakeCase encoder

private struct SavedRecipeRow: Codable {
    let id: UUID
    let userId: UUID
    let recipe: Recipe
    let profileId: UUID
    let profileNameSnapshot: String
    let savedAt: Date
    let isFavorite: Bool

    init(_ saved: SavedRecipe, userId: UUID) {
        id = saved.id; self.userId = userId; recipe = saved.recipe
        profileId = saved.profileId; profileNameSnapshot = saved.profileNameSnapshot
        savedAt = saved.savedAt; isFavorite = saved.isFavorite
    }

    var domain: SavedRecipe {
        SavedRecipe(id: id, recipe: recipe, profileId: profileId,
                    profileNameSnapshot: profileNameSnapshot, savedAt: savedAt, isFavorite: isFavorite)
    }
}

private struct CookedMealRow: Codable {
    let id: UUID; let userId: UUID; let cookedAt: Date
    let profileId: UUID; let profileNameSnapshot: String; let recipeTitle: String
    let recipeIngredients: [Ingredient]; let consumptions: [PantryConsumption]
    let warnings: [String]
    let calories: Int; let proteinG: Int; let carbsG: Int; let fatG: Int; let fiberG: Int

    init(_ r: CookedMealRecord, userId: UUID) {
        id = r.id; self.userId = userId; cookedAt = r.cookedAt
        profileId = r.profileId; profileNameSnapshot = r.profileNameSnapshot
        recipeTitle = r.recipeTitle; recipeIngredients = r.recipeIngredients
        consumptions = r.consumptions; warnings = r.warnings
        calories = r.calories; proteinG = r.proteinG; carbsG = r.carbsG
        fatG = r.fatG; fiberG = r.fiberG
    }

    var domain: CookedMealRecord {
        CookedMealRecord(id: id, cookedAt: cookedAt, profileId: profileId,
                         profileNameSnapshot: profileNameSnapshot, recipeTitle: recipeTitle,
                         recipeIngredients: recipeIngredients, consumptions: consumptions,
                         warnings: warnings, calories: calories, proteinG: proteinG,
                         carbsG: carbsG, fatG: fatG, fiberG: fiberG)
    }
}

private struct ProfileRow: Codable {
    let id: UUID; let userId: UUID; let name: String; let type: String
    let age: Int?; let weightKg: Double?; let heightCm: Double?; let location: String?
    let isVegetarian: Bool; let avoidFoodItems: [String]
    let nutritionGoals: NutritionGoals?; let createdAt: Date; let updatedAt: Date

    init(_ p: UserProfile, userId: UUID) {
        id = p.id; self.userId = userId; name = p.name; type = p.type.rawValue
        age = p.age; weightKg = p.weightKg; heightCm = p.heightCm; location = p.location
        isVegetarian = p.isVegetarian; avoidFoodItems = p.avoidFoodItems
        nutritionGoals = p.nutritionGoals; createdAt = p.createdAt; updatedAt = p.updatedAt
    }

    var domain: UserProfile {
        UserProfile(id: id, type: ProfileType(rawValue: type) ?? .registered,
                    name: name, age: age, weightKg: weightKg, heightCm: heightCm,
                    location: location, isVegetarian: isVegetarian, avoidFoodItems: avoidFoodItems,
                    nutritionGoals: nutritionGoals, createdAt: createdAt, updatedAt: updatedAt)
    }
}

private struct PlannedMealRow: Codable {
    let id: UUID; let userId: UUID
    let savedRecipeId: UUID; let recipeTitle: String; let addedAt: Date

    init(_ m: PlannedMeal, userId: UUID) {
        id = m.id; self.userId = userId
        savedRecipeId = m.savedRecipeId; recipeTitle = m.recipeTitle; addedAt = m.addedAt
    }

    var domain: PlannedMeal {
        PlannedMeal(id: id, savedRecipeId: savedRecipeId, recipeTitle: recipeTitle, addedAt: addedAt)
    }
}
