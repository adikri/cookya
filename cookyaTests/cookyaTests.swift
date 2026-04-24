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

    func testRefreshUploadsPantryItemsMissingFromRemote() async {
        let store = makeStore()
        let rice = PantryItem(name: "Rice", quantityText: "2 cups", category: .grains)
        let dal = PantryItem(name: "Dal", quantityText: "1 cup", category: .protein)

        await store.savePantryItem(rice)
        await store.savePantryItem(dal)

        // Clear the upserts recorded by the two saves so we only observe refresh-driven ones.
        inventoryService.resetRecorded()

        // Remote only has rice — dal is local-only and must be uploaded during refresh.
        inventoryService.pantryToFetch = [rice]

        await store.refresh()

        XCTAssertEqual(inventoryService.upsertedPantryItems.count, 1)
        XCTAssertEqual(inventoryService.upsertedPantryItems.first?.id, dal.id)
    }

    func testRefreshUploadsGroceryItemsMissingFromRemote() async {
        let store = makeStore()
        let bread = GroceryItem(name: "Bread", quantityText: "1 loaf", category: .bakery)
        let milk = GroceryItem(name: "Milk", quantityText: "1 l", category: .dairy)

        await store.saveGroceryItem(bread)
        await store.saveGroceryItem(milk)

        inventoryService.resetRecorded()

        inventoryService.groceryToFetch = [bread]

        await store.refresh()

        XCTAssertEqual(inventoryService.upsertedGroceryItems.count, 1)
        XCTAssertEqual(inventoryService.upsertedGroceryItems.first?.id, milk.id)
    }

    func testRefreshDoesNotReuploadItemsAlreadyInRemote() async {
        let store = makeStore()
        let rice = PantryItem(name: "Rice", quantityText: "2 cups", category: .grains)

        await store.savePantryItem(rice)
        inventoryService.resetRecorded()

        // Remote has the same item — nothing should be uploaded.
        inventoryService.pantryToFetch = [rice]

        await store.refresh()

        XCTAssertEqual(inventoryService.upsertedPantryItems.count, 0)
    }

    func testRefreshWithEmptyLocalDoesNotUpload() async {
        let store = makeStore()
        let remote1 = PantryItem(name: "Rice", quantityText: "2 cups", category: .grains)
        let remote2 = PantryItem(name: "Dal", quantityText: "1 cup", category: .protein)

        inventoryService.pantryToFetch = [remote1, remote2]

        await store.refresh()

        XCTAssertEqual(inventoryService.upsertedPantryItems.count, 0)
        XCTAssertEqual(store.pantryItems.count, 2)
    }

    func testRefreshSetsSyncErrorWhenPantryLocalOnlyUploadFails() async {
        let store = makeStore()
        let rice = PantryItem(name: "Rice", quantityText: "2 cups", category: .grains)
        let dal = PantryItem(name: "Dal", quantityText: "1 cup", category: .protein)

        await store.savePantryItem(rice)
        await store.savePantryItem(dal)
        inventoryService.resetRecorded()
        inventoryService.pantryToFetch = [rice]
        inventoryService.pantryUpsertError = .networkError

        await store.refresh()

        XCTAssertEqual(inventoryService.upsertedPantryItems.count, 2)
        XCTAssertTrue(inventoryService.upsertedPantryItems.allSatisfy { $0.id == dal.id })
        XCTAssertEqual(store.lastSyncError, InventorySyncError.networkError.errorDescription)
    }

    func testRefreshSetsSyncErrorWhenGroceryLocalOnlyUploadFails() async {
        let store = makeStore()
        let bread = GroceryItem(name: "Bread", quantityText: "1 loaf", category: .bakery)
        let milk = GroceryItem(name: "Milk", quantityText: "1 l", category: .dairy)

        await store.saveGroceryItem(bread)
        await store.saveGroceryItem(milk)
        inventoryService.resetRecorded()
        inventoryService.groceryToFetch = [bread]
        inventoryService.groceryUpsertError = .networkError

        await store.refresh()

        XCTAssertEqual(inventoryService.upsertedGroceryItems.count, 2)
        XCTAssertTrue(inventoryService.upsertedGroceryItems.allSatisfy { $0.id == milk.id })
        XCTAssertEqual(store.lastSyncError, InventorySyncError.networkError.errorDescription)
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
    // Configurable return values for fetch.
    var pantryToFetch: [PantryItem] = []
    var groceryToFetch: [GroceryItem] = []
    var pantryUpsertError: InventorySyncError?
    var groceryUpsertError: InventorySyncError?

    // Recorded calls — used by tests to assert sync-driven upserts and deletes.
    private(set) var upsertedPantryItems: [PantryItem] = []
    private(set) var upsertedGroceryItems: [GroceryItem] = []
    private(set) var deletedPantryIds: [UUID] = []
    private(set) var deletedGroceryIds: [UUID] = []

    func resetRecorded() {
        upsertedPantryItems.removeAll()
        upsertedGroceryItems.removeAll()
        deletedPantryIds.removeAll()
        deletedGroceryIds.removeAll()
        pantryUpsertError = nil
        groceryUpsertError = nil
    }

    func fetchPantry() async throws -> [PantryItem] { pantryToFetch }

    func upsertPantryItem(_ item: PantryItem) async throws -> PantryItem {
        upsertedPantryItems.append(item)
        if let pantryUpsertError {
            throw pantryUpsertError
        }
        return item
    }

    func deletePantryItem(id: UUID) async throws {
        deletedPantryIds.append(id)
    }

    func fetchGrocery() async throws -> [GroceryItem] { groceryToFetch }

    func upsertGroceryItem(_ item: GroceryItem) async throws -> GroceryItem {
        upsertedGroceryItems.append(item)
        if let groceryUpsertError {
            throw groceryUpsertError
        }
        return item
    }

    func deleteGroceryItem(id: UUID) async throws {
        deletedGroceryIds.append(id)
    }

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
