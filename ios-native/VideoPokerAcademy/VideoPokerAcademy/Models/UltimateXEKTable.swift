import Foundation

/// Pre-computed E[K_awarded] values for Ultimate X poker.
///
/// E[K] is the expected multiplier awarded on the next hand, averaged over all
/// C(47, drawCount) draw outcomes for a given hold pattern.
///
/// Coverage:
///   - Draw-all (bitmask=0): C(47,5) = 1.53M outcomes per group/playCount
///   - Single-card hold (ranks two–ace): C(47,4) = 178K outcomes each
///
/// Values are identical for all paytables within the same multiplier group.
/// Generated offline using EKTableGenerator (Settings → Developer).
///
/// STUB: All values are 1.0 until EKTableGenerator output is pasted here (Task 5).
struct UltimateXEKTable {

    // MARK: - Public API

    /// E[K] when discarding all 5 cards.
    static func eKDrawAll(playCount: UltimateXPlayCount, family: GameFamily) -> Double {
        tableData[groupIndex(for: family)][playCountIndex(playCount)][0]
    }

    /// E[K] when holding exactly one card of the given rank.
    static func eKSingleCard(rank: Rank, playCount: UltimateXPlayCount, family: GameFamily) -> Double {
        tableData[groupIndex(for: family)][playCountIndex(playCount)][rankScenarioIndex(rank)]
    }

    // MARK: - Index Helpers

    private static func groupIndex(for family: GameFamily) -> Int {
        switch family {
        case .jacksOrBetter, .tensOrBetter, .bonusPokerDeluxe, .allAmerican:
            return 0
        case .bonusPoker, .bonusPokerPlus:
            return 1
        case .doubleBonus, .doubleDoubleBonus, .superDoubleBonus,
             .doubleJackpot, .doubleDoubleJackpot,
             .acesBonus, .acesAndEights, .acesAndFaces, .bonusAcesFaces,
             .superAces, .royalAcesBonus, .whiteHotAces,
             .ddbAcesFaces, .ddbPlus:
            return 2
        case .tripleDoubleBonus, .tripleBonus, .tripleBonusPlus, .tripleTripleBonus:
            return 3
        case .deucesWild, .looseDeuces:
            return 4
        }
    }

    private static func playCountIndex(_ playCount: UltimateXPlayCount) -> Int {
        switch playCount {
        case .three: return 0
        case .five:  return 1
        case .ten:   return 2
        case .oneHundred: return 2
        }
    }

    /// scenarioIndex: 0=drawAll, 1=two, 2=three, ..., 13=ace
    private static func rankScenarioIndex(_ rank: Rank) -> Int {
        rank.rawValue - 1  // two.rawValue=2 → 1, ace.rawValue=14 → 13
    }

    // MARK: - Table Data
    //
    // Layout: tableData[groupIndex][playCountIndex][scenarioIndex]
    // Groups 0–4: JoB, BonusPoker, DoubleBonus, TripleDoubleBonus, DeucesWild
    // Play counts 0–2: three, five, ten
    // Scenarios 0–13: drawAll, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace
    //
    // STUB: Replace with EKTableGenerator output (Settings → Developer → Generate E[K] Table).

    // Generated 2026-03-25T19:29:21Z by EKTableGenerator
    // Representative paytables: JoB=jacks-or-better-9-6, BP=bonus-poker-8-5,
    //   DB=double-bonus-10-7, TDB=triple-double-bonus-9-6, DW=deuces-wild-full-pay
    // Scenario order: [drawAll, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace]
    private static let tableData: [[[Double]]] = [
        // Group 0: JacksOrBetter
        [
            // three-play
            [1.334196, 1.311535, 1.316295, 1.322670, 1.327430, 1.327430, 1.327430, 1.327430, 1.327430, 1.327430, 1.479831, 1.475071, 1.468696, 1.470311],
            // five-play
            [1.334420, 1.311827, 1.316587, 1.322961, 1.327721, 1.327721, 1.327721, 1.327721, 1.327721, 1.327721, 1.480122, 1.475362, 1.468988, 1.470602],
            // ten-play
            [1.334492, 1.311883, 1.316671, 1.323073, 1.327861, 1.327861, 1.327861, 1.327861, 1.327861, 1.327861, 1.480234, 1.475446, 1.469044, 1.470658],
        ],
        // Group 1: BonusPoker
        [
            // three-play
            [1.338218, 1.313408, 1.318970, 1.326415, 1.331977, 1.331977, 1.331977, 1.331977, 1.331977, 1.331977, 1.483576, 1.478014, 1.470569, 1.472453],
            // five-play
            [1.338358, 1.313442, 1.319003, 1.326449, 1.332251, 1.332251, 1.332251, 1.332251, 1.332251, 1.332251, 1.483851, 1.478289, 1.470843, 1.472486],
            // ten-play
            [1.338555, 1.313980, 1.319553, 1.327009, 1.332341, 1.332341, 1.332341, 1.332341, 1.332341, 1.332341, 1.483929, 1.478356, 1.470900, 1.473024],
        ],
        // Group 2: DoubleBonus
        [
            // three-play
            [1.336382, 1.310644, 1.316211, 1.323662, 1.329229, 1.329229, 1.329229, 1.329229, 1.329229, 1.329229, 1.480823, 1.475256, 1.467805, 1.469689],
            // five-play
            [1.336523, 1.310678, 1.316245, 1.323696, 1.329504, 1.329504, 1.329504, 1.329504, 1.329504, 1.329504, 1.481098, 1.475531, 1.468079, 1.469722],
            // ten-play
            [1.336719, 1.311216, 1.316794, 1.324256, 1.329594, 1.329594, 1.329594, 1.329594, 1.329594, 1.329594, 1.481176, 1.475598, 1.468136, 1.470260],
        ],
        // Group 3: TripleDoubleBonus
        [
            // three-play
            [1.336382, 1.310644, 1.316211, 1.323662, 1.329229, 1.329229, 1.329229, 1.329229, 1.329229, 1.329229, 1.480823, 1.475256, 1.467805, 1.469689],
            // five-play
            [1.336382, 1.310644, 1.316211, 1.323662, 1.329229, 1.329229, 1.329229, 1.329229, 1.329229, 1.329229, 1.480823, 1.475256, 1.467805, 1.469689],
            // ten-play
            [1.336382, 1.310644, 1.316211, 1.323662, 1.329229, 1.329229, 1.329229, 1.329229, 1.329229, 1.329229, 1.480823, 1.475256, 1.467805, 1.469689],
        ],
        // Group 4: DeucesWild
        [
            // three-play
            [1.340432, 2.045149, 1.264088, 1.275979, 1.285168, 1.291408, 1.303299, 1.303299, 1.303299, 1.299431, 1.290242, 1.280279, 1.268388, 1.263751],
            // five-play
            [1.340728, 2.046809, 1.264278, 1.276170, 1.285359, 1.291599, 1.303490, 1.303490, 1.303490, 1.299622, 1.290433, 1.280470, 1.268578, 1.263942],
            // ten-play
            [1.341235, 2.049836, 1.264290, 1.276181, 1.285370, 1.291610, 1.303501, 1.303501, 1.303501, 1.300406, 1.291217, 1.281255, 1.269363, 1.264727],
        ],
    ]
}
