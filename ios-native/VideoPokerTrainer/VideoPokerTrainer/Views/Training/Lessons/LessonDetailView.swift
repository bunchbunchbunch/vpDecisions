import SwiftUI

struct LessonDetailView: View {
    @StateObject private var viewModel: LessonViewModel
    @Binding var navigationPath: NavigationPath
    @State private var showQuiz = false

    init(lessonId: String, navigationPath: Binding<NavigationPath>) {
        self._viewModel = StateObject(wrappedValue: LessonViewModel(lessonId: lessonId))
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
                } else if let error = viewModel.error {
                    errorView(error)
                } else if showQuiz {
                    LessonQuizView(viewModel: viewModel, navigationPath: $navigationPath, showQuiz: $showQuiz)
                } else if let lesson = viewModel.lesson {
                    if isLandscape {
                        landscapeLayout(lesson: lesson, geometry: geometry)
                    } else {
                        portraitLayout(lesson: lesson)
                    }
                }
            }
        }
        .navigationTitle(viewModel.lesson?.title ?? "Lesson")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(viewModel.lesson?.title ?? "Lesson")
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
            Text("Loading lesson...")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
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

    private func portraitLayout(lesson: Lesson) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                lessonHeader(lesson: lesson)

                // Sections
                ForEach(lesson.sections) { section in
                    sectionView(section)
                }

                // Start Quiz Button
                startQuizButton(lesson: lesson)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Landscape Layout

    private func landscapeLayout(lesson: Lesson, geometry: GeometryProxy) -> some View {
        HStack(alignment: .top, spacing: 20) {
            // Left column: Header + Start Button
            VStack(spacing: 16) {
                compactLessonHeader(lesson: lesson)
                Spacer()
                startQuizButton(lesson: lesson)
            }
            .frame(width: (geometry.size.width - 48) * 0.35)

            // Right column: Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(lesson.sections) { section in
                        sectionView(section)
                    }
                }
            }
            .frame(width: (geometry.size.width - 48) * 0.65)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Lesson Header

    private func lessonHeader(lesson: Lesson) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusXL)
                .fill(AppTheme.Gradients.primary)
                .frame(height: 140)

            VStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)

                Text(lesson.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(lesson.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
        }
    }

    private func compactLessonHeader(lesson: Lesson) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "book.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.Colors.mintGreen)

                Text(lesson.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(lesson.description)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.cardBackground)
        )
    }

    // MARK: - Section View

    @ViewBuilder
    private func sectionView(_ section: LessonSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = section.title {
                HStack(spacing: 8) {
                    sectionIcon(for: section.type)

                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            if let content = section.content {
                Text(content)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineSpacing(4)
            }

            if let example = section.exampleHand {
                exampleHandView(example)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(section.type == .tip ? AppTheme.Colors.mintGreen.opacity(0.1) : AppTheme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(section.type == .tip ? AppTheme.Colors.mintGreen.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private func sectionIcon(for type: LessonSectionType) -> some View {
        Group {
            switch type {
            case .concept:
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
            case .example:
                Image(systemName: "hand.point.right.fill")
                    .foregroundColor(.blue)
            case .tip:
                Image(systemName: "star.fill")
                    .foregroundColor(AppTheme.Colors.mintGreen)
            }
        }
        .font(.system(size: 16))
    }

    // MARK: - Example Hand View

    private func exampleHandView(_ example: ExampleHand) -> some View {
        VStack(spacing: 12) {
            if let cards = example.getCards() {
                HStack(spacing: 8) {
                    ForEach(0..<cards.count, id: \.self) { index in
                        ExampleCardView(
                            card: cards[index],
                            isSelected: example.correctHold.contains(index),
                            showHoldIndicator: true
                        )
                        .frame(width: 50, height: 70)
                    }
                }
            }

            Text(example.explanation)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .italic()
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Start Quiz Button

    private func startQuizButton(lesson: Lesson) -> some View {
        VStack(spacing: 12) {
            Button {
                viewModel.startQuiz()
                showQuiz = true
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Take the Quiz")
                }
                .primaryButton()
            }

            Text("Score \(lesson.passingScore)/\(lesson.quizSize) to pass")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.Colors.textSecondary)

            if viewModel.progress.status == .completed {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.mintGreen)
                    Text("Best: \(viewModel.progress.bestScore)/\(lesson.quizSize)")
                        .foregroundColor(AppTheme.Colors.mintGreen)
                }
                .font(.system(size: 14, weight: .medium))
            }
        }
    }
}

// MARK: - Example Card View (for lesson examples)

struct ExampleCardView: View {
    let card: Card
    let isSelected: Bool
    var showHoldIndicator: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)

            VStack(spacing: 2) {
                Text(card.rank.display)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(card.suit.color == .red ? .red : .black)

                Image(systemName: "suit.\(card.suit.symbol).fill")
                    .font(.system(size: 16))
                    .foregroundColor(card.suit.color == .red ? .red : .black)
            }

            if showHoldIndicator && isSelected {
                VStack {
                    Spacer()
                    Text("HOLD")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.Colors.mintGreen)
                        .cornerRadius(4)
                }
                .padding(.bottom, 4)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? AppTheme.Colors.mintGreen : Color.clear, lineWidth: 2)
        )
    }
}
