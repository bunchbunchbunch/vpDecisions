import Foundation

struct PayTable: Identifiable, Hashable {
    let id: String
    let name: String

    static let jacksOrBetter = PayTable(id: "jacks-or-better-9-6", name: "Jacks or Better 9/6")
    static let doubleDoubleBonus = PayTable(id: "double-double-bonus-9-6", name: "Double Double Bonus 9/6")
    static let tripleDoubleBonus = PayTable(id: "triple-double-bonus-9-6", name: "Triple Double Bonus 9/6")
    static let deucesWildNSUD = PayTable(id: "deuces-wild-nsud", name: "Deuces Wild NSUD")
    static let bonusPoker85 = PayTable(id: "bonus-poker-8-5", name: "Bonus Poker 8/5")
    static let doubleBonus107 = PayTable(id: "double-bonus-10-7", name: "Double Bonus 10/7")

    // Only include paytables with complete strategy data in Supabase
    static let allPayTables: [PayTable] = [
        .jacksOrBetter,
        .doubleDoubleBonus,
        .tripleDoubleBonus,
        .deucesWildNSUD,
        .bonusPoker85,
        .doubleBonus107
    ]

    static let defaultPayTable = jacksOrBetter
}
