import XCTest
@testable import cookya

@MainActor
final class OpenAIRecipeServiceTests: XCTestCase {

    override func tearDown() {
        URLProtocolStub.handler = nil
        super.tearDown()
    }

    func testGenerateRecipeSuccessDecodesRecipe() async throws {
        let jsonContent = """
        {"title":"Egg Bowl","ingredients":[{"name":"Egg","quantity":"2"}],"instructions":["Cook"],"calories":320,"difficulty":"easy"}
        """
        let responseObject: [String: Any] = [
            "choices": [
                [
                    "message": [
                        "content": jsonContent
                    ]
                ]
            ]
        ]
        let body = try JSONSerialization.data(withJSONObject: responseObject)

        URLProtocolStub.handler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://api.openai.com/v1/chat/completions")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                body
            )
        }

        let service = OpenAIRecipeService(
            session: makeStubbedSession(),
            config: AppConfig(openAIAPIKey: "test-key", openAIBaseURL: URL(string: "https://api.openai.com")!, openAIModel: "gpt-4.1-mini", backendBaseURL: nil)
        )

        let recipe = try await service.generateRecipe(
            request: RecipeGenerationRequest(
                pantrySelections: [],
                manualIngredients: [Ingredient(name: "Egg")],
                difficulty: .easy,
                servings: 1,
                profile: nil,
                prioritizedIngredients: []
            )
        )

        let title = recipe.title
        let firstIngredientName = recipe.ingredients.first?.name
        let difficulty = recipe.difficulty

        XCTAssertEqual(title, "Egg Bowl")
        XCTAssertEqual(firstIngredientName, "Egg")
        XCTAssertEqual(difficulty, .easy)
    }

    func testGenerateRecipeMalformedModelContentThrowsDecodingFailed() async {
        let body = """
        {"choices":[{"message":{"content":"not-json"}}]}
        """

        URLProtocolStub.handler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://api.openai.com/v1/chat/completions")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data(body.utf8)
            )
        }

        let service = OpenAIRecipeService(
            session: makeStubbedSession(),
            config: AppConfig(openAIAPIKey: "test-key", openAIBaseURL: URL(string: "https://api.openai.com")!, openAIModel: "gpt-4.1-mini", backendBaseURL: nil)
        )

        do {
            _ = try await service.generateRecipe(
                request: RecipeGenerationRequest(
                    pantrySelections: [],
                    manualIngredients: [Ingredient(name: "Egg")],
                    difficulty: .easy,
                    servings: 1,
                    profile: nil,
                    prioritizedIngredients: []
                )
            )
            XCTFail("Expected decodingFailed")
        } catch let error as RecipeGenerationError {
            XCTAssertEqual(error, .decodingFailed)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGenerateRecipeRateLimitedThrowsRateLimited() async {
        URLProtocolStub.handler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://api.openai.com/v1/chat/completions")!,
                    statusCode: 429,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data()
            )
        }

        let service = OpenAIRecipeService(
            session: makeStubbedSession(),
            config: AppConfig(openAIAPIKey: "test-key", openAIBaseURL: URL(string: "https://api.openai.com")!, openAIModel: "gpt-4.1-mini", backendBaseURL: nil)
        )

        do {
            _ = try await service.generateRecipe(
                request: RecipeGenerationRequest(
                    pantrySelections: [],
                    manualIngredients: [Ingredient(name: "Egg")],
                    difficulty: .easy,
                    servings: 1,
                    profile: nil,
                    prioritizedIngredients: []
                )
            )
            XCTFail("Expected rateLimited")
        } catch let error as RecipeGenerationError {
            XCTAssertEqual(error, .rateLimited)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGenerateRecipeNetworkFailureThrowsNetworkError() async {
        URLProtocolStub.handler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let service = OpenAIRecipeService(
            session: makeStubbedSession(),
            config: AppConfig(openAIAPIKey: "test-key", openAIBaseURL: URL(string: "https://api.openai.com")!, openAIModel: "gpt-4.1-mini", backendBaseURL: nil)
        )

        do {
            _ = try await service.generateRecipe(
                request: RecipeGenerationRequest(
                    pantrySelections: [],
                    manualIngredients: [Ingredient(name: "Egg")],
                    difficulty: .easy,
                    servings: 1,
                    profile: nil,
                    prioritizedIngredients: []
                )
            )
            XCTFail("Expected networkError")
        } catch let error as RecipeGenerationError {
            XCTAssertEqual(error, .networkError)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func makeStubbedSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: config)
    }
}

private final class URLProtocolStub: URLProtocol {
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
