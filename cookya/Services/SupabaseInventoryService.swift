import Foundation
import Supabase

struct SupabaseInventoryService: InventorySyncingService {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    // MARK: - Pantry

    func fetchPantry() async throws -> [PantryItem] {
        do {
            let records: [PantryItemRecord] = try await client
                .from("pantry_items")
                .select()
                .execute()
                .value
            return records.map(\.domain)
        } catch {
            throw mapped(error)
        }
    }

    func upsertPantryItem(_ item: PantryItem) async throws -> PantryItem {
        do {
            let dto = PantryItemRecord(item, userId: try currentUserId())
            let record: PantryItemRecord = try await client
                .from("pantry_items")
                .upsert(dto)
                .select()
                .single()
                .execute()
                .value
            return record.domain
        } catch let e as InventorySyncError {
            throw e
        } catch {
            throw mapped(error)
        }
    }

    func deletePantryItem(id: UUID) async throws {
        do {
            try await client
                .from("pantry_items")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        } catch {
            throw mapped(error)
        }
    }

    // MARK: - Grocery

    func fetchGrocery() async throws -> [GroceryItem] {
        do {
            let records: [GroceryItemRecord] = try await client
                .from("grocery_items")
                .select()
                .execute()
                .value
            return records.map(\.domain)
        } catch {
            throw mapped(error)
        }
    }

    func upsertGroceryItem(_ item: GroceryItem) async throws -> GroceryItem {
        do {
            let dto = GroceryItemRecord(item, userId: try currentUserId())
            let record: GroceryItemRecord = try await client
                .from("grocery_items")
                .upsert(dto)
                .select()
                .single()
                .execute()
                .value
            return record.domain
        } catch let e as InventorySyncError {
            throw e
        } catch {
            throw mapped(error)
        }
    }

    func deleteGroceryItem(id: UUID) async throws {
        do {
            try await client
                .from("grocery_items")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        } catch {
            throw mapped(error)
        }
    }

    // MARK: - Purchase

    func markPurchased(groceryItem: GroceryItem) async throws -> PantryItem {
        // Delete the grocery row, then create the pantry row.
        // If the upsert fails after the delete, the grocery item is lost from the backend
        // but the local store already handles this gracefully via its optimistic state.
        try await deleteGroceryItem(id: groceryItem.id)
        let pantryItem = PantryItem(
            id: groceryItem.id,
            name: groceryItem.name,
            quantityText: groceryItem.quantityText,
            category: groceryItem.category,
            updatedAt: .now
        )
        return try await upsertPantryItem(pantryItem)
    }

    // MARK: - Helpers

    private func currentUserId() throws -> UUID {
        guard let user = client.auth.currentUser else {
            throw InventorySyncError.notAuthenticated
        }
        return user.id
    }

    private func mapped(_ error: Error) -> InventorySyncError {
        if let e = error as? InventorySyncError { return e }
        if let urlError = error as? URLError {
            return urlError.code == .cancelled ? .cancelled : .networkError
        }
        return .networkError
    }
}

// MARK: - DTOs
// camelCase fields → snake_case columns via SupabaseManager's convertToSnakeCase encoder

private struct PantryItemRecord: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let quantityText: String
    let category: String
    let expiryDate: Date?
    let updatedAt: Date

    init(_ item: PantryItem, userId: UUID) {
        id = item.id
        self.userId = userId
        name = item.name
        quantityText = item.quantityText
        category = item.category.rawValue
        expiryDate = item.expiryDate
        updatedAt = item.updatedAt
    }

    var domain: PantryItem {
        PantryItem(
            id: id,
            name: name,
            quantityText: quantityText,
            category: InventoryCategory(rawValue: category) ?? .other,
            expiryDate: expiryDate,
            updatedAt: updatedAt
        )
    }
}

private struct GroceryItemRecord: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let quantityText: String
    let category: String
    let note: String?
    let source: String
    let reasonRecipes: [String]
    let createdAt: Date

    init(_ item: GroceryItem, userId: UUID) {
        id = item.id
        self.userId = userId
        name = item.name
        quantityText = item.quantityText
        category = item.category.rawValue
        note = item.note
        source = item.source.rawValue
        reasonRecipes = item.reasonRecipes
        createdAt = item.createdAt
    }

    var domain: GroceryItem {
        GroceryItem(
            id: id,
            name: name,
            quantityText: quantityText,
            category: InventoryCategory(rawValue: category) ?? .other,
            note: note,
            source: GroceryItemSource(rawValue: source) ?? .manual,
            reasonRecipes: reasonRecipes,
            createdAt: createdAt
        )
    }
}
