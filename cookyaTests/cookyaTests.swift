import XCTest
@testable import cookya

@MainActor
final class InventoryStoreTests: XCTestCase {
    private var testDefaults: UserDefaults!
    private var testSuiteName: String!
    private var inventoryService: MockInventorySyncService!

    override func setUp() {
        super.setUp()
        testSuiteName = "InventoryStoreTests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: testSuiteName)
        inventoryService = MockInventorySyncService()
    }

    override func tearDown() {
        if let testSuiteName {
            testDefaults?.removePersistentDomain(forName: testSuiteName)
        }
        inventoryService = nil
        testDefaults = nil
        testSuiteName = nil
        super.tearDown()
    }

    func testDuplicatePantryItemSaveMergesInsteadOfDuplicating() async {
        let store = makeStore()
        let original = PantryItem(name: "Egg", quantityText: "6 count", category: .protein)
        let incoming = PantryItem(name: " egg ", quantityText: "2 count", category: .protein)

        await store.savePantryItem(original)
        await store.savePantryItem(incoming)

        XCTAssertEqual(store.pantryItems.count, 1)
        XCTAssertEqual(store.pantryItems.first?.name.lowercased(), "egg")
        XCTAssertEqual(store.pantryItems.first?.quantityText, "8 count")
    }

    func testPurchasedItemMergesIntoExistingPantryItem() async {
        let store = makeStore()
        let pantryBread = PantryItem(name: "Bread", quantityText: "1 loaf", category: .bakery)
        let groceryBread = GroceryItem(name: "Bread", quantityText: "1 loaf", category: .bakery)

        await store.savePantryItem(pantryBread)
        await store.saveGroceryItem(groceryBread)
        await store.markPurchased(groceryBread, quantityText: "1 loaf", category: .bakery, expiryDate: nil)

        XCTAssertEqual(store.pantryItems.count, 1)
        XCTAssertEqual(store.pantryItems.first?.quantityText, "2 loaf")
        XCTAssertTrue(store.groceryItems.isEmpty)
    }

    func testPurchasedFreshItemDoesNotMergeIntoExpiredPantryBatch() async {
        let store = makeStore()
        let expiredMilk = PantryItem(
            name: "Milk",
            quantityText: "1 l",
            category: .dairy,
            expiryDate: Calendar.current.date(byAdding: .day, value: -1, to: .now)
        )
        let groceryMilk = GroceryItem(name: "Milk", quantityText: "1 l", category: .dairy)
        let freshExpiry = Calendar.current.date(byAdding: .day, value: 3, to: .now)

        await store.savePantryItem(expiredMilk)
        await store.saveGroceryItem(groceryMilk)
        await store.markPurchased(groceryMilk, quantityText: "1 l", category: .dairy, expiryDate: freshExpiry)

        XCTAssertEqual(store.pantryItems.count, 2)
        XCTAssertEqual(store.expiredPantryItems.count, 1)
        XCTAssertEqual(store.usablePantryItems.count, 1)
        XCTAssertEqual(store.usablePantryItems.first?.quantityText, "1 l")
    }

    func testConsumePantryItemsBlocksOnUnitMismatch() async {
        let store = makeStore()
        let bread = PantryItem(name: "Bread", quantityText: "1 loaf", category: .bakery)

        await store.savePantryItem(bread)

        let result = await store.consumePantryItems([
            PantryConsumption(item: bread, usedQuantityText: "1 slice")
        ])

        XCTAssertFalse(result.applied)
        XCTAssertEqual(store.pantryItems.count, 1)
        XCTAssertEqual(store.pantryItems.first?.quantityText, "1 loaf")
        XCTAssertFalse(result.warnings.isEmpty)
    }

    private func makeStore() -> InventoryStore {
        InventoryStore(
            inventoryService: inventoryService,
            userDefaults: testDefaults
        )
    }
}

@MainActor
private final class MockInventorySyncService: InventorySyncingService {
    func fetchPantry() async throws -> [PantryItem] { [] }

    func upsertPantryItem(_ item: PantryItem) async throws -> PantryItem {
        item
    }

    func deletePantryItem(id: UUID) async throws {}

    func fetchGrocery() async throws -> [GroceryItem] { [] }

    func upsertGroceryItem(_ item: GroceryItem) async throws -> GroceryItem {
        item
    }

    func deleteGroceryItem(id: UUID) async throws {}

    func markPurchased(groceryItem: GroceryItem) async throws -> PantryItem {
        PantryItem(
            id: groceryItem.id,
            name: groceryItem.name,
            quantityText: groceryItem.quantityText,
            category: groceryItem.category,
            updatedAt: .now
        )
    }
}
