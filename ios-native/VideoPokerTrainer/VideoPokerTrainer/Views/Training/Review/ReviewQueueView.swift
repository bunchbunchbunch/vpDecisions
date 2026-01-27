import SwiftUI

struct ReviewQueueView: View {
    @StateObject private var viewModel: ReviewQueueViewModel
    @Binding var navigationPath: NavigationPath

    init(navigationPath: Binding<NavigationPath>, paytableId: String = PayTable.jacksOrBetter96.id) {
        self._navigationPath = navigationPath
        self._viewModel = StateObject(wrappedValue: ReviewQueueViewModel(paytableId: paytableId))
    }

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                AppTheme.Gradients.background
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    loadingView
                } else if viewModel.isPreparing {
                    preparingView
                } else if let error = viewModel.error {
                    errorView(error)
                } else if !viewModel.hasItems {
                    emptyQueueView
                } else if viewModel.isComplete {
                    reviewCompleteView
                } else if let item = viewModel.currentItem {
                    if isLandscape {
                        landscapeReviewLayout(item: item, geometry: geometry)
                    } else {
                        portraitReviewLayout(item: item)
                    }
                }
            }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Review Queue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Text("Loading review queue...")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }

    // MARK: - Preparing View

    private var preparingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Text(viewModel.preparationMessage)
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text(error)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Button("Go Back") {
                navigationPath.removeLast()
            }
            .foregroundColor(AppTheme.Colors.mintGreen)
        }
        .padding()
    }

    // MARK: - Empty Queue View

    private var emptyQueueView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.Colors.mintGreen)

            Text("All Caught Up!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("No items to review right now.\nKeep practicing and check back later.")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                navigationPath.removeLast()
            } label: {
                Text("Back to Training")
                    .primaryButton()
            }
            .padding(.top, 16)
        }
        .padding()
    }

    // MARK: - Review Complete View

    private var reviewCompleteView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "star.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.yellow)

            Text("Review Complete!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(String(format: "%.0f%% accuracy", viewModel.accuracy))
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppTheme.Colors.mintGreen)

            Text("\(viewModel.correctCount)/\(viewModel.reviewItems.count) correct")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task {
                        await viewModel.restart()
                    }
                } label: {
                    Text("Review More")
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
        .padding()
    }

    // MARK: - Portrait Layout

    private func portraitReviewLayout(item: ReviewItem) -> some View {
        VStack(spacing: 16) {
            // Progress
            progressBar

            Spacer()

            // Category + mistake info
            VStack(spacing: 8) {
                if let category = item.category {
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

                Text("Missed \(item.mistakeCount) time\(item.mistakeCount == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
            }

            Text("Select the cards to hold")
                .font(.headline)
                .foregroundColor(.white)

            // Cards
            cardsView(item: item)

            Spacer()

            // Feedback
            if viewModel.showFeedback {
                feedbackView(item: item)
            }

            // Action button
            actionButton
        }
        .padding()
    }

    // MARK: - Landscape Layout

    private func landscapeReviewLayout(item: ReviewItem, geometry: GeometryProxy) -> some View {
        HStack(spacing: 20) {
            // Left side: Cards
            VStack(spacing: 16) {
                if let category = item.category {
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

                cardsView(item: item)
            }
            .frame(width: (geometry.size.width - 48) * 0.55)

            // Right side: Progress, Feedback, Button
            VStack(spacing: 16) {
                progressBar

                Text("Missed \(item.mistakeCount) time\(item.mistakeCount == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)

                Spacer()

                if viewModel.showFeedback {
                    feedbackView(item: item)
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
                Text("Item \(viewModel.currentIndex + 1)/\(viewModel.reviewItems.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                Text("\(viewModel.correctCount) correct")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.mintGreen)
            }

            ProgressView(value: viewModel.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.Colors.mintGreen))
        }
    }

    // MARK: - Cards View

    private func cardsView(item: ReviewItem) -> some View {
        Group {
            if let cards = item.getCards() {
                HStack(spacing: 8) {
                    ForEach(0..<cards.count, id: \.self) { index in
                        Button {
                            viewModel.toggleCardSelection(index)
                        } label: {
                            ReviewCardView(
                                card: cards[index],
                                isSelected: viewModel.selectedIndices.contains(index),
                                isCorrect: viewModel.showFeedback ? item.correctHold.contains(index) : nil
                            )
                            .frame(width: 60, height: 84)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.showFeedback)
                    }
                }
            }
        }
    }

    // MARK: - Feedback View

    private func feedbackView(item: ReviewItem) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: viewModel.lastAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(viewModel.lastAnswerCorrect ? AppTheme.Colors.mintGreen : .red)

                Text(viewModel.lastAnswerCorrect ? "Correct!" : "Incorrect")
                    .font(.headline)
                    .foregroundColor(viewModel.lastAnswerCorrect ? AppTheme.Colors.mintGreen : .red)
            }

            if !viewModel.lastAnswerCorrect {
                Text(String(format: "Total EV lost on this hand: %.4f", item.totalEvLost))
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textSecondary)
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

// MARK: - Review Card View

struct ReviewCardView: View {
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
