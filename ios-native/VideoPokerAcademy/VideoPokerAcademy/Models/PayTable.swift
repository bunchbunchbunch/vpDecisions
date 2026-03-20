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

    /// Returns the top 3 hand names (highest paying) for big win detection
    var topThreeHandNames: [String] {
        Array(rows.prefix(3).map { $0.handName })
    }

    /// Check if a hand name qualifies as a "big win" (top 3 hands)
    func isBigWin(handName: String) -> Bool {
        topThreeHandNames.contains(handName)
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
