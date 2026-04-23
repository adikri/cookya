import SwiftUI
import Combine

@MainActor
final class ProfileStore: ObservableObject {
    @Published private(set) var primaryProfile: UserProfile?
    @Published private(set) var isGuestModeActive = false

    private let primaryStorageKey = AppPersistenceKey.primaryProfile
    private let guestModeStorageKey = AppPersistenceKey.guestModeActive
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let syncService: (any ProfileSyncing)?

    var hasCompletedOnboarding: Bool {
        primaryProfile != nil || isGuestModeActive
    }

    var activeProfile: UserProfile? {
        isGuestModeActive ? guestProfile : primaryProfile
    }

    var guestProfile: UserProfile {
        UserProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            type: .guest,
            name: "Guest",
            createdAt: .now,
            updatedAt: .now
        )
    }

    init(
        userDefaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        syncService: (any ProfileSyncing)? = nil
    ) {
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
        self.syncService = syncService
        loadProfile()
    }

    func createRegisteredProfile(
        name: String,
        age: Int?,
        weightKg: Double?,
        heightCm: Double?,
        location: String?,
        isVegetarian: Bool,
        avoidFoodItems: [String]
    ) {
        let now = Date()
        primaryProfile = UserProfile(
            type: .registered,
            name: name,
            age: age,
            weightKg: weightKg,
            heightCm: heightCm,
            location: location,
            isVegetarian: isVegetarian,
            avoidFoodItems: avoidFoodItems,
            createdAt: now,
            updatedAt: now
        )
        isGuestModeActive = false
        persistState()
    }

    func continueAsGuest() {
        isGuestModeActive = true
        persistState()
    }

    func activatePrimaryProfile() {
        guard primaryProfile != nil else { return }
        isGuestModeActive = false
        persistState()
    }

    func updateActiveProfile(
        name: String,
        age: Int?,
        weightKg: Double?,
        heightCm: Double?,
        location: String?,
        isVegetarian: Bool,
        avoidFoodItems: [String]
    ) {
        guard var profile = primaryProfile ?? (isGuestModeActive ? nil : primaryProfile) else {
            if isGuestModeActive {
                createRegisteredProfile(
                    name: name,
                    age: age,
                    weightKg: weightKg,
                    heightCm: heightCm,
                    location: location,
                    isVegetarian: isVegetarian,
                    avoidFoodItems: avoidFoodItems
                )
            }
            return
        }
        profile.name = name
        profile.age = age
        profile.weightKg = weightKg
        profile.heightCm = heightCm
        profile.location = location
        profile.isVegetarian = isVegetarian
        profile.avoidFoodItems = avoidFoodItems
        profile.updatedAt = .now

        profile.type = .registered

        primaryProfile = profile
        isGuestModeActive = false
        persistState()
    }

    private func loadProfile() {
        if let data = userDefaults.data(forKey: primaryStorageKey) {
            guard PersistencePayloadValidator.matchesExpectedTopLevel(data, shape: .object) else {
                primaryProfile = nil
                AppLogger.action(
                    "persistence_decode_failed",
                    screen: "ProfileStore",
                    metadata: ["key": primaryStorageKey, "entity": "primaryProfile", "error": "Unexpected top-level JSON shape"]
                )
                isGuestModeActive = userDefaults.bool(forKey: guestModeStorageKey)
                return
            }
            do {
                primaryProfile = try decoder.decode(UserProfile.self, from: data)
            } catch {
                primaryProfile = nil
                AppLogger.action(
                    "persistence_decode_failed",
                    screen: "ProfileStore",
                    metadata: ["key": primaryStorageKey, "entity": "primaryProfile", "error": String(describing: error)]
                )
            }
        }

        isGuestModeActive = userDefaults.bool(forKey: guestModeStorageKey)
    }

    private func persistState() {
        if let profile = primaryProfile {
            do {
                let data = try encoder.encode(profile)
                userDefaults.set(data, forKey: primaryStorageKey)
            } catch {
                AppLogger.action(
                    "persistence_encode_failed",
                    screen: "ProfileStore",
                    metadata: ["key": primaryStorageKey, "entity": "primaryProfile", "error": String(describing: error)]
                )
                assertionFailure("Failed to persist primary profile: \(error)")
            }
            Task { try? await syncService?.upsertProfile(profile) }
        }
        userDefaults.set(isGuestModeActive, forKey: guestModeStorageKey)
    }

    func reloadFromDisk() {
        loadProfile()
    }
}
