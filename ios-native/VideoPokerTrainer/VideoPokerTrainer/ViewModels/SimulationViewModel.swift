import Foundation
import SwiftUI

@MainActor
class SimulationViewModel: ObservableObject {
    // MARK: - Published State

    @Published var config = SimulationConfig.default
    @Published var phase: SimulationPhase = .configuration
    @Published var results: SimulationResults?
    @Published var progress = SimulationProgress()
    @Published var isRunning = false
    @Published var errorMessage: String?

    // Configuration selections
    @Published var selectedPaytableId: String = PayTable.jacksOrBetter96.id
    @Published var selectedDenomination: BetDenomination = .quarter
    @Published var selectedLinesPerHand: Int = 10
    @Published var selectedHandsPerSim: Int = 1000
    @Published var selectedNumSims: Int = 100

    // Cancellation support
    private var simulationTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var currentPaytable: PayTable? {
        PayTable.allPayTables.first { $0.id == selectedPaytableId }
    }

    var configSummary: String {
        let totalHands = selectedHandsPerSim * selectedNumSims * selectedLinesPerHand
        return formatNumber(totalHands) + " total hands"
    }

    var totalWageredSummary: String {
        let betPerHand = Double(5 * selectedLinesPerHand) * selectedDenomination.rawValue
        let total = betPerHand * Double(selectedHandsPerSim * selectedNumSims)
        return formatCurrency(total) + " total wagered"
    }

    // MARK: - Actions

    func startSimulation() async {
        // Build config from selections
        config = SimulationConfig(
            paytableId: selectedPaytableId,
            denomination: selectedDenomination,
            linesPerHand: selectedLinesPerHand,
            handsPerSimulation: selectedHandsPerSim,
            numberOfSimulations: selectedNumSims
        )

        // Initialize state
        phase = .running
        isRunning = true
        errorMessage = nil
        results = SimulationResults(config: config, runs: [], isComplete: false, isCancelled: false)

        // Initialize progress
        progress = SimulationProgress(
            currentRun: 0,
            totalRuns: config.numberOfSimulations,
            currentHand: 0,
            handsPerRun: config.handsPerSimulation,
            startTime: Date()
        )

        // Preload strategy data
        let prepared = await StrategyService.shared.preparePaytable(paytableId: config.paytableId)
        if !prepared {
            errorMessage = "Failed to load strategy data"
            isRunning = false
            phase = .configuration
            return
        }

        // Run simulation in background
        let paytableId = config.paytableId
        let denomination = config.denomination
        let linesPerHand = config.linesPerHand
        let handsPerSim = config.handsPerSimulation
        let numSims = config.numberOfSimulations

        simulationTask = Task.detached(priority: .userInitiated) { [weak self] in
            for runNum in 0..<numSims {
                if Task.isCancelled { break }

                let run = await self?.runSingleSimulation(
                    runNumber: runNum,
                    paytableId: paytableId,
                    denomination: denomination,
                    linesPerHand: linesPerHand,
                    handsPerSimulation: handsPerSim
                )

                if let run = run {
                    await MainActor.run { [weak self] in
                        self?.results?.runs.append(run)
                        self?.progress.currentRun = runNum + 1
                    }
                }
            }

            await MainActor.run { [weak self] in
                self?.results?.isComplete = !Task.isCancelled
                self?.results?.isCancelled = Task.isCancelled
                self?.phase = .results
                self?.isRunning = false
            }
        }
    }

    func cancelSimulation() {
        simulationTask?.cancel()
        simulationTask = nil
        results?.isCancelled = true
        isRunning = false
        phase = .results
    }

    func reset() {
        phase = .configuration
        results = nil
        progress = SimulationProgress()
        isRunning = false
        errorMessage = nil
        simulationTask?.cancel()
        simulationTask = nil
    }

    func runAgain() async {
        // Reset state but don't change phase to configuration
        // since we're going directly to running
        results = nil
        progress = SimulationProgress()
        errorMessage = nil
        simulationTask?.cancel()
        simulationTask = nil

        await startSimulation()
    }

    // MARK: - Private Simulation Logic

