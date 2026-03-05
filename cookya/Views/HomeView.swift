//
//  ContentView.swift
//  cookya
//
//  Created by adi on 05/03/26.
//

import SwiftUI

struct HomeView: View {
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                
                Text("Cookya")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                NavigationLink("Generate Recipe") {
                    IngredientInputView()
                }
                .buttonStyle(.borderedProminent)
                
                NavigationLink("Saved Recipes") {
                    SavedRecipesView()
                }
                .buttonStyle(.bordered)
                
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView()
}
