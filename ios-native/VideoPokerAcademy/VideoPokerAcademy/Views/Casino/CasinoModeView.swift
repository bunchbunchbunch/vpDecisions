import SwiftUI

struct CasinoModeView: View {

    // MARK: - State

    @State private var viewModel: CasinoModeViewModel
    @State private var savedBrightness: CGFloat = UIScreen.main.brightness
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Init

    init(paytableId: String) {
        _viewModel = State(initialValue: CasinoModeViewModel(paytableId: paytableId))
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Compact status bar at top
                statusBar
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                Divider().background(Color.white.opacity(0.15))

                // Main content area
                if let hand = viewModel.lastHand,
                   let result = viewModel.lastStrategyResult,
                   viewModel.listeningState == .idle {
                    resultsTable(hand: hand, result: result)
                } else {
                    centeredStateIndicator
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onTapGesture {
            viewModel.toggleListening()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Text("Voice Mode")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("BETA")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
            }
        }
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.endSession()
            UIScreen.main.brightness = savedBrightness
        }
        .onChange(of: viewModel.isSessionActive) { _, isActive in
            if isActive {
                savedBrightness = UIScreen.main.brightness
                UIScreen.main.brightness = 0.1
            } else {
                UIScreen.main.brightness = savedBrightness
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                viewModel.endSession()
            } else if newPhase == .active {
                if !viewModel.isSessionActive {
                    viewModel.startSession()
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 12) {
            switch viewModel.listeningState {
            case .idle:
                Image(systemName: "mic.slash")
                    .foregroundStyle(.gray)
                Text(viewModel.lastHand == nil ? "Tap screen or press volume button" : "Tap to speak next hand")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .listening:
                Image(systemName: "mic.fill")
                    .foregroundStyle(.green)
                    .symbolEffect(.pulse)
                if !viewModel.currentTranscript.isEmpty {
                    Text(viewModel.currentTranscript)
                        .font(.caption)
                        .foregroundStyle(.green)
                        .lineLimit(2)
                } else {
                    Text("Listening...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .processing:
                ProgressView()
                    .tint(.white)
                    .scaleEffect(0.75)
                Text("Looking up strategy...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .error(let message):
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.yellow)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.yellow)
                    .lineLimit(2)
            }
            Spacer()
        }
    }

    // MARK: - Centered State Indicator (when no results yet)

    @ViewBuilder
    private var centeredStateIndicator: some View {
        switch viewModel.listeningState {
        case .idle:
            VStack(spacing: 12) {
                Image(systemName: "mic.slash")
                    .font(.system(size: 56))
                    .foregroundStyle(.gray)
                Text("Tap screen or press\nvolume button to start")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        case .listening:
            VStack(spacing: 16) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
                    .symbolEffect(.pulse)
                Text("Listening...")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                if !viewModel.currentTranscript.isEmpty {
                    Text(viewModel.currentTranscript)
                        .font(.body)
                        .foregroundStyle(.green.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
        case .processing:
            VStack(spacing: 16) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
                Text("Looking up strategy...")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        case .error(let message):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 56))
                    .foregroundStyle(.yellow)
                Text(message)
                    .font(.body)
                    .foregroundStyle(.yellow.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Text("Tap screen to retry")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Results Table

    private func resultsTable(hand: Hand, result: StrategyResult) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                // Best hold summary
                VStack(spacing: 8) {
                    Text("Best Hold")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    let bestHoldOriginal = hand.canonicalIndicesToOriginal(result.bestHoldIndices)
                    HStack(spacing: 8) {
                        if bestHoldOriginal.isEmpty {
                            Text("Draw all 5 cards")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(bestHoldOriginal, id: \.self) { index in
                                Text(hand.cards[index].displayText)
                                    .font(.system(.title2, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundStyle(hand.cards[index].suit.color)
                            }
                        }
                    }

                    Text("EV: \(String(format: "%.4f", result.bestEv))")
                        .font(.headline)
                        .foregroundStyle(Color(hex: "4cd964"))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.07))
                .cornerRadius(12)

                // Spoken advice
                if !viewModel.lastResponse.isEmpty {
                    Text(viewModel.lastResponse)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                // All options table
                VStack(spacing: 6) {
                    // Header
                    HStack {
                        Text("Rank")
                            .frame(width: 38, alignment: .leading)
                        Text("Hold")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("EV")
                            .frame(width: 60, alignment: .trailing)
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)

                    // Rows
                    ForEach(Array(result.sortedHoldOptions.enumerated()), id: \.offset) { index, option in
                        let originalIndices = hand.canonicalIndicesToOriginal(option.indices)
                        let optionCards = originalIndices.map { hand.cards[$0] }
                        let rank = result.rankForOption(at: index)
                        let isBest = rank == 1

                        HStack(spacing: 8) {
                            Text("\(rank)")
                                .font(.subheadline)
                                .fontWeight(isBest ? .bold : .regular)
                                .foregroundStyle(isBest ? .white : .secondary)
                                .frame(width: 38, alignment: .leading)

                            if optionCards.isEmpty {
                                Text("Draw all")
                                    .font(.subheadline)
                                    .italic()
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                HStack(spacing: 4) {
                                    ForEach(optionCards, id: \.id) { card in
                                        Text(card.displayText)
                                            .font(.subheadline)
                                            .foregroundStyle(card.suit.color)
                                            .fontWeight(isBest ? .bold : .regular)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Text(String(format: "%.3f", option.ev))
                                .font(.subheadline)
                                .fontWeight(isBest ? .bold : .regular)
                                .foregroundStyle(isBest ? Color(hex: "4cd964") : .secondary)
                                .frame(width: 60, alignment: .trailing)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isBest ? Color(hex: "1a3a5c") : Color.white.opacity(0.04))
                        .cornerRadius(6)
                    }
                }
            }
            .padding()
        }
    }
}
