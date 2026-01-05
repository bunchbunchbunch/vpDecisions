import SwiftUI

struct PlayStartView: View {
    @Binding var navigationPath: NavigationPath
    @State private var settings = PlaySettings()
    @State private var balance = PlayerBalance()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Title
            VStack(spacing: 8) {
                Image(systemName: "suit.spade.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color(hex: "9b59b6"))

                Text("Play Mode")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Simulate real video poker")
                    .foregroundColor(.secondary)
            }

            // Balance display
            VStack(spacing: 4) {
                Text("Current Balance")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatCurrency(balance.balance))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "27ae60"))
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            Spacer()

            // Quick settings
            VStack(spacing: 16) {
                // Paytable picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Game Type")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Picker("Paytable", selection: $settings.selectedPaytableId) {
                        ForEach(PayTable.allPayTables, id: \.id) { paytable in
                            Text(paytable.name).tag(paytable.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }

                // Line count
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lines")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        ForEach(LineCount.allCases, id: \.self) { lineCount in
                            Button {
                                settings.lineCount = lineCount
                            } label: {
                                Text(lineCount.displayName)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
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

                // Denomination
                VStack(alignment: .leading, spacing: 8) {
                    Text("Denomination")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(BetDenomination.allCases, id: \.self) { denom in
                                Button {
                                    settings.denomination = denom
                                } label: {
                                    Text(denom.displayName)
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
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
                }

                // Optimal feedback toggle
                Toggle("Show Optimal Play Feedback", isOn: $settings.showOptimalFeedback)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Spacer()

            // Bet summary
            VStack(spacing: 4) {
                Text("Bet per hand")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatCurrency(settings.totalBetDollars))
                    .font(.title2)
                    .fontWeight(.bold)
            }

            // Start button
            Button {
                // Save settings before navigating
                Task {
                    await PlayPersistence.shared.saveSettings(settings)
                }
                navigationPath.append(AppScreen.playGame)
            } label: {
                Text("Start Playing")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "9b59b6"))
            .padding(.horizontal)
            .disabled(balance.balance < settings.totalBetDollars)

            Button("Back to Menu") {
                navigationPath.removeLast()
            }
            .foregroundColor(.secondary)

            Spacer()
        }
        .navigationTitle("Play")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            settings = await PlayPersistence.shared.loadSettings()
            balance = await PlayPersistence.shared.loadBalance()
        }
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
        PlayStartView(navigationPath: .constant(NavigationPath()))
    }
}
