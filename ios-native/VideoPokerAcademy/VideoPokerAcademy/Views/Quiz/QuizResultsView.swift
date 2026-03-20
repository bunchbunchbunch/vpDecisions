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
        let isDeucesWild = PayTable.allPayTables.first { $0.id == viewModel.paytableId }?.isDeucesWild ?? false

        return VStack(spacing: 0) {
            // Main row with card images
            Button {
                withAnimation {
                    if expandedHandIndex == index {
                        expandedHandIndex = nil
                    } else {
                        expandedHandIndex = index
                    }
                }
            } label: {
                VStack(spacing: 8) {
                    // Header row with status and hand number
                    HStack {
                        Image(systemName: quizHand.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(quizHand.isCorrect ? .green : .red)

                        Text("Hand #\(index + 1)")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: expandedHandIndex == index ? "chevron.down" : "chevron.right")
                            .foregroundColor(.secondary)
                    }

                    // Card images - large and prominent
                    HStack(spacing: 6) {
                        ForEach(Array(quizHand.hand.cards.enumerated()), id: \.element.id) { cardIndex, card in
                            let isHeld = quizHand.userHoldIndices.contains(cardIndex)
                            CardView(
                                card: card,
                                isSelected: isHeld,
                                showAsWild: isDeucesWild
                            )
                            .frame(width: 56)
                        }
                    }
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
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func expandedDetails(quizHand: QuizHand) -> some View {
        // Convert canonical indices to original for the best hold
        let canonicalBestIndices = quizHand.strategyResult.bestHoldIndices
        let correctHoldOriginal = quizHand.hand.canonicalIndicesToOriginal(canonicalBestIndices)

        return VStack(alignment: .leading, spacing: 16) {
            Divider()

            // User's hold (already in original order)
            HStack {
                Text("Your hold:")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(width: 90, alignment: .leading)
                if quizHand.userHoldIndices.isEmpty {
                    Text("Draw all")
                        .font(.body)
                        .italic()
                        .foregroundColor(.secondary)
                } else {
                    HStack(spacing: 6) {
                        ForEach(quizHand.userHoldIndices, id: \.self) { index in
                            let card = quizHand.hand.cards[index]
                            Text(card.displayText)
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundColor(card.suit.color)
                        }
                    }
                }
            }

            // Correct hold (if different)
            if !quizHand.isCorrect {
                HStack {
                    Text("Correct:")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(width: 90, alignment: .leading)
                    if correctHoldOriginal.isEmpty {
                        Text("Draw all")
                            .font(.body)
                            .italic()
                            .foregroundColor(.green)
                    } else {
                        HStack(spacing: 6) {
                            ForEach(correctHoldOriginal, id: \.self) { index in
                                let card = quizHand.hand.cards[index]
                                Text(card.displayText)
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(card.suit.color)
                            }
                        }
                    }
                }
            }

            // Top hold options
            VStack(alignment: .leading, spacing: 10) {
                Text("Top options:")
                    .foregroundColor(.secondary)
                    .font(.body)
                    .fontWeight(.medium)

                let userCanonicalHold = quizHand.hand.originalIndicesToCanonical(quizHand.userHoldIndices)
                let allOptions = quizHand.strategyResult.sortedHoldOptionsPrioritizingUser(userCanonicalHold)
                ForEach(Array(allOptions.prefix(5).enumerated()), id: \.offset) { i, option in
                    // Convert canonical indices to original for each option
                    let originalIndices = quizHand.hand.canonicalIndicesToOriginal(option.indices)
                    let rank = quizHand.strategyResult.rankForOption(at: i, inUserPrioritizedList: allOptions)

                    HStack {
                        Text("\(rank).")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(width: 28)

                        if originalIndices.isEmpty {
                            Text("Draw all")
                                .font(.body)
                                .italic()
                        } else {
                            HStack(spacing: 6) {
                                ForEach(originalIndices, id: \.self) { index in
                                    let card = quizHand.hand.cards[index]
                                    Text(card.displayText)
                                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                                        .foregroundColor(card.suit.color)
                                }
                            }
                        }

                        Spacer()

                        Text(String(format: "%.4f", option.ev))
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
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
