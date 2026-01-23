import SwiftUI

enum AppScreen: Hashable {
    case quizStart
    case quizPlay(paytableId: String, weakSpotsMode: Bool, quizSize: Int)
    case quizResults
    case mastery
    case analyzer
    case settings
    case weakSpots
    case playStart
    case playGame
    case simulationStart
}

struct HomeView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var navigationPath = NavigationPath()
    @State private var selectedPaytable = PayTable.jacksOrBetter96 {
        didSet {
            NSLog("🏠 HomeView selectedPaytable changed to: %@ - %@", selectedPaytable.id, selectedPaytable.name)
        }
    }
    @State private var weakSpotsMode = false
    @State private var showBetaFeatures = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Background gradient
                AppTheme.Gradients.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Welcome section
                        welcomeSection

                        // Play Mode - Featured card
                        playModeCard

                        // Training Mode section
                        trainingModeSection

                        // Features in Beta section
                        betaFeaturesSection
                    }
                    .padding()
                }
            }
            .withTour(.home)
            .task {
                await SyncService.shared.syncPendingAttempts()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    profileButton
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(for: AppScreen.self) { screen in
                destinationView(for: screen)
            }
            .navigationDestination(for: SimulationViewModel.self) { vm in
                SimulationContainerView(viewModel: vm, navigationPath: $navigationPath)
            }
        }
    }

    // MARK: - Header

    private var headerLogo: some View {
        HStack(spacing: 8) {
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundColor(AppTheme.Colors.mintGreen)

            VStack(alignment: .leading, spacing: 0) {
                Text("Video Poker")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text("Academy")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }

    private var profileButton: some View {
        Button {
            navigationPath.append(AppScreen.settings)
        } label: {
            Circle()
                .fill(AppTheme.Colors.cardBackground)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                )
        }
    }

    // MARK: - Welcome Section

    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome Back!")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            Text(authViewModel.currentUser?.email?.components(separatedBy: "@").first ?? "Player")
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Play Mode Card

    private var playModeCard: some View {
        Button {
            navigationPath.append(AppScreen.playStart)
        } label: {
            HStack {
                // Red chip icon
                Image("chip-red")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Play Mode")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Simulate your favorite video poker games.")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.Colors.cardBackground)
            )
        }
        .buttonStyle(.plain)
        .tourTarget("playModeButton")
    }

    // MARK: - Training Mode Section

    private var trainingModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Mode")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            Text("Sharpen your strategy and play smarter.")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.Colors.textSecondary)

            HStack(spacing: 12) {
                // Quiz Mode
                FeatureCard(
                    chipImage: "chip-gold",
                    title: "Quiz Mode",
                    subtitle: "Test yourself on optimal strategy."
                ) {
                    weakSpotsMode = false
                    navigationPath.append(AppScreen.quizStart)
                }
                .tourTarget("quizModeButton")

                // Analyze
                FeatureCard(
                    chipImage: "chip-blue",
                    title: "Analyze",
                    subtitle: "See the optimal strategy for a specific hand."
                ) {
                    navigationPath.append(AppScreen.analyzer)
                }
                .tourTarget("analyzerButton")
            }
        }
    }

    // MARK: - Beta Features Section

    private var betaFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Collapsible header
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showBetaFeatures.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    Text("Features in Beta")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    Spacer()

                    Image(systemName: showBetaFeatures ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(12)
            }

            // Expandable content
            if showBetaFeatures {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Available in beta. Expect improvements.")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    HStack(spacing: 12) {
                        // Weak Spots
                        FeatureCard(
                            chipImage: "chip-black",
                            title: "Weak Spots",
                            subtitle: "Practice your problem hands."
                        ) {
                            weakSpotsMode = true
                            navigationPath.append(AppScreen.weakSpots)
                        }

                        // Progress
                        FeatureCard(
                            title: "Progress",
                            subtitle: "Track your mastery.",
                            showCards: true
                        ) {
                            navigationPath.append(AppScreen.mastery)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Navigation Destinations

    @ViewBuilder
    private func destinationView(for screen: AppScreen) -> some View {
        switch screen {
        case .quizStart:
            QuizStartView(
                navigationPath: $navigationPath,
                selectedPaytable: $selectedPaytable,
                weakSpotsMode: $weakSpotsMode
            )
        case .quizPlay(let paytableId, let weakSpotsMode, let quizSize):
            QuizPlayView(
                viewModel: QuizViewModel(
                    paytableId: paytableId,
                    weakSpotsMode: weakSpotsMode,
                    quizSize: quizSize
                ),
                navigationPath: $navigationPath
            )
        case .quizResults:
            Text("Quiz Results - navigated from quiz")
        case .mastery:
            MasteryDashboardView(
                viewModel: MasteryViewModel(paytableId: selectedPaytable.id),
                navigationPath: $navigationPath
            )
        case .analyzer:
            HandAnalyzerView()
        case .settings:
            SettingsView(authViewModel: authViewModel)
        case .weakSpots:
            QuizStartView(
                navigationPath: $navigationPath,
                selectedPaytable: $selectedPaytable,
                weakSpotsMode: .constant(true)
            )
        case .playStart:
            PlayStartView(navigationPath: $navigationPath)
        case .playGame:
            PlayView(navigationPath: $navigationPath)
        case .simulationStart:
            SimulationStartView(navigationPath: $navigationPath)
        }
    }
}

// MARK: - Level Badge

struct LevelBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    var icon: String = ""
    var iconColor: Color = .white
    var chipImage: String? = nil
    let title: String
    let subtitle: String
    var showCards: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                if showCards {
                    // Mini cards display for Progress
                    HStack(spacing: -8) {
                        MiniCardIcon(suit: "heart", color: .red)
                        MiniCardIcon(suit: "diamond", color: .red)
                        MiniCardIcon(suit: "club", color: .black)
                        MiniCardIcon(suit: "spade", color: .black)
                    }
                } else if let chipImage = chipImage {
                    // Chip image
                    Image(chipImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                } else {
                    // Circle icon (fallback)
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.2))
                            .frame(width: 50, height: 50)

                        Image(systemName: icon)
                            .font(.system(size: 22))
                            .foregroundColor(iconColor)
                    }
                }

                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.Colors.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mini Card Icon

