import SwiftUI

struct CookingProfileView: View {
    @EnvironmentObject private var profileStore: ProfileStore

    var body: some View {
        List {
            Section("Current selection") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(profileStore.activeProfile?.name ?? "Guest")
                        .font(.headline)
                    Text(profileStore.isGuestModeActive ? "Guest mode" : "Personal profile")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                if profileStore.primaryProfile != nil {
                    Button("Cook with personal profile") {
                        profileStore.activatePrimaryProfile()
                    }
                }

                Button("Cook as Guest") {
                    profileStore.continueAsGuest()
                }
            }
        }
        .navigationTitle("Who's Cooking")
        .onAppear {
            AppLogger.screen("CookingProfile", metadata: ["mode": profileStore.isGuestModeActive ? "guest" : "personal"])
        }
    }
}

#Preview {
    NavigationStack {
        CookingProfileView()
            .environmentObject(ProfileStore())
    }
}
