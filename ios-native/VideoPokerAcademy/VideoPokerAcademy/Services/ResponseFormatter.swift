import Foundation

struct ResponseFormatter {

    // MARK: - Spoken Rank Map (words only, never digits)

    static let spokenRank: [Rank: String] = [
        .two: "two", .three: "three", .four: "four", .five: "five",
        .six: "six", .seven: "seven", .eight: "eight", .nine: "nine",
        .ten: "ten", .jack: "jack", .queen: "queen", .king: "king", .ace: "ace"
    ]

    private static let royalRanks: Set<Rank> = [.ten, .jack, .queen, .king, .ace]
    private static let spokenCount = ["", "one", "two", "three", "four"]

    // MARK: - Public API

    static func format(hand: Hand, result: StrategyResult, gameFamily: GameFamily) -> String {
        let heldIndices = result.bestHoldIndices
        let heldCards = hand.cardsAtIndices(heldIndices)
        let handName = determineHandName(
            hand: hand,
            heldIndices: heldIndices,
            heldCards: heldCards,
            gameFamily: gameFamily
        )
        let holdInstruction = buildHoldInstruction(heldIndices: heldIndices, heldCards: heldCards, gameFamily: gameFamily)
        return "\(handName). \(holdInstruction)."
    }

    // MARK: - Hand Name

    private static func determineHandName(
        hand: Hand,
        heldIndices: [Int],
        heldCards: [Card],
        gameFamily: GameFamily
    ) -> String {
        if heldIndices.isEmpty { return "No made hand" }

        if heldIndices.count == 5 {
            return gameFamily.isWildGame
                ? evaluateWildHandName(hand: hand)
                : evaluateFullHandName(hand: hand)
        }
        return evaluateDrawName(heldCards: heldCards, gameFamily: gameFamily)
    }

    // Standard (non-wild) five-card hand name
    private static func evaluateFullHandName(hand: Hand) -> String {
        let ranks = hand.cards.map(\.rank)
        let suits = hand.cards.map(\.suit)
        let rankCounts = Dictionary(grouping: ranks, by: { $0 }).mapValues(\.count)
        let isFlush = Set(suits).count == 1
        let sortedRankValues = ranks.map(\.rawValue).sorted()
        let isSequential = zip(sortedRankValues, sortedRankValues.dropFirst()).allSatisfy { $1 == $0 + 1 }
        let isWheelStraight = sortedRankValues == [2, 3, 4, 5, 14]
        let isStraight = isSequential || isWheelStraight

        if isFlush && sortedRankValues == [10, 11, 12, 13, 14] { return "Royal flush" }
        if isFlush && isSequential { return "Straight flush" }
        if rankCounts.values.contains(4) { return "Four of a kind" }
        if rankCounts.values.contains(3) && rankCounts.values.contains(2) { return "Full house" }
        if isFlush { return "Flush" }
        if isStraight { return "Straight" }
        if rankCounts.values.contains(3) {
            let r = rankCounts.first { $0.value == 3 }!.key
            return "Three \(spokenRank[r]!)s"
        }
        if rankCounts.values.filter({ $0 == 2 }).count == 2 { return "Two pair" }
        if let pairRank = rankCounts.first(where: { $0.value == 2 })?.key {
            return pairRank.rawValue >= Rank.jack.rawValue
                ? "Pair of \(spokenRank[pairRank]!)s"
                : "Low pair"
        }
        return "High card"
    }

    // Wild card game five-card hand name (Deuces Wild hand hierarchy)
    private static func evaluateWildHandName(hand: Hand) -> String {
        let ranks = hand.cards.map(\.rank)
        let suits = hand.cards.map(\.suit)
        let deuceCount = ranks.filter { $0 == .two }.count
        let nonDeuceRanks = ranks.filter { $0 != .two }
        let rankCounts = Dictionary(grouping: nonDeuceRanks, by: { $0 }).mapValues(\.count)
        let isNaturalFlush = Set(suits).count == 1
        let sortedRankValues = ranks.map(\.rawValue).sorted()
        let isNaturalRoyal = isNaturalFlush && sortedRankValues == [10, 11, 12, 13, 14]

        if deuceCount == 0 && isNaturalRoyal { return "Natural royal flush" }
        if deuceCount == 4 { return "Four deuces" }
        // Five of a kind: 4 matching non-deuces + deuces fill, or any grouping with deuces
        let maxNonDeuce = rankCounts.values.max() ?? 0
        if maxNonDeuce + deuceCount >= 5 { return "Five of a kind" }
        // Wild royal: flush, contains deuces, and non-deuce ranks are all royal cards
        if isNaturalFlush && deuceCount > 0 && Set(nonDeuceRanks).isSubset(of: royalRanks) { return "Wild royal flush" }
        if maxNonDeuce + deuceCount >= 4 { return "Four of a kind" }
        return evaluateFullHandName(hand: hand) // fall back for straights, flushes, etc.
    }

