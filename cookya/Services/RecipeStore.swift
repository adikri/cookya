import SwiftUI
import Combine

@MainActor
final class RecipeStore: ObservableObject {
    static let shared = RecipeStore()

    @Published private(set) var savedRecipes: [SavedRecipe] = []

    private let guestProfileId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let storageKey = AppPersistenceKey.savedRecipes
    private let generatedRecipeCacheKey = AppPersistenceKey.generatedRecipeCache
    private let generatedRecipeTimestampsKey = AppPersistenceKey.generatedRecipeTimestamps
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let generatedRecipeCacheLimit: Int
    private var generatedRecipeCache: [String: Recipe] = [:]
    private var generatedRecipeTimestamps: [String: Date] = [:]
    private let syncService: (any SavedRecipeSyncing)?

    init(
        userDefaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        generatedRecipeCacheLimit: Int = 50,
        syncService: (any SavedRecipeSyncing)? = nil
    ) {
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
        self.generatedRecipeCacheLimit = generatedRecipeCacheLimit
        self.syncService = syncService
        loadSavedRecipes()
        loadGeneratedRecipeCache()
        loadGeneratedRecipeTimestamps()
        trimGeneratedRecipeCacheIfNeeded()
    }

    func saveRecipe(_ recipe: Recipe, for profile: UserProfile?) {
        let profileId = profile?.id ?? guestProfileId
        let profileName = profile?.name ?? "Guest"

        guard !isSaved(recipe, for: profile) else { return }

        let saved = SavedRecipe(recipe: recipe, profileId: profileId, profileNameSnapshot: profileName)
        savedRecipes.insert(saved, at: 0)
        persistSavedRecipes()
        Task { try? await syncService?.upsertSavedRecipe(saved) }
    }

    func removeRecipes(at offsets: IndexSet) {
        let toDelete = offsets.map { savedRecipes[$0] }
        savedRecipes.remove(atOffsets: offsets)
        persistSavedRecipes()
        Task { for recipe in toDelete { try? await syncService?.deleteSavedRecipe(id: recipe.id) } }
    }

    func updateFavoriteState(for savedRecipeID: UUID, isFavorite: Bool) {
        guard let index = savedRecipes.firstIndex(where: { $0.id == savedRecipeID }) else { return }
        savedRecipes[index].isFavorite = isFavorite
        persistSavedRecipes()
        Task { try? await syncService?.upsertSavedRecipe(savedRecipes[index]) }
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
        generatedRecipeTimestamps[fingerprint] = .now
        trimGeneratedRecipeCacheIfNeeded()
        persistGeneratedRecipeCache()
        persistGeneratedRecipeTimestamps()
    }

    private func loadSavedRecipes() {
        guard let data = userDefaults.data(forKey: storageKey) else { return }
        guard PersistencePayloadValidator.matchesExpectedTopLevel(data, shape: .array) else {
            savedRecipes = []
            AppLogger.action(
                "persistence_decode_failed",
                screen: "RecipeStore",
                metadata: ["key": storageKey, "entity": "savedRecipes", "error": "Unexpected top-level JSON shape"]
            )
            return
        }

        do {
            savedRecipes = try decoder.decode([SavedRecipe].self, from: data)
        } catch {
            savedRecipes = []
            AppLogger.action(
                "persistence_decode_failed",
                screen: "RecipeStore",
                metadata: ["key": storageKey, "entity": "savedRecipes", "error": String(describing: error)]
            )
        }
    }

    private func persistSavedRecipes() {
        do {
            let data = try encoder.encode(savedRecipes)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            AppLogger.action(
                "persistence_encode_failed",
                screen: "RecipeStore",
                metadata: ["key": storageKey, "entity": "savedRecipes", "error": String(describing: error)]
            )
            assertionFailure("Failed to persist saved recipes: \(error)")
        }
    }

    private func loadGeneratedRecipeCache() {
        guard let data = userDefaults.data(forKey: generatedRecipeCacheKey) else { return }
        guard PersistencePayloadValidator.matchesExpectedTopLevel(data, shape: .object) else {
            generatedRecipeCache = [:]
            AppLogger.action(
                "persistence_decode_failed",
                screen: "RecipeStore",
                metadata: ["key": generatedRecipeCacheKey, "entity": "generatedRecipeCache", "error": "Unexpected top-level JSON shape"]
            )
            return
        }

        do {
            generatedRecipeCache = try decoder.decode([String: Recipe].self, from: data)
        } catch {
            generatedRecipeCache = [:]
            AppLogger.action(
                "persistence_decode_failed",
                screen: "RecipeStore",
                metadata: ["key": generatedRecipeCacheKey, "entity": "generatedRecipeCache", "error": String(describing: error)]
            )
        }
    }

    private func persistGeneratedRecipeCache() {
        do {
            let data = try encoder.encode(generatedRecipeCache)
            userDefaults.set(data, forKey: generatedRecipeCacheKey)
        } catch {
            AppLogger.action(
                "persistence_encode_failed",
                screen: "RecipeStore",
                metadata: ["key": generatedRecipeCacheKey, "entity": "generatedRecipeCache", "error": String(describing: error)]
            )
            assertionFailure("Failed to persist generated recipe cache: \(error)")
        }
    }

    private func loadGeneratedRecipeTimestamps() {
        guard let data = userDefaults.data(forKey: generatedRecipeTimestampsKey) else { return }
        guard PersistencePayloadValidator.matchesExpectedTopLevel(data, shape: .object) else {
            generatedRecipeTimestamps = [:]
            AppLogger.action(
                "persistence_decode_failed",
                screen: "RecipeStore",
                metadata: ["key": generatedRecipeTimestampsKey, "entity": "generatedRecipeTimestamps", "error": "Unexpected top-level JSON shape"]
            )
            return
        }

        do {
            generatedRecipeTimestamps = try decoder.decode([String: Date].self, from: data)
        } catch {
            generatedRecipeTimestamps = [:]
            AppLogger.action(
                "persistence_decode_failed",
                screen: "RecipeStore",
                metadata: ["key": generatedRecipeTimestampsKey, "entity": "generatedRecipeTimestamps", "error": String(describing: error)]
            )
        }
    }

    private func persistGeneratedRecipeTimestamps() {
        do {
            let data = try encoder.encode(generatedRecipeTimestamps)
            userDefaults.set(data, forKey: generatedRecipeTimestampsKey)
        } catch {
            AppLogger.action(
                "persistence_encode_failed",
                screen: "RecipeStore",
                metadata: ["key": generatedRecipeTimestampsKey, "entity": "generatedRecipeTimestamps", "error": String(describing: error)]
            )
            assertionFailure("Failed to persist generated recipe timestamps: \(error)")
        }
    }

    private func trimGeneratedRecipeCacheIfNeeded() {
        let fingerprintsToEvict = GeneratedRecipeCachePolicy.fingerprintsToEvict(
            cacheKeys: Set(generatedRecipeCache.keys),
            timestamps: generatedRecipeTimestamps,
            limit: generatedRecipeCacheLimit
        )

        for fingerprint in fingerprintsToEvict {
            generatedRecipeCache.removeValue(forKey: fingerprint)
            generatedRecipeTimestamps.removeValue(forKey: fingerprint)
        }

        generatedRecipeTimestamps = generatedRecipeTimestamps.filter { generatedRecipeCache[$0.key] != nil }
    }

    func reloadFromDisk() {
        loadSavedRecipes()
        loadGeneratedRecipeCache()
        loadGeneratedRecipeTimestamps()
        trimGeneratedRecipeCacheIfNeeded()
    }

}
