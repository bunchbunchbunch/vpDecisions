import SwiftUI

enum HandCategory: String, CaseIterable, Codable {
    case highPairs = "high_pairs"
    case lowPairs = "low_pairs"
    case twoPair = "two_pair"
    case threeOfAKind = "three_of_a_kind"
    case fourToFlush = "four_to_flush"
    case openEndedStraight = "open_ended_straight"
    case insideStraight = "inside_straight"
    case fourToRoyal = "four_to_royal"
    case fourToStraightFlush = "four_to_straight_flush"
    case threeToRoyal = "three_to_royal"
    case threeToStraightFlush = "three_to_straight_flush"
    case highCards = "high_cards"
    case discardAll = "discard_all"
    case madeHands = "made_hands"
    case mixedDecisions = "mixed_decisions"

    var displayName: String {
        switch self {
        case .highPairs: return "High Pairs (J-A)"
        case .lowPairs: return "Low Pairs (2-T)"
        case .twoPair: return "Two Pair"
        case .threeOfAKind: return "Three of a Kind"
        case .fourToFlush: return "Four to a Flush"
        case .openEndedStraight: return "Open-Ended Straight Draw"
        case .insideStraight: return "Inside Straight Draw"
        case .fourToRoyal: return "Four to a Royal"
        case .fourToStraightFlush: return "Four to Straight Flush"
        case .threeToRoyal: return "Three to a Royal"
        case .threeToStraightFlush: return "Three to Straight Flush"
        case .highCards: return "High Cards Only"
        case .discardAll: return "Discard All"
        case .madeHands: return "Made Hands"
        case .mixedDecisions: return "Mixed Decisions"
        }
    }

    var color: Color {
        switch self {
        case .highPairs: return Color(hex: "27ae60")      // Green
        case .lowPairs: return Color(hex: "2ecc71")       // Light green
        case .twoPair: return Color(hex: "3498db")        // Blue
        case .threeOfAKind: return Color(hex: "9b59b6")   // Purple
        case .fourToFlush: return Color(hex: "1abc9c")    // Teal
        case .openEndedStraight: return Color(hex: "e67e22") // Orange
        case .insideStraight: return Color(hex: "d35400") // Dark orange
        case .fourToRoyal: return Color(hex: "f1c40f")    // Gold
        case .fourToStraightFlush: return Color(hex: "e74c3c") // Red
        case .threeToRoyal: return Color(hex: "f39c12")   // Yellow-orange
        case .threeToStraightFlush: return Color(hex: "c0392b") // Dark red
        case .highCards: return Color(hex: "7f8c8d")      // Gray
        case .discardAll: return Color(hex: "95a5a6")     // Light gray
        case .madeHands: return Color(hex: "2c3e50")      // Dark blue
        case .mixedDecisions: return Color(hex: "8e44ad") // Dark purple
        }
    }

    /// Categorize a hand based on the optimal hold
    static func categorize(hand: Hand, holdIndices: [Int]) -> HandCategory {
        let heldCards = hand.cardsAtIndices(holdIndices)
        let holdCount = holdIndices.count

        // No cards held = discard all
        if holdCount == 0 {
            return .discardAll
        }

        // All 5 cards held = made hand
        if holdCount == 5 {
            return .madeHands
        }

        // Check for pairs
        let ranks = heldCards.map { $0.rank }
        let rankCounts = Dictionary(grouping: ranks, by: { $0 }).mapValues { $0.count }
        let maxCount = rankCounts.values.max() ?? 0

        if maxCount == 3 {
            return .threeOfAKind
        }

        if maxCount == 2 {
            let pairCount = rankCounts.values.filter { $0 == 2 }.count
            if pairCount == 2 {
                return .twoPair
            }
            // Single pair
            let pairRank = rankCounts.first { $0.value == 2 }?.key
            if let rank = pairRank {
                if rank.rawValue >= Rank.jack.rawValue {
                    return .highPairs
                } else {
                    return .lowPairs
                }
            }
        }

        // Check for flush draws (4 cards same suit)
        let suits = heldCards.map { $0.suit }
        let suitCounts = Dictionary(grouping: suits, by: { $0 }).mapValues { $0.count }
        let maxSuitCount = suitCounts.values.max() ?? 0

        if holdCount == 4 && maxSuitCount == 4 {
            // Check if it's a royal or straight flush draw
            let sortedRanks = ranks.sorted()
            let hasHighCards = sortedRanks.contains { $0.rawValue >= Rank.ten.rawValue }

            if hasHighCards && sortedRanks.contains(.ace) {
                return .fourToRoyal
            }
            // Check for straight flush possibility
            let rankValues = sortedRanks.map { $0.rawValue }
            let range = (rankValues.max() ?? 0) - (rankValues.min() ?? 0)
            if range <= 4 {
                return .fourToStraightFlush
            }
            return .fourToFlush
        }

        // Check for 3 to royal/straight flush
        if holdCount == 3 && maxSuitCount == 3 {
            let sortedRanks = ranks.sorted()
            let hasHighCards = sortedRanks.allSatisfy { $0.rawValue >= Rank.ten.rawValue }
            if hasHighCards {
                return .threeToRoyal
            }
            return .threeToStraightFlush
        }

        // Check for straight draws (4 cards)
        if holdCount == 4 {
            let sortedRankValues = ranks.map { $0.rawValue }.sorted()
            let range = sortedRankValues.last! - sortedRankValues.first!

            if range == 3 {
                return .openEndedStraight
            } else if range == 4 {
                return .insideStraight
            }
        }

        // High cards only (holding just high cards)
        let highCardCount = ranks.filter { $0.rawValue >= Rank.jack.rawValue }.count
        if highCardCount > 0 && holdCount <= 2 {
            return .highCards
        }

        return .mixedDecisions
    }
}
