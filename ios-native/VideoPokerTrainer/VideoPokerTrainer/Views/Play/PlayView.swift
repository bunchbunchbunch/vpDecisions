import SwiftUI

struct PlayView: View {
    @StateObject private var viewModel = PlayViewModel()
    @Binding var navigationPath: NavigationPath
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    @State private var showSettings = false
    @State private var showStats = false
    @State private var showAddFunds = false
    @State private var showPaytable = false
    @State private var fundsToAdd: String = ""

    // Swipe gesture state
    @State private var swipedCardIndices: Set<Int> = []
    @State private var isDragging = false
    @State private var dragStartLocation: CGPoint?

    // Exit confirmation
    @State private var showExitConfirmation = false

    // Win counting animation
    @State private var animatedWinAmount: Double = 0
    @State private var animatedBalanceAmount: Double = 0
    @State private var isCountingWin: Bool = false
    @State private var countingTimer: Timer?
    @State private var targetWinAmount: Double = 0
    @State private var targetBalanceAmount: Double = 0
    @State private var preWinBalance: Double = 0

    var body: some View {
        ZStack {
            mainContent

            // Loading overlay when preparing paytable
            if viewModel.isPreparingPaytable {
                preparingPaytableOverlay
            }
        }
        .withTour(.playGame)
        .navigationTitle("Play Mode")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if viewModel.phase == .dealt {
                        showExitConfirmation = true
                    } else {
                        Task {
                            await viewModel.endSession()
                        }
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            ToolbarItem(placement: .principal) {
                Text(viewModel.currentPaytable?.name ?? "Video Poker")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "FFD700"))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        showStats = true
                    } label: {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.white)
                    }

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
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
        .alert("Leave Game?", isPresented: $showExitConfirmation) {
            Button("Stay", role: .cancel) { }
            Button("Leave") {
                Task {
                    await viewModel.abandonHand()
                    await viewModel.endSession()
                }
                dismiss()
            }
        } message: {
            Text("You have an active hand. Your bet will be refunded and the hand won't count in your statistics.")
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .inactive:
                Task {
                    await viewModel.saveHandState()
                }
            case .background:
                Task {
                    await viewModel.saveHandState()
                }
            case .active:
                if oldPhase == .background || oldPhase == .inactive {
                    Task {
                        await viewModel.restoreHandState()
                    }
                }
            @unknown default:
                break
            }
        }
        .onChange(of: viewModel.phase) { oldPhase, newPhase in
            if newPhase == .result && viewModel.totalPayoutDollars > 0 {
                startWinCountingAnimation()
            } else if newPhase == .betting {
                // Reset animation state when starting new hand
                resetWinAnimation()
            }
        }
        .onDisappear {
            countingTimer?.invalidate()
            countingTimer = nil
        }
    }

    // MARK: - Win Counting Animation

    private func startWinCountingAnimation() {
        let winAmount = viewModel.totalPayoutDollars
        let currentBalance = viewModel.balance.balance

        // Store targets
        targetWinAmount = winAmount
        targetBalanceAmount = currentBalance
        preWinBalance = currentBalance - winAmount

        // Start from zero win and pre-win balance
        animatedWinAmount = 0
        animatedBalanceAmount = preWinBalance
        isCountingWin = true

        // Calculate increment based on win size (complete in ~1.5 seconds)
        let totalSteps = 30.0
        let winIncrement = winAmount / totalSteps
        let intervalTime = 1.5 / totalSteps

        countingTimer?.invalidate()
        countingTimer = Timer.scheduledTimer(withTimeInterval: intervalTime, repeats: true) { timer in
            if animatedWinAmount < targetWinAmount {
                animatedWinAmount = min(animatedWinAmount + winIncrement, targetWinAmount)
                animatedBalanceAmount = min(animatedBalanceAmount + winIncrement, targetBalanceAmount)
            } else {
                finishWinAnimation()
            }
        }
    }

    private func skipWinAnimation() {
        if isCountingWin {
            finishWinAnimation()
        }
    }

    private func finishWinAnimation() {
        countingTimer?.invalidate()
        countingTimer = nil
        animatedWinAmount = targetWinAmount
        animatedBalanceAmount = targetBalanceAmount
        isCountingWin = false
    }

    private func resetWinAnimation() {
        countingTimer?.invalidate()
        countingTimer = nil
        animatedWinAmount = 0
        animatedBalanceAmount = viewModel.balance.balance
        isCountingWin = false
        targetWinAmount = 0
        targetBalanceAmount = 0
    }

    // MARK: - Preparing Paytable Overlay

    private var preparingPaytableOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                if viewModel.preparationFailed {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.orange)

                    Text("Game Unavailable")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(viewModel.preparationMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 12) {
                        Button {
                            showSettings = true
                        } label: {
                            Text("Change Game")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: "667eea"))

                        Button {
                            dismiss()
                        } label: {
                            Text("Go Back")
                                .font(.subheadline)
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                } else {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Color(hex: "667eea"))

                    Text(viewModel.preparationMessage)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    VStack(spacing: 8) {
                        Text("Preparing compressed strategy data for use.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("To save the uncompressed file for quicker play, change storage options in Settings → Offline Data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        GeometryReader { geometry in
            ZStack {
                // Casino-style dark blue gradient background
                LinearGradient(
                    colors: [Color(hex: "0a0a1a"), Color(hex: "1a1a3a"), Color(hex: "0a0a1a")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Fixed top section - paytable and cards (doesn't move)
                    VStack(spacing: 0) {
                        // Multi-hand grid (for 5/10 line modes)
                        if viewModel.settings.lineCount == .oneHundred {
                            HundredPlayTallyView(
                                tallyResults: viewModel.phase == .result ? viewModel.hundredPlayTally : [],
                                denomination: viewModel.settings.denomination.rawValue
                            )
                            .frame(height: 160)
                            .padding(.horizontal, 8)
                        } else if viewModel.settings.lineCount != .one {
                            MultiHandGrid(
                                lineCount: viewModel.settings.lineCount,
                                results: gridResults,
                                phase: viewModel.phase,
                                denomination: viewModel.settings.denomination.rawValue,
                                showAsWild: viewModel.currentPaytable?.isDeucesWild ?? false
                            )
                        }

                        // Compact Paytable Display
                        compactPaytableBar
                            .padding(.horizontal, 8)
                            .padding(.top, 4)

                        // Machine frame with cards
                        machineFrame(geometry: geometry)
                            .padding(.horizontal, 8)
                            .padding(.top, 8)

                        // Balance, Bet, Win Display Bar (below cards)
                        creditsBar
                            .padding(.top, 8)
                    }

                    // Flexible bottom section - result info, EV table, buttons
                    VStack(spacing: 0) {
                        // Result info (when in result phase)
                        if viewModel.phase == .result {
                            resultInfoBar
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                        }

                        Spacer(minLength: 0)

                        // EV Options Table (scrollable when visible)
                        if viewModel.settings.showOptimalFeedback && viewModel.phase == .result {
                            ScrollView {
                                evOptionsTable
                                    .padding(.horizontal)
                            }
                            .frame(maxHeight: 180)
                        }

                        // Casino-style button bar
                        casinoButtonBar
                            .padding(.horizontal, 8)
                            .padding(.bottom, 8)
                    }
                }
            }
        }
    }

    // MARK: - Credits Bar

    private var creditsBar: some View {
        HStack {
            // Balance display (in dollars) - tap to add funds
            Button {
                showAddFunds = true
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("BALANCE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "888888"))
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "00FF00").opacity(0.7))
                    }

                    Text(balanceDollarsDisplay)
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                        .foregroundColor(viewModel.balance.balance >= viewModel.settings.totalBetDollars ? Color(hex: "00FF00") : Color(hex: "FF4444"))
                }
            }
            .tourTarget("balanceArea")

            Spacer()

            // Bet display (in dollars)
            VStack(alignment: .trailing, spacing: 2) {
                Text("BET")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "888888"))

                Text(betDollarsDisplay)
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundColor(Color(hex: "FFFF00"))
            }

            Spacer()

            // Win display (in dollars)
            VStack(alignment: .trailing, spacing: 2) {
                Text("WIN")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "888888"))

                Text(winDollarsDisplay)
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundColor(Color(hex: "FFD700"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "333355"), lineWidth: 1)
                )
        )
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }

    private var balanceDollarsDisplay: String {
        if isCountingWin {
            return formatDollars(animatedBalanceAmount)
        }
        return formatDollars(viewModel.balance.balance)
    }

    private var betDollarsDisplay: String {
        formatDollars(viewModel.settings.totalBetDollars)
    }

    private var winDollarsDisplay: String {
        if isCountingWin {
            return formatDollars(animatedWinAmount)
        }
        let winAmount = viewModel.phase == .result ? viewModel.totalPayoutDollars : 0
        return formatDollars(winAmount)
    }

    private func formatDollars(_ amount: Double) -> String {
        return String(format: "$%.2f", amount)
    }

    // MARK: - Compact Paytable Bar

    private var compactPaytableBar: some View {
        Button {
            showPaytable = true
        } label: {
            HStack(spacing: 0) {
                if let paytable = viewModel.currentPaytable {
                    // Show top payouts in a row
                    ForEach(Array(paytable.rows.prefix(4)), id: \.handName) { row in
                        VStack(spacing: 2) {
                            Text(abbreviateHandName(row.handName))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color(hex: "AAAAAA"))
                            Text("\(row.payouts[4])")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(Color(hex: "FFD700"))
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // More indicator
                    VStack(spacing: 2) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "AAAAAA"))
                        Text("MORE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(hex: "AAAAAA"))
                    }
                    .frame(width: 50)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(hex: "444466"), lineWidth: 1)
                    )
            )
        }
        .tourTarget("paytableButton")
    }

    private func abbreviateHandName(_ name: String) -> String {
        switch name {
        case "Royal Flush": return "ROYAL"
        case "Straight Flush": return "ST FL"
        case "Four of a Kind": return "4 KIND"
        case "Full House": return "F HOUSE"
        case "Flush": return "FLUSH"
        case "Straight": return "STRT"
        case "Three of a Kind": return "3 KIND"
        case "Two Pair": return "2 PAIR"
        case "Jacks or Better": return "JKS+"
        case "Tens or Better": return "10s+"
        case "Five of a Kind": return "5 KIND"
        case "Wild Royal Flush": return "W ROYAL"
        case "Natural Royal Flush": return "N ROYAL"
        // Four of a kind variants
        case "Four Aces": return "4 ACES"
        case "Four 2s", "Four Twos", "Four Deuces": return "4 2s"
        case "Four 3s", "Four Threes": return "4 3s"
        case "Four 4s", "Four Fours": return "4 4s"
        case "Four 5s", "Four Fives": return "4 5s"
        case "Four 6s", "Four Sixes": return "4 6s"
        case "Four 7s", "Four Sevens": return "4 7s"
        case "Four 8s", "Four Eights": return "4 8s"
        case "Four 9s", "Four Nines": return "4 9s"
        case "Four 10s", "Four Tens": return "4 10s"
        case "Four Jacks": return "4 Js"
        case "Four Queens": return "4 Qs"
        case "Four Kings": return "4 Ks"
        // Range-based four of a kind
        case "Four 2-4": return "4 2-4"
        case "Four 5-K": return "4 5-K"
        case "Four 2s-4s": return "4 2s-4s"
        case "Four 5s-Ks": return "4 5s-Ks"
        // Aces with kicker hands
        case let s where s.hasPrefix("Four Aces"):
            return "4 A+" + (s.contains("2-4") ? "2-4" : s.contains("J-K") ? "JK" : "")
        // Generic four of a kind patterns
        case let s where s.hasPrefix("Four "):
            let rest = s.dropFirst(5)
            if rest.hasPrefix("Aces") { return "4 ACES" }
            return "4 " + rest.prefix(3).uppercased()
        default: return String(name.prefix(7)).uppercased()
        }
    }

    // MARK: - Machine Frame with Cards

    private func machineFrame(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Cards area with felt background
            ZStack {
                // Green felt
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "1a4d1a"), Color(hex: "0d3d0d"), Color(hex: "1a4d1a")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                VStack(spacing: 8) {
                    // Dealt winner indicator or spacer
                    if viewModel.phase == .dealt, let handName = viewModel.dealtWinnerName {
                        Text(handName.uppercased())
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(Color(hex: "FFD700"))
                            .padding(.top, 8)
                    } else {
                        Spacer(minLength: 16)
                    }

                    // Cards with win badge overlay
                    ZStack(alignment: .bottom) {
                        if !viewModel.dealtCards.isEmpty {
                            GeometryReader { cardGeometry in
                                HStack(spacing: 6) {
                                    ForEach(Array(viewModel.dealtCards.enumerated()), id: \.element.id) { index, card in
                                        let displayCard = displayCardForIndex(index)
                                        CardView(
                                            card: displayCard,
                                            isSelected: viewModel.selectedIndices.contains(index),
                                            showAsWild: viewModel.currentPaytable?.isDeucesWild ?? false
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

                                            let cardWidth = (cardGeometry.size.width - 24) / 5
                                            let xPosition = value.location.x
                                            let cardIndex = Int(xPosition / (cardWidth + 6))

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
                            HStack(spacing: 6) {
                                ForEach(0..<5, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.black.opacity(0.3))
                                        .aspectRatio(2.5/3.5, contentMode: .fit)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                }
                            }
                        }

                        // Win badge overlay (result phase only)
                        if viewModel.phase == .result, let result = mainHandResult {
                            mainHandWinBadge(result: result)
                                .offset(y: 16)
                        }
                    }
                    .frame(height: 120)
                    .padding(.horizontal, 8)

                    // Swipe tip or phase indicator
                    if viewModel.phase == .dealt && viewModel.showSwipeTip {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.draw")
                                .font(.system(size: 11))
                            Text("TAP OR SWIPE TO HOLD")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "AAAAAA"))
                        .padding(.bottom, 4)
                    } else {
                        Text(" ")
                            .font(.system(size: 11))
                            .padding(.bottom, 4)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .background(
            // Machine chrome frame
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "2a2a4a"), Color(hex: "1a1a3a"), Color(hex: "2a2a4a")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "4a4a6a"), Color(hex: "3a3a5a")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
        )
        .tourTarget("cardsArea")
    }

    // MARK: - Result Info Bar

    private var resultInfoBar: some View {
        HStack {
            if viewModel.settings.showOptimalFeedback {
                if viewModel.showMistakeFeedback {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(hex: "FFA726"))
                        Text("INCORRECT")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "FFA726"))
                        if viewModel.userEvLost > 0 {
                            let dollarEvLost = viewModel.userEvLost * viewModel.settings.totalBetDollars
                            Text("(-\(formatCurrency(dollarEvLost)) EV)")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "FFA726"))
                        }
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "00FF00"))
                        Text("CORRECT!")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "00FF00"))
                    }
                }
            }

            Spacer()
        }
    }

    // MARK: - Casino Button Bar

    private var casinoButtonBar: some View {
        // Main DEAL/DRAW button (centered, full width)
        Button {
            // Skip win animation if user presses DEAL while counting
            skipWinAnimation()

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
            VStack(spacing: 2) {
                Text(actionButtonLabel)
                    .font(.system(size: 20, weight: .black))
                if viewModel.phase == .betting || viewModel.phase == .result {
                    Text(formatCurrency(viewModel.settings.totalBetDollars))
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        actionButtonEnabled ?
                        LinearGradient(
                            colors: [Color(hex: "00aa00"), Color(hex: "008800")],
                            startPoint: .top,
                            endPoint: .bottom
                        ) :
                        LinearGradient(
                            colors: [Color(hex: "444444"), Color(hex: "333333")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(actionButtonEnabled ? Color(hex: "00cc00") : Color(hex: "555555"), lineWidth: 2)
                    )
                    .shadow(color: actionButtonEnabled ? Color(hex: "00ff00").opacity(0.3) : .clear, radius: 8)
            )
        }
        .disabled(!actionButtonEnabled)
        .tourTarget("actionButton")
        .padding(.horizontal, 16)
    }

    private var actionButtonLabel: String {
        switch viewModel.phase {
        case .betting, .result:
            return viewModel.canDeal ? "DEAL" : "ADD FUNDS"
        case .dealt:
            return "DRAW"
        case .drawing:
            return "..."
        }
    }

    private var actionButtonEnabled: Bool {
        switch viewModel.phase {
        case .betting, .result:
            return viewModel.canDeal
        case .dealt:
            return true
        case .drawing:
            return false
        }
    }

    private func displayCardForIndex(_ index: Int) -> Card {
        if viewModel.phase == .result, let lastResult = viewModel.lineResults.last {
            return lastResult.finalHand[index].toCard()
        }
        return viewModel.dealtCards[index]
    }

    private var gridResults: [PlayHandResult] {
        guard viewModel.lineResults.count > 1 else { return [] }
        return Array(viewModel.lineResults.dropLast())
    }

    private var mainHandResult: PlayHandResult? {
        viewModel.lineResults.last
    }

    // MARK: - Win Badge

    @ViewBuilder
    private func mainHandWinBadge(result: PlayHandResult) -> some View {
        if let handName = result.handName, result.payout > 0 {
            let badgeColors = winBadgeColors(for: handName)
            let payoutDollars = Double(result.payout) * viewModel.settings.denomination.rawValue
            HStack(spacing: 6) {
                Text(handName.uppercased())
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.white)
                Text("+\(formatCurrency(payoutDollars))")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
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
            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
        }
    }

    private func winBadgeColors(for handName: String) -> [Color] {
        switch handName {
        case "Jacks or Better", "Tens or Better":
            return [Color(hex: "B388FF"), Color(hex: "9575CD")]
        case "Two Pair":
            return [Color(hex: "81D4FA"), Color(hex: "4FC3F7")]
        case "Three of a Kind":
            return [Color(hex: "FFEE58"), Color(hex: "FDD835")]
        case "Straight":
            return [Color(hex: "F06292"), Color(hex: "EC407A")]
        case "Flush":
            return [Color(hex: "66BB6A"), Color(hex: "43A047")]
        case "Full House":
            return [Color(hex: "5C6BC0"), Color(hex: "3F51B5")]
        case _ where handName.contains("Four"):
            return [Color(hex: "F8BBD9"), Color(hex: "F48FB1")]
        case "Straight Flush":
            return [Color(hex: "7E57C2"), Color(hex: "5E35B1")]
        case "Royal Flush", "Natural Royal", "Wild Royal":
            return [Color(hex: "EF5350"), Color(hex: "E53935")]
        default:
            return [Color(hex: "FFD700"), Color(hex: "FFA500")]
        }
    }

    // MARK: - EV Options Table

    private var evOptionsTable: some View {
        Group {
            if let result = viewModel.strategyResult {
                let hand = Hand(cards: viewModel.dealtCards)
                let userHold = Array(viewModel.selectedIndices).sorted()
                let userCanonicalHold = hand.originalIndicesToCanonical(userHold)
                let options = result.sortedHoldOptionsPrioritizingUser(userCanonicalHold)
                // Limit to top 3 options for readability
                let topOptions = Array(options.prefix(3))

                VStack(spacing: 6) {
                    // Table header
                    HStack {
                        Text("#")
                            .font(.system(size: 13, weight: .bold))
                            .frame(width: 28, alignment: .leading)
                        Text("HOLD")
                            .font(.system(size: 13, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("EXP. VALUE")
                            .font(.system(size: 13, weight: .bold))
                            .frame(width: 85, alignment: .trailing)
                    }
                    .foregroundColor(Color(hex: "888888"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)

                    // Table rows (top 3 only)
                    ForEach(Array(topOptions.enumerated()), id: \.offset) { index, option in
                        let optionOriginalIndices = hand.canonicalIndicesToOriginal(option.indices)
                        let optionCards = optionOriginalIndices.map { viewModel.dealtCards[$0] }
                        let rank = result.rankForOption(at: index, inUserPrioritizedList: options)
                        let isBest = rank == 1
                        let isUserSelection = userCanonicalHold.sorted() == option.indices.sorted()

                        HStack(spacing: 6) {
                            Text("\(rank)")
                                .font(.system(size: 16, weight: isBest ? .bold : .medium, design: .monospaced))
                                .frame(width: 28, alignment: .leading)

                            if optionCards.isEmpty {
                                Text("Draw all")
                                    .font(.system(size: 16, weight: .medium))
                                    .italic()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                HStack(spacing: 4) {
                                    ForEach(optionCards, id: \.id) { card in
                                        Text(card.displayText)
                                            .font(.system(size: 16, weight: isBest ? .bold : .medium))
                                            .foregroundColor(card.suit.textColor(for: colorScheme))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            let dollarEv = option.ev * viewModel.settings.totalBetDollars
                            Text(formatCurrency(dollarEv))
                                .font(.system(size: 16, weight: isBest ? .bold : .medium, design: .monospaced))
                                .frame(width: 85, alignment: .trailing)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            isUserSelection
                                ? (isBest ? Color(hex: "00aa00").opacity(0.3) : Color(hex: "FFA726").opacity(0.3))
                                : (isBest ? Color(hex: "667eea").opacity(0.2) : Color.black.opacity(0.2))
                        )
                        .cornerRadius(6)
                    }
                }
            }
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

                        VStack(spacing: 4) {
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
                    sessionStatsCard
                    allTimeStatsCard
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
