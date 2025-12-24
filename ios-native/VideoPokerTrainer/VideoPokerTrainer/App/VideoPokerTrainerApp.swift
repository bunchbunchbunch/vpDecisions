import SwiftUI

@main
struct VideoPokerTrainerApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                HomeView(authViewModel: authViewModel)
            } else {
                AuthView()
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var hand = Hand.deal()
    @State private var selectedIndices: Set<Int> = []
    @State private var supabaseStatus = "Not tested"
    @State private var strategyResult: String = ""
    @StateObject private var audioService = AudioService.shared
    @StateObject private var hapticService = HapticService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // User info and sign out
                HStack {
                    if let email = authViewModel.currentUser?.email {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Sign Out") {
                        Task {
                            await authViewModel.signOut()
                        }
                    }
                    .font(.caption)
                }

                Text("Video Poker Trainer")
                    .font(.title)
                    .fontWeight(.bold)

                // Display 5 cards
                HStack(spacing: 8) {
                    ForEach(Array(hand.cards.enumerated()), id: \.element.id) { index, card in
                        CardView(
                            card: card,
                            isSelected: selectedIndices.contains(index)
                        ) {
                            toggleCard(index)
                            audioService.play(.cardSelect)
                            hapticService.trigger(.light)
                        }
                        .frame(width: 55)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.3))
                .cornerRadius(12)

                Text("Key: \(hand.canonicalKey)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Deal New Hand") {
                    hand = Hand.deal()
                    selectedIndices = []
                    strategyResult = ""
                }
                .buttonStyle(.borderedProminent)

                Divider()

                // Phase 3 Tests
                Text("Phase 3: Services Test")
                    .font(.headline)

                // Supabase test
                HStack {
                    Text("Supabase:")
                    Text(supabaseStatus)
                        .foregroundColor(supabaseStatus == "Connected!" ? .green : .secondary)
                }

                Button("Test Supabase Connection") {
                    testSupabase()
                }
                .buttonStyle(.bordered)

                // Strategy lookup test
                Button("Lookup Strategy for Current Hand") {
                    lookupStrategy()
                }
                .buttonStyle(.bordered)

                if !strategyResult.isEmpty {
                    Text(strategyResult)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                }

                // Sound test
                HStack {
                    Button("Test Sound") {
                        audioService.play(.correct)
                    }
                    .buttonStyle(.bordered)

                    Button("Test Haptic") {
                        hapticService.trigger(.success)
                    }
                    .buttonStyle(.bordered)
                }

                Text("Phase 3 Complete!")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding(.top)
            }
            .padding()
        }
    }

    private func toggleCard(_ index: Int) {
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }

    private func testSupabase() {
        supabaseStatus = "Testing..."
        Task {
            do {
                let success = try await SupabaseService.shared.testConnection()
                await MainActor.run {
                    supabaseStatus = success ? "Connected!" : "No data"
                }
            } catch {
                await MainActor.run {
                    supabaseStatus = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func lookupStrategy() {
        Task {
            do {
                if let result = try await StrategyService.shared.lookup(
                    hand: hand,
                    paytableId: PayTable.jacksOrBetter.id
                ) {
                    let holdCards = result.bestHoldIndices.map { hand.cards[$0].displayText }.joined(separator: " ")
                    await MainActor.run {
                        strategyResult = "Best hold: \(holdCards)\nEV: \(String(format: "%.4f", result.bestEv))"
                    }
                } else {
                    await MainActor.run {
                        strategyResult = "No strategy found for this hand"
                    }
                }
            } catch {
                await MainActor.run {
                    strategyResult = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    ContentView(authViewModel: AuthViewModel())
}
