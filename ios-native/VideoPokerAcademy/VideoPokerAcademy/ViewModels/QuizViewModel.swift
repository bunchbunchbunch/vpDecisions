import Foundation
import SwiftUI

struct QuizHand: Identifiable {
    let id = UUID()
    let hand: Hand
    let strategyResult: StrategyResult
    var currentMultiplier: Double = 1.0
    var uxResult: UltimateXStrategyResult? = nil
    var userHoldIndices: [Int] = []
    var isCorrect: Bool = false
    var category: HandCategory = .mixedDecisions
}

@MainActor
class QuizViewModel: ObservableObject {
    @Published var hands: [QuizHand] = []
    @Published var currentIndex = 0
    @Published var selectedIndices: Set<Int> = []
    @Published var showFeedback = false
    @Published var isCorrect = false
    @Published var isLoading = false
    @Published var loadingProgress = 0
    @Published var isPreparingPaytable = false
    @Published var preparationMessage = "Loading strategy data..."
    @Published var isQuizComplete = false
    @Published var correctCount = 0
    @Published var evLost: Double = 0
    @Published var showSwipeTip = true
    @Published var isComputingHandUX: Bool = false

    private var uxPrefetchTask: Task<Void, Never>?

    // Dealt winner celebration
    @Published var showDealtWinner = false
    @Published var dealtWinnerName: String? = nil

    let quizSize: Int
    let paytableId: String
    let weakSpotsMode: Bool
    let isUltimateXMode: Bool
    let ultimateXPlayCount: UltimateXPlayCount

    private var handStartTime: Date?
    private let audioService = AudioService.shared
    private let hapticService = HapticService.shared

    init(paytableId: String, weakSpotsMode: Bool = false, quizSize: Int = 25,
         isUltimateXMode: Bool = false, ultimateXPlayCount: UltimateXPlayCount = .ten) {
        self.paytableId = paytableId
        self.weakSpotsMode = weakSpotsMode
        self.quizSize = quizSize
        self.isUltimateXMode = isUltimateXMode
        self.ultimateXPlayCount = ultimateXPlayCount
        debugNSLog("📊 QuizViewModel initialized with paytableId: %@, quizSize: %d", paytableId, quizSize)
    }

    var currentHand: QuizHand? {
        guard currentIndex < hands.count else { return nil }
        return hands[currentIndex]
    }

    /// Display string for the current hand's multiplier (UX mode only), e.g. "3×".
    /// Returns nil for a 1× multiplier to suppress the badge on non-bonus hands.
    var currentMultiplierDisplay: String? {
        guard isUltimateXMode, let hand = currentHand, hand.currentMultiplier > 1.0 else { return nil }
        return String(format: "%.0f×", hand.currentMultiplier)
    }

    var progressText: String {
        "\(currentIndex + 1)/\(quizSize)"
    }

    var progressValue: Double {
        Double(currentIndex) / Double(quizSize)
    }

    // MARK: - Quiz Flow

    func loadQuiz() async {
        isLoading = true
        loadingProgress = 0
        hands = []

        // Preload the paytable binary file - auto-downloads if needed
        isPreparingPaytable = true

        let success = await StrategyService.shared.preparePaytable(paytableId: paytableId) { [weak self] status in
            guard let self = self else { return }
            self.preparationMessage = status.message

            switch status {
            case .checking, .downloading:
                self.isPreparingPaytable = true
            case .ready:
                self.isPreparingPaytable = false
            case .failed:
                self.isPreparingPaytable = false
            }
        }

        isPreparingPaytable = false

        // If preparation failed, exit early
        if !success {
            isLoading = false
            return
        }

        var foundHands: [QuizHand] = []
        var attempts = 0
        let maxAttempts = 500

        while foundHands.count < quizSize && attempts < maxAttempts {
            attempts += 1
            let hand = Hand.deal()

            do {
                if let result = try await StrategyService.shared.lookup(hand: hand, paytableId: paytableId) {
                    if foundHands.count == 0 {
                        debugNSLog("🔍 First hand lookup using paytableId: %@, hand: %@", paytableId, hand.canonicalKey)
                    }

                    if isUltimateXMode {
                        // Assign multiplier now; UX result computed lazily
                        let family = PayTable.allPayTables.first(where: { $0.id == paytableId })?.family ?? .jacksOrBetter
                        let possibleMults = UltimateXMultiplierTable.possibleMultipliers(for: ultimateXPlayCount, family: family)
                        var quizHand = QuizHand(hand: hand, strategyResult: result)
                        quizHand.currentMultiplier = Double(possibleMults.randomElement() ?? 1)
                        foundHands.append(quizHand)
                        loadingProgress = foundHands.count
                    } else {
                        let quizHand = QuizHand(hand: hand, strategyResult: result)
                        foundHands.append(quizHand)
                        loadingProgress = foundHands.count
                    }
                }
            } catch {
                debugLog("Error looking up strategy: \(error)")
            }
        }

        hands = foundHands

        // UX mode: compute hand 0 before showing quiz
        if isUltimateXMode && !hands.isEmpty {
            await computeUX(for: 0)
        }

        isLoading = false
        handStartTime = Date()

        // Play card flip sound for first hand
        audioService.play(.cardFlip)

        // Check if first hand is a dealt winner
        await checkDealtWinner()

        // Start background prefetch for hands 1+ (after checkDealtWinner)
        if isUltimateXMode {
            startUXPrefetch(from: 1)
        }
    }

