import SwiftUI

struct QuizPlayView: View {
    @StateObject var viewModel: QuizViewModel
    @Binding var navigationPath: NavigationPath
    @Environment(\.dismiss) private var dismiss
    @State private var swipedCardIndices: Set<Int> = []
    @State private var isDragging = false
    @State private var dragStartLocation: CGPoint?

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
        .withTour(.quizPlay, isReady: !viewModel.hands.isEmpty)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(hex: "667eea"))

            if viewModel.isPreparingPaytable {
                // Paytable preparation phase
                Text(viewModel.preparationMessage)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                VStack(spacing: 8) {
                    Text("Preparing compressed strategy data for use.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("To save the uncompressed file for quicker play, change storage options in Settings → Offline Data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                // Finding hands phase
                Text("Loading hands...")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("Found \(viewModel.loadingProgress)/\(viewModel.quizSize)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }

    // MARK: - Quiz View

    private var quizView: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            if isLandscape {
                landscapeQuizLayout(geometry: geometry)
            } else {
                portraitQuizLayout(geometry: geometry)
            }
        }
    }

    // MARK: - Portrait Quiz Layout

    private func portraitQuizLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Progress bar
            progressBar
                .tourTarget("progressBar")
                .padding(.bottom, 8)

            // Scrollable content
            ScrollView {
                VStack(spacing: 0) {
                    // Paytable
                    if let paytable = PayTable.allPayTables.first(where: { $0.id == viewModel.paytableId }) {
                        CompactPayTableView(paytable: paytable)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }

                    // Cards area
                    cardsAreaView(geometry: geometry)
                        .padding(.horizontal)
                        .tourTarget("quizCardsArea")

                    // EV Options Table (scrollable)
                    if viewModel.showFeedback, let currentHand = viewModel.currentHand {
                        evOptionsTable(for: currentHand)
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .tourTarget("evTable")
                    }
                }
            }

            // Action button (fixed at bottom)
            actionButton
                .tourTarget("submitButton")
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
    }

    // MARK: - Landscape Quiz Layout

    private func landscapeQuizLayout(geometry: GeometryProxy) -> some View {
        let leftWidth = geometry.size.width * 0.58
        let rightWidth = geometry.size.width * 0.42 - 16

        return HStack(alignment: .top, spacing: 8) {
            // Left side: Cards area with paytable above
            VStack(spacing: 8) {
                // Compact paytable at top
                if let paytable = PayTable.allPayTables.first(where: { $0.id == viewModel.paytableId }) {
                    CompactPayTableView(paytable: paytable)
                        .padding(.horizontal, 4)
                }

                // Cards area - takes remaining height
                landscapeCardsArea(width: leftWidth - 16, height: geometry.size.height * 0.65)
                    .tourTarget("quizCardsArea")

                Spacer()
            }
            .frame(width: leftWidth)
            .padding(.leading, 8)

            // Right side: Progress, EV table, and action button
            VStack(spacing: 8) {
                // Progress bar (compact)
                landscapeProgressBar
                    .tourTarget("progressBar")

                // EV Options Table (scrollable)
                ScrollView {
                    if viewModel.showFeedback, let currentHand = viewModel.currentHand {
                        evOptionsTable(for: currentHand)
                            .tourTarget("evTable")
                    }
                }

                Spacer()

                // Action button (fixed at bottom)
                actionButton
                    .tourTarget("submitButton")
                    .padding(.bottom, 8)
            }
            .frame(width: rightWidth)
            .padding(.trailing, 8)
        }
        .padding(.top, 8)
    }

    // MARK: - Landscape Progress Bar (compact)

    private var landscapeProgressBar: some View {
        VStack(spacing: 4) {
            HStack {
                Text(viewModel.progressText)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(viewModel.correctCount) correct")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "667eea"))
                        .frame(width: geo.size.width * viewModel.progressValue)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Landscape Cards Area

    private func landscapeCardsArea(width: CGFloat, height: CGFloat) -> some View {
        // Calculate card dimensions - cards are 2.5:3.5 aspect ratio
        // In landscape, we want cards to fit horizontally with some padding
        let cardAspectRatio: CGFloat = 2.5 / 3.5
        let availableCardsWidth = width - 24  // padding
        let cardWidth = (availableCardsWidth - 24) / 5  // 5 cards with spacing
        let cardHeight = cardWidth / cardAspectRatio

        return ZStack {
            // Green felt background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "2d5016"))
                .shadow(radius: 3)

            VStack(spacing: 4) {
                // Dealt winner banner at top
                if viewModel.showDealtWinner, let handName = viewModel.dealtWinnerName {
                    DealtWinnerBanner(handName: handName)
                        .transition(AnyTransition.scale.combined(with: AnyTransition.opacity))
                        .padding(.top, 4)
                }

                Spacer()

                // Cards in horizontal row - explicitly sized
                if let currentHand = viewModel.currentHand {
                    let isDeucesWild = PayTable.allPayTables.first { $0.id == viewModel.paytableId }?.isDeucesWild ?? false

                    HStack(spacing: 6) {
                        ForEach(Array(currentHand.hand.cards.enumerated()), id: \.element.id) { index, card in
                            CardView(
                                card: card,
                                isSelected: viewModel.selectedIndices.contains(index),
                                showAsWild: isDeucesWild
                            ) {
                                viewModel.toggleCard(index)
                            }
                            .frame(width: cardWidth)
                        }
                    }
                }

                Spacer()

                // Feedback or tip at bottom
                if viewModel.showFeedback, let currentHand = viewModel.currentHand {
                    feedbackOverlay(for: currentHand)
                        .padding(.bottom, 4)
                } else if viewModel.showSwipeTip {
                    swipeTipOverlay
                        .padding(.bottom, 4)
                        .transition(.opacity)
                }
            }
        }
        .frame(width: width, height: height)
    }

    // MARK: - Portrait Cards Area View

    private func cardsAreaView(geometry: GeometryProxy) -> some View {
        ZStack {
            // Green felt background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "2d5016"))
                .shadow(radius: 5)

            // Cards (fixed vertical position)
            if let currentHand = viewModel.currentHand {
                let isDeucesWild = PayTable.allPayTables.first { $0.id == viewModel.paytableId }?.isDeucesWild ?? false
                GeometryReader { cardGeometry in
                    HStack(spacing: 8) {
                        ForEach(Array(currentHand.hand.cards.enumerated()), id: \.element.id) { index, card in
                            CardView(
                                card: card,
                                isSelected: viewModel.selectedIndices.contains(index),
                                showAsWild: isDeucesWild
                            ) {
                                viewModel.toggleCard(index)
                            }
                        }
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Calculate which card is at this position
                                let cardWidth = (cardGeometry.size.width - 32) / 5  // 8px spacing * 4
                                let xPosition = value.location.x
                                let cardIndex = Int(xPosition / (cardWidth + 8))

                                if !isDragging {
                                    isDragging = true
                                    dragStartLocation = value.location
                                    swipedCardIndices = []
                                }

                                // Check if this is a valid card and we haven't toggled it yet
                                if cardIndex >= 0 && cardIndex < 5 && !swipedCardIndices.contains(cardIndex) {
                                    // Check if we've moved enough to be a swipe
                                    guard let startLocation = dragStartLocation else { return }
                                    let dragDistance = hypot(
                                        value.location.x - startLocation.x,
                                        value.location.y - startLocation.y
                                    )

                                    // If we've moved more than 10 points OR already swiped other cards, toggle immediately
                                    if dragDistance > 10 || !swipedCardIndices.isEmpty {
                                        swipedCardIndices.insert(cardIndex)
                                        viewModel.toggleCard(cardIndex)
                                    }
                                }
                            }
                            .onEnded { _ in
                                // Reset state
                                swipedCardIndices = []
                                isDragging = false
                                dragStartLocation = nil
                            }
                    )
                }
                .frame(height: 100)
                .padding(.horizontal)
            }

            // Dealt winner banner (overlay above cards)
            VStack {
                if viewModel.showDealtWinner, let handName = viewModel.dealtWinnerName {
                    DealtWinnerBanner(handName: handName)
                        .transition(AnyTransition.scale.combined(with: AnyTransition.opacity))
                        .padding(.top, 8)
                }
                Spacer()
            }

            // Feedback overlay (below cards)
            VStack {
                Spacer()
                if viewModel.showFeedback, let currentHand = viewModel.currentHand {
                    feedbackOverlay(for: currentHand)
                        .padding(.bottom, 8)
                }
            }

            // Swipe tip (below cards, shown initially)
            VStack {
                Spacer()
                if viewModel.showSwipeTip && !viewModel.showFeedback {
                    swipeTipOverlay
                        .padding(.bottom, 8)
                        .transition(.opacity)
                }
            }
        }
        .frame(height: 220)
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
        return VStack(spacing: 4) {
            Text(viewModel.isCorrect ? "Correct!" : "Incorrect")
                .font(.headline)
                .foregroundColor(.white)

            if !viewModel.isCorrect && viewModel.evLost > 0 {
                Text("EV Lost: \(String(format: "%.3f", viewModel.evLost))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(viewModel.isCorrect ? Color.green.opacity(0.9) : Color(hex: "FFA726").opacity(0.9))
        )
    }

    // MARK: - Swipe Tip Overlay

    private var swipeTipOverlay: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.draw")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
            Text("Tip: Swipe to select cards")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "667eea").opacity(0.85))
        )
    }

    // MARK: - EV Options Table

    private func evOptionsTable(for quizHand: QuizHand) -> some View {
        // Get user's hold in canonical order for prioritization
        let userCanonicalHold = quizHand.hand.originalIndicesToCanonical(quizHand.userHoldIndices)
        let options = quizHand.strategyResult.sortedHoldOptionsPrioritizingUser(userCanonicalHold)

        return VStack(spacing: 8) {
            // Table header
            HStack {
                Text("Rank")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 40, alignment: .leading)

                Text("Hold")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("EV")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 60, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray5))
            .cornerRadius(8)

            // Table rows
            VStack(spacing: 4) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    let optionOriginalIndices = quizHand.hand.canonicalIndicesToOriginal(option.indices)
                    let optionCards = optionOriginalIndices.map { quizHand.hand.cards[$0] }
                    let rank = quizHand.strategyResult.rankForOption(at: index, inUserPrioritizedList: options)
                    let isBest = rank == 1
                    let isUserSelection = viewModel.showFeedback && optionOriginalIndices.sorted() == quizHand.userHoldIndices.sorted()

                    HStack(spacing: 8) {
                        // Rank (shows tied rank number)
                        Text("\(rank)")
                            .font(.subheadline)
                            .fontWeight(isBest ? .bold : .regular)
                            .frame(width: 40, alignment: .leading)

                        // Hold cards
                        if optionCards.isEmpty {
                            Text("Draw all")
                                .font(.subheadline)
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            HStack(spacing: 4) {
                                ForEach(optionCards, id: \.id) { card in
                                    Text(card.displayText)
                                        .font(.subheadline)
                                        .foregroundColor(card.suit.color)
                                        .fontWeight(isBest ? .bold : .regular)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // EV
                        Text(String(format: "%.3f", option.ev))
                            .font(.subheadline)
                            .fontWeight(isBest ? .bold : .regular)
                            .frame(width: 60, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        isUserSelection && !viewModel.isCorrect
                            ? Color(hex: "FFA726").opacity(0.3)
                            : (isBest ? Color(hex: "667eea").opacity(0.2) : Color(.systemGray6))
                    )
                    .cornerRadius(6)
                }
            }
        }
        .padding(.vertical, 4)
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
                .padding(.vertical, 16)
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
