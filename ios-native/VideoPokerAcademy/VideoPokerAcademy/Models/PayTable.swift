import Foundation

struct PayTable: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    var isBundled: Bool

    /// Standard initializer for defining paytables
    init(id: String, name: String, isBundled: Bool = false) {
        self.id = id
        self.name = name
        self.isBundled = isBundled
    }

    // MARK: - Last Selected Game Persistence

    static var lastSelectedId: String {
        get {
            let id = UserDefaults.standard.string(forKey: "lastSelectedPaytableId")
            if let id, allPayTables.contains(where: { $0.id == id }) {
                return id
            }
            return PayTable.jacksOrBetter96.id
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "lastSelectedPaytableId")
        }
    }

    // Computed property to determine game family from ID
    var family: GameFamily {
        // Order matters - check longer/more specific prefixes first

        // Triple variants (check before double)
        if id.hasPrefix("triple-triple-bonus") { return .tripleTripleBonus }
        if id.hasPrefix("triple-bonus-plus") { return .tripleBonusPlus }
        if id.hasPrefix("triple-double-bonus") { return .tripleDoubleBonus }
        if id.hasPrefix("triple-bonus") { return .tripleBonus }

        // Double Double variants (check before double)
        if id.hasPrefix("double-double-jackpot") { return .doubleDoubleJackpot }
        if id.hasPrefix("double-double-bonus") { return .doubleDoubleBonus }

        // Double variants
        if id.hasPrefix("double-jackpot") { return .doubleJackpot }
        if id.hasPrefix("double-bonus") { return .doubleBonus }

        // Bonus Poker variants (check longer prefixes first)
        if id.hasPrefix("bonus-poker-deluxe") { return .bonusPokerDeluxe }
        if id.hasPrefix("bonus-poker-plus") { return .bonusPokerPlus }
        if id.hasPrefix("bonus-aces-faces") { return .bonusAcesFaces }
        if id.hasPrefix("bonus-poker") { return .bonusPoker }

        // DDB variants
        if id.hasPrefix("ddb-aces-faces") { return .ddbAcesFaces }
        if id.hasPrefix("ddb-plus") { return .ddbPlus }

        // Aces games
        if id.hasPrefix("aces-and-eights") { return .acesAndEights }
        if id.hasPrefix("aces-and-faces") { return .acesAndFaces }
        if id.hasPrefix("aces-bonus") { return .acesBonus }
        if id.hasPrefix("super-aces") { return .superAces }
        if id.hasPrefix("royal-aces-bonus") { return .royalAcesBonus }
        if id.hasPrefix("white-hot-aces") { return .whiteHotAces }

        // Wild card games
        if id.hasPrefix("loose-deuces") { return .looseDeuces }
        if id.hasPrefix("deuces-wild") { return .deucesWild }

        // Super Double Bonus
        if id.hasPrefix("super-double-bonus") { return .superDoubleBonus }

        // Standard games
        if id.hasPrefix("jacks-or-better") { return .jacksOrBetter }
        if id.hasPrefix("tens-or-better") { return .tensOrBetter }
        if id.hasPrefix("all-american") { return .allAmerican }

        return .jacksOrBetter // fallback
    }

    /// Returns true if this is a Deuces Wild variant (2s are wild)
    var isDeucesWild: Bool {
        family == .deucesWild || family == .looseDeuces
    }

    /// Returns pay table rows adjusted for WWW mode.
    /// For non-wild base games, adds Five of a Kind and Wild Royal rows.
    /// For Deuces Wild (which already has these), returns rows unchanged.
    func wwwRows() -> [PayTableRow] {
        // Deuces Wild already has Wild Royal and Five of a Kind
        if isDeucesWild { return rows }

        // Check if already has these rows
        let existingNames = Set(rows.map { $0.handName })
        if existingNames.contains("Five of a Kind") { return rows }

        // Derive payouts: Wild Royal = Royal Flush payout, Five of a Kind = Four of a Kind payout
        let royalPayout = rows.first { $0.handName == "Royal Flush" }?.payouts ?? [250, 500, 750, 1000, 4000]
        let quadPayout = rows.first { $0.handName == "Four of a Kind" }?.payouts ?? [25, 50, 75, 100, 125]

        var wwwRows = rows
        // Insert after Royal Flush (index 0): Wild Royal, then Five of a Kind
        wwwRows.insert(PayTableRow(handName: "Wild Royal", payouts: royalPayout), at: 1)
        wwwRows.insert(PayTableRow(handName: "Five of a Kind", payouts: quadPayout), at: 2)
        return wwwRows
    }

    /// Returns the top 3 hand names (highest paying) for big win detection
    var topThreeHandNames: [String] {
        Array(rows.prefix(3).map { $0.handName })
    }

    /// Check if a hand name qualifies as a "big win" (top 3 hands)
    func isBigWin(handName: String) -> Bool {
        topThreeHandNames.contains(handName)
    }

    /// Return percentage under optimal play. Values from PayTableData.swift comments and PAYTABLES.md.
    static let returnPercentages: [String: Double] = [
        // Jacks or Better
        "jacks-or-better-9-6": 99.54,
        "jacks-or-better-9-5": 98.45,
        "jacks-or-better-8-6": 98.39,
        "jacks-or-better-8-5": 97.30,
        "jacks-or-better-8-5-35": 99.66,
        "jacks-or-better-7-5": 96.15,
        "jacks-or-better-6-5": 95.00,
        "jacks-or-better-9-6-90": 100.00,
        "jacks-or-better-9-6-940": 99.90,

        // Tens or Better
        "tens-or-better-6-5": 99.14,

        // All American
        "all-american-40-7": 100.72,
        "all-american-35-8": 99.60,
        "all-american-30-8": 98.49,
        "all-american-25-8": 97.37,

        // Bonus Poker
        "bonus-poker-8-5": 99.17,
        "bonus-poker-7-5": 98.01,
        "bonus-poker-7-5-1200": 99.09,
        "bonus-poker-6-5": 96.87,

        // Bonus Poker Deluxe
        "bonus-poker-deluxe-9-6": 99.64,
        "bonus-poker-deluxe-9-5": 98.55,
        "bonus-poker-deluxe-8-6": 98.49,
        "bonus-poker-deluxe-8-5": 97.40,
        "bonus-poker-deluxe-7-5": 96.25,
        "bonus-poker-deluxe-6-5": 95.36,

        // Bonus Poker Plus
        "bonus-poker-plus-10-7": 99.61,
        "bonus-poker-plus-9-6": 98.34,

        // Double Bonus
        "double-bonus-10-7": 100.17,
        "double-bonus-10-7-80": 100.52,
        "double-bonus-10-7-4": 100.77,
        "double-bonus-10-6": 98.88,
        "double-bonus-9-7-5": 99.11,
        "double-bonus-9-6-5": 97.81,
        "double-bonus-9-6-4": 96.38,

        // Double Double Bonus
        "double-double-bonus-10-6": 100.07,
        "double-double-bonus-9-6": 98.98,
        "double-double-bonus-9-5": 97.87,
        "double-double-bonus-8-5": 96.79,
        "double-double-bonus-7-5": 95.71,
        "double-double-bonus-6-5": 94.66,

        // Super Double Bonus
        "super-double-bonus-9-5": 99.69,
        "super-double-bonus-8-5": 98.69,
        "super-double-bonus-7-5": 97.77,
        "super-double-bonus-6-5": 96.87,

        // Triple Double Bonus
        "triple-double-bonus-9-7": 99.58,
        "triple-double-bonus-9-6": 98.15,
        "triple-double-bonus-8-5": 95.97,

        // Triple Bonus
        "triple-bonus-9-5": 99.94,
        "triple-bonus-8-5": 98.52,
        "triple-bonus-7-5": 97.45,

        // Triple Bonus Plus
        "triple-bonus-plus-9-5": 99.80,
        "triple-bonus-plus-8-5": 98.73,
        "triple-bonus-plus-7-5": 97.67,

        // Triple Triple Bonus
        "triple-triple-bonus-9-6": 99.75,
        "triple-triple-bonus-9-5": 98.61,
        "triple-triple-bonus-8-5": 97.61,
        "triple-triple-bonus-7-5": 96.55,

        // Deuces Wild
        "deuces-wild-full-pay": 100.76,
        "deuces-wild-nsud": 99.73,
        "deuces-wild-illinois": 98.91,
        "deuces-wild-colorado": 96.77,
        "deuces-wild-25-15-9": 100.76,
        "deuces-wild-25-12-9": 99.81,
        "deuces-wild-25-15-8": 100.36,
        "deuces-wild-20-15-9": 99.89,
        "deuces-wild-20-12-9": 99.42,
        "deuces-wild-44-nsud": 99.73,
        "deuces-wild-44-illinois": 98.91,
        "deuces-wild-44-apdw": 99.96,

        // Loose Deuces
        "loose-deuces-500-17": 101.60,
        "loose-deuces-500-15": 100.97,
        "loose-deuces-500-12": 100.15,
        "loose-deuces-400-12": 99.20,

        // Double Jackpot
        "double-jackpot-8-5": 99.63,
        "double-jackpot-7-5": 98.49,

        // Double Double Jackpot
        "double-double-jackpot-10-6": 100.35,
        "double-double-jackpot-9-6": 99.27,

        // Aces & Eights
        "aces-and-eights-8-5": 99.78,
        "aces-and-eights-7-5": 98.63,

        // Aces & Faces
        "aces-and-faces-8-5": 99.26,
        "aces-and-faces-7-6": 98.85,
        "aces-and-faces-7-5": 98.12,
        "aces-and-faces-6-5": 96.97,

        // Aces Bonus
        "aces-bonus-8-5": 99.40,
        "aces-bonus-7-5": 98.25,
        "aces-bonus-6-5": 97.11,

        // Bonus Aces & Faces
        "bonus-aces-faces-8-5": 99.26,
        "bonus-aces-faces-7-5": 98.12,
        "bonus-aces-faces-6-5": 96.97,

        // Super Aces
        "super-aces-8-5": 99.94,
        "super-aces-7-5": 98.85,
        "super-aces-6-5": 97.78,

        // Royal Aces Bonus
        "royal-aces-bonus-9-6": 99.58,
        "royal-aces-bonus-10-5": 99.20,
        "royal-aces-bonus-8-6": 98.51,
        "royal-aces-bonus-9-5": 97.55,

        // White Hot Aces
        "white-hot-aces-9-5": 99.80,
        "white-hot-aces-8-5": 98.50,
        "white-hot-aces-7-5": 97.44,
        "white-hot-aces-6-5": 96.39,

        // DDB Aces & Faces
        "ddb-aces-faces-9-6": 99.47,
        "ddb-aces-faces-9-5": 98.37,

        // DDB Plus
        "ddb-plus-9-6": 99.68,
        "ddb-plus-9-5": 98.57,
        "ddb-plus-8-5": 97.49,
    ]

    var returnPercentage: Double? {
        PayTable.returnPercentages[id]
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
        case "colorado": return "Colorado"
        case "illinois": return "Illinois"
        case "44-nsud": return "44 NSUD"
        case "44-illinois": return "44 Illinois"
        case "44-apdw": return "44 APDW"
        case "9-6-940": return "9/6 (94.0%)"
        case "9-6-90": return "9/6 (90%)"
        case "10-7-100": return "10/7 (100%)"
        case "10-6-100": return "10/6 (100%)"
        case "8-6-100": return "8/6 (100%)"
        case "10-7-80": return "10/7 (80 RF)"
        case "10-7-4": return "10/7 (4K)"
        case "9-6-4": return "9/6 (4K)"
        case "9-6-5": return "9/6 (5K)"
        case "9-7-5": return "9/7 (5K)"
        case "7-5-1200": return "7/5 (1200)"
        default:
            // Convert "9-6" to "9/6", "20-12-9" to "20/12/9", etc.
            return suffix.replacingOccurrences(of: "-", with: "/")
                .uppercased()
                .trimmingCharacters(in: CharacterSet.whitespaces)
        }
    }

    /// Variant name with return percentage for display in selectors (e.g., "9/6 99.54%")
    var variantDisplayName: String {
        let base = variantName
        guard let pct = returnPercentage else { return base }
        return String(format: "%@ %.2f%%", base, pct)
    }

    // ==========================================================================
    // MARK: - All Paytable Definitions (106 games from Supabase)
    // ==========================================================================

    static let allPayTables: [PayTable] = [
        // Aces & Eights (2)
        PayTable(id: "aces-and-eights-7-5", name: "Aces & Eights 7/5"),
        PayTable(id: "aces-and-eights-8-5", name: "Aces & Eights 8/5"),

        // Aces & Faces (4)
        PayTable(id: "aces-and-faces-6-5", name: "Aces & Faces 6/5"),
        PayTable(id: "aces-and-faces-7-5", name: "Aces & Faces 7/5"),
        PayTable(id: "aces-and-faces-7-6", name: "Aces & Faces 7/6"),
        PayTable(id: "aces-and-faces-8-5", name: "Aces & Faces 8/5"),

        // Aces Bonus (3)
        PayTable(id: "aces-bonus-6-5", name: "Aces Bonus 6/5"),
        PayTable(id: "aces-bonus-7-5", name: "Aces Bonus 7/5"),
        PayTable(id: "aces-bonus-8-5", name: "Aces Bonus 8/5"),

        // All American (4)
        PayTable(id: "all-american-25-8", name: "All American 25/8"),
        PayTable(id: "all-american-30-8", name: "All American 30/8"),
        PayTable(id: "all-american-35-8", name: "All American 35/8"),
        PayTable(id: "all-american-40-7", name: "All American 40/7"),

        // Bonus Aces & Faces (3)
        PayTable(id: "bonus-aces-faces-6-5", name: "Bonus Aces & Faces 6/5"),
        PayTable(id: "bonus-aces-faces-7-5", name: "Bonus Aces & Faces 7/5"),
        PayTable(id: "bonus-aces-faces-8-5", name: "Bonus Aces & Faces 8/5"),

        // Bonus Poker (4)
        PayTable(id: "bonus-poker-6-5", name: "Bonus Poker 6/5"),
        PayTable(id: "bonus-poker-7-5", name: "Bonus Poker 7/5"),
        PayTable(id: "bonus-poker-7-5-1200", name: "Bonus Poker 7/5 (1200)"),
        PayTable(id: "bonus-poker-8-5", name: "Bonus Poker 8/5"),

        // Bonus Poker Deluxe (7)
        PayTable(id: "bonus-poker-deluxe-6-5", name: "Bonus Poker Deluxe 6/5"),
        PayTable(id: "bonus-poker-deluxe-7-5", name: "Bonus Poker Deluxe 7/5"),
        PayTable(id: "bonus-poker-deluxe-8-5", name: "Bonus Poker Deluxe 8/5"),
        PayTable(id: "bonus-poker-deluxe-8-6", name: "Bonus Poker Deluxe 8/6"),
        PayTable(id: "bonus-poker-deluxe-8-6-100", name: "Bonus Poker Deluxe 8/6 (100%)"),
        PayTable(id: "bonus-poker-deluxe-9-5", name: "Bonus Poker Deluxe 9/5"),
        PayTable(id: "bonus-poker-deluxe-9-6", name: "Bonus Poker Deluxe 9/6"),

        // Bonus Poker Plus (2)
        PayTable(id: "bonus-poker-plus-9-6", name: "Bonus Poker Plus 9/6"),
        PayTable(id: "bonus-poker-plus-10-7", name: "Bonus Poker Plus 10/7"),

        // DDB Aces & Faces (2)
        PayTable(id: "ddb-aces-faces-9-5", name: "DDB Aces & Faces 9/5"),
        PayTable(id: "ddb-aces-faces-9-6", name: "DDB Aces & Faces 9/6"),

        // DDB Plus (3)
        PayTable(id: "ddb-plus-8-5", name: "DDB Plus 8/5"),
        PayTable(id: "ddb-plus-9-5", name: "DDB Plus 9/5"),
        PayTable(id: "ddb-plus-9-6", name: "DDB Plus 9/6"),

        // Deuces Wild (11)
        PayTable(id: "deuces-wild-20-12-9", name: "Deuces Wild 20/12/9"),
        PayTable(id: "deuces-wild-20-15-9", name: "Deuces Wild 20/15/9"),
        PayTable(id: "deuces-wild-25-12-9", name: "Deuces Wild 25/12/9"),
        PayTable(id: "deuces-wild-25-15-8", name: "Deuces Wild 25/15/8"),
        PayTable(id: "deuces-wild-44-apdw", name: "Deuces Wild 44 APDW"),
        PayTable(id: "deuces-wild-44-illinois", name: "Deuces Wild 44 Illinois"),
        PayTable(id: "deuces-wild-44-nsud", name: "Deuces Wild 44 NSUD"),
        PayTable(id: "deuces-wild-colorado", name: "Deuces Wild Colorado"),
        PayTable(id: "deuces-wild-full-pay", name: "Deuces Wild Full Pay"),
        PayTable(id: "deuces-wild-illinois", name: "Deuces Wild Illinois"),
        PayTable(id: "deuces-wild-nsud", name: "Deuces Wild NSUD"),

        // Double Bonus (8)
        PayTable(id: "double-bonus-9-6-4", name: "Double Bonus 9/6 (4K)"),
        PayTable(id: "double-bonus-9-6-5", name: "Double Bonus 9/6 (5K)"),
        PayTable(id: "double-bonus-9-7-5", name: "Double Bonus 9/7 (5K)"),
        PayTable(id: "double-bonus-10-6", name: "Double Bonus 10/6"),
        PayTable(id: "double-bonus-10-7", name: "Double Bonus 10/7"),
        PayTable(id: "double-bonus-10-7-4", name: "Double Bonus 10/7 (4K)"),
        PayTable(id: "double-bonus-10-7-80", name: "Double Bonus 10/7 (80 RF)"),
        PayTable(id: "double-bonus-10-7-100", name: "Double Bonus 10/7 (100%)"),

        // Double Double Bonus (8)
        PayTable(id: "double-double-bonus-6-5", name: "Double Double Bonus 6/5"),
        PayTable(id: "double-double-bonus-7-5", name: "Double Double Bonus 7/5"),
        PayTable(id: "double-double-bonus-8-5", name: "Double Double Bonus 8/5"),
        PayTable(id: "double-double-bonus-9-5", name: "Double Double Bonus 9/5"),
        PayTable(id: "double-double-bonus-9-6", name: "Double Double Bonus 9/6"),
        PayTable(id: "double-double-bonus-10-6", name: "Double Double Bonus 10/6"),
        PayTable(id: "double-double-bonus-10-6-100", name: "Double Double Bonus 10/6 (100%)"),

        // Double Double Jackpot (2)
        PayTable(id: "double-double-jackpot-9-6", name: "Double Double Jackpot 9/6"),
        PayTable(id: "double-double-jackpot-10-6", name: "Double Double Jackpot 10/6"),

        // Double Jackpot (2)
        PayTable(id: "double-jackpot-7-5", name: "Double Jackpot 7/5"),
        PayTable(id: "double-jackpot-8-5", name: "Double Jackpot 8/5"),

        // Jacks or Better (8)
        PayTable(id: "jacks-or-better-6-5", name: "Jacks or Better 6/5"),
        PayTable(id: "jacks-or-better-7-5", name: "Jacks or Better 7/5"),
        PayTable(id: "jacks-or-better-8-5", name: "Jacks or Better 8/5"),
        PayTable(id: "jacks-or-better-8-5-35", name: "Jacks or Better 8/5 (35)"),
        PayTable(id: "jacks-or-better-8-6", name: "Jacks or Better 8/6"),
        PayTable(id: "jacks-or-better-9-5", name: "Jacks or Better 9/5"),
        PayTable(id: "jacks-or-better-9-6", name: "Jacks or Better 9/6"),
        PayTable(id: "jacks-or-better-9-6-90", name: "Jacks or Better 9/6 (90%)"),
        PayTable(id: "jacks-or-better-9-6-940", name: "Jacks or Better 9/6 (94.0%)"),

        // Loose Deuces (4)
        PayTable(id: "loose-deuces-400-12", name: "Loose Deuces 400/12"),
        PayTable(id: "loose-deuces-500-12", name: "Loose Deuces 500/12"),
        PayTable(id: "loose-deuces-500-15", name: "Loose Deuces 500/15"),
        PayTable(id: "loose-deuces-500-17", name: "Loose Deuces 500/17"),

        // Royal Aces Bonus (4)
        PayTable(id: "royal-aces-bonus-8-6", name: "Royal Aces Bonus 8/6"),
        PayTable(id: "royal-aces-bonus-9-5", name: "Royal Aces Bonus 9/5"),
        PayTable(id: "royal-aces-bonus-9-6", name: "Royal Aces Bonus 9/6"),
        PayTable(id: "royal-aces-bonus-10-5", name: "Royal Aces Bonus 10/5"),

        // Super Aces (3)
        PayTable(id: "super-aces-6-5", name: "Super Aces 6/5"),
        PayTable(id: "super-aces-7-5", name: "Super Aces 7/5"),
        PayTable(id: "super-aces-8-5", name: "Super Aces 8/5"),

        // Super Double Bonus (4)
        PayTable(id: "super-double-bonus-6-5", name: "Super Double Bonus 6/5"),
        PayTable(id: "super-double-bonus-7-5", name: "Super Double Bonus 7/5"),
        PayTable(id: "super-double-bonus-8-5", name: "Super Double Bonus 8/5"),
        PayTable(id: "super-double-bonus-9-5", name: "Super Double Bonus 9/5"),

        // Tens or Better (1)
        PayTable(id: "tens-or-better-6-5", name: "Tens or Better 6/5"),

        // Triple Bonus (3)
        PayTable(id: "triple-bonus-7-5", name: "Triple Bonus 7/5"),
        PayTable(id: "triple-bonus-8-5", name: "Triple Bonus 8/5"),
        PayTable(id: "triple-bonus-9-5", name: "Triple Bonus 9/5"),

        // Triple Bonus Plus (3)
        PayTable(id: "triple-bonus-plus-7-5", name: "Triple Bonus Plus 7/5"),
        PayTable(id: "triple-bonus-plus-8-5", name: "Triple Bonus Plus 8/5"),
        PayTable(id: "triple-bonus-plus-9-5", name: "Triple Bonus Plus 9/5"),

        // Triple Double Bonus (3)
        PayTable(id: "triple-double-bonus-8-5", name: "Triple Double Bonus 8/5"),
        PayTable(id: "triple-double-bonus-9-6", name: "Triple Double Bonus 9/6"),
        PayTable(id: "triple-double-bonus-9-7", name: "Triple Double Bonus 9/7"),

        // Triple Triple Bonus (4)
        PayTable(id: "triple-triple-bonus-7-5", name: "Triple Triple Bonus 7/5"),
        PayTable(id: "triple-triple-bonus-8-5", name: "Triple Triple Bonus 8/5"),
        PayTable(id: "triple-triple-bonus-9-5", name: "Triple Triple Bonus 9/5"),
        PayTable(id: "triple-triple-bonus-9-6", name: "Triple Triple Bonus 9/6"),

        // White Hot Aces (4)
        PayTable(id: "white-hot-aces-6-5", name: "White Hot Aces 6/5"),
        PayTable(id: "white-hot-aces-7-5", name: "White Hot Aces 7/5"),
        PayTable(id: "white-hot-aces-8-5", name: "White Hot Aces 8/5"),
        PayTable(id: "white-hot-aces-9-5", name: "White Hot Aces 9/5"),
    ]

    // MARK: - Convenience Accessors (for backward compatibility)

    static let jacksOrBetter96 = allPayTables.first { $0.id == "jacks-or-better-9-6" }!
    static let doubleDoubleBonus96 = allPayTables.first { $0.id == "double-double-bonus-9-6" }!
    static let deucesWildNSUD = allPayTables.first { $0.id == "deuces-wild-nsud" }!
    static let doubleBonus107 = allPayTables.first { $0.id == "double-bonus-10-7" }!

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

    /// Create a PayTable from a DownloadablePaytable
    init(from downloadable: DownloadablePaytable) {
        self.id = downloadable.id
        self.name = downloadable.name
        self.isBundled = false
    }
}

