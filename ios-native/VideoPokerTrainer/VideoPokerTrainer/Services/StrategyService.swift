import Foundation

actor StrategyService {
    static let shared = StrategyService()

    private var cache: [String: StrategyResult] = [:]
    private let maxCacheSize = 100

    private init() {}

    /// Lookup optimal strategy for a hand using Binary V2 format
    func lookup(hand: Hand, paytableId: String) async throws -> StrategyResult? {
        let key = "\(paytableId):\(hand.canonicalKey)"

        // 1. Check memory cache first
        if let cached = cache[key] {
            return cached
        }

        // 2. Look up from binary V2 store
        if let result = await BinaryStrategyStoreV2.shared.lookup(
            paytableId: paytableId,
            handKey: hand.canonicalKey
        ) {
            cacheResult(key: key, result: result)
            return result
        }

        // No strategy found
        NSLog("⚠️ No strategy found for %@ / %@", paytableId, hand.canonicalKey)
        return nil
    }

    /// Check if a paytable has strategy data available
    func hasOfflineData(paytableId: String) async -> Bool {
        return await BinaryStrategyStoreV2.shared.hasStrategyFile(paytableId: paytableId)
    }

    /// Prepare a paytable for use - preloads the binary file
    /// Returns true if ready, false if not available
    func preparePaytable(paytableId: String) async -> Bool {
        return await BinaryStrategyStoreV2.shared.preload(paytableId: paytableId)
    }

    /// Get all available paytables with bundled strategy data
    func getAvailablePaytables() async -> [String] {
        return await BinaryStrategyStoreV2.shared.getAvailablePaytables()
    }

    // MARK: - Cache Management

    private func cacheResult(key: String, result: StrategyResult) {
        if cache.count >= maxCacheSize {
            // Remove oldest entries (simple approach: clear half)
            let keysToRemove = Array(cache.keys.prefix(maxCacheSize / 2))
            for key in keysToRemove {
                cache.removeValue(forKey: key)
            }
        }
        cache[key] = result
    }

    /// Clear the memory cache
    func clearCache() {
        cache.removeAll()
    }
}
