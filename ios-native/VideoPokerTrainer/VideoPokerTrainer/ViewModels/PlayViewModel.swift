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
        self.allTimeStats = await PlayPersistence.shared.loadStats(for: settings.selectedPaytableId)

        // Check for orphaned hand (app was terminated with active hand)
        await checkForOrphanedHand()

        // Prepare the paytable if needed
        await prepareCurrentPaytable()
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

        // Deal cards
        let deck = Card.shuffledDeck()
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
    }

    private func performStandardDraw() async {
        // Perform draws for each line
        var results: [PlayHandResult] = []
        var deckCopy = remainingDeck

        for lineNum in 0..<settings.lineCount.rawValue {
            let (finalHand, newDeck) = performDraw(
                dealtCards: dealtCards,
                heldIndices: selectedIndices,
                deck: deckCopy
            )
            deckCopy = newDeck

            let evaluation = evaluateFinalHand(finalHand)
            let payout = calculatePayout(handName: evaluation.handName)

            let result = PlayHandResult(
                lineNumber: lineNum + 1,
                finalHand: finalHand,
                handName: evaluation.handName,
                payout: payout,
                winningIndices: evaluation.winningIndices
            )
            results.append(result)
        }

        lineResults = results

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
            for result in results where result.handName != nil {
                let handName = result.handName!
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
        // Track hand counts for tally
        var handCounts: [String: Int] = [:]
        var totalCreditsWon = 0
        var biggestSingleWin = 0
        var biggestWinHand: String?

        // Perform 100 draws
        for _ in 0..<100 {
            // Create a fresh deck for each hand (minus dealt cards)
            var freshDeck = Card.shuffledDeck()
            freshDeck.removeAll { card in
                dealtCards.contains { $0.rank == card.rank && $0.suit == card.suit }
            }

            let (finalHand, _) = performDraw(
                dealtCards: dealtCards,
                heldIndices: selectedIndices,
                deck: freshDeck
            )

            let evaluation = evaluateFinalHand(finalHand)
            let payout = calculatePayout(handName: evaluation.handName)

            if let handName = evaluation.handName {
                handCounts[handName, default: 0] += 1
                totalCreditsWon += payout

                if payout > biggestSingleWin {
                    biggestSingleWin = payout
                    biggestWinHand = handName
                }
            }
        }

        // Build tally results sorted by pay value (highest first)
        var tallyResults: [HundredPlayTallyResult] = []
        for (handName, count) in handCounts {
            let payPerHand = calculatePayout(handName: handName)
            let subtotal = count * payPerHand
            tallyResults.append(HundredPlayTallyResult(
                handName: handName,
                payPerHand: payPerHand,
                count: count,
                subtotal: subtotal
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
    }

    // MARK: - Settings Management

    func updateSettings(_ newSettings: PlaySettings) async {
        // If paytable changed, load new stats and prepare paytable
        if newSettings.selectedPaytableId != settings.selectedPaytableId {
            allTimeStats = await PlayPersistence.shared.loadStats(for: newSettings.selectedPaytableId)
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
            settings: settings
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
            if let result = try await StrategyService.shared.lookup(hand: hand, paytableId: settings.selectedPaytableId) {
                let canonicalIndices = result.bestHoldIndices
                optimalHoldIndices = hand.canonicalIndicesToOriginal(canonicalIndices).sorted()
                strategyResult = result
            }
        } catch {
            debugLog("Failed to lookup optimal strategy: \(error)")
        }
    }

    private func checkForMistake() {
        let userHold = Array(selectedIndices).sorted()
        let optimal = optimalHoldIndices.sorted()

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
        let hand = Hand(cards: dealtCards)
        let userHold = Array(selectedIndices).sorted()

        do {
            if let result = try await StrategyService.shared.lookup(hand: hand, paytableId: settings.selectedPaytableId) {
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
        if paytableId.contains("deuces-wild") {
            return evaluateDeucesWildHand(cards: cards, rankCounts: rankCounts, numDeuces: numDeuces)
        } else {
            return evaluateStandardHand(cards: cards, pairs: pairs, trips: trips, quads: quads, paytableId: paytableId)
        }
    }

    private func evaluateStandardHand(cards: [Card], pairs: [Int], trips: [Int], quads: [Int], paytableId: String) -> HandEvaluation {
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
            let handName = getFourOfAKindName(quadRank: quadRank, cards: cards, paytableId: paytableId)
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

        // High pair (Jacks or Better / Tens or Better)
        let minPairRank = paytableId.contains("tens-or-better") ? 10 : 11
        for pairRank in pairs {
            if pairRank >= minPairRank {
                let indices = getCardIndices(cards: cards, rank: pairRank)
                let handName = paytableId.contains("tens-or-better") ? "Tens or Better" : "Jacks or Better"
                return HandEvaluation(handName: handName, winningIndices: indices)
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

        // Flush
        if isFlush(cards) {
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

    private func getFourOfAKindName(quadRank: Int, cards: [Card], paytableId: String) -> String {
        // For bonus poker variants, check kicker
        if paytableId.contains("double-double") || paytableId.contains("triple-double") {
            let kicker = cards.first { $0.rank.rawValue != quadRank }?.rank.rawValue ?? 0

            if quadRank == 14 { // Aces
                if kicker >= 2 && kicker <= 4 {
                    return "Four Aces + 2-4"
                }
                return "Four Aces"
            } else if quadRank >= 2 && quadRank <= 4 {
                if kicker == 14 || (kicker >= 2 && kicker <= 4) {
                    return "Four 2-4 + A-4"
                }
                return "Four 2-4"
            } else {
                return "Four 5-K"
            }
        } else if paytableId.contains("bonus") || paytableId.contains("double-bonus") {
            if quadRank == 14 {
                return "Four Aces"
            } else if quadRank >= 2 && quadRank <= 4 {
                return "Four 2-4"
            } else {
                return "Four 5-K"
            }
        }

        return "Four of a Kind"
    }

    private func calculatePayout(handName: String?) -> Int {
        guard let handName = handName,
              let paytable = currentPaytable else { return 0 }

        let coinIndex = settings.coinsPerLine - 1
        guard coinIndex >= 0 && coinIndex < 5 else { return 0 }

        for row in paytable.rows {
            if row.handName == handName {
                return row.payouts[coinIndex]
            }
        }

        return 0
    }

    // MARK: - Hand Detection Helpers

    private func isFlush(_ cards: [Card]) -> Bool {
        let firstSuit = cards[0].suit
        return cards.allSatisfy { $0.suit == firstSuit }
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

    private func getCardIndices(cards: [Card], rank: Int) -> [Int] {
        return cards.enumerated().compactMap { index, card in
            card.rank.rawValue == rank ? index : nil
        }
    }
}
