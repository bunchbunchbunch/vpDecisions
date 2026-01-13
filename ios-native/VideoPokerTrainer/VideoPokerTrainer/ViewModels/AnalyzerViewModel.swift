import Foundation
import SwiftUI

@MainActor
class AnalyzerViewModel: ObservableObject {
    @Published var selectedCards: [Card] = []
    @Published var selectedPaytable = PayTable.jacksOrBetter96
    @Published var strategyResult: StrategyResult?
    @Published var isAnalyzing = false
    @Published var showResults = false
    @Published var errorMessage: String?

    // Loading state for paytable preparation
    @Published var isPreparingPaytable = false
    @Published var preparationMessage = "Loading strategy data..."

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

            // Auto-analyze when 5 cards are selected
            if selectedCards.count == 5 {
                Task {
                    await analyze()
                }
            }
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

        // Check if offline and game not available
        let isOnline = await MainActor.run { NetworkMonitor.shared.isOnline }
        if !isOnline {
            let hasOfflineData = await StrategyService.shared.hasOfflineData(paytableId: selectedPaytable.id)
            if !hasOfflineData {
                errorMessage = "This game isn't available offline. Please go online or select a downloaded game."
                isAnalyzing = false
                return
            }
        }

        // Prepare paytable if needed (download/decompress)
        await preparePaytableIfNeeded()

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

    /// Prepares the current paytable for use (preloads binary file)
    private func preparePaytableIfNeeded() async {
        let paytableId = selectedPaytable.id

        // Check if strategy data is available
        let hasData = await StrategyService.shared.hasOfflineData(paytableId: paytableId)
        if !hasData {
            isPreparingPaytable = true
            preparationMessage = "Strategy not available for \(selectedPaytable.name)"
            return
        }

        // Preload the binary file for faster lookups
        _ = await StrategyService.shared.preparePaytable(paytableId: paytableId)
    }
}
