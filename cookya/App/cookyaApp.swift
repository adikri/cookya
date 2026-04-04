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
    private let backupCoordinator: AppBackupCoordinator

    init() {
        let userDefaults = UserDefaults.standard
        let backupCoordinator = AppBackupCoordinator(userDefaults: userDefaults)
        backupCoordinator.restoreIfNeeded()

        self.backupCoordinator = backupCoordinator
        _recipeStore = StateObject(wrappedValue: RecipeStore(userDefaults: userDefaults))
        _profileStore = StateObject(wrappedValue: ProfileStore(userDefaults: userDefaults))
        _inventoryStore = StateObject(wrappedValue: InventoryStore(userDefaults: userDefaults))
        _cookedMealStore = StateObject(wrappedValue: CookedMealStore(userDefaults: userDefaults))
        _knownItemStore = StateObject(wrappedValue: KnownItemStore(userDefaults: userDefaults))

        backupCoordinator.startObserving()
        AppLogger.log("App launched", metadata: ["logsDirectory": AppLogger.logsDirectoryPath])
    }

    var body: some Scene {
        WindowGroup {
            if profileStore.hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(recipeStore)
                    .environmentObject(inventoryStore)
                    .environmentObject(profileStore)
                    .environmentObject(cookedMealStore)
                    .environmentObject(knownItemStore)
            } else {
                ProfileOnboardingView()
                    .environmentObject(profileStore)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive || newPhase == .background {
                backupCoordinator.refreshBackup()
            }
        }
    }
}
