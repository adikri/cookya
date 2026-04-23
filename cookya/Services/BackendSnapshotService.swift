import Foundation

struct BackendSnapshotService {
    enum SnapshotError: LocalizedError, Equatable {
        case missingBackendURL
        case missingAuthToken
        case notFound
        case networkError
        case invalidResponse
        case decodingFailed
        case serverError(code: Int, message: String?)

        var errorDescription: String? {
            switch self {
            case .missingBackendURL:
                return "Missing backend URL."
            case .missingAuthToken:
                return "Missing backend access token."
            case .notFound:
                return "No backup found on backend."
            case .networkError:
                return "Could not reach backend."
            case .invalidResponse:
                return "Backend returned an unexpected response."
            case .decodingFailed:
                return "Could not decode backup data from backend."
            case let .serverError(code, message):
                if let message, !message.isEmpty {
                    return "Backend error (\(code)): \(message)"
                }
                return "Backend error (\(code))."
            }
        }
    }

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
        guard let baseURL = config.backendBaseURL else { throw SnapshotError.missingBackendURL }
        guard let token = BackendAuthToken.load(), !token.isEmpty else { throw SnapshotError.missingAuthToken }
        guard let url = URL(string: "/v1/snapshot", relativeTo: baseURL)?.absoluteURL else {
            throw SnapshotError.invalidResponse
        }

        AppLogger.action("snapshot_fetch_started", screen: "BackendSnapshotService")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw SnapshotError.invalidResponse }

            if http.statusCode == 404 {
                AppLogger.action("snapshot_fetch_not_found", screen: "BackendSnapshotService")
                throw SnapshotError.notFound
            }

            guard (200 ... 299).contains(http.statusCode) else {
                let apiError = try? decoder.decode(APIErrorResponse.self, from: data)
                AppLogger.action("snapshot_fetch_server_error", screen: "BackendSnapshotService", metadata: [
                    "statusCode": String(http.statusCode),
                    "message": apiError?.error.message ?? ""
                ])
                throw SnapshotError.serverError(code: http.statusCode, message: apiError?.error.message)
            }

            do {
                let backup = try decoder.decode(CookyaExportBackup.self, from: data)
                AppLogger.action("snapshot_fetch_succeeded", screen: "BackendSnapshotService")
                return backup
            } catch {
                AppLogger.action("snapshot_fetch_decode_failed", screen: "BackendSnapshotService")
                throw SnapshotError.decodingFailed
            }
        } catch let error as SnapshotError {
            throw error
        } catch {
            AppLogger.action("snapshot_fetch_network_error", screen: "BackendSnapshotService", metadata: ["error": String(describing: error)])
            throw SnapshotError.networkError
        }
    }

    func upsertLatest(_ backup: CookyaExportBackup) async throws {
        guard let baseURL = config.backendBaseURL else { throw SnapshotError.missingBackendURL }
        guard let token = BackendAuthToken.load(), !token.isEmpty else { throw SnapshotError.missingAuthToken }
        guard let url = URL(string: "/v1/snapshot", relativeTo: baseURL)?.absoluteURL else {
            throw SnapshotError.invalidResponse
        }

        AppLogger.action("snapshot_upsert_started", screen: "BackendSnapshotService")

        let data = try encoder.encode(backup)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = data

        do {
            let (respData, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw SnapshotError.invalidResponse }
            guard (200 ... 299).contains(http.statusCode) else {
                let apiError = try? decoder.decode(APIErrorResponse.self, from: respData)
                AppLogger.action("snapshot_upsert_server_error", screen: "BackendSnapshotService", metadata: [
                    "statusCode": String(http.statusCode),
                    "message": apiError?.error.message ?? ""
                ])
                throw SnapshotError.serverError(code: http.statusCode, message: apiError?.error.message)
            }
            AppLogger.action("snapshot_upsert_succeeded", screen: "BackendSnapshotService")
        } catch let error as SnapshotError {
            throw error
        } catch {
            AppLogger.action("snapshot_upsert_network_error", screen: "BackendSnapshotService", metadata: ["error": String(describing: error)])
            throw SnapshotError.networkError
        }
    }
}

private struct APIErrorResponse: Decodable {
    let error: APIError

    struct APIError: Decodable {
        let message: String
    }
}

