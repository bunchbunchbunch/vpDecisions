import Foundation

// MARK: - Play Variant

enum PlayVariant: String, Codable, Equatable, Hashable {
    case standard
    case ultimateX
    case wildWildWild

    var isUltimateX: Bool { self == .ultimateX }
    var isWildWildWild: Bool { self == .wildWildWild }

    var coinsPerLine: Int {
        switch self {
        case .standard: return 5
        case .ultimateX, .wildWildWild: return 10
        }
    }

    var displayName: String {
        switch self {
        case .standard:      return "Standard"
        case .ultimateX:     return "Ult X"
        case .wildWildWild:  return "Wild³"
        }
    }
}

// MARK: - Ultimate X Hold Option

struct UltimateXHoldOption: Identifiable {
    let id: Int           // bitmask
    let holdIndices: [Int]
    let baseEV: Double
    let eKAwarded: Double
    let adjustedEV: Double  // avgMultiplier × 2 × baseEV + eKAwarded - 1
}

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
    case three = 3
    case five = 5
    case ten = 10
    case oneHundred = 100

    var displayName: String {
        switch self {
        case .one: return "1 Line"
        case .three: return "3 Lines"
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
    let payPerHand: Int  // Credits per hand at 5 coins (base, before multiplier)
    let count: Int
    let subtotal: Int    // Actual total payout (multiplied for UX)
    var avgAppliedMultiplier: Double = 1.0  // Average multiplier applied (UX only, 1.0 otherwise)

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
    let appliedMultiplier: Int  // Multiplier applied to THIS hand's payout (1 if none)
    let earnedMultiplier: Int   // Multiplier this hand earns for NEXT hand (1 if no qualifying win)

    init(
        lineNumber: Int,
        finalHand: [Card],
        handName: String?,
        payout: Int,
        winningIndices: [Int],
        appliedMultiplier: Int = 1,
        earnedMultiplier: Int = 1
    ) {
        self.id = UUID()
        self.lineNumber = lineNumber
        self.finalHand = finalHand.map { CardData(rank: $0.rank, suit: $0.suit) }
        self.handName = handName
        self.payout = payout
        self.winningIndices = winningIndices
        self.appliedMultiplier = appliedMultiplier
        self.earnedMultiplier = earnedMultiplier
    }

    enum CodingKeys: String, CodingKey {
        case id, lineNumber, finalHand, handName, payout, winningIndices
        case appliedMultiplier, earnedMultiplier
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        lineNumber = try c.decode(Int.self, forKey: .lineNumber)
        finalHand = try c.decode([CardData].self, forKey: .finalHand)
        handName = try c.decodeIfPresent(String.self, forKey: .handName)
        payout = try c.decode(Int.self, forKey: .payout)
        winningIndices = try c.decode([Int].self, forKey: .winningIndices)
        appliedMultiplier = try c.decodeIfPresent(Int.self, forKey: .appliedMultiplier) ?? 1
        earnedMultiplier = try c.decodeIfPresent(Int.self, forKey: .earnedMultiplier) ?? 1
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
    var selectedPaytableId: String = PayTable.lastSelectedId
    var variant: PlayVariant = .standard

    // Coins per line depends on variant (UX = 10, standard = 5)
    var coinsPerLine: Int { variant.coinsPerLine }

    var effectiveLineCount: Int { lineCount.rawValue }

    /// Derives UltimateXPlayCount from lineCount for multiplier table lookups.
    /// Only meaningful when variant == .ultimateX.
    /// Note: 1-line UX uses the same multiplier table as 3-play (smallest available table).
    var effectiveUXPlayCount: UltimateXPlayCount {
        switch lineCount {
        case .one, .three:      return .three   // 1-line uses 3-play table (smallest available)
        case .five:             return .five
        case .ten, .oneHundred: return .ten
        }
    }

    var totalBetCredits: Int {
        effectiveLineCount * coinsPerLine
    }

    var totalBetDollars: Double {
        Double(totalBetCredits) * denomination.rawValue
    }

    /// The dollar amount that strategy EVs should be scaled by.
    /// Strategy file EVs are per-coin based on the 5-coin pay table column,
    /// so this always uses 5 coins per line regardless of variant (WWW/UX bet 10 coins
    /// but payouts still come from the 5-coin column).
    var evScaleDollars: Double {
        Double(effectiveLineCount * 5) * denomination.rawValue
    }

    /// Paytable key for stats storage, incorporating the variant suffix.
    var statsPaytableKey: String {
        switch variant {
        case .standard:      return selectedPaytableId
        case .ultimateX:     return selectedPaytableId + "-ux-\(effectiveUXPlayCount.rawValue)play"
        case .wildWildWild:  return selectedPaytableId + "-www"
        }
    }

    // MARK: - Codable (backward-compatible)

    enum CodingKeys: String, CodingKey {
        case denomination
        case lineCount
        case showOptimalFeedback
        case selectedPaytableId
        case variant
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        denomination = try container.decodeIfPresent(BetDenomination.self, forKey: .denomination) ?? .one
        lineCount = try container.decodeIfPresent(LineCount.self, forKey: .lineCount) ?? .one
        showOptimalFeedback = try container.decodeIfPresent(Bool.self, forKey: .showOptimalFeedback) ?? true
        selectedPaytableId = try container.decodeIfPresent(String.self, forKey: .selectedPaytableId) ?? PayTable.lastSelectedId
        variant = try container.decodeIfPresent(PlayVariant.self, forKey: .variant) ?? .standard
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(denomination, forKey: .denomination)
        try container.encode(lineCount, forKey: .lineCount)
        try container.encode(showOptimalFeedback, forKey: .showOptimalFeedback)
        try container.encode(selectedPaytableId, forKey: .selectedPaytableId)
        try container.encode(variant, forKey: .variant)
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
    let wwwWildCount: Int  // Total wilds added to deck (0 if not WWW)

    init(dealtCards: [Card], selectedIndices: Set<Int>, remainingDeck: [Card],
         betAmount: Double, settings: PlaySettings, wwwWildCount: Int = 0) {
        self.dealtCards = dealtCards.map { CardData(rank: $0.rank, suit: $0.suit) }
        self.selectedIndices = Array(selectedIndices)
        self.remainingDeck = remainingDeck.map { CardData(rank: $0.rank, suit: $0.suit) }
        self.betAmount = betAmount
        self.settings = settings
        self.timestamp = Date()
        self.wwwWildCount = wwwWildCount
    }

    enum CodingKeys: String, CodingKey {
        case dealtCards, selectedIndices, remainingDeck, betAmount, settings, timestamp
        case wwwWildCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        dealtCards = try c.decode([CardData].self, forKey: .dealtCards)
        selectedIndices = try c.decode([Int].self, forKey: .selectedIndices)
        remainingDeck = try c.decode([CardData].self, forKey: .remainingDeck)
        betAmount = try c.decode(Double.self, forKey: .betAmount)
        settings = try c.decode(PlaySettings.self, forKey: .settings)
        timestamp = try c.decode(Date.self, forKey: .timestamp)
        wwwWildCount = try c.decodeIfPresent(Int.self, forKey: .wwwWildCount) ?? 0
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