// MARK: - Paytable Registry

/// Actor that manages the dynamic list of available paytables (bundled + downloaded)
@MainActor
@Observable
class PaytableRegistry {
    static let shared = PaytableRegistry()

    private(set) var allPaytables: [PayTable] = PayTable.allPayTables
    private(set) var downloadablePaytables: [DownloadablePaytable] = []
    private(set) var isLoadingManifest = false
    private(set) var manifestError: String?

    // Download status tracking
    private(set) var downloadStatuses: [String: StrategyDownloadStatus] = [:]

    private init() {
        // Initialize with bundled paytables
        refreshAvailablePaytables()
    }

    /// Refresh the list of available paytables from both bundle and cache
    func refreshAvailablePaytables() {
        Task {
            let availableIds = await BinaryStrategyStoreV2.shared.getAvailablePaytables()

            // Start with bundled paytables that are available
            var paytables = PayTable.allPayTables.filter { availableIds.contains($0.id) }

            // Add any downloaded paytables that aren't in the bundled list
            for id in availableIds {
                if !PayTable.allPayTables.contains(where: { $0.id == id }) {
                    // This is a downloaded paytable not in our static list
                    let name = formatPaytableName(from: id)
                    paytables.append(PayTable(id: id, name: name, isBundled: false))
                }
            }

            self.allPaytables = paytables.sorted { $0.name < $1.name }

            // Update download statuses
            for paytable in allPaytables {
                downloadStatuses[paytable.id] = .downloaded
            }
        }
    }

