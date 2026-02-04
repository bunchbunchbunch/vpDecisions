import Foundation
import SwiftUI

struct TrainingQuizHand: Identifiable {
    let id = UUID()
    let hand: Hand
    let strategyResult: StrategyResult?
    let practiceHand: TrainingPracticeHand
    var userHoldIndices: [Int] = []
    var isCorrect: Bool = false
}

@MainActor
class TrainingLessonQuizViewModel: ObservableObject {
    @Published var hands: [TrainingQuizHand] = []
    @Published var currentIndex = 0
    @Published var selectedIndices: Set<Int> = []
    @Published var showFeedback = false
    @Published var isCorrect = false
    @Published var evLost: Double = 0
    @Published var isLoading = true
    @Published var isQuizComplete = false
    @Published var correctCount = 0
    @Published var showSwipeTip = true
    @Published var showDealtWinner = false
    @Published var dealtWinnerName: String? = nil
    @Published var isPreparingPaytable = false
    @Published var preparationMessage = "Loading strategy data..."

    let lesson: TrainingLesson
    let paytableId: String

    private let audioService = AudioService.shared
    private let hapticService = HapticService.shared
    private let progressStore = TrainingProgressStore.shared
    private var cachedStrategyResults: [Int: StrategyResult] = [:]

    init(lesson: TrainingLesson, paytableId: String = PayTable.jacksOrBetter96.id) {
        self.lesson = lesson
        self.paytableId = paytableId
    }

    var currentHand: TrainingQuizHand? {
        guard currentIndex < hands.count else { return nil }
        return hands[currentIndex]
    }

    var progressText: String {
        "\(currentIndex + 1)/\(hands.count)"
    }

    var progressValue: Double {
        guard !hands.isEmpty else { return 0 }
        return Double(currentIndex) / Double(hands.count)
    }

    // MARK: - Quiz Flow

    func loadQuiz() async {
        isLoading = true
        hands = []

        // Prepare the 9/6 JoB paytable
        isPreparingPaytable = true
        let success = await StrategyService.shared.preparePaytable(paytableId: paytableId) { [weak self] status in
            guard let self = self else { return }
            self.preparationMessage = status.message
            switch status {
            case .checking, .downloading:
                self.isPreparingPaytable = true
            case .ready, .failed:
                self.isPreparingPaytable = false
            }
        }
        isPreparingPaytable = false

        if !success {
            // Fall back: create hands without strategy results
            hands = createHandsWithoutStrategy()
            isLoading = false
            return
        }

        // Create hands with strategy lookup (randomized each time)
        cachedStrategyResults = [:]
        var quizHands: [TrainingQuizHand] = []
        for practiceHand in lesson.practiceHands {
            let randomized = randomizeHand(practiceHand)
            guard let cards = randomized.getCards(), cards.count == 5 else { continue }
            let hand = Hand(cards: cards)

            var strategyResult: StrategyResult? = nil
            do {
                strategyResult = try await StrategyService.shared.lookup(hand: hand, paytableId: paytableId)
            } catch {
                NSLog("⚠️ Strategy lookup failed for hand %d: %@", practiceHand.number, error.localizedDescription)
            }

            if let result = strategyResult {
                cachedStrategyResults[practiceHand.number] = result
            }

            quizHands.append(TrainingQuizHand(
                hand: hand,
                strategyResult: strategyResult,
                practiceHand: randomized
            ))
        }

        hands = quizHands
        isLoading = false

        audioService.play(.cardFlip)
        await checkDealtWinner()
    }

