//
//  cookyaApp.swift
//  cookya
//
//  Created by adi on 05/03/26.
//

import SwiftUI

@main
struct cookyaApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var recipeStore: RecipeStore
    @StateObject private var profileStore: ProfileStore
    @StateObject private var inventoryStore: InventoryStore
    @StateObject private var cookedMealStore: CookedMealStore
    @StateObject private var knownItemStore: KnownItemStore
    @StateObject private var backendSyncStatusStore: BackendSyncStatusStore
    @StateObject private var weeklyPlanStore: WeeklyPlanStore
    @StateObject private var authStore: AuthStore
    private let backupCoordinator: AppBackupCoordinator

    init() {
        let userDefaults = UserDefaults.standard
        let backupCoordinator = AppBackupCoordinator(
            userDefaults: userDefaults,
            snapshotService: SupabaseSnapshotService(client: SupabaseManager.shared.client)
        )
        backupCoordinator.restoreIfNeeded()

        self.backupCoordinator = backupCoordinator
        _recipeStore = StateObject(wrappedValue: RecipeStore(userDefaults: userDefaults))
        _profileStore = StateObject(wrappedValue: ProfileStore(userDefaults: userDefaults))
        _inventoryStore = StateObject(wrappedValue: InventoryStore(
            inventoryService: SupabaseInventoryService(client: SupabaseManager.shared.client),
            userDefaults: userDefaults
        ))
        _cookedMealStore = StateObject(wrappedValue: CookedMealStore(userDefaults: userDefaults))
        _knownItemStore = StateObject(wrappedValue: KnownItemStore(userDefaults: userDefaults))
        _backendSyncStatusStore = StateObject(wrappedValue: BackendSyncStatusStore(userDefaults: userDefaults))
        _weeklyPlanStore = StateObject(wrappedValue: WeeklyPlanStore(userDefaults: userDefaults))
        _authStore = StateObject(wrappedValue: AuthStore())

        backupCoordinator.startObserving()
        AppLogger.log("App launched", metadata: ["logsDirectory": AppLogger.logsDirectoryPath])

        Task { @MainActor in
            await backupCoordinator.restoreFromBackendIfNeeded()
        }
    }

    var body: some Scene {
        WindowGroup {
            if authStore.isLoading {
                ProgressView()
            } else if !authStore.isAuthenticated {
                SignInView()
                    .environmentObject(authStore)
            } else if profileStore.hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(recipeStore)
                    .environmentObject(inventoryStore)
                    .environmentObject(profileStore)
                    .environmentObject(cookedMealStore)
                    .environmentObject(knownItemStore)
                    .environmentObject(backendSyncStatusStore)
                    .environmentObject(weeklyPlanStore)
                    .environmentObject(authStore)
            } else {
                ProfileOnboardingView()
                    .environmentObject(profileStore)
                    .environmentObject(authStore)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive || newPhase == .background {
                backupCoordinator.refreshBackup()
            }
        }
    }
}
