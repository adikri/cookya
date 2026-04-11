import SwiftUI

struct GuestModeView: View {
    @EnvironmentObject private var profileStore: ProfileStore

    var body: some View {
        List {
            Section {
                Text("Cook recipes without saving them under your personal profile.")
                    .foregroundStyle(.secondary)
            }

            Section("Current mode") {
                Text(profileStore.isGuestModeActive ? "Guest" : (profileStore.activeProfile?.name ?? "No profile"))
            }

            Section {
                Button("Use Guest mode") {
                    profileStore.continueAsGuest()
                }

                if profileStore.primaryProfile != nil {
                    Button("Return to personal profile") {
                        profileStore.activatePrimaryProfile()
                    }
                }
            }
        }
        .navigationTitle("Guest Mode")
        .onAppear {
            AppLogger.screen("GuestMode", metadata: ["mode": profileStore.isGuestModeActive ? "guest" : "personal"])
        }
    }
}

struct GuestModeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            GuestModeView()
                .environmentObject(ProfileStore())
        }
    }
}
