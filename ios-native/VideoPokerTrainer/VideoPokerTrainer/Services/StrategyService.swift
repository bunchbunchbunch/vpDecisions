import Foundation

// MARK: - Local Strategy Models
struct LocalStrategyFile: Codable {
    let game: String
    let paytableId: String
    let version: String
    let generated: String
    let handCount: Int
    let strategies: [String: LocalStrategy]

    enum CodingKeys: String, CodingKey {
        case game
        case paytableId = "paytable_id"
        case version
        case generated
        case handCount = "hand_count"
        case strategies
    }
}

struct LocalStrategy: Codable {
    let hold: Int
    let ev: Double
}

actor StrategyService {
    static let shared = StrategyService()

    private var cache: [String: StrategyResult] = [:]
    private let maxCacheSize = 100

    // Local strategy data loaded from JSON files
    private var localStrategies: [String: [String: LocalStrategy]] = [:]
    private var isLocalDataLoaded = false

    private init() {
        Task {
            await loadLocalStrategies()
        }
    }

    /// Load local strategy JSON files from app bundle
    private func loadLocalStrategies() {
        let paytableFiles: [(id: String, filename: String)] = [
            ("jacks-or-better-9-6", "strategy_jacks_or_better_9_6"),
            ("double-double-bonus-9-6", "strategy_double_double_bonus_9_6"),
            ("bonus-poker-8-5", "strategy_bonus_poker_8_5")
        ]

        for (paytableId, filename) in paytableFiles {
            guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
                print("Warning: Could not find \(filename).json in bundle")
                continue
            }

            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode(LocalStrategyFile.self, from: data)
                localStrategies[paytableId] = decoded.strategies
                print("Loaded \(decoded.handCount) strategies for \(decoded.game)")
            } catch {
                print("Error loading \(filename).json: \(error)")
            }
        }

        isLocalDataLoaded = true
        print("Local strategies loaded: \(localStrategies.keys.joined(separator: ", "))")
    }

    /// Lookup optimal strategy for a hand
    func lookup(hand: Hand, paytableId: String) async throws -> StrategyResult? {
        let key = "\(paytableId):\(hand.canonicalKey)"

        // Check cache first
        if let cached = cache[key] {
            return cached
        }

        // Try Supabase first to get full strategy with all hold options
        if let result = try await SupabaseService.shared.lookupStrategy(
            paytableId: paytableId,
            handKey: hand.canonicalKey
        ) {
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

        // Fall back to local strategies if Supabase fails (offline mode)
        if let localStrategy = localStrategies[paytableId]?[hand.canonicalKey] {
            // Create a StrategyResult from local data (without hold_evs)
            let result = StrategyResult(
                bestHold: localStrategy.hold,
                bestEv: localStrategy.ev,
                holdEvs: [:]  // Not included in local data
            )

            // Cache it
            cache[key] = result
            return result
        }

        return nil
    }

    /// Clear the cache
    func clearCache() {
        cache.removeAll()
    }
}
