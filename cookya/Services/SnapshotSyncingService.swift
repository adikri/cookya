import Foundation

protocol SnapshotSyncingService {
    func fetchLatest() async throws -> CookyaExportBackup
    func upsertLatest(_ backup: CookyaExportBackup) async throws
}

enum SnapshotSyncError: LocalizedError, Equatable {
    case notAuthenticated   // no session / no backend URL / no auth token
    case notFound           // no snapshot exists for this user
    case networkError       // network failure or server error
    case decodingFailed     // response could not be decoded as CookyaExportBackup

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return nil
        case .notFound:         return nil
        case .networkError:     return "Could not reach backup service."
        case .decodingFailed:   return "Could not decode backup data."
        }
    }
}
