import Foundation

struct DealtWinnerResult {
    let isWinner: Bool
    let handName: String?
    let winningIndices: [Int]
}

actor HandEvaluator {
    static let shared = HandEvaluator()

    private init() {}

    // MARK: - Shared Resolution Helpers

    /// Data-driven quad hand name resolution. Checks paytable row names to find the correct
    /// hand name for a given quad rank and kicker, without relying on paytable ID strings.
    static nonisolated func resolveQuadHandName(
        quadRank: Int,
        kickerRank: Int,
        paytableRowNames: Set<String>
    ) -> String {
        // Aces
        if quadRank == 14 {
            if kickerRank >= 2 && kickerRank <= 4 && paytableRowNames.contains("Four Aces + 2-4") {
                return "Four Aces + 2-4"
            }
            if kickerRank >= 11 && paytableRowNames.contains("Four Aces + Face") {
                return "Four Aces + Face"
            }
            if paytableRowNames.contains("Four Aces") { return "Four Aces" }
            if paytableRowNames.contains("Four Aces/Eights") { return "Four Aces/Eights" }
        }

        // Face cards (J/Q/K = ranks 11–13)
        if quadRank >= 11 && quadRank <= 13 {
            if kickerRank >= 11 && paytableRowNames.contains("Four Face + A-K") {
                return "Four Face + A-K"
            }
            if kickerRank >= 11 && paytableRowNames.contains("Four K/Q/J + Face") {
                return "Four K/Q/J + Face"
            }
            if (kickerRank == 14 || (kickerRank >= 2 && kickerRank <= 4)) && paytableRowNames.contains("Four J-K + A-4") {
                return "Four J-K + A-4"
            }
            if paytableRowNames.contains("Four J-K") { return "Four J-K" }
            if paytableRowNames.contains("Four K/Q/J") { return "Four K/Q/J" }
            if paytableRowNames.contains("Four Face") { return "Four Face" }
            if paytableRowNames.contains("Four 5-K") { return "Four 5-K" }
            if paytableRowNames.contains("Four 2-6/9-K") { return "Four 2-6/9-K" }
        }

        // Eights (special case for Aces & Eights)
        if quadRank == 8 && paytableRowNames.contains("Four Aces/Eights") {
            return "Four Aces/Eights"
        }

        // Sevens (special case for Aces & Eights)
        if quadRank == 7 && paytableRowNames.contains("Four Sevens") {
            return "Four Sevens"
        }

        // Low ranks (2–4)
        if quadRank >= 2 && quadRank <= 4 {
            if kickerRank >= 2 && kickerRank <= 4 && paytableRowNames.contains("Four 2-4 + 2-4") {
                return "Four 2-4 + 2-4"
            }
            if (kickerRank == 14 || (kickerRank >= 2 && kickerRank <= 4)) && paytableRowNames.contains("Four 2-4 + A-4") {
                return "Four 2-4 + A-4"
            }
            if paytableRowNames.contains("Four 2-4") { return "Four 2-4" }
            if paytableRowNames.contains("Four 2-10") { return "Four 2-10" }
            if paytableRowNames.contains("Four 2-6/9-K") { return "Four 2-6/9-K" }
        }

        // Remaining ranks (5–10, or J–K without a specific matching row)
        if paytableRowNames.contains("Four 5-K") { return "Four 5-K" }
        if quadRank <= 10 && paytableRowNames.contains("Four 2-10") { return "Four 2-10" }
        if ((quadRank >= 2 && quadRank <= 6) || (quadRank >= 9 && quadRank <= 13)) &&
            paytableRowNames.contains("Four 2-6/9-K") {
            return "Four 2-6/9-K"
        }

        return "Four of a Kind"
    }

    /// Returns the high pair row name and minimum qualifying rank for the given paytable,
    /// or nil if no pair qualifies (e.g. pure deuces wild variants).
    static nonisolated func resolveHighPairInfo(
        paytableRowNames: Set<String>
    ) -> (name: String, minRank: Int)? {
        if paytableRowNames.contains("Pair of Aces") { return ("Pair of Aces", 14) }
        if paytableRowNames.contains("Kings or Better") { return ("Kings or Better", 13) }
        if paytableRowNames.contains("Jacks or Better") { return ("Jacks or Better", 11) }
        if paytableRowNames.contains("Tens or Better") { return ("Tens or Better", 10) }
        return nil
    }

    /// Check if a dealt hand is a winner for the given paytable
    nonisolated func evaluateDealtHand(hand: Hand, paytableId: String) -> DealtWinnerResult {
        // Count cards by rank
        var rankCounts: [Int: Int] = [:]
        for card in hand.cards {
            rankCounts[card.rank.rawValue, default: 0] += 1
        }

        // Check for pairs and their ranks
        let pairs = rankCounts.filter { $0.value == 2 }.map { $0.key }.sorted(by: >)
        let trips = rankCounts.filter { $0.value == 3 }.map { $0.key }
        let quads = rankCounts.filter { $0.value == 4 }.map { $0.key }

        // Count deuces (2s) for Deuces Wild games
        let numDeuces = rankCounts[2, default: 0]

        // Build paytable row name set for data-driven hand name resolution
        let paytableRowNames: Set<String>
        if let paytable = PayTable.allPayTables.first(where: { $0.id == paytableId }) {
            paytableRowNames = Set(paytable.rows.map { $0.handName })
        } else {
            paytableRowNames = []
        }

        // Evaluate based on paytable family
        if paytableId.hasPrefix("deuces-wild") || paytableId.hasPrefix("loose-deuces") {
            return evaluateDeucesWild(hand: hand, rankCounts: rankCounts, numDeuces: numDeuces)
        } else if paytableId == "tens-or-better-6-5" {
            return evaluateTensOrBetter(hand: hand, pairs: pairs, trips: trips, quads: quads, paytableRowNames: paytableRowNames)
        } else {
            // Jacks or Better family (including all bonus variants)
            return evaluateJacksOrBetter(hand: hand, pairs: pairs, trips: trips, quads: quads, paytableRowNames: paytableRowNames)
        }
    }

    // MARK: - Jacks or Better Evaluation

    nonisolated private func evaluateJacksOrBetter(hand: Hand, pairs: [Int], trips: [Int], quads: [Int], paytableRowNames: Set<String>) -> DealtWinnerResult {
        // Royal Flush
        if isRoyalFlush(hand: hand) {
            return DealtWinnerResult(
                isWinner: true,
                handName: "Royal Flush",
                winningIndices: Array(0..<5)
            )
        }

        // Straight Flush
        if isStraightFlush(hand: hand) {
            return DealtWinnerResult(
                isWinner: true,
                handName: "Straight Flush",
                winningIndices: Array(0..<5)
            )
        }

        // Four of a kind (data-driven: resolves bonus quad names)
        if let quadRank = quads.first {
            let indices = getCardIndices(hand: hand, rank: quadRank)
            let kicker = hand.cards.first { $0.rank.rawValue != quadRank }?.rank.rawValue ?? 0
            let handName = HandEvaluator.resolveQuadHandName(quadRank: quadRank, kickerRank: kicker, paytableRowNames: paytableRowNames)
            return DealtWinnerResult(
                isWinner: true,
                handName: handName,
                winningIndices: indices
            )
        }

        // Full house
        if !trips.isEmpty && !pairs.isEmpty {
            let tripIndices = getCardIndices(hand: hand, rank: trips[0])
            let pairIndices = getCardIndices(hand: hand, rank: pairs[0])
            return DealtWinnerResult(
                isWinner: true,
                handName: "Full House",
                winningIndices: tripIndices + pairIndices
            )
        }

        // Flush
        if isFlush(hand: hand) {
            return DealtWinnerResult(
                isWinner: true,
                handName: "Flush",
                winningIndices: Array(0..<5)
            )
        }

        // Straight
        if isStraight(hand: hand) {
            return DealtWinnerResult(
                isWinner: true,
                handName: "Straight",
                winningIndices: Array(0..<5)
            )
        }

        // Three of a kind
        if let tripRank = trips.first {
            let indices = getCardIndices(hand: hand, rank: tripRank)
            return DealtWinnerResult(
                isWinner: true,
                handName: "Three of a Kind",
                winningIndices: indices
            )
        }

        // Two pair
        if pairs.count >= 2 {
            let indices1 = getCardIndices(hand: hand, rank: pairs[0])
            let indices2 = getCardIndices(hand: hand, rank: pairs[1])
            return DealtWinnerResult(
                isWinner: true,
                handName: "Two Pair",
                winningIndices: indices1 + indices2
            )
        }

        // High pair (data-driven: Pair of Aces / Kings or Better / Jacks or Better)
        if let pairInfo = HandEvaluator.resolveHighPairInfo(paytableRowNames: paytableRowNames) {
            for pairRank in pairs {
                if pairRank >= pairInfo.minRank {
                    let indices = getCardIndices(hand: hand, rank: pairRank)
                    return DealtWinnerResult(
                        isWinner: true,
                        handName: pairInfo.name,
                        winningIndices: indices
                    )
                }
            }
        }

        return DealtWinnerResult(isWinner: false, handName: nil, winningIndices: [])
    }

    // MARK: - Tens or Better Evaluation

    nonisolated private func evaluateTensOrBetter(hand: Hand, pairs: [Int], trips: [Int], quads: [Int], paytableRowNames: Set<String>) -> DealtWinnerResult {
        // Same as Jacks or Better but minimum is Tens (T=10)

        // Royal Flush
        if isRoyalFlush(hand: hand) {
            return DealtWinnerResult(
                isWinner: true,
                handName: "Royal Flush",
                winningIndices: Array(0..<5)
            )
        }

        // Straight Flush
        if isStraightFlush(hand: hand) {
            return DealtWinnerResult(
                isWinner: true,
                handName: "Straight Flush",
                winningIndices: Array(0..<5)
            )
        }

        // Four of a kind
        if let quadRank = quads.first {
            let indices = getCardIndices(hand: hand, rank: quadRank)
            let kicker = hand.cards.first { $0.rank.rawValue != quadRank }?.rank.rawValue ?? 0
            let handName = HandEvaluator.resolveQuadHandName(quadRank: quadRank, kickerRank: kicker, paytableRowNames: paytableRowNames)
            return DealtWinnerResult(
                isWinner: true,
                handName: handName,
                winningIndices: indices
            )
        }

        // Full house
        if !trips.isEmpty && !pairs.isEmpty {
            let tripIndices = getCardIndices(hand: hand, rank: trips[0])
            let pairIndices = getCardIndices(hand: hand, rank: pairs[0])
            return DealtWinnerResult(
                isWinner: true,
                handName: "Full House",
                winningIndices: tripIndices + pairIndices
            )
        }

        // Flush
        if isFlush(hand: hand) {
            return DealtWinnerResult(
                isWinner: true,
                handName: "Flush",
                winningIndices: Array(0..<5)
            )
        }

        // Straight
        if isStraight(hand: hand) {
            return DealtWinnerResult(
                isWinner: true,
                handName: "Straight",
                winningIndices: Array(0..<5)
            )
        }

        // Three of a kind
        if let tripRank = trips.first {
            let indices = getCardIndices(hand: hand, rank: tripRank)
            return DealtWinnerResult(
                isWinner: true,
                handName: "Three of a Kind",
                winningIndices: indices
            )
        }

        // Two pair
        if pairs.count >= 2 {
            let indices1 = getCardIndices(hand: hand, rank: pairs[0])
            let indices2 = getCardIndices(hand: hand, rank: pairs[1])
            return DealtWinnerResult(
                isWinner: true,
                handName: "Two Pair",
                winningIndices: indices1 + indices2
            )
        }

        // Pair of Tens or Better (T=10, J=11, Q=12, K=13, A=14)
        if let pairInfo = HandEvaluator.resolveHighPairInfo(paytableRowNames: paytableRowNames) {
            for pairRank in pairs {
                if pairRank >= pairInfo.minRank {
                    let indices = getCardIndices(hand: hand, rank: pairRank)
                    return DealtWinnerResult(
                        isWinner: true,
                        handName: pairInfo.name,
                        winningIndices: indices
                    )
                }
            }
        }

        return DealtWinnerResult(isWinner: false, handName: nil, winningIndices: [])
    }

    // MARK: - Deuces Wild Evaluation

    nonisolated private func evaluateDeucesWild(hand: Hand, rankCounts: [Int: Int], numDeuces: Int) -> DealtWinnerResult {
        // Minimum paying hand is Three of a Kind

        // Natural Royal Flush (no deuces)
        if numDeuces == 0 && isRoyalFlush(hand: hand) {
            return DealtWinnerResult(
                isWinner: true,
                handName: "Natural Royal",
                winningIndices: Array(0..<5)
            )
        }

        // Four Deuces
        if numDeuces == 4 {
            let indices = getCardIndices(hand: hand, rank: 2)
            return DealtWinnerResult(
                isWinner: true,
                handName: "Four Deuces",
                winningIndices: indices
            )
        }

        // Wild Royal (with deuces)
        if numDeuces > 0 && isWildRoyalFlush(hand: hand, numDeuces: numDeuces) {
            return DealtWinnerResult(
                isWinner: true,
                handName: "Wild Royal",
                winningIndices: Array(0..<5)
            )
        }

        // Five of a Kind (needs deuces)
        let maxCount = rankCounts.filter { $0.key != 2 }.map { $0.value }.max() ?? 0
        if maxCount + numDeuces >= 5 {
            return DealtWinnerResult(
                isWinner: true,
                handName: "Five of a Kind",
                winningIndices: Array(0..<5)
            )
        }

        // Straight Flush
        if isStraightFlushWithWilds(hand: hand, numDeuces: numDeuces) {
            return DealtWinnerResult(
                isWinner: true,
                handName: "Straight Flush",
                winningIndices: Array(0..<5)
            )
        }

        // Four of a Kind
        if maxCount + numDeuces >= 4 {
            let rank = rankCounts.filter { $0.key != 2 && $0.value == maxCount }.map { $0.key }.first
            if let rank = rank {
                let indices = getCardIndices(hand: hand, rank: rank) + getCardIndices(hand: hand, rank: 2)
                return DealtWinnerResult(
                    isWinner: true,
                    handName: "Four of a Kind",
                    winningIndices: Array(indices.prefix(4))
                )
            }
        }

        // Full House (with deuces can make trips + pair)
        if canMakeFullHouse(rankCounts: rankCounts, numDeuces: numDeuces) {
            return DealtWinnerResult(
                isWinner: true,
                handName: "Full House",
                winningIndices: Array(0..<5)
            )
        }

        // Flush (deuces are wild for suit)
        if isFlushWithWilds(hand: hand) {
            return DealtWinnerResult(
                isWinner: true,
                handName: "Flush",
                winningIndices: Array(0..<5)
            )
        }

        // Straight
        if isStraightWithWilds(hand: hand, numDeuces: numDeuces) {
            return DealtWinnerResult(
                isWinner: true,
                handName: "Straight",
                winningIndices: Array(0..<5)
            )
        }

        // Three of a Kind (minimum paying hand)
        if maxCount + numDeuces >= 3 {
            let rank = rankCounts.filter { $0.key != 2 && $0.value == maxCount }.map { $0.key }.first
            if let rank = rank {
                let indices = getCardIndices(hand: hand, rank: rank) + getCardIndices(hand: hand, rank: 2)
                return DealtWinnerResult(
                    isWinner: true,
                    handName: "Three of a Kind",
                    winningIndices: Array(indices.prefix(3))
                )
            }
        }

        return DealtWinnerResult(isWinner: false, handName: nil, winningIndices: [])
    }

    // MARK: - Helper Functions

    nonisolated private func getCardIndices(hand: Hand, rank: Int) -> [Int] {
        return hand.cards.enumerated().compactMap { index, card in
            card.rank.rawValue == rank ? index : nil
        }
    }

    nonisolated private func isFlush(hand: Hand) -> Bool {
        let firstSuit = hand.cards[0].suit
        return hand.cards.allSatisfy { $0.suit == firstSuit }
    }

    /// Check for flush in Deuces Wild where 2s are wild cards (can be any suit)
    nonisolated private func isFlushWithWilds(hand: Hand) -> Bool {
        // Get non-deuce cards (deuces are wild for suit)
        let nonDeuceCards = hand.cards.filter { $0.rank.rawValue != 2 }

        // If all cards are deuces, any flush is possible
        if nonDeuceCards.isEmpty {
            return true
        }

        // Check if all non-deuce cards are the same suit
        let firstSuit = nonDeuceCards[0].suit
        return nonDeuceCards.allSatisfy { $0.suit == firstSuit }
    }

    nonisolated private func isStraight(hand: Hand) -> Bool {
        let ranks = hand.cards.map { $0.rank.rawValue }.sorted()

        // Check for regular straight
        var isConsecutive = true
        for i in 0..<4 {
            if ranks[i+1] != ranks[i] + 1 {
                isConsecutive = false
                break
            }
        }
        if isConsecutive { return true }

        // Check for A-2-3-4-5 (wheel)
        if ranks == [2, 3, 4, 5, 14] {
            return true
        }

        return false
    }

    /// Check for straight in Deuces Wild where 2s are wild cards
    nonisolated private func isStraightWithWilds(hand: Hand, numDeuces: Int) -> Bool {
        // Get non-wild ranks (exclude 2s)
        let nonWildRanks = hand.cards
            .filter { $0.rank.rawValue != 2 }
            .map { $0.rank.rawValue }

        // If all cards are wild, any straight is possible
        if nonWildRanks.isEmpty {
            return true
        }

        // Try each possible straight window (A-low through 10-high)
        // Straights: A-2-3-4-5 (1-5), 2-6, 3-7, 4-8, 5-9, 6-10, 7-J, 8-Q, 9-K, 10-A
        let startRanks = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

        for low in startRanks {
            let high = low + 4

            // Check if ALL non-wild cards fit in this window
            var allFit = true
            for rank in nonWildRanks {
                // For A-low straight (wheel), Ace (14) counts as 1
                let effectiveRank = (low == 1 && rank == 14) ? 1 : rank
                if effectiveRank < low || effectiveRank > high {
                    allFit = false
                    break
                }
            }

            if allFit {
                // Count unique ranks in this window to see how many wilds we need
                let uniqueRanksInWindow = Set(nonWildRanks.map { rank -> Int in
                    (low == 1 && rank == 14) ? 1 : rank
                })
                let neededWilds = 5 - uniqueRanksInWindow.count
                if neededWilds <= numDeuces {
                    return true
                }
            }
        }

        return false
    }

    nonisolated private func isStraightFlush(hand: Hand) -> Bool {
        return isFlush(hand: hand) && isStraight(hand: hand)
    }

    /// Check for straight flush in Deuces Wild where 2s are wild cards
    nonisolated private func isStraightFlushWithWilds(hand: Hand, numDeuces: Int) -> Bool {
        // Check if non-deuce cards are all same suit (deuces are wild for suit)
        let nonDeuceCards = hand.cards.filter { $0.rank.rawValue != 2 }
        if !nonDeuceCards.isEmpty {
            let firstSuit = nonDeuceCards[0].suit
            if !nonDeuceCards.allSatisfy({ $0.suit == firstSuit }) {
                return false
            }
        }
        return isStraightWithWilds(hand: hand, numDeuces: numDeuces)
    }

    nonisolated private func isRoyalFlush(hand: Hand) -> Bool {
        if !isFlush(hand: hand) { return false }
        let ranks = Set(hand.cards.map { $0.rank.rawValue })
        return ranks == Set([10, 11, 12, 13, 14]) // T, J, Q, K, A
    }

    nonisolated private func isWildRoyalFlush(hand: Hand, numDeuces: Int) -> Bool {
        if numDeuces == 0 { return false }

        // Check if non-deuce cards are all same suit (deuces are wild for suit)
        let nonDeuceCards = hand.cards.filter { $0.rank.rawValue != 2 }
        if !nonDeuceCards.isEmpty {
            let firstSuit = nonDeuceCards[0].suit
            if !nonDeuceCards.allSatisfy({ $0.suit == firstSuit }) {
                return false
            }
        }

        // Check if we can make T-J-Q-K-A with deuces
        let nonDeuceRanks = nonDeuceCards.map { $0.rank.rawValue }
        let royalRanks: Set<Int> = [10, 11, 12, 13, 14]

        // Check if non-deuce cards are subset of royal ranks
        if !Set(nonDeuceRanks).isSubset(of: royalRanks) { return false }

        // Check if we have enough deuces to complete
        let missing = royalRanks.subtracting(nonDeuceRanks).count
        return missing <= numDeuces
    }

    nonisolated private func canMakeFullHouse(rankCounts: [Int: Int], numDeuces: Int) -> Bool {
        let nonDeuces = rankCounts.filter { $0.key != 2 }.sorted { $0.value > $1.value }

        if nonDeuces.count >= 2 {
            let first = nonDeuces[0].value
            let second = nonDeuces[1].value

            // Can we make trips from first and pair from second?
            let neededForTrips = max(0, 3 - first)
            let neededForPair = max(0, 2 - second)

            return neededForTrips + neededForPair <= numDeuces
        }

        return false
    }
}
