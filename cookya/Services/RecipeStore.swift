import SwiftUI
import Combine

@MainActor
final class RecipeStore: ObservableObject {
    static let shared = RecipeStore()

    @Published private(set) var savedRecipes: [SavedRecipe] = []

    private let guestProfileId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let storageKey = "saved_recipes_v1"
    private let generatedRecipeCacheKey = "generated_recipe_cache_v1"
    private let generatedRecipeTimestampsKey = "generated_recipe_cache_timestamps_v1"
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var generatedRecipeCache: [String: Recipe] = [:]
    private var generatedRecipeTimestamps: [String: Date] = [:]

    init(
        userDefaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
        loadSavedRecipes()
        loadGeneratedRecipeCache()
        loadGeneratedRecipeTimestamps()
    }

    func saveRecipe(_ recipe: Recipe, for profile: UserProfile?) {
        let profileId = profile?.id ?? guestProfileId
        let profileName = profile?.name ?? "Guest"

        guard !isSaved(recipe, for: profile) else { return }

        savedRecipes.insert(
            SavedRecipe(
                recipe: recipe,
                profileId: profileId,
                profileNameSnapshot: profileName
            ),
            at: 0
        )
        persistSavedRecipes()
    }

    func removeRecipes(at offsets: IndexSet) {
        savedRecipes.remove(atOffsets: offsets)
        persistSavedRecipes()
    }

    func updateFavoriteState(for savedRecipeID: UUID, isFavorite: Bool) {
        guard let index = savedRecipes.firstIndex(where: { $0.id == savedRecipeID }) else { return }
        savedRecipes[index].isFavorite = isFavorite
        persistSavedRecipes()
    }

    func isSaved(_ recipe: Recipe, for profile: UserProfile?) -> Bool {
        let profileId = profile?.id ?? guestProfileId
        return savedRecipes.contains { $0.recipe.id == recipe.id && $0.profileId == profileId }
    }

    func recipes(for profile: UserProfile?) -> [SavedRecipe] {
        let profileId = profile?.id ?? guestProfileId
        return savedRecipes.filter { $0.profileId == profileId }
    }

    func cachedGeneratedRecipe(for request: RecipeGenerationRequest) -> Recipe? {
        generatedRecipeCache[request.normalizedFingerprint]
    }

    func cachedGeneratedDate(for request: RecipeGenerationRequest) -> Date? {
        generatedRecipeTimestamps[request.normalizedFingerprint]
    }

    func cacheGeneratedRecipe(_ recipe: Recipe, for request: RecipeGenerationRequest) {
        let fingerprint = request.normalizedFingerprint
        generatedRecipeCache[fingerprint] = recipe
        generatedRecipeTimestamps[fingerprint] = generatedRecipeTimestamps[fingerprint] ?? .now
        persistGeneratedRecipeCache()
        persistGeneratedRecipeTimestamps()
    }

    private func loadSavedRecipes() {
        guard let data = userDefaults.data(forKey: storageKey) else { return }

        do {
            savedRecipes = try decoder.decode([SavedRecipe].self, from: data)
        } catch {
            savedRecipes = []
        }
    }

    private func persistSavedRecipes() {
        do {
            let data = try encoder.encode(savedRecipes)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            assertionFailure("Failed to persist saved recipes: \(error)")
        }
    }

    private func loadGeneratedRecipeCache() {
        guard let data = userDefaults.data(forKey: generatedRecipeCacheKey) else { return }

        do {
            generatedRecipeCache = try decoder.decode([String: Recipe].self, from: data)
        } catch {
            generatedRecipeCache = [:]
        }
    }

    private func persistGeneratedRecipeCache() {
        do {
            let data = try encoder.encode(generatedRecipeCache)
            userDefaults.set(data, forKey: generatedRecipeCacheKey)
        } catch {
            assertionFailure("Failed to persist generated recipe cache: \(error)")
        }
    }

    private func loadGeneratedRecipeTimestamps() {
        guard let data = userDefaults.data(forKey: generatedRecipeTimestampsKey) else { return }

        do {
            generatedRecipeTimestamps = try decoder.decode([String: Date].self, from: data)
        } catch {
            generatedRecipeTimestamps = [:]
        }
    }

    private func persistGeneratedRecipeTimestamps() {
        do {
            let data = try encoder.encode(generatedRecipeTimestamps)
            userDefaults.set(data, forKey: generatedRecipeTimestampsKey)
        } catch {
            assertionFailure("Failed to persist generated recipe timestamps: \(error)")
        }
    }
}
