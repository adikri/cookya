import Supabase

protocol AuthServiceProtocol {
    var authStateChanges: AsyncStream<(event: AuthChangeEvent, session: Session?)> { get }
    func signIn(email: String, password: String) async throws -> Session
    func signUp(email: String, password: String) async throws -> AuthResponse
    func signOut() async throws
    func currentSession() async throws -> Session
}

struct LiveAuthService: AuthServiceProtocol {
    private let authClient: AuthClient

    init(_ authClient: AuthClient) {
        self.authClient = authClient
    }

    var authStateChanges: AsyncStream<(event: AuthChangeEvent, session: Session?)> {
        authClient.authStateChanges
    }

    func signIn(email: String, password: String) async throws -> Session {
        try await authClient.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String) async throws -> AuthResponse {
        try await authClient.signUp(email: email, password: password)
    }

    func signOut() async throws {
        try await authClient.signOut()
    }

    func currentSession() async throws -> Session {
        try await authClient.session
    }
}
