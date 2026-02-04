import SwiftUI

struct SimulationStartView: View {
    @Binding var navigationPath: NavigationPath
    @StateObject private var viewModel = SimulationViewModel()
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var showOfflineAlert = false

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let maxContentWidth: CGFloat = isLandscape ? min(600, geometry.size.width - 48) : .infinity

            ScrollView {
                VStack(spacing: 24) {
                    // Gradient header card
                    headerCard

                    // Configuration options
                    VStack(spacing: 20) {
                        // Game selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Game")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            GameSelectorView(selectedPaytableId: $viewModel.selectedPaytableId)
                        }

                        // Denomination picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Denomination")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            denominationPicker
                        }

                        // Lines per hand
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Lines per Hand")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            linesPicker
                        }

                        // Hands per simulation
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hands per Simulation")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            handsPerSimPicker
                        }

                        // Number of simulations
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Number of Simulations")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            numSimsPicker
                        }
                    }
                    .padding(.horizontal)

                    // Summary
                    summaryCard

                    // Start button
                    Button {
                        startSimulation()
                    } label: {
                        Text("Run Simulation")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.Colors.simulation)
                    .padding(.horizontal)

                    Button("Back to Menu") {
                        navigationPath.removeLast()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.vertical)
                .frame(maxWidth: maxContentWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Simulation")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Game Not Available Offline", isPresented: $showOfflineAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This game hasn't been downloaded yet. Please connect to the internet or choose a different game.")
        }
    }

    // MARK: - Subviews

    private var headerCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusXL)
                .fill(AppTheme.Gradients.teal)
                .frame(height: 140)

            VStack(spacing: 8) {
                Image("chip-green")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)

                Text("Simulation Mode")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Test strategies at scale")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .padding(.horizontal)
    }

    private var denominationPicker: some View {
        HStack(spacing: 8) {
            ForEach(BetDenomination.allCases, id: \.self) { denom in
                Button {
                    viewModel.selectedDenomination = denom
                } label: {
                    Text(denom.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.Colors.simulation)
                .opacity(viewModel.selectedDenomination == denom ? 1.0 : 0.5)
                .background(
                    viewModel.selectedDenomination == denom
                        ? AppTheme.Colors.simulation.opacity(0.15)
                        : Color.clear
                )
                .cornerRadius(8)
            }
        }
    }

    private var linesPicker: some View {
        CustomNumberPicker(
            value: $viewModel.selectedLinesPerHand,
            presets: [1, 5, 10, 100],
            color: AppTheme.Colors.simulation
        )
    }

    private var handsPerSimPicker: some View {
        CustomNumberPicker(
            value: $viewModel.selectedHandsPerSim,
            presets: [100, 500, 1000, 5000],
            color: AppTheme.Colors.simulation
        )
    }

    private var numSimsPicker: some View {
        CustomNumberPicker(
            value: $viewModel.selectedNumSims,
            presets: [1, 10, 50, 100],
            color: AppTheme.Colors.simulation
        )
    }

    private var summaryCard: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(AppTheme.Colors.simulation)
                Text("Summary")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.configSummary)
                        .font(.headline)
                    Text(viewModel.totalWageredSummary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(AppTheme.Layout.cornerRadiusMedium)
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func startSimulation() {
        Task {
            // Check if offline and game not available
            if !networkMonitor.isOnline {
                let isAvailable = await StrategyService.shared.hasOfflineData(paytableId: viewModel.selectedPaytableId)
                if !isAvailable {
                    showOfflineAlert = true
                    return
                }
            }

            // Navigate to running view with the viewModel
            navigationPath.append(viewModel)
        }
    }
}

// MARK: - Custom Number Picker

struct CustomNumberPicker: View {
    @Binding var value: Int
    let presets: [Int]
    let color: Color

    @State private var customText: String = ""
    @State private var isCustom: Bool = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            // Preset buttons
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    Button {
                        value = preset
                        isCustom = false
                        customText = ""
                        isTextFieldFocused = false
                    } label: {
                        Text(formatPreset(preset))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)
                    .tint(color)
                    .opacity(!isCustom && value == preset ? 1.0 : 0.5)
                    .background(
                        !isCustom && value == preset
                            ? color.opacity(0.15)
                            : Color.clear
                    )
                    .cornerRadius(8)
                }
            }

            // Custom input row
            HStack(spacing: 8) {
                Text("Custom:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField("Enter value", text: $customText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 120)
                    .focused($isTextFieldFocused)
                    .onChange(of: customText) { _, newValue in
                        if let intValue = Int(newValue), intValue > 0 {
                            value = intValue
                            isCustom = !presets.contains(intValue)
                        }
                    }

                if isCustom {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(color)
                }

                Spacer()
            }
        }
    }

    private func formatPreset(_ number: Int) -> String {
        if number >= 1000 {
            let thousands = Double(number) / 1000.0
            if thousands == Double(Int(thousands)) {
                return "\(Int(thousands))K"
            }
            return String(format: "%.1fK", thousands)
        }
        return "\(number)"
    }
}

// Make SimulationViewModel Hashable for navigation
extension SimulationViewModel: Hashable {
    nonisolated static func == (lhs: SimulationViewModel, rhs: SimulationViewModel) -> Bool {
        lhs === rhs
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

#Preview {
    NavigationStack {
        SimulationStartView(navigationPath: .constant(NavigationPath()))
    }
}
