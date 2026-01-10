import SwiftUI

struct PlayStartView: View {
    @Binding var navigationPath: NavigationPath
    @State private var settings = PlaySettings()
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var showOfflineAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // Gradient header card
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusXL)
                    .fill(AppTheme.Gradients.purple)
                    .frame(height: 140)

                VStack(spacing: 8) {
                    Image(systemName: "suit.spade.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)

                    Text("Play Mode")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Simulate real video poker")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 20)

            // Settings section
            VStack(spacing: 16) {
                // Game selector
                VStack(alignment: .leading, spacing: 6) {
                    Text("Game")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    GameSelectorView(selectedPaytableId: $settings.selectedPaytableId)
                }
                .tourTarget("gameSelector")

                // Line count
                VStack(alignment: .leading, spacing: 6) {
                    Text("Lines")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 10) {
                        ForEach(LineCount.allCases, id: \.self) { lineCount in
                            Button {
                                settings.lineCount = lineCount
                            } label: {
                                Text(lineCount.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.bordered)
                            .tint(Color(hex: "9b59b6"))
                            .opacity(settings.lineCount == lineCount ? 1.0 : 0.5)
                            .background(
                                settings.lineCount == lineCount
                                    ? Color(hex: "9b59b6").opacity(0.15)
                                    : Color.clear
                            )
                            .cornerRadius(10)
                        }
                    }
                }
                .tourTarget("linesSelector")

                // Denomination
                VStack(alignment: .leading, spacing: 6) {
                    Text("Denomination")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(BetDenomination.allCases, id: \.self) { denom in
                            Button {
                                settings.denomination = denom
                            } label: {
                                Text(denom.displayName)
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.bordered)
                            .tint(Color(hex: "9b59b6"))
                            .opacity(settings.denomination == denom ? 1.0 : 0.5)
                            .background(
                                settings.denomination == denom
                                    ? Color(hex: "9b59b6").opacity(0.15)
                                    : Color.clear
                            )
                            .cornerRadius(10)
                        }
                    }
                }
                .tourTarget("denominationSelector")

                // Optimal feedback toggle
                Toggle("Show Optimal Play Feedback", isOn: $settings.showOptimalFeedback)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .tourTarget("optimalFeedbackToggle")
            }
            .padding(.horizontal)

            Spacer()

            // Start button
            VStack(spacing: 12) {
                Button {
                    Task {
                        // Check if offline and game not available
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
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "9b59b6"))

                Button("Back to Menu") {
                    navigationPath.removeLast()
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .withTour(.playStart)
        .navigationTitle("Play")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            settings = await PlayPersistence.shared.loadSettings()
        }
        .alert("Game Not Available Offline", isPresented: $showOfflineAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This game hasn't been downloaded yet. Please connect to the internet to download it, or choose a different game.")
        }
    }
}

#Preview {
    NavigationStack {
        PlayStartView(navigationPath: .constant(NavigationPath()))
    }
}
