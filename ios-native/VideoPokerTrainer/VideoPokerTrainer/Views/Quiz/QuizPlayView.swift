import SwiftUI

struct QuizPlayView: View {
    @StateObject var viewModel: QuizViewModel
    @Binding var navigationPath: NavigationPath
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.isQuizComplete {
                QuizResultsView(viewModel: viewModel, navigationPath: $navigationPath)
            } else {
                quizView
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Quit") {
                    navigationPath.removeLast(navigationPath.count)
                }
            }
        }
        .task {
            await viewModel.loadQuiz()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading hands...")
                .font(.headline)

            Text("Found \(viewModel.loadingProgress)/\(viewModel.quizSize)")
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Quiz View

    private var quizView: some View {
        VStack(spacing: 0) {
            // Progress bar
            progressBar

            Spacer()

            // Cards area
            ZStack {
                // Green felt background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "2d5016"))
                    .shadow(radius: 5)

                VStack(spacing: 16) {
                    // Dealt winner banner
                    if viewModel.showDealtWinner, let handName = viewModel.dealtWinnerName {
                        DealtWinnerBanner(handName: handName)
                            .transition(AnyTransition.scale.combined(with: AnyTransition.opacity))
                    }

                    // Cards
                    if let currentHand = viewModel.currentHand {
                        HStack(spacing: 8) {
                            ForEach(Array(currentHand.hand.cards.enumerated()), id: \.element.id) { index, card in
                                CardView(
                                    card: card,
                                    isSelected: viewModel.selectedIndices.contains(index)
                                ) {
                                    viewModel.toggleCard(index)
                                }
                            }
                        }
                    }

                    // Feedback overlay
                    if viewModel.showFeedback, let currentHand = viewModel.currentHand {
                        feedbackOverlay(for: currentHand)
                    }
                }
                .padding()
            }
            .frame(height: 250)
            .padding(.horizontal)

            Spacer()

            // Action button
            actionButton
                .padding()
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text(viewModel.progressText)
                    .font(.headline)

                Spacer()

                Text("\(viewModel.correctCount) correct")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "667eea"))
                        .frame(width: geometry.size.width * viewModel.progressValue)
                }
            }
            .frame(height: 8)
            .padding(.horizontal)
        }
        .padding(.top)
    }

    // MARK: - Feedback Overlay

    private func feedbackOverlay(for quizHand: QuizHand) -> some View {
        // Convert canonical (sorted) indices to original deal order
        let canonicalIndices = quizHand.strategyResult.bestHoldIndices
        let originalIndices = quizHand.hand.canonicalIndicesToOriginal(canonicalIndices)
        let bestCards = originalIndices.map { quizHand.hand.cards[$0] }

        return VStack(spacing: 8) {
            Text(viewModel.isCorrect ? "Correct!" : "Incorrect")
                .font(.headline)
                .foregroundColor(.white)

            // Best hold
            HStack(spacing: 4) {
                Text("Best:")
                    .foregroundColor(.white.opacity(0.8))
                if bestCards.isEmpty {
                    Text("Draw all")
                        .foregroundColor(.white.opacity(0.8))
                        .italic()
                } else {
                    ForEach(bestCards, id: \.id) { card in
                        Text(card.displayText)
                            .foregroundColor(card.suit.color == Color(hex: "e74c3c") ? .red : .white)
                            .fontWeight(.bold)
                    }
                }
                Text("EV: \(String(format: "%.3f", quizHand.strategyResult.bestEv))")
                    .foregroundColor(.white.opacity(0.8))
            }
            .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.isCorrect ? Color.green.opacity(0.9) : Color(hex: "d35400").opacity(0.9))
        )
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button {
            if viewModel.showFeedback {
                viewModel.next()
            } else {
                viewModel.submit()
            }
        } label: {
            Text(buttonText)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
        .tint(viewModel.showFeedback ? Color(hex: "3498db") : Color(hex: "667eea"))
    }

    private var buttonText: String {
        if viewModel.showFeedback {
            return viewModel.currentIndex + 1 >= viewModel.hands.count ? "See Results" : "Next"
        }
        return "Submit"
    }
}

#Preview {
    NavigationStack {
        QuizPlayView(
            viewModel: QuizViewModel(paytableId: "jacks-or-better-9-6"),
            navigationPath: .constant(NavigationPath())
        )
    }
}