    private func createHandsWithoutStrategy() -> [TrainingQuizHand] {
        lesson.practiceHands.compactMap { practiceHand in
            let randomized = randomizeHand(practiceHand)
            guard let cards = randomized.getCards(), cards.count == 5 else { return nil }
            return TrainingQuizHand(
                hand: Hand(cards: cards),
                strategyResult: nil,
                practiceHand: randomized
            )
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
        audioService.play(.submit)

        let userHold = Array(selectedIndices).sorted()

        if let result = currentHand.strategyResult {
            // Grade using strategy service (source of truth)
            let userCanonicalHold = currentHand.hand.originalIndicesToCanonical(userHold)
            let correct = result.isHoldTiedForBest(userCanonicalHold)

            hands[currentIndex].userHoldIndices = userHold
            hands[currentIndex].isCorrect = correct

            // Calculate EV lost
            evLost = 0
            if !correct {
                let userBitmask = Hand.bitmaskFromHoldIndices(userCanonicalHold)
                if let userEv = result.holdEvs[String(userBitmask)] {
                    evLost = result.bestEv - userEv
                }
            }

            isCorrect = correct
        } else {
            // Fallback: grade using holdCards from lesson data
            let correct = userHold == currentHand.practiceHand.holdIndices
            hands[currentIndex].userHoldIndices = userHold
            hands[currentIndex].isCorrect = correct
            evLost = 0
            isCorrect = correct
        }

        if isCorrect {
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
        if showSwipeTip { showSwipeTip = false }
    }

    func next() {
        audioService.play(.nextHand)

        if currentIndex + 1 >= hands.count {
            // Quiz complete
            audioService.play(.quizComplete)
            isQuizComplete = true

            // Record progress
            progressStore.recordAttempt(
                lessonNumber: lesson.number,
                score: correctCount,
                totalHands: hands.count
            )
        } else {
            showDealtWinner = false
            dealtWinnerName = nil
            currentIndex += 1
            selectedIndices = []
            showFeedback = false
            audioService.play(.cardFlip)

            Task {
                await checkDealtWinner()
            }
        }
    }

    func reset() {
        currentIndex = 0
        selectedIndices = []
        showFeedback = false
        isCorrect = false
        evLost = 0
        isQuizComplete = false
        correctCount = 0
        showSwipeTip = true
        showDealtWinner = false
        dealtWinnerName = nil

        // Re-randomize cards with fresh suit shuffles and position scrambles
        var quizHands: [TrainingQuizHand] = []
        for practiceHand in lesson.practiceHands {
            let randomized = randomizeHand(practiceHand)
            guard let cards = randomized.getCards(), cards.count == 5 else { continue }
            let hand = Hand(cards: cards)
            let strategyResult = cachedStrategyResults[practiceHand.number]

            quizHands.append(TrainingQuizHand(
                hand: hand,
                strategyResult: strategyResult,
                practiceHand: randomized
            ))
        }

        hands = quizHands
        audioService.play(.cardFlip)

        Task {
            await checkDealtWinner()
        }
    }

    // MARK: - Hand Randomization

    private static let allSuits: [Character] = ["h", "d", "c", "s"]

    private func randomizeHand(_ practiceHand: TrainingPracticeHand) -> TrainingPracticeHand {
        var cards = practiceHand.cards
        var holdCards = practiceHand.holdCards

        // Suit shuffling: 10 random suit swaps
        for _ in 0..<10 {
            let i = Int.random(in: 0..<4)
            var j = Int.random(in: 0..<4)
            while j == i { j = Int.random(in: 0..<4) }
            let suitA = Self.allSuits[i]
            let suitB = Self.allSuits[j]

            cards = Self.swapSuits(in: cards, suitA: suitA, suitB: suitB)
            holdCards = Self.swapSuits(in: holdCards, suitA: suitA, suitB: suitB)
        }

        // Shuffle card positions
        cards.shuffle()

        return TrainingPracticeHand(
            number: practiceHand.number,
            cards: cards,
            holdCards: holdCards,
            explanation: practiceHand.explanation
        )
    }

    private static func swapSuits(in cardStrings: [String], suitA: Character, suitB: Character) -> [String] {
        cardStrings.map { card in
            guard let suit = card.last else { return card }
            if suit == suitA {
                return String(card.dropLast()) + String(suitB)
            } else if suit == suitB {
                return String(card.dropLast()) + String(suitA)
            }
            return card
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
            showDealtWinner = true
            dealtWinnerName = handName
            audioService.play(.dealtWinner)
        } else {
            showDealtWinner = false
            dealtWinnerName = nil
        }
    }
}
