import Testing
import Foundation
@testable import VideoPokerAcademy

@Suite("Ultimate X Quiz Tests")
@MainActor
struct UltimateXQuizTests {

    @Test("QuizHand defaults: currentMultiplier = 1.0, uxResult = nil")
    func testQuizHandDefaults() async throws {
        let hand = Hand.deal()
        let paytableId = PayTable.jacksOrBetter96.id
        guard let result = try await StrategyService.shared.lookup(hand: hand, paytableId: paytableId) else {
            return
        }
        let quizHand = QuizHand(hand: hand, strategyResult: result)
        #expect(quizHand.currentMultiplier == 1.0)
        #expect(quizHand.uxResult == nil)
    }

    @Test("QuizViewModel initializes with UX params")
    func testQuizViewModelUXInit() {
        let vm = QuizViewModel(
            paytableId: PayTable.jacksOrBetter96.id,
            isUltimateXMode: true,
            ultimateXPlayCount: UltimateXPlayCount.ten
        )
        #expect(vm.isUltimateXMode == true)
        #expect(vm.ultimateXPlayCount == UltimateXPlayCount.ten)
    }

    @Test("QuizViewModel initializes with standard defaults")
    func testQuizViewModelStandardInit() {
        let vm = QuizViewModel(paytableId: PayTable.jacksOrBetter96.id)
        #expect(vm.isUltimateXMode == false)
        #expect(vm.ultimateXPlayCount == UltimateXPlayCount.ten)
    }

    @Test("loadQuiz sets isLoading to false without computing all UX upfront")
    func testLoadQuizCompletesWithoutAllUX() async throws {
        // In UX mode, loadQuiz should finish with only hand 0 having uxResult set.
        // Hands 1+ are computed in background — so after loadQuiz returns,
        // at least hand 0 must have a uxResult, and isLoading must be false.
        let vm = QuizViewModel(
            paytableId: PayTable.jacksOrBetter96.id,
            quizSize: 3,
            isUltimateXMode: true,
            ultimateXPlayCount: .ten
        )
        await vm.loadQuiz()
        #expect(!vm.isLoading)
        #expect(!vm.hands.isEmpty)
        #expect(vm.hands[0].uxResult != nil)
    }

    @Test("isComputingHandUX starts as false")
    func testIsComputingHandUXDefault() {
        let vm = QuizViewModel(
            paytableId: PayTable.jacksOrBetter96.id,
            isUltimateXMode: true,
            ultimateXPlayCount: .ten
        )
        #expect(!vm.isComputingHandUX)
    }
}
