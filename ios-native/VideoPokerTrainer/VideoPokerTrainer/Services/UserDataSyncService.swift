import Foundation

extension Notification.Name {
    static let userDataDidSync = Notification.Name("userDataDidSync")
}

actor UserDataSyncService {
    static let shared = UserDataSyncService()

    private let dirtyKeysKey = "_sync_dirty_keys"
    private let timestampsKey = "_sync_timestamps"

    private var isSyncing = false

    /// All keys we sync (static ones — dynamic playStats_* discovered at runtime)
    private let staticSyncKeys: [String] = [
        "lesson_progress",
        "drill_stats",
        "training_lesson_progress_v2",
        "review_items",
        "review_stats",
        "playerBalance",
        "playSettings",
        "completedTours"
    ]

    private init() {}

    // MARK: - Dirty Key Tracking

    private func getDirtyKeys() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: dirtyKeysKey) ?? [])
    }

    private func setDirtyKeys(_ keys: Set<String>) {
        UserDefaults.standard.set(Array(keys), forKey: dirtyKeysKey)
    }

    private func getTimestamps() -> [String: TimeInterval] {
        (UserDefaults.standard.dictionary(forKey: timestampsKey) as? [String: TimeInterval]) ?? [:]
    }

    private func setTimestamps(_ stamps: [String: TimeInterval]) {
        UserDefaults.standard.set(stamps, forKey: timestampsKey)
    }

    private func initializedKey(for userId: UUID) -> String {
        "_sync_initialized_\(userId.uuidString)"
    }

    // MARK: - Mark Dirty

    func markDirty(key: String) async {
        var dirty = getDirtyKeys()
        dirty.insert(key)
        setDirtyKeys(dirty)

        var stamps = getTimestamps()
        stamps[key] = Date().timeIntervalSince1970
        setTimestamps(stamps)

        // Push immediately if online
        let isOnline = await MainActor.run { NetworkMonitor.shared.isOnline }
        if isOnline {
            await pushChanges()
        }
    }

    // MARK: - Push Changes

    func pushChanges() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        let dirty = getDirtyKeys()
        guard !dirty.isEmpty else { return }

        guard let userId = await MainActor.run(body: { SupabaseService.shared.currentUser?.id }) else { return }

        let stamps = getTimestamps()
        var rows: [UserDataRow] = []

        for key in dirty {
            guard let value = readValueAsString(for: key) else { continue }
            let timestamp = stamps[key] ?? Date().timeIntervalSince1970
            let row = UserDataRow(
                userId: userId,
                dataKey: key,
                dataValue: value,
                updatedAt: Date(timeIntervalSince1970: timestamp),
                schemaVersion: 1
            )
            rows.append(row)
        }

        guard !rows.isEmpty else { return }

        do {
            try await SupabaseService.shared.upsertUserData(rows: rows)
            // Clear dirty keys on success
            var remaining = getDirtyKeys()
            for row in rows {
                remaining.remove(row.dataKey)
            }
            setDirtyKeys(remaining)
            NSLog("✅ UserDataSync: Pushed \(rows.count) keys")
        } catch {
            NSLog("❌ UserDataSync: Push failed: \(error)")
        }
    }

    // MARK: - Pull and Merge

    func pullAndMerge() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            let remoteRows = try await SupabaseService.shared.getAllUserData()
            guard !remoteRows.isEmpty else {
                NSLog("ℹ️ UserDataSync: No remote data to pull")
                return
            }

            let localStamps = getTimestamps()
            var updatedStamps = localStamps
            var didUpdate = false

            for row in remoteRows {
                let localTimestamp = localStamps[row.dataKey] ?? 0
                let remoteTimestamp = row.updatedAt.timeIntervalSince1970

                // Only apply remote if it's newer than local
                if remoteTimestamp > localTimestamp {
                    writeValueFromString(row.dataValue, for: row.dataKey)
                    updatedStamps[row.dataKey] = remoteTimestamp
                    didUpdate = true
                }
            }

            if didUpdate {
                setTimestamps(updatedStamps)
                // Remove pulled keys from dirty set (they're now in sync)
                var dirty = getDirtyKeys()
                for row in remoteRows {
                    let localTimestamp = localStamps[row.dataKey] ?? 0
                    if row.updatedAt.timeIntervalSince1970 > localTimestamp {
                        dirty.remove(row.dataKey)
                    }
                }
                setDirtyKeys(dirty)

                NSLog("✅ UserDataSync: Pulled and merged remote data")
                await MainActor.run {
                    NotificationCenter.default.post(name: .userDataDidSync, object: nil)
                }
            }
        } catch {
            NSLog("❌ UserDataSync: Pull failed: \(error)")
        }
    }

    // MARK: - Full Sync

    func syncAll() async {
        guard let userId = await MainActor.run(body: { SupabaseService.shared.currentUser?.id }) else { return }

        let isFirstSync = !UserDefaults.standard.bool(forKey: initializedKey(for: userId))
        if isFirstSync {
            await initializeForUser(userId)
        } else {
            // Normal sync: push first, then pull
            await pushChanges()
            await pullAndMerge()
        }
    }

    // MARK: - Initialize for User

    func initializeForUser(_ userId: UUID) async {
        let key = initializedKey(for: userId)
        guard !UserDefaults.standard.bool(forKey: key) else {
            // Already initialized, just do a normal sync
            await pushChanges()
            await pullAndMerge()
            return
        }

        do {
            let remoteRows = try await SupabaseService.shared.getAllUserData()

            if remoteRows.isEmpty {
                // Server empty — push all local data
                NSLog("ℹ️ UserDataSync: First sync — server empty, pushing all local data")
                markAllLocalKeysAsDirty()
                // Set initialized before pushing so pushChanges can proceed
                UserDefaults.standard.set(true, forKey: key)
                await pushChanges()
            } else {
                // Server has data — pull first (new device scenario)
                NSLog("ℹ️ UserDataSync: First sync — server has data, pulling first")
                UserDefaults.standard.set(true, forKey: key)

                // Apply all remote data (force-apply since this is first sync)
                var stamps = getTimestamps()
                for row in remoteRows {
                    writeValueFromString(row.dataValue, for: row.dataKey)
                    stamps[row.dataKey] = row.updatedAt.timeIntervalSince1970
                }
                setTimestamps(stamps)

                await MainActor.run {
                    NotificationCenter.default.post(name: .userDataDidSync, object: nil)
                }

                // Now push any local keys that weren't on the server
                let remoteKeys = Set(remoteRows.map(\.dataKey))
                let allLocalKeys = discoverAllLocalSyncKeys()
                let localOnly = allLocalKeys.subtracting(remoteKeys)
                if !localOnly.isEmpty {
                    var dirty = getDirtyKeys()
                    for k in localOnly {
                        dirty.insert(k)
                        // Set current timestamp for these local-only keys
                        var s = getTimestamps()
                        s[k] = Date().timeIntervalSince1970
                        setTimestamps(s)
                    }
                    setDirtyKeys(dirty)
                    await pushChanges()
                }
            }
        } catch {
            NSLog("❌ UserDataSync: Initialization failed: \(error)")
        }
    }

    // MARK: - Clear Sync State

    func clearSyncState() {
        UserDefaults.standard.removeObject(forKey: dirtyKeysKey)
        UserDefaults.standard.removeObject(forKey: timestampsKey)

        // Clear all _sync_initialized_* keys
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in allKeys where key.hasPrefix("_sync_initialized_") {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: - Helpers

    private func discoverAllLocalSyncKeys() -> Set<String> {
        var keys = Set(staticSyncKeys)
        // Add dynamic playStats_* keys
        let allDefaults = UserDefaults.standard.dictionaryRepresentation().keys
        for key in allDefaults where key.hasPrefix("playStats_") {
            keys.insert(key)
        }
        return keys
    }

    private func markAllLocalKeysAsDirty() {
        let allKeys = discoverAllLocalSyncKeys()
        var dirty = getDirtyKeys()
        var stamps = getTimestamps()
        let now = Date().timeIntervalSince1970

        for key in allKeys {
            // Only mark dirty if there's actually data for this key
            if UserDefaults.standard.object(forKey: key) != nil {
                dirty.insert(key)
                if stamps[key] == nil {
                    stamps[key] = now
                }
            }
        }

        setDirtyKeys(dirty)
        setTimestamps(stamps)
    }

    /// Read a UserDefaults value and encode it as a JSON string for Supabase
    private func readValueAsString(for key: String) -> String? {
        if key == "completedTours" {
            // Stored as stringArray, encode to JSON string
            guard let array = UserDefaults.standard.stringArray(forKey: key) else { return nil }
            guard let data = try? JSONEncoder().encode(array) else { return nil }
            return String(data: data, encoding: .utf8)
        } else {
            // Stored as Data (JSON), convert to string
            guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
            return String(data: data, encoding: .utf8)
        }
    }

    /// Write a JSON string from Supabase back to UserDefaults in the correct format
    private func writeValueFromString(_ value: String, for key: String) {
        if key == "completedTours" {
            // Decode JSON string back to stringArray
            guard let data = value.data(using: .utf8),
                  let array = try? JSONDecoder().decode([String].self, from: data) else { return }
            UserDefaults.standard.set(array, forKey: key)
        } else {
            // Store as Data
            guard let data = value.data(using: .utf8) else { return }
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
