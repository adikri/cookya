import XCTest
import Supabase
@testable import cookya

@MainActor
final class AuthStoreTests: XCTestCase {

    // MARK: - signIn

    func testSignInSuccessSetsSession() async throws {
        let expectedSession = makeSession()
        let mock = MockAuthService(signInResult: .success(expectedSession))
        let store = AuthStore(authService: mock)
        await store.sessionRestoreTask.value

        try await store.signIn(email: "a@b.com", password: "pass")

        XCTAssertEqual(store.session?.user.id, expectedSession.user.id)
        XCTAssertTrue(store.isAuthenticated)
    }

    func testSignInFailureLeavesSessionNil() async {
        let mock = MockAuthService(signInResult: .failure(URLError(.badServerResponse)))
        let store = AuthStore(authService: mock)
        await store.sessionRestoreTask.value

        do {
            try await store.signIn(email: "a@b.com", password: "bad")
            XCTFail("Expected error")
        } catch {
            XCTAssertNil(store.session)
            XCTAssertFalse(store.isAuthenticated)
        }
    }

    // MARK: - signUp

    func testSignUpWithSessionSetsSession() async throws {
        let session = makeSession()
        let response = makeAuthResponse(session: session)
        let mock = MockAuthService(signUpResult: .success(response))
        let store = AuthStore(authService: mock)
        await store.sessionRestoreTask.value

        try await store.signUp(email: "a@b.com", password: "pass")

        XCTAssertEqual(store.session?.user.id, session.user.id)
        XCTAssertTrue(store.isAuthenticated)
    }

