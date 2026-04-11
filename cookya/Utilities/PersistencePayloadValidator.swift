import Foundation

enum PersistencePayloadShape {
    case array
    case object
}

enum PersistencePayloadValidator {
    static func matchesExpectedTopLevel(_ data: Data, shape: PersistencePayloadShape) -> Bool {
        guard let value = try? JSONSerialization.jsonObject(with: data) else {
            return false
        }

        switch shape {
        case .array:
            return value is [Any]
        case .object:
            return value is [String: Any]
        }
    }
}
