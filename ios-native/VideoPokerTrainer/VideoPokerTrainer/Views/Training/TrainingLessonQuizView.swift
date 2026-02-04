import SwiftUI

struct TrainingLessonQuizView: View {
    @StateObject var viewModel: TrainingLessonQuizViewModel
    @Binding var navigationPath: NavigationPath
    @State private var swipedCardIndices: Set<Int> = []
    @State private var isDragging = false
    @State private var dragStartLocation: CGPoint?
    @State private var isLandscape = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.isQuizComplete {
                TrainingLessonResultsView(viewModel: viewModel, navigationPath: $navigationPath)
            } else {
                quizView
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(isLandscape ? .hidden : .visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    navigationPath.removeLast()
                } label: {
                    Text("Quit")
                        .foregroundColor(.white)
                }
            }
        }
        .task {
            await viewModel.loadQuiz()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(hex: "667eea"))

            if viewModel.isPreparingPaytable {
                Text(viewModel.preparationMessage)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            } else {
                Text("Loading practice hands...")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
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
            let currentlyLandscape = geometry.size.width > geometry.size.height

            ZStack {
                LinearGradient(
                    colors: [Color(hex: "0a0a1a"), Color(hex: "1a1a3a"), Color(hex: "0a0a1a")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if currentlyLandscape {
                    landscapeQuizLayout(geometry: geometry)
                } else {
                    portraitQuizLayout(geometry: geometry)
                }
            }
            .onChange(of: currentlyLandscape) { _, newValue in
                isLandscape = newValue
            }
            .onAppear {
                isLandscape = currentlyLandscape
            }
        }
    }

    // MARK: - Portrait Quiz Layout

    private func portraitQuizLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            progressBar
                .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 0) {
                    if let paytable = PayTable.allPayTables.first(where: { $0.id == viewModel.paytableId }) {
                        CompactPayTableView(paytable: paytable)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }

                    cardsAreaView(geometry: geometry)
                        .padding(.horizontal)

                    if viewModel.showFeedback, let currentHand = viewModel.currentHand {
                        if currentHand.strategyResult != nil {
                            evOptionsTable(for: currentHand)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }

                        explanationCard(for: currentHand)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                }
            }

            actionButton
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
    }

    // MARK: - Landscape Quiz Layout

    private func landscapeQuizLayout(geometry: GeometryProxy) -> some View {
        let leadingSafeArea = geometry.safeAreaInsets.leading
        let availableWidth = geometry.size.width
        let leftWidth = availableWidth * 0.42
        let rightWidth = availableWidth * 0.58 - 16

        let hasDynamicIslandOnLeft = leadingSafeArea > 20
        let cornerClearance: CGFloat = hasDynamicIslandOnLeft ? 24 : 4
        let effectiveTopPadding = cornerClearance

        return HStack(alignment: .top, spacing: 8) {
            // Left side: Navigation header, progress, EV table
            VStack(spacing: 6) {
                landscapeNavigationHeader
                landscapeProgressBar

                if viewModel.showFeedback, let currentHand = viewModel.currentHand {
                    ScrollView {
                        VStack(spacing: 8) {
                            if currentHand.strategyResult != nil {
                                evOptionsTable(for: currentHand)
                            }
                            explanationCard(for: currentHand)
                        }
                    }
                } else {
                    Spacer(minLength: 0)
                }
            }
            .padding(.leading, max(leadingSafeArea, 8))
            .padding(.top, effectiveTopPadding)
            .padding(.bottom, 4)
            .frame(width: leftWidth)

            // Right side: Cards and action button
            VStack(spacing: 4) {
                Spacer(minLength: 0)

                landscapeCardsArea(width: rightWidth - 8, height: geometry.size.height * 0.60)

                actionButton
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
            }
            .frame(width: rightWidth)
            .padding(.trailing, 8)
        }
    }

    // MARK: - Landscape Navigation Header

    private var landscapeNavigationHeader: some View {
        HStack {
            Button {
                navigationPath.removeLast()
            } label: {
                Text("Quit")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }

            Spacer()

            Text("Lesson \(viewModel.lesson.number)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "FFD700"))
                .lineLimit(1)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }

    // MARK: - Landscape Progress Bar

    private var landscapeProgressBar: some View {
        VStack(spacing: 4) {
            HStack {
                Text(viewModel.progressText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()

                Text("\(viewModel.correctCount) correct")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.2))

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
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "1a4d1a"), Color(hex: "0d3d0d"), Color(hex: "1a4d1a")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(radius: 3)

            VStack(spacing: 4) {
                if viewModel.showDealtWinner, let handName = viewModel.dealtWinnerName {
                    DealtWinnerBanner(handName: handName)
                        .transition(AnyTransition.scale.combined(with: AnyTransition.opacity))
                        .padding(.top, 4)
                }

                Spacer()

                if let currentHand = viewModel.currentHand {
                    GeometryReader { cardGeometry in
                        let cardSpacing: CGFloat = 4
                        let cardWidth = (cardGeometry.size.width - (cardSpacing * 4)) / 5

                        HStack(spacing: cardSpacing) {
                            ForEach(Array(currentHand.hand.cards.enumerated()), id: \.element.id) { index, card in
                                CardView(
                                    card: card,
                                    isSelected: viewModel.selectedIndices.contains(index)
                                ) {
                                    viewModel.toggleCard(index)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    guard !viewModel.showFeedback else { return }
                                    let xPosition = value.location.x
                                    let cardIndex = Int(xPosition / (cardWidth + cardSpacing))

                                    if !isDragging {
                                        isDragging = true
                                        dragStartLocation = value.location
                                        swipedCardIndices = []
                                    }

                                    if cardIndex >= 0 && cardIndex < 5 && !swipedCardIndices.contains(cardIndex) {
                                        guard let startLocation = dragStartLocation else { return }
                                        let dragDistance = hypot(
                                            value.location.x - startLocation.x,
                                            value.location.y - startLocation.y
                                        )
                                        if dragDistance > 10 || !swipedCardIndices.isEmpty {
                                            swipedCardIndices.insert(cardIndex)
                                            viewModel.toggleCard(cardIndex)
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    swipedCardIndices = []
                                    isDragging = false
                                    dragStartLocation = nil
                                }
                        )
                    }
                }

                Spacer()

                if viewModel.showFeedback, let currentHand = viewModel.currentHand {
                    feedbackOverlay(for: currentHand)
                        .padding(.bottom, 4)
                } else if viewModel.showSwipeTip {
                    swipeTipOverlay
                        .padding(.bottom, 4)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(width: width, height: height)
    }

    // MARK: - Portrait Cards Area

    private func cardsAreaView(geometry: GeometryProxy) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "1a4d1a"), Color(hex: "0d3d0d"), Color(hex: "1a4d1a")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(radius: 5)

            if let currentHand = viewModel.currentHand {
                GeometryReader { cardGeometry in
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
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let cardWidth = (cardGeometry.size.width - 32) / 5
                                let xPosition = value.location.x
                                let cardIndex = Int(xPosition / (cardWidth + 8))

                                if !isDragging {
                                    isDragging = true
                                    dragStartLocation = value.location
                                    swipedCardIndices = []
                                }

                                if cardIndex >= 0 && cardIndex < 5 && !swipedCardIndices.contains(cardIndex) {
                                    guard let startLocation = dragStartLocation else { return }
                                    let dragDistance = hypot(
                                        value.location.x - startLocation.x,
                                        value.location.y - startLocation.y
                                    )
                                    if dragDistance > 10 || !swipedCardIndices.isEmpty {
                                        swipedCardIndices.insert(cardIndex)
                                        viewModel.toggleCard(cardIndex)
                                    }
                                }
                            }
                            .onEnded { _ in
                                swipedCardIndices = []
                                isDragging = false
                                dragStartLocation = nil
                            }
                    )
                }
                .frame(height: 100)
                .padding(.horizontal)
            }

            // Dealt winner banner
            VStack {
                if viewModel.showDealtWinner, let handName = viewModel.dealtWinnerName {
                    DealtWinnerBanner(handName: handName)
                        .transition(AnyTransition.scale.combined(with: AnyTransition.opacity))
                        .padding(.top, 8)
                }
                Spacer()
            }

            // Feedback overlay
            VStack {
                Spacer()
                if viewModel.showFeedback, let currentHand = viewModel.currentHand {
                    feedbackOverlay(for: currentHand)
                        .padding(.bottom, 8)
                }
            }

            // Swipe tip
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
                    .foregroundColor(.white)

                Spacer()

                Text("\(viewModel.correctCount) correct")
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))

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

    private func feedbackOverlay(for quizHand: TrainingQuizHand) -> some View {
        VStack(spacing: 4) {
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

    private func evOptionsTable(for quizHand: TrainingQuizHand) -> some View {
        guard let strategyResult = quizHand.strategyResult else {
            return AnyView(EmptyView())
        }

        let userCanonicalHold = quizHand.hand.originalIndicesToCanonical(quizHand.userHoldIndices)
        let options = strategyResult.sortedHoldOptionsPrioritizingUser(userCanonicalHold)

        return AnyView(
            VStack(spacing: 8) {
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
                        let rank = strategyResult.rankForOption(at: index, inUserPrioritizedList: options)
                        let isBest = rank == 1
                        let isUserSelection = viewModel.showFeedback && optionOriginalIndices.sorted() == quizHand.userHoldIndices.sorted()

                        HStack(spacing: 8) {
                            Text("\(rank)")
                                .font(.subheadline)
                                .fontWeight(isBest ? .bold : .regular)
                                .frame(width: 40, alignment: .leading)

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
        )
    }

    // MARK: - Explanation Card

    private func explanationCard(for quizHand: TrainingQuizHand) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Explanation", systemImage: "lightbulb.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.yellow)

            Text(quizHand.practiceHand.explanation)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "1a1a3a"))
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
