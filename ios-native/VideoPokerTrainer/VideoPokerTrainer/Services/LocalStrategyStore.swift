import Foundation
import SQLite3
import Compression

/// Local SQLite-based storage for strategy data
/// Provides fast offline lookups for all paytables
actor LocalStrategyStore {
    static let shared = LocalStrategyStore()

    private var db: OpaquePointer?
    private let dbPath: String

    // Prepared statements for performance
    private var lookupStmt: OpaquePointer?
    private var insertStmt: OpaquePointer?
    private var countStmt: OpaquePointer?

    private init() {
        // Store in app's Caches directory (can be cleared by system)
        let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        dbPath = cachesPath.appendingPathComponent("strategies.sqlite").path

        Task {
            await openDatabase()
            // Clear any data from previous session - strategies will be re-decompressed on demand
            await clearOnLaunch()
        }
    }

    /// Clear strategy data for "compressed" paytables on app launch
    /// "Ready" paytables are kept in SQLite for instant access
    private func clearOnLaunch() {
        // Get all paytables currently in SQLite
        let storedPaytables = getAvailablePaytables()

        var clearedCount = 0
        for paytable in storedPaytables {
            // Check if this paytable should be cleared (compressed mode)
            if PaytablePreferences.shared.shouldClearOnLaunch(paytableId: paytable.paytableId) {
                executeSQL("DELETE FROM strategies WHERE paytable_id = '\(paytable.paytableId)';")
                executeSQL("DELETE FROM paytable_meta WHERE paytable_id = '\(paytable.paytableId)';")
                clearedCount += 1
            }
        }

        if clearedCount > 0 {
            NSLog("🧹 Cleared %d compressed paytable(s) from previous session", clearedCount)
        }

        let keptCount = storedPaytables.count - clearedCount
        if keptCount > 0 {
            NSLog("💾 Kept %d ready paytable(s) in cache", keptCount)
        }
    }

    // MARK: - Database Setup

    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("❌ Error opening database: \(String(cString: sqlite3_errmsg(db)))")
            return
        }

        createTables()
        prepareStatements()
        print("✅ LocalStrategyStore database opened at \(dbPath)")
    }

    private func createTables() {
        let createStrategiesSQL = """
            CREATE TABLE IF NOT EXISTS strategies (
                paytable_id TEXT NOT NULL,
                hand_key TEXT NOT NULL,
                best_hold INTEGER NOT NULL,
                best_ev REAL NOT NULL,
                hold_evs TEXT NOT NULL,
                PRIMARY KEY (paytable_id, hand_key)
            ) WITHOUT ROWID;
        """

        let createMetaSQL = """
            CREATE TABLE IF NOT EXISTS paytable_meta (
                paytable_id TEXT PRIMARY KEY,
                display_name TEXT NOT NULL,
                version INTEGER NOT NULL,
                hand_count INTEGER NOT NULL,
                downloaded_at TEXT,
                is_bundled INTEGER DEFAULT 0
            );
        """

        executeSQL(createStrategiesSQL)
        executeSQL(createMetaSQL)

        // Create index for faster lookups
        executeSQL("CREATE INDEX IF NOT EXISTS idx_strategies_lookup ON strategies(paytable_id, hand_key);")
    }

    private func prepareStatements() {
        let lookupSQL = "SELECT best_hold, best_ev, hold_evs FROM strategies WHERE paytable_id = ? AND hand_key = ?;"
        if sqlite3_prepare_v2(db, lookupSQL, -1, &lookupStmt, nil) != SQLITE_OK {
            print("❌ Error preparing lookup statement: \(String(cString: sqlite3_errmsg(db)))")
        }

        let insertSQL = "INSERT OR REPLACE INTO strategies (paytable_id, hand_key, best_hold, best_ev, hold_evs) VALUES (?, ?, ?, ?, ?);"
        if sqlite3_prepare_v2(db, insertSQL, -1, &insertStmt, nil) != SQLITE_OK {
            print("❌ Error preparing insert statement: \(String(cString: sqlite3_errmsg(db)))")
        }

        let countSQL = "SELECT COUNT(*) FROM strategies WHERE paytable_id = ?;"
        if sqlite3_prepare_v2(db, countSQL, -1, &countStmt, nil) != SQLITE_OK {
            print("❌ Error preparing count statement: \(String(cString: sqlite3_errmsg(db)))")
        }
    }

    private func executeSQL(_ sql: String) {
        var errMsg: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errMsg) != SQLITE_OK {
            if let errMsg = errMsg {
                print("❌ SQL Error: \(String(cString: errMsg))")
                sqlite3_free(errMsg)
            }
        }
    }

    // MARK: - Public API

    /// Look up strategy for a hand from local storage
    func lookup(paytableId: String, handKey: String) -> StrategyResult? {
        guard let stmt = lookupStmt else { return nil }

        defer { sqlite3_reset(stmt) }

        sqlite3_bind_text(stmt, 1, paytableId, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(stmt, 2, handKey, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

        if sqlite3_step(stmt) == SQLITE_ROW {
            let bestHold = Int(sqlite3_column_int(stmt, 0))
            let bestEv = sqlite3_column_double(stmt, 1)

            var holdEvs: [String: Double] = [:]
            if let holdEvsText = sqlite3_column_text(stmt, 2) {
                let holdEvsString = String(cString: holdEvsText)
                if let data = holdEvsString.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
                    holdEvs = decoded
                }
            }

            return StrategyResult(bestHold: bestHold, bestEv: bestEv, holdEvs: holdEvs)
        }

        return nil
    }

    /// Check if a paytable has local data available
    func hasLocalData(paytableId: String) -> Bool {
        return getHandCount(paytableId: paytableId) > 0
    }

    /// Get the number of hands stored for a paytable
    func getHandCount(paytableId: String) -> Int {
        guard let stmt = countStmt else { return 0 }

        defer { sqlite3_reset(stmt) }

        sqlite3_bind_text(stmt, 1, paytableId, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

        if sqlite3_step(stmt) == SQLITE_ROW {
            return Int(sqlite3_column_int(stmt, 0))
        }

        return 0
    }

    /// Get all paytables that have local data
    func getAvailablePaytables() -> [PaytableMetadata] {
        var results: [PaytableMetadata] = []

        let sql = "SELECT paytable_id, display_name, version, hand_count, downloaded_at, is_bundled FROM paytable_meta;"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let paytableId = String(cString: sqlite3_column_text(stmt, 0))
                let displayName = String(cString: sqlite3_column_text(stmt, 1))
                let version = Int(sqlite3_column_int(stmt, 2))
                let handCount = Int(sqlite3_column_int(stmt, 3))
                let downloadedAt = sqlite3_column_text(stmt, 4).map { String(cString: $0) }
                let isBundled = sqlite3_column_int(stmt, 5) == 1

                results.append(PaytableMetadata(
                    paytableId: paytableId,
                    displayName: displayName,
                    version: version,
                    handCount: handCount,
                    downloadedAt: downloadedAt,
                    isBundled: isBundled
                ))
            }
            sqlite3_finalize(stmt)
        }

        return results
    }

    /// Get total storage size used by the database
    func getDatabaseSize() -> Int64 {
        let fileManager = FileManager.default
        if let attrs = try? fileManager.attributesOfItem(atPath: dbPath),
           let size = attrs[.size] as? Int64 {
            return size
        }
        return 0
    }

    // MARK: - Data Import

    /// Import strategies from a JSON file (bundled or downloaded)
    /// Supports both plain .json and gzip-compressed .json.gz files
    func importFromJSON(url: URL, paytableId: String, displayName: String, isBundled: Bool) async throws -> Int {
        var data = try Data(contentsOf: url)

        // Decompress if gzipped (check for gzip magic bytes: 0x1f 0x8b)
        if data.count >= 2 && data[0] == 0x1f && data[1] == 0x8b {
            guard let decompressed = decompressGzip(data) else {
                throw LocalStrategyError.decompressionFailed
            }
            data = decompressed
            NSLog("📦 Decompressed \(url.lastPathComponent): \(data.count / 1024 / 1024) MB")
        }

        // Parse JSON with streaming for large files
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let strategies = json["strategies"] as? [String: [String: Any]] else {
            throw LocalStrategyError.invalidFormat
        }

        let version = json["version"] as? Int ?? 1
        var imported = 0

        // Use transaction for better performance
        executeSQL("BEGIN TRANSACTION;")

        for (handKey, strategyData) in strategies {
            guard let bestHold = strategyData["hold"] as? Int,
                  let bestEv = strategyData["ev"] as? Double else {
                continue
            }

            // Handle hold_evs if present
            var holdEvsJson = "{}"
            if let holdEvs = strategyData["hold_evs"] as? [String: Double] {
                if let data = try? JSONEncoder().encode(holdEvs) {
                    holdEvsJson = String(data: data, encoding: .utf8) ?? "{}"
                }
            }

            insertStrategy(paytableId: paytableId, handKey: handKey, bestHold: bestHold, bestEv: bestEv, holdEvsJson: holdEvsJson)
            imported += 1

            // Commit in batches
            if imported % 10000 == 0 {
                executeSQL("COMMIT;")
                executeSQL("BEGIN TRANSACTION;")
            }
        }

        executeSQL("COMMIT;")

        // Update metadata
        updateMetadata(
            paytableId: paytableId,
            displayName: displayName,
            version: version,
            handCount: imported,
            isBundled: isBundled
        )

        print("✅ Imported \(imported) strategies for \(displayName)")
        return imported
    }

    private func insertStrategy(paytableId: String, handKey: String, bestHold: Int, bestEv: Double, holdEvsJson: String) {
        guard let stmt = insertStmt else { return }

        defer { sqlite3_reset(stmt) }

        sqlite3_bind_text(stmt, 1, paytableId, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(stmt, 2, handKey, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_int(stmt, 3, Int32(bestHold))
        sqlite3_bind_double(stmt, 4, bestEv)
        sqlite3_bind_text(stmt, 5, holdEvsJson, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

        if sqlite3_step(stmt) != SQLITE_DONE {
            // Silently continue on errors (likely duplicate)
        }
    }

    private func updateMetadata(paytableId: String, displayName: String, version: Int, handCount: Int, isBundled: Bool) {
        let sql = """
            INSERT OR REPLACE INTO paytable_meta
            (paytable_id, display_name, version, hand_count, downloaded_at, is_bundled)
            VALUES (?, ?, ?, ?, ?, ?);
        """

        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, paytableId, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            sqlite3_bind_text(stmt, 2, displayName, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            sqlite3_bind_int(stmt, 3, Int32(version))
            sqlite3_bind_int(stmt, 4, Int32(handCount))

            let dateString = ISO8601DateFormatter().string(from: Date())
            sqlite3_bind_text(stmt, 5, dateString, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            sqlite3_bind_int(stmt, 6, isBundled ? 1 : 0)

            sqlite3_step(stmt)
            sqlite3_finalize(stmt)
        }
    }

    /// Delete all data for a paytable
    func deletePaytable(paytableId: String) {
        executeSQL("DELETE FROM strategies WHERE paytable_id = '\(paytableId)';")
        executeSQL("DELETE FROM paytable_meta WHERE paytable_id = '\(paytableId)';")
        print("🗑️ Deleted local data for \(paytableId)")
    }

    /// Delete all local strategy data
    func deleteAllData() {
        executeSQL("DELETE FROM strategies;")
        executeSQL("DELETE FROM paytable_meta;")
        executeSQL("VACUUM;")
        print("🗑️ Deleted all local strategy data")
    }

    deinit {
        sqlite3_finalize(lookupStmt)
        sqlite3_finalize(insertStmt)
        sqlite3_finalize(countStmt)
        sqlite3_close(db)
    }
}

// MARK: - Supporting Types

struct PaytableMetadata {
    let paytableId: String
    let displayName: String
    let version: Int
    let handCount: Int
    let downloadedAt: String?
    let isBundled: Bool
}

enum LocalStrategyError: Error {
    case invalidFormat
    case databaseError(String)
    case fileNotFound
    case decompressionFailed
}

// MARK: - Gzip Decompression

private func decompressGzip(_ data: Data) -> Data? {
    // Skip gzip header (minimum 10 bytes)
    guard data.count > 10 else { return nil }

    // Find the start of compressed data (after header)
    var headerSize = 10
    let flags = data[3]

    // Check for optional fields in gzip header
    if flags & 0x04 != 0 { // FEXTRA
        guard data.count > headerSize + 2 else { return nil }
        let extraLen = Int(data[headerSize]) | (Int(data[headerSize + 1]) << 8)
        headerSize += 2 + extraLen
    }
    if flags & 0x08 != 0 { // FNAME - null-terminated string
        while headerSize < data.count && data[headerSize] != 0 { headerSize += 1 }
        headerSize += 1
    }
    if flags & 0x10 != 0 { // FCOMMENT - null-terminated string
        while headerSize < data.count && data[headerSize] != 0 { headerSize += 1 }
        headerSize += 1
    }
    if flags & 0x02 != 0 { // FHCRC
        headerSize += 2
    }

    guard headerSize < data.count - 8 else { return nil }

    // Get uncompressed size from last 4 bytes (little-endian)
    let sizeBytes = data.suffix(4)
    let uncompressedSize = Int(sizeBytes[sizeBytes.startIndex])
        | (Int(sizeBytes[sizeBytes.startIndex + 1]) << 8)
        | (Int(sizeBytes[sizeBytes.startIndex + 2]) << 16)
        | (Int(sizeBytes[sizeBytes.startIndex + 3]) << 24)

    // Compressed data is between header and trailer (8 bytes: CRC32 + size)
    let compressedData = data.subdata(in: headerSize..<(data.count - 8))

    // Decompress using zlib (COMPRESSION_ZLIB handles raw deflate)
    var decompressed = Data(count: uncompressedSize)
    let result = decompressed.withUnsafeMutableBytes { destBuffer in
        compressedData.withUnsafeBytes { srcBuffer in
            compression_decode_buffer(
                destBuffer.bindMemory(to: UInt8.self).baseAddress!,
                uncompressedSize,
                srcBuffer.bindMemory(to: UInt8.self).baseAddress!,
                compressedData.count,
                nil,
                COMPRESSION_ZLIB
            )
        }
    }

    return result > 0 ? decompressed.prefix(result) : nil
}
