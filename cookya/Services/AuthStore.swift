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

    private let authService: any AuthServiceProtocol
    private(set) var sessionRestoreTask: Task<Void, Never>!
    private var authStateObservationTask: Task<Void, Never>?

    init(authService: (any AuthServiceProtocol)? = nil) {
        self.authService = authService ?? LiveAuthService(SupabaseManager.shared.client.auth)
        authStateObservationTask = Task { await observeAuthStateChanges() }
        sessionRestoreTask = Task { await restoreSession() }
    }

    deinit {
        sessionRestoreTask?.cancel()
        authStateObservationTask?.cancel()
    }

    func signIn(email: String, password: String) async throws {
        let authSession = try await authService.signIn(email: email, password: password)
        session = authSession
        AppLogger.action("auth_sign_in_succeeded", metadata: ["userId": authSession.user.id.uuidString])
    }

    func signUp(email: String, password: String) async throws {
        let response = try await authService.signUp(email: email, password: password)
        if let s = response.session {
            session = s
            AppLogger.action("auth_sign_up_succeeded", metadata: ["userId": response.user.id.uuidString])
        } else {
            AppLogger.action("auth_sign_up_confirmation_required", metadata: ["userId": response.user.id.uuidString])
            throw AuthError.confirmationRequired
        }
    }

    func signOut() async {
        do {
            try await authService.signOut()
            AppLogger.action("auth_sign_out_succeeded")
        } catch {
            AppLogger.action("auth_sign_out_failed", metadata: ["error": String(describing: error)])
        }
        session = nil
    }

    private func restoreSession() async {
        defer { isLoading = false }
        do {
            session = try await authService.currentSession()
            if let session {
                AppLogger.action("auth_session_restored", metadata: ["userId": session.user.id.uuidString])
            }
        } catch {
            session = nil
        }
    }

    private func observeAuthStateChanges() async {
        for await state in authService.authStateChanges {
            switch state.event {
            case .initialSession:
                continue
            case .signedIn, .tokenRefreshed, .userUpdated, .passwordRecovery, .mfaChallengeVerified:
                session = state.session
                if let session = state.session {
                    AppLogger.action(
                        "auth_state_changed",
                        metadata: ["event": state.event.rawValue, "userId": session.user.id.uuidString]
                    )
                } else {
                    AppLogger.action("auth_state_changed", metadata: ["event": state.event.rawValue])
                }
            case .signedOut, .userDeleted:
                session = nil
                AppLogger.action("auth_state_changed", metadata: ["event": state.event.rawValue])
            }
        }
    }
}
