import SwiftUI

struct MasteryDashboardView: View {
    @StateObject var viewModel: MasteryViewModel
    @Binding var navigationPath: NavigationPath

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else {
                    // Overall mastery card
                    overallMasteryCard

                    // Category breakdown
                    categoryList
                }

                // Action buttons
                actionButtons
            }
            .padding()
        }
        .navigationTitle("Progress")
        .task {
            await viewModel.loadScores()
        }
    }

    // MARK: - Overall Mastery Card

    private var overallMasteryCard: some View {
        VStack(spacing: 12) {
            Text("Overall Mastery")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("\(Int(viewModel.overallMastery))%")
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(viewModel.masteryColor)

            Text(viewModel.masteryLevel)
                .font(.headline)
                .foregroundColor(viewModel.masteryColor)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(viewModel.masteryColor)
                        .frame(width: geometry.size.width * (viewModel.overallMastery / 100))
                }
            }
            .frame(height: 12)

            Text("\(viewModel.totalAttempts) hands practiced")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    // MARK: - Category List

    private var categoryList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.headline)

            ForEach(HandCategory.allCases, id: \.self) { category in
                categoryRow(category)
            }
        }
    }

    private func categoryRow(_ category: HandCategory) -> some View {
        let score = viewModel.scoreForCategory(category)

        return HStack(spacing: 12) {
            // Color indicator
            Circle()
                .fill(category.color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(category.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if score?.isDue == true {
                        Text("DUE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray5))

                        RoundedRectangle(cornerRadius: 3)
                            .fill(progressColor(for: score))
                            .frame(width: geometry.size.width * progressValue(for: score))
                    }
                }
                .frame(height: 6)
            }

            Spacer()

            // Stats
            VStack(alignment: .trailing, spacing: 2) {
                if let score = score, score.totalAttempts > 0 {
                    Text("\(Int(score.masteryScore))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(progressColor(for: score))

                    Text("\(score.correctAttempts)/\(score.totalAttempts)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("--")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Not practiced")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }

    private func progressValue(for score: MasteryScore?) -> Double {
        guard let score = score, score.totalAttempts > 0 else { return 0 }
        return score.masteryScore / 100
    }

    private func progressColor(for score: MasteryScore?) -> Color {
        guard let score = score else { return .gray }
        switch score.masteryScore {
        case 0..<50: return .red
        case 50..<70: return .orange
        case 70..<90: return .blue
        default: return .green
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                // Navigate to weak spots quiz
                navigationPath.removeLast()
                // Small delay to let navigation complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    navigationPath.append(AppScreen.weakSpots)
                }
            } label: {
                HStack {
                    Image(systemName: "flame.fill")
                    Text("Practice Weak Spots")
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "e74c3c"))

            Button {
                navigationPath.removeLast()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    navigationPath.append(AppScreen.quizStart)
                }
            } label: {
                HStack {
                    Image(systemName: "target")
                    Text("Start Regular Quiz")
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview {
    NavigationStack {
        MasteryDashboardView(
            viewModel: MasteryViewModel(paytableId: "jacks-or-better-9-6"),
            navigationPath: .constant(NavigationPath())
        )
    }
}
