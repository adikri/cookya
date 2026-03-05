//
//  SavedRecipesView.swift
//  cookya
//
//  Created by adi on 05/03/26.
//

import SwiftUI

struct SavedRecipesView: View {
    
    var body: some View {
        NavigationStack {
            Text("Saved Recipes")
                .font(.title)
                .navigationTitle("Saved")
        }
    }
}

#Preview {
    SavedRecipesView()
}