struct MiniCardIcon: View {
    let suit: String
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.white)
            .frame(width: 28, height: 38)
            .overlay(
                Image(systemName: "suit.\(suit).fill")
                    .font(.system(size: 14))
                    .foregroundColor(color)
            )
            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
    }
}

// MARK: - Quiz Start View

struct QuizStartView: View {
    @Binding var navigationPath: NavigationPath
    @Binding var selectedPaytable: PayTable
    @Binding var weakSpotsMode: Bool

    @State private var selectedPaytableId: String = PayTable.jacksOrBetter96.id
    @State private var selectedFamily: GameFamily = .jacksOrBetter
    @State private var selectedQuizSize: Int = 25
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var showOfflineAlert = false

    // Longest family name to establish dropdown width
    private var longestFamilyName: String {
        GameFamily.allCases.map(\.displayName).max(by: { $0.count < $1.count }) ?? ""
    }

    private var selectedVariantName: String {
        PayTable.allPayTables.first { $0.id == selectedPaytableId }?.variantName ?? "Select Variant"
    }

    var body: some View {
        ZStack {
            AppTheme.Gradients.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Gradient header card
                    ZStack {
                        RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusXL)
                            .fill(weakSpotsMode ? AppTheme.Gradients.red : AppTheme.Gradients.primary)
                            .frame(height: 140)

                        VStack(spacing: 8) {
                            Image(weakSpotsMode ? "chip-black" : "chip-gold")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)

                            Text(weakSpotsMode ? "Weak Spots" : "Quiz Mode")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text(weakSpotsMode ? "Practice your problem hands." : "Test yourself on optimal strategy.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }

                    // Popular Games
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Popular Games")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)

                        FlowLayout(spacing: 8) {
                            ForEach(PayTable.popularPaytables, id: \.id) { game in
                                GameChip(
                                    title: game.name,
                                    isSelected: selectedPaytableId == game.id
                                ) {
                                    selectedPaytableId = game.id
                                    selectedFamily = game.family
                                    selectedPaytable = game
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .tourTarget("quizGameSelector")

                    // All Games
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
                                        let familyPaytables = PayTable.paytables(for: family)
                                        if !familyPaytables.contains(where: { $0.id == selectedPaytableId }),
                                           let first = familyPaytables.first {
                                            selectedPaytableId = first.id
                                            selectedPaytable = first
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
                                    ZStack(alignment: .leading) {
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
                                        selectedPaytableId = paytable.id
                                        selectedPaytable = paytable
                                    } label: {
                                        HStack {
                                            Text(paytable.variantName)
                                            if selectedPaytableId == paytable.id {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    ZStack(alignment: .leading) {
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

                    // Quiz size selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quiz Size")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)

                        HStack(spacing: 8) {
                            ForEach([10, 25, 100], id: \.self) { size in
                                SelectionChip(
                                    title: "\(size)",
                                    isSelected: selectedQuizSize == size
                                ) {
                                    selectedQuizSize = size
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .tourTarget("quizSizeSelector")

                    Spacer(minLength: 20)

                    // Start Quiz button
                    VStack(spacing: 12) {
                        Button {
                            Task {
                                if !networkMonitor.isOnline {
                                    let isAvailable = await StrategyService.shared.hasOfflineData(paytableId: selectedPaytable.id)
                                    if !isAvailable {
                                        showOfflineAlert = true
                                        return
                                    }
                                }

                                NSLog("🚀 QuizStartView: Starting %d-hand quiz with paytable: %@ - %@", selectedQuizSize, selectedPaytable.id, selectedPaytable.name)
                                navigationPath.append(AppScreen.quizPlay(
                                    paytableId: selectedPaytable.id,
                                    weakSpotsMode: weakSpotsMode,
                                    quizSize: selectedQuizSize
                                ))
                            }
                        } label: {
                            Text("Start Quiz")
                                .primaryButton()
                        }
                        .tourTarget("startQuizButton")

                        Button("Back to Menu") {
                            navigationPath.removeLast()
                        }
                        .foregroundColor(AppTheme.Colors.mintGreen)
                        .underline()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
        }
        .withTour(.quizStart)
        .navigationTitle(weakSpotsMode ? "Weak Spots" : "Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(weakSpotsMode ? "Weak Spots" : "Quiz Mode")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            selectedPaytableId = selectedPaytable.id
            if let paytable = PayTable.allPayTables.first(where: { $0.id == selectedPaytableId }) {
                selectedFamily = paytable.family
            }
        }
        .alert("Game Not Available Offline", isPresented: $showOfflineAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This game hasn't been downloaded yet. Please connect to the internet to download it, or choose a different game.")
        }
    }
}

#Preview {
    HomeView(authViewModel: AuthViewModel())
}
