import XCTest
@testable import cookya

final class BackupImportApplierTests: XCTestCase {
    func testApplyReplaceAllSetsAndRemovesKeys() throws {
        let suiteName = "BackupImportApplierTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(Data("old".utf8), forKey: AppPersistenceKey.pantryItems)
        defaults.set(true, forKey: AppPersistenceKey.guestModeActive)

        let snapshot = AppBackupSnapshot(
            pantryItemsData: Data("new".utf8),
            groceryItemsData: nil,
            savedRecipesData: nil,
            cookedMealRecordsData: nil,
            primaryProfileData: nil,
            guestModeActive: nil,
            knownInventoryItemsData: Data("known".utf8)
        )

        let backup = CookyaExportBackup(
            snapshot: snapshot,
            appVersion: "1.0",
            appBuild: "1"
        )

        let result = BackupImportApplier.applyReplaceAll(backup, to: defaults)

        XCTAssertEqual(defaults.data(forKey: AppPersistenceKey.pantryItems), Data("new".utf8))
        XCTAssertNil(defaults.object(forKey: AppPersistenceKey.guestModeActive))
        XCTAssertEqual(defaults.data(forKey: AppPersistenceKey.knownInventoryItems), Data("known".utf8))
        XCTAssertTrue(result.restoredKeys.contains(AppPersistenceKey.pantryItems))
        XCTAssertTrue(result.restoredKeys.contains(AppPersistenceKey.knownInventoryItems))
    }
}

