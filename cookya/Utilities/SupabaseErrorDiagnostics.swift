import Foundation

enum SupabaseErrorDiagnostics {
    static func inventorySyncError(from error: Error) -> InventorySyncError {
        if let inventoryError = error as? InventorySyncError {
            return inventoryError
        }
        if error is CancellationError {
            return .cancelled
        }
        if error is DecodingError {
            return .decodingFailed
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return nsError.code == NSURLErrorCancelled ? .cancelled : .networkError
        }
        if nsError.domain == "Swift.CancellationError" {
            return .cancelled
        }

        return .networkError
    }

    static func snapshotSyncError(from error: Error) -> SnapshotSyncError {
        if let snapshotError = error as? SnapshotSyncError {
            return snapshotError
        }
        if error is DecodingError {
            return .decodingFailed
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .networkError
        }

        return .networkError
    }

    static func metadata(for error: Error) -> [String: String] {
        let nsError = error as NSError
        return [
            "errorType": String(reflecting: type(of: error)),
            "error": String(describing: error),
            "localizedDescription": nsError.localizedDescription,
            "domain": nsError.domain,
            "code": String(nsError.code)
        ]
    }
}
