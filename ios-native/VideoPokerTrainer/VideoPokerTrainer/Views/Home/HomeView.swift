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
                ToolbarItem(placement: .navigationBarLeading) {
                    headerLogo
                }
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

            // Level badges
            HStack(spacing: 8) {
                LevelBadge(text: "Level 12", color: AppTheme.Colors.mintGreen)
                LevelBadge(text: "Professional", color: AppTheme.Colors.mintGreen)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Play Mode Card

    private var playModeCard: some View {
        Button {
            navigationPath.append(AppScreen.playStart)
        } label: {
            HStack {
                // Poker chips icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "C41E3A"))
                        .frame(width: 50, height: 50)
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 40, height: 40)
                    Circle()
                        .fill(Color(hex: "C41E3A"))
                        .frame(width: 35, height: 35)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Play Mode")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Sharpen your strategy and play smarter.")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                Spacer()

                Text("PLAY")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.darkGreen)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(16)
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
                    icon: "target",
                    iconColor: Color(hex: "F5A623"),
                    title: "Quiz Mode",
                    subtitle: "Lorem Ipsum"
                ) {
                    weakSpotsMode = false
                    navigationPath.append(AppScreen.quizStart)
                }
                .tourTarget("quizModeButton")

                // Analyze
                FeatureCard(
                    icon: "magnifyingglass",
                    iconColor: AppTheme.Colors.mintGreen,
                    title: "Analyze",
                    subtitle: "Lorem Ipsum"
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
                            icon: "flame.fill",
                            iconColor: Color(hex: "E74C3C"),
                            title: "Weak Spots",
                            subtitle: "Lorem Ipsum"
                        ) {
                            weakSpotsMode = true
                            navigationPath.append(AppScreen.weakSpots)
                        }

                        // Progress
                        FeatureCard(
                            icon: "suit.club.fill",
                            iconColor: Color(hex: "E74C3C"),
                            title: "Progress",
                            subtitle: "Lorem Ipsum",
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
            SettingsView()
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
    let icon: String
    let iconColor: Color
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
                } else {
                    // Circle icon
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
    @State private var selectedQuizSize: Int = 25
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var showOfflineAlert = false

    var body: some View {
        ZStack {
            AppTheme.Gradients.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Gradient header card
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusXL)
                        .fill(weakSpotsMode ? AppTheme.Gradients.red : AppTheme.Gradients.primary)
                        .frame(height: 140)

                    VStack(spacing: 8) {
                        Image(systemName: weakSpotsMode ? "flame.fill" : "target")
                            .font(.system(size: 44))
                            .foregroundColor(.white)

                        Text(weakSpotsMode ? "Weak Spots Mode" : "Quiz Mode")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Test your video poker strategy")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Settings
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Game")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.Colors.textSecondary)

                        GameSelectorView(selectedPaytableId: $selectedPaytableId)
                            .onChange(of: selectedPaytableId) { _, newValue in
                                if let paytable = PayTable.allPayTables.first(where: { $0.id == newValue }) {
                                    selectedPaytable = paytable
                                }
                            }
                    }
                    .tourTarget("quizGameSelector")
                    .onAppear {
                        selectedPaytableId = selectedPaytable.id
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Quiz size selection
                VStack(spacing: 12) {
                    Text("Quiz Size")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    HStack(spacing: 12) {
                        ForEach([10, 25, 100], id: \.self) { size in
                            Button {
                                selectedQuizSize = size
                            } label: {
                                Text("\(size)")
                                    .font(.headline)
                                    .foregroundColor(selectedQuizSize == size ? AppTheme.Colors.darkGreen : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        selectedQuizSize == size ? AppTheme.Colors.mintGreen : AppTheme.Colors.cardBackground
                                    )
                                    .cornerRadius(20)
                            }
                        }
                    }
                }
                .tourTarget("quizSizeSelector")
                .padding(.horizontal)

                Spacer()

                // Start Quiz button
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
                .padding(.horizontal)

                Button("Back to Menu") {
                    navigationPath.removeLast()
                }
                .foregroundColor(AppTheme.Colors.mintGreen)
                .underline()

                Spacer()
            }
        }
        .withTour(.quizStart)
        .navigationTitle(weakSpotsMode ? "Weak Spots" : "Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
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
