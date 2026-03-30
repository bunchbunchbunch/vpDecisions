import Foundation
import SwiftUI

@MainActor
class PlayViewModel: ObservableObject {
    // MARK: - Published State

    @Published var phase: PlayPhase = .betting
    @Published var settings: PlaySettings
    @Published var balance: PlayerBalance
    @Published var currentStats: PlaySessionStats = PlaySessionStats()

    // Loading state for paytable preparation
    @Published var isPreparingPaytable = false
    @Published var preparationMessage = "Loading strategy data..."
    @Published var preparationFailed = false

    // Current hand state
    @Published var dealtCards: [Card] = []
    @Published var selectedIndices: Set<Int> = []
    @Published var remainingDeck: [Card] = []

    // Multi-line results
    @Published var lineResults: [PlayHandResult] = []
    @Published var hundredPlayTally: [HundredPlayTallyResult] = []
    @Published var isAnimating = false

    // Optimal play feedback
    @Published var optimalHoldIndices: [Int] = []
    @Published var userEvLost: Double = 0
    @Published var showMistakeFeedback = false
    @Published var strategyResult: StrategyResult? = nil

    // Swipe tip
    @Published var showSwipeTip = true

    // Dealt winner celebration
    @Published var showDealtWinner = false
    @Published var dealtWinnerName: String? = nil

    // Wild Wild Wild state
    @Published var wwwWildCount: Int = 0  // Total wilds added to deck (0–3)

    // Ultimate X state
    @Published var ultimateXMultipliers: [Int] = []  // per-line, 1–12; empty when standard
    @Published var ultimateXTopHolds: [UltimateXHoldOption] = []
    @Published var isComputingUXStrategy = false
    @Published var ultimateXUserHold: UltimateXHoldOption? = nil
    @Published var isComputingUXUserHold = false
    @Published var uxAvgMultiplierUsed: Double = 1.0

    // Session tracking
    private var sessionStartDate: Date?
    private var allTimeStats: PlayStats

    // Services
    private let audioService = AudioService.shared
    private let hapticService = HapticService.shared

    // MARK: - Computed Properties

    var currentPaytable: PayTable? {
        PayTable.allPayTables.first { $0.id == settings.selectedPaytableId }
    }

    var canDeal: Bool {
        (phase == .betting || phase == .result) && balance.balance >= settings.totalBetDollars
    }

    var totalPayout: Int {
        if settings.lineCount == .oneHundred {
            return hundredPlayTally.reduce(0) { $0 + $1.subtotal }
        }
        return lineResults.reduce(0) { $0 + $1.payout }
    }

    var totalPayoutDollars: Double {
        Double(totalPayout) * settings.denomination.rawValue
    }

    var isWinner: Bool {
        totalPayout > 0
    }

    var averageNextHandMultiplier: Double {
        guard !ultimateXMultipliers.isEmpty else { return 1.0 }
        return Double(ultimateXMultipliers.reduce(0, +)) / Double(ultimateXMultipliers.count)
    }

    // MARK: - Initialization

    init() {
        let initialSettings = PlaySettings()
        self.settings = initialSettings
        self.balance = PlayerBalance()
        self.allTimeStats = PlayStats(paytableId: initialSettings.selectedPaytableId)

        Task {
            await loadPersistedData()
        }
    }

    private func loadPersistedData() async {
        self.settings = await PlayPersistence.shared.loadSettings()
        self.balance = await PlayPersistence.shared.loadBalance()
        self.allTimeStats = await PlayPersistence.shared.loadStats(for: settings.statsPaytableKey)

        // Check for orphaned hand (app was terminated with active hand)
        await checkForOrphanedHand()

        // Prepare the paytable if needed
        await prepareCurrentPaytable()

        // Initialize UX multipliers if the loaded variant is UX
        if settings.variant.isUltimateX {
            initializeUXMultipliers()
        }
    }

    /// Checks if there's a saved hand state from a previous session that was terminated.
    /// If found, refunds the bet and clears the state.
    private func checkForOrphanedHand() async {
        guard let savedHand = await PlayPersistence.shared.loadActiveHand() else { return }

        // Refund the bet
        balance.win(savedHand.betAmount)
        await PlayPersistence.shared.saveBalance(balance)

        // Clear the orphaned hand state
        await PlayPersistence.shared.clearActiveHand()

        debugNSLog("🎰 Orphaned hand detected - bet refunded: $%.2f", savedHand.betAmount)
    }

    /// Prepares the current paytable for use - auto-downloads if needed
    func prepareCurrentPaytable() async {
        let paytableId = settings.selectedPaytableId

        // Reset state
        preparationFailed = false
        isPreparingPaytable = true
        preparationMessage = "Checking strategy data..."

        // Use callback-based preparePaytable that auto-downloads if needed
        let success = await StrategyService.shared.preparePaytable(paytableId: paytableId) { [weak self] status in
            guard let self = self else { return }

            self.preparationMessage = status.message

            switch status {
            case .checking, .downloading:
                self.isPreparingPaytable = true
                self.preparationFailed = false
            case .ready:
                self.isPreparingPaytable = false
                self.preparationFailed = false
            case .failed:
                self.isPreparingPaytable = true
                self.preparationFailed = true
            }
        }

        // Ensure final state is correct
        if success {
            isPreparingPaytable = false
            preparationFailed = false
        } else {
            preparationFailed = true
        }

        // For WWW: prepare the 3 wild-count strategy files (1w, 2w, 3w)
        // 0w uses the base strategy file (already prepared above)
        if settings.variant.isWildWildWild {
            isPreparingPaytable = true
            for n in 1...3 {
                let wwwId = WildWildWildDistribution.wwwStrategyId(baseId: paytableId, wildCount: n)
                let ok = await StrategyService.shared.preparePaytable(paytableId: wwwId) { [weak self] status in
                    guard let self else { return }
                    switch status {
                    case .downloading(let progress):
                        preparationMessage = "Downloading Wild Wild Wild strategies... \(Int(progress * 100))%"
                    case .ready, .checking:
                        break
                    case .failed(let msg):
                        debugNSLog("⚠️ WWW strategy download failed for %@: %@", wwwId, msg)
                    }
                }
                if !ok {
                    debugNSLog("⚠️ WWW strategy unavailable for %@", wwwId)
                }
            }
            isPreparingPaytable = false
            preparationFailed = false
            preparationMessage = "Ready"
        }
    }

    // MARK: - Game Actions

