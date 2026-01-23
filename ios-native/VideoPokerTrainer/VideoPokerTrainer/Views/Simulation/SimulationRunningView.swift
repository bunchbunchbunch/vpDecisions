import SwiftUI

struct SimulationRunningView: View {
    @ObservedObject var viewModel: SimulationViewModel
    @Binding var navigationPath: NavigationPath

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let maxContentWidth: CGFloat = isLandscape ? min(500, geometry.size.width - 48) : .infinity
            let progressSize: CGFloat = isLandscape ? 140 : 180

            VStack(spacing: isLandscape ? 20 : 32) {
                Spacer()

                // Circular progress
                ZStack {
                    Circle()
                        .stroke(AppTheme.Colors.simulation.opacity(0.2), lineWidth: 12)
                        .frame(width: progressSize, height: progressSize)

                    Circle()
                        .trim(from: 0, to: viewModel.progress.overallProgress)
                        .stroke(
                            AppTheme.Colors.simulation,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: progressSize, height: progressSize)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: viewModel.progress.overallProgress)

                    VStack(spacing: 4) {
                        Text("\(Int(viewModel.progress.overallProgress * 100))%")
                            .font(.system(size: isLandscape ? 32 : 42, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.Colors.simulation)

                        Text("Complete")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // Progress details
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Run")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(viewModel.progress.currentRun) of \(viewModel.progress.totalRuns)")
                                .font(.headline)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("Hand")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(viewModel.progress.currentHand) of \(viewModel.progress.handsPerRun)")
                                .font(.headline)
                        }
                    }

                    // Progress bar
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.Colors.simulation.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.Colors.simulation)
                            .frame(width: max(0, (geometry.size.width - (isLandscape ? 96 : 64)) * viewModel.progress.overallProgress), height: 8)
                            .animation(.linear(duration: 0.5), value: viewModel.progress.overallProgress)
                    }
                    .frame(height: 8)

                    // Time info
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Elapsed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatTime(viewModel.progress.elapsedTime))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("Est. Remaining")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatTime(viewModel.progress.estimatedRemainingTime))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(AppTheme.Layout.cornerRadiusMedium)
                .frame(maxWidth: maxContentWidth)

                Spacer()

                // Cancel button
                Button(role: .destructive) {
                    viewModel.cancelSimulation()
                } label: {
                    Label("Cancel Simulation", systemImage: "xmark.circle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: maxContentWidth)
                .padding(.bottom)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Running Simulation")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.startSimulation()
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    NavigationStack {
        SimulationRunningView(
            viewModel: SimulationViewModel(),
            navigationPath: .constant(NavigationPath())
        )
    }
}
