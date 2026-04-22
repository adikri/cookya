//
//  MainTabView.swift
//  cookya
//
//  Created by adi on 05/03/26.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var recipeStore: RecipeStore
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var inventoryStore: InventoryStore
    @EnvironmentObject private var cookedMealStore: CookedMealStore
    @EnvironmentObject private var knownItemStore: KnownItemStore
    @EnvironmentObject private var weeklyPlanStore: WeeklyPlanStore

    var body: some View {
        TabView {

            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            SavedRecipesView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark")
                }

            WeeklyMealPlanView()
                .tabItem {
                    Label("Plan", systemImage: "calendar")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: .cookyaBackupImported)) { _ in
            recipeStore.reloadFromDisk()
            profileStore.reloadFromDisk()
            inventoryStore.reloadFromDisk()
            cookedMealStore.reloadFromDisk()
            knownItemStore.reloadFromDisk()
            weeklyPlanStore.reloadFromDisk()
            AppLogger.action("backup_import_reloaded")
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(RecipeStore())
            .environmentObject(InventoryStore())
            .environmentObject(ProfileStore())
            .environmentObject(CookedMealStore())
            .environmentObject(WeeklyPlanStore())
    }
}
