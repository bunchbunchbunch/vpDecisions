import Foundation

struct PayTable: Identifiable, Hashable {
    let id: String
    let name: String

    // Computed property to determine game family from ID
    var family: GameFamily {
        // Order matters - check longer prefixes first
        if id.hasPrefix("double-double-bonus") { return .doubleDoubleBonus }
        if id.hasPrefix("triple-double-bonus") { return .tripleDoubleBonus }
        if id.hasPrefix("double-bonus") { return .doubleBonus }
        if id.hasPrefix("bonus-poker-deluxe") { return .bonusPokerDeluxe }
        if id.hasPrefix("bonus-poker") { return .bonusPoker }
        if id.hasPrefix("tens-or-better") { return .tensOrBetter }
        if id.hasPrefix("jacks-or-better") { return .jacksOrBetter }
        if id.hasPrefix("deuces-wild") { return .deucesWild }
        return .jacksOrBetter // fallback
    }

    /// Returns true if this is a Deuces Wild variant (2s are wild)
    var isDeucesWild: Bool {
        family == .deucesWild
    }

    // Short variant name for display (e.g., "9/6", "NSUD", "Full Pay")
    var variantName: String {
        // Strip the family prefix and format nicely
        let prefix = family.rawValue + "-"
        guard id.hasPrefix(prefix) else { return name }

        let suffix = String(id.dropFirst(prefix.count))

        // Handle special cases
        switch suffix {
        case "full-pay": return "Full Pay"
        case "nsud": return "NSUD"
        default:
            // Convert "9-6" to "9/6", "9-6-90" to "9/6/90", etc.
            return suffix.replacingOccurrences(of: "-", with: "/")
                .uppercased()
                .replacingOccurrences(of: "RF", with: " RF")
                .trimmingCharacters(in: CharacterSet.whitespaces)
        }
    }

    // Jacks or Better variants
    static let jacksOrBetter96 = PayTable(id: "jacks-or-better-9-6", name: "Jacks or Better 9/6")
    static let jacksOrBetter95 = PayTable(id: "jacks-or-better-9-5", name: "Jacks or Better 9/5")
    static let jacksOrBetter86 = PayTable(id: "jacks-or-better-8-6", name: "Jacks or Better 8/6")
    static let jacksOrBetter85 = PayTable(id: "jacks-or-better-8-5", name: "Jacks or Better 8/5")
    static let jacksOrBetter8535 = PayTable(id: "jacks-or-better-8-5-35", name: "Jacks or Better 8/5/35")
    static let jacksOrBetter75 = PayTable(id: "jacks-or-better-7-5", name: "Jacks or Better 7/5")
    static let jacksOrBetter65 = PayTable(id: "jacks-or-better-6-5", name: "Jacks or Better 6/5")
    static let jacksOrBetter9690 = PayTable(id: "jacks-or-better-9-6-90", name: "Jacks or Better 9/6/90 (100%)")
    static let jacksOrBetter96940 = PayTable(id: "jacks-or-better-9-6-940", name: "Jacks or Better 9/6 RF940")

    // Tens or Better variants
    static let tensOrBetter65 = PayTable(id: "tens-or-better-6-5", name: "Tens or Better 6/5")

    // Bonus Poker variants
    static let bonusPoker85 = PayTable(id: "bonus-poker-8-5", name: "Bonus Poker 8/5")
    static let bonusPoker75 = PayTable(id: "bonus-poker-7-5", name: "Bonus Poker 7/5")
    static let bonusPoker65 = PayTable(id: "bonus-poker-6-5", name: "Bonus Poker 6/5")
    static let bonusPoker751200 = PayTable(id: "bonus-poker-7-5-1200", name: "Bonus Poker 7/5 RF1200")

    // Bonus Poker Deluxe variants
    static let bonusPokerDeluxe96 = PayTable(id: "bonus-poker-deluxe-9-6", name: "Bonus Poker Deluxe 9/6")

    // Double Bonus variants
    static let doubleBonus107 = PayTable(id: "double-bonus-10-7", name: "Double Bonus 10/7")

    // Double Double Bonus variants
    static let doubleDoubleBonus96 = PayTable(id: "double-double-bonus-9-6", name: "Double Double Bonus 9/6")

    // Triple Double Bonus variants
    static let tripleDoubleBonus96 = PayTable(id: "triple-double-bonus-9-6", name: "Triple Double Bonus 9/6")

    // Deuces Wild variants
    static let deucesWildFullPay = PayTable(id: "deuces-wild-full-pay", name: "Deuces Wild Full Pay")
    static let deucesWildNSUD = PayTable(id: "deuces-wild-nsud", name: "Deuces Wild NSUD")

    // All paytables with complete strategy data in Supabase
    static let allPayTables: [PayTable] = [
        // Jacks or Better
        .jacksOrBetter96,
        .jacksOrBetter95,
        .jacksOrBetter86,
        .jacksOrBetter85,
        .jacksOrBetter8535,
        .jacksOrBetter75,
        .jacksOrBetter65,
        .jacksOrBetter9690,
        .jacksOrBetter96940,
        // Tens or Better
        .tensOrBetter65,
        // Bonus Poker
        .bonusPoker85,
        .bonusPoker75,
        .bonusPoker65,
        .bonusPoker751200,
        // Bonus Poker Deluxe
        .bonusPokerDeluxe96,
        // Double Bonus
        .doubleBonus107,
        // Double Double Bonus
        .doubleDoubleBonus96,
        // Triple Double Bonus
        .tripleDoubleBonus96,
        // Deuces Wild
        .deucesWildFullPay,
        .deucesWildNSUD,
    ]

    static let defaultPayTable = jacksOrBetter96

    // Popular paytables for quick access
    static let popularPaytableIds: [String] = [
        "jacks-or-better-9-6",
        "double-double-bonus-9-6",
        "deuces-wild-nsud",
        "double-bonus-10-7"
    ]

    static var popularPaytables: [PayTable] {
        popularPaytableIds.compactMap { id in
            allPayTables.first { $0.id == id }
        }
    }

    static func paytables(for family: GameFamily) -> [PayTable] {
        allPayTables.filter { $0.family == family }
    }
}
