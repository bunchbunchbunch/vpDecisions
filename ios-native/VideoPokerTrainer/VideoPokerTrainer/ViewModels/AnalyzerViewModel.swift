import Foundation
import SwiftUI

@MainActor
class AnalyzerViewModel: ObservableObject {
    @Published var selectedCards: [Card] = []
    @Published var selectedPaytable = PayTable.jacksOrBetter
    @Published var strategyResult: StrategyResult?
    @Published var isAnalyzing = false
    @Published var showResults = false
    @Published var errorMessage: String?

    var canAnalyze: Bool {
        selectedCards.count == 5
    }

    var hand: Hand? {
        guard selectedCards.count == 5 else { return nil }
        return Hand(cards: selectedCards)
    }

    func toggleCard(_ card: Card) {
        if let index = selectedCards.firstIndex(where: { $0.rank == card.rank && $0.suit == card.suit }) {
            selectedCards.remove(at: index)
        } else if selectedCards.count < 5 {
            selectedCards.append(card)
        }
    }

    func isCardSelected(_ card: Card) -> Bool {
        selectedCards.contains { $0.rank == card.rank && $0.suit == card.suit }
    }

    func clear() {
        selectedCards = []
        strategyResult = nil
        showResults = false
        errorMessage = nil
    }

    func analyze() async {
        guard let hand = hand else { return }

        isAnalyzing = true
        errorMessage = nil

        do {
            strategyResult = try await StrategyService.shared.lookup(
                hand: hand,
                paytableId: selectedPaytable.id
            )

            if strategyResult != nil {
                showResults = true
            } else {
                errorMessage = "No strategy found for this hand"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalyzing = false
    }
}