    private func runSingleSimulation(
        runNumber: Int,
        paytableId: String,
        denomination: BetDenomination,
        linesPerHand: Int,
        handsPerSimulation: Int
    ) async -> SimulationRun {
        var run = SimulationRun(runNumber: runNumber)
        var bankroll: Double = 0

        let betPerHand = Double(5 * linesPerHand) * denomination.rawValue

        for handNum in 0..<handsPerSimulation {
            // Check cancellation periodically
            if handNum % 50 == 0 && Task.isCancelled { break }

            // Deal a fresh hand
            var deck = Card.shuffledDeck()
            let dealtCards = Array(deck.prefix(5))
            deck = Array(deck.dropFirst(5))

            // Get optimal hold
            let hand = Hand(cards: dealtCards)
            let optimalHold = await getOptimalHold(hand: hand, paytableId: paytableId)

            // Deduct bet
            bankroll -= betPerHand
            run.totalBet += betPerHand

            // Track hand
            run.handsPlayed += 1

            // Play all lines
            var lineWinnings: Double = 0
            for _ in 0..<linesPerHand {
                // Fresh deck for each line (minus dealt cards)
                var lineDeck = Card.shuffledDeck()
                lineDeck.removeAll { card in
                    dealtCards.contains { $0.rank == card.rank && $0.suit == card.suit }
                }
                lineDeck.shuffle()

                let finalHand = performDraw(
                    dealtCards: dealtCards,
                    heldIndices: optimalHold,
                    deck: lineDeck
                )

                let result = evaluateHand(finalHand, paytableId: paytableId)
                let payoutCredits = result.payout
                let payoutDollars = Double(payoutCredits) * denomination.rawValue

                lineWinnings += payoutDollars

                // Track W2G taxable wins (over $2000)
                if payoutDollars >= 2000 {
                    run.winsOver2000 += 1
                }

                if let handName = result.handName {
                    run.winsByHandType[handName, default: 0] += 1
                }
            }

            // Update bankroll
            bankroll += lineWinnings
            run.totalWon += lineWinnings

            // Track biggest win/loss for this hand
            let netThisHand = lineWinnings - betPerHand
            if netThisHand > run.biggestWin {
                run.biggestWin = netThisHand
            }
            if netThisHand < run.biggestLoss {
                run.biggestLoss = netThisHand
            }

            // Sample bankroll history (every 10 hands to reduce memory)
            if handNum % 10 == 0 || handNum == handsPerSimulation - 1 {
                run.bankrollHistory.append(bankroll)
            }

            // Update progress every 100 hands
            if handNum % 100 == 0 {
                await MainActor.run { [weak self] in
                    self?.progress.currentHand = handNum
                }
            }
        }

        return run
    }

    private func getOptimalHold(hand: Hand, paytableId: String) async -> Set<Int> {
        do {
            if let result = try await StrategyService.shared.lookup(hand: hand, paytableId: paytableId) {
                let canonicalIndices = result.bestHoldIndices
                return Set(hand.canonicalIndicesToOriginal(canonicalIndices))
            }
        } catch {
            // If lookup fails, hold nothing (worst case)
        }
        return []
    }

    private func performDraw(dealtCards: [Card], heldIndices: Set<Int>, deck: [Card]) -> [Card] {
        var finalHand = dealtCards
        var drawIndex = 0

        for i in 0..<5 {
            if !heldIndices.contains(i) {
                guard drawIndex < deck.count else { break }
                finalHand[i] = deck[drawIndex]
                drawIndex += 1
            }
        }

        return finalHand
    }

    // MARK: - Hand Evaluation

    private func evaluateHand(_ cards: [Card], paytableId: String) -> SingleHandResult {
        var rankCounts: [Int: Int] = [:]
        for card in cards {
            rankCounts[card.rank.rawValue, default: 0] += 1
        }

        let pairs = rankCounts.filter { $0.value == 2 }.map { $0.key }.sorted(by: >)
        let trips = rankCounts.filter { $0.value == 3 }.map { $0.key }
        let quads = rankCounts.filter { $0.value == 4 }.map { $0.key }
        let numDeuces = rankCounts[2, default: 0]

        var handName: String?

        if paytableId.contains("deuces-wild") {
            handName = evaluateDeucesWildHand(cards: cards, rankCounts: rankCounts, numDeuces: numDeuces)
        } else {
            handName = evaluateStandardHand(cards: cards, pairs: pairs, trips: trips, quads: quads, paytableId: paytableId)
        }

        let payout = calculatePayout(handName: handName, paytableId: paytableId)
        return SingleHandResult(handName: handName, payout: payout)
    }

