import XCTest
@testable import cookya

@MainActor
final class BackendSyncStatusStoreTests: XCTestCase {
    private var testDefaults: UserDefaults!
    private var testSuiteName: String!
    private var notificationCenter: NotificationCenter!

    override func setUp() {
        super.setUp()
        testSuiteName = "BackendSyncStatusStoreTests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: testSuiteName)
        notificationCenter = NotificationCenter()
    }

    override func tearDown() {
        if let testSuiteName {
            testDefaults?.removePersistentDomain(forName: testSuiteName)
        }
        testDefaults = nil
        testSuiteName = nil
        notificationCenter = nil
        super.tearDown()
    }

    func testSyncNowStoresUploadTimestampAndClearsErrorOnSuccess() async {
        let pantryData = try! JSONEncoder.withISO8601Dates().encode([PantryItem(name: "Milk", quantityText: "1 l", category: .dairy)])
        testDefaults.set(pantryData, forKey: AppPersistenceKey.pantryItems)
        let snapshotService = SnapshotServiceStub()
        let store = BackendSyncStatusStore(
            userDefaults: testDefaults,
            snapshotService: snapshotService,
            notificationCenter: notificationCenter
        )

        await store.syncNow()

        XCTAssertNotNil(store.lastUploadAt)
        XCTAssertNil(store.lastError)
        XCTAssertEqual(snapshotService.upsertCallCount, 1)
        XCTAssertNotNil(testDefaults.object(forKey: AppPersistenceKey.backendSnapshotLastUploadAt) as? Date)
        XCTAssertNil(testDefaults.string(forKey: AppPersistenceKey.backendSnapshotLastError))
    }

    func testSyncNowUsesLocalizedErrorDescriptionOnFailure() async {
        let pantryData = try! JSONEncoder.withISO8601Dates().encode([PantryItem(name: "Eggs", quantityText: "6 count", category: .protein)])
        testDefaults.set(pantryData, forKey: AppPersistenceKey.pantryItems)
        let snapshotService = SnapshotServiceStub()
        snapshotService.upsertError = BackendSnapshotService.SnapshotError.missingAuthToken
        let store = BackendSyncStatusStore(
            userDefaults: testDefaults,
            snapshotService: snapshotService,
            notificationCenter: notificationCenter
        )

        await store.syncNow()

        XCTAssertEqual(store.lastError, "Missing backend access token.")
        XCTAssertEqual(testDefaults.string(forKey: AppPersistenceKey.backendSnapshotLastError), "Missing backend access token.")
    }

    func testRestoreNowReplaceAllPostsImportNotificationAndClearsErrorOnSuccess() async throws {
        let pantryData = try JSONEncoder.withISO8601Dates().encode([PantryItem(name: "Rice", quantityText: "1 kg", category: .grains)])
        let backup = CookyaExportBackup(
            snapshot: AppBackupSnapshot(
                pantryItemsData: pantryData,
                groceryItemsData: nil,
                savedRecipesData: nil,
                cookedMealRecordsData: nil,
                primaryProfileData: nil,
                guestModeActive: nil,
                knownInventoryItemsData: nil
            ),
            appVersion: nil,
            appBuild: nil
        )
        let snapshotService = SnapshotServiceStub()
        snapshotService.fetchResult = backup
        let store = BackendSyncStatusStore(
            userDefaults: testDefaults,
            snapshotService: snapshotService,
            notificationCenter: notificationCenter
        )

        var didPostImportNotification = false
        let observer = notificationCenter.addObserver(
            forName: .cookyaBackupImported,
            object: nil,
            queue: nil
        ) { _ in
            didPostImportNotification = true
        }
        defer { notificationCenter.removeObserver(observer) }

        await store.restoreNowReplaceAll()

        XCTAssertTrue(didPostImportNotification)
        XCTAssertNotNil(store.lastRestoreAt)
        XCTAssertNil(store.lastError)
        XCTAssertEqual(testDefaults.data(forKey: AppPersistenceKey.pantryItems), pantryData)
    }

    func testRestoreNowReplaceAllUsesLocalizedErrorDescriptionOnFailure() async {
        let snapshotService = SnapshotServiceStub()
        snapshotService.fetchError = BackendSnapshotService.SnapshotError.networkError
        let store = BackendSyncStatusStore(
            userDefaults: testDefaults,
            snapshotService: snapshotService,
            notificationCenter: notificationCenter
        )

        await store.restoreNowReplaceAll()

        XCTAssertEqual(store.lastError, "Could not reach backend.")
        XCTAssertEqual(testDefaults.string(forKey: AppPersistenceKey.backendSnapshotLastError), "Could not reach backend.")
    }
}

@MainActor
private final class SnapshotServiceStub: BackendSnapshotServicing {
    var fetchResult: CookyaExportBackup?
    var fetchError: Error?
    var upsertError: Error?
    var upsertCallCount = 0

    func fetchLatest() async throws -> CookyaExportBackup {
        if let fetchError { throw fetchError }
        guard let fetchResult else {
            throw BackendSnapshotService.SnapshotError.notFound
        }
        return fetchResult
    }

    func upsertLatest(_ backup: CookyaExportBackup) async throws {
        upsertCallCount += 1
        if let upsertError { throw upsertError }
    }
}

private extension JSONEncoder {
    static func withISO8601Dates() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
