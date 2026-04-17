import XCTest
@testable import cookya

@MainActor
final class BackendInventoryServiceTests: XCTestCase {
    func testFetchPantryThrowsMissingAuthTokenWhenTokenProviderIsEmpty() async {
        let service = BackendInventoryService(
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
            _ = try await service.fetchPantry()
            XCTFail("Expected missingAuthToken")
        } catch let error as InventorySyncError {
            XCTAssertEqual(error, .missingAuthToken)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func makeStubbedSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        return URLSession(configuration: config)
    }
}