    private func evaluateStandardHand(cards: [Card], pairs: [Int], trips: [Int], quads: [Int], paytableId: String) -> String? {
        // Royal Flush
        if isRoyalFlush(cards) {
            return "Royal Flush"
        }

        // Straight Flush
        if isStraightFlush(cards) {
            return "Straight Flush"
        }

        // Four of a Kind
        if let quadRank = quads.first {
            return getFourOfAKindName(quadRank: quadRank, cards: cards, paytableId: paytableId)
        }

        // Full House
        if !trips.isEmpty && !pairs.isEmpty {
            return "Full House"
        }

        // Flush
        if isFlush(cards) {
            return "Flush"
        }

        // Straight
        if isStraight(cards) {
            return "Straight"
        }

        // Three of a Kind
        if !trips.isEmpty {
            return "Three of a Kind"
        }

        // Two Pair
        if pairs.count >= 2 {
            return "Two Pair"
        }

        // High pair (Jacks or Better / Tens or Better)
        let minPairRank = paytableId.contains("tens-or-better") ? 10 : 11
        for pairRank in pairs {
            if pairRank >= minPairRank {
                return paytableId.contains("tens-or-better") ? "Tens or Better" : "Jacks or Better"
            }
        }

        return nil
    }

    private func evaluateDeucesWildHand(cards: [Card], rankCounts: [Int: Int], numDeuces: Int) -> String? {
        // Natural Royal (no deuces)
        if numDeuces == 0 && isRoyalFlush(cards) {
            return "Natural Royal"
        }

        // Four Deuces
        if numDeuces == 4 {
            return "Four Deuces"
        }

        // Wild Royal
        if numDeuces > 0 && isWildRoyalFlush(cards, numDeuces: numDeuces) {
            return "Wild Royal"
        }

        // Five of a Kind
        let maxCount = rankCounts.filter { $0.key != 2 }.map { $0.value }.max() ?? 0
        if maxCount + numDeuces >= 5 {
            return "Five of a Kind"
        }

        // Straight Flush
        if isStraightFlush(cards) || canMakeStraightFlushWithWilds(cards, numDeuces: numDeuces) {
            return "Straight Flush"
        }

        // Four of a Kind
        if maxCount + numDeuces >= 4 {
            return "Four of a Kind"
        }

        // Full House
        if canMakeFullHouseWithWilds(rankCounts: rankCounts, numDeuces: numDeuces) {
            return "Full House"
        }

        // Flush
        if isFlush(cards) {
            return "Flush"
        }

        // Straight
        if isStraight(cards) || canMakeStraightWithWilds(cards, numDeuces: numDeuces) {
            return "Straight"
        }

        // Three of a Kind
        if maxCount + numDeuces >= 3 {
            return "Three of a Kind"
        }

        return nil
    }

    private func getFourOfAKindName(quadRank: Int, cards: [Card], paytableId: String) -> String {
        if paytableId.contains("double-double") || paytableId.contains("triple-double") {
            let kicker = cards.first { $0.rank.rawValue != quadRank }?.rank.rawValue ?? 0

            if quadRank == 14 {
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

    private func calculatePayout(handName: String?, paytableId: String) -> Int {
        guard let handName = handName,
              let paytable = PayTable.allPayTables.first(where: { $0.id == paytableId }) else {
            return 0
        }

        // Always 5 coins per line (max bet)
        let coinIndex = 4

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

        var isConsecutive = true
        for i in 0..<4 {
            if ranks[i+1] != ranks[i] + 1 {
                isConsecutive = false
                break
            }
        }
        if isConsecutive { return true }

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

        if nonDeuceRanks.isEmpty { return true }

        let startRanks = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

        for low in startRanks {
            let high = low + 4

            var allFit = true
            for rank in nonDeuceRanks {
                let effectiveRank = (low == 1 && rank == 14) ? 1 : rank
                if effectiveRank < low || effectiveRank > high {
                    allFit = false
                    break
                }
            }

            if allFit {
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

    // MARK: - Formatting Helpers

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}
