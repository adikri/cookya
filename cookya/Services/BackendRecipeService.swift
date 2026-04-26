import Foundation

struct BackendRecipeService: RecipeGeneratingService {
    private let session: URLSession
    private let config: AppConfig
    private let decoder: JSONDecoder

    nonisolated init(
        session: URLSession = .shared,
        config: AppConfig = .live
    ) {
        self.session = session
        self.config = config
        self.decoder = JSONDecoder()
    }

    func generateRecipe(request: RecipeGenerationRequest) async throws -> Recipe {
        guard let baseURL = config.backendBaseURL else {
            AppLogger.action("recipe_generation_fallback", screen: "BackendRecipeService", metadata: ["reason": "no_backend_url"])
            return try await fallbackRecipeService.generateRecipe(request: request)
        }

        guard let endpoint = URL(string: "/v1/recipes/generate", relativeTo: baseURL)?.absoluteURL else {
            throw RecipeGenerationError.invalidResponse
        }

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = BackendAuthToken.load(), !token.isEmpty {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        urlRequest.httpBody = try JSONEncoder().encode(BackendRecipeRequest(from: request))

        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let http = response as? HTTPURLResponse else {
                throw RecipeGenerationError.invalidResponse
            }

            guard (200 ... 299).contains(http.statusCode) else {
                let apiError = try? decoder.decode(BackendErrorResponse.self, from: data)
                AppLogger.action("recipe_generation_server_error", screen: "BackendRecipeService", metadata: [
                    "statusCode": String(http.statusCode),
                    "message": apiError?.error.message ?? ""
                ])
                throw RecipeGenerationError.serverError(code: http.statusCode, message: apiError?.error.message)
            }

            do {
                let recipe = try decoder.decode(Recipe.self, from: data)
                AppLogger.action("recipe_generation_succeeded", screen: "BackendRecipeService", metadata: ["title": recipe.title])
                return recipe
            } catch {
                AppLogger.action("recipe_generation_decode_failed", screen: "BackendRecipeService")
                throw RecipeGenerationError.decodingFailed
            }
        } catch is CancellationError {
            throw RecipeGenerationError.cancelled
        } catch let error as URLError where shouldFallbackToOpenAI(error) {
            AppLogger.action("recipe_generation_fallback", screen: "BackendRecipeService", metadata: ["reason": "network_error", "code": String(error.code.rawValue)])
            return try await fallbackRecipeService.generateRecipe(request: request)
        } catch let error as RecipeGenerationError {
            throw error
        } catch {
            throw RecipeGenerationError.networkError
        }
    }

    private var fallbackRecipeService: OpenAIRecipeService {
        OpenAIRecipeService(session: session, config: config)
    }

    private func shouldFallbackToOpenAI(_ error: URLError) -> Bool {
        switch error.code {
        case .notConnectedToInternet,
             .networkConnectionLost,
             .cannotConnectToHost,
             .cannotFindHost,
             .timedOut,
             .dnsLookupFailed:
            return true
        default:
            return false
        }
    }
}

private struct BackendNutritionGap: Encodable {
    let remainingCalories: Int
    let remainingProteinG: Int
}

private struct BackendRecipeRequest: Encodable {
    let pantryItems: [BackendPantryItem]
    let manualIngredients: [Ingredient]
    let difficulty: Difficulty
    let servings: Int
    let profile: UserProfile?
    let prioritizedIngredientNames: [String]
    let locationContext: String?
    let nutritionGap: BackendNutritionGap?
    let targetDish: String?

    init(from request: RecipeGenerationRequest) {
        pantryItems = request.pantrySelections.map {
            BackendPantryItem(
                id: $0.pantryItem.id,
                name: $0.pantryItem.name,
                availableQuantityText: $0.pantryItem.quantityText,
                selectedQuantityText: $0.selectedQuantityText,
                category: $0.pantryItem.category,
                expiryDate: $0.pantryItem.expiryDate
            )
        }
        manualIngredients = request.manualIngredients
        difficulty = request.difficulty
        servings = request.servings
        profile = request.profile
        prioritizedIngredientNames = request.prioritizedIngredients.map(\.name)
        locationContext = request.profile?.location
        nutritionGap = request.nutritionGap.map {
            BackendNutritionGap(remainingCalories: $0.remainingCalories, remainingProteinG: $0.remainingProteinG)
        }
        let dish = request.targetDish.trimmingCharacters(in: .whitespacesAndNewlines)
        targetDish = dish.isEmpty ? nil : dish
    }
}

private struct BackendPantryItem: Encodable {
    let id: UUID
    let name: String
    let availableQuantityText: String
    let selectedQuantityText: String
    let category: InventoryCategory
    let expiryDate: Date?
}

private struct BackendErrorResponse: Decodable {
    let error: APIError

    struct APIError: Decodable {
        let message: String
    }
}
