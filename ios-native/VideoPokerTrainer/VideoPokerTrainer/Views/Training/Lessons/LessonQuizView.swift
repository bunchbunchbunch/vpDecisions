import SwiftUI

struct LessonQuizView: View {
    @ObservedObject var viewModel: LessonViewModel
    @Binding var navigationPath: NavigationPath
    @Binding var showQuiz: Bool

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                AppTheme.Gradients.background
                    .ignoresSafeArea()

                if viewModel.isQuizComplete {
                    LessonCompleteView(
                        viewModel: viewModel,
                        navigationPath: $navigationPath,
                        showQuiz: $showQuiz
                    )
                } else if let hand = viewModel.currentHand {
                    if isLandscape {
                        landscapeQuizLayout(hand: hand, geometry: geometry)
                    } else {
                        portraitQuizLayout(hand: hand)
                    }
                }
            }
        }
    }

    // MARK: - Portrait Layout

    private func portraitQuizLayout(hand: PracticeHand) -> some View {
        VStack(spacing: 16) {
            // Progress bar
            progressBar

            Spacer()

            // Question
            Text("Select the cards to hold")
                .font(.headline)
                .foregroundColor(.white)

            // Cards
            if let cards = hand.getCards() {
                cardsView(cards: cards, hand: hand)
            }

            // Category badge
            if let category = hand.handCategory {
                Text(category.displayName)
                    .font(.system(size: 12))
                    .foregroundColor(category.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(category.color.opacity(0.5), lineWidth: 1)
                    )
            }

            Spacer()

            // Feedback
            if viewModel.showFeedback {
                feedbackView(hand: hand)
            }

            // Action button
            actionButton
        }
        .padding()
    }

    // MARK: - Landscape Layout

    private func landscapeQuizLayout(hand: PracticeHand, geometry: GeometryProxy) -> some View {
        HStack(spacing: 20) {
            // Left side: Cards
            VStack(spacing: 16) {
                if let cards = hand.getCards() {
                    cardsView(cards: cards, hand: hand)
                }

                if let category = hand.handCategory {
                    Text(category.displayName)
                        .font(.system(size: 12))
                        .foregroundColor(category.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .stroke(category.color.opacity(0.5), lineWidth: 1)
                        )
                }
            }
            .frame(width: (geometry.size.width - 48) * 0.55)

            // Right side: Progress, Feedback, Button
            VStack(spacing: 16) {
                progressBar

                Text("Select the cards to hold")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                if viewModel.showFeedback {
                    feedbackView(hand: hand)
                }

                actionButton
            }
            .frame(width: (geometry.size.width - 48) * 0.45)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Question \(viewModel.currentQuizIndex + 1)/\(viewModel.quizHands.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                Text("\(viewModel.correctCount) correct")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.mintGreen)
            }

            ProgressView(value: viewModel.quizProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.Colors.mintGreen))
        }
    }

    // MARK: - Cards View

    private func cardsView(cards: [Card], hand: PracticeHand) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<cards.count, id: \.self) { index in
                Button {
                    viewModel.toggleCardSelection(index)
                } label: {
                    QuizCardView(
                        card: cards[index],
                        isSelected: viewModel.selectedIndices.contains(index),
                        isCorrect: viewModel.showFeedback ? hand.correctHold.contains(index) : nil
                    )
                    .frame(width: 60, height: 84)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.showFeedback)
            }
        }
    }

    // MARK: - Feedback View

    private func feedbackView(hand: PracticeHand) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: viewModel.lastAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(viewModel.lastAnswerCorrect ? AppTheme.Colors.mintGreen : .red)

                Text(viewModel.lastAnswerCorrect ? "Correct!" : "Incorrect")
                    .font(.headline)
                    .foregroundColor(viewModel.lastAnswerCorrect ? AppTheme.Colors.mintGreen : .red)
            }

            if !viewModel.lastAnswerCorrect, let explanation = hand.explanation {
                Text(explanation)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.cardBackground)
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
            Text(viewModel.showFeedback ? "Next" : "Submit")
                .primaryButton()
        }
        .disabled(!viewModel.showFeedback && viewModel.selectedIndices.isEmpty)
    }
}

// MARK: - Quiz Card View

struct QuizCardView: View {
    let card: Card
    let isSelected: Bool
    let isCorrect: Bool?

    private var borderColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? AppTheme.Colors.mintGreen : .red
        }
        return isSelected ? AppTheme.Colors.mintGreen : .clear
    }

    private var borderWidth: CGFloat {
        isSelected || isCorrect != nil ? 3 : 0
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)

            VStack(spacing: 4) {
                Text(card.rank.display)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(card.suit.color == .red ? .red : .black)

                Image(systemName: "suit.\(card.suit.symbol).fill")
                    .font(.system(size: 20))
                    .foregroundColor(card.suit.color == .red ? .red : .black)
            }

            // Hold indicator
            if isSelected {
                VStack {
                    Spacer()
                    Text("HOLD")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.Colors.mintGreen)
                        .cornerRadius(4)
                }
                .padding(.bottom, 6)
            }

            // Correct/Incorrect indicator after feedback
            if let isCorrect = isCorrect {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(isCorrect ? AppTheme.Colors.mintGreen : .red)
                    }
                    Spacer()
                }
                .padding(4)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: borderWidth)
        )
    }
}
