import Foundation

struct PayTable: Identifiable, Hashable {
    let id: String
    let name: String

    // Jacks or Better variants
    static let jacksOrBetter96 = PayTable(id: "jacks-or-better-9-6", name: "Jacks or Better 9/6")
    static let jacksOrBetter95 = PayTable(id: "jacks-or-better-9-5", name: "Jacks or Better 9/5")
    static let jacksOrBetter86 = PayTable(id: "jacks-or-better-8-6", name: "Jacks or Better 8/6")
    static let jacksOrBetter85 = PayTable(id: "jacks-or-better-8-5", name: "Jacks or Better 8/5")
    static let jacksOrBetter75 = PayTable(id: "jacks-or-better-7-5", name: "Jacks or Better 7/5")
    static let jacksOrBetter65 = PayTable(id: "jacks-or-better-6-5", name: "Jacks or Better 6/5")
    static let jacksOrBetter9690 = PayTable(id: "jacks-or-better-9-6-90", name: "Jacks or Better 9/6/90 (100%)")
    static let jacksOrBetter96940 = PayTable(id: "jacks-or-better-9-6-940", name: "Jacks or Better 9/6 RF940")

    // Bonus Poker variants
    static let bonusPoker85 = PayTable(id: "bonus-poker-8-5", name: "Bonus Poker 8/5")

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
        .jacksOrBetter75,
        .jacksOrBetter65,
        .jacksOrBetter9690,
        .jacksOrBetter96940,
        // Bonus Poker
        .bonusPoker85,
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
}
