import Foundation

actor StrategyService {
    static let shared = StrategyService()

    private var cache: [String: StrategyResult] = [:]
    private let maxCacheSize = 100

    private init() {}

    /// Lookup optimal strategy for a hand
    func lookup(hand: Hand, paytableId: String) async throws -> StrategyResult? {
        let key = "\(paytableId):\(hand.canonicalKey)"

        // Check cache first
        if let cached = cache[key] {
            return cached
        }

        // Fetch from Supabase
        guard let result = try await SupabaseService.shared.lookupStrategy(
            paytableId: paytableId,
            handKey: hand.canonicalKey
        ) else {
            return nil
        }

        // Cache the result
        if cache.count >= maxCacheSize {
            // Remove oldest entries (simple approach: clear half)
            let keysToRemove = Array(cache.keys.prefix(maxCacheSize / 2))
            for key in keysToRemove {
                cache.removeValue(forKey: key)
            }
        }
        cache[key] = result

        return result
    }

    /// Clear the cache
    func clearCache() {
        cache.removeAll()
    }
}
