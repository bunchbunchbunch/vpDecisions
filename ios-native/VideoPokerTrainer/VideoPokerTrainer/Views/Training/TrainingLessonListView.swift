import SwiftUI

struct TrainingLessonListView: View {
    @StateObject private var viewModel = TrainingLessonListViewModel()
    @Binding var navigationPath: NavigationPath

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                AppTheme.Gradients.background
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
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
        .onAppear {
            viewModel.load()
        }
    }

    // MARK: - Portrait Layout

    private var portraitLayout: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                lessonsSection
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Landscape Layout

    private func landscapeLayout(geometry: GeometryProxy) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Left column: header
            VStack(spacing: 12) {
                compactHeaderSection
                Spacer()
            }
            .frame(width: (geometry.size.width - 48) * 0.35)

            // Right column: lessons list
            ScrollView(showsIndicators: false) {
                lessonsSection
            }
            .frame(width: (geometry.size.width - 48) * 0.65)
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
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)

                Text("VP Academy")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("\(viewModel.completedCount)/\(viewModel.totalCount) lessons completed")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
            }
        }
    }

    private var compactHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.Colors.mintGreen)

                VStack(alignment: .leading, spacing: 2) {
                    Text("VP Academy")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text("\(viewModel.completedCount)/\(viewModel.totalCount) lessons")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Colors.mintGreen)
                        .frame(width: geo.size.width * (viewModel.totalCount > 0 ? Double(viewModel.completedCount) / Double(viewModel.totalCount) : 0))
                }
            }
            .frame(height: 6)
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

                if viewModel.hasCompletedAll {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.mintGreen)
                }
            }

            ForEach(viewModel.lessons) { lesson in
                TrainingLessonRow(
                    lesson: lesson,
                    score: viewModel.scoreFor(lesson.number),
                    status: viewModel.statusFor(lesson.number),
                    isRecommended: lesson.number == viewModel.recommendedLessonNumber
                ) {
                    navigationPath.append(AppScreen.trainingLessonContent(lessonNumber: lesson.number))
                }
            }
        }
    }
}

// MARK: - Training Lesson Row

struct TrainingLessonRow: View {
    let lesson: TrainingLesson
    let score: TrainingLessonScore
    let status: TrainingLessonStatus
    let isRecommended: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Status indicator
                statusIcon

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Lesson \(lesson.number)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)

                        if isRecommended && status != .completed {
                            Text("NEXT")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color(hex: "667eea")))
                        }
                    }

                    Text(lesson.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                // Score badge
                if score.attempts > 0 {
                    Text("\(score.bestScore)/\(lesson.practiceHands.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(score.completed ? AppTheme.Colors.mintGreen : .orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .stroke(score.completed ? AppTheme.Colors.mintGreen : .orange, lineWidth: 1)
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
        switch status {
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
