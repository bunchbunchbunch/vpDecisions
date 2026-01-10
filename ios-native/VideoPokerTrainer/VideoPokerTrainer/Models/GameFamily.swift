import Foundation

enum GameFamily: String, CaseIterable, Identifiable {
    case jacksOrBetter = "jacks-or-better"
    case tensOrBetter = "tens-or-better"
    case bonusPoker = "bonus-poker"
    case bonusPokerDeluxe = "bonus-poker-deluxe"
    case doubleBonus = "double-bonus"
    case doubleDoubleBonus = "double-double-bonus"
    case tripleDoubleBonus = "triple-double-bonus"
    case deucesWild = "deuces-wild"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .jacksOrBetter: return "Jacks or Better"
        case .tensOrBetter: return "Tens or Better"
        case .bonusPoker: return "Bonus Poker"
        case .bonusPokerDeluxe: return "Bonus Poker Deluxe"
        case .doubleBonus: return "Double Bonus"
        case .doubleDoubleBonus: return "Double Double Bonus"
        case .tripleDoubleBonus: return "Triple Double Bonus"
        case .deucesWild: return "Deuces Wild"
        }
    }

    var shortName: String {
        switch self {
        case .jacksOrBetter: return "JoB"
        case .tensOrBetter: return "ToB"
        case .bonusPoker: return "BP"
        case .bonusPokerDeluxe: return "BPD"
        case .doubleBonus: return "DB"
        case .doubleDoubleBonus: return "DDB"
        case .tripleDoubleBonus: return "TDB"
        case .deucesWild: return "DW"
        }
    }
}
