import Foundation
import Combine

@MainActor
final class BackendSyncStatusStore: ObservableObject {
    @Published private(set) var lastUploadAt: Date?
    @Published private(set) var lastRestoreAt: Date?
    @Published private(set) var lastError: String?
    @Published private(set) var isSyncing = false

    private let userDefaults: UserDefaults
    private let snapshotService: BackendSnapshotServicing
    private let notificationCenter: NotificationCenter

    init(
        userDefaults: UserDefaults = .standard,
        snapshotService: (any BackendSnapshotServicing)? = nil,
        notificationCenter: NotificationCenter = .default
    ) {
        self.userDefaults = userDefaults
        self.snapshotService = snapshotService ?? BackendSnapshotService()
        self.notificationCenter = notificationCenter
        loadFromDisk()
    }

    func syncNow() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            let snapshot = CookyaBackupCodec.makeSnapshot(userDefaults: userDefaults)
            guard snapshot.isEmpty == false else {
                lastError = nil
                persist()
                AppLogger.action("backend_snapshot_upsert_skipped_empty")
                return
            }

            let export = CookyaExportBackup(snapshot: snapshot)
            try await snapshotService.upsertLatest(export)
            lastUploadAt = .now
            lastError = nil
            persist()
            AppLogger.action("backend_snapshot_upsert_succeeded", metadata: ["version": String(export.version)])
        } catch {
            lastError = Self.errorMessage(for: error)
            persist()
            AppLogger.action("backend_snapshot_upsert_failed", metadata: ["error": Self.errorMessage(for: error)])
        }
    }

    func restoreNowReplaceAll() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            let backup = try await snapshotService.fetchLatest()
            _ = BackupImportApplier.applyReplaceAll(backup, to: userDefaults)
            notificationCenter.post(name: .cookyaBackupImported, object: nil)
            lastRestoreAt = .now
            lastError = nil
            persist()
            AppLogger.action("backend_snapshot_restore_succeeded", metadata: ["version": String(backup.version)])
        } catch {
            lastError = Self.errorMessage(for: error)
            persist()
            AppLogger.action("backend_snapshot_restore_failed", metadata: ["error": Self.errorMessage(for: error)])
        }
    }

    private static func errorMessage(for error: Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription, !description.isEmpty {
            return description
        }
        return String(describing: error)
    }

    private func loadFromDisk() {
        if let d = userDefaults.object(forKey: AppPersistenceKey.backendSnapshotLastUploadAt) as? Date {
            lastUploadAt = d
        }
        if let d = userDefaults.object(forKey: AppPersistenceKey.backendSnapshotLastRestoreAt) as? Date {
            lastRestoreAt = d
        }
        lastError = userDefaults.string(forKey: AppPersistenceKey.backendSnapshotLastError)
    }

    private func persist() {
        if let lastUploadAt {
            userDefaults.set(lastUploadAt, forKey: AppPersistenceKey.backendSnapshotLastUploadAt)
        } else {
            userDefaults.removeObject(forKey: AppPersistenceKey.backendSnapshotLastUploadAt)
        }

        if let lastRestoreAt {
            userDefaults.set(lastRestoreAt, forKey: AppPersistenceKey.backendSnapshotLastRestoreAt)
        } else {
            userDefaults.removeObject(forKey: AppPersistenceKey.backendSnapshotLastRestoreAt)
        }

        if let lastError, !lastError.isEmpty {
            userDefaults.set(lastError, forKey: AppPersistenceKey.backendSnapshotLastError)
        } else {
            userDefaults.removeObject(forKey: AppPersistenceKey.backendSnapshotLastError)
        }
    }
}
