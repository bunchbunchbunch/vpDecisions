import SwiftUI

struct QuizResultsView: View {
    @ObservedObject var viewModel: QuizViewModel
    @Binding var navigationPath: NavigationPath
    @State private var expandedHandIndex: Int? = nil

    var scorePercentage: Int {
        guard viewModel.hands.count > 0 else { return 0 }
        return Int(Double(viewModel.correctCount) / Double(viewModel.hands.count) * 100)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Quiz Complete!")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("\(viewModel.correctCount) / \(viewModel.hands.count)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(scoreColor)

                    Text("\(scorePercentage)%")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding()

                Divider()

                // Hand review
                VStack(alignment: .leading, spacing: 12) {
                    Text("Review Hands")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(Array(viewModel.hands.enumerated()), id: \.element.id) { index, quizHand in
                        handReviewRow(index: index, quizHand: quizHand)
                    }
                }

                // Play again button
                Button {
                    viewModel.reset()
                    navigationPath.removeLast(navigationPath.count)
                } label: {
                    Text("Back to Menu")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .navigationTitle("Results")
        .navigationBarBackButtonHidden(true)
    }

    private var scoreColor: Color {
        switch scorePercentage {
        case 0..<50: return .red
        case 50..<70: return .orange
        case 70..<90: return .blue
        default: return .green
        }
    }

    // MARK: - Hand Review Row

    private func handReviewRow(index: Int, quizHand: QuizHand) -> some View {
        VStack(spacing: 0) {
            // Main row
            Button {
                withAnimation {
                    if expandedHandIndex == index {
                        expandedHandIndex = nil
                    } else {
                        expandedHandIndex = index
                    }
                }
            } label: {
                HStack {
                    // Status icon
                    Image(systemName: quizHand.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(quizHand.isCorrect ? .green : .red)

                    // Hand number
                    Text("#\(index + 1)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Cards
                    HStack(spacing: 2) {
                        ForEach(quizHand.hand.cards, id: \.id) { card in
                            Text(card.displayText)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(card.suit.color)
                        }
                    }

                    Spacer()

                    // Expand icon
                    Image(systemName: expandedHandIndex == index ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .buttonStyle(.plain)

            // Expanded details
            if expandedHandIndex == index {
                expandedDetails(quizHand: quizHand)
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    private func expandedDetails(quizHand: QuizHand) -> some View {
        // Convert canonical indices to original for the best hold
        let canonicalBestIndices = quizHand.strategyResult.bestHoldIndices
        let correctHoldOriginal = quizHand.hand.canonicalIndicesToOriginal(canonicalBestIndices)

        return VStack(alignment: .leading, spacing: 12) {
            Divider()

            // User's hold (already in original order)
            HStack {
                Text("Your hold:")
                    .foregroundColor(.secondary)
                if quizHand.userHoldIndices.isEmpty {
                    Text("(none)")
                        .italic()
                        .foregroundColor(.secondary)
                } else {
                    ForEach(quizHand.userHoldIndices, id: \.self) { index in
                        let card = quizHand.hand.cards[index]
                        Text(card.displayText)
                            .foregroundColor(card.suit.color)
                            .fontWeight(.bold)
                    }
                }
            }
            .font(.subheadline)

            // Correct hold (if different)
            if !quizHand.isCorrect {
                HStack {
                    Text("Correct:")
                        .foregroundColor(.secondary)
                    if correctHoldOriginal.isEmpty {
                        Text("Draw all")
                            .italic()
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(correctHoldOriginal, id: \.self) { index in
                            let card = quizHand.hand.cards[index]
                            Text(card.displayText)
                                .foregroundColor(card.suit.color)
                                .fontWeight(.bold)
                        }
                    }
                }
                .font(.subheadline)
            }

            // Top hold options
            VStack(alignment: .leading, spacing: 4) {
                Text("Top options:")
                    .foregroundColor(.secondary)
                    .font(.caption)

                ForEach(Array(quizHand.strategyResult.sortedHoldOptions.prefix(5).enumerated()), id: \.offset) { i, option in
                    // Convert canonical indices to original for each option
                    let originalIndices = quizHand.hand.canonicalIndicesToOriginal(option.indices)

                    HStack {
                        Text("\(i + 1).")
                            .foregroundColor(.secondary)
                            .frame(width: 20)

                        if originalIndices.isEmpty {
                            Text("Draw all")
                                .italic()
                        } else {
                            ForEach(originalIndices, id: \.self) { index in
                                let card = quizHand.hand.cards[index]
                                Text(card.displayText)
                                    .foregroundColor(card.suit.color)
                            }
                        }

                        Spacer()

                        Text(String(format: "%.4f", option.ev))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

#Preview {
    NavigationStack {
        QuizResultsView(
            viewModel: QuizViewModel(paytableId: "jacks-or-better-9-6"),
            navigationPath: .constant(NavigationPath())
        )
    }
}
