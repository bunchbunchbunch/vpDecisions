import SwiftUI

struct PlayView: View {
    @StateObject private var viewModel = PlayViewModel()
    @Binding var navigationPath: NavigationPath
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var showSettings = false
    @State private var showStats = false
    @State private var showAddFunds = false
    @State private var showPaytable = false
    @State private var fundsToAdd: String = ""

    // Swipe gesture state
    @State private var swipedCardIndices: Set<Int> = []
    @State private var isDragging = false
    @State private var dragStartLocation: CGPoint?

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top bar with balance and settings
                topBar

                // Multi-hand grid (for 5/10 line modes) - fixed
                if viewModel.settings.lineCount != .one {
                    MultiHandGrid(
                        lineCount: viewModel.settings.lineCount,
                        results: gridResults,
                        phase: viewModel.phase,
                        denomination: viewModel.settings.denomination.rawValue
                    )
                }

                // Cards area (main hand - last line) - fixed
                cardsArea(geometry: geometry)
                    .padding(.top, 12)

                // EV Options Table (scrollable when visible)
                if viewModel.settings.showOptimalFeedback && viewModel.phase == .result {
                    ScrollView {
                        evOptionsTable
                            .padding(.horizontal)
                            .padding(.top, 12)
                    }
                } else {
                    Spacer()
                }

