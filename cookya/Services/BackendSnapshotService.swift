import Foundation

protocol BackendSnapshotServicing {
    func fetchLatest() async throws -> CookyaExportBackup
    func upsertLatest(_ backup: CookyaExportBackup) async throws
}

struct BackendSnapshotService: BackendSnapshotServicing {
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
    private let tokenProvider: () -> String?

    init(
        session: URLSession = .shared,
        config: AppConfig = .live,
        tokenProvider: @escaping () -> String? = { BackendAuthToken.load() }
    ) {
        self.session = session
        self.config = config
        self.tokenProvider = tokenProvider

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func fetchLatest() async throws -> CookyaExportBackup {
        guard let baseURL = config.backendBaseURL else { throw SnapshotError.missingBackendURL }
        guard let token = tokenProvider()?.trimmingCharacters(in: .whitespacesAndNewlines), !token.isEmpty else {
            throw SnapshotError.missingAuthToken
        }
        guard let url = URL(string: "/v1/snapshot", relativeTo: baseURL)?.absoluteURL else {
            throw SnapshotError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw SnapshotError.invalidResponse }

            if http.statusCode == 404 {
                throw SnapshotError.notFound
            }

            guard (200 ... 299).contains(http.statusCode) else {
                let apiError = try? decoder.decode(APIErrorResponse.self, from: data)
                throw SnapshotError.serverError(code: http.statusCode, message: apiError?.error.message)
            }

            do {
                return try decoder.decode(CookyaExportBackup.self, from: data)
            } catch {
                throw SnapshotError.decodingFailed
            }
        } catch let error as SnapshotError {
            throw error
        } catch {
            throw SnapshotError.networkError
        }
    }

    func upsertLatest(_ backup: CookyaExportBackup) async throws {
        guard let baseURL = config.backendBaseURL else { throw SnapshotError.missingBackendURL }
        guard let token = tokenProvider()?.trimmingCharacters(in: .whitespacesAndNewlines), !token.isEmpty else {
            throw SnapshotError.missingAuthToken
        }
        guard let url = URL(string: "/v1/snapshot", relativeTo: baseURL)?.absoluteURL else {
            throw SnapshotError.invalidResponse
        }

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
                throw SnapshotError.serverError(code: http.statusCode, message: apiError?.error.message)
            }
        } catch let error as SnapshotError {
            throw error
        } catch {
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
