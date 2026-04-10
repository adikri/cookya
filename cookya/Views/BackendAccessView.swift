import SwiftUI

struct BackendAccessView: View {
    @State private var tokenInput: String = BackendAuthToken.load() ?? ""
    @State private var statusMessage: String?

    var body: some View {
        Form {
            Section {
                SecureField("Backend app token", text: $tokenInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Backend")
            } footer: {
                Text("This token is stored on-device in Keychain and used to authorize recipe generation requests to your backend relay.")
            }

            Section {
                Button("Save token") {
                    if BackendAuthToken.save(tokenInput) {
                        statusMessage = "Saved."
                    } else {
                        statusMessage = "Could not save token."
                    }
                }

                Button("Clear token", role: .destructive) {
                    _ = BackendAuthToken.clear()
                    tokenInput = ""
                    statusMessage = "Cleared."
                }
            }

            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Backend Access")
        .onAppear {
            AppLogger.screen("BackendAccess")
        }
    }
}

#Preview {
    NavigationStack {
        BackendAccessView()
    }
}

