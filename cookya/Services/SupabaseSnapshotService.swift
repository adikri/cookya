import Foundation
import Supabase

struct SupabaseSnapshotService: SnapshotSyncingService {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchLatest() async throws -> CookyaExportBackup {
        do {
            let records: [SnapshotRecord] = try await client
                .from("user_snapshots")
                .select()
                .execute()
                .value
            guard let record = records.first else { throw SnapshotSyncError.notFound }
            return record.snapshot
        } catch let e as SnapshotSyncError {
            throw e
        } catch {
            AppLogger.action(
                "supabase_snapshot_request_failed",
                screen: "SupabaseSnapshotService",
                metadata: ["operation": "fetchLatest"].merging(SupabaseErrorDiagnostics.metadata(for: error), uniquingKeysWith: { _, new in new })
            )
            throw SupabaseErrorDiagnostics.snapshotSyncError(from: error)
        }
    }

    func upsertLatest(_ backup: CookyaExportBackup) async throws {
        do {
            let userId = try currentUserId()
            let record = SnapshotRecord(userId: userId, snapshot: backup, updatedAt: .now)
            try await client
                .from("user_snapshots")
                .upsert(record, onConflict: "user_id")
                .execute()
        } catch let e as SnapshotSyncError {
            throw e
        } catch {
            AppLogger.action(
                "supabase_snapshot_request_failed",
                screen: "SupabaseSnapshotService",
                metadata: ["operation": "upsertLatest"].merging(SupabaseErrorDiagnostics.metadata(for: error), uniquingKeysWith: { _, new in new })
            )
            throw SupabaseErrorDiagnostics.snapshotSyncError(from: error)
        }
    }

    private func currentUserId() throws -> UUID {
        guard let user = client.auth.currentUser else {
            throw SnapshotSyncError.notAuthenticated
        }
        return user.id
    }
}

// camelCase fields → snake_case columns via SupabaseManager's convertToSnakeCase encoder
private struct SnapshotRecord: Codable {
    let userId: UUID
    let snapshot: CookyaExportBackup
    let updatedAt: Date
}