    func deal() async {
        guard canDeal else { return }

        // Deduct bet
        let betAmount = settings.totalBetDollars
        guard balance.bet(betAmount) else { return }
        await PlayPersistence.shared.saveBalance(balance)

        // Update stats
        currentStats.handsPlayed += 1
        currentStats.totalBet += betAmount

        // Start session if needed
        if sessionStartDate == nil {
            sessionStartDate = Date()
        }

        // Create deck — augmented for WWW, standard otherwise
        let wwwCount: Int
        if settings.variant.isWildWildWild {
            let family = currentPaytable?.family ?? .jacksOrBetter
            wwwCount = WildWildWildDistribution.sampleWildCount(for: family)
        } else {
            wwwCount = 0
        }
        wwwWildCount = wwwCount

        let deck = Card.shuffledDeck(jokerCount: wwwCount)
        dealtCards = Array(deck.prefix(5))
        remainingDeck = Array(deck.dropFirst(5))
        selectedIndices = []
        lineResults = []
        hundredPlayTally = []
        optimalHoldIndices = []
        userEvLost = 0
        showMistakeFeedback = false
        strategyResult = nil
        showDealtWinner = false
        dealtWinnerName = nil

        phase = .dealt

        audioService.play(.cardFlip)

        // Check if dealt hand is already a winner
        evaluateDealtHandForBanner()

        // Lookup optimal strategy
        await lookupOptimalStrategy()

        // For UX mode: fire-and-forget top-5 strategy computation
        if settings.variant.isUltimateX {
            isComputingUXStrategy = true
            ultimateXTopHolds = []
            ultimateXUserHold = nil
            isComputingUXUserHold = false
            Task {
                await computeUXTopHolds()
            }
        }
    }

    func toggleCard(_ index: Int) {
        guard phase == .dealt, index >= 0, index < 5 else { return }

        audioService.play(.cardSelect)

        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }

