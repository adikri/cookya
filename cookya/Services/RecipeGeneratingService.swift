import Foundation

protocol RecipeGeneratingService {
    func generateRecipe(request: RecipeGenerationRequest) async throws -> Recipe
}

enum RecipeGenerationError: LocalizedError, Equatable {
    case missingAPIKey
    case missingBackendURL
    case networkError
    case invalidResponse
    case decodingFailed
    case rateLimited
    case serverError(code: Int, message: String?)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is missing. Add OPENAI_API_KEY in your local config."
        case .missingBackendURL:
            return "Backend URL is missing. Add COOKYA_BACKEND_BASE_URL in your local config."
        case .networkError:
            return "Network error. Check your internet connection and try again."
        case .invalidResponse:
            return "The API returned an unexpected response."
        case .decodingFailed:
            return "Could not decode recipe output from the model."
        case .rateLimited:
            return "Rate limit reached. Please wait and try again."
        case let .serverError(code, message):
            if let message, !message.isEmpty {
                return "Server error (\(code)): \(message)"
            }
            return "Server error (\(code))."
        case .cancelled:
            return "Request was cancelled."
        }
    }
}
