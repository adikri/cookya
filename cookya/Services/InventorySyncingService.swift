import Foundation

protocol InventorySyncingService {
    func fetchPantry() async throws -> [PantryItem]
    func upsertPantryItem(_ item: PantryItem) async throws -> PantryItem
    func deletePantryItem(id: UUID) async throws
    func fetchGrocery() async throws -> [GroceryItem]
    func upsertGroceryItem(_ item: GroceryItem) async throws -> GroceryItem
    func deleteGroceryItem(id: UUID) async throws
    func markPurchased(groceryItem: GroceryItem) async throws -> PantryItem
}

enum InventorySyncError: LocalizedError, Equatable {
    case missingBackendURL
    case cancelled
    case networkError
    case invalidResponse
    case decodingFailed
    case serverError(code: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .missingBackendURL:
            return nil
        case .cancelled:
            return nil
        case .networkError:
            return "Inventory sync failed. You can keep using the local cache and try syncing again later."
        case .invalidResponse:
            return "The inventory service returned an unexpected response."
        case .decodingFailed:
            return "Could not decode inventory data from the backend."
        case let .serverError(code, message):
            if let message, !message.isEmpty {
                return "Inventory service error (\(code)): \(message)"
            }
            return "Inventory service error (\(code))."
        }
    }
}
