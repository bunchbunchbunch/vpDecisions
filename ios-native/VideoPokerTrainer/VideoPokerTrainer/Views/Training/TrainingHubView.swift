import SwiftUI

struct TrainingHubView: View {
    @StateObject private var viewModel: TrainingHubViewModel
    @Binding var navigationPath: NavigationPath

    init(navigationPath: Binding<NavigationPath>, paytableId: String = PayTable.jacksOrBetter96.id) {
        self._navigationPath = navigationPath
        self._viewModel = StateObject(wrappedValue: TrainingHubViewModel(paytableId: paytableId))
    }

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                AppTheme.Gradients.background
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    loadingView
                } else {
                    if isLandscape {
                        landscapeLayout(geometry: geometry)
                    } else {
                        portraitLayout
                    }
                }
            }
        }
        .navigationTitle("Training")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Training")
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
            Text("Loading training content...")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }

    // MARK: - Portrait Layout

    private var portraitLayout: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // Lessons Section
                lessonsSection

                // Drills Section
                drillsSection

                // Review Queue Section
                reviewSection
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Landscape Layout

    private func landscapeLayout(geometry: GeometryProxy) -> some View {
        HStack(alignment: .top, spacing: 20) {
            // Left column: Lessons
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    compactHeaderSection
                    lessonsSection
                }
            }
            .frame(width: (geometry.size.width - 48) * 0.5)

            // Right column: Drills + Review
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    drillsSection
                    reviewSection
                }
            }
            .frame(width: (geometry.size.width - 48) * 0.5)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusXL)
                .fill(AppTheme.Gradients.primary)
                .frame(height: 120)

            VStack(spacing: 8) {
                Image("chip-purple")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)

                Text("VP Academy")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                if let summary = viewModel.trainingSummary {
                    Text("\(summary.completedLessons)/\(summary.totalLessons) lessons completed")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }
            }
        }
    }

    private var compactHeaderSection: some View {
        HStack(spacing: 12) {
            Image("chip-purple")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("VP Academy")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                if let summary = viewModel.trainingSummary {
                    Text("\(summary.completedLessons)/\(summary.totalLessons) lessons")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }

            Spacer()
        }
    }

    // MARK: - Lessons Section

    private var lessonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Lessons")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                if viewModel.hasCompletedAllLessons {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.mintGreen)
                }
            }

            ForEach(viewModel.lessons) { lesson in
                LessonRowView(
                    lesson: lesson,
                    progress: viewModel.progressFor(lesson.id)
                ) {
                    navigationPath.append(AppScreen.lessonDetail(lessonId: lesson.id))
                }
            }

            if viewModel.lessons.isEmpty {
                emptyStateView(
                    icon: "book.closed",
                    message: "No lessons available yet"
                )
            }
        }
    }

    // MARK: - Drills Section

    private var drillsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Drills")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.drills) { drill in
                    DrillCardView(
                        drill: drill,
                        stats: viewModel.statsFor(drill.id)
                    ) {
                        navigationPath.append(AppScreen.drillPlay(drillId: drill.id))
                    }
                }
            }
        }
    }

    // MARK: - Review Section

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review Queue")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            Button {
                navigationPath.append(AppScreen.reviewQueue)
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.Colors.mintGreen)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Review Mistakes")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        if viewModel.reviewDueCount > 0 {
                            Text("\(viewModel.reviewDueCount) items due for review")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        } else {
                            Text("No items to review")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }

                    Spacer()

                    if viewModel.reviewDueCount > 0 {
                        Text("\(viewModel.reviewDueCount)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.red)
                            )
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.Colors.cardBackground)
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.reviewDueCount == 0)
            .opacity(viewModel.reviewDueCount == 0 ? 0.5 : 1)
        }
    }

    // MARK: - Empty State

    private func emptyStateView(icon: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppTheme.Colors.textSecondary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - Lesson Row View

struct LessonRowView: View {
    let lesson: Lesson
    let progress: LessonProgress
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Status indicator
                statusIcon

                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text(lesson.description)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                // Score badge if completed
                if progress.status == .completed {
                    Text("\(progress.bestScore)/\(lesson.quizSize)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.Colors.mintGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .stroke(AppTheme.Colors.mintGreen, lineWidth: 1)
                        )
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.Colors.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch progress.status {
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(AppTheme.Colors.mintGreen)
        case .inProgress:
            Image(systemName: "play.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.yellow)
        case .notStarted:
            Image(systemName: "circle")
                .font(.system(size: 24))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
}

// MARK: - Drill Card View

struct DrillCardView: View {
    let drill: Drill
    let stats: DrillStats
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: drill.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.Colors.mintGreen)

                Text(drill.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if stats.totalSessions > 0 {
                    Text("\(Int(stats.accuracy))% accuracy")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                } else {
                    Text("Not started")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.Colors.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }
}
