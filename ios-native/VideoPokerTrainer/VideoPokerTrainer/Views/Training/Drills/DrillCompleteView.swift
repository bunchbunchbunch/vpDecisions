import SwiftUI

struct DrillCompleteView: View {
    @ObservedObject var viewModel: DrillViewModel
    @Binding var navigationPath: NavigationPath

    private var accuracy: Double {
        viewModel.session?.accuracy ?? 0
    }

    private var isPerfect: Bool {
        guard let session = viewModel.session else { return false }
        return session.correctCount == session.hands.count
    }

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            VStack(spacing: 24) {
                Spacer()

                // Result icon
                resultIcon

                // Score
                scoreDisplay

                // Stats
                statsDisplay

                Spacer()

                // Action buttons
                if isLandscape {
                    HStack(spacing: 16) {
                        actionButtons
                    }
                } else {
                    VStack(spacing: 12) {
                        actionButtons
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Result Icon

    private var resultIcon: some View {
        ZStack {
            Circle()
                .fill(isPerfect ? AppTheme.Colors.mintGreen.opacity(0.2) : Color.blue.opacity(0.2))
                .frame(width: 100, height: 100)

            if isPerfect {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.Colors.mintGreen)
            }
        }
    }

    // MARK: - Score Display

    private var scoreDisplay: some View {
        VStack(spacing: 8) {
            Text(String(format: "%.0f%%", accuracy))
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)

            if isPerfect {
                Text("Perfect Score!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.yellow)
            } else {
                Text("Drill Complete")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.mintGreen)
            }
        }
    }

    // MARK: - Stats Display

    private var statsDisplay: some View {
        HStack(spacing: 24) {
            statItem(
                title: "Correct",
                value: "\(viewModel.session?.correctCount ?? 0)/\(viewModel.session?.hands.count ?? 0)",
                icon: "checkmark.circle"
            )

            statItem(
                title: "EV Lost",
                value: String(format: "%.4f", viewModel.session?.totalEvLost ?? 0),
                icon: "chart.line.downtrend.xyaxis"
            )

            if let stats = viewModel.stats {
                statItem(
                    title: "Best Streak",
                    value: "\(stats.bestStreak)",
                    icon: "flame.fill"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.cardBackground)
        )
    }

    private func statItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.mintGreen)

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Text(title)
                .font(.system(size: 10))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        Button {
            Task {
                await viewModel.restart()
            }
        } label: {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                Text("Play Again")
            }
            .primaryButton()
        }

        Button {
            navigationPath.removeLast()
        } label: {
            Text("Back to Training")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
}