    /// Fetch the manifest of downloadable games from Supabase
    func fetchDownloadableGames() async {
        isLoadingManifest = true
        manifestError = nil

        do {
            let manifest = try await StrategyService.shared.fetchAvailableStrategies()
            downloadablePaytables = manifest

            // Update download statuses for all games
            for game in manifest {
                let status = await StrategyService.shared.getDownloadStatus(paytableId: game.id)
                downloadStatuses[game.id] = status
            }
        } catch {
            manifestError = error.localizedDescription
            NSLog("❌ Failed to fetch manifest: %@", error.localizedDescription)
        }

        isLoadingManifest = false
    }

    /// Download a strategy file
    func downloadStrategy(paytableId: String) async -> Bool {
        downloadStatuses[paytableId] = .downloading(progress: 0)

        do {
            let success = try await StrategyService.shared.downloadStrategy(paytableId: paytableId) { [weak self] progress in
                Task { @MainActor in
                    self?.downloadStatuses[paytableId] = .downloading(progress: progress)
                }
            }

            if success {
                downloadStatuses[paytableId] = .downloaded
                refreshAvailablePaytables()
            }
            return success
        } catch {
            downloadStatuses[paytableId] = .failed(error.localizedDescription)
            return false
        }
    }

    /// Delete a downloaded strategy file
    func deleteStrategy(paytableId: String) async {
        do {
            try await StrategyService.shared.deleteStrategy(paytableId: paytableId)
            downloadStatuses[paytableId] = .notDownloaded
            refreshAvailablePaytables()
        } catch {
            NSLog("❌ Failed to delete strategy: %@", error.localizedDescription)
        }
    }

