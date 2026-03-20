import Foundation

/// Unified strategy lookup service using Binary V2 format only
actor StrategyLookupService {
    static let shared = StrategyLookupService()

    private init() {}

    /// Look up strategy for a hand
    /// Returns nil if no strategy is available for this paytable/hand
    func lookup(paytableId: String, handKey: String) async -> StrategyResult? {
        return await BinaryStrategyStoreV2.shared.lookup(paytableId: paytableId, handKey: handKey)
    }

    /// Check if any strategy data is available for a paytable
    func hasStrategyData(paytableId: String) async -> Bool {
        return await BinaryStrategyStoreV2.shared.hasStrategyFile(paytableId: paytableId)
    }

    /// Get all available paytables
    func getAllAvailablePaytables() async -> [String] {
        return await BinaryStrategyStoreV2.shared.getAvailablePaytables()
    }

    /// Preload a paytable into memory for faster subsequent lookups
    func preload(paytableId: String) async -> Bool {
        return await BinaryStrategyStoreV2.shared.preload(paytableId: paytableId)
    }
}
