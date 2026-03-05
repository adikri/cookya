//
//  IngredientInputView.swift
//  cookya
//
//  Created by adi on 05/03/26.
//

import SwiftUI

struct IngredientInputView: View {

    @StateObject private var viewModel = RecipeViewModel()

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                TextField("Enter ingredient", text: $viewModel.ingredientInput)
                    .textFieldStyle(.roundedBorder)

                Button("Add") {
                    viewModel.addIngredient()
                }
            }

            Picker("Difficulty", selection: $viewModel.selectedDifficulty) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    Text(difficulty.rawValue.capitalized).tag(difficulty)
                }
            }
            .pickerStyle(.segmented)

            if let error = viewModel.generationError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            List {
                ForEach(viewModel.ingredients) { item in
                    Text(item.name)
                }
                .onDelete(perform: viewModel.removeIngredients)
            }

            Button("Generate Recipe") {
                viewModel.generateRecipe()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading || viewModel.ingredients.isEmpty)

            if viewModel.isLoading {
                ProgressView("Generating...")
            }
        }
        .padding()
        .navigationTitle("Ingredients")
        .navigationDestination(item: $viewModel.generatedRecipe) { recipe in
            RecipeResultView(recipe: recipe)
        }
    }
}

#Preview {
    IngredientInputView()
}