    func toggleCard(_ index: Int) {
        guard !showFeedback else { return }

        audioService.play(.cardSelect)

        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }

    func submit() {
        guard let currentHand = currentHand, !showFeedback else { return }

        // Safety net: if UX result not yet ready (rare race condition), compute it first
        if isUltimateXMode, currentHand.uxResult == nil {
            Task {
                isComputingHandUX = true
                await computeUX(for: currentIndex)
                isComputingHandUX = false
                if hands[currentIndex].uxResult != nil {
                    submit()
                }
                // If uxResult still nil after lookup (e.g. network failure), don't loop —
                // isComputingHandUX is reset to false so user can try again.
            }
            return
        }

        audioService.play(.submit)

        // User selection is in original deal order
        let userHold = Array(selectedIndices).sorted()

        // Convert user's hold from original to canonical order
        let userCanonicalHold = currentHand.hand.originalIndicesToCanonical(userHold)

        // Debug logging for tied ranks
        let userBitmask = Hand.bitmaskFromHoldIndices(userCanonicalHold)
        let tiedBitmasks = currentHand.strategyResult.tiedForBestBitmasks
        let bestEv = currentHand.strategyResult.bestEv
        debugNSLog("🎯 TIED RANKS DEBUG:")
        debugNSLog("  Hand: %@", currentHand.hand.cards.map { "\($0.rank.display)\($0.suit.code)" }.joined(separator: " "))
        debugNSLog("  User hold (original): %@", userHold.description)
        debugNSLog("  User hold (canonical): %@", userCanonicalHold.description)
        debugNSLog("  User bitmask: %d", userBitmask)
        debugNSLog("  Best EV: %.6f", bestEv)
        debugNSLog("  Tied bitmasks: %@", tiedBitmasks.description)
        debugNSLog("  User bitmask in tied? %@", tiedBitmasks.contains(userBitmask) ? "YES" : "NO")

        // Log all options with their EVs to see if there are tiny differences
        let sortedOptions = currentHand.strategyResult.sortedHoldOptions.prefix(5)
        for (i, opt) in sortedOptions.enumerated() {
            let diff = abs(opt.ev - bestEv)
            debugNSLog("  Option %d: bitmask=%d, EV=%.10f, diff=%.10f", i, opt.bitmask, opt.ev, diff)
        }

        // Check if user's hold is tied for best EV (not just exact match with bestHold)
        let correct: Bool
        if isUltimateXMode, let uxResult = currentHand.uxResult {
            correct = uxResult.isAdjustedHoldTiedForBest(userCanonicalHold)
        } else {
            correct = currentHand.strategyResult.isHoldTiedForBest(userCanonicalHold)
        }

        // For category assignment, use the primary best hold
        let canonicalBestHold: [Int]
        if isUltimateXMode, let uxResult = currentHand.uxResult {
            canonicalBestHold = uxResult.adjustedBestHoldIndices
        } else {
            canonicalBestHold = currentHand.strategyResult.bestHoldIndices
        }
        let correctHold = currentHand.hand.canonicalIndicesToOriginal(canonicalBestHold).sorted()

        // Update the current hand
        hands[currentIndex].userHoldIndices = userHold
        hands[currentIndex].isCorrect = correct
        hands[currentIndex].category = HandCategory.categorize(
            hand: currentHand.hand,
            holdIndices: correctHold
        )

        // Calculate EV difference if wrong
        evLost = 0
        if !correct {
            if isUltimateXMode, let uxResult = currentHand.uxResult {
                if let userAdjustedEv = uxResult.adjustedHoldEvs[String(userBitmask)] {
                    evLost = uxResult.adjustedBestEv - userAdjustedEv
                }
            } else {
                if let userEv = currentHand.strategyResult.holdEvs[String(userBitmask)] {
                    evLost = currentHand.strategyResult.bestEv - userEv
                }
            }
        }

        isCorrect = correct
        if correct {
            correctCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.audioService.play(.correct)
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.audioService.play(.incorrect)
                self.hapticService.trigger(.error)
            }
        }

        showFeedback = true

        // Hide swipe tip after first submission
        if showSwipeTip {
            showSwipeTip = false
        }

