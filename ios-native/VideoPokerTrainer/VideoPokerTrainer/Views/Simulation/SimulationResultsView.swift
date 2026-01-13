import SwiftUI
import Charts

struct SimulationResultsView: View {
    @ObservedObject var viewModel: SimulationViewModel
    @Binding var navigationPath: NavigationPath
    @State private var showBankrollChart = true
    @State private var showWinDistribution = true
    @State private var showRunDetails = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with completion status
                headerSection

                // Overall results card
                overallResultsCard

                // Statistics grid
                statisticsGrid

                // Charts section
                chartsSection

                // Action buttons
                actionButtons
            }
            .padding()
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 8) {
            if let results = viewModel.results {
                HStack {
                    Image(systemName: results.isCancelled ? "exclamationmark.circle" : "checkmark.circle.fill")
                        .foregroundColor(results.isCancelled ? .orange : .green)
                        .font(.title2)

                    Text(results.isCancelled ? "Simulation Cancelled" : "Simulation Complete")
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()
                }

                if let paytable = viewModel.currentPaytable {
                    Text(paytable.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var overallResultsCard: some View {
        VStack(spacing: 16) {
            Text("OVERALL RESULTS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let results = viewModel.results {
                VStack(spacing: 12) {
                    resultRow(label: "Total Hands", value: formatNumber(results.totalHandsPlayed))
                    resultRow(label: "Total Wagered", value: formatCurrency(results.overallTotalBet))
                    resultRow(label: "Total Won", value: formatCurrency(results.overallTotalWon))
                    resultRow(
                        label: "Net Result",
                        value: formatCurrency(results.overallNetResult),
                        valueColor: results.overallNetResult >= 0 ? .green : .red
                    )

                    Divider()

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Actual RTP")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.2f%%", results.overallRTP))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.Colors.simulation)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("Theoretical")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(getTheoreticalRTP())
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(AppTheme.Layout.cornerRadiusMedium)
    }

    private var statisticsGrid: some View {
        VStack(spacing: 16) {
            Text("STATISTICS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let results = viewModel.results {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    statCard(title: "Paying Hands", value: formatNumber(results.totalWins), icon: "checkmark.circle")
                    statCard(title: "Biggest Win", value: formatCurrency(results.biggestWin), icon: "arrow.up.circle", color: .green)
                    statCard(title: "Best Run", value: formatCurrency(results.bestRun?.netResult ?? 0), icon: "star.fill", color: .green)
                    statCard(title: "Worst Run", value: formatCurrency(results.worstRun?.netResult ?? 0), icon: "star.slash", color: .red)
                    statCard(
                        title: "Average Run",
                        value: formatCurrency(results.avgNetResult),
                        icon: "chart.bar",
                        color: results.avgNetResult >= 0 ? .green : .red
                    )
                    w2gStatCard(results: results)
                }
            }
        }
    }

    private var chartsSection: some View {
        VStack(spacing: 16) {
            Text("CHARTS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Simulation Outcomes Chart
            chartToggle(title: "Simulation Outcomes", icon: "chart.line.uptrend.xyaxis", isExpanded: $showBankrollChart)
            if showBankrollChart, let results = viewModel.results {
                BankrollChartView(runs: results.runs)
                    .frame(height: 200)
                    .padding(.bottom)
            }

            // Win Distribution
            chartToggle(title: "Wins by Hand Type", icon: "rectangle.3.group.fill", isExpanded: $showWinDistribution)
            if showWinDistribution, let results = viewModel.results {
                WinDistributionChart(winsByHandType: results.aggregatedWinsByHandType)
                    .frame(height: 300)
                    .padding(.bottom)
            }

            // Run Details Table
            chartToggle(title: "Run Details", icon: "list.number", isExpanded: $showRunDetails)
            if showRunDetails, let results = viewModel.results {
                runDetailsTable(runs: results.runs)
                    .padding(.bottom)
            }
        }
    }

    private func runDetailsTable(runs: [SimulationRun]) -> some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                Text("Run")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(width: 50, alignment: .leading)
                Text("Wagered")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text("Won")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text("Net")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray5))

            // Scrollable list of runs
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(runs) { run in
                        HStack {
                            Text("#\(run.runNumber + 1)")
                                .font(.subheadline)
                                .frame(width: 50, alignment: .leading)
                            Text(formatCompactCurrency(run.totalBet))
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            Text(formatCompactCurrency(run.totalWon))
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            Text(formatCompactCurrency(run.netResult))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(run.netResult >= 0 ? .green : .red)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(run.runNumber % 2 == 0 ? Color.clear : Color(.systemGray6))
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .background(Color(.systemGray6))
        .cornerRadius(AppTheme.Layout.cornerRadiusSmall)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    // runAgain resets and starts a new simulation
                    // The container view will switch to running view based on phase
                    await viewModel.runAgain()
                }
            } label: {
                Label("Run Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.Colors.simulation)

            Button {
                // Reset and go back to start to configure a different simulation
                viewModel.reset()
                navigationPath.removeLast()
            } label: {
                Label("New Simulation", systemImage: "plus.circle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.Colors.simulation)

            Button("Back to Menu") {
                viewModel.reset()
                while navigationPath.count > 0 {
                    navigationPath.removeLast()
                }
            }
            .foregroundColor(.secondary)
        }
    }

    // MARK: - Helper Views

    private func resultRow(label: String, value: String, valueColor: Color = .primary) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color = AppTheme.Colors.simulation) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(AppTheme.Layout.cornerRadiusSmall)
    }

    @ViewBuilder
    private func w2gStatCard(results: SimulationResults) -> some View {
        let runCount = results.runs.count
        let w2gCount = results.totalWinsOver2000

        if w2gCount == 0 {
            // No W2G wins
            statCard(title: "W2G Wins", value: "0", icon: "dollarsign.circle")
        } else {
            let avgW2GPerRun = Double(w2gCount) / Double(runCount)
            if avgW2GPerRun >= 1.0 {
                // More than 1 W2G per run on average
                statCard(
                    title: "W2G's per Run",
                    value: String(format: "%.1f", avgW2GPerRun),
                    icon: "dollarsign.circle",
                    color: .purple
                )
            } else {
                // Less than 1 W2G per run on average
                let runsPerW2G = Double(runCount) / Double(w2gCount)
                statCard(
                    title: "Avg Runs per W2G",
                    value: String(format: "%.1f", runsPerW2G),
                    icon: "dollarsign.circle",
                    color: .purple
                )
            }
        }
    }

    private func chartToggle(title: String, icon: String, isExpanded: Binding<Bool>) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.wrappedValue.toggle()
            }
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.Colors.simulation)
                Text(title)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(AppTheme.Layout.cornerRadiusSmall)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }

    private func formatCompactCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }

    private func getTheoreticalRTP() -> String {
        // Theoretical RTP lookup based on paytable ID
        guard let paytable = viewModel.currentPaytable else { return "N/A" }

        // Known theoretical RTPs for common paytables
        let rtpLookup: [String: Double] = [
            "jacks-or-better-9-6": 99.54,
            "jacks-or-better-9-5": 98.45,
            "jacks-or-better-8-6": 98.39,
            "jacks-or-better-8-5": 97.30,
            "jacks-or-better-7-5": 96.15,
            "double-bonus-10-7-5": 100.17,
            "double-bonus-9-7-5": 99.11,
            "double-double-bonus-9-6": 98.98,
            "double-double-bonus-9-5": 97.87,
            "triple-double-bonus-9-6": 99.58,
            "triple-double-bonus-9-5": 98.15,
            "bonus-poker-8-5": 99.17,
            "bonus-poker-7-5": 98.01,
            "deuces-wild-nsud": 100.76,
            "deuces-wild-full-pay": 100.76
        ]

        if let rtp = rtpLookup[paytable.id] {
            return String(format: "%.2f%%", rtp)
        }
        return "N/A"
    }

}

