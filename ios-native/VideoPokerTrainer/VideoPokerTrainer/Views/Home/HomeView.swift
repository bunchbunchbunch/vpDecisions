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
    @State private var showInDevelopment = false
    @State private var showClearStrategyAlert = false
    @State private var strategyCleared = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 20) {
                    // Branded header
                    brandedHeader

                    // Main action buttons
                    actionButtons
                }
                .padding()
            }
            .withTour(.home)
            .task {
                // Sync any pending hand attempts from previous offline sessions
                await SyncService.shared.syncPendingAttempts()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    accountMenu
                }
            }
            .navigationDestination(for: AppScreen.self) { screen in
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
                }
            }
        }
    }

    // MARK: - Subviews

    private var brandedHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("VP Academy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.Gradients.primary)
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private var accountMenu: some View {
        Menu {
            // User email (non-interactive label)
            Section {
                Label(authViewModel.currentUser?.email ?? "User", systemImage: "envelope")
            }

            // Settings
            Button {
                navigationPath.append(AppScreen.settings)
            } label: {
                Label("Settings", systemImage: "gearshape")
            }

            Divider()

            // Sign Out
            Button(role: .destructive) {
                Task {
                    await authViewModel.signOut()
                }
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            Circle()
                .fill(Color(hex: "667eea").opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(authViewModel.currentUser?.email?.prefix(1).uppercased() ?? "?"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "667eea"))
                )
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Row 1: Play Mode (featured)
            ActionButton(
                title: "Play Mode",
                icon: "suit.spade.fill",
                color: Color(hex: "9b59b6")
            ) {
                navigationPath.append(AppScreen.playStart)
            }
            .tourTarget("playModeButton")

            // Row 2: Quiz and Analyzer
            HStack(spacing: 12) {
                ActionButton(
                    title: "Quiz Mode",
                    icon: "target",
                    color: Color(hex: "667eea")
                ) {
                    weakSpotsMode = false
                    navigationPath.append(AppScreen.quizStart)
                }
                .tourTarget("quizModeButton")

                ActionButton(
                    title: "Analyzer",
                    icon: "magnifyingglass",
                    color: Color(hex: "3498db")
                ) {
                    navigationPath.append(AppScreen.analyzer)
                }
                .tourTarget("analyzerButton")
            }

            // In Development Section
            inDevelopmentSection
        }
    }

    private var inDevelopmentSection: some View {
        VStack(spacing: 12) {
            // Collapsible header
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showInDevelopment.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "hammer.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("In Development")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Spacer()

                    Image(systemName: showInDevelopment ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)

            // Expandable content
            if showInDevelopment {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ActionButton(
                            title: "Weak Spots",
                            icon: "flame.fill",
                            color: Color(hex: "e74c3c")
                        ) {
                            weakSpotsMode = true
                            navigationPath.append(AppScreen.weakSpots)
                        }

                        ActionButton(
                            title: "Progress",
                            icon: "chart.bar.fill",
                            color: Color(hex: "27ae60")
                        ) {
                            navigationPath.append(AppScreen.mastery)
                        }
                    }

                    // Clear Strategy Cache button
                    Button {
                        showClearStrategyAlert = true
                    } label: {
                        HStack {
                            Image(systemName: strategyCleared ? "checkmark.circle.fill" : "arrow.counterclockwise")
                                .foregroundColor(strategyCleared ? .green : .orange)
                            Text(strategyCleared ? "Strategy Cache Cleared" : "Clear Strategy Cache")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(strategyCleared ? .green : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .alert("Clear Strategy Cache?", isPresented: $showClearStrategyAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Clear", role: .destructive) {
                            Task {
                                await LocalStrategyStore.shared.deleteAllData()
                                strategyCleared = true
                                // Reset after 3 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    strategyCleared = false
                                }
                            }
                        }
                    } message: {
                        Text("This will delete all decompressed strategy data. The bundled strategies will be re-decompressed on next use.")
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Action Button Component

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Icon with background circle
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: AppTheme.Layout.iconSizeMedium, height: AppTheme.Layout.iconSizeMedium)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusLarge)
                    .fill(Color(.systemBackground))
                    .shadow(color: color.opacity(0.15), radius: 8, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusLarge)
                    .stroke(color.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
                // Game selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Game")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

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
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    // 10 hands
                    Button {
                        selectedQuizSize = 10
                    } label: {
                        Text("10")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(weakSpotsMode ? Color(hex: "e74c3c") : Color(hex: "667eea"))
                    .opacity(selectedQuizSize == 10 ? 1.0 : 0.5)
                    .background(
                        selectedQuizSize == 10 ? (weakSpotsMode ? Color(hex: "e74c3c") : Color(hex: "667eea")).opacity(0.15) : Color.clear
                    )
                    .cornerRadius(10)

                    // 25 hands (default)
                    Button {
                        selectedQuizSize = 25
                    } label: {
                        Text("25")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(weakSpotsMode ? Color(hex: "e74c3c") : Color(hex: "667eea"))
                    .opacity(selectedQuizSize == 25 ? 1.0 : 0.5)
                    .background(
                        selectedQuizSize == 25 ? (weakSpotsMode ? Color(hex: "e74c3c") : Color(hex: "667eea")).opacity(0.15) : Color.clear
                    )
                    .cornerRadius(10)

                    // 100 hands
                    Button {
                        selectedQuizSize = 100
                    } label: {
                        Text("100")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(weakSpotsMode ? Color(hex: "e74c3c") : Color(hex: "667eea"))
                    .opacity(selectedQuizSize == 100 ? 1.0 : 0.5)
                    .background(
                        selectedQuizSize == 100 ? (weakSpotsMode ? Color(hex: "e74c3c") : Color(hex: "667eea")).opacity(0.15) : Color.clear
                    )
                    .cornerRadius(10)
                }
            }
            .tourTarget("quizSizeSelector")
            .padding(.horizontal)

            Spacer()

            // Start Quiz button
            Button {
                Task {
                    // Check if offline and game not available
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
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(weakSpotsMode ? Color(hex: "e74c3c") : Color(hex: "667eea"))
            .tourTarget("startQuizButton")
            .padding(.horizontal)

            Button("Back to Menu") {
                navigationPath.removeLast()
            }
            .foregroundColor(.secondary)

            Spacer()
        }
        .withTour(.quizStart)
        .navigationTitle(weakSpotsMode ? "Weak Spots" : "Quiz")
        .navigationBarTitleDisplayMode(.inline)
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
