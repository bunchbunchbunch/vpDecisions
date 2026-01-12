import Foundation

/// Unified strategy lookup service that uses the fastest available source
/// Priority: Binary V2 (full holdEvs) → SQLite → Binary V1 (no holdEvs)
actor StrategyLookupService {
    static let shared = StrategyLookupService()

    private init() {}

    /// Look up strategy for a hand, using the fastest available source with holdEvs
    /// Returns nil if no strategy is available for this paytable/hand
    func lookup(paytableId: String, handKey: String) async -> StrategyResult? {
        // Try binary V2 store first (O(log n) on mmap'd data, has full holdEvs)
        if let v2Result = await BinaryStrategyStoreV2.shared.lookup(paytableId: paytableId, handKey: handKey) {
            return v2Result
        }

        // Try SQLite store (downloaded/decompressed strategies, has holdEvs)
        if let sqliteResult = await LocalStrategyStore.shared.lookup(paytableId: paytableId, handKey: handKey) {
            return sqliteResult
        }

        // Fall back to binary V1 store (no holdEvs - returns empty)
        if let binaryResult = await BinaryStrategyStore.shared.lookup(paytableId: paytableId, handKey: handKey) {
            return binaryResult.toStrategyResult()
        }

        return nil
    }

    /// Check if any strategy data is available for a paytable
    func hasStrategyData(paytableId: String) async -> Bool {
        // Check binary V2 first
        if await BinaryStrategyStoreV2.shared.hasStrategyFile(paytableId: paytableId) {
            return true
        }

        // Check SQLite
        if await LocalStrategyStore.shared.hasLocalData(paytableId: paytableId) {
            return true
        }

        // Check binary V1
        return await BinaryStrategyStore.shared.hasStrategyFile(paytableId: paytableId)
    }

    /// Get source type used for a paytable (for debugging/display)
    func getStrategySource(paytableId: String) async -> StrategySource {
        if await BinaryStrategyStoreV2.shared.hasStrategyFile(paytableId: paytableId) {
            return .binaryV2
        }

        if await LocalStrategyStore.shared.hasLocalData(paytableId: paytableId) {
            return .sqlite
        }

        if await BinaryStrategyStore.shared.hasStrategyFile(paytableId: paytableId) {
            return .binaryV1
        }

        return .none
    }

    /// Get all available paytables from all sources
    func getAllAvailablePaytables() async -> Set<String> {
        var paytables = Set<String>()

        // Get binary V2 paytables
        let v2Paytables = await BinaryStrategyStoreV2.shared.getAvailablePaytables()
        paytables.formUnion(v2Paytables)

        // Get binary V1 paytables
        let v1Paytables = await BinaryStrategyStore.shared.getAvailablePaytables()
        paytables.formUnion(v1Paytables)

        // Get SQLite paytables
        let sqlitePaytables = await LocalStrategyStore.shared.getAvailablePaytables()
        paytables.formUnion(sqlitePaytables.map { $0.paytableId })

        return paytables
    }

    /// Preload a paytable into memory for faster subsequent lookups
    func preload(paytableId: String) async -> Bool {
        // Try to preload binary V2 (memory-map the file with holdEvs)
        if await BinaryStrategyStoreV2.shared.preload(paytableId: paytableId) {
            return true
        }

        // Try to preload binary V1 (memory-map the file, no holdEvs)
        if await BinaryStrategyStore.shared.preload(paytableId: paytableId) {
            return true
        }

        // SQLite is already "preloaded" (using prepared statements)
        return await LocalStrategyStore.shared.hasLocalData(paytableId: paytableId)
    }
}

/// Strategy data source type
enum StrategySource: String {
    case binaryV2 = "Binary V2 (mmap, full EVs)"
    case binaryV1 = "Binary V1 (mmap)"
    case sqlite = "SQLite"
    case none = "None"
}
