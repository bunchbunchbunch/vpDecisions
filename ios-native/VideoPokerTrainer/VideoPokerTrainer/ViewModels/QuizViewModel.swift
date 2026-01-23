import Foundation
import SwiftUI

struct QuizHand: Identifiable {
    let id = UUID()
    let hand: Hand
    let strategyResult: StrategyResult
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

    // Dealt winner celebration
    @Published var showDealtWinner = false
    @Published var dealtWinnerName: String? = nil

    let quizSize: Int
    let paytableId: String
    let weakSpotsMode: Bool

    private var handStartTime: Date?
    private let audioService = AudioService.shared
    private let hapticService = HapticService.shared

    init(paytableId: String, weakSpotsMode: Bool = false, quizSize: Int = 25) {
        self.paytableId = paytableId
        self.weakSpotsMode = weakSpotsMode
        self.quizSize = quizSize
        NSLog("📊 QuizViewModel initialized with paytableId: %@, quizSize: %d", paytableId, quizSize)
    }

    var currentHand: QuizHand? {
        guard currentIndex < hands.count else { return nil }
        return hands[currentIndex]
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

        // Preload the paytable binary file
        _ = await StrategyService.shared.preparePaytable(paytableId: paytableId)

        var foundHands: [QuizHand] = []
        var attempts = 0
        let maxAttempts = 500

        while foundHands.count < quizSize && attempts < maxAttempts {
            attempts += 1
            let hand = Hand.deal()

            do {
                if let result = try await StrategyService.shared.lookup(hand: hand, paytableId: paytableId) {
                    if foundHands.count == 0 {
                        NSLog("🔍 First hand lookup using paytableId: %@, hand: %@", paytableId, hand.canonicalKey)
                    }

                    let quizHand = QuizHand(hand: hand, strategyResult: result)
                    foundHands.append(quizHand)
                    loadingProgress = foundHands.count
                }
            } catch {
                print("Error looking up strategy: \(error)")
            }
        }

        hands = foundHands
        isLoading = false
        handStartTime = Date()

        // Play card flip sound for first hand
        audioService.play(.cardFlip)

        // Check if first hand is a dealt winner
        await checkDealtWinner()
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

        audioService.play(.submit)

        // User selection is in original deal order
        let userHold = Array(selectedIndices).sorted()

        // Convert user's hold from original to canonical order
        let userCanonicalHold = currentHand.hand.originalIndicesToCanonical(userHold)

        // Debug logging for tied ranks
        let userBitmask = Hand.bitmaskFromHoldIndices(userCanonicalHold)
        let tiedBitmasks = currentHand.strategyResult.tiedForBestBitmasks
        let bestEv = currentHand.strategyResult.bestEv
        NSLog("🎯 TIED RANKS DEBUG:")
        NSLog("  Hand: %@", currentHand.hand.cards.map { "\($0.rank.display)\($0.suit.code)" }.joined(separator: " "))
        NSLog("  User hold (original): %@", userHold.description)
        NSLog("  User hold (canonical): %@", userCanonicalHold.description)
        NSLog("  User bitmask: %d", userBitmask)
        NSLog("  Best EV: %.6f", bestEv)
        NSLog("  Tied bitmasks: %@", tiedBitmasks.description)
        NSLog("  User bitmask in tied? %@", tiedBitmasks.contains(userBitmask) ? "YES" : "NO")

        // Log all options with their EVs to see if there are tiny differences
        let sortedOptions = currentHand.strategyResult.sortedHoldOptions.prefix(5)
        for (i, opt) in sortedOptions.enumerated() {
            let diff = abs(opt.ev - bestEv)
            NSLog("  Option %d: bitmask=%d, EV=%.10f, diff=%.10f", i, opt.bitmask, opt.ev, diff)
        }

        // Check if user's hold is tied for best EV (not just exact match with bestHold)
        let correct = currentHand.strategyResult.isHoldTiedForBest(userCanonicalHold)

        // For category assignment, use the primary best hold
        let canonicalBestHold = currentHand.strategyResult.bestHoldIndices
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
            let userCanonicalHold = currentHand.hand.originalIndicesToCanonical(userHold)
            let userCanonicalBitmask = Hand.bitmaskFromHoldIndices(userCanonicalHold)
            if let userEv = currentHand.strategyResult.holdEvs[String(userCanonicalBitmask)] {
                evLost = currentHand.strategyResult.bestEv - userEv
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
        let canonicalBestHold = currentHand.strategyResult.bestHoldIndices
        let correctHold = currentHand.hand.canonicalIndicesToOriginal(canonicalBestHold)

        // Calculate EV difference if wrong
        var evDifference: Double = 0
        if !currentHand.isCorrect {
            // Convert user's hold from original to canonical order for EV lookup
            let userCanonicalHold = currentHand.hand.originalIndicesToCanonical(userHold)
            let userCanonicalBitmask = Hand.bitmaskFromHoldIndices(userCanonicalHold)
            if let userEv = currentHand.strategyResult.holdEvs[String(userCanonicalBitmask)] {
                evDifference = currentHand.strategyResult.bestEv - userEv
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
    }
}
