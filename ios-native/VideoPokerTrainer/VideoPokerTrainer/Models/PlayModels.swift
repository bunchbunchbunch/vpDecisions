import Foundation

// MARK: - Bet Denomination

enum BetDenomination: Double, CaseIterable, Codable {
    case quarter = 0.25
    case fifty = 0.50
    case one = 1.00
    case five = 5.00
    case twentyFive = 25.00

    var displayName: String {
        switch self {
        case .quarter: return "$0.25"
        case .fifty: return "$0.50"
        case .one: return "$1"
        case .five: return "$5"
        case .twentyFive: return "$25"
        }
    }
}

// MARK: - Line Count

enum LineCount: Int, CaseIterable, Codable {
    case one = 1
    case five = 5
    case ten = 10
    case oneHundred = 100

    var displayName: String {
        switch self {
        case .one: return "1 Line"
        case .five: return "5 Lines"
        case .ten: return "10 Lines"
        case .oneHundred: return "100 Lines"
        }
    }
}

// MARK: - Hundred Play Tally Result

struct HundredPlayTallyResult: Identifiable {
    let id = UUID()
    let handName: String
    let payPerHand: Int  // Credits per hand at 5 coins
    let count: Int
    let subtotal: Int    // count * payPerHand

    var subtotalDollars: Double {
        Double(subtotal)
    }
}

// MARK: - Play Hand Result

struct PlayHandResult: Identifiable, Codable {
    let id: UUID
    let lineNumber: Int
    let finalHand: [CardData]
    let handName: String?
    let payout: Int  // In credits (multiply by denomination for dollars)
    let winningIndices: [Int]

    init(lineNumber: Int, finalHand: [Card], handName: String?, payout: Int, winningIndices: [Int]) {
        self.id = UUID()
        self.lineNumber = lineNumber
        self.finalHand = finalHand.map { CardData(rank: $0.rank, suit: $0.suit) }
        self.handName = handName
        self.payout = payout
        self.winningIndices = winningIndices
    }
}

// Codable card representation for persistence
struct CardData: Codable, Equatable {
    let rank: Rank
    let suit: Suit

    func toCard() -> Card {
        Card(rank: rank, suit: suit)
    }
}

// MARK: - Play Session Stats

struct PlaySessionStats: Codable {
    var handsPlayed: Int = 0
    var totalBet: Double = 0
    var totalWon: Double = 0
    var biggestWin: Double = 0
    var biggestWinHandName: String? = nil

    // Win counts by hand type
    var winsByHandType: [String: Int] = [:]

    // Mistake tracking
    var mistakesMade: Int = 0
    var totalEvLost: Double = 0
    var mistakeHands: Int = 0  // Hands where a mistake was made

    var netProfit: Double {
        totalWon - totalBet
    }

    var returnPercentage: Double {
        guard totalBet > 0 else { return 0 }
        return (totalWon / totalBet) * 100
    }
}

// MARK: - Play Stats (Persistent, per-variant)

struct PlayStats: Codable {
    var paytableId: String
    var allTime: PlaySessionStats = PlaySessionStats()
    var sessions: [PlaySessionRecord] = []

    init(paytableId: String) {
        self.paytableId = paytableId
    }
}

struct PlaySessionRecord: Codable, Identifiable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let stats: PlaySessionStats

    init(startDate: Date, endDate: Date, stats: PlaySessionStats) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        self.stats = stats
    }
}

// MARK: - Player Balance

struct PlayerBalance: Codable {
    var balance: Double = 1000.0  // Starting balance
    var totalDeposited: Double = 1000.0
    var totalWithdrawn: Double = 0

    mutating func deposit(_ amount: Double) {
        balance += amount
        totalDeposited += amount
    }

    mutating func bet(_ amount: Double) -> Bool {
        guard balance >= amount else { return false }
        balance -= amount
        return true
    }

    mutating func win(_ amount: Double) {
        balance += amount
    }
}

// MARK: - Play Settings

