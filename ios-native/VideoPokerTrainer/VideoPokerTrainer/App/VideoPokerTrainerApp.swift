import SwiftUI

@main
struct VideoPokerTrainerApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showResetPassword = false

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    HomeView(authViewModel: authViewModel)
                } else {
                    AuthView()
                }
            }
            .sheet(isPresented: $showResetPassword) {
                ResetPasswordView(viewModel: authViewModel)
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        // Handle deep links from email (password reset, magic link, etc.)
        // Supabase format: vptrainer://[path]#access_token=xxx&refresh_token=yyy
        print("📱 Deep link received: \(url.absoluteString)")

        // Extract tokens from URL fragment
        if let fragment = url.fragment {
            let params = fragment.components(separatedBy: "&")
            var accessToken: String?
            var refreshToken: String?
            var type: String?

            for param in params {
                let keyValue = param.components(separatedBy: "=")
                if keyValue.count == 2 {
                    let key = keyValue[0]
                    let value = keyValue[1]

                    if key == "access_token" {
                        accessToken = value
                    } else if key == "refresh_token" {
                        refreshToken = value
                    } else if key == "type" {
                        type = value
                    }
                }
            }

            // Handle the deep link based on type
            Task {
                await MainActor.run {
                    if url.path == "/reset-password" || type == "recovery" {
                        // Show reset password screen
                        showResetPassword = true
                    }
                    // Magic link and other auth types are handled automatically by Supabase
                }
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
