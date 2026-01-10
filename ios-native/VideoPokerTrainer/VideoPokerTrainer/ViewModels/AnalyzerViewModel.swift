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

    /// Prepares the current paytable for use (decompresses if needed)
    private func preparePaytableIfNeeded() async {
        let paytableId = selectedPaytable.id
        let paytableName = selectedPaytable.name

        // Check if we need to load
        let needsLoading = await StrategyService.shared.paytableNeedsLoading(paytableId: paytableId)
        if !needsLoading {
            return  // Already loaded or not bundled/downloadable
        }

        // Show loading state with detailed status updates
        isPreparingPaytable = true

        let success = await StrategyService.shared.preparePaytable(paytableId: paytableId) { [weak self] status in
            guard let self = self else { return }
            switch status {
            case .checking:
                self.preparationMessage = "Checking \(paytableName)..."
            case .downloading:
                self.preparationMessage = "Downloading \(paytableName)..."
            case .importing:
                self.preparationMessage = "Importing \(paytableName)..."
            case .ready:
                self.preparationMessage = "Ready"
            case .failed(let message):
                self.preparationMessage = "Failed: \(message)"
            }
        }

        // Hide loading state (keep showing if failed)
        if success {
            isPreparingPaytable = false
        }
    }
}
