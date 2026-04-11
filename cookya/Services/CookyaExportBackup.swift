import Foundation

struct CookyaExportBackup: Codable {
    let version: Int
    let createdAt: Date
    let snapshot: AppBackupSnapshot
    let appVersion: String?
    let appBuild: String?

    init(
        version: Int = 1,
        createdAt: Date = .now,
        snapshot: AppBackupSnapshot,
        appVersion: String? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
        appBuild: String? = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    ) {
        self.version = version
        self.createdAt = createdAt
        self.snapshot = snapshot
        self.appVersion = appVersion
        self.appBuild = appBuild
    }
}

enum CookyaBackupCodec {
    static let currentVersion = 1

    enum BackupError: LocalizedError, Equatable {
        case invalidFormat
        case unsupportedVersion(Int)
        case emptySnapshot

        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return "Backup file is not a valid Cookya backup."
            case .unsupportedVersion(let v):
                return "Backup version \(v) is not supported."
            case .emptySnapshot:
                return "Backup file contains no app data."
            }
        }
    }

    static func makeSnapshot(userDefaults: UserDefaults = .standard) -> AppBackupSnapshot {
        AppBackupSnapshot(
            pantryItemsData: userDefaults.data(forKey: AppPersistenceKey.pantryItems),
            groceryItemsData: userDefaults.data(forKey: AppPersistenceKey.groceryItems),
            savedRecipesData: userDefaults.data(forKey: AppPersistenceKey.savedRecipes),
            cookedMealRecordsData: userDefaults.data(forKey: AppPersistenceKey.cookedMealRecords),
            primaryProfileData: userDefaults.data(forKey: AppPersistenceKey.primaryProfile),
            guestModeActive: userDefaults.object(forKey: AppPersistenceKey.guestModeActive) as? Bool,
            knownInventoryItemsData: userDefaults.data(forKey: AppPersistenceKey.knownInventoryItems)
        )
    }

    static func encode(_ backup: CookyaExportBackup) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(backup)
    }

    static func decode(_ data: Data) -> Result<CookyaExportBackup, BackupError> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let backup = try? decoder.decode(CookyaExportBackup.self, from: data) else {
            return .failure(.invalidFormat)
        }

        guard backup.version == currentVersion else {
            return .failure(.unsupportedVersion(backup.version))
        }

        guard !backup.snapshot.isEmpty else {
            return .failure(.emptySnapshot)
        }

        return .success(backup)
    }
}