struct PlaySettings: Codable {
    var denomination: BetDenomination = .one
    var lineCount: LineCount = .one
    var showOptimalFeedback: Bool = true
    var selectedPaytableId: String = PayTable.jacksOrBetter96.id

    // Always bet 5 coins per line (max bet)
    var coinsPerLine: Int { 5 }

    var totalBetCredits: Int {
        lineCount.rawValue * coinsPerLine
    }

    var totalBetDollars: Double {
        Double(totalBetCredits) * denomination.rawValue
    }
}

// MARK: - Game Phase

enum PlayPhase: Equatable, Codable {
    case betting
    case dealt
    case drawing
    case result
}

// MARK: - Active Hand State (for background persistence)

/// Stores the state of an active hand so it can be restored if the app goes to background
/// and then returns, or refunded if the app was terminated.
struct ActiveHandState: Codable {
    let dealtCards: [CardData]
    let selectedIndices: [Int]
    let remainingDeck: [CardData]
    let betAmount: Double
    let settings: PlaySettings
    let timestamp: Date

    init(dealtCards: [Card], selectedIndices: Set<Int>, remainingDeck: [Card], betAmount: Double, settings: PlaySettings) {
        self.dealtCards = dealtCards.map { CardData(rank: $0.rank, suit: $0.suit) }
        self.selectedIndices = Array(selectedIndices)
        self.remainingDeck = remainingDeck.map { CardData(rank: $0.rank, suit: $0.suit) }
        self.betAmount = betAmount
        self.settings = settings
        self.timestamp = Date()
    }
}

// MARK: - Persistence Manager

actor PlayPersistence {
    static let shared = PlayPersistence()

    private let balanceKey = "playerBalance"
    private let statsKeyPrefix = "playStats_"
    private let settingsKey = "playSettings"
    private let activeHandKey = "activeHandState"

    private init() {}

    // MARK: - Balance

    func loadBalance() -> PlayerBalance {
        guard let data = UserDefaults.standard.data(forKey: balanceKey),
              let balance = try? JSONDecoder().decode(PlayerBalance.self, from: data) else {
            return PlayerBalance()
        }
        return balance
    }

    func saveBalance(_ balance: PlayerBalance) {
        if let data = try? JSONEncoder().encode(balance) {
            UserDefaults.standard.set(data, forKey: balanceKey)
        }
        Task {
            await UserDataSyncService.shared.markDirty(key: "playerBalance")
        }
    }

    // MARK: - Stats (per paytable)

    func loadStats(for paytableId: String) -> PlayStats {
        let key = statsKeyPrefix + paytableId
        guard let data = UserDefaults.standard.data(forKey: key),
              let stats = try? JSONDecoder().decode(PlayStats.self, from: data) else {
            return PlayStats(paytableId: paytableId)
        }
        return stats
    }

    func saveStats(_ stats: PlayStats) {
        let key = statsKeyPrefix + stats.paytableId
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: key)
        }
        Task {
            await UserDataSyncService.shared.markDirty(key: "playStats_\(stats.paytableId)")
        }
    }

    func loadAllStats() -> [PlayStats] {
        return PayTable.allPayTables.map { loadStats(for: $0.id) }
    }

    // MARK: - Settings

    func loadSettings() -> PlaySettings {
        guard let data = UserDefaults.standard.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(PlaySettings.self, from: data) else {
            return PlaySettings()
        }
        return settings
    }

    func saveSettings(_ settings: PlaySettings) {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
        Task {
            await UserDataSyncService.shared.markDirty(key: "playSettings")
        }
    }

    // MARK: - Active Hand State

    func loadActiveHand() -> ActiveHandState? {
        guard let data = UserDefaults.standard.data(forKey: activeHandKey),
              let state = try? JSONDecoder().decode(ActiveHandState.self, from: data) else {
            return nil
        }
        return state
    }

    func saveActiveHand(_ state: ActiveHandState) {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: activeHandKey)
            // Force immediate write - critical for when app is quickly terminated
            UserDefaults.standard.synchronize()
        }
    }

    func clearActiveHand() {
        UserDefaults.standard.removeObject(forKey: activeHandKey)
    }
}
