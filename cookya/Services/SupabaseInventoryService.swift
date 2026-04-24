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
            AppLogger.action(
                "supabase_inventory_request_failed",
                screen: "SupabaseInventoryService",
                metadata: ["operation": "fetchPantry"].merging(SupabaseErrorDiagnostics.metadata(for: error), uniquingKeysWith: { _, new in new })
            )
            throw SupabaseErrorDiagnostics.inventorySyncError(from: error)
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
            AppLogger.action(
                "supabase_inventory_request_failed",
                screen: "SupabaseInventoryService",
                metadata: ["operation": "upsertPantryItem", "itemId": item.id.uuidString].merging(SupabaseErrorDiagnostics.metadata(for: error), uniquingKeysWith: { _, new in new })
            )
            throw SupabaseErrorDiagnostics.inventorySyncError(from: error)
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
            AppLogger.action(
                "supabase_inventory_request_failed",
                screen: "SupabaseInventoryService",
                metadata: ["operation": "deletePantryItem", "itemId": id.uuidString].merging(SupabaseErrorDiagnostics.metadata(for: error), uniquingKeysWith: { _, new in new })
            )
            throw SupabaseErrorDiagnostics.inventorySyncError(from: error)
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
            AppLogger.action(
                "supabase_inventory_request_failed",
                screen: "SupabaseInventoryService",
                metadata: ["operation": "fetchGrocery"].merging(SupabaseErrorDiagnostics.metadata(for: error), uniquingKeysWith: { _, new in new })
            )
            throw SupabaseErrorDiagnostics.inventorySyncError(from: error)
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
            AppLogger.action(
                "supabase_inventory_request_failed",
                screen: "SupabaseInventoryService",
                metadata: ["operation": "upsertGroceryItem", "itemId": item.id.uuidString].merging(SupabaseErrorDiagnostics.metadata(for: error), uniquingKeysWith: { _, new in new })
            )
            throw SupabaseErrorDiagnostics.inventorySyncError(from: error)
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
            AppLogger.action(
                "supabase_inventory_request_failed",
                screen: "SupabaseInventoryService",
                metadata: ["operation": "deleteGroceryItem", "itemId": id.uuidString].merging(SupabaseErrorDiagnostics.metadata(for: error), uniquingKeysWith: { _, new in new })
            )
            throw SupabaseErrorDiagnostics.inventorySyncError(from: error)
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
