#if DEBUG
import Foundation

/// Offline generator for UltimateXEKTable pre-computed values.
///
/// Usage: Settings → Developer → "Generate E[K] Table"
/// Output: Swift code printed to Xcode console. Paste into UltimateXEKTable.swift.
///
/// Runtime: ~5–15 minutes on simulator (58M hand evaluations total).
actor EKTableGenerator {

    static let shared = EKTableGenerator()

    private static let representativePaytableIds = [
        "jacks-or-better-9-6",    // group 0: JacksOrBetter
        "bonus-poker-8-5",         // group 1: BonusPoker
        "double-bonus-10-7",       // group 2: DoubleBonus
        "triple-double-bonus-9-6", // group 3: TripleDoubleBonus
        "deuces-wild-full-pay",    // group 4: DeucesWild
    ]

    private static let groupNames = [
        "JacksOrBetter", "BonusPoker", "DoubleBonus", "TripleDoubleBonus", "DeucesWild"
    ]

    // MARK: - Entry Point

    /// Computes all 210 E[K] values and returns formatted Swift code for UltimateXEKTable.
    func generateAll() async -> String {
        var result: [[[Double]]] = []

        for groupIndex in 0..<5 {
            let paytableId = Self.representativePaytableIds[groupIndex]
            let groupName = Self.groupNames[groupIndex]
            var groupData: [[Double]] = []

            for playCount in UltimateXPlayCount.allCases {
                print("EKTableGenerator: group \(groupIndex + 1)/5 (\(groupName)), \(playCount.displayName)...")
                var scenarios: [Double] = []

                // Scenario 0: draw-all
                scenarios.append(await computeDrawAll(paytableId: paytableId, playCount: playCount))

                // Scenarios 1–13: hold rank two through ace
                for rank in Rank.allCases {
                    scenarios.append(await computeSingleCard(rank: rank, paytableId: paytableId, playCount: playCount))
                }

                groupData.append(scenarios)
            }

            result.append(groupData)
        }

        print("EKTableGenerator: complete.")
        return formatAsSwift(result)
    }

    // MARK: - Draw-All Computation (C(47,5) = 1,533,939 combos)

    private func computeDrawAll(paytableId: String, playCount: UltimateXPlayCount) async -> Double {
        let family = PayTable.allPayTables.first(where: { $0.id == paytableId })?.family ?? .jacksOrBetter

        // Fixed canonical hand: no deuces, no pairs, no flush/straight potential
        let hand = Hand(cards: [
            Card(rank: .three, suit: .spades),
            Card(rank: .six,   suit: .hearts),
            Card(rank: .nine,  suit: .diamonds),
            Card(rank: .queen, suit: .clubs),
            Card(rank: .king,  suit: .spades),
        ])

        let dealtKeys = Set(hand.cards.map { "\($0.rank.rawValue)_\($0.suit.rawValue)" })
        let remainingDeck = Card.createDeck().filter {
            !dealtKeys.contains("\($0.rank.rawValue)_\($0.suit.rawValue)")
        }

        var total: Double = 0
        var count = 0

        enumerateCombinations(n: remainingDeck.count, k: 5) { indices in
            let drawHand = Hand(cards: indices.map { remainingDeck[$0] })
            let result = HandEvaluator.shared.evaluateDealtHand(hand: drawHand, paytableId: paytableId)
            let m = UltimateXMultiplierTable.multiplier(for: result.handName ?? "", playCount: playCount, family: family)
            total += Double(m)
            count += 1
        }

        return total / Double(max(count, 1))
    }

    // MARK: - Single-Card Hold Computation (C(47,4) = 178,365 combos)

    private func computeSingleCard(rank: Rank, paytableId: String, playCount: UltimateXPlayCount) async -> Double {
        let family = PayTable.allPayTables.first(where: { $0.id == paytableId })?.family ?? .jacksOrBetter
        let hand = canonicalHand(for: rank)
        let heldPosition = 0  // held card is always at position 0

        let dealtKeys = Set(hand.cards.map { "\($0.rank.rawValue)_\($0.suit.rawValue)" })
        let remainingDeck = Card.createDeck().filter {
            !dealtKeys.contains("\($0.rank.rawValue)_\($0.suit.rawValue)")
        }

        var total: Double = 0
        var count = 0

        enumerateCombinations(n: remainingDeck.count, k: 4) { indices in
            let drawn = indices.map { remainingDeck[$0] }
            var finalCards = hand.cards
            var drawIdx = 0
            for pos in 0..<5 where pos != heldPosition {
                finalCards[pos] = drawn[drawIdx]
                drawIdx += 1
            }
            let drawHand = Hand(cards: finalCards)
            let result = HandEvaluator.shared.evaluateDealtHand(hand: drawHand, paytableId: paytableId)
            let m = UltimateXMultiplierTable.multiplier(for: result.handName ?? "", playCount: playCount, family: family)
            total += Double(m)
            count += 1
        }

        return total / Double(max(count, 1))
    }

    // MARK: - Canonical Hand Builder

    /// Canonical hand for single-card hold: target rank at position 0, fillers at 1–4.
    /// Fillers (3♥, 6♦, 9♣, Q♥) are bumped by 1 if they equal the target rank.
    private func canonicalHand(for rank: Rank) -> Hand {
        func filler(_ preferred: Rank, _ alternate: Rank) -> Rank {
            rank == preferred ? alternate : preferred
        }
        return Hand(cards: [
            Card(rank: rank,                         suit: .spades),
            Card(rank: filler(.three, .four),        suit: .hearts),
            Card(rank: filler(.six,   .seven),       suit: .diamonds),
            Card(rank: filler(.nine,  .eight),       suit: .clubs),
            Card(rank: filler(.queen, .king),        suit: .hearts),
        ])
    }

    // MARK: - Combination Enumerator

    private func enumerateCombinations(n: Int, k: Int, handler: ([Int]) -> Void) {
        guard k > 0, k <= n else {
            if k == 0 { handler([]) }
            return
        }
        var indices = Array(0..<k)
        while true {
            handler(indices)
            var i = k - 1
            while i >= 0 && indices[i] == n - k + i { i -= 1 }
            if i < 0 { break }
            indices[i] += 1
            for j in (i + 1)..<k { indices[j] = indices[j - 1] + 1 }
        }
    }

    // MARK: - Output Formatter

    private func formatAsSwift(_ data: [[[Double]]]) -> String {
        let date = ISO8601DateFormatter().string(from: Date())
        var lines = [
            "// Generated \(date) by EKTableGenerator",
            "// Representative paytables: JoB=jacks-or-better-9-6, BP=bonus-poker-8-5,",
            "//   DB=double-bonus-10-7, TDB=triple-double-bonus-9-6, DW=deuces-wild-full-pay",
            "// Scenario order: [drawAll, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace]",
            "private static let tableData: [[[Double]]] = [",
        ]

        let playCounts = ["three-play", "five-play", "ten-play"]

        for (gi, group) in data.enumerated() {
            lines.append("    // Group \(gi): \(Self.groupNames[gi])")
            lines.append("    [")
            for (pi, scenarios) in group.enumerated() {
                let vals = scenarios.map { String(format: "%.6f", $0) }.joined(separator: ", ")
                lines.append("        // \(playCounts[pi])")
                lines.append("        [\(vals)],")
            }
            lines.append("    ],")
        }

        lines.append("]")
        return lines.joined(separator: "\n")
    }
}
#endif
