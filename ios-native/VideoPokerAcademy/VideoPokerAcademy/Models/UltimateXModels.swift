import Foundation

// MARK: - Ultimate X Play Count

/// The number of hands played simultaneously in Ultimate X
enum UltimateXPlayCount: Int, CaseIterable, Identifiable, Codable {
    case three = 3
    case five = 5
    case ten = 10

    var id: Int { rawValue }

    var displayName: String {
        "\(rawValue)-Play"
    }
}

// MARK: - Ultimate X Multiplier Table

/// Per-game-family multiplier tables for Ultimate X poker.
/// Multiplier values sourced from Wizard of Odds (IGT-provided tables).
struct UltimateXMultiplierTable {

    // MARK: - Public API

    /// Returns the multiplier for a given hand name, play count, and game family.
    static func multiplier(for handName: String, playCount: UltimateXPlayCount, family: GameFamily) -> Int {
        let normalized = handName.lowercased()
        let group = multiplierGroup(for: family)
        switch playCount {
        case .three: return group.threePlay[normalized] ?? 1
        case .five:  return group.fivePlay[normalized]  ?? 1
        case .ten:   return group.tenPlay[normalized]   ?? 1
        }
    }

    /// Returns all distinct multiplier values that can be awarded for a game family and play count.
    static func possibleMultipliers(for playCount: UltimateXPlayCount, family: GameFamily) -> [Int] {
        let group = multiplierGroup(for: family)
        let table: [String: Int]
        switch playCount {
        case .three: table = group.threePlay
        case .five:  table = group.fivePlay
        case .ten:   table = group.tenPlay
        }
        return Array(Set(table.values)).sorted()
    }

    /// Maximum possible multiplier across all game families and play counts.
    static let maxMultiplier = 12

    // MARK: - Group Mapping

    private static func multiplierGroup(for family: GameFamily) -> MultiplierGroup {
        switch family {
        case .jacksOrBetter, .tensOrBetter, .bonusPokerDeluxe, .allAmerican:
            return jacksOrBetter
        case .bonusPoker, .bonusPokerPlus:
            return bonusPoker
        case .doubleBonus, .doubleDoubleBonus, .superDoubleBonus,
             .doubleJackpot, .doubleDoubleJackpot,
             .acesBonus, .acesAndEights, .acesAndFaces, .bonusAcesFaces,
             .superAces, .royalAcesBonus, .whiteHotAces,
             .ddbAcesFaces, .ddbPlus:
            return doubleBonus
        case .tripleDoubleBonus, .tripleBonus, .tripleBonusPlus, .tripleTripleBonus:
            return tripleDoubleBonus
        case .deucesWild, .looseDeuces:
            return deucesWild
        }
    }

    // MARK: - Multiplier Group Data

    private struct MultiplierGroup {
        let threePlay: [String: Int]
        let fivePlay:  [String: Int]
        let tenPlay:   [String: Int]
    }

    // MARK: Group 1: Jacks or Better
    // Source: Wizard of Odds — confirmed for JoB, BonusPokerDeluxe, AllAmerican, TensOrBetter
    // Note: "tens or better" included here because tensOrBetter family maps to this group.
    //       Non-JoB groups do not need this key since tensOrBetter is never assigned to them.
    // Note: "no win": 1 is included explicitly so possibleMultipliers() returns 1 via Set(table.values).

    private static let jacksOrBetter = MultiplierGroup(
        threePlay: [
            "royal flush": 2, "straight flush": 2,
            "four of a kind": 2, "four aces": 2, "four 2-4": 2, "four 5-k": 2,
            "four aces + 2-4": 2, "four 2-4 + a-4": 2,
            "four aces + face": 2, "four j-k": 2, "four j-k + a-4": 2,
            "four face": 2, "four face + a-k": 2, "four k/q/j": 2, "four k/q/j + face": 2,
            "four 2-10": 2, "four 2-6/9-k": 2, "four sevens": 2, "four aces/eights": 2,
            "four 2-4 + 2-4": 2,
            "full house": 12, "flush": 11, "straight": 7,
            "three of a kind": 4, "two pair": 3,
            "jacks or better": 2, "tens or better": 2, "no win": 1,
        ],
        fivePlay: [
            "royal flush": 2, "straight flush": 2,
            "four of a kind": 3, "four aces": 3, "four 2-4": 3, "four 5-k": 3,
            "four aces + 2-4": 3, "four 2-4 + a-4": 3,
            "four aces + face": 3, "four j-k": 3, "four j-k + a-4": 3,
            "four face": 3, "four face + a-k": 3, "four k/q/j": 3, "four k/q/j + face": 3,
            "four 2-10": 3, "four 2-6/9-k": 3, "four sevens": 3, "four aces/eights": 3,
            "four 2-4 + 2-4": 3,
            "full house": 12, "flush": 11, "straight": 7,
            "three of a kind": 4, "two pair": 3,
            "jacks or better": 2, "tens or better": 2, "no win": 1,
        ],
        tenPlay: [
            "royal flush": 7, "straight flush": 7,
            "four of a kind": 3, "four aces": 3, "four 2-4": 3, "four 5-k": 3,
            "four aces + 2-4": 3, "four 2-4 + a-4": 3,
            "four aces + face": 3, "four j-k": 3, "four j-k + a-4": 3,
            "four face": 3, "four face + a-k": 3, "four k/q/j": 3, "four k/q/j + face": 3,
            "four 2-10": 3, "four 2-6/9-k": 3, "four sevens": 3, "four aces/eights": 3,
            "four 2-4 + 2-4": 3,
            "full house": 12, "flush": 11, "straight": 7,
            "three of a kind": 4, "two pair": 3,
            "jacks or better": 2, "tens or better": 2, "no win": 1,
        ]
    )

