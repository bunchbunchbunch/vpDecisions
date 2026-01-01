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
    @Published var isQuizComplete = false
    @Published var correctCount = 0

    // Dealt winner celebration
    @Published var showDealtWinner = false
    @Published var dealtWinnerName: String? = nil

    let quizSize = 25
    let paytableId: String
    let weakSpotsMode: Bool
    let closeDecisionsOnly: Bool

    private var handStartTime: Date?
    private let audioService = AudioService.shared
    private let hapticService = HapticService.shared

    init(paytableId: String, weakSpotsMode: Bool = false, closeDecisionsOnly: Bool = false) {
        self.paytableId = paytableId
        self.weakSpotsMode = weakSpotsMode
        self.closeDecisionsOnly = closeDecisionsOnly
        NSLog("📊 QuizViewModel initialized with paytableId: %@", paytableId)
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
                    // Check if this hand meets our criteria
                    if closeDecisionsOnly {
                        let options = result.sortedHoldOptions
                        if options.count >= 2 {
                            let evGap = options[0].ev - options[1].ev
                            // Only include hands where top 2 options are within 0.1 EV
                            if evGap > 0.1 {
                                continue
                            }
                        }
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

        // Database stores best hold in canonical (sorted) order
        // Convert to original order for comparison
        let canonicalBestHold = currentHand.strategyResult.bestHoldIndices
        let correctHold = currentHand.hand.canonicalIndicesToOriginal(canonicalBestHold).sorted()

        let correct = userHold == correctHold

        // Update the current hand
        hands[currentIndex].userHoldIndices = userHold
        hands[currentIndex].isCorrect = correct
        hands[currentIndex].category = HandCategory.categorize(
            hand: currentHand.hand,
            holdIndices: correctHold
        )

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

        do {
            try await SupabaseService.shared.saveHandAttempt(attempt)
        } catch {
            print("Failed to save attempt: \(error)")
        }
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
