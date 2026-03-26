import Foundation

/// Computes E[K_awarded] — the expected Ultimate X multiplier awarded on the next hand —
/// by enumerating all possible draw outcomes for a given hold bitmask.
///
/// For a hold bitmask, held cards are fixed; the remaining 47 undealt cards form the draw pool.
/// All C(47, drawCount) combinations are evaluated. The average multiplier across all outcomes
/// is E[K_awarded].
///
/// Special case: bitmask == 0 (discard all) returns 1.0 for performance (C(47,5) = 1.5M combos).
actor HoldOutcomeCalculator {

    /// Compute E[K_awarded] for a specific hold bitmask.
    /// Returns 1.0 if bitmask == 0 (discard all — skipped for performance;
    /// the true E[K] is slightly above 1.0 but C(47,5) = 1.5M combos is too slow).
    func computeEK(
        hand: Hand,
        holdBitmask: Int,
        paytableId: String,
        playCount: UltimateXPlayCount
    ) async -> Double {
        // Resolve family once — used for table lookups and inner-loop multiplier calls
        let family = PayTable.allPayTables.first(where: { $0.id == paytableId })?.family ?? .jacksOrBetter

        // Use pre-computed table for draw-all: C(47,5) = 1.53M combos
        guard holdBitmask != 0 else {
            return UltimateXEKTable.eKDrawAll(playCount: playCount, family: family)
        }

        let canonicalIndices = Hand.holdIndicesFromBitmask(holdBitmask)
        let originalIndices = hand.canonicalIndicesToOriginal(canonicalIndices)
        let drawCount = 5 - originalIndices.count

        // Use pre-computed table for single-card holds: C(47,4) = 178K combos
        if originalIndices.count == 1 {
            let heldCard = hand.cards[originalIndices[0]]
            return UltimateXEKTable.eKSingleCard(rank: heldCard.rank, playCount: playCount, family: family)
        }

        // For 2-5 card holds: live computation (fast — max C(47,3) = 16K combos)

        // Build remaining deck: all 52 cards minus the 5 dealt cards
        // Card's Hashable conformance is UUID-based, not rank/suit-based, so we
        // cannot use Set(hand.cards) to deduplicate — use rank+suit string keys instead.
        let dealtKeys = Set(hand.cards.map { "\($0.rank.rawValue)_\($0.suit.rawValue)" })
        let remainingDeck = Card.createDeck().filter { card in
            !dealtKeys.contains("\(card.rank.rawValue)_\(card.suit.rawValue)")
        }

        // drawCount == 0: evaluate the hand as-is (hold all 5)
        if drawCount == 0 {
            let result = HandEvaluator.shared.evaluateDealtHand(
                hand: hand,
                paytableId: paytableId
            )
            let multiplier = UltimateXMultiplierTable.multiplier(
                for: result.handName ?? "",
                playCount: playCount,
                family: family
            )
            return Double(multiplier)
        }

        // Collect all C(47, drawCount) combination index arrays synchronously
        var allCombos: [[Int]] = []
        enumerateCombinationIndices(n: remainingDeck.count, k: drawCount) { indices in
            allCombos.append(indices)
        }

        // Evaluate each combination (async actor calls to HandEvaluator)
        var totalMultiplier: Double = 0

        for indices in allCombos {
            let drawnCards = indices.map { remainingDeck[$0] }

            // Build the 5-card hand preserving original position order
            var finalCards = hand.cards  // start with dealt hand
            var drawIdx = 0
            for pos in 0..<5 {
                if !originalIndices.contains(pos) {
                    finalCards[pos] = drawnCards[drawIdx]
                    drawIdx += 1
                }
            }

            let drawHand = Hand(cards: finalCards)
            let result = HandEvaluator.shared.evaluateDealtHand(
                hand: drawHand,
                paytableId: paytableId
            )
            let multiplier = UltimateXMultiplierTable.multiplier(
                for: result.handName ?? "",
                playCount: playCount,
                family: family
            )
            totalMultiplier += Double(multiplier)
        }

        assert(!allCombos.isEmpty, "enumerateCombinationIndices produced no combinations — deck size < draw count")
        return totalMultiplier / Double(allCombos.count)
    }

    /// Generate all C(n, k) index combinations using an iterative algorithm.
    /// Calls `handler` once per combination with an array of k indices.
    private func enumerateCombinationIndices(n: Int, k: Int, handler: ([Int]) -> Void) {
        guard k > 0, k <= n else {
            if k == 0 { handler([]) }
            return
        }
        var indices = Array(0..<k)
        while true {
            handler(indices)
            // Find rightmost index that can be incremented
            var i = k - 1
            while i >= 0 && indices[i] == n - k + i { i -= 1 }
            if i < 0 { break }
            indices[i] += 1
            for j in (i + 1)..<k { indices[j] = indices[j - 1] + 1 }
        }
    }
}
