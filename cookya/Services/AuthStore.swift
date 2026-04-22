import SwiftUI
import Supabase

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var session: Session?
    @Published private(set) var isLoading = true

    var isAuthenticated: Bool { session != nil }

    private var client: SupabaseClient { SupabaseManager.shared.client }

    init() {
        Task { await restoreSession() }
    }

    func signIn(email: String, password: String) async throws {
        let response = try await client.auth.signIn(email: email, password: password)
        session = response.session
        AppLogger.action("auth_sign_in_succeeded", metadata: ["userId": response.user.id.uuidString])
    }

    func signUp(email: String, password: String) async throws {
        let response = try await client.auth.signUp(email: email, password: password)
        session = response.session
        AppLogger.action("auth_sign_up_succeeded", metadata: ["userId": response.user.id.uuidString])
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
            session = nil
            AppLogger.action("auth_sign_out_succeeded")
        } catch {
            AppLogger.action("auth_sign_out_failed", metadata: ["error": String(describing: error)])
        }
    }

    private func restoreSession() async {
        defer { isLoading = false }
        do {
            session = try await client.auth.session
            if let session {
                AppLogger.action("auth_session_restored", metadata: ["userId": session.user.id.uuidString])
            }
        } catch {
            session = nil
        }
    }
}
