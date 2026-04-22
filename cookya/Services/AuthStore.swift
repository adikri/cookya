import SwiftUI
import Combine
import Supabase

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var session: Session?
    @Published private(set) var isLoading = true

    var isAuthenticated: Bool { session != nil }

    enum AuthError: LocalizedError {
        case confirmationRequired
        var errorDescription: String? {
            switch self {
            case .confirmationRequired:
                return "confirmation_required"
            }
        }
    }

    private var client: SupabaseClient { SupabaseManager.shared.client }

    init() {
        Task { await restoreSession() }
    }

    func signIn(email: String, password: String) async throws {
        let authSession = try await client.auth.signIn(email: email, password: password)
        session = authSession
        AppLogger.action("auth_sign_in_succeeded", metadata: ["userId": authSession.user.id.uuidString])
    }

    func signUp(email: String, password: String) async throws {
        let response = try await client.auth.signUp(email: email, password: password)
        if let s = response.session {
            session = s
            AppLogger.action("auth_sign_up_succeeded", metadata: ["userId": response.user.id.uuidString])
        } else {
            // Supabase requires email confirmation — sign-up queued
            AppLogger.action("auth_sign_up_confirmation_required", metadata: ["userId": response.user.id.uuidString])
            throw AuthError.confirmationRequired
        }
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
