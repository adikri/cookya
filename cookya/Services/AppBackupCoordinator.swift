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
    private let snapshotService: any SnapshotSyncingService
    private let uploadDebounceNanoseconds: UInt64
    private var defaultsObserver: NSObjectProtocol?
    private var isApplyingRestore = false
    private var pendingUploadTask: Task<Void, Never>?
    private var pendingUploadData: Data?
    private var lastUploadedData: Data?

    init(
        userDefaults: UserDefaults = .standard,
        fileManager: FileManager = .default,
        notificationCenter: NotificationCenter = .default,
        backupFileURL: URL? = nil,
        snapshotService: (any SnapshotSyncingService)? = nil,
        uploadDebounceNanoseconds: UInt64 = 350_000_000
    ) {
        self.userDefaults = userDefaults
        self.fileManager = fileManager
        self.notificationCenter = notificationCenter
        self.backupFileURL = backupFileURL ?? Self.defaultBackupFileURL(fileManager: fileManager)
        self.snapshotService = snapshotService ?? SupabaseSnapshotService(client: SupabaseManager.shared.client)
        self.uploadDebounceNanoseconds = uploadDebounceNanoseconds

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
        pendingUploadTask?.cancel()
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

    func refreshBackup(flushUpload: Bool = false) {
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

            let export = CookyaExportBackup(snapshot: snapshot)
            enqueueSnapshotUpload(export: export, encodedSnapshot: data, flush: flushUpload)
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

    func restoreFromBackendIfNeeded() async {
        // Only restore from backend when local app state is empty (fresh install / first launch).
        let localSnapshot = CookyaBackupCodec.makeSnapshot(userDefaults: userDefaults)
        if localSnapshot.isEmpty == false { return }

        do {
            let backup = try await snapshotService.fetchLatest()
            _ = BackupImportApplier.applyReplaceAll(backup, to: userDefaults)
            notificationCenter.post(name: .cookyaBackupImported, object: nil)
            AppLogger.action(
                "backend_snapshot_restore_succeeded",
                metadata: ["version": String(backup.version), "createdAt": backup.createdAt.ISO8601Format()]
            )
        } catch let error as SnapshotSyncError {
            if case .notFound = error { return }
            if case .notAuthenticated = error { return }
            AppLogger.action(
                "backend_snapshot_restore_failed",
                metadata: ["error": String(describing: error), "message": error.errorDescription ?? ""]
            )
        } catch {
            AppLogger.action(
                "backend_snapshot_restore_failed",
                metadata: ["error": String(describing: error)]
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
            pendingUploadTask?.cancel()
            pendingUploadTask = nil
            pendingUploadData = nil
            lastUploadedData = nil
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

    private func enqueueSnapshotUpload(export: CookyaExportBackup, encodedSnapshot: Data, flush: Bool) {
        if lastUploadedData == encodedSnapshot {
            return
        }

        pendingUploadTask?.cancel()
        pendingUploadData = encodedSnapshot

        pendingUploadTask = Task { @MainActor [weak self] in
            guard let self else { return }

            if !flush {
                try? await Task.sleep(nanoseconds: uploadDebounceNanoseconds)
            }

            if Task.isCancelled { return }
            guard self.pendingUploadData == encodedSnapshot else { return }

            do {
                try await self.snapshotService.upsertLatest(export)
                self.lastUploadedData = encodedSnapshot
                AppLogger.action("backend_snapshot_upsert_succeeded", metadata: ["version": String(export.version)])
            } catch {
                AppLogger.action(
                    "backend_snapshot_upsert_failed",
                    metadata: ["error": String(describing: error)]
                )
            }

            if self.pendingUploadData == encodedSnapshot {
                self.pendingUploadData = nil
                self.pendingUploadTask = nil
            }
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
