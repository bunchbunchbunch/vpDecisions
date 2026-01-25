import Foundation

enum GameFamily: String, CaseIterable, Identifiable {
    // Standard Games
    case jacksOrBetter = "jacks-or-better"
    case tensOrBetter = "tens-or-better"

    // Bonus Poker Family
    case bonusPoker = "bonus-poker"
    case bonusPokerDeluxe = "bonus-poker-deluxe"
    case bonusPokerPlus = "bonus-poker-plus"

    // Double Bonus Family
    case doubleBonus = "double-bonus"
    case doubleDoubleBonus = "double-double-bonus"
    case superDoubleBonus = "super-double-bonus"

    // Triple Bonus Family
    case tripleBonus = "triple-bonus"
    case tripleBonusPlus = "triple-bonus-plus"
    case tripleDoubleBonus = "triple-double-bonus"
    case tripleTripleBonus = "triple-triple-bonus"

    // Jackpot Games
    case doubleJackpot = "double-jackpot"
    case doubleDoubleJackpot = "double-double-jackpot"

    // Aces Games
    case acesBonus = "aces-bonus"
    case acesAndEights = "aces-and-eights"
    case acesAndFaces = "aces-and-faces"
    case bonusAcesFaces = "bonus-aces-faces"
    case superAces = "super-aces"
    case royalAcesBonus = "royal-aces-bonus"
    case whiteHotAces = "white-hot-aces"

    // DDB Variants
    case ddbAcesFaces = "ddb-aces-faces"
    case ddbPlus = "ddb-plus"

    // Wild Card Games
    case deucesWild = "deuces-wild"
    case looseDeuces = "loose-deuces"

    // Other
    case allAmerican = "all-american"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        // Standard Games
        case .jacksOrBetter: return "Jacks or Better"
        case .tensOrBetter: return "Tens or Better"

        // Bonus Poker Family
        case .bonusPoker: return "Bonus Poker"
        case .bonusPokerDeluxe: return "Bonus Poker Deluxe"
        case .bonusPokerPlus: return "Bonus Poker Plus"

        // Double Bonus Family
        case .doubleBonus: return "Double Bonus"
        case .doubleDoubleBonus: return "Double Double Bonus"
        case .superDoubleBonus: return "Super Double Bonus"

        // Triple Bonus Family
        case .tripleBonus: return "Triple Bonus"
        case .tripleBonusPlus: return "Triple Bonus Plus"
        case .tripleDoubleBonus: return "Triple Double Bonus"
        case .tripleTripleBonus: return "Triple Triple Bonus"

        // Jackpot Games
        case .doubleJackpot: return "Double Jackpot"
        case .doubleDoubleJackpot: return "Double Double Jackpot"

        // Aces Games
        case .acesBonus: return "Aces Bonus"
        case .acesAndEights: return "Aces & Eights"
        case .acesAndFaces: return "Aces & Faces"
        case .bonusAcesFaces: return "Bonus Aces & Faces"
        case .superAces: return "Super Aces"
        case .royalAcesBonus: return "Royal Aces Bonus"
        case .whiteHotAces: return "White Hot Aces"

        // DDB Variants
        case .ddbAcesFaces: return "DDB Aces & Faces"
        case .ddbPlus: return "DDB Plus"

        // Wild Card Games
        case .deucesWild: return "Deuces Wild"
        case .looseDeuces: return "Loose Deuces"

        // Other
        case .allAmerican: return "All American"
        }
    }

    var shortName: String {
        switch self {
        // Standard Games
        case .jacksOrBetter: return "JoB"
        case .tensOrBetter: return "ToB"

        // Bonus Poker Family
        case .bonusPoker: return "BP"
        case .bonusPokerDeluxe: return "BPD"
        case .bonusPokerPlus: return "BP+"

        // Double Bonus Family
        case .doubleBonus: return "DB"
        case .doubleDoubleBonus: return "DDB"
        case .superDoubleBonus: return "SDB"

        // Triple Bonus Family
        case .tripleBonus: return "TB"
        case .tripleBonusPlus: return "TB+"
        case .tripleDoubleBonus: return "TDB"
        case .tripleTripleBonus: return "TTB"

        // Jackpot Games
        case .doubleJackpot: return "DJ"
        case .doubleDoubleJackpot: return "DDJ"

        // Aces Games
        case .acesBonus: return "AB"
        case .acesAndEights: return "A&8"
        case .acesAndFaces: return "A&F"
        case .bonusAcesFaces: return "BAF"
        case .superAces: return "SA"
        case .royalAcesBonus: return "RAB"
        case .whiteHotAces: return "WHA"

        // DDB Variants
        case .ddbAcesFaces: return "DDBAF"
        case .ddbPlus: return "DDB+"

        // Wild Card Games
        case .deucesWild: return "DW"
        case .looseDeuces: return "LD"

        // Other
        case .allAmerican: return "AA"
        }
    }

    /// Returns true if this is a wild card game (deuces are wild)
    var isWildGame: Bool {
        switch self {
        case .deucesWild, .looseDeuces:
            return true
        default:
            return false
        }
    }
}
