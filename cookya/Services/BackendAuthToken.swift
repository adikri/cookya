import Foundation

enum BackendAuthToken {
    private static let service = "cookya.backend"
    private static let account = "appToken"

    static func load() -> String? {
        KeychainStore.readString(service: service, account: account)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @discardableResult
    static func save(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return KeychainStore.upsertString(trimmed, service: service, account: account)
    }

    @discardableResult
    static func clear() -> Bool {
        KeychainStore.delete(service: service, account: account)
    }
}

