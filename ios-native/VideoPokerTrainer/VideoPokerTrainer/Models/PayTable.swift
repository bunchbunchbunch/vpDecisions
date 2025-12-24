import Foundation

struct PayTable: Identifiable, Hashable {
    let id: String
    let name: String

    static let jacksOrBetter = PayTable(id: "jacks-or-better-9-6", name: "Jacks or Better 9/6")
    static let doubleDoubleBonus = PayTable(id: "double-double-bonus-9-6", name: "Double Double Bonus 9/6")
    static let deucesWildNSUD = PayTable(id: "deuces-wild-nsud", name: "Deuces Wild NSUD")
    static let deucesWildFullPay = PayTable(id: "deuces-wild-full-pay", name: "Deuces Wild Full Pay")
    static let bonusPoker85 = PayTable(id: "bonus-poker-8-5", name: "Bonus Poker 8/5")
    static let doubleBonus107 = PayTable(id: "double-bonus-10-7", name: "Double Bonus 10/7")
    static let tripleDoubleBonus96 = PayTable(id: "triple-double-bonus-9-6", name: "Triple Double Bonus 9/6")
    static let allAmerican = PayTable(id: "all-american", name: "All American")
    static let bonusPokerDeluxe86 = PayTable(id: "bonus-poker-deluxe-8-6", name: "Bonus Poker Deluxe 8/6")
    static let tensOrBetter65 = PayTable(id: "tens-or-better-6-5", name: "Tens or Better 6/5")

    static let allPayTables: [PayTable] = [
        .jacksOrBetter,
        .doubleDoubleBonus,
        .deucesWildNSUD,
        .deucesWildFullPay,
        .bonusPoker85,
        .doubleBonus107,
        .tripleDoubleBonus96,
        .allAmerican,
        .bonusPokerDeluxe86,
        .tensOrBetter65
    ]

    static let defaultPayTable = jacksOrBetter
}
