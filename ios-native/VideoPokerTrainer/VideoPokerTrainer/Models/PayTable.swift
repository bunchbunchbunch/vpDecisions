import Foundation

struct PayTable: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    var isBundled: Bool

    /// Standard initializer for defining paytables
    init(id: String, name: String, isBundled: Bool = true) {
        self.id = id
        self.name = name
        self.isBundled = isBundled
    }

    // Computed property to determine game family from ID
    var family: GameFamily {
        // Order matters - check longer prefixes first
        if id.hasPrefix("double-double-bonus") { return .doubleDoubleBonus }
        if id.hasPrefix("triple-double-bonus") { return .tripleDoubleBonus }
        if id.hasPrefix("double-bonus") { return .doubleBonus }
        if id.hasPrefix("bonus-poker") { return .bonusPoker }
        if id.hasPrefix("jacks-or-better") { return .jacksOrBetter }
        if id.hasPrefix("deuces-wild") { return .deucesWild }
        return .jacksOrBetter // fallback
    }

    /// Returns true if this is a Deuces Wild variant (2s are wild)
    var isDeucesWild: Bool {
        family == .deucesWild
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
        case "9-6-940": return "9/6 (94.0%)"
        default:
            // Convert "9-6" to "9/6", "9-6-90" to "9/6/90", etc.
            return suffix.replacingOccurrences(of: "-", with: "/")
                .uppercased()
                .replacingOccurrences(of: "RF", with: " RF")
                .trimmingCharacters(in: CharacterSet.whitespaces)
        }
    }

    // ==========================================================================
    // MARK: - Paytable Definitions (VPS2 only)
    // Only games with VPS2 binary strategy files are included
    // ==========================================================================

    // Jacks or Better variants (6 with VPS2)
    static let jacksOrBetter96 = PayTable(id: "jacks-or-better-9-6", name: "Jacks or Better 9/6")
    static let jacksOrBetter96_940 = PayTable(id: "jacks-or-better-9-6-940", name: "Jacks or Better 9/6 (94.0%)")
    static let jacksOrBetter95 = PayTable(id: "jacks-or-better-9-5", name: "Jacks or Better 9/5")
    static let jacksOrBetter85 = PayTable(id: "jacks-or-better-8-5", name: "Jacks or Better 8/5")
    static let jacksOrBetter75 = PayTable(id: "jacks-or-better-7-5", name: "Jacks or Better 7/5")
    static let jacksOrBetter65 = PayTable(id: "jacks-or-better-6-5", name: "Jacks or Better 6/5")

    // Bonus Poker variants (2 with VPS2)
    static let bonusPoker85 = PayTable(id: "bonus-poker-8-5", name: "Bonus Poker 8/5")
    static let bonusPoker75 = PayTable(id: "bonus-poker-7-5", name: "Bonus Poker 7/5")

    // Double Bonus variants (1 with VPS2)
    static let doubleBonus107 = PayTable(id: "double-bonus-10-7", name: "Double Bonus 10/7")

    // Double Double Bonus variants (2 with VPS2)
    static let doubleDoubleBonus96 = PayTable(id: "double-double-bonus-9-6", name: "Double Double Bonus 9/6")
    static let doubleDoubleBonus85 = PayTable(id: "double-double-bonus-8-5", name: "Double Double Bonus 8/5")

    // Triple Double Bonus variants (1 with VPS2)
    static let tripleDoubleBonus96 = PayTable(id: "triple-double-bonus-9-6", name: "Triple Double Bonus 9/6")

    // Deuces Wild variants (2 with VPS2)
    static let deucesWildFullPay = PayTable(id: "deuces-wild-full-pay", name: "Deuces Wild Full Pay")
    static let deucesWildNSUD = PayTable(id: "deuces-wild-nsud", name: "Deuces Wild NSUD")

    // ==========================================================================
    // MARK: - Paytable Collections
    // ==========================================================================

    // All paytables with VPS2 strategy files
    static let allPayTables: [PayTable] = [
        // Jacks or Better
        .jacksOrBetter96,
        .jacksOrBetter96_940,
        .jacksOrBetter95,
        .jacksOrBetter85,
        .jacksOrBetter75,
        .jacksOrBetter65,
        // Bonus Poker
        .bonusPoker85,
        .bonusPoker75,
        // Double Bonus
        .doubleBonus107,
        // Double Double Bonus
        .doubleDoubleBonus96,
        .doubleDoubleBonus85,
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
