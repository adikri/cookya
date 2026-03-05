import SwiftUI

struct RecipeResultView: View {
    @EnvironmentObject private var recipeStore: RecipeStore
    let recipe: Recipe

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(recipe.title)
                    .font(.title)
                    .fontWeight(.bold)

                HStack(spacing: 12) {
                    Label(recipe.difficulty.rawValue.capitalized, systemImage: "flame")
                    Label("\(recipe.calories) kcal", systemImage: "bolt.heart")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Button {
                    recipeStore.saveRecipe(recipe)
                } label: {
                    Label(recipeStore.isSaved(recipe) ? "Saved" : "Save Recipe", systemImage: recipeStore.isSaved(recipe) ? "bookmark.fill" : "bookmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(recipeStore.isSaved(recipe))

                sectionTitle("Ingredients")
                ForEach(recipe.ingredients) { ingredient in
                    HStack {
                        Text("• \(ingredient.name)")
                        if !ingredient.quantity.isEmpty {
                            Text("(\(ingredient.quantity))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                sectionTitle("Instructions")
                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, step in
                    Text("\(index + 1). \(step)")
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .padding(.top, 4)
    }
}

#Preview {
    let sampleIngredients = [
        Ingredient(name: "Eggs"),
        Ingredient(name: "Spinach"),
        Ingredient(name: "Tomato")
    ]

    let sampleRecipe = Recipe(
        title: "Eggs & Spinach Easy Bowl",
        ingredients: sampleIngredients,
        instructions: [
            "Prep ingredients.",
            "Saute and cook for 12 minutes.",
            "Serve warm."
        ],
        calories: 320,
        difficulty: .easy
    )

    NavigationStack {
        RecipeResultView(recipe: sampleRecipe)
            .environmentObject(RecipeStore())
    }
}