    // MARK: Group 2: Bonus Poker
    // Source: Wizard of Odds — Straight 8x (not 7x), RF 10-play 4x (not 7x)

    private static let bonusPoker = MultiplierGroup(
        threePlay: [
            "royal flush": 2, "straight flush": 2,
            "four aces": 2, "four aces + 2-4": 2, "four aces + face": 2,
            "four 2-4": 2, "four 2-4 + a-4": 2, "four 2-4 + 2-4": 2,
            "four 5-k": 2, "four of a kind": 2,
            "four j-k": 2, "four j-k + a-4": 2, "four face": 2,
            "four face + a-k": 2, "four k/q/j": 2, "four k/q/j + face": 2,
            "four 2-10": 2, "four 2-6/9-k": 2, "four sevens": 2, "four aces/eights": 2,
            "full house": 12, "flush": 11, "straight": 8,
            "three of a kind": 4, "two pair": 3, "jacks or better": 2, "no win": 1,
        ],
        fivePlay: [
            "royal flush": 2, "straight flush": 2,
            "four aces": 2, "four aces + 2-4": 2, "four aces + face": 2,
            "four 2-4": 2, "four 2-4 + a-4": 2, "four 2-4 + 2-4": 2,
            "four 5-k": 3, "four of a kind": 3,
            "four j-k": 3, "four j-k + a-4": 3, "four face": 3,
            "four face + a-k": 3, "four k/q/j": 3, "four k/q/j + face": 3,
            "four 2-10": 3, "four 2-6/9-k": 3, "four sevens": 3, "four aces/eights": 3,
            "full house": 12, "flush": 11, "straight": 8,
            "three of a kind": 4, "two pair": 3, "jacks or better": 2, "no win": 1,
        ],
        tenPlay: [
            "royal flush": 4, "straight flush": 4,
            "four aces": 4, "four aces + 2-4": 4, "four aces + face": 4,
            "four 2-4": 4, "four 2-4 + a-4": 4, "four 2-4 + 2-4": 4,
            "four 5-k": 3, "four of a kind": 3,
            "four j-k": 3, "four j-k + a-4": 3, "four face": 3,
            "four face + a-k": 3, "four k/q/j": 3, "four k/q/j + face": 3,
            "four 2-10": 3, "four 2-6/9-k": 3, "four sevens": 3, "four aces/eights": 3,
            "full house": 12, "flush": 11, "straight": 8,
            "three of a kind": 4, "two pair": 3, "jacks or better": 2, "no win": 1,
        ]
    )

    // MARK: Group 3: Double Bonus
    // Source: Wizard of Odds — Flush 10x (not 11x), Straight 8x, RF 10-play 4x

    private static let doubleBonus = MultiplierGroup(
        threePlay: [
            "royal flush": 2, "straight flush": 2,
            "four aces": 2, "four aces + 2-4": 2, "four aces + face": 2,
            "four 2-4": 2, "four 2-4 + a-4": 2, "four 2-4 + 2-4": 2,
            "four 5-k": 2, "four of a kind": 2,
            "four j-k": 2, "four j-k + a-4": 2, "four face": 2,
            "four face + a-k": 2, "four k/q/j": 2, "four k/q/j + face": 2,
            "four 2-10": 2, "four 2-6/9-k": 2, "four sevens": 2, "four aces/eights": 2,
            "full house": 12, "flush": 10, "straight": 8,
            "three of a kind": 4, "two pair": 3, "jacks or better": 2, "no win": 1,
        ],
        fivePlay: [
            "royal flush": 2, "straight flush": 2,
            "four aces": 2, "four aces + 2-4": 2, "four aces + face": 2,
            "four 2-4": 2, "four 2-4 + a-4": 2, "four 2-4 + 2-4": 2,
            "four 5-k": 3, "four of a kind": 3,
            "four j-k": 3, "four j-k + a-4": 3, "four face": 3,
            "four face + a-k": 3, "four k/q/j": 3, "four k/q/j + face": 3,
            "four 2-10": 3, "four 2-6/9-k": 3, "four sevens": 3, "four aces/eights": 3,
            "full house": 12, "flush": 10, "straight": 8,
            "three of a kind": 4, "two pair": 3, "jacks or better": 2, "no win": 1,
        ],
        tenPlay: [
            "royal flush": 4, "straight flush": 4,
            "four aces": 4, "four aces + 2-4": 4, "four aces + face": 4,
            "four 2-4": 4, "four 2-4 + a-4": 4, "four 2-4 + 2-4": 4,
            "four 5-k": 3, "four of a kind": 3,
            "four j-k": 3, "four j-k + a-4": 3, "four face": 3,
            "four face + a-k": 3, "four k/q/j": 3, "four k/q/j + face": 3,
            "four 2-10": 3, "four 2-6/9-k": 3, "four sevens": 3, "four aces/eights": 3,
            "full house": 12, "flush": 10, "straight": 8,
            "three of a kind": 4, "two pair": 3, "jacks or better": 2, "no win": 1,
        ]
    )

