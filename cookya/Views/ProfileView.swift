//
//  ProfileView.swift
//  cookya
//
//  Created by adi on 05/03/26.
//

import SwiftUI

struct ProfileView: View {
    
    var body: some View {
        NavigationStack {
            Text("Profile")
                .font(.title)
                .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
}
