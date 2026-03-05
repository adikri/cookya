//
//  SavedRecipesView.swift
//  cookya
//
//  Created by adi on 05/03/26.
//

import SwiftUI

struct SavedRecipesView: View {
    @EnvironmentObject private var recipeStore: RecipeStore

    var body: some View {
        NavigationStack {
            Group {
                if recipeStore.savedRecipes.isEmpty {
                    ContentUnavailableView(
                        "No Saved Recipes",
                        systemImage: "bookmark",
                        description: Text("Generate a recipe and save it to find it here.")
                    )
                } else {
                    List {
                        ForEach(recipeStore.savedRecipes) { recipe in
                            NavigationLink {
                                RecipeResultView(recipe: recipe)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(recipe.title)
                                        .font(.headline)
                                    Text("\(recipe.difficulty.rawValue.capitalized) • \(recipe.calories) kcal")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: recipeStore.removeRecipes)
                    }
                }
            }
            .navigationTitle("Saved")
        }
    }
}

#Preview {
    SavedRecipesView()
        .environmentObject(RecipeStore())
}
