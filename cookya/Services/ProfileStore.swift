import SwiftUI
import Combine

@MainActor
final class ProfileStore: ObservableObject {
    @Published private(set) var primaryProfile: UserProfile?
    @Published private(set) var isGuestModeActive = false

    private let primaryStorageKey = "primary_profile_v1"
    private let guestModeStorageKey = "guest_mode_active_v1"

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

    init() {
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
        if let data = UserDefaults.standard.data(forKey: primaryStorageKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            primaryProfile = profile
        }

        isGuestModeActive = UserDefaults.standard.bool(forKey: guestModeStorageKey)
    }

    private func persistState() {
        if let profile = primaryProfile,
           let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: primaryStorageKey)
        }
        UserDefaults.standard.set(isGuestModeActive, forKey: guestModeStorageKey)
    }
}