    /// Get download status for a paytable
    func getDownloadStatus(for paytableId: String) -> StrategyDownloadStatus {
        return downloadStatuses[paytableId] ?? .notDownloaded
    }

    /// Check if a paytable is available (bundled or downloaded)
    func isAvailable(_ paytableId: String) -> Bool {
        return allPaytables.contains { $0.id == paytableId }
    }

    /// Get paytables for a specific game family
    func paytables(for family: GameFamily) -> [PayTable] {
        allPaytables.filter { $0.family == family }
    }

    /// Get all downloadable paytables for a specific game family
    func downloadablePaytables(for family: GameFamily) -> [DownloadablePaytable] {
        downloadablePaytables.filter { game in
            // Check if the family matches directly
            if game.family == family.rawValue {
                return true
            }
            // Also include games where the ID starts with the family prefix
            // This handles cases where manifest family might differ slightly
            if game.id.hasPrefix(family.rawValue) {
                return true
            }
            return false
        }
    }

    /// Format a paytable ID into a readable name
    private func formatPaytableName(from id: String) -> String {
        // Convert "jacks-or-better-9-6" to "Jacks or Better 9/6"
        let parts = id.split(separator: "-")
        var words: [String] = []
        var numbers: [String] = []

        for part in parts {
            if let _ = Int(part) {
                numbers.append(String(part))
            } else {
                words.append(String(part).capitalized)
            }
        }

        let gameName = words.joined(separator: " ")
        let variant = numbers.joined(separator: "/")

        if variant.isEmpty {
            return gameName
        }
        return "\(gameName) \(variant)"
    }
}
