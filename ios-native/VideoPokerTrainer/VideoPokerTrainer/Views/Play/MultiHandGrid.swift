import SwiftUI

/// Grid display of multiple poker hands for multi-line mode
struct MultiHandGrid: View {
    let lineCount: LineCount
    let results: [PlayHandResult]
    let phase: PlayPhase
    let denomination: Double

    private var gridConfig: (columns: Int, rows: Int, handCount: Int) {
        switch lineCount {
        case .one, .oneHundred:
            return (0, 0, 0)  // No grid for 1-line or 100-play (100-play uses tally view)
        case .five:
            return (2, 2, 4)  // 2x2 grid, 4 hands (5th in main area)
        case .ten:
            return (3, 3, 9)  // 3x3 grid, 9 hands (10th in main area)
        }
    }

    private var showAsCardBacks: Bool {
        phase != .result
    }

    var body: some View {
        if lineCount != .one {
            GeometryReader { geometry in
                let config = gridConfig
                let availableWidth = geometry.size.width - 16  // Minimal horizontal padding
                let gridSpacing: CGFloat = config.columns == 3 ? 6 : 8
                let totalSpacing = CGFloat(config.columns - 1) * gridSpacing
                let handWidth = (availableWidth - totalSpacing) / CGFloat(config.columns)

                // Calculate card width based on hand width
                // Hand contains 5 cards with 25% overlap each (except first)
                // So total width = cardWidth + 4 * (cardWidth * 0.75) = cardWidth * 4
                // Plus padding (8px total horizontal)
                let cardWidth = (handWidth - 8) / 4.0

                VStack(spacing: config.columns == 3 ? 6 : 8) {
                    ForEach(0..<config.rows, id: \.self) { row in
                        HStack(spacing: gridSpacing) {
                            ForEach(0..<config.columns, id: \.self) { col in
                                let index = row * config.columns + col
                                if index < config.handCount {
                                    miniHandForIndex(index, cardWidth: cardWidth)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(height: calculateGridHeight())
        }
    }

    private func calculateGridHeight() -> CGFloat {
        let config = gridConfig
        guard config.rows > 0 else { return 0 }

        // Estimate card height based on typical screen width
        // Card aspect ratio is 2.5/3.5
        let estimatedCardWidth: CGFloat = config.columns == 3 ? 28 : 38
        let cardHeight = estimatedCardWidth / (2.5 / 3.5)
        let rowHeight = cardHeight + 16  // Card + padding + win overlay space
        let verticalSpacing: CGFloat = config.columns == 3 ? 6 : 8

        return CGFloat(config.rows) * rowHeight + CGFloat(config.rows - 1) * verticalSpacing + 8
    }

    @ViewBuilder
    private func miniHandForIndex(_ index: Int, cardWidth: CGFloat) -> some View {
        let lineNumber = index + 1  // Lines are 1-indexed

        if showAsCardBacks {
            // Pre-draw: show card backs
            MiniHandView(
                lineNumber: lineNumber,
                cards: nil,
                handName: nil,
                payout: 0,
                winningIndices: [],
                showAsCardBacks: true,
                denomination: denomination,
                cardWidth: cardWidth
            )
        } else if index < results.count {
            // Post-draw: show actual result
            let result = results[index]
            MiniHandView(
                lineNumber: lineNumber,
                cards: result.finalHand,
                handName: result.handName,
                payout: result.payout,
                winningIndices: result.winningIndices,
                showAsCardBacks: false,
                denomination: denomination,
                cardWidth: cardWidth
            )
        } else {
            // Fallback: show card backs
            MiniHandView(
                lineNumber: lineNumber,
                cards: nil,
                handName: nil,
                payout: 0,
                winningIndices: [],
                showAsCardBacks: true,
                denomination: denomination,
                cardWidth: cardWidth
            )
        }
    }
}

#Preview("5 Lines - Card Backs") {
    MultiHandGrid(
        lineCount: .five,
        results: [],
        phase: .dealt,
        denomination: 1.0
    )
    .background(Color(.systemBackground))
}

#Preview("5 Lines - Results") {
    MultiHandGrid(
        lineCount: .five,
        results: [
            PlayHandResult(
                lineNumber: 1,
                finalHand: [
                    Card(rank: .ace, suit: .spades),
                    Card(rank: .ace, suit: .hearts),
                    Card(rank: .king, suit: .diamonds),
                    Card(rank: .queen, suit: .clubs),
                    Card(rank: .jack, suit: .spades)
                ],
                handName: "Jacks or Better",
                payout: 5,
                winningIndices: [0, 1]
            ),
            PlayHandResult(
                lineNumber: 2,
                finalHand: [
                    Card(rank: .two, suit: .spades),
                    Card(rank: .five, suit: .hearts),
                    Card(rank: .seven, suit: .diamonds),
                    Card(rank: .nine, suit: .clubs),
                    Card(rank: .jack, suit: .spades)
                ],
                handName: nil,
                payout: 0,
                winningIndices: []
            ),
            PlayHandResult(
                lineNumber: 3,
                finalHand: [
                    Card(rank: .king, suit: .spades),
                    Card(rank: .king, suit: .hearts),
                    Card(rank: .king, suit: .diamonds),
                    Card(rank: .two, suit: .clubs),
                    Card(rank: .five, suit: .spades)
                ],
                handName: "Three of a Kind",
                payout: 15,
                winningIndices: [0, 1, 2]
            ),
            PlayHandResult(
                lineNumber: 4,
                finalHand: [
                    Card(rank: .three, suit: .hearts),
                    Card(rank: .four, suit: .hearts),
                    Card(rank: .six, suit: .clubs),
                    Card(rank: .eight, suit: .diamonds),
                    Card(rank: .ten, suit: .spades)
                ],
                handName: nil,
                payout: 0,
                winningIndices: []
            )
        ],
        phase: .result,
        denomination: 1.0
    )
    .background(Color(.systemBackground))
}

#Preview("10 Lines - Card Backs") {
    MultiHandGrid(
        lineCount: .ten,
        results: [],
        phase: .dealt,
        denomination: 1.0
    )
    .background(Color(.systemBackground))
}
