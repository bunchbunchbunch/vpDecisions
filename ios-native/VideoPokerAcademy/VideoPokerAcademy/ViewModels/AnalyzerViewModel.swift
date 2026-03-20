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

    // Ultimate X mode
    @Published var isUltimateXMode = false
    @Published var ultimateXPlayCount: UltimateXPlayCount = .ten
    @Published var ultimateXMultiplier: Int = 1
    @Published var ultimateXResult: UltimateXStrategyResult?

    var canAnalyze: Bool {
        selectedCards.count == 5
    }

    var hand: Hand? {
        guard selectedCards.count == 5 else { return nil }
        return Hand(cards: selectedCards)
    }

    /// Whether Ultimate X strategy differs from base strategy
    var ultimateXStrategyDiffers: Bool {
        ultimateXResult?.strategyDiffers ?? false
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
        ultimateXResult = nil
        showResults = false
        errorMessage = nil
    }

    /// Toggle Ultimate X mode
    func toggleUltimateXMode() {
        isUltimateXMode.toggle()
        // Re-analyze if we have cards selected
        if selectedCards.count == 5 {
            Task {
                await analyze()
            }
        }
    }

    /// Update the Ultimate X multiplier and re-analyze
    func setUltimateXMultiplier(_ multiplier: Int) {
        ultimateXMultiplier = max(1, min(multiplier, UltimateXMultiplierTable.maxMultiplier))
        if isUltimateXMode && selectedCards.count == 5 {
            Task {
                await analyze()
            }
        }
    }

    /// Update the Ultimate X play count and re-analyze
    func setUltimateXPlayCount(_ playCount: UltimateXPlayCount) {
        ultimateXPlayCount = playCount
        if isUltimateXMode && selectedCards.count == 5 {
            Task {
                await analyze()
            }
        }
    }

    func analyze() async {
        guard let hand = hand else { return }

        isAnalyzing = true
        errorMessage = nil
        ultimateXResult = nil

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
            // Always get base strategy result
            strategyResult = try await StrategyService.shared.lookup(
                hand: hand,
                paytableId: selectedPaytable.id
            )

            // If Ultimate X mode is enabled, also get adjusted strategy
            if isUltimateXMode {
                ultimateXResult = try await UltimateXStrategyService.shared.lookup(
                    hand: hand,
                    paytableId: selectedPaytable.id,
                    currentMultiplier: ultimateXMultiplier,
                    playCount: ultimateXPlayCount
                )
            }

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

    /// Prepares the current paytable for use - auto-downloads if needed
    private func preparePaytableIfNeeded() async {
        let paytableId = selectedPaytable.id

        isPreparingPaytable = true
        preparationMessage = "Checking strategy data..."

        let success = await StrategyService.shared.preparePaytable(paytableId: paytableId) { [weak self] status in
            guard let self = self else { return }

            self.preparationMessage = status.message

            switch status {
            case .checking, .downloading:
                self.isPreparingPaytable = true
            case .ready:
                self.isPreparingPaytable = false
            case .failed(let error):
                self.isPreparingPaytable = false
                self.errorMessage = error
            }
        }

        // Ensure final state is correct
        isPreparingPaytable = false
        if !success && errorMessage == nil {
            errorMessage = "Failed to load strategy data"
        }
    }
}