    // MARK: Group 4: Triple Double Bonus
    // Source: Wizard of Odds — ALL quads flat 2x regardless of play count

    private static let tripleDoubleBonus = MultiplierGroup(
        threePlay: [
            "royal flush": 2, "straight flush": 2,
            "four aces": 2, "four aces + 2-4": 2, "four aces + face": 2,
            "four 2-4": 2, "four 2-4 + a-4": 2, "four 2-4 + 2-4": 2,
            "four 5-k": 2, "four of a kind": 2,
            "four j-k": 2, "four j-k + a-4": 2, "four face": 2,
            "four face + a-k": 2, "four k/q/j": 2, "four k/q/j + face": 2,
            "four 2-10": 2, "four 2-6/9-k": 2, "four sevens": 2, "four aces/eights": 2,
            "full house": 12, "flush": 10, "straight": 8,
            "three of a kind": 4, "two pair": 3, "jacks or better": 2, "no win": 1,
        ],
        fivePlay: [
            "royal flush": 2, "straight flush": 2,
            "four aces": 2, "four aces + 2-4": 2, "four aces + face": 2,
            "four 2-4": 2, "four 2-4 + a-4": 2, "four 2-4 + 2-4": 2,
            "four 5-k": 2, "four of a kind": 2,
            "four j-k": 2, "four j-k + a-4": 2, "four face": 2,
            "four face + a-k": 2, "four k/q/j": 2, "four k/q/j + face": 2,
            "four 2-10": 2, "four 2-6/9-k": 2, "four sevens": 2, "four aces/eights": 2,
            "full house": 12, "flush": 10, "straight": 8,
            "three of a kind": 4, "two pair": 3, "jacks or better": 2, "no win": 1,
        ],
        tenPlay: [
            "royal flush": 2, "straight flush": 2,
            "four aces": 2, "four aces + 2-4": 2, "four aces + face": 2,
            "four 2-4": 2, "four 2-4 + a-4": 2, "four 2-4 + 2-4": 2,
            "four 5-k": 2, "four of a kind": 2,
            "four j-k": 2, "four j-k + a-4": 2, "four face": 2,
            "four face + a-k": 2, "four k/q/j": 2, "four k/q/j + face": 2,
            "four 2-10": 2, "four 2-6/9-k": 2, "four sevens": 2, "four aces/eights": 2,
            "full house": 12, "flush": 10, "straight": 8,
            "three of a kind": 4, "two pair": 3, "jacks or better": 2, "no win": 1,
        ]
    )

    // MARK: Group 5: Deuces Wild
    // Source: Wizard of Odds — completely different structure; SF=12x, 4oK=7x, FH=Flush=5x
    // KEY NOTE: HandEvaluator.evaluateDeucesWild returns "Natural Royal" and "Wild Royal"
    // (not "Natural Royal Flush" / "Wild Royal Flush"). Keys must match after lowercasing.

    private static let deucesWild = MultiplierGroup(
        threePlay: [
            "natural royal": 2, "four deuces": 2, "wild royal": 2,
            "five of a kind": 2, "straight flush": 12, "four of a kind": 7,
            "full house": 5, "flush": 5, "straight": 3, "three of a kind": 2,
            "no win": 1,
        ],
        fivePlay: [
            "natural royal": 2, "four deuces": 2, "wild royal": 2,
            "five of a kind": 3, "straight flush": 12, "four of a kind": 7,
            "full house": 5, "flush": 5, "straight": 3, "three of a kind": 2,
            "no win": 1,
        ],
        tenPlay: [
            "natural royal": 4, "four deuces": 4, "wild royal": 4,
            "five of a kind": 3, "straight flush": 12, "four of a kind": 7,
            "full house": 5, "flush": 5, "straight": 3, "three of a kind": 2,
            "no win": 1,
        ]
    )
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
