import SwiftUI

struct HandAnalyzerView: View {
    @StateObject private var viewModel = AnalyzerViewModel()
    @Environment(\.dismiss) private var dismiss

    let allSuits: [Suit] = [.hearts, .diamonds, .clubs, .spades]
    let allRanks: [Rank] = Rank.allCases

    var body: some View {
        VStack(spacing: 0) {
            // Selected cards display
            selectedCardsBar

            Divider()

            // Card grid
            cardGrid

            // Paytable picker and analyze button
            bottomBar
        }
        .navigationTitle("Hand Analyzer")
        .sheet(isPresented: $viewModel.showResults) {
            resultsSheet
        }
    }

    // MARK: - Selected Cards Bar

    private var selectedCardsBar: some View {
        HStack(spacing: 8) {
            ForEach(0..<5) { index in
                if index < viewModel.selectedCards.count {
                    let card = viewModel.selectedCards[index]
                    CardView(card: card, isSelected: false)
                        .frame(width: 50, height: 70)
                } else {
                    // Placeholder
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(width: 50, height: 70)
                        .overlay(
                            Text("?")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        )
                }
            }

            Spacer()

            if !viewModel.selectedCards.isEmpty {
                Button("Clear") {
                    viewModel.clear()
                }
                .font(.caption)
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

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 12) {
            // Paytable picker
            Picker("Paytable", selection: $viewModel.selectedPaytable) {
                ForEach(PayTable.allPayTables, id: \.id) { paytable in
                    Text(paytable.name).tag(paytable)
                }
            }
            .pickerStyle(.menu)

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            // Analyze button
            Button {
                Task {
                    await viewModel.analyze()
                }
            } label: {
                if viewModel.isAnalyzing {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Analyze")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canAnalyze || viewModel.isAnalyzing)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Results Sheet

    private var resultsSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let hand = viewModel.hand, let result = viewModel.strategyResult {
                    // Best hold
                    VStack(spacing: 8) {
                        Text("Best Hold")
                            .font(.headline)

                        HStack(spacing: 8) {
                            if result.bestHoldIndices.isEmpty {
                                Text("Draw all 5 cards")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(result.bestHoldIndices, id: \.self) { index in
                                    CardView(card: hand.cards[index], isSelected: false)
                                        .frame(width: 50, height: 70)
                                }
                            }
                        }

                        Text("EV: \(String(format: "%.4f", result.bestEv))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "27ae60"))
                    }
                    .padding()

                    Divider()

                    // All options
                    Text("All Hold Options")
                        .font(.headline)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(Array(result.sortedHoldOptions.prefix(10).enumerated()), id: \.offset) { i, option in
                                holdOptionRow(hand: hand, option: option, rank: i + 1)
                            }

                            if result.sortedHoldOptions.count > 10 {
                                Text("+ \(result.sortedHoldOptions.count - 10) more options")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.showResults = false
                    }
                }
            }
        }
    }

    private func holdOptionRow(hand: Hand, option: (bitmask: Int, ev: Double, indices: [Int]), rank: Int) -> some View {
        HStack {
            Text("\(rank).")
                .foregroundColor(.secondary)
                .frame(width: 24)

            if option.indices.isEmpty {
                Text("Draw all")
                    .italic()
                    .foregroundColor(.secondary)
            } else {
                ForEach(option.indices, id: \.self) { index in
                    Text(hand.cards[index].displayText)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(hand.cards[index].suit.color)
                }
            }

            Spacer()

            Text(String(format: "%.4f", option.ev))
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(rank == 1 ? Color.green.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        HandAnalyzerView()
    }
}