        // Save attempt to Supabase (async, don't wait)
        Task {
            await saveAttempt()
        }
    }

    func next() {
        audioService.play(.nextHand)

        if currentIndex + 1 >= hands.count {
            // Quiz complete
            audioService.play(.quizComplete)
            isQuizComplete = true
        } else {
            // Clear dealt winner state before moving to next hand
            showDealtWinner = false
            dealtWinnerName = nil

            currentIndex += 1
            selectedIndices = []
            showFeedback = false
            handStartTime = Date()

            // Play card flip sound for new hand
            audioService.play(.cardFlip)

            // Check if new hand is a dealt winner
            Task {
                await checkDealtWinner()
            }
        }
    }

    // MARK: - Dealt Winner Detection

    func checkDealtWinner() async {
        guard let currentHand = currentHand else { return }

        let result = await HandEvaluator.shared.evaluateDealtHand(
            hand: currentHand.hand,
            paytableId: paytableId
        )

        if result.isWinner, let handName = result.handName {
            // Show banner and keep it visible until next hand
            await MainActor.run {
                showDealtWinner = true
                dealtWinnerName = handName

                // Play sound
                audioService.play(.dealtWinner)
            }
        } else {
            // Not a winner, clear state
            await MainActor.run {
                showDealtWinner = false
                dealtWinnerName = nil
            }
        }
    }

    // MARK: - Helpers

    /// Computes and stores the UX strategy result for the hand at `index`.
    /// No-op if uxResult is already set or index is out of bounds.
    private func computeUX(for index: Int) async {
        guard index < hands.count, hands[index].uxResult == nil else { return }
        let quizHand = hands[index]
        if let uxResult = try? await UltimateXStrategyService.shared.lookup(
            hand: quizHand.hand,
            paytableId: paytableId,
            currentMultiplier: quizHand.currentMultiplier,
            playCount: ultimateXPlayCount
        ) {
            hands[index].uxResult = uxResult
        }
    }

    /// Starts a background Task that computes UX results for hands starting at `startIndex`.
    /// Cancels any existing prefetch task first.
    private func startUXPrefetch(from startIndex: Int) {
        uxPrefetchTask?.cancel()
        uxPrefetchTask = Task { [weak self] in
            guard let self else { return }
            for i in startIndex..<self.hands.count {
                guard !Task.isCancelled else { return }
                await self.computeUX(for: i)
            }
        }
    }

    private func saveAttempt() async {
        guard let user = SupabaseService.shared.currentUser,
              let currentHand = currentHand else { return }

        let responseTime: Int?
        if let startTime = handStartTime {
            responseTime = Int(Date().timeIntervalSince(startTime) * 1000)
        } else {
            responseTime = nil
        }

        // User hold is in original order
        let userHold = Array(selectedIndices).sorted()

        // Convert canonical best hold to original order for storage
        let canonicalBestHold: [Int]
        if isUltimateXMode, let uxResult = currentHand.uxResult {
            canonicalBestHold = uxResult.adjustedBestHoldIndices
        } else {
            canonicalBestHold = currentHand.strategyResult.bestHoldIndices
        }
        let correctHold = currentHand.hand.canonicalIndicesToOriginal(canonicalBestHold)

        // Calculate EV difference if wrong
        var evDifference: Double = 0
        if !currentHand.isCorrect {
            // Convert user's hold from original to canonical order for EV lookup
            let userCanonicalHold = currentHand.hand.originalIndicesToCanonical(userHold)
            let userCanonicalBitmask = Hand.bitmaskFromHoldIndices(userCanonicalHold)
            if isUltimateXMode, let uxResult = currentHand.uxResult {
                if let userAdjustedEv = uxResult.adjustedHoldEvs[String(userCanonicalBitmask)] {
                    evDifference = uxResult.adjustedBestEv - userAdjustedEv
                }
            } else {
                if let userEv = currentHand.strategyResult.holdEvs[String(userCanonicalBitmask)] {
                    evDifference = currentHand.strategyResult.bestEv - userEv
                }
            }
        }

        let attempt = HandAttempt(
            userId: user.id,
            handKey: currentHand.hand.canonicalKey,
            handCategory: currentHand.category.rawValue,
            paytableId: paytableId,
            userHold: userHold,
            optimalHold: correctHold,
            isCorrect: currentHand.isCorrect,
            evDifference: evDifference,
            responseTimeMs: responseTime
        )

        // Use SyncService for offline-first saving
        await SyncService.shared.saveAttempt(attempt)
    }

    func reset() {
        hands = []
        currentIndex = 0
        selectedIndices = []
        showFeedback = false
        isCorrect = false
        isLoading = false
        loadingProgress = 0
        isQuizComplete = false
        correctCount = 0
        uxPrefetchTask?.cancel()
        uxPrefetchTask = nil
        isComputingHandUX = false
    }
}
