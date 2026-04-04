import XCTest
@testable import cookya

@MainActor
final class AppBackupCoordinatorTests: XCTestCase {
    private var testDefaults: UserDefaults!
    private var testSuiteName: String!
    private var backupFileURL: URL!
    private var backupDirectoryURL: URL!

    override func setUp() {
        super.setUp()
        testSuiteName = "AppBackupCoordinatorTests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: testSuiteName)
        backupDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cookya-backup-tests-\(UUID().uuidString)", isDirectory: true)
        backupFileURL = backupDirectoryURL.appendingPathComponent("state-backup-v1.json")
    }

    override func tearDown() {
        if let testSuiteName {
            testDefaults?.removePersistentDomain(forName: testSuiteName)
        }
        if let backupDirectoryURL {
            try? FileManager.default.removeItem(at: backupDirectoryURL)
        }
        testDefaults = nil
        testSuiteName = nil
        backupFileURL = nil
        backupDirectoryURL = nil
        super.tearDown()
    }

    func testRefreshBackupWritesPersistedStateToBackupFile() throws {
        let pantryItems = [PantryItem(name: "Milk", quantityText: "1 l", category: .dairy)]
        let pantryData = try JSONEncoder.withISO8601Dates().encode(pantryItems)
        testDefaults.set(pantryData, forKey: AppPersistenceKey.pantryItems)
        testDefaults.set(true, forKey: AppPersistenceKey.guestModeActive)

        let coordinator = makeCoordinator()
        coordinator.refreshBackup()

        let backupData = try Data(contentsOf: backupFileURL)
        let snapshot = try JSONDecoder.withISO8601Dates().decode(AppBackupSnapshot.self, from: backupData)

        XCTAssertEqual(snapshot.pantryItemsData, pantryData)
        XCTAssertEqual(snapshot.guestModeActive, true)
    }

    func testRestoreIfNeededRestoresMissingLocalStateFromBackup() throws {
        let pantryItems = [PantryItem(name: "Egg", quantityText: "6 count", category: .protein)]
        let pantryData = try JSONEncoder.withISO8601Dates().encode(pantryItems)
        let snapshot = AppBackupSnapshot(
            pantryItemsData: pantryData,
            groceryItemsData: nil,
            savedRecipesData: nil,
            cookedMealRecordsData: nil,
            primaryProfileData: nil,
            guestModeActive: true,
            knownInventoryItemsData: nil
        )
        let backupData = try JSONEncoder.withISO8601Dates().encode(snapshot)
        try FileManager.default.createDirectory(at: backupFileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try backupData.write(to: backupFileURL, options: .atomic)

        let coordinator = makeCoordinator()
        coordinator.restoreIfNeeded()

        XCTAssertEqual(testDefaults.data(forKey: AppPersistenceKey.pantryItems), pantryData)
        XCTAssertEqual(testDefaults.object(forKey: AppPersistenceKey.guestModeActive) as? Bool, true)
    }

    func testRestoreIfNeededDoesNotOverwriteExistingLocalState() throws {
        let localPantryData = try JSONEncoder.withISO8601Dates().encode([
            PantryItem(name: "Bread", quantityText: "1 loaf", category: .bakery)
        ])
        let backupPantryData = try JSONEncoder.withISO8601Dates().encode([
            PantryItem(name: "Milk", quantityText: "1 l", category: .dairy)
        ])

        testDefaults.set(localPantryData, forKey: AppPersistenceKey.pantryItems)

        let snapshot = AppBackupSnapshot(
            pantryItemsData: backupPantryData,
            groceryItemsData: nil,
            savedRecipesData: nil,
            cookedMealRecordsData: nil,
            primaryProfileData: nil,
            guestModeActive: nil,
            knownInventoryItemsData: nil
        )
        let backupData = try JSONEncoder.withISO8601Dates().encode(snapshot)
        try FileManager.default.createDirectory(at: backupFileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try backupData.write(to: backupFileURL, options: .atomic)

        let coordinator = makeCoordinator()
        coordinator.restoreIfNeeded()

        XCTAssertEqual(testDefaults.data(forKey: AppPersistenceKey.pantryItems), localPantryData)
    }

    private func makeCoordinator() -> AppBackupCoordinator {
        AppBackupCoordinator(
            userDefaults: testDefaults,
            fileManager: .default,
            notificationCenter: NotificationCenter(),
            backupFileURL: backupFileURL
        )
    }
}

private extension JSONEncoder {
    static func withISO8601Dates() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static func withISO8601Dates() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