        // Hide swipe tip after first card toggle
        if showSwipeTip {
            showSwipeTip = false
        }
    }

    func draw() async {
        guard phase == .dealt else { return }

        phase = .drawing
        isAnimating = true
        showDealtWinner = false

        // Check for mistakes if feedback is enabled
        if settings.showOptimalFeedback {
            checkForMistake()
            if showMistakeFeedback {
                hapticService.trigger(.error)
            }
        }

        // Handle 100-play mode differently with tally
        if settings.lineCount == .oneHundred {
            await performHundredPlayDraw()
        } else {
            await performStandardDraw()
        }

        isAnimating = false
        phase = .result

        // Clear saved hand state since hand completed normally
        await clearSavedHandState()
        RatingPromptService.shared.markTriggerEvent()
    }

    private func performStandardDraw() async {
        // Perform draws for each line
        var results: [PlayHandResult] = []
        var deckCopy = remainingDeck

        let isUX = settings.variant.isUltimateX
        let family = currentPaytable?.family ?? .jacksOrBetter

        for lineNum in 0..<settings.effectiveLineCount {
            let (finalHand, newDeck) = performDraw(
                dealtCards: dealtCards,
                heldIndices: selectedIndices,
                deck: deckCopy
            )
            deckCopy = newDeck

            let evaluation = evaluateFinalHand(finalHand)
            let basePayout = calculatePayout(handName: evaluation.handName)

            // For UX: multiply payout by the active multiplier for this line
            let lineMultiplier = (isUX && lineNum < ultimateXMultipliers.count)
                ? ultimateXMultipliers[lineNum] : 1
            let payout = basePayout * lineMultiplier

            let earnedMultiplier: Int
            if isUX {
                earnedMultiplier = UltimateXMultiplierTable.multiplier(
                    for: evaluation.handName ?? "no win",
                    playCount: settings.effectiveUXPlayCount,
                    family: family
                )
            } else {
                earnedMultiplier = 1
            }

            let result = PlayHandResult(
                lineNumber: lineNum + 1,
                finalHand: finalHand,
                handName: evaluation.handName,
                payout: payout,
                winningIndices: evaluation.winningIndices,
                appliedMultiplier: isUX ? lineMultiplier : 1,
                earnedMultiplier: earnedMultiplier
            )
            results.append(result)
        }

        // After all lines resolved: update UX multipliers for next hand
        if isUX {
            for (i, result) in results.enumerated() where i < ultimateXMultipliers.count {
                ultimateXMultipliers[i] = result.earnedMultiplier
            }
        }

        lineResults = results

        // For UX mode: compute user's hold EV if it isn't in the top-5
        if isUX {
            Task { await computeUXUserHoldIfNeeded() }
        }

        // Update balance with winnings
        let winAmount = totalPayoutDollars
        if winAmount > 0 {
            balance.win(winAmount)
            await PlayPersistence.shared.saveBalance(balance)

            // Update stats
            currentStats.totalWon += winAmount
            if winAmount > currentStats.biggestWin {
                currentStats.biggestWin = winAmount
                currentStats.biggestWinHandName = results.first { $0.payout > 0 }?.handName
            }

            // Track wins by hand type and check for big wins
            var hasBigWin = false
            for result in results {
                guard let handName = result.handName else { continue }
                currentStats.winsByHandType[handName, default: 0] += 1
                if currentPaytable?.isBigWin(handName: handName) == true {
                    hasBigWin = true
                }
            }

            // Play appropriate win sound
            if hasBigWin {
                audioService.play(.bigWin)
            } else if winAmount > settings.totalBetDollars {
                audioService.play(.correct)
            }
            // Small wins (win ≤ bet) play no sound
        }
    }

    private func performHundredPlayDraw() async {
        let isUX = settings.variant.isUltimateX
        let family = currentPaytable?.family ?? .jacksOrBetter

        // Track hand counts and actual payouts for tally
        var handCounts: [String: Int] = [:]
        var handActualPayouts: [String: Int] = [:]   // summed actual payouts per hand type (for UX)
        var handMultiplierSums: [String: Double] = [:]  // sum of multipliers applied per hand type
        var totalCreditsWon = 0
        var biggestSingleWin = 0
        var biggestWinHand: String?

        // Track earned multipliers per line for UX
        var newMultipliers: [Int] = isUX ? Array(repeating: 1, count: 100) : []

        // Perform 100 draws
        for i in 0..<100 {
            // Create a fresh deck for each hand (minus dealt cards)
            var freshDeck = Card.shuffledDeck(jokerCount: wwwWildCount)
            freshDeck.removeAll { card in
                dealtCards.contains { $0.rank == card.rank && $0.suit == card.suit }
            }

            let (finalHand, _) = performDraw(
                dealtCards: dealtCards,
                heldIndices: selectedIndices,
                deck: freshDeck
            )

            let evaluation = evaluateFinalHand(finalHand)
            let basePayout = calculatePayout(handName: evaluation.handName)

            // For UX: apply the per-line multiplier
            let lineMultiplier = (isUX && i < ultimateXMultipliers.count) ? ultimateXMultipliers[i] : 1
            let payout = basePayout * lineMultiplier

            // For UX: compute earned multiplier for this line
            if isUX {
                let earned = UltimateXMultiplierTable.multiplier(
                    for: evaluation.handName ?? "no win",
                    playCount: settings.effectiveUXPlayCount,
                    family: family
                )
                newMultipliers[i] = earned
            }

            if let handName = evaluation.handName {
                handCounts[handName, default: 0] += 1
                handActualPayouts[handName, default: 0] += payout
                handMultiplierSums[handName, default: 0.0] += Double(lineMultiplier)
                totalCreditsWon += payout

                if payout > biggestSingleWin {
                    biggestSingleWin = payout
                    biggestWinHand = handName
                }
            }
        }

        // After all 100 lines: update UX multipliers for next hand
        if isUX {
            for i in 0..<min(newMultipliers.count, ultimateXMultipliers.count) {
                ultimateXMultipliers[i] = newMultipliers[i]
            }
        }

        // Build tally results sorted by pay value (highest first)
        // For UX: use actual summed payouts as subtotal (since each line pays differently)
        var tallyResults: [HundredPlayTallyResult] = []
        for (handName, count) in handCounts {
            let payPerHand = calculatePayout(handName: handName)
            let subtotal = isUX ? (handActualPayouts[handName] ?? count * payPerHand) : count * payPerHand
            let avgMult = isUX
                ? (handMultiplierSums[handName] ?? Double(count)) / Double(count)
                : 1.0
            tallyResults.append(HundredPlayTallyResult(
                handName: handName,
                payPerHand: payPerHand,
                count: count,
                subtotal: subtotal,
                avgAppliedMultiplier: avgMult
            ))
        }
        tallyResults.sort { $0.payPerHand > $1.payPerHand }
        hundredPlayTally = tallyResults

        // Clear line results for 100-play mode
        lineResults = []

        // Update balance with winnings
        let winAmount = Double(totalCreditsWon) * settings.denomination.rawValue
        if winAmount > 0 {
            balance.win(winAmount)
            await PlayPersistence.shared.saveBalance(balance)

            // Update stats
            currentStats.totalWon += winAmount
            let biggestWinDollars = Double(biggestSingleWin) * settings.denomination.rawValue
            if biggestWinDollars > currentStats.biggestWin {
                currentStats.biggestWin = biggestWinDollars
                currentStats.biggestWinHandName = biggestWinHand
            }

            // Track wins by hand type and check for big wins
            var hasBigWin = false
            for (handName, count) in handCounts {
                currentStats.winsByHandType[handName, default: 0] += count
                if currentPaytable?.isBigWin(handName: handName) == true {
                    hasBigWin = true
                }
            }

            // Play appropriate win sound
            if hasBigWin {
                audioService.play(.bigWin)
            } else if winAmount > settings.totalBetDollars {
                audioService.play(.correct)
            }
            // Small wins (win ≤ bet) play no sound
        }
    }

    func newHand() {
        phase = .betting
        dealtCards = []
        selectedIndices = []
        lineResults = []
        hundredPlayTally = []
        remainingDeck = []
        optimalHoldIndices = []
        userEvLost = 0
        showMistakeFeedback = false
        strategyResult = nil
        wwwWildCount = 0
        ultimateXTopHolds = []
        isComputingUXStrategy = false
        ultimateXUserHold = nil
        isComputingUXUserHold = false
        uxAvgMultiplierUsed = 1.0
    }

    // MARK: - Settings Management

    func updateSettings(_ newSettings: PlaySettings) async {
        // If paytable or variant changed, load new stats and prepare paytable
        if newSettings.selectedPaytableId != settings.selectedPaytableId
            || newSettings.variant != settings.variant {
            allTimeStats = await PlayPersistence.shared.loadStats(for: newSettings.statsPaytableKey)
        }

        settings = newSettings
        await PlayPersistence.shared.saveSettings(settings)

        // Prepare the new paytable if needed
        await prepareCurrentPaytable()
    }

    func addFunds(_ amount: Double) async {
        balance.deposit(amount)
        await PlayPersistence.shared.saveBalance(balance)
    }

    /// Saves the current hand state when going to background.
    /// This allows the hand to be restored if the user returns, or refunded if the app is terminated.
    func saveHandState() async {
        guard phase == .dealt else {
            // No active hand to save - clear any stale state
            await PlayPersistence.shared.clearActiveHand()
            return
        }

        let state = ActiveHandState(
            dealtCards: dealtCards,
            selectedIndices: selectedIndices,
            remainingDeck: remainingDeck,
            betAmount: settings.totalBetDollars,
            settings: settings,
            wwwWildCount: wwwWildCount
        )
        await PlayPersistence.shared.saveActiveHand(state)
        debugNSLog("🎰 Hand state saved for background")
    }

    /// Restores the hand state when returning from background.
    /// Returns true if a hand was restored, false otherwise.
    @discardableResult
    func restoreHandState() async -> Bool {
        guard let savedHand = await PlayPersistence.shared.loadActiveHand() else {
            return false
        }

        // Restore the hand
        dealtCards = savedHand.dealtCards.map { $0.toCard() }
        selectedIndices = Set(savedHand.selectedIndices)
        remainingDeck = savedHand.remainingDeck.map { $0.toCard() }
        wwwWildCount = savedHand.wwwWildCount
        phase = .dealt

        // Clear the saved state since we've restored it
        await PlayPersistence.shared.clearActiveHand()

        debugNSLog("🎰 Hand state restored from background")
        return true
    }

    /// Clears any saved hand state (call when hand is completed normally).
    func clearSavedHandState() async {
        await PlayPersistence.shared.clearActiveHand()
    }

    /// Abandons the current hand when user explicitly navigates away.
    /// Refunds the bet and does not count the hand in statistics.
    func abandonHand() async {
        guard phase == .dealt else { return }

        // Refund the bet
        let betAmount = settings.totalBetDollars
        balance.win(betAmount)
        await PlayPersistence.shared.saveBalance(balance)

        // Remove from stats (hand was counted when dealt)
        currentStats.handsPlayed -= 1
        currentStats.totalBet -= betAmount

        // Clear any saved hand state
        await PlayPersistence.shared.clearActiveHand()

        // Reset hand state
        dealtCards = []
        selectedIndices = []
        remainingDeck = []
        lineResults = []
        hundredPlayTally = []
        optimalHoldIndices = []
        userEvLost = 0
        showMistakeFeedback = false
        strategyResult = nil
        wwwWildCount = 0
        showDealtWinner = false
        dealtWinnerName = nil

        phase = .betting

        debugNSLog("🎰 Hand abandoned - bet refunded: $%.2f", betAmount)
    }

    // MARK: - Stats Management

    func endSession() async {
        guard let startDate = sessionStartDate else { return }

        // Create session record
        let record = PlaySessionRecord(
            startDate: startDate,
            endDate: Date(),
            stats: currentStats
        )

        // Update all-time stats
        allTimeStats.allTime.handsPlayed += currentStats.handsPlayed
        allTimeStats.allTime.totalBet += currentStats.totalBet
        allTimeStats.allTime.totalWon += currentStats.totalWon
        allTimeStats.allTime.mistakesMade += currentStats.mistakesMade
        allTimeStats.allTime.totalEvLost += currentStats.totalEvLost
        allTimeStats.allTime.mistakeHands += currentStats.mistakeHands

        if currentStats.biggestWin > allTimeStats.allTime.biggestWin {
            allTimeStats.allTime.biggestWin = currentStats.biggestWin
            allTimeStats.allTime.biggestWinHandName = currentStats.biggestWinHandName
        }

        // Merge win counts
        for (handType, count) in currentStats.winsByHandType {
            allTimeStats.allTime.winsByHandType[handType, default: 0] += count
        }

        allTimeStats.sessions.append(record)
        await PlayPersistence.shared.saveStats(allTimeStats)

        // Reset session
        sessionStartDate = nil
        currentStats = PlaySessionStats()
    }

    func getAllTimeStats() -> PlayStats {
        return allTimeStats
    }

    // MARK: - Ultimate X State

    func initializeUXMultipliers() {
        guard settings.variant.isUltimateX else { return }
        let lineCount = settings.lineCount == .oneHundred ? 100 : settings.effectiveLineCount
        ultimateXMultipliers = Array(repeating: 1, count: lineCount)
        ultimateXTopHolds = []
    }

    func resetUXState() {
        ultimateXMultipliers = []
        ultimateXTopHolds = []
        isComputingUXStrategy = false
        ultimateXUserHold = nil
        isComputingUXUserHold = false
        uxAvgMultiplierUsed = 1.0
    }

    // MARK: - Private Helpers

    private func evaluateDealtHandForBanner() {
        let evaluation = evaluateFinalHand(dealtCards)
        if let handName = evaluation.handName {
            showDealtWinner = true
            dealtWinnerName = handName
            audioService.play(.dealtWinner)
        }
    }

    private func performDraw(dealtCards: [Card], heldIndices: Set<Int>, deck: [Card]) -> ([Card], [Card]) {
        var finalHand = dealtCards
        var remainingDeck = deck
        var drawIndex = 0

        for i in 0..<5 {
            if !heldIndices.contains(i) {
                guard drawIndex < remainingDeck.count else { break }
                finalHand[i] = remainingDeck[drawIndex]
                drawIndex += 1
            }
        }

        remainingDeck = Array(remainingDeck.dropFirst(drawIndex))
        return (finalHand, remainingDeck)
    }

    private func lookupOptimalStrategy() async {
        let hand = Hand(cards: dealtCards)

        do {
            if settings.variant.isWildWildWild {
                let baseId = settings.selectedPaytableId
                let wwwId = WildWildWildDistribution.wwwStrategyId(baseId: baseId, wildCount: wwwWildCount)
                if let result = try await StrategyService.shared.lookup(hand: hand, paytableId: wwwId) {
                    let canonicalIndices = result.bestHoldIndices
                    optimalHoldIndices = hand.canonicalIndicesToOriginal(canonicalIndices).sorted()
                    strategyResult = result
                }
            } else if let result = try await StrategyService.shared.lookup(hand: hand, paytableId: settings.selectedPaytableId) {
                let canonicalIndices = result.bestHoldIndices
                optimalHoldIndices = hand.canonicalIndicesToOriginal(canonicalIndices).sorted()
                strategyResult = result
            }
        } catch {
            debugLog("Failed to lookup optimal strategy: \(error)")
        }
    }

    /// Computes the top-5 optimal holds for Ultimate X using the full EV formula.
    /// Fires as a background Task after deal; updates ultimateXTopHolds when done.
    private func computeUXTopHolds() async {
        defer { isComputingUXStrategy = false }
        guard settings.variant.isUltimateX else { return }
        let pc = settings.effectiveUXPlayCount

        // Snapshot the dealt hand before any awaits so we can detect stale results
        let handSnapshot = dealtCards

        let hand = Hand(cards: dealtCards)
        let paytableId = settings.selectedPaytableId

        // 1. Get base strategy result (all holdEvs)
        guard let baseResult = try? await StrategyService.shared.lookup(hand: hand, paytableId: paytableId) else { return }

        // 2. Pick top-5 bitmasks by base EV (bitmask 0 = draw all is included)
        let topBitmasks = baseResult.holdEvs
            .compactMap { key, ev -> (bitmask: Int, ev: Double)? in
                guard let bitmask = Int(key) else { return nil }
                return (bitmask: bitmask, ev: ev)
            }
            .sorted { $0.ev > $1.ev }
            .prefix(5)
            .map { $0.bitmask }

        // 3. Average multiplier across all lines
        let avgMultiplier: Double = ultimateXMultipliers.isEmpty
            ? 1.0
            : Double(ultimateXMultipliers.reduce(0, +)) / Double(ultimateXMultipliers.count)
        uxAvgMultiplierUsed = avgMultiplier

        let calculator = HoldOutcomeCalculator()
        var holdOptions: [UltimateXHoldOption] = []

        for bitmask in topBitmasks {
            guard let baseEV = baseResult.holdEvs[String(bitmask)] else { continue }

            let eK = await calculator.computeEK(
                hand: hand,
                holdBitmask: bitmask,
                paytableId: paytableId,
                playCount: pc
            )
            let adjustedEV = avgMultiplier * 2.0 * baseEV + eK - 1.0

            // Convert canonical indices back to original positions for display
            let canonicalIndices = Hand.holdIndicesFromBitmask(bitmask)
            let originalIndices = hand.canonicalIndicesToOriginal(canonicalIndices).sorted()

            holdOptions.append(UltimateXHoldOption(
                id: bitmask,
                holdIndices: originalIndices,
                baseEV: baseEV,
                eKAwarded: eK,
                adjustedEV: adjustedEV
            ))
        }

        // 4. Sort by adjustedEV descending
        holdOptions.sort { $0.adjustedEV > $1.adjustedEV }

        // Guard: if the user dealt a new hand while we were computing, discard stale results
        guard dealtCards == handSnapshot else { return }

        ultimateXTopHolds = holdOptions
    }

    /// Computes the user's actual hold EV after draw, adding it to the panel if not already in top-5.
    @MainActor
    private func computeUXUserHoldIfNeeded() async {
        guard settings.variant.isUltimateX else { return }
        guard !dealtCards.isEmpty else { return }

        // If top-5 is still computing, skip — panel will show computing spinner for top-5
        guard !isComputingUXStrategy else { return }

        let hand = Hand(cards: dealtCards)
        let paytableId = settings.selectedPaytableId
        let pc = settings.effectiveUXPlayCount

        // Convert original selectedIndices → canonical → bitmask
        let userOriginalIndices = Array(selectedIndices).sorted()
        let userCanonicalIndices = hand.originalIndicesToCanonical(userOriginalIndices)
        let userBitmask = Hand.bitmaskFromHoldIndices(userCanonicalIndices)

        // Check if user's hold is already in the top-5
        if ultimateXTopHolds.contains(where: { $0.id == userBitmask }) {
            ultimateXUserHold = nil
            return
        }

        // Not in top-5 — compute on the fly
        isComputingUXUserHold = true
        defer { isComputingUXUserHold = false }

        let avgMultiplier: Double = ultimateXMultipliers.isEmpty
            ? 1.0
            : Double(ultimateXMultipliers.reduce(0, +)) / Double(ultimateXMultipliers.count)

        // Get base EV for user's bitmask from StrategyService
        let baseEV: Double
        if let baseResult = try? await StrategyService.shared.lookup(hand: hand, paytableId: paytableId),
           let ev = baseResult.holdEvs[String(userBitmask)] {
            baseEV = ev
        } else {
            baseEV = 0.0
        }

        // Compute E[K] for this hold
        let eK = await HoldOutcomeCalculator().computeEK(
            hand: hand,
            holdBitmask: userBitmask,
            paytableId: paytableId,
            playCount: pc
        )

        let adjustedEV = avgMultiplier * 2.0 * baseEV + eK - 1.0

        // Convert canonical indices back to original positions for display
        let canonicalDisplayIndices = Hand.holdIndicesFromBitmask(userBitmask)
        let originalDisplayIndices = hand.canonicalIndicesToOriginal(canonicalDisplayIndices).sorted()

        ultimateXUserHold = UltimateXHoldOption(
            id: userBitmask,
            holdIndices: originalDisplayIndices,
            baseEV: baseEV,
            eKAwarded: eK,
            adjustedEV: adjustedEV
        )
    }

    private func checkForMistake() {
        let userHold = Array(selectedIndices).sorted()

        // For UX: use the top hold from adjustedEV-ranked list; fall back to base EV if not yet computed
        let optimal: [Int]
        if settings.variant.isUltimateX, let topHold = ultimateXTopHolds.first {
            optimal = topHold.holdIndices.sorted()
        } else {
            optimal = optimalHoldIndices.sorted()
        }

        if userHold != optimal {
            showMistakeFeedback = true
            currentStats.mistakesMade += 1
            currentStats.mistakeHands += 1

            // Calculate EV loss
            Task {
                await calculateEvLoss()
            }
        }

        // Save hand attempt (for all hands, not just mistakes)
        Task {
            await saveHandAttempt(isCorrect: userHold == optimal)
        }
    }

    private func saveHandAttempt(isCorrect: Bool) async {
        guard let user = SupabaseService.shared.currentUser,
              let result = strategyResult else { return }

        let hand = Hand(cards: dealtCards)
        let userHold = Array(selectedIndices).sorted()

        // Convert canonical best hold to original order
        let canonicalBestHold = result.bestHoldIndices
        let correctHold = hand.canonicalIndicesToOriginal(canonicalBestHold)

        // Calculate EV difference
        var evDifference: Double = 0
        if !isCorrect {
            let userCanonicalHold = hand.originalIndicesToCanonical(userHold)
            let userBitmask = Hand.bitmaskFromHoldIndices(userCanonicalHold)
            if let userEv = result.holdEvs[String(userBitmask)] {
                evDifference = result.bestEv - userEv
            }
        }

        // Determine hand category
        let category = HandCategory.categorize(hand: hand, holdIndices: correctHold)

        let attempt = HandAttempt(
            userId: user.id,
            handKey: hand.canonicalKey,
            handCategory: category.rawValue,
            paytableId: settings.selectedPaytableId,
            userHold: userHold,
            optimalHold: correctHold,
            isCorrect: isCorrect,
            evDifference: evDifference,
            responseTimeMs: nil  // Play mode doesn't track response time
        )

        await SyncService.shared.saveAttempt(attempt)
    }

    private func calculateEvLoss() async {
        // For UX mode: use adjustedEV values from ultimateXTopHolds
        if settings.variant.isUltimateX, !ultimateXTopHolds.isEmpty {
            let userHold = Array(selectedIndices).sorted()
            let bestAdjustedEV = ultimateXTopHolds[0].adjustedEV

            // Find the user's hold in the top holds list, or use ultimateXUserHold
            let userAdjustedEV: Double?
            if let userHoldOption = ultimateXUserHold {
                userAdjustedEV = userHoldOption.adjustedEV
            } else {
                userAdjustedEV = ultimateXTopHolds.first(where: { $0.holdIndices.sorted() == userHold })?.adjustedEV
            }

            if let userEV = userAdjustedEV {
                let evLost = bestAdjustedEV - userEV
                userEvLost = evLost
                currentStats.totalEvLost += evLost * settings.totalBetDollars
            }
            return
        }

        let hand = Hand(cards: dealtCards)
        let userHold = Array(selectedIndices).sorted()

        let strategyPaytableId: String
        if settings.variant.isWildWildWild {
            strategyPaytableId = WildWildWildDistribution.wwwStrategyId(baseId: settings.selectedPaytableId, wildCount: wwwWildCount)
        } else {
            strategyPaytableId = settings.selectedPaytableId
        }

        do {
            if let result = try await StrategyService.shared.lookup(hand: hand, paytableId: strategyPaytableId) {
                let userCanonicalHold = hand.originalIndicesToCanonical(userHold)
                let userBitmask = Hand.bitmaskFromHoldIndices(userCanonicalHold)

                if let userEv = result.holdEvs[String(userBitmask)] {
                    let evLost = result.bestEv - userEv
                    userEvLost = evLost
                    currentStats.totalEvLost += evLost * settings.totalBetDollars
                }
            }
        } catch {
            debugLog("Failed to calculate EV loss: \(error)")
        }
    }

    // MARK: - Hand Evaluation

    private struct HandEvaluation {
        let handName: String?
        let winningIndices: [Int]
    }

    private func evaluateFinalHand(_ cards: [Card]) -> HandEvaluation {
        // WWW mode: use dedicated evaluator
        if settings.variant.isWildWildWild {
            return evaluateWWWHand(cards)
        }

        let paytableId = settings.selectedPaytableId

        var rankCounts: [Int: Int] = [:]
        for card in cards {
            rankCounts[card.rank.rawValue, default: 0] += 1
        }

        let pairs = rankCounts.filter { $0.value == 2 }.map { $0.key }.sorted(by: >)
        let trips = rankCounts.filter { $0.value == 3 }.map { $0.key }
        let quads = rankCounts.filter { $0.value == 4 }.map { $0.key }
        let numDeuces = rankCounts[2, default: 0]

        // Check hand types based on paytable
        if paytableId.hasPrefix("deuces-wild") || paytableId.hasPrefix("loose-deuces") {
            return evaluateDeucesWildHand(cards: cards, rankCounts: rankCounts, numDeuces: numDeuces)
        } else {
            let paytableRowNames = Set(currentPaytable?.rows.map { $0.handName } ?? [])
            return evaluateStandardHand(cards: cards, pairs: pairs, trips: trips, quads: quads, paytableRowNames: paytableRowNames)
        }
    }

    private func evaluateStandardHand(cards: [Card], pairs: [Int], trips: [Int], quads: [Int], paytableRowNames: Set<String>) -> HandEvaluation {
        // Royal Flush
        if isRoyalFlush(cards) {
            return HandEvaluation(handName: "Royal Flush", winningIndices: Array(0..<5))
        }

        // Straight Flush
        if isStraightFlush(cards) {
            return HandEvaluation(handName: "Straight Flush", winningIndices: Array(0..<5))
        }

        // Four of a Kind (with kicker checks for bonus games)
        if let quadRank = quads.first {
            let quadIndices = getCardIndices(cards: cards, rank: quadRank)
            let kicker = cards.first { $0.rank.rawValue != quadRank }?.rank.rawValue ?? 0
            let handName = HandEvaluator.resolveQuadHandName(quadRank: quadRank, kickerRank: kicker, paytableRowNames: paytableRowNames)
            return HandEvaluation(handName: handName, winningIndices: quadIndices)
        }

        // Full House
        if !trips.isEmpty && !pairs.isEmpty {
            return HandEvaluation(handName: "Full House", winningIndices: Array(0..<5))
        }

        // Flush
        if isFlush(cards) {
            return HandEvaluation(handName: "Flush", winningIndices: Array(0..<5))
        }

        // Straight
        if isStraight(cards) {
            return HandEvaluation(handName: "Straight", winningIndices: Array(0..<5))
        }

        // Three of a Kind
        if let tripRank = trips.first {
            let indices = getCardIndices(cards: cards, rank: tripRank)
            return HandEvaluation(handName: "Three of a Kind", winningIndices: indices)
        }

        // Two Pair
        if pairs.count >= 2 {
            let indices1 = getCardIndices(cards: cards, rank: pairs[0])
            let indices2 = getCardIndices(cards: cards, rank: pairs[1])
            return HandEvaluation(handName: "Two Pair", winningIndices: indices1 + indices2)
        }

        // High pair (data-driven: Pair of Aces / Kings or Better / Jacks or Better / Tens or Better)
        if let pairInfo = HandEvaluator.resolveHighPairInfo(paytableRowNames: paytableRowNames) {
            for pairRank in pairs {
                if pairRank >= pairInfo.minRank {
                    let indices = getCardIndices(cards: cards, rank: pairRank)
                    return HandEvaluation(handName: pairInfo.name, winningIndices: indices)
                }
            }
        }

        return HandEvaluation(handName: nil, winningIndices: [])
    }

    private func evaluateDeucesWildHand(cards: [Card], rankCounts: [Int: Int], numDeuces: Int) -> HandEvaluation {
        // Natural Royal (no deuces)
        if numDeuces == 0 && isRoyalFlush(cards) {
            return HandEvaluation(handName: "Natural Royal", winningIndices: Array(0..<5))
        }

        // Four Deuces
        if numDeuces == 4 {
            return HandEvaluation(handName: "Four Deuces", winningIndices: getCardIndices(cards: cards, rank: 2))
        }

        // Wild Royal
        if numDeuces > 0 && isWildRoyalFlush(cards, numDeuces: numDeuces) {
            return HandEvaluation(handName: "Wild Royal", winningIndices: Array(0..<5))
        }

        // Five of a Kind
        let maxCount = rankCounts.filter { $0.key != 2 }.map { $0.value }.max() ?? 0
        if maxCount + numDeuces >= 5 {
            return HandEvaluation(handName: "Five of a Kind", winningIndices: Array(0..<5))
        }

        // Straight Flush
        if isStraightFlush(cards) || canMakeStraightFlushWithWilds(cards, numDeuces: numDeuces) {
            return HandEvaluation(handName: "Straight Flush", winningIndices: Array(0..<5))
        }

        // Four of a Kind
        if maxCount + numDeuces >= 4 {
            return HandEvaluation(handName: "Four of a Kind", winningIndices: Array(0..<5))
        }

        // Full House
        if canMakeFullHouseWithWilds(rankCounts: rankCounts, numDeuces: numDeuces) {
            return HandEvaluation(handName: "Full House", winningIndices: Array(0..<5))
        }

        // Flush (deuces are wild for suit)
        if isFlushWithWilds(cards) {
            return HandEvaluation(handName: "Flush", winningIndices: Array(0..<5))
        }

        // Straight
        if isStraight(cards) || canMakeStraightWithWilds(cards, numDeuces: numDeuces) {
            return HandEvaluation(handName: "Straight", winningIndices: Array(0..<5))
        }

        // Three of a Kind (minimum paying hand in Deuces Wild)
        if maxCount + numDeuces >= 3 {
            return HandEvaluation(handName: "Three of a Kind", winningIndices: Array(0..<5))
        }

        return HandEvaluation(handName: nil, winningIndices: [])
    }

    private func calculatePayout(handName: String?) -> Int {
        guard let handName = handName,
              let paytable = currentPaytable else { return 0 }

        // UX bets 10 coins but uses the 5-coin paytable payout column
        let paytableCoinIndex = min(settings.coinsPerLine, 5) - 1
        guard paytableCoinIndex >= 0,
              paytableCoinIndex < 5 else { return 0 }

        let rows = settings.variant.isWildWildWild ? paytable.wwwRows() : paytable.rows
        guard let row = rows.first(where: { $0.handName == handName }) else { return 0 }
        guard paytableCoinIndex < row.payouts.count else { return 0 }
        return row.payouts[paytableCoinIndex]
    }

    // MARK: - Hand Detection Helpers

    private func isFlush(_ cards: [Card]) -> Bool {
        let firstSuit = cards[0].suit
        return cards.allSatisfy { $0.suit == firstSuit }
    }

    private func isFlushWithWilds(_ cards: [Card]) -> Bool {
        let nonDeuceCards = cards.filter { $0.rank.rawValue != 2 }
        guard !nonDeuceCards.isEmpty else { return true }
        let firstSuit = nonDeuceCards[0].suit
        return nonDeuceCards.allSatisfy { $0.suit == firstSuit }
    }

    private func isStraight(_ cards: [Card]) -> Bool {
        let ranks = cards.map { $0.rank.rawValue }.sorted()

        // Regular straight
        var isConsecutive = true
        for i in 0..<4 {
            if ranks[i+1] != ranks[i] + 1 {
                isConsecutive = false
                break
            }
        }
        if isConsecutive { return true }

        // Wheel (A-2-3-4-5)
        return ranks == [2, 3, 4, 5, 14]
    }

    private func isStraightFlush(_ cards: [Card]) -> Bool {
        return isFlush(cards) && isStraight(cards)
    }

    private func isRoyalFlush(_ cards: [Card]) -> Bool {
        if !isFlush(cards) { return false }
        let ranks = Set(cards.map { $0.rank.rawValue })
        return ranks == Set([10, 11, 12, 13, 14])
    }

    private func isWildRoyalFlush(_ cards: [Card], numDeuces: Int) -> Bool {
        if numDeuces == 0 { return false }

        // Check if non-deuce cards are all same suit (deuces are wild for suit)
        let nonDeuceCards = cards.filter { $0.rank.rawValue != 2 }
        if !nonDeuceCards.isEmpty {
            let firstSuit = nonDeuceCards[0].suit
            if !nonDeuceCards.allSatisfy({ $0.suit == firstSuit }) {
                return false
            }
        }

        let nonDeuceRanks = nonDeuceCards.map { $0.rank.rawValue }
        let royalRanks: Set<Int> = [10, 11, 12, 13, 14]

        if !Set(nonDeuceRanks).isSubset(of: royalRanks) { return false }

        let missing = royalRanks.subtracting(nonDeuceRanks).count
        return missing <= numDeuces
    }

    private func canMakeStraightWithWilds(_ cards: [Card], numDeuces: Int) -> Bool {
        let nonDeuceRanks = cards.filter { $0.rank.rawValue != 2 }.map { $0.rank.rawValue }
        guard nonDeuceRanks.count + numDeuces == 5 else { return false }

        // If all cards are wild, any straight is possible
        if nonDeuceRanks.isEmpty { return true }

        // Try each possible straight window (A-low through 10-high)
        // Straights: A-2-3-4-5 (1-5), 2-6, 3-7, 4-8, 5-9, 6-10, 7-J, 8-Q, 9-K, 10-A
        let startRanks = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

        for low in startRanks {
            let high = low + 4

            // Check if ALL non-wild cards fit in this window
            var allFit = true
            for rank in nonDeuceRanks {
                // For A-low straight (wheel), Ace (14) counts as 1
                let effectiveRank = (low == 1 && rank == 14) ? 1 : rank
                if effectiveRank < low || effectiveRank > high {
                    allFit = false
                    break
                }
            }

            if allFit {
                // Count unique ranks in this window to see how many wilds we need
                let uniqueRanksInWindow = Set(nonDeuceRanks.map { rank -> Int in
                    (low == 1 && rank == 14) ? 1 : rank
                })
                let neededWilds = 5 - uniqueRanksInWindow.count
                if neededWilds <= numDeuces {
                    return true
                }
            }
        }

        return false
    }

    private func canMakeStraightFlushWithWilds(_ cards: [Card], numDeuces: Int) -> Bool {
        // Check if non-deuce cards are all same suit (deuces are wild for suit)
        let nonDeuceCards = cards.filter { $0.rank.rawValue != 2 }
        if !nonDeuceCards.isEmpty {
            let firstSuit = nonDeuceCards[0].suit
            if !nonDeuceCards.allSatisfy({ $0.suit == firstSuit }) {
                return false
            }
        }
        return canMakeStraightWithWilds(cards, numDeuces: numDeuces)
    }

    private func canMakeFullHouseWithWilds(rankCounts: [Int: Int], numDeuces: Int) -> Bool {
        let nonDeuces = rankCounts.filter { $0.key != 2 }.sorted { $0.value > $1.value }

        guard nonDeuces.count >= 2 else { return false }

        let first = nonDeuces[0].value
        let second = nonDeuces[1].value

        let neededForTrips = max(0, 3 - first)
        let neededForPair = max(0, 2 - second)

        return neededForTrips + neededForPair <= numDeuces
    }

    // MARK: - Generic Wild Helpers (for WWW — do NOT filter deuces)

    /// Generic: all naturals same suit (wilds fill suit)
    private func isFlushWithGenericWilds(_ naturals: [Card]) -> Bool {
        guard !naturals.isEmpty else { return true }
        let firstSuit = naturals[0].suit
        return naturals.allSatisfy { $0.suit == firstSuit }
    }

    /// Generic: can naturals + wilds form a royal flush?
    private func isWildRoyalWithGenericWilds(_ naturals: [Card], numWilds: Int) -> Bool {
        guard numWilds > 0 else { return false }
        guard isFlushWithGenericWilds(naturals) else { return false }
        let royalRanks: Set<Int> = [10, 11, 12, 13, 14] // T, J, Q, K, A
        let naturalRanks = Set(naturals.map { $0.rank.rawValue })
        guard naturalRanks.isSubset(of: royalRanks) else { return false }
        return naturalRanks.count + numWilds >= 5
    }

    /// Generic: can naturals + wilds form a straight?
    private func canMakeStraightWithGenericWilds(_ naturals: [Card], numWilds: Int) -> Bool {
        let ranks = naturals.map { $0.rank.rawValue }.sorted()
        guard ranks.count + numWilds == 5 else { return false }
        guard Set(ranks).count == ranks.count else { return false } // no duplicates
        // Try ace-low (A=1) and ace-high (A=14)
        for aceVal in [14, 1] {
            let adjusted = ranks.map { $0 == 14 ? aceVal : $0 }.sorted()
            if adjusted.isEmpty { return true } // all wilds
            let lo = adjusted.first!
            let hi = adjusted.last!
            if hi - lo <= 4 { return true }
        }
        return false
    }

    /// Generic: can naturals + wilds form a straight flush?
    private func canMakeStraightFlushWithGenericWilds(_ naturals: [Card], numWilds: Int) -> Bool {
        guard isFlushWithGenericWilds(naturals) else { return false }
        return canMakeStraightWithGenericWilds(naturals, numWilds: numWilds)
    }

    /// Generic: can rank counts + wilds form a full house?
    private func canMakeFullHouseWithGenericWilds(rankCounts: [Int: Int], numWilds: Int) -> Bool {
        let sorted = rankCounts.values.sorted(by: >)
        guard sorted.count >= 2 else { return false }
        let needTrips = max(0, 3 - sorted[0])
        let needPair = max(0, 2 - sorted[1])
        return needTrips + needPair <= numWilds
    }

    // MARK: - WWW Hand Evaluation

    private func evaluateWWWHand(_ cards: [Card]) -> HandEvaluation {
        let isDeucesBase = settings.selectedPaytableId.hasPrefix("deuces-wild") ||
                           settings.selectedPaytableId.hasPrefix("loose-deuces")

        let numJokers = cards.filter { $0.rank == .joker }.count
        let nonJokers = cards.filter { $0.rank != .joker }
        let numDeuces = isDeucesBase ? nonJokers.filter { $0.rank == .two }.count : 0
        let totalWilds = numJokers + numDeuces

        let naturals = nonJokers.filter { !isDeucesBase || $0.rank != .two }

        var rankCounts: [Int: Int] = [:]
        for card in naturals {
            rankCounts[card.rank.rawValue, default: 0] += 1
        }
        let maxCount = rankCounts.values.max() ?? 0

        // Zero wilds — evaluate as standard
        if totalWilds == 0 {
            let paytableRowNames = Set(currentPaytable?.rows.map { $0.handName } ?? [])
            let pairs = rankCounts.filter { $0.value == 2 }.map { $0.key }.sorted(by: >)
            let trips = rankCounts.filter { $0.value == 3 }.map { $0.key }
            let quads = rankCounts.filter { $0.value == 4 }.map { $0.key }
            return evaluateStandardHand(cards: cards, pairs: pairs, trips: trips, quads: quads, paytableRowNames: paytableRowNames)
        }

        // Deuces-specific: Four Deuces
        if isDeucesBase && numDeuces == 4 {
            return HandEvaluation(handName: "Four Deuces", winningIndices: getCardIndices(cards: cards, rank: 2))
        }

        // Five of a Kind
        if maxCount + totalWilds >= 5 {
            return HandEvaluation(handName: "Five of a Kind", winningIndices: Array(0..<5))
        }

        // Wild Royal Flush — USE GENERIC HELPER
        if isWildRoyalWithGenericWilds(naturals, numWilds: totalWilds) {
            return HandEvaluation(handName: "Wild Royal", winningIndices: Array(0..<5))
        }

        // Straight Flush — USE GENERIC HELPER
        if canMakeStraightFlushWithGenericWilds(naturals, numWilds: totalWilds) {
            return HandEvaluation(handName: "Straight Flush", winningIndices: Array(0..<5))
        }

        // Four of a Kind
        if maxCount + totalWilds >= 4 {
            let paytableRowNames = Set(currentPaytable?.rows.map { $0.handName } ?? [])
            let quadRank = rankCounts.max(by: { $0.value < $1.value })?.key ?? 0
            let kicker = naturals.first { $0.rank.rawValue != quadRank }?.rank.rawValue ?? 0
            let handName = HandEvaluator.resolveQuadHandName(quadRank: quadRank, kickerRank: kicker, paytableRowNames: paytableRowNames)
            return HandEvaluation(handName: handName, winningIndices: Array(0..<5))
        }

        // Full House — USE GENERIC HELPER
        if canMakeFullHouseWithGenericWilds(rankCounts: rankCounts, numWilds: totalWilds) {
            return HandEvaluation(handName: "Full House", winningIndices: Array(0..<5))
        }

        // Flush and Straight checks — USE GENERIC HELPERS
        let isFlushResult = isFlushWithGenericWilds(naturals)
        let isStraightResult = canMakeStraightWithGenericWilds(naturals, numWilds: totalWilds)
        if isFlushResult && !isStraightResult {
            return HandEvaluation(handName: "Flush", winningIndices: Array(0..<5))
        }

        if isStraightResult && !isFlushResult {
            return HandEvaluation(handName: "Straight", winningIndices: Array(0..<5))
        }

        // Three of a Kind
        if maxCount + totalWilds >= 3 {
            return HandEvaluation(handName: "Three of a Kind", winningIndices: Array(0..<5))
        }

        // Two Pair
        let numPairs = rankCounts.filter { $0.value == 2 }.count
        if numPairs >= 2 {
            return HandEvaluation(handName: "Two Pair", winningIndices: Array(0..<5))
        }

        // High Pair
        if let pairInfo = HandEvaluator.resolveHighPairInfo(paytableRowNames: Set(currentPaytable?.rows.map { $0.handName } ?? [])) {
            let highestNatural = rankCounts.keys.max() ?? 0
            if highestNatural >= pairInfo.minRank || totalWilds >= 1 {
                let bestRank = max(highestNatural, pairInfo.minRank)
                if bestRank >= pairInfo.minRank {
                    return HandEvaluation(handName: pairInfo.name, winningIndices: Array(0..<5))
                }
            }
        }

        return HandEvaluation(handName: nil, winningIndices: [])
    }

    private func getCardIndices(cards: [Card], rank: Int) -> [Int] {
        return cards.enumerated().compactMap { index, card in
            card.rank.rawValue == rank ? index : nil
        }
    }
}
