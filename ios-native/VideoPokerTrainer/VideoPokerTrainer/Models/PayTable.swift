import Foundation

struct PayTable: Identifiable, Hashable {
    let id: String
    let name: String

    static let jacksOrBetter = PayTable(id: "jacks-or-better-9-6", name: "Jacks or Better 9/6")
    static let doubleDoubleBonus = PayTable(id: "double-double-bonus-9-6", name: "Double Double Bonus 9/6")

    static let allPayTables: [PayTable] = [
        .jacksOrBetter,
        .doubleDoubleBonus
    ]

    static let defaultPayTable = jacksOrBetter
}
