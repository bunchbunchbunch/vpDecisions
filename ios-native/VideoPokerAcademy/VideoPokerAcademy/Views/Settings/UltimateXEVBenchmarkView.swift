import SwiftUI

struct UltimateXEVBenchmarkView: View {
    @State private var viewModel = UltimateXEVBenchmarkViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.Gradients.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("UX EV Benchmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.Colors.mintGreen)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                Divider().background(Color.white.opacity(0.1))

                ScrollView {
                    VStack(spacing: 16) {
                        runButton

                        if viewModel.isRunning {
                            ProgressView("Computing E[K] for top-5 holds…")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .padding()
                        }

                        if let result = viewModel.result {
                            resultContent(result)
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(AppTheme.Colors.danger)
                                .padding()
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Run Button

    private var runButton: some View {
        Button {
            Task { await viewModel.runBenchmark() }
        } label: {
            HStack {
                if viewModel.isRunning {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "play.circle.fill")
                }
                Text(viewModel.isRunning ? "Running…" : "Run Benchmark")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(viewModel.isRunning ? Color.gray : AppTheme.Colors.mintGreen)
            .cornerRadius(25)
        }
        .disabled(viewModel.isRunning)
    }

    // MARK: - Result Content

    @ViewBuilder
    private func resultContent(_ result: EVBenchmarkResult) -> some View {
        // Hand display
        benchmarkSection(title: "Dealt Hand") {
            handView(result.hand)
        }

        // Multiplier
        benchmarkSection(title: "Multiplier") {
            HStack {
                Text("M = \(result.multiplier)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(result.multiplier > 1 ? AppTheme.Colors.mintGreen : .white)
                Spacer()
                Text("(3-Play JoB 9/6)")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding()
        }

        // Strategy comparison
        benchmarkSection(title: "Strategy Comparison") {
            VStack(spacing: 0) {
                strategyRow(
                    label: "Base (M=1)",
                    bitmask: result.baseBestHold,
                    hand: result.hand,
                    ev: result.baseEV
                )
                Divider().background(Color.white.opacity(0.1))
                strategyRow(
                    label: "Simplified: 2×EV + (M-1)",
                    bitmask: result.simplifiedBestHold,
                    hand: result.hand,
                    ev: result.simplifiedBestEV
                )
                Divider().background(Color.white.opacity(0.1))
                strategyRow(
                    label: "Full: M×2×EV + E[K]-1",
                    bitmask: result.fullBestHold,
                    hand: result.hand,
                    ev: result.fullBestEV
                )
                Divider().background(Color.white.opacity(0.1))

                HStack {
                    Image(systemName: result.formulasAgree
                          ? "checkmark.circle.fill"
                          : "xmark.circle.fill")
                        .foregroundColor(result.formulasAgree
                          ? AppTheme.Colors.mintGreen
                          : AppTheme.Colors.danger)
                    Text(result.formulasAgree
                         ? "Simplified and full formulas agree"
                         : "STRATEGY DIFFERS between formulas!")
                        .font(.system(size: 13,
                              weight: result.formulasAgree ? .regular : .bold))
                        .foregroundColor(result.formulasAgree
                          ? AppTheme.Colors.textSecondary
                          : AppTheme.Colors.danger)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }

        // Top holds table
        benchmarkSection(title: "Top 5 Holds (Full Formula)") {
            VStack(spacing: 0) {
                HStack {
                    Text("Hold").frame(width: 100, alignment: .leading)
                    Text("E[K]").frame(width: 50, alignment: .trailing)
                    Text("Base EV").frame(width: 70, alignment: .trailing)
                    Text("Full EV").frame(width: 70, alignment: .trailing)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)

                ForEach(Array(result.topHoldDetails.enumerated()), id: \.offset) { _, detail in
                    HStack {
                        Text(holdDescription(detail.heldIndices, hand: result.hand))
                            .frame(width: 100, alignment: .leading)
                            .font(.system(size: 12, design: .monospaced))
                        Text(String(format: "%.2f", detail.eKAwarded))
                            .frame(width: 50, alignment: .trailing)
                        Text(String(format: "%.4f", detail.baseEV))
                            .frame(width: 70, alignment: .trailing)
                        Text(String(format: "%.4f", detail.fullAdjustedEV))
                            .frame(width: 70, alignment: .trailing)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(detail.isFullBest ? AppTheme.Colors.mintGreen : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(detail.isFullBest ? Color.white.opacity(0.05) : Color.clear)
                }
            }
        }

        // Computation time + per-hold-size breakdown
        benchmarkSection(title: "Performance") {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Text("Total (\(result.evaluatedHoldCount) of 31 holds):")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Spacer()
                    Text(String(format: "%.1f ms", result.computationTimeMs))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(result.computationTimeMs < 500
                            ? AppTheme.Colors.mintGreen
                            : .orange)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if !result.timingByHoldSize.isEmpty {
                    Divider().background(Color.white.opacity(0.1))

                    ForEach(result.timingByHoldSize.keys.sorted(by: >), id: \.self) { holdSize in
                        if let ms = result.timingByHoldSize[holdSize] {
                            let combosLabel = holdSize == 5 ? "1 combo" : holdSizeCombosLabel(holdSize)
                            HStack {
                                Text("Hold \(holdSize)")
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                Text(combosLabel)
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.6))
                                Spacer()
                                Text(String(format: "%.1f ms", ms))
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            .font(.system(size: 13))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Views

    private func handView(_ hand: Hand) -> some View {
        HStack(spacing: 8) {
            ForEach(hand.cards) { card in
                Text(card.displayText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(card.suit.color)
                    .frame(minWidth: 40)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding()
    }

    private func strategyRow(label: String, bitmask: Int, hand: Hand, ev: Double) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Text(holdDescription(Hand.holdIndicesFromBitmask(bitmask), hand: hand))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            Spacer()
            Text(String(format: "%.4f", ev))
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func holdDescription(_ canonicalIndices: [Int], hand: Hand) -> String {
        if canonicalIndices.isEmpty { return "Discard all" }
        if canonicalIndices.count == 5 { return "Hold all" }
        let originalIndices = hand.canonicalIndicesToOriginal(canonicalIndices)
        return originalIndices.map { hand.cards[$0].displayText }.joined(separator: " ")
    }

    /// Human-readable combo count label for a given hold size (draw count = 5 - holdSize).
    private func holdSizeCombosLabel(_ holdSize: Int) -> String {
        let drawCount = 5 - holdSize
        let combos: Int
        switch drawCount {
        case 1: combos = 47
        case 2: combos = 1_081
        case 3: combos = 16_215
        case 4: combos = 178_365
        default: combos = 0
        }
        let formatted = combos >= 1_000
            ? String(format: "%gK combos", Double(combos) / 1_000)
            : "\(combos) combo"
        return "(\(formatted))"
    }

    private func benchmarkSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .textCase(.uppercase)
            VStack(spacing: 0) { content() }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.Colors.cardBackground)
                )
        }
    }
}
