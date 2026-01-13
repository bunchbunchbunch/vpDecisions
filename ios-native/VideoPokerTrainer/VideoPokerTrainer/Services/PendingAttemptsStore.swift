import Foundation
import SQLite3

/// Lightweight SQLite store for pending hand attempts (offline sync)
actor PendingAttemptsStore {
    static let shared = PendingAttemptsStore()

    private var db: OpaquePointer?
    private let dbPath: String

    // Prepared statements
    private var insertPendingStmt: OpaquePointer?
    private var getPendingStmt: OpaquePointer?
    private var countPendingStmt: OpaquePointer?

    private init() {
        let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        dbPath = cachesPath.appendingPathComponent("pending_attempts.sqlite").path

        Task {
            await openDatabase()
        }
    }

    // MARK: - Database Setup

    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("❌ Error opening pending attempts database: \(String(cString: sqlite3_errmsg(db)))")
            return
        }

        createTables()
        prepareStatements()
        print("✅ PendingAttemptsStore database opened at \(dbPath)")
    }

    private func createTables() {
        let createPendingAttemptsSQL = """
            CREATE TABLE IF NOT EXISTS pending_attempts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id TEXT NOT NULL,
                hand_key TEXT NOT NULL,
                hand_category TEXT NOT NULL,
                paytable_id TEXT NOT NULL,
                user_hold TEXT NOT NULL,
                optimal_hold TEXT NOT NULL,
                is_correct INTEGER NOT NULL,
                ev_difference REAL NOT NULL,
                response_time_ms INTEGER,
                created_at TEXT NOT NULL,
                sync_status TEXT DEFAULT 'pending'
            );
        """
        executeSQL(createPendingAttemptsSQL)
        executeSQL("CREATE INDEX IF NOT EXISTS idx_pending_status ON pending_attempts(sync_status);")
    }

    private func prepareStatements() {
        let insertPendingSQL = """
            INSERT INTO pending_attempts
            (user_id, hand_key, hand_category, paytable_id, user_hold, optimal_hold, is_correct, ev_difference, response_time_ms, created_at, sync_status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending');
        """
        if sqlite3_prepare_v2(db, insertPendingSQL, -1, &insertPendingStmt, nil) != SQLITE_OK {
            print("❌ Error preparing insert pending statement: \(String(cString: sqlite3_errmsg(db)))")
        }

        let getPendingSQL = "SELECT id, user_id, hand_key, hand_category, paytable_id, user_hold, optimal_hold, is_correct, ev_difference, response_time_ms, created_at FROM pending_attempts WHERE sync_status = 'pending' ORDER BY id ASC;"
        if sqlite3_prepare_v2(db, getPendingSQL, -1, &getPendingStmt, nil) != SQLITE_OK {
            print("❌ Error preparing get pending statement: \(String(cString: sqlite3_errmsg(db)))")
        }

        let countPendingSQL = "SELECT COUNT(*) FROM pending_attempts WHERE sync_status = 'pending';"
        if sqlite3_prepare_v2(db, countPendingSQL, -1, &countPendingStmt, nil) != SQLITE_OK {
            print("❌ Error preparing count pending statement: \(String(cString: sqlite3_errmsg(db)))")
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

    /// Save a hand attempt locally for later sync
    func savePendingAttempt(_ attempt: HandAttempt) {
        guard let stmt = insertPendingStmt else { return }

        defer { sqlite3_reset(stmt) }

        let userIdString = attempt.userId.uuidString
        let userHoldJson = (try? JSONEncoder().encode(attempt.userHold)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        let optimalHoldJson = (try? JSONEncoder().encode(attempt.optimalHold)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        let createdAt = ISO8601DateFormatter().string(from: Date())

        sqlite3_bind_text(stmt, 1, userIdString, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(stmt, 2, attempt.handKey, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(stmt, 3, attempt.handCategory, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(stmt, 4, attempt.paytableId, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(stmt, 5, userHoldJson, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(stmt, 6, optimalHoldJson, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_int(stmt, 7, attempt.isCorrect ? 1 : 0)
        sqlite3_bind_double(stmt, 8, attempt.evDifference)

        if let responseTime = attempt.responseTimeMs {
            sqlite3_bind_int(stmt, 9, Int32(responseTime))
        } else {
            sqlite3_bind_null(stmt, 9)
        }

        sqlite3_bind_text(stmt, 10, createdAt, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

        if sqlite3_step(stmt) == SQLITE_DONE {
            NSLog("💾 Saved pending attempt for hand: \(attempt.handKey)")
        } else {
            NSLog("❌ Failed to save pending attempt: \(String(cString: sqlite3_errmsg(db)))")
        }
    }

    /// Get all pending (unsynced) attempts
    func getPendingAttempts() -> [PendingAttempt] {
        guard let stmt = getPendingStmt else { return [] }

        defer { sqlite3_reset(stmt) }

        var results: [PendingAttempt] = []

        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let userIdString = String(cString: sqlite3_column_text(stmt, 1))
            let handKey = String(cString: sqlite3_column_text(stmt, 2))
            let handCategory = String(cString: sqlite3_column_text(stmt, 3))
            let paytableId = String(cString: sqlite3_column_text(stmt, 4))
            let userHoldJson = String(cString: sqlite3_column_text(stmt, 5))
            let optimalHoldJson = String(cString: sqlite3_column_text(stmt, 6))
            let isCorrect = sqlite3_column_int(stmt, 7) == 1
            let evDifference = sqlite3_column_double(stmt, 8)

            let responseTimeMs: Int?
            if sqlite3_column_type(stmt, 9) != SQLITE_NULL {
                responseTimeMs = Int(sqlite3_column_int(stmt, 9))
            } else {
                responseTimeMs = nil
            }

            let createdAtString = String(cString: sqlite3_column_text(stmt, 10))

            // Parse JSON arrays
            let userHold = (try? JSONDecoder().decode([Int].self, from: userHoldJson.data(using: .utf8) ?? Data())) ?? []
            let optimalHold = (try? JSONDecoder().decode([Int].self, from: optimalHoldJson.data(using: .utf8) ?? Data())) ?? []

            // Parse date
            let createdAt = ISO8601DateFormatter().date(from: createdAtString) ?? Date()

            if let userId = UUID(uuidString: userIdString) {
                results.append(PendingAttempt(
                    id: id,
                    userId: userId,
                    handKey: handKey,
                    handCategory: handCategory,
                    paytableId: paytableId,
                    userHold: userHold,
                    optimalHold: optimalHold,
                    isCorrect: isCorrect,
                    evDifference: evDifference,
                    responseTimeMs: responseTimeMs,
                    createdAt: createdAt
                ))
            }
        }

        return results
    }

    /// Get count of pending attempts
    func getPendingAttemptCount() -> Int {
        guard let stmt = countPendingStmt else { return 0 }

        defer { sqlite3_reset(stmt) }

        if sqlite3_step(stmt) == SQLITE_ROW {
            return Int(sqlite3_column_int(stmt, 0))
        }

        return 0
    }

    /// Mark an attempt as synced
    func markAttemptSynced(id: Int64) {
        executeSQL("UPDATE pending_attempts SET sync_status = 'synced' WHERE id = \(id);")
    }

    /// Delete all synced attempts
    func clearSyncedAttempts() {
        executeSQL("DELETE FROM pending_attempts WHERE sync_status = 'synced';")
    }

    deinit {
        sqlite3_finalize(insertPendingStmt)
        sqlite3_finalize(getPendingStmt)
        sqlite3_finalize(countPendingStmt)
        sqlite3_close(db)
    }
}

// MARK: - Supporting Types

struct PendingAttempt: Identifiable {
    let id: Int64
    let userId: UUID
    let handKey: String
    let handCategory: String
    let paytableId: String
    let userHold: [Int]
    let optimalHold: [Int]
    let isCorrect: Bool
    let evDifference: Double
    let responseTimeMs: Int?
    let createdAt: Date

    func toHandAttempt() -> HandAttempt {
        HandAttempt(
            userId: userId,
            handKey: handKey,
            handCategory: handCategory,
            paytableId: paytableId,
            userHold: userHold,
            optimalHold: optimalHold,
            isCorrect: isCorrect,
            evDifference: evDifference,
            responseTimeMs: responseTimeMs
        )
    }
}
