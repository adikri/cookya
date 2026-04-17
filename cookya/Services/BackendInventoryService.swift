import Foundation

struct BackendInventoryService: InventorySyncingService {
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

    func fetchPantry() async throws -> [PantryItem] {
        try await send(path: "/v1/pantry", method: "GET", body: Optional<Data>.none, decode: [PantryItem].self)
    }

    func upsertPantryItem(_ item: PantryItem) async throws -> PantryItem {
        let data = try encoder.encode(item)
        return try await send(path: "/v1/pantry/\(item.id.uuidString)", method: "PUT", body: data, decode: PantryItem.self)
    }

    func deletePantryItem(id: UUID) async throws {
        _ = try await send(path: "/v1/pantry/\(id.uuidString)", method: "DELETE", body: Optional<Data>.none, decode: EmptyResponse.self)
    }

    func fetchGrocery() async throws -> [GroceryItem] {
        try await send(path: "/v1/grocery", method: "GET", body: Optional<Data>.none, decode: [GroceryItem].self)
    }

    func upsertGroceryItem(_ item: GroceryItem) async throws -> GroceryItem {
        let data = try encoder.encode(item)
        return try await send(path: "/v1/grocery/\(item.id.uuidString)", method: "PUT", body: data, decode: GroceryItem.self)
    }

    func deleteGroceryItem(id: UUID) async throws {
        _ = try await send(path: "/v1/grocery/\(id.uuidString)", method: "DELETE", body: Optional<Data>.none, decode: EmptyResponse.self)
    }

    func markPurchased(groceryItem: GroceryItem) async throws -> PantryItem {
        let data = try encoder.encode(groceryItem)
        return try await send(path: "/v1/grocery/\(groceryItem.id.uuidString)/purchase", method: "POST", body: data, decode: PantryItem.self)
    }

    private func send<T: Decodable>(path: String, method: String, body: Data?, decode: T.Type) async throws -> T {
        guard let baseURL = config.backendBaseURL else {
            throw InventorySyncError.missingBackendURL
        }
        guard let token = tokenProvider()?.trimmingCharacters(in: .whitespacesAndNewlines), !token.isEmpty else {
            throw InventorySyncError.missingAuthToken
        }

        guard let url = URL(string: path, relativeTo: baseURL)?.absoluteURL else {
            throw InventorySyncError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = body

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw InventorySyncError.invalidResponse
            }

            guard (200 ... 299).contains(http.statusCode) else {
                let apiError = try? decoder.decode(APIErrorResponse.self, from: data)
                throw InventorySyncError.serverError(code: http.statusCode, message: apiError?.error.message)
            }

            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw InventorySyncError.decodingFailed
            }
        } catch let error as InventorySyncError {
            throw error
        } catch {
            let meta: [String: String]
            if let urlError = error as? URLError {
                if urlError.code == .cancelled {
                    throw InventorySyncError.cancelled
                }
                meta = [
                    "urlErrorCode": String(urlError.errorCode),
                    "urlError": urlError.localizedDescription,
                    "method": method,
                    "path": path
                ]
            } else {
                meta = [
                    "error": String(describing: error),
                    "method": method,
                    "path": path
                ]
            }
            AppLogger.action("inventory_sync_network_error", screen: "BackendInventoryService", metadata: meta)
            throw InventorySyncError.networkError
        }
    }
}

private struct APIErrorResponse: Decodable {
    let error: APIError

    struct APIError: Decodable {
        let message: String
    }
}

private struct EmptyResponse: Decodable {}
