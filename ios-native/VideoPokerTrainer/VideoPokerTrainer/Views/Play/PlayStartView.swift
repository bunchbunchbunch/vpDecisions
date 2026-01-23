import SwiftUI

struct PlayStartView: View {
    @Binding var navigationPath: NavigationPath
    @State private var settings = PlaySettings()
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var showOfflineAlert = false
    @State private var selectedFamily: GameFamily = .jacksOrBetter

    var body: some View {
        ZStack {
            AppTheme.Gradients.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with chip icon
                    headerSection

                    // Popular Games
                    popularGamesSection

                    // All Games dropdown
                    allGamesSection

                    // Lines selection
                    linesSection

                    // Denomination selection
                    denominationSection

                    // Optimal feedback toggle
                    optimalFeedbackToggle

                    Spacer(minLength: 20)

                    // Start button
                    startButtonSection
                        .frame(maxWidth: .infinity)
                }
                .padding()
            }
        }
        .withTour(.playStart)
        .navigationTitle("Play Mode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Play Mode")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .task {
            settings = await PlayPersistence.shared.loadSettings()
        }
        .alert("Game Not Available Offline", isPresented: $showOfflineAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This game hasn't been downloaded yet. Please connect to the internet to download it, or choose a different game.")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 16) {
            // Red chip icon
            Image("chip-red")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text("Play Mode")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text("Simulate your favorite video poker games.")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Popular Games

    private var popularGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular Games")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)

            FlowLayout(spacing: 8) {
                ForEach(PayTable.popularPaytables, id: \.id) { game in
                    GameChip(
                        title: game.name,
                        isSelected: settings.selectedPaytableId == game.id
                    ) {
                        settings.selectedPaytableId = game.id
                        // Sync the family dropdown
                        selectedFamily = game.family
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tourTarget("gameSelector")
    }

    // MARK: - All Games

    private var allGamesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("All Games")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)

            HStack(spacing: 8) {
                // Game Family dropdown
                Menu {
                    ForEach(GameFamily.allCases) { family in
                        Button {
                            selectedFamily = family
                            // Auto-select first paytable in family if current isn't in it
                            let familyPaytables = PayTable.paytables(for: family)
                            if !familyPaytables.contains(where: { $0.id == settings.selectedPaytableId }),
                               let first = familyPaytables.first {
                                settings.selectedPaytableId = first.id
                            }
                        } label: {
                            HStack {
                                Text(family.displayName)
                                if selectedFamily == family {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        // Use ZStack with hidden longest text to establish minimum width
                        ZStack(alignment: .leading) {
                            // Hidden text of longest option to set minimum width
                            Text(longestFamilyName)
                                .font(.system(size: 15))
                                .hidden()

                            Text(selectedFamily.displayName)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.Colors.cardBackground)
                    )
                }

                // Paytable variant dropdown
                Menu {
                    ForEach(PayTable.paytables(for: selectedFamily), id: \.id) { paytable in
                        Button {
                            settings.selectedPaytableId = paytable.id
                        } label: {
                            HStack {
                                Text(paytable.variantName)
                                if settings.selectedPaytableId == paytable.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        // Use ZStack with hidden longest text to establish minimum width
                        ZStack(alignment: .leading) {
                            // Hidden text to set minimum width for variant names
                            Text("9/6 (94.0%)")
                                .font(.system(size: 15))
                                .hidden()

                            Text(selectedVariantName)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.Colors.cardBackground)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            // Initialize selected family based on current paytable
            if let paytable = PayTable.allPayTables.first(where: { $0.id == settings.selectedPaytableId }) {
                selectedFamily = paytable.family
            }
        }
    }

    // Longest family name to establish dropdown width
    private var longestFamilyName: String {
        GameFamily.allCases.map(\.displayName).max(by: { $0.count < $1.count }) ?? ""
    }

    private var selectedVariantName: String {
        PayTable.allPayTables.first { $0.id == settings.selectedPaytableId }?.variantName ?? "Select Variant"
    }

    // MARK: - Lines Section

    private var linesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lines")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)

            HStack(spacing: 8) {
                ForEach(LineCount.allCases, id: \.self) { lineCount in
                    SelectionChip(
                        title: lineCount.displayName,
                        isSelected: settings.lineCount == lineCount
                    ) {
                        settings.lineCount = lineCount
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tourTarget("linesSelector")
    }

    // MARK: - Denomination Section

    private var denominationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Denomination")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)

            HStack(spacing: 8) {
                ForEach(BetDenomination.allCases, id: \.self) { denom in
                    SelectionChip(
                        title: denom.displayName,
                        isSelected: settings.denomination == denom
                    ) {
                        settings.denomination = denom
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tourTarget("denominationSelector")
    }

    // MARK: - Optimal Feedback Toggle

    private var optimalFeedbackToggle: some View {
        HStack {
            Image(systemName: "eye")
                .font(.system(size: 18))
                .foregroundColor(AppTheme.Colors.textSecondary)

            Text("Show Optimal Play Feedback")
                .font(.system(size: 15))
                .foregroundColor(.white)

            Spacer()

            Toggle("", isOn: $settings.showOptimalFeedback)
                .labelsHidden()
                .tint(AppTheme.Colors.mintGreen)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.cardBackground)
        )
        .tourTarget("optimalFeedbackToggle")
    }

    // MARK: - Start Button

    private var startButtonSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    if !networkMonitor.isOnline {
                        let isAvailable = await StrategyService.shared.hasOfflineData(paytableId: settings.selectedPaytableId)
                        if !isAvailable {
                            showOfflineAlert = true
                            return
                        }
                    }

                    await PlayPersistence.shared.saveSettings(settings)
                    navigationPath.append(AppScreen.playGame)
                }
            } label: {
                Text("Start Playing")
                    .primaryButton()
            }

            Button("Back to Menu") {
                navigationPath.removeLast()
            }
            .foregroundColor(AppTheme.Colors.mintGreen)
            .underline()
        }
    }
}

// MARK: - Selection Chip

struct SelectionChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? AppTheme.Colors.darkGreen : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? AppTheme.Colors.mintGreen : AppTheme.Colors.cardBackground)
                )
        }
    }
}

// MARK: - Game Chip

struct GameChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? AppTheme.Colors.darkGreen : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? AppTheme.Colors.mintGreen : AppTheme.Colors.cardBackground)
                )
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        let containerWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX - spacing)
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

#Preview {
    NavigationStack {
        PlayStartView(navigationPath: .constant(NavigationPath()))
    }
}
