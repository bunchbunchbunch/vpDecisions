import SwiftUI

struct HandAnalyzerView: View {
    @StateObject private var viewModel = AnalyzerViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPaytableId: String = PayTable.jacksOrBetter.id

    let allSuits: [Suit] = [.hearts, .diamonds, .clubs, .spades]
    let allRanks: [Rank] = Rank.allCases

    var body: some View {
        VStack(spacing: 0) {
            // Paytable picker at top
            paytablePickerBar

            Divider()

            // Selected cards display
            selectedCardsBar

            Divider()

            // Card grid
            cardGrid

            // Results table (inline, similar to quiz mode)
            if viewModel.showResults, let hand = viewModel.hand, let result = viewModel.strategyResult {
                Divider()
                resultsTable(hand: hand, result: result)
            }

            // Bottom bar with just error message
            if let error = viewModel.errorMessage {
                bottomErrorBar(error: error)
            }
        }
        .navigationTitle("Hand Analyzer")
    }

    // MARK: - Selected Cards Bar

    private var selectedCardsBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ForEach(0..<5) { index in
                    if index < viewModel.selectedCards.count {
                        let card = viewModel.selectedCards[index]
                        CardView(card: card, isSelected: false)
                            .frame(width: 60, height: 84)
                    } else {
                        // Card back placeholder - match CardView structure exactly
                        VStack(spacing: 4) {
                            Image("1B")
                                .resizable()
                                .aspectRatio(2.5/3.5, contentMode: .fit)
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.2),
                                        radius: 4,
                                        x: 0,
                                        y: 2)

                            // Invisible spacer to match HELD label space in CardView
                            Text("HELD")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .opacity(0)
                        }
                        .frame(width: 60, height: 84)
                    }
                }
            }

            if !viewModel.selectedCards.isEmpty {
                Button("Clear") {
                    viewModel.clear()
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Card Grid

    private var cardGrid: some View {
        ScrollView {
            VStack(spacing: 2) {
                ForEach(allSuits, id: \.self) { suit in
                    HStack(spacing: 2) {
                        ForEach(allRanks, id: \.self) { rank in
                            cardGridCell(rank: rank, suit: suit)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func cardGridCell(rank: Rank, suit: Suit) -> some View {
        let card = Card(rank: rank, suit: suit)
        let isSelected = viewModel.isCardSelected(card)
        let isDisabled = viewModel.selectedCards.count >= 5 && !isSelected

        return Button {
            viewModel.toggleCard(card)
        } label: {
            VStack(spacing: 0) {
                Text(rank.fullName)
                    .font(.system(size: 14, weight: .bold))
                Text(suit.symbol)
                    .font(.system(size: 12))
            }
            .foregroundColor(isDisabled ? .gray : suit.color)
            .frame(width: 28, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? Color.yellow.opacity(0.3) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 2)
            )
        }
        .disabled(isDisabled)
    }

    // MARK: - Paytable Picker Bar

    private var paytablePickerBar: some View {
        VStack(spacing: 8) {
            Text("Game Type")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Picker("Paytable", selection: $selectedPaytableId) {
                ForEach(PayTable.allPayTables, id: \.id) { paytable in
                    Text(paytable.name).tag(paytable.id)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedPaytableId) { newValue in
                if let paytable = PayTable.allPayTables.first(where: { $0.id == newValue }) {
                    viewModel.selectedPaytable = paytable
                }
            }
            .onAppear {
                selectedPaytableId = viewModel.selectedPaytable.id
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Bottom Error Bar

    private func bottomErrorBar(error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(error)
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Results Table (inline, similar to quiz mode)

    private func resultsTable(hand: Hand, result: StrategyResult) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                // Best hold summary
                VStack(spacing: 8) {
                    Text("Best Hold")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    let bestHoldOriginal = hand.canonicalIndicesToOriginal(result.bestHoldIndices)
                    HStack(spacing: 6) {
                        if bestHoldOriginal.isEmpty {
                            Text("Draw all 5 cards")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(bestHoldOriginal, id: \.self) { index in
                                Text(hand.cards[index].displayText)
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(hand.cards[index].suit.color)
                            }
                        }
                    }

                    Text("EV: \(String(format: "%.4f", result.bestEv))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "27ae60"))
                }
                .padding()
                .background(Color(hex: "667eea").opacity(0.1))
                .cornerRadius(12)

                // All options table
                VStack(spacing: 8) {
                    // Table header
                    HStack {
                        Text("Rank")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 40, alignment: .leading)

                        Text("Hold")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("EV")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 60, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)

                    // Table rows
                    VStack(spacing: 4) {
                        ForEach(Array(result.sortedHoldOptions.enumerated()), id: \.offset) { index, option in
                            let optionOriginalIndices = hand.canonicalIndicesToOriginal(option.indices)
                            let optionCards = optionOriginalIndices.map { hand.cards[$0] }
                            let isBest = index == 0

                            HStack(spacing: 8) {
                                // Rank
                                Text("\(index + 1)")
                                    .font(.subheadline)
                                    .fontWeight(isBest ? .bold : .regular)
                                    .frame(width: 40, alignment: .leading)

                                // Hold cards
                                if optionCards.isEmpty {
                                    Text("Draw all")
                                        .font(.subheadline)
                                        .italic()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    HStack(spacing: 4) {
                                        ForEach(optionCards, id: \.id) { card in
                                            Text(card.displayText)
                                                .font(.subheadline)
                                                .foregroundColor(card.suit.color)
                                                .fontWeight(isBest ? .bold : .regular)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                // EV
                                Text(String(format: "%.3f", option.ev))
                                    .font(.subheadline)
                                    .fontWeight(isBest ? .bold : .regular)
                                    .frame(width: 60, alignment: .trailing)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isBest ? Color(hex: "667eea").opacity(0.2) : Color(.systemGray6))
                            .cornerRadius(6)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    NavigationStack {
        HandAnalyzerView()
    }
}
