import Foundation

struct AppConfig {
    let openAIAPIKey: String
    let openAIBaseURL: URL
    let openAIModel: String

    static var live: AppConfig {
        let env = ProcessInfo.processInfo.environment

        let apiKey = firstNonEmpty(
            env["OPENAI_API_KEY"],
            Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String
        ) ?? ""

        let baseURLString = firstNonEmpty(
            env["OPENAI_BASE_URL"],
            Bundle.main.object(forInfoDictionaryKey: "OPENAI_BASE_URL") as? String
        ) ?? "https://api.openai.com"

        let model = firstNonEmpty(
            env["OPENAI_MODEL"],
            Bundle.main.object(forInfoDictionaryKey: "OPENAI_MODEL") as? String
        ) ?? "gpt-4.1-mini"

        let trimmedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalModel = trimmedModel.isEmpty ? "gpt-4.1-mini" : trimmedModel

        return AppConfig(
            openAIAPIKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
            openAIBaseURL: URL(string: baseURLString) ?? URL(string: "https://api.openai.com")!,
            openAIModel: finalModel
        )
    }

    private static func firstNonEmpty(_ values: String?...) -> String? {
        for value in values {
            if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
        }
        return nil
    }
}
