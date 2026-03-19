import Foundation

struct OpenAIRecipeService: RecipeGeneratingService {
    private let session: URLSession
    private let config: AppConfig

    nonisolated init(session: URLSession = .shared, config: AppConfig = .live) {
        self.session = session
        self.config = config
    }

    func generateRecipe(request generationRequest: RecipeGenerationRequest) async throws -> Recipe {
        guard !config.openAIAPIKey.isEmpty else {
            throw RecipeGenerationError.missingAPIKey
        }

        let endpoint = URL(string: "v1/chat/completions", relativeTo: config.openAIBaseURL)?.absoluteURL
        guard let endpoint else {
            throw RecipeGenerationError.invalidResponse
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.openAIAPIKey)", forHTTPHeaderField: "Authorization")

        let body = buildRequestBody(request: generationRequest)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw RecipeGenerationError.invalidResponse
            }

            guard (200 ... 299).contains(http.statusCode) else {
                if http.statusCode == 429 {
                    throw RecipeGenerationError.rateLimited
                }

                let apiError = try? JSONDecoder().decode(OpenAIAPIErrorResponse.self, from: data)
                throw RecipeGenerationError.serverError(code: http.statusCode, message: apiError?.error.message)
            }

            let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            guard let content = completion.choices.first?.message.content,
                  let contentData = content.data(using: .utf8)
            else {
                throw RecipeGenerationError.invalidResponse
            }

            do {
                return try JSONDecoder().decode(Recipe.self, from: contentData)
            } catch {
                throw RecipeGenerationError.decodingFailed
            }
        } catch let error as RecipeGenerationError {
            throw error
        } catch is CancellationError {
            throw RecipeGenerationError.cancelled
        } catch {
            throw RecipeGenerationError.networkError
        }
    }

    private func buildRequestBody(request: RecipeGenerationRequest) -> [String: Any] {
        let ingredientRows: [[String: String]] = request.allIngredients.map {
            [
                "name": $0.name,
                "quantity": $0.quantity
            ]
        }

        let pantryRows = request.pantrySelections.map { selection in
            [
                "name": selection.pantryItem.name,
                "availableQuantity": selection.pantryItem.quantityText,
                "selectedQuantity": selection.selectedQuantityText.isEmpty ? "not specified" : selection.selectedQuantityText,
                "category": selection.pantryItem.category.rawValue,
                "expiryDate": selection.pantryItem.expiryDate?.formatted(date: .abbreviated, time: .omitted) ?? "none"
            ]
        }

        let prioritizedIngredients = request.prioritizedIngredients.map(\.name).joined(separator: ", ")
        let avoidFoods = request.profile?.avoidFoodItems.joined(separator: ", ") ?? "none"
        let location = request.profile?.location ?? "not provided"
        let dietary = request.profile?.isVegetarian == true ? "vegetarian" : "no vegetarian restriction"

        let userPrompt = """
        Create one home-cooking recipe using these ingredients and requested difficulty.

        Ingredients:
        \(ingredientRows)

        Pantry context:
        \(pantryRows)

        Difficulty: \(request.difficulty.rawValue)
        Servings: \(request.servings)
        Dietary preference: \(dietary)
        Avoid foods/allergens: \(avoidFoods)
        Location context: \(location)
        Prioritize these ingredients first if possible: \(prioritizedIngredients.isEmpty ? "none" : prioritizedIngredients)

        Hard constraints:
        - Never include any avoid foods.
        - If vegetarian is requested, do not include meat, fish, or seafood.
        - Keep recipe realistic for home cooking.
        - Prefer expiring pantry items when they fit naturally.
        - Make the recipe suitable for exactly \(request.servings) serving(s).
        - If a selected pantry quantity is provided, treat it as the target amount to use for that ingredient.

        Output only JSON matching the schema exactly.
        """

        return [
            "model": config.openAIModel,
            "messages": [
                [
                    "role": "system",
                    "content": "You are a recipe assistant. Return only strict JSON that follows the provided schema. No markdown, no extra text."
                ],
                [
                    "role": "user",
                    "content": userPrompt
                ]
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "recipe_response",
                    "strict": true,
                    "schema": [
                        "type": "object",
                        "additionalProperties": false,
                        "required": ["title", "ingredients", "instructions", "calories", "difficulty"],
                        "properties": [
                            "title": ["type": "string"],
                            "ingredients": [
                                "type": "array",
                                "items": [
                                    "type": "object",
                                    "additionalProperties": false,
                                    "required": ["name", "quantity"],
                                    "properties": [
                                        "name": ["type": "string"],
                                        "quantity": ["type": "string"]
                                    ]
                                ]
                            ],
                            "instructions": [
                                "type": "array",
                                "items": ["type": "string"],
                                "minItems": 1
                            ],
                            "calories": ["type": "integer", "minimum": 0],
                            "difficulty": ["type": "string", "enum": ["easy", "medium", "hard"]]
                        ]
                    ]
                ]
            ]
        ]
    }
}

private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String?
    }
}

private struct OpenAIAPIErrorResponse: Decodable {
    let error: APIError

    struct APIError: Decodable {
        let message: String
    }
}
