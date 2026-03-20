import SwiftUI

struct TrainingLessonContentView: View {
    let lesson: TrainingLesson
    @Binding var navigationPath: NavigationPath

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                AppTheme.Gradients.background
                    .ignoresSafeArea()

                if isLandscape {
                    landscapeLayout(geometry: geometry)
                } else {
                    portraitLayout
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Lesson \(lesson.number)")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Portrait Layout

    private var portraitLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                titleSection
                keyConceptSection
                whatToLearnSection
                commonMistakesSection
                startQuizButton
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Landscape Layout

    private func landscapeLayout(geometry: GeometryProxy) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Left column: title and concept
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    titleSection
                    keyConceptSection
                }
            }
            .frame(width: (geometry.size.width - 48) * 0.45)

            // Right column: learn, mistakes, start button
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    whatToLearnSection
                    commonMistakesSection
                    startQuizButton
                }
            }
            .frame(width: (geometry.size.width - 48) * 0.55)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Sections

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lesson \(lesson.number)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.Colors.mintGreen)

            Text(lesson.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            Text("\(lesson.practiceHands.count) practice hands")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }

    private var keyConceptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Key Concept", systemImage: "lightbulb.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.yellow)

            Text(lesson.keyConcept)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.cardBackground)
        )
    }

    private var whatToLearnSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What You'll Learn")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            ForEach(Array(lesson.whatToLearn.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.mintGreen)
                        .padding(.top, 2)

                    Text(item)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.cardBackground)
        )
    }

    private var commonMistakesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Common Mistakes")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            ForEach(Array(lesson.commonMistakes.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                        .padding(.top, 2)

                    Text(item)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.cardBackground)
        )
    }

    private var startQuizButton: some View {
        Button {
            navigationPath.append(AppScreen.trainingLessonQuiz(lessonNumber: lesson.number))
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Start Quiz (\(lesson.practiceHands.count) hands)")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color(hex: "667eea"))
    }
}
