import SwiftUI

struct DrillPlayView: View {
    @StateObject private var viewModel: DrillViewModel
    @Binding var navigationPath: NavigationPath

    init(drillId: String, navigationPath: Binding<NavigationPath>) {
        self._viewModel = StateObject(wrappedValue: DrillViewModel(drillId: drillId))
        self._navigationPath = navigationPath
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
                } else if viewModel.isComplete {
                    DrillCompleteView(viewModel: viewModel, navigationPath: $navigationPath)
                } else if let hand = viewModel.currentHand {
                    if isLandscape {
                        landscapeDrillLayout(hand: hand, geometry: geometry)
                    } else {
                        portraitDrillLayout(hand: hand)
                    }
                }
            }
        }
        .navigationTitle(viewModel.drill?.title ?? "Drill")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(viewModel.drill?.title ?? "Drill")
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
            Text("Loading drill...")
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

    // MARK: - Portrait Layout

    private func portraitDrillLayout(hand: DrillHand) -> some View {
        VStack(spacing: 16) {
            // Progress and streak
            HStack {
                progressBar
                Spacer()
                streakBadge
            }

            Spacer()

            // Category badge
            Text(hand.category.displayName)
                .font(.system(size: 12))
                .foregroundColor(hand.category.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .stroke(hand.category.color.opacity(0.5), lineWidth: 1)
                )

            Text("Select the cards to hold")
                .font(.headline)
                .foregroundColor(.white)

            // Cards
            cardsView(hand: hand)

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

    private func landscapeDrillLayout(hand: DrillHand, geometry: GeometryProxy) -> some View {
        HStack(spacing: 20) {
            // Left side: Cards
            VStack(spacing: 16) {
                Text(hand.category.displayName)
                    .font(.system(size: 12))
                    .foregroundColor(hand.category.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(hand.category.color.opacity(0.5), lineWidth: 1)
                    )

                cardsView(hand: hand)
            }
            .frame(width: (geometry.size.width - 48) * 0.55)

            // Right side: Progress, Feedback, Button
            VStack(spacing: 16) {
                HStack {
                    progressBar
                    Spacer()
                    streakBadge
                }

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
        VStack(alignment: .leading, spacing: 4) {
            Text("Hand \(viewModel.session?.currentIndex ?? 0 + 1)/\(viewModel.session?.hands.count ?? 0)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            ProgressView(value: viewModel.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.Colors.mintGreen))
                .frame(width: 120)
        }
    }

    // MARK: - Streak Badge

    private var streakBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundColor(viewModel.currentStreak > 0 ? .orange : AppTheme.Colors.textSecondary)

            Text("\(viewModel.currentStreak)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(viewModel.currentStreak > 0 ? .orange : AppTheme.Colors.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(AppTheme.Colors.cardBackground)
        )
    }

    // MARK: - Cards View

    private func cardsView(hand: DrillHand) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<hand.hand.cards.count, id: \.self) { index in
                Button {
                    viewModel.toggleCardSelection(index)
                } label: {
                    DrillPlayingCardView(
                        card: hand.hand.cards[index],
                        isSelected: viewModel.selectedIndices.contains(index),
                        isCorrect: viewModel.showFeedback ? isCardCorrect(index: index, hand: hand) : nil
                    )
                    .frame(width: 60, height: 84)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.showFeedback)
            }
        }
    }

    private func isCardCorrect(index: Int, hand: DrillHand) -> Bool {
        // Convert to canonical for comparison
        let optimalIndices = hand.hand.canonicalIndicesToOriginal(hand.strategyResult.bestHoldIndices)
        return optimalIndices.contains(index)
    }

    // MARK: - Feedback View

    private func feedbackView(hand: DrillHand) -> some View {
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
                if let evLost = hand.evLost {
                    Text(String(format: "EV Lost: %.4f", evLost))
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
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

// MARK: - Drill Playing Card View

struct DrillPlayingCardView: View {
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
