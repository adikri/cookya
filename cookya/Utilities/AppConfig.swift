import Foundation

struct AppConfig {
    let openAIAPIKey: String
    let openAIBaseURL: URL
    let openAIModel: String
    let backendBaseURL: URL?

    nonisolated static var live: AppConfig {
        let env = ProcessInfo.processInfo.environment
        let bundledSecrets = bundledSecretsDictionary()

        let apiKey = firstValid(
            env["OPENAI_API_KEY"],
            bundledSecrets["OPENAI_API_KEY"],
            Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String
        ) ?? ""

        let baseURLString = firstValid(
            env["OPENAI_BASE_URL"],
            bundledSecrets["OPENAI_BASE_URL"],
            Bundle.main.object(forInfoDictionaryKey: "OPENAI_BASE_URL") as? String
        )

        let model = firstValid(
            env["OPENAI_MODEL"],
            bundledSecrets["OPENAI_MODEL"],
            Bundle.main.object(forInfoDictionaryKey: "OPENAI_MODEL") as? String
        ) ?? "gpt-4.1-mini"

        let backendBaseURLString = firstValid(
            env["COOKYA_BACKEND_BASE_URL"],
            bundledSecrets["COOKYA_BACKEND_BASE_URL"],
            Bundle.main.object(forInfoDictionaryKey: "COOKYA_BACKEND_BASE_URL") as? String
        )

        let resolvedOpenAIBaseURL = resolvedOpenAIBaseURL(from: baseURLString)
        let resolvedBackendBaseURL = resolvedBackendBaseURL(from: backendBaseURLString)

        return AppConfig(
            openAIAPIKey: apiKey,
            openAIBaseURL: resolvedOpenAIBaseURL,
            openAIModel: model,
            backendBaseURL: resolvedBackendBaseURL
        )
    }

    nonisolated private static func firstValid(_ values: String?...) -> String? {
        for value in values {
            guard let value else { continue }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            if trimmed == "Debug" || trimmed == "Release" || trimmed == "$(OPENAI_API_KEY)" { continue }
            return trimmed
        }
        return nil
    }

    nonisolated private static func bundledSecretsDictionary() -> [String: String] {
        guard let url = Bundle.main.url(forResource: "LocalSecrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String]
        else {
            return [:]
        }

        return plist
    }

    nonisolated private static func resolvedOpenAIBaseURL(from rawValue: String?) -> URL {
        let defaultURL = URL(string: "https://api.openai.com")!
        guard let rawValue else { return defaultURL }

        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "https:" || trimmed == "http:" {
            return defaultURL
        }

        return URL(string: trimmed) ?? defaultURL
    }

    nonisolated private static func resolvedBackendBaseURL(from rawValue: String?) -> URL? {
        guard let rawValue else { return nil }

        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "https:" || trimmed == "http:" {
            return nil
        }

        return URL(string: trimmed)
    }
}
