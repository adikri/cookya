//
//  cookyaApp.swift
//  cookya
//
//  Created by adi on 05/03/26.
//

import SwiftUI

@main
struct cookyaApp: App {
    @StateObject private var recipeStore = RecipeStore.shared
    @StateObject private var profileStore = ProfileStore()
    @StateObject private var inventoryStore = InventoryStore()
    @StateObject private var cookedMealStore = CookedMealStore()
    @StateObject private var knownItemStore = KnownItemStore()

    init() {
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
    }
}
