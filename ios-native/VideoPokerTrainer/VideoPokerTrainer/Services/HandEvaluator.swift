import Foundation

struct DealtWinnerResult {
    let isWinner: Bool
    let handName: String?
    let winningIndices: [Int]
}

actor HandEvaluator {
    static let shared = HandEvaluator()

    private init() {}

    /// Check if a dealt hand is a winner for the given paytable
    func evaluateDealtHand(hand: Hand, paytableId: String) -> DealtWinnerResult {
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

        // Evaluate based on paytable
        switch paytableId {
        case "tens-or-better-6-5":
            return evaluateTensOrBetter(hand: hand, pairs: pairs, trips: trips, quads: quads)

        case "deuces-wild-nsud", "deuces-wild-full-pay":
            return evaluateDeucesWild(hand: hand, rankCounts: rankCounts, numDeuces: numDeuces)

        default:
            // Jacks or Better family (including all bonus variants)
            return evaluateJacksOrBetter(hand: hand, pairs: pairs, trips: trips, quads: quads)
        }
    }

    // MARK: - Jacks or Better Evaluation

    private func evaluateJacksOrBetter(hand: Hand, pairs: [Int], trips: [Int], quads: [Int]) -> DealtWinnerResult {
        // Four of a kind
        if let quadRank = quads.first {
            let indices = getCardIndices(hand: hand, rank: quadRank)
            return DealtWinnerResult(
                isWinner: true,
                handName: "Four of a Kind",
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

        // Pair of Jacks or Better (J=11, Q=12, K=13, A=14)
        for pairRank in pairs {
            if pairRank >= 11 {
                let indices = getCardIndices(hand: hand, rank: pairRank)
                return DealtWinnerResult(
                    isWinner: true,
                    handName: "Jacks or Better",
                    winningIndices: indices
                )
            }
        }

        return DealtWinnerResult(isWinner: false, handName: nil, winningIndices: [])
    }

    // MARK: - Tens or Better Evaluation

    private func evaluateTensOrBetter(hand: Hand, pairs: [Int], trips: [Int], quads: [Int]) -> DealtWinnerResult {
        // Same as Jacks or Better but minimum is Tens (T=10)

        // Four of a kind
        if let quadRank = quads.first {
            let indices = getCardIndices(hand: hand, rank: quadRank)
            return DealtWinnerResult(
                isWinner: true,
                handName: "Four of a Kind",
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
        for pairRank in pairs {
            if pairRank >= 10 {
                let indices = getCardIndices(hand: hand, rank: pairRank)
                return DealtWinnerResult(
                    isWinner: true,
                    handName: "Tens or Better",
                    winningIndices: indices
                )
            }
        }

        return DealtWinnerResult(isWinner: false, handName: nil, winningIndices: [])
    }

    // MARK: - Deuces Wild Evaluation

    private func evaluateDeucesWild(hand: Hand, rankCounts: [Int: Int], numDeuces: Int) -> DealtWinnerResult {
        // Minimum paying hand is Three of a Kind

        // Natural Royal Flush (no deuces)
        if numDeuces == 0 && isRoyalFlush(hand: hand) {
            return DealtWinnerResult(
                isWinner: true,
                handName: "Natural Royal Flush",
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
                handName: "Wild Royal Flush",
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
        if isStraightFlush(hand: hand) {
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

    private func getCardIndices(hand: Hand, rank: Int) -> [Int] {
        return hand.cards.enumerated().compactMap { index, card in
            card.rank.rawValue == rank ? index : nil
        }
    }

    private func isFlush(hand: Hand) -> Bool {
        let firstSuit = hand.cards[0].suit
        return hand.cards.allSatisfy { $0.suit == firstSuit }
    }

    private func isStraight(hand: Hand) -> Bool {
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

    private func isStraightFlush(hand: Hand) -> Bool {
        return isFlush(hand: hand) && isStraight(hand: hand)
    }

    private func isRoyalFlush(hand: Hand) -> Bool {
        if !isFlush(hand: hand) { return false }
        let ranks = Set(hand.cards.map { $0.rank.rawValue })
        return ranks == Set([10, 11, 12, 13, 14]) // T, J, Q, K, A
    }

    private func isWildRoyalFlush(hand: Hand, numDeuces: Int) -> Bool {
        if numDeuces == 0 { return false }
        if !isFlush(hand: hand) { return false }

        // Check if we can make T-J-Q-K-A with deuces
        let nonDeuceRanks = hand.cards.filter { $0.rank.rawValue != 2 }.map { $0.rank.rawValue }
        let royalRanks: Set<Int> = [10, 11, 12, 13, 14]

        // Check if non-deuce cards are subset of royal ranks
        if !Set(nonDeuceRanks).isSubset(of: royalRanks) { return false }

        // Check if we have enough deuces to complete
        let missing = royalRanks.subtracting(nonDeuceRanks).count
        return missing <= numDeuces
    }

    private func canMakeFullHouse(rankCounts: [Int: Int], numDeuces: Int) -> Bool {
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