// MARK: - Chart Views

struct BankrollChartView: View {
    let runs: [SimulationRun]

    var body: some View {
        Chart {
            // Show all runs - each line represents final bankroll of a simulation
            ForEach(runs) { run in
                ForEach(Array(run.bankrollHistory.enumerated()), id: \.offset) { handIndex, bankroll in
                    LineMark(
                        x: .value("Hand", handIndex * 10), // Multiply by 10 since we sampled every 10 hands
                        y: .value("Bankroll", bankroll)
                    )
                    .foregroundStyle(by: .value("Run", "Run \(run.runNumber + 1)"))
                    .opacity(0.7)
                }
            }
        }
        .chartXAxisLabel("Hands Played")
        .chartYAxisLabel("Bankroll ($)")
        .chartLegend(.hidden) // Hide legend when showing many runs
    }
}

struct WinDistributionChart: View {
    let winsByHandType: [String: Int]

    var body: some View {
        let sortedHands = winsByHandType.sorted { $0.value > $1.value }

        Chart {
            ForEach(sortedHands.prefix(10), id: \.key) { handType, count in
                BarMark(
                    x: .value("Count", count),
                    y: .value("Hand", handType)
                )
                .foregroundStyle(colorForHand(handType).gradient)
                .annotation(position: .trailing) {
                    Text(formatNumber(count))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .chartXAxisLabel("Count")
    }

    private func colorForHand(_ handName: String) -> Color {
        switch handName {
        case "Royal Flush", "Natural Royal":
            return .purple
        case "Straight Flush", "Four Deuces":
            return .blue
        case "Four of a Kind", "Four Aces", "Four 2-4", "Four 5-K", "Five of a Kind":
            return .indigo
        case "Full House", "Wild Royal":
            return .teal
        case "Flush":
            return .cyan
        case "Straight":
            return .green
        case "Three of a Kind":
            return .yellow
        case "Two Pair":
            return .orange
        default:
            return AppTheme.Colors.simulation
        }
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

#Preview {
    NavigationStack {
        SimulationResultsView(
            viewModel: SimulationViewModel(),
            navigationPath: .constant(NavigationPath())
        )
    }
}
