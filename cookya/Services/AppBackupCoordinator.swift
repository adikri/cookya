import Foundation

struct AppBackupSnapshot: Codable {
    let version: Int
    let updatedAt: Date
    let pantryItemsData: Data?
    let groceryItemsData: Data?
    let savedRecipesData: Data?
    let cookedMealRecordsData: Data?
    let primaryProfileData: Data?
    let guestModeActive: Bool?
    let knownInventoryItemsData: Data?

    init(
        version: Int = 1,
        updatedAt: Date = .now,
        pantryItemsData: Data?,
        groceryItemsData: Data?,
        savedRecipesData: Data?,
        cookedMealRecordsData: Data?,
        primaryProfileData: Data?,
        guestModeActive: Bool?,
        knownInventoryItemsData: Data?
    ) {
        self.version = version
        self.updatedAt = updatedAt
        self.pantryItemsData = pantryItemsData
        self.groceryItemsData = groceryItemsData
        self.savedRecipesData = savedRecipesData
        self.cookedMealRecordsData = cookedMealRecordsData
        self.primaryProfileData = primaryProfileData
        self.guestModeActive = guestModeActive
        self.knownInventoryItemsData = knownInventoryItemsData
    }

    var isEmpty: Bool {
        pantryItemsData == nil &&
        groceryItemsData == nil &&
        savedRecipesData == nil &&
        cookedMealRecordsData == nil &&
        primaryProfileData == nil &&
        guestModeActive == nil &&
        knownInventoryItemsData == nil
    }
}

@MainActor
final class AppBackupCoordinator {
    private let userDefaults: UserDefaults
    private let fileManager: FileManager
    private let notificationCenter: NotificationCenter
    private let backupFileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var defaultsObserver: NSObjectProtocol?
    private var isApplyingRestore = false

    init(
        userDefaults: UserDefaults = .standard,
        fileManager: FileManager = .default,
        notificationCenter: NotificationCenter = .default,
        backupFileURL: URL? = nil
    ) {
        self.userDefaults = userDefaults
        self.fileManager = fileManager
        self.notificationCenter = notificationCenter
        self.backupFileURL = backupFileURL ?? Self.defaultBackupFileURL(fileManager: fileManager)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    deinit {
        if let defaultsObserver {
            notificationCenter.removeObserver(defaultsObserver)
        }
    }

    func restoreIfNeeded() {
        guard let snapshot = loadSnapshot() else { return }

        var restoredKeys: [String] = []
        isApplyingRestore = true
        defer { isApplyingRestore = false }

        restoredKeys += restore(data: snapshot.pantryItemsData, forKey: AppPersistenceKey.pantryItems)
        restoredKeys += restore(data: snapshot.groceryItemsData, forKey: AppPersistenceKey.groceryItems)
        restoredKeys += restore(data: snapshot.savedRecipesData, forKey: AppPersistenceKey.savedRecipes)
        restoredKeys += restore(data: snapshot.cookedMealRecordsData, forKey: AppPersistenceKey.cookedMealRecords)
        restoredKeys += restore(data: snapshot.primaryProfileData, forKey: AppPersistenceKey.primaryProfile)
        restoredKeys += restore(bool: snapshot.guestModeActive, forKey: AppPersistenceKey.guestModeActive)
        restoredKeys += restore(data: snapshot.knownInventoryItemsData, forKey: AppPersistenceKey.knownInventoryItems)

        guard !restoredKeys.isEmpty else { return }
        AppLogger.action(
            "backup_restored",
            metadata: [
                "keys": restoredKeys.joined(separator: ","),
                "path": backupFileURL.path
            ]
        )
    }

    func startObserving() {
        guard defaultsObserver == nil else { return }

        defaultsObserver = notificationCenter.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: userDefaults,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.isApplyingRestore { return }
                self.refreshBackup()
            }
        }

        refreshBackup()
    }

    func refreshBackup() {
        let snapshot = AppBackupSnapshot(
            pantryItemsData: userDefaults.data(forKey: AppPersistenceKey.pantryItems),
            groceryItemsData: userDefaults.data(forKey: AppPersistenceKey.groceryItems),
            savedRecipesData: userDefaults.data(forKey: AppPersistenceKey.savedRecipes),
            cookedMealRecordsData: userDefaults.data(forKey: AppPersistenceKey.cookedMealRecords),
            primaryProfileData: userDefaults.data(forKey: AppPersistenceKey.primaryProfile),
            guestModeActive: userDefaults.object(forKey: AppPersistenceKey.guestModeActive) as? Bool,
            knownInventoryItemsData: userDefaults.data(forKey: AppPersistenceKey.knownInventoryItems)
        )

        if snapshot.isEmpty {
            removeBackupIfPresent()
            return
        }

        do {
            try ensureBackupDirectoryExists()
            let data = try encoder.encode(snapshot)
            let existing = try? Data(contentsOf: backupFileURL)
            guard existing != data else { return }
            try data.write(to: backupFileURL, options: .atomic)
        } catch {
            AppLogger.action(
                "backup_refresh_failed",
                metadata: [
                    "path": backupFileURL.path,
                    "error": String(describing: error)
                ]
            )
        }
    }

    private func restore(data: Data?, forKey key: String) -> [String] {
        guard userDefaults.object(forKey: key) == nil, let data else { return [] }
        userDefaults.set(data, forKey: key)
        return [key]
    }

    private func restore(bool: Bool?, forKey key: String) -> [String] {
        guard userDefaults.object(forKey: key) == nil, let value = bool else { return [] }
        userDefaults.set(value, forKey: key)
        return [key]
    }

    private func loadSnapshot() -> AppBackupSnapshot? {
        guard let data = try? Data(contentsOf: backupFileURL) else { return nil }

        do {
            return try decoder.decode(AppBackupSnapshot.self, from: data)
        } catch {
            AppLogger.action(
                "backup_decode_failed",
                metadata: [
                    "path": backupFileURL.path,
                    "error": String(describing: error)
                ]
            )
            return nil
        }
    }

    private func removeBackupIfPresent() {
        guard fileManager.fileExists(atPath: backupFileURL.path) else { return }
        do {
            try fileManager.removeItem(at: backupFileURL)
        } catch {
            AppLogger.action(
                "backup_remove_failed",
                metadata: [
                    "path": backupFileURL.path,
                    "error": String(describing: error)
                ]
            )
        }
    }

    private func ensureBackupDirectoryExists() throws {
        let directory = backupFileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    private static func defaultBackupFileURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return baseURL
            .appendingPathComponent("cookya-backups", isDirectory: true)
            .appendingPathComponent("state-backup-v1.json")
    }
}
