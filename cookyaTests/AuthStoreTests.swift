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
}

// MARK: - MockAuthService

private final class MockAuthService: AuthServiceProtocol {
    private let signInResult: Result<Session, Error>
    private let signUpResult: Result<AuthResponse, Error>
    private let signOutError: Error?
    private let sessionResult: Result<Session, Error>

    init(
        signInResult: Result<Session, Error> = .failure(URLError(.userAuthenticationRequired)),
        signUpResult: Result<AuthResponse, Error> = .failure(URLError(.badServerResponse)),
        signOutError: Error? = nil,
        sessionResult: Result<Session, Error> = .failure(URLError(.userAuthenticationRequired))
    ) {
        self.signInResult = signInResult
        self.signUpResult = signUpResult
        self.signOutError = signOutError
        self.sessionResult = sessionResult
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
        accessToken: "test-access-token",
        tokenType: "bearer",
        expiresIn: 3600,
        expiresAt: Date().timeIntervalSince1970 + 3600,
        refreshToken: "test-refresh-token",
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