    func testSignUpWithoutSessionThrowsConfirmationRequired() async {
        let response = makeAuthResponse(session: nil)
        let mock = MockAuthService(signUpResult: .success(response))
        let store = AuthStore(authService: mock)
        await store.sessionRestoreTask.value

        do {
            try await store.signUp(email: "a@b.com", password: "pass")
            XCTFail("Expected confirmationRequired")
        } catch AuthStore.AuthError.confirmationRequired {
            XCTAssertNil(store.session)
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    func testSignUpNetworkFailurePropagatesError() async {
        let mock = MockAuthService(signUpResult: .failure(URLError(.notConnectedToInternet)))
        let store = AuthStore(authService: mock)
        await store.sessionRestoreTask.value

        do {
            try await store.signUp(email: "a@b.com", password: "pass")
            XCTFail("Expected error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
            XCTAssertNil(store.session)
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    // MARK: - signOut

    func testSignOutClearsSession() async throws {
        let session = makeSession()
        let mock = MockAuthService(sessionResult: .success(session))
        let store = AuthStore(authService: mock)
        await store.sessionRestoreTask.value
        XCTAssertNotNil(store.session)

        await store.signOut()

        XCTAssertNil(store.session)
        XCTAssertFalse(store.isAuthenticated)
    }

    func testSignOutSwallowsServiceError() async {
        let session = makeSession()
        let mock = MockAuthService(
            signOutError: URLError(.badServerResponse),
            sessionResult: .success(session)
        )
        let store = AuthStore(authService: mock)
        await store.sessionRestoreTask.value

        await store.signOut()

        XCTAssertNil(store.session)
    }

    // MARK: - session restore

    func testRestoreSessionSuccessSetsSession() async {
        let session = makeSession()
        let mock = MockAuthService(sessionResult: .success(session))
        let store = AuthStore(authService: mock)
        await store.sessionRestoreTask.value

        XCTAssertEqual(store.session?.user.id, session.user.id)
        XCTAssertFalse(store.isLoading)
    }

    func testRestoreSessionFailureLeavesSessionNil() async {
        let mock = MockAuthService(sessionResult: .failure(URLError(.userAuthenticationRequired)))
        let store = AuthStore(authService: mock)
        await store.sessionRestoreTask.value

        XCTAssertNil(store.session)
        XCTAssertFalse(store.isLoading)
    }

    func testIsLoadingFalseAfterRestore() async {
        let mock = MockAuthService(sessionResult: .failure(URLError(.userAuthenticationRequired)))
        let store = AuthStore(authService: mock)
        await store.sessionRestoreTask.value

        XCTAssertFalse(store.isLoading)
    }

    // MARK: - auth state changes

    func testAuthStateSignedInAfterLaunchSetsSession() async {
        let mock = MockAuthService(sessionResult: .failure(URLError(.userAuthenticationRequired)))
        let store = AuthStore(authService: mock)
        await store.sessionRestoreTask.value

        let session = makeSession()
        mock.emitAuthStateChange(event: .signedIn, session: session)
        await drainObservers()

        XCTAssertEqual(store.session?.user.id, session.user.id)
        XCTAssertTrue(store.isAuthenticated)
    }

    func testAuthStateSignedOutAfterLaunchClearsSession() async {
        let session = makeSession()
        let mock = MockAuthService(sessionResult: .success(session))
        let store = AuthStore(authService: mock)
        await store.sessionRestoreTask.value
        XCTAssertNotNil(store.session)

        mock.emitAuthStateChange(event: .signedOut, session: nil)
        await drainObservers()

        XCTAssertNil(store.session)
        XCTAssertFalse(store.isAuthenticated)
    }

    func testAuthStateTokenRefreshedReplacesSession() async {
        let oldSession = makeSession(userId: UUID())
        let newSession = makeSession(userId: oldSession.user.id)
        let mock = MockAuthService(sessionResult: .success(oldSession))
        let store = AuthStore(authService: mock)
        await store.sessionRestoreTask.value

        mock.emitAuthStateChange(event: .tokenRefreshed, session: newSession)
        await drainObservers()

        XCTAssertEqual(store.session?.accessToken, newSession.accessToken)
        XCTAssertEqual(store.session?.refreshToken, newSession.refreshToken)
    }
}

// MARK: - Helpers

// A single Task.yield() is not always enough for `for await` on AsyncStream
// to deliver a buffered event through the MainActor scheduler. Three cycles
// reliably covers the scheduling latency without introducing a wall-clock delay.
@MainActor
private func drainObservers() async {
    for _ in 0..<3 { await Task.yield() }
}

// MARK: - MockAuthService

private final class MockAuthService: AuthServiceProtocol {
    private let signInResult: Result<Session, Error>
    private let signUpResult: Result<AuthResponse, Error>
    private let signOutError: Error?
    private let sessionResult: Result<Session, Error>
    private let authStateChangesStream: AsyncStream<(event: AuthChangeEvent, session: Session?)>
    private let authStateChangesContinuation: AsyncStream<(event: AuthChangeEvent, session: Session?)>.Continuation

    init(
        signInResult: Result<Session, Error> = .failure(URLError(.userAuthenticationRequired)),
        signUpResult: Result<AuthResponse, Error> = .failure(URLError(.badServerResponse)),
        signOutError: Error? = nil,
        sessionResult: Result<Session, Error> = .failure(URLError(.userAuthenticationRequired))
    ) {
        let (stream, continuation) = AsyncStream<(event: AuthChangeEvent, session: Session?)>.makeStream()
        self.authStateChangesStream = stream
        self.authStateChangesContinuation = continuation
        self.signInResult = signInResult
        self.signUpResult = signUpResult
        self.signOutError = signOutError
        self.sessionResult = sessionResult
    }

    var authStateChanges: AsyncStream<(event: AuthChangeEvent, session: Session?)> {
        authStateChangesStream
    }

    func signIn(email: String, password: String) async throws -> Session {
        try signInResult.get()
    }

    func signUp(email: String, password: String) async throws -> AuthResponse {
        try signUpResult.get()
    }

    func signOut() async throws {
        if let error = signOutError { throw error }
    }

    func currentSession() async throws -> Session {
        try sessionResult.get()
    }

    func emitAuthStateChange(event: AuthChangeEvent, session: Session?) {
        authStateChangesContinuation.yield((event: event, session: session))
    }
}

// MARK: - Factories

private func makeUser(id: UUID = UUID()) -> User {
    User(
        id: id,
        appMetadata: [:],
        userMetadata: [:],
        aud: "authenticated",
        createdAt: Date(timeIntervalSince1970: 0),
        updatedAt: Date(timeIntervalSince1970: 0)
    )
}

private func makeSession(userId: UUID = UUID()) -> Session {
    Session(
        accessToken: "test-access-token-\(UUID().uuidString)",
        tokenType: "bearer",
        expiresIn: 3600,
        expiresAt: Date().timeIntervalSince1970 + 3600,
        refreshToken: "test-refresh-token-\(UUID().uuidString)",
        user: makeUser(id: userId)
    )
}

private func makeAuthResponse(session: Session?) -> AuthResponse {
    if let session {
        return .session(session)
    } else {
        return .user(makeUser())
    }
}
