import XCTest
@testable import cookya

@MainActor
final class BackendSnapshotServiceTests: XCTestCase {
    override func tearDown() {
        URLProtocolSnapshotStub.handler = nil
        super.tearDown()
    }

    func testFetchLatestThrowsMissingAuthTokenWhenTokenProviderIsEmpty() async {
        let service = BackendSnapshotService(
            session: makeStubbedSession(),
            config: AppConfig(
                openAIAPIKey: "",
                openAIBaseURL: URL(string: "https://api.openai.com")!,
                openAIModel: "gpt-4.1-mini",
                backendBaseURL: URL(string: "https://cookya.example.com")!
            ),
            tokenProvider: { "" }
        )

        do {
            _ = try await service.fetchLatest()
            XCTFail("Expected missingAuthToken")
        } catch let error as BackendSnapshotService.SnapshotError {
            XCTAssertEqual(error, .missingAuthToken)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchLatestDecodesBackupOnSuccess() async throws {
        let backup = CookyaExportBackup(
            snapshot: AppBackupSnapshot(
                pantryItemsData: Data("pantry".utf8),
                groceryItemsData: nil,
                savedRecipesData: nil,
                cookedMealRecordsData: nil,
                primaryProfileData: nil,
                guestModeActive: nil,
                knownInventoryItemsData: nil
            ),
            appVersion: nil,
            appBuild: nil
        )
        let body = try CookyaBackupCodec.encode(backup)

        URLProtocolSnapshotStub.handler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            return (
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                body
            )
        }

        let service = BackendSnapshotService(
            session: makeStubbedSession(),
            config: AppConfig(
                openAIAPIKey: "",
                openAIBaseURL: URL(string: "https://api.openai.com")!,
                openAIModel: "gpt-4.1-mini",
                backendBaseURL: URL(string: "https://cookya.example.com")!
            ),
            tokenProvider: { "test-token" }
        )

        let decoded = try await service.fetchLatest()
        XCTAssertEqual(decoded.snapshot.pantryItemsData, backup.snapshot.pantryItemsData)
    }

    func testUpsertLatestThrowsNetworkErrorOnTransportFailure() async {
        URLProtocolSnapshotStub.handler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let service = BackendSnapshotService(
            session: makeStubbedSession(),
            config: AppConfig(
                openAIAPIKey: "",
                openAIBaseURL: URL(string: "https://api.openai.com")!,
                openAIModel: "gpt-4.1-mini",
                backendBaseURL: URL(string: "https://cookya.example.com")!
            ),
            tokenProvider: { "test-token" }
        )

        do {
            try await service.upsertLatest(CookyaExportBackup(snapshot: AppBackupSnapshot(
                pantryItemsData: Data("pantry".utf8),
                groceryItemsData: nil,
                savedRecipesData: nil,
                cookedMealRecordsData: nil,
                primaryProfileData: nil,
                guestModeActive: nil,
                knownInventoryItemsData: nil
            )))
            XCTFail("Expected networkError")
        } catch let error as BackendSnapshotService.SnapshotError {
            XCTAssertEqual(error, .networkError)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func makeStubbedSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolSnapshotStub.self]
        return URLSession(configuration: config)
    }
}

private final class URLProtocolSnapshotStub: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
