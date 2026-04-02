import Foundation

struct WildWildWildDistribution {
    /// Returns [p(0 wilds), p(1 wild), p(2 wilds), p(3 wilds)]
    static func probabilities(for family: GameFamily) -> [Double] {
        switch family {
        case .jacksOrBetter, .tensOrBetter, .allAmerican:
            return [0.400, 0.190, 0.210, 0.200]
        case .deucesWild, .looseDeuces:
            return [0.400, 0.183, 0.217, 0.200]
        case .bonusPoker, .bonusPokerPlus:
            return [0.356, 0.101, 0.442, 0.101]
        case .doubleDoubleBonus, .ddbAcesFaces, .ddbPlus:
            return [0.490, 0.220, 0.240, 0.050]
        case .doubleBonus:
            return [0.490, 0.150, 0.310, 0.050]
        case .bonusPokerDeluxe:
            return [0.490, 0.208, 0.252, 0.050]
        case .tripleDoubleBonus:
            return [0.490, 0.329, 0.141, 0.040]
        case .tripleTripleBonus:
            return [0.490, 0.338, 0.162, 0.010]
        default:
            return [0.400, 0.190, 0.210, 0.200]
        }
    }

    static func sampleWildCount(for family: GameFamily) -> Int {
        let probs = probabilities(for: family)
        let roll = Double.random(in: 0..<1)
        var cumulative = 0.0
        for (i, p) in probs.enumerated() {
            cumulative += p
            if roll < cumulative { return i }
        }
        return 0
    }

    static func wwwStrategyId(baseId: String, wildCount: Int) -> String {
        // 0 wilds = standard 52-card deck, unreachable WWW hands — use base strategy
        guard wildCount > 0 else { return baseId }
        return "www-\(baseId)-\(wildCount)w"
    }

    /// Pay tables with WWW strategies available in Supabase.
    /// Add new IDs here as strategies are generated and uploaded.
    static let supportedPaytableIds: Set<String> = [
        "jacks-or-better-9-6",
        "bonus-poker-8-5",
        "bonus-poker-deluxe-9-6",
        "double-bonus-9-7-5",
        "double-double-bonus-9-6",
        "triple-double-bonus-9-7",
        "deuces-wild-nsud",
    ]

    static func isSupported(paytableId: String) -> Bool {
        supportedPaytableIds.contains(paytableId)
    }
}
