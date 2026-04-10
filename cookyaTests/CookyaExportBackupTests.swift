import XCTest
@testable import cookya

final class CookyaExportBackupTests: XCTestCase {
    func testEncodeDecodeRoundTrip() throws {
        let snapshot = AppBackupSnapshot(
            pantryItemsData: Data("[{\"name\":\"Milk\"}]".utf8),
            groceryItemsData: nil,
            savedRecipesData: nil,
            cookedMealRecordsData: nil,
            primaryProfileData: nil,
            guestModeActive: true,
            knownInventoryItemsData: nil
        )

        let backup = CookyaExportBackup(
            snapshot: snapshot,
            appVersion: "1.0",
            appBuild: "1"
        )

        let data = try CookyaBackupCodec.encode(backup)
        let decoded = try XCTUnwrap(try? CookyaBackupCodec.decode(data).get())

        XCTAssertEqual(decoded.version, CookyaBackupCodec.currentVersion)
        XCTAssertEqual(decoded.snapshot.pantryItemsData, snapshot.pantryItemsData)
        XCTAssertEqual(decoded.snapshot.guestModeActive, true)
        XCTAssertEqual(decoded.appVersion, "1.0")
    }

    func testDecodeRejectsInvalidJSON() {
        let result = CookyaBackupCodec.decode(Data("not-json".utf8))
        switch result {
        case .failure(.invalidFormat):
            break
        default:
            XCTFail("Expected invalidFormat")
        }
    }

    func testDecodeRejectsUnsupportedVersion() throws {
        let snapshot = AppBackupSnapshot(
            pantryItemsData: Data("[]".utf8),
            groceryItemsData: nil,
            savedRecipesData: nil,
            cookedMealRecordsData: nil,
            primaryProfileData: nil,
            guestModeActive: nil,
            knownInventoryItemsData: nil
        )

        let backup = CookyaExportBackup(version: 999, snapshot: snapshot, appVersion: nil, appBuild: nil)
        let data = try CookyaBackupCodec.encode(backup)
        switch CookyaBackupCodec.decode(data) {
        case .failure(.unsupportedVersion(999)):
            break
        default:
            XCTFail("Expected unsupportedVersion(999)")
        }
    }

    func testDecodeRejectsEmptySnapshot() throws {
        let snapshot = AppBackupSnapshot(
            pantryItemsData: nil,
            groceryItemsData: nil,
            savedRecipesData: nil,
            cookedMealRecordsData: nil,
            primaryProfileData: nil,
            guestModeActive: nil,
            knownInventoryItemsData: nil
        )

        let backup = CookyaExportBackup(snapshot: snapshot, appVersion: nil, appBuild: nil)
        let data = try CookyaBackupCodec.encode(backup)
        switch CookyaBackupCodec.decode(data) {
        case .failure(.emptySnapshot):
            break
        default:
            XCTFail("Expected emptySnapshot")
        }
    }
}

