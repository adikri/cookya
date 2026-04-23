import Foundation

struct BackendSnapshotService: SnapshotSyncingService {
    private let session: URLSession
    private let config: AppConfig
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, config: AppConfig = .live) {
        self.session = session
        self.config = config

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func fetchLatest() async throws -> CookyaExportBackup {
        guard let baseURL = config.backendBaseURL else { throw SnapshotSyncError.notAuthenticated }
        guard let token = BackendAuthToken.load(), !token.isEmpty else { throw SnapshotSyncError.notAuthenticated }
        guard let url = URL(string: "/v1/snapshot", relativeTo: baseURL)?.absoluteURL else {
            throw SnapshotSyncError.networkError
        }

        AppLogger.action("snapshot_fetch_started", screen: "BackendSnapshotService")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw SnapshotSyncError.networkError }

            if http.statusCode == 404 {
                AppLogger.action("snapshot_fetch_not_found", screen: "BackendSnapshotService")
                throw SnapshotSyncError.notFound
            }

            guard (200...299).contains(http.statusCode) else {
                AppLogger.action("snapshot_fetch_server_error", screen: "BackendSnapshotService", metadata: ["statusCode": String(http.statusCode)])
                throw SnapshotSyncError.networkError
            }

            do {
                let backup = try decoder.decode(CookyaExportBackup.self, from: data)
                AppLogger.action("snapshot_fetch_succeeded", screen: "BackendSnapshotService")
                return backup
            } catch {
                AppLogger.action("snapshot_fetch_decode_failed", screen: "BackendSnapshotService")
                throw SnapshotSyncError.decodingFailed
            }
        } catch let e as SnapshotSyncError {
            throw e
        } catch {
            AppLogger.action("snapshot_fetch_network_error", screen: "BackendSnapshotService", metadata: ["error": String(describing: error)])
            throw SnapshotSyncError.networkError
        }
    }

    func upsertLatest(_ backup: CookyaExportBackup) async throws {
        guard let baseURL = config.backendBaseURL else { throw SnapshotSyncError.notAuthenticated }
        guard let token = BackendAuthToken.load(), !token.isEmpty else { throw SnapshotSyncError.notAuthenticated }
        guard let url = URL(string: "/v1/snapshot", relativeTo: baseURL)?.absoluteURL else {
            throw SnapshotSyncError.networkError
        }

        AppLogger.action("snapshot_upsert_started", screen: "BackendSnapshotService")

        let data = try encoder.encode(backup)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = data

        do {
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw SnapshotSyncError.networkError }
            guard (200...299).contains(http.statusCode) else {
                AppLogger.action("snapshot_upsert_server_error", screen: "BackendSnapshotService", metadata: ["statusCode": String(http.statusCode)])
                throw SnapshotSyncError.networkError
            }
            AppLogger.action("snapshot_upsert_succeeded", screen: "BackendSnapshotService")
        } catch let e as SnapshotSyncError {
            throw e
        } catch {
            AppLogger.action("snapshot_upsert_network_error", screen: "BackendSnapshotService", metadata: ["error": String(describing: error)])
            throw SnapshotSyncError.networkError
        }
    }
}
