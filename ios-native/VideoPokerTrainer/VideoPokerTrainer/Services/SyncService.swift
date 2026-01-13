import Foundation

actor SyncService {
    static let shared = SyncService()

    private var isSyncing = false

    private init() {}

    // MARK: - Save Attempt (offline-first)

    func saveAttempt(_ attempt: HandAttempt) async {
        // Always save locally first
        await PendingAttemptsStore.shared.savePendingAttempt(attempt)

        // Try to sync immediately if online
        if await MainActor.run(body: { NetworkMonitor.shared.isOnline }) {
            await syncPendingAttempts()
        }
    }

    // MARK: - Sync Pending Attempts

    func syncPendingAttempts() async {
        // Prevent concurrent syncs
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        let pending = await PendingAttemptsStore.shared.getPendingAttempts()
        guard !pending.isEmpty else { return }

        NSLog("🔄 SyncService: Syncing \(pending.count) pending attempts")

        for attempt in pending {
            do {
                try await SupabaseService.shared.saveHandAttempt(attempt.toHandAttempt())
                await PendingAttemptsStore.shared.markAttemptSynced(id: attempt.id)
                NSLog("✅ SyncService: Synced attempt \(attempt.id)")
            } catch {
                // Will retry on next sync
                NSLog("❌ SyncService: Failed to sync attempt \(attempt.id): \(error)")
                break // Stop on first failure to preserve order
            }
        }

        // Clean up synced attempts
        await PendingAttemptsStore.shared.clearSyncedAttempts()
    }

    // MARK: - Pending Count (for UI)

    func pendingAttemptCount() async -> Int {
        await PendingAttemptsStore.shared.getPendingAttemptCount()
    }
}
