import SwiftUI

enum AppScreen: Hashable {
    case quizStart
    case quizPlay(paytableId: String, weakSpotsMode: Bool, closeDecisionsOnly: Bool, quizSize: Int)
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
    @State private var selectedPaytable = PayTable.jacksOrBetter {
        didSet {
            NSLog("🏠 HomeView selectedPaytable changed to: %@ - %@", selectedPaytable.id, selectedPaytable.name)
        }
    }
    @State private var closeDecisionsOnly = false
    @State private var weakSpotsMode = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 20) {
                    // User profile bar
                    userProfileBar

                    // Overall mastery card
                    masteryCard

                    // Main action buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("VP Trainer")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: AppScreen.self) { screen in
                switch screen {
                case .quizStart:
                    QuizStartView(
                        navigationPath: $navigationPath,
                        selectedPaytable: $selectedPaytable,
                        closeDecisionsOnly: $closeDecisionsOnly,
                        weakSpotsMode: $weakSpotsMode
                    )
                case .quizPlay(let paytableId, let weakSpotsMode, let closeDecisionsOnly, let quizSize):
                    QuizPlayView(
                        viewModel: QuizViewModel(
                            paytableId: paytableId,
                            weakSpotsMode: weakSpotsMode,
                            closeDecisionsOnly: closeDecisionsOnly,
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
                        closeDecisionsOnly: $closeDecisionsOnly,
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

    private var userProfileBar: some View {
        HStack {
            // Avatar placeholder
            Circle()
                .fill(Color(hex: "667eea").opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(authViewModel.currentUser?.email?.prefix(1).uppercased() ?? "?"))
                        .font(.headline)
                        .foregroundColor(Color(hex: "667eea"))
                )

            VStack(alignment: .leading) {
                Text(authViewModel.currentUser?.email ?? "User")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()

            Button("Sign Out") {
                Task {
                    await authViewModel.signOut()
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private var masteryCard: some View {
        Button {
            navigationPath.append(AppScreen.mastery)
        } label: {
            VStack(spacing: 8) {
                Text("Overall Mastery")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("--")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Color(hex: "667eea"))

                Text("Tap to view progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
        .buttonStyle(.plain)
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

            // Row 2: Quiz and Weak Spots
            HStack(spacing: 12) {
                ActionButton(
                    title: "Quiz Mode",
                    icon: "target",
                    color: Color(hex: "667eea")
                ) {
                    weakSpotsMode = false
                    navigationPath.append(AppScreen.quizStart)
                }

                ActionButton(
                    title: "Weak Spots",
                    icon: "flame.fill",
                    color: Color(hex: "e74c3c")
                ) {
                    weakSpotsMode = true
                    navigationPath.append(AppScreen.weakSpots)
                }
            }

            // Row 3: Progress and Analyzer
            HStack(spacing: 12) {
                ActionButton(
                    title: "Progress",
                    icon: "chart.bar.fill",
                    color: Color(hex: "27ae60")
                ) {
                    navigationPath.append(AppScreen.mastery)
                }

                ActionButton(
                    title: "Analyzer",
                    icon: "magnifyingglass",
                    color: Color(hex: "3498db")
                ) {
                    navigationPath.append(AppScreen.analyzer)
                }
            }

            // Row 4: Settings (full width)
            ActionButton(
                title: "Settings",
                icon: "gearshape.fill",
                color: Color(hex: "95a5a6")
            ) {
                navigationPath.append(AppScreen.settings)
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
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quiz Start View

struct QuizStartView: View {
    @Binding var navigationPath: NavigationPath
    @Binding var selectedPaytable: PayTable
    @Binding var closeDecisionsOnly: Bool
    @Binding var weakSpotsMode: Bool

    @State private var selectedPaytableId: String = PayTable.jacksOrBetter.id
    @State private var selectedQuizSize: Int = 25

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Title
            VStack(spacing: 8) {
                Image(systemName: weakSpotsMode ? "flame.fill" : "target")
                    .font(.system(size: 50))
                    .foregroundColor(weakSpotsMode ? Color(hex: "e74c3c") : Color(hex: "667eea"))

                Text(weakSpotsMode ? "Weak Spots Mode" : "Quiz Mode")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Test your video poker strategy")
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Settings
            VStack(spacing: 16) {
                // Paytable picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Game Type")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Picker("Paytable", selection: $selectedPaytableId) {
                        ForEach(PayTable.allPayTables, id: \.id) { paytable in
                            Text(paytable.name).tag(paytable.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .onChange(of: selectedPaytableId) { newValue in
                        NSLog("🎯 Picker changed to ID: %@", newValue)
                        if let paytable = PayTable.allPayTables.first(where: { $0.id == newValue }) {
                            selectedPaytable = paytable
                            NSLog("🎯 Updated selectedPaytable to: %@ - %@", paytable.id, paytable.name)
                        }
                    }
                }
                .onAppear {
                    selectedPaytableId = selectedPaytable.id
                }

                // Close decisions toggle
                Toggle("Close Decisions Only", isOn: $closeDecisionsOnly)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
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
            .padding(.horizontal)

            Spacer()

            // Start Quiz button
            Button {
                NSLog("🚀 QuizStartView: Starting %d-hand quiz with paytable: %@ - %@", selectedQuizSize, selectedPaytable.id, selectedPaytable.name)
                navigationPath.append(AppScreen.quizPlay(
                    paytableId: selectedPaytable.id,
                    weakSpotsMode: weakSpotsMode,
                    closeDecisionsOnly: closeDecisionsOnly,
                    quizSize: selectedQuizSize
                ))
            } label: {
                Text("Start Quiz")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(weakSpotsMode ? Color(hex: "e74c3c") : Color(hex: "667eea"))
            .padding(.horizontal)

            Button("Back to Menu") {
                navigationPath.removeLast()
            }
            .foregroundColor(.secondary)

            Spacer()
        }
        .navigationTitle(weakSpotsMode ? "Weak Spots" : "Quiz")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    HomeView(authViewModel: AuthViewModel())
}
