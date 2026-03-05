//
//  IngredientInputView.swift
//  cookya
//
//  Created by adi on 05/03/26.
//

import SwiftUI

struct IngredientInputView: View {
    
    @State private var ingredient = ""
    @State private var ingredients: [String] = []
    
    var body: some View {
        NavigationStack {
            
            VStack(spacing: 20) {
                
                HStack {
                    TextField("Enter ingredient", text: $ingredient)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Add") {
                        if !ingredient.isEmpty {
                            ingredients.append(ingredient)
                            ingredient = ""
                        }
                    }
                }
                
                List(ingredients, id: \.self) { item in
                    Text(item)
                }
                
                Button("Generate Recipe") {
                    
                }
                .buttonStyle(.borderedProminent)
                
            }
            .padding()
            .navigationTitle("Ingredients")
        }
    }
}

#Preview {
    IngredientInputView()
}
