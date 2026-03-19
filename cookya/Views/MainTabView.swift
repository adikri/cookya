//
//  MainTabView.swift
//  cookya
//
//  Created by adi on 05/03/26.
//

import SwiftUI

struct MainTabView: View {

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

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(RecipeStore())
        .environmentObject(InventoryStore())
        .environmentObject(ProfileStore())
        .environmentObject(CookedMealStore())
}