                // Bottom controls
                bottomControls
            }
        }
        .navigationTitle("Play")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    Task {
                        await viewModel.endSession()
                    }
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        showStats = true
                    } label: {
                        Image(systemName: "chart.bar.fill")
                    }

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            PlaySettingsSheet(viewModel: viewModel, isPresented: $showSettings)
        }
        .sheet(isPresented: $showStats) {
            PlayStatsSheet(viewModel: viewModel, isPresented: $showStats)
        }
        .sheet(isPresented: $showPaytable) {
            PaytableSheet(viewModel: viewModel, isPresented: $showPaytable)
        }
        .alert("Add Funds", isPresented: $showAddFunds) {
            TextField("Amount", text: $fundsToAdd)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) {
                fundsToAdd = ""
            }
            Button("Add") {
                if let amount = Double(fundsToAdd), amount > 0 {
                    Task {
                        await viewModel.addFunds(amount)
                    }
                }
                fundsToAdd = ""
            }
        } message: {
            Text("Enter amount to add to your balance")
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Balance
            VStack(alignment: .leading, spacing: 2) {
                Text("Balance")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatCurrency(viewModel.balance.balance))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.balance.balance >= viewModel.settings.totalBetDollars ? .primary : .red)
            }

            Spacer()

            // Add funds button
            Button {
                showAddFunds = true
            } label: {
                Label("Add Funds", systemImage: "plus.circle.fill")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)

            Spacer()

            // Current denomination
            VStack(alignment: .trailing, spacing: 2) {
                Text("Denom")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.settings.denomination.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Cards Area

    private func cardsArea(geometry: GeometryProxy) -> some View {
        ZStack {
            // Green felt background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "2d5016"))
                .shadow(radius: 5)

            VStack(spacing: 4) {
                // Dealt winner banner (overlay above cards)
                if viewModel.showDealtWinner, let handName = viewModel.dealtWinnerName {
                    DealtWinnerBanner(handName: handName)
                        .transition(AnyTransition.scale.combined(with: AnyTransition.opacity))
                        .padding(.top, 8)
                } else {
                    // Top info row: Lines, Paytable button, Coins
                    HStack {
                        Text("\(viewModel.settings.lineCount.displayName)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))

                        Spacer()

                        // Paytable button
                        Button {
                            showPaytable = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "list.bullet.rectangle")
                                    .font(.caption)
                                Text("Paytable")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(6)
                        }

                        Spacer()

                        Text("5 coins")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                Spacer()

                // Cards with win badge overlay
                ZStack(alignment: .bottom) {
                    if !viewModel.dealtCards.isEmpty {
                        GeometryReader { cardGeometry in
                            HStack(spacing: 8) {
                                ForEach(Array(viewModel.dealtCards.enumerated()), id: \.element.id) { index, card in
                                    let displayCard = displayCardForIndex(index)
                                    CardView(
                                        card: displayCard,
                                        isSelected: viewModel.selectedIndices.contains(index)
                                    ) {
                                        if viewModel.phase == .dealt {
                                            viewModel.toggleCard(index)
                                        }
                                    }
                                }
                            }
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        guard viewModel.phase == .dealt else { return }

                                        let cardWidth = (cardGeometry.size.width - 32) / 5
                                        let xPosition = value.location.x
                                        let cardIndex = Int(xPosition / (cardWidth + 8))

                                        if !isDragging {
                                            isDragging = true
                                            dragStartLocation = value.location
                                            swipedCardIndices = []
                                        }

                                        if cardIndex >= 0 && cardIndex < 5 && !swipedCardIndices.contains(cardIndex) {
                                            guard let startLocation = dragStartLocation else { return }
                                            let dragDistance = hypot(
                                                value.location.x - startLocation.x,
                                                value.location.y - startLocation.y
                                            )

                                            if dragDistance > 10 || !swipedCardIndices.isEmpty {
                                                swipedCardIndices.insert(cardIndex)
                                                viewModel.toggleCard(cardIndex)
                                            }
                                        }
                                    }
                                    .onEnded { _ in
                                        swipedCardIndices = []
                                        isDragging = false
                                        dragStartLocation = nil
                                    }
                            )
                        }
                    } else {
                        // Empty card placeholders
                        HStack(spacing: 8) {
                            ForEach(0..<5, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.1))
                                    .aspectRatio(2.5/3.5, contentMode: .fit)
                            }
                        }
                    }

                    // Win badge overlay (result phase only)
                    if viewModel.phase == .result, let result = mainHandResult {
                        mainHandWinBadge(result: result)
                            .offset(y: 12)
                    }
                }
                .frame(height: 100)
                .padding(.horizontal)

                Spacer()

                // Unified info line below cards
                handInfoLine
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
            }
        }
        .frame(height: 200)
        .padding(.horizontal)
    }

    // MARK: - Hand Info Line

    @ViewBuilder
    private var handInfoLine: some View {
        HStack(spacing: 8) {
            if viewModel.phase == .betting {
                // Empty placeholder to maintain layout
                Text(" ")
                    .font(.caption)
            } else if viewModel.phase == .dealt {
                // Swipe tip during dealt phase
                if viewModel.showSwipeTip {
                    Image(systemName: "hand.draw")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Text("Swipe to select")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Text(" ")
                        .font(.caption)
                }
            } else if viewModel.phase == .result {
                // Result info: Feedback | Bet summary (win/no-win shown as badge on cards)

                // Feedback (if enabled)
                if viewModel.settings.showOptimalFeedback {
                    if viewModel.showMistakeFeedback {
                        Text("✗ Incorrect Decision")
                            .font(.caption)
                            .foregroundColor(Color(hex: "FFA726"))
                        if viewModel.userEvLost > 0 {
                            let dollarEvLost = viewModel.userEvLost * viewModel.settings.totalBetDollars
                            Text("-\(formatCurrency(dollarEvLost))")
                                .font(.caption)
                                .foregroundColor(Color(hex: "FFA726"))
                        }
                    } else {
                        Text("✓ Correct Decision")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                }

                // Bet summary
                Text("\(formatCurrency(viewModel.settings.totalBetDollars))→\(formatCurrency(viewModel.totalPayoutDollars))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    private func displayCardForIndex(_ index: Int) -> Card {
        // During result phase, show the final cards from the last line result (main hand)
        if viewModel.phase == .result, let lastResult = viewModel.lineResults.last {
            return lastResult.finalHand[index].toCard()
        }
        return viewModel.dealtCards[index]
    }

    /// Results for the grid (all but the last line, which shows in the main play area)
    private var gridResults: [PlayHandResult] {
        guard viewModel.lineResults.count > 1 else { return [] }
        return Array(viewModel.lineResults.dropLast())
    }

    /// The main hand result (last line)
    private var mainHandResult: PlayHandResult? {
        viewModel.lineResults.last
    }

    // MARK: - Win Badge

    @ViewBuilder
    private func mainHandWinBadge(result: PlayHandResult) -> some View {
        if let handName = result.handName, result.payout > 0 {
            let badgeColors = winBadgeColors(for: handName)
            // Winner badge (only show for wins, matching mini-hand behavior)
            HStack(spacing: 6) {
                Text(handName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("+\(formatCurrency(Double(result.payout) * viewModel.settings.denomination.rawValue))")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: badgeColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        // No badge shown for non-winning hands (matches mini-hand grid behavior)
    }

    private func winBadgeColors(for handName: String) -> [Color] {
        switch handName {
        case "Jacks or Better", "Tens or Better":
            // Light Purple
            return [Color(hex: "B388FF"), Color(hex: "9575CD")]
        case "Two Pair":
            // Light Blue
            return [Color(hex: "81D4FA"), Color(hex: "4FC3F7")]
        case "Three of a Kind":
            // Yellow
            return [Color(hex: "FFEE58"), Color(hex: "FDD835")]
        case "Straight":
            // Dark Pink
            return [Color(hex: "F06292"), Color(hex: "EC407A")]
        case "Flush":
            // Green
            return [Color(hex: "66BB6A"), Color(hex: "43A047")]
        case "Full House":
            // Dark Blue
            return [Color(hex: "5C6BC0"), Color(hex: "3F51B5")]
        case _ where handName.contains("Four"):
            // Light Pink (Four of a Kind and variants)
            return [Color(hex: "F8BBD9"), Color(hex: "F48FB1")]
        case "Straight Flush":
            // Dark Purple
            return [Color(hex: "7E57C2"), Color(hex: "5E35B1")]
        case "Royal Flush", "Natural Royal", "Wild Royal":
            // Red
            return [Color(hex: "EF5350"), Color(hex: "E53935")]
        default:
            // Default gold
            return [Color(hex: "FFD700"), Color(hex: "FFA500")]
        }
    }

    // MARK: - EV Options Table

    private var evOptionsTable: some View {
        Group {
            if let result = viewModel.strategyResult {
                let hand = Hand(cards: viewModel.dealtCards)
                let options = result.sortedHoldOptions
                let userHold = Array(viewModel.selectedIndices).sorted()
                let userCanonicalHold = hand.originalIndicesToCanonical(userHold)

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

                        Text("Exp. Value")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 70, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)

                    // Table rows
                    VStack(spacing: 4) {
                        ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                            let optionOriginalIndices = hand.canonicalIndicesToOriginal(option.indices)
                            let optionCards = optionOriginalIndices.map { viewModel.dealtCards[$0] }
                            let isBest = index == 0
                            let isUserSelection = userCanonicalHold.sorted() == option.indices.sorted()

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
                                                .foregroundColor(card.suit.textColor(for: colorScheme))
                                                .fontWeight(isBest ? .bold : .regular)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                // Expected Value in dollars
                                let dollarEv = option.ev * viewModel.settings.totalBetDollars
                                Text(formatCurrency(dollarEv))
                                    .font(.subheadline)
                                    .fontWeight(isBest ? .bold : .regular)
                                    .frame(width: 70, alignment: .trailing)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                isUserSelection
                                    ? (isBest ? Color(hex: "27ae60").opacity(0.3) : Color(hex: "FFA726").opacity(0.3))
                                    : (isBest ? Color(hex: "667eea").opacity(0.2) : Color(.systemGray6))
                            )
                            .cornerRadius(6)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }


    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 12) {
            // Action button
            actionButton
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var actionButton: some View {
        Button {
            Task {
                switch viewModel.phase {
                case .betting, .result:
                    await viewModel.deal()
                case .dealt:
                    await viewModel.draw()
                case .drawing:
                    break
                }
            }
        } label: {
            Text(actionButtonText)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(actionButtonColor)
        .disabled(!viewModel.canDeal && (viewModel.phase == .betting || viewModel.phase == .result))
    }

    private var actionButtonText: String {
        switch viewModel.phase {
        case .betting, .result:
            return viewModel.canDeal ? "DEAL" : "Insufficient Funds"
        case .dealt:
            return "DRAW"
        case .drawing:
            return "Drawing..."
        }
    }

    private var actionButtonColor: Color {
        switch viewModel.phase {
        case .betting, .result:
            return viewModel.canDeal ? Color(hex: "667eea") : Color.gray
        case .dealt:
            return Color(hex: "27ae60")
        case .drawing:
            return Color.gray
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Paytable Sheet

struct PaytableSheet: View {
    @ObservedObject var viewModel: PlayViewModel
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            if let paytable = viewModel.currentPaytable {
                ScrollView {
                    VStack(spacing: 16) {
                        Text(paytable.name)
                            .font(.headline)
                            .padding(.top)

                        // Paytable rows
                        VStack(spacing: 4) {
                            // Header
                            HStack {
                                Text("Hand")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                ForEach(1...5, id: \.self) { coins in
                                    Text("\(coins)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .frame(width: 45, alignment: .trailing)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)

                            // Rows
                            ForEach(paytable.rows, id: \.handName) { row in
                                HStack {
                                    Text(row.handName)
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    ForEach(Array(row.payouts.enumerated()), id: \.offset) { index, payout in
                                        Text("\(payout)")
                                            .font(.subheadline)
                                            .fontWeight(index == 4 ? .bold : .regular)
                                            .frame(width: 45, alignment: .trailing)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .cornerRadius(6)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .navigationTitle("Paytable")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Settings Sheet

struct PlaySettingsSheet: View {
    @ObservedObject var viewModel: PlayViewModel
    @Binding var isPresented: Bool

    @State private var selectedPaytableId: String = ""
    @State private var selectedDenomination: BetDenomination = .one
    @State private var selectedLineCount: LineCount = .one
    @State private var showOptimalFeedback: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Game") {
                    Picker("Variant", selection: $selectedPaytableId) {
                        ForEach(PayTable.allPayTables, id: \.id) { paytable in
                            Text(paytable.name).tag(paytable.id)
                        }
                    }
                }

                Section("Bet") {
                    Picker("Denomination", selection: $selectedDenomination) {
                        ForEach(BetDenomination.allCases, id: \.self) { denom in
                            Text(denom.displayName).tag(denom)
                        }
                    }

                    Picker("Lines", selection: $selectedLineCount) {
                        ForEach(LineCount.allCases, id: \.self) { count in
                            Text(count.displayName).tag(count)
                        }
                    }
                }

                Section("Feedback") {
                    Toggle("Show Optimal Play Feedback", isOn: $showOptimalFeedback)
                }

                Section {
                    HStack {
                        Text("Total Bet")
                        Spacer()
                        let totalBet = Double(selectedLineCount.rawValue * 5) * selectedDenomination.rawValue
                        Text(formatCurrency(totalBet))
                            .fontWeight(.bold)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            var newSettings = viewModel.settings
                            newSettings.selectedPaytableId = selectedPaytableId
                            newSettings.denomination = selectedDenomination
                            newSettings.lineCount = selectedLineCount
                            newSettings.showOptimalFeedback = showOptimalFeedback
                            await viewModel.updateSettings(newSettings)
                            isPresented = false
                        }
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                selectedPaytableId = viewModel.settings.selectedPaytableId
                selectedDenomination = viewModel.settings.denomination
                selectedLineCount = viewModel.settings.lineCount
                showOptimalFeedback = viewModel.settings.showOptimalFeedback
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Stats Sheet

struct PlayStatsSheet: View {
    @ObservedObject var viewModel: PlayViewModel
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Current session stats
                    sessionStatsCard

                    // All-time stats
                    allTimeStatsCard

                    // Wins by hand type
                    winsBreakdownCard
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private var sessionStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Session")
                .font(.headline)

            statsGrid(stats: viewModel.currentStats)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private var allTimeStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Time (\(viewModel.currentPaytable?.name ?? ""))")
                .font(.headline)

            statsGrid(stats: viewModel.getAllTimeStats().allTime)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private func statsGrid(stats: PlaySessionStats) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            statItem(title: "Hands Played", value: "\(stats.handsPlayed)")
            statItem(title: "Total Bet", value: formatCurrency(stats.totalBet))
            statItem(title: "Total Won", value: formatCurrency(stats.totalWon))
            statItem(
                title: "Net Profit",
                value: formatCurrency(stats.netProfit),
                color: stats.netProfit >= 0 ? .green : .red
            )
            statItem(title: "Return %", value: String(format: "%.1f%%", stats.returnPercentage))
            statItem(title: "Biggest Win", value: formatCurrency(stats.biggestWin))
            statItem(title: "Mistakes", value: "\(stats.mistakesMade)")
            statItem(title: "EV Lost", value: formatCurrency(stats.totalEvLost))
        }
    }

    private func statItem(title: String, value: String, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var winsBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wins by Hand Type")
                .font(.headline)

            let allTimeStats = viewModel.getAllTimeStats().allTime
            if allTimeStats.winsByHandType.isEmpty {
                Text("No wins recorded yet")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(allTimeStats.winsByHandType.sorted(by: { $0.value > $1.value }), id: \.key) { handType, count in
                    HStack {
                        Text(handType)
                            .font(.subheadline)
                        Spacer()
                        Text("\(count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

#Preview {
    NavigationStack {
        PlayView(navigationPath: .constant(NavigationPath()))
    }
}
