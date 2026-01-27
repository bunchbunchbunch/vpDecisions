import Foundation

// MARK: - Ultimate X Play Count

/// The number of hands played simultaneously in Ultimate X
enum UltimateXPlayCount: Int, CaseIterable, Identifiable {
    case three = 3
    case five = 5
    case ten = 10

    var id: Int { rawValue }

    var displayName: String {
        "\(rawValue)-Play"
    }
}

// MARK: - Ultimate X Multiplier Table

/// Multiplier tables for Ultimate X poker
/// Multipliers are awarded based on winning hand type and apply to the NEXT hand
struct UltimateXMultiplierTable {
    /// Get the multiplier awarded for a winning hand type
    /// - Parameters:
    ///   - handName: The winning hand name (e.g., "Full House", "Flush")
    ///   - playCount: The Ultimate X play configuration (3, 5, or 10)
    /// - Returns: The multiplier to apply to the next hand (1 = no multiplier)
    static func multiplier(for handName: String, playCount: UltimateXPlayCount) -> Int {
        // Normalize hand name for lookup
        let normalized = handName.lowercased()

        switch playCount {
        case .three:
            return threePlayMultipliers[normalized] ?? 1
        case .five:
            return fivePlayMultipliers[normalized] ?? 1
        case .ten:
            return tenPlayMultipliers[normalized] ?? 1
        }
    }

    /// Get all possible multiplier values for a play count
    static func possibleMultipliers(for playCount: UltimateXPlayCount) -> [Int] {
        switch playCount {
        case .three:
            return [1, 2, 3, 4, 7, 11, 12]
        case .five:
            return [1, 2, 3, 4, 7, 11, 12]
        case .ten:
            return [1, 2, 3, 4, 7, 11, 12]
        }
    }

    /// Maximum possible multiplier
    static let maxMultiplier = 12

    // MARK: - Jacks or Better Multiplier Tables

    /// 3-Play multipliers for Jacks or Better family
    private static let threePlayMultipliers: [String: Int] = [
        "royal flush": 2,
        "straight flush": 2,
        "four of a kind": 2,
        "four aces": 2,
        "four 2-4": 2,
        "four 5-k": 2,
        "four aces + 2-4": 2,
        "four 2-4 + a-4": 2,
        "full house": 12,
        "flush": 11,
        "straight": 7,
        "three of a kind": 4,
        "two pair": 3,
        "jacks or better": 2,
        "tens or better": 2
    ]

    /// 5-Play multipliers for Jacks or Better family
    private static let fivePlayMultipliers: [String: Int] = [
        "royal flush": 2,
        "straight flush": 2,
        "four of a kind": 3,
        "four aces": 2,
        "four 2-4": 3,
        "four 5-k": 3,
        "four aces + 2-4": 2,
        "four 2-4 + a-4": 2,
        "full house": 12,
        "flush": 11,
        "straight": 7,
        "three of a kind": 4,
        "two pair": 3,
        "jacks or better": 2,
        "tens or better": 2
    ]

    /// 10-Play multipliers for Jacks or Better family
    private static let tenPlayMultipliers: [String: Int] = [
        "royal flush": 7,
        "straight flush": 7,
        "four of a kind": 3,
        "four aces": 2,
        "four 2-4": 3,
        "four 5-k": 3,
        "four aces + 2-4": 2,
        "four 2-4 + a-4": 2,
        "full house": 12,
        "flush": 11,
        "straight": 7,
        "three of a kind": 4,
        "two pair": 3,
        "jacks or better": 2,
        "tens or better": 2
    ]
}

// MARK: - Ultimate X Strategy Result

/// Extended strategy result that includes Ultimate X multiplier adjustments
struct UltimateXStrategyResult {
    /// The base strategy result (without multiplier consideration)
    let baseResult: StrategyResult

    /// The current multiplier being applied
    let currentMultiplier: Int

    /// The play count configuration
    let playCount: UltimateXPlayCount

    /// The optimal hold considering the current multiplier
    let adjustedBestHold: Int

    /// The adjusted EV for the best hold
    let adjustedBestEv: Double

    /// Adjusted EVs for all 32 hold options
    let adjustedHoldEvs: [String: Double]

    /// Whether the optimal strategy differs from base game strategy
    var strategyDiffers: Bool {
        baseResult.bestHold != adjustedBestHold
    }

    /// Get indices for the adjusted best hold
    var adjustedBestHoldIndices: [Int] {
        Hand.holdIndicesFromBitmask(adjustedBestHold)
    }

    /// Get all adjusted hold options sorted by EV (highest first)
    var sortedAdjustedHoldOptions: [(bitmask: Int, ev: Double, indices: [Int])] {
        adjustedHoldEvs.compactMap { key, ev in
            guard let bitmask = Int(key) else { return nil }
            return (bitmask: bitmask, ev: ev, indices: Hand.holdIndicesFromBitmask(bitmask))
        }.sorted { $0.ev > $1.ev }
    }

    /// Get the rank for an adjusted hold option at a given index
    func rankForAdjustedOption(at index: Int) -> Int {
        let sorted = sortedAdjustedHoldOptions
        guard index < sorted.count else { return index + 1 }

        let tolerance = 0.0001
        var rank = 1
        var previousEv: Double?

        for i in 0...index {
            if let prevEv = previousEv {
                if abs(sorted[i].ev - prevEv) >= tolerance {
                    rank = i + 1
                }
            }
            previousEv = sorted[i].ev
        }

        return rank
    }

    /// Check if a given hold is tied for best in the adjusted strategy
    func isAdjustedHoldTiedForBest(_ canonicalIndices: [Int]) -> Bool {
        let userBitmask = Hand.bitmaskFromHoldIndices(canonicalIndices)
        let sorted = sortedAdjustedHoldOptions
        guard let bestEv = sorted.first?.ev else { return false }

        let tolerance = 0.0001
        let tiedBitmasks = sorted.filter { abs($0.ev - bestEv) < tolerance }.map { $0.bitmask }
        return tiedBitmasks.contains(userBitmask)
    }
}
