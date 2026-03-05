//
//  cookyaApp.swift
//  cookya
//
//  Created by adi on 05/03/26.
//

import SwiftUI

@main
struct cookyaApp: App {
    @StateObject private var recipeStore = RecipeStore()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(recipeStore)
        }
    }
}