    private static func evaluateDrawName(heldCards: [Card], gameFamily: GameFamily) -> String {
        let count = heldCards.count
        let prefix = count == 4 ? "Four" : count == 3 ? "Three" : count == 2 ? "Two" : "One"
        let suits = heldCards.map(\.suit)
        let ranks = heldCards.map(\.rank)
        let allSameSuit = Set(suits).count == 1

        // For wild games with held deuces, compute effective strength
        if gameFamily.isWildGame {
            let deuceCount = ranks.filter { $0 == .two }.count
            if deuceCount > 0 {
                let nonWildRanks = ranks.filter { $0 != .two }
                let nonWildCounts = Dictionary(grouping: nonWildRanks, by: { $0 }).mapValues(\.count)
                let maxNonWild = nonWildCounts.values.max() ?? 0
                let effectiveCount = maxNonWild + deuceCount

                // Suit draws (check all held cards' suits)
                let nonWildRankSet = Set(nonWildRanks)
                let isRoyalDraw = allSameSuit && nonWildRankSet.isSubset(of: royalRanks)
                if isRoyalDraw { return "\(prefix) to a royal" }
                if allSameSuit && count == 4 { return "Four to a flush" }
                if allSameSuit { return "\(prefix) to a straight flush" }

                // Wild-enhanced rank hand names (generic, per spec example)
                if effectiveCount >= 5 { return "Five of a kind" }
                if effectiveCount >= 4 { return "Four of a kind" }
                if effectiveCount >= 3 { return "Three of a kind" }
                if effectiveCount >= 2 {
                    if let pairRank = nonWildCounts.max(by: { $0.value < $1.value })?.key {
                        return pairRank.rawValue >= Rank.jack.rawValue
                            ? "Pair of \(spokenRank[pairRank]!)s"
                            : "Low pair"
                    }
                }
                return "\(prefix) to a straight"
            }
        }

        let isRoyalDraw = allSameSuit && Set(ranks).isSubset(of: royalRanks)
        if isRoyalDraw { return "\(prefix) to a royal" }
        if allSameSuit && count == 4 { return "Four to a flush" }
        if allSameSuit { return "\(prefix) to a straight flush" }

        let rankCounts = Dictionary(grouping: ranks, by: { $0 }).mapValues(\.count)
        if rankCounts.values.contains(4) { return "Four of a kind" }
        if rankCounts.values.contains(3) {
            let r = rankCounts.first { $0.value == 3 }!.key
            return "Three \(spokenRank[r]!)s"
        }
        if rankCounts.values.filter({ $0 == 2 }).count == 2 { return "Two pair" }
        if let pairRank = rankCounts.first(where: { $0.value == 2 })?.key {
            return pairRank.rawValue >= Rank.jack.rawValue
                ? "Pair of \(spokenRank[pairRank]!)s"
                : "Low pair"
        }
        return "\(prefix) to a straight"
    }

    // MARK: - Hold Instruction

    private static func buildHoldInstruction(heldIndices: [Int], heldCards: [Card], gameFamily: GameFamily) -> String {
        if heldIndices.isEmpty { return "Discard everything" }
        if heldIndices.count == 5 { return "Hold all five" }

        // For wild games, held deuces are announced as "the wild two"
        if gameFamily.isWildGame {
            let wilds = heldCards.filter { $0.rank == .two }
            let nonWilds = heldCards.filter { $0.rank != .two }
            if !wilds.isEmpty {
                let wildStr: String
                if wilds.count == 1 {
                    wildStr = "the wild two"
                } else {
                    wildStr = "\(spokenCount[wilds.count]) wild twos"
                }
                if nonWilds.isEmpty {
                    return "Hold \(wildStr)"
                }
                let nonWildPart = describeHeldCards(nonWilds)
                return "\(nonWildPart) and \(wildStr)"
            }
        }

        return describeHeldCards(heldCards)
    }

    // Returns "Hold the ..." instruction for a set of cards (no wilds)
    private static func describeHeldCards(_ cards: [Card]) -> String {
        let ranks = cards.map(\.rank)
        let rankCounts = Dictionary(grouping: ranks, by: { $0 }).mapValues(\.count)

        // Two pair: "Hold the jacks and fours"
        if rankCounts.values.filter({ $0 == 2 }).count == 2 {
            let pairs = rankCounts.filter { $0.value == 2 }.keys.sorted { $0.rawValue > $1.rawValue }
            return "Hold the \(spokenRank[pairs[0]]!)s and \(spokenRank[pairs[1]]!)s"
        }
        if let quad = rankCounts.first(where: { $0.value == 4 }) {
            return "Hold the four \(spokenRank[quad.key]!)s"
        }
        if let triple = rankCounts.first(where: { $0.value == 3 }) {
            return "Hold the three \(spokenRank[triple.key]!)s"
        }
        if let pair = rankCounts.first(where: { $0.value == 2 }) {
            return "Hold the two \(spokenRank[pair.key]!)s"
        }
        // Distinct cards: "Hold the ace, king, queen, and jack"
        let names = cards.map { spokenRank[$0.rank]! }
        switch names.count {
        case 1: return "Hold the \(names[0])"
        case 2: return "Hold the \(names[0]) and \(names[1])"
        default:
            let allButLast = names.dropLast().joined(separator: ", ")
            return "Hold the \(allButLast), and \(names.last!)"
        }
    }
}
