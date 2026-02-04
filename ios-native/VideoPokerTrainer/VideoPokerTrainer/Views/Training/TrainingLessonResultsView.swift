import SwiftUI

struct TrainingLessonResultsView: View {
    @ObservedObject var viewModel: TrainingLessonQuizViewModel
    @Binding var navigationPath: NavigationPath

    private var isPerfect: Bool {
        viewModel.correctCount == viewModel.hands.count
    }

    private var hasNextLesson: Bool {
        viewModel.lesson.number < TrainingLesson.allLessons.count
    }

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                LinearGradient(
                    colors: [Color(hex: "0a0a1a"), Color(hex: "1a1a3a"), Color(hex: "0a0a1a")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    resultIcon

                    scoreDisplay

                    resultMessage

                    Spacer()

                    if isLandscape {
                        HStack(spacing: 16) {
                            actionButtons
                        }
                    } else {
                        VStack(spacing: 12) {
                            actionButtons
                        }
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Result Icon

    private var resultIcon: some View {
        ZStack {
            Circle()
                .fill(isPerfect ? AppTheme.Colors.mintGreen.opacity(0.2) : Color.orange.opacity(0.2))
                .frame(width: 100, height: 100)

            Image(systemName: isPerfect ? "checkmark.circle.fill" : "arrow.counterclockwise.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(isPerfect ? AppTheme.Colors.mintGreen : .orange)
        }
    }

    // MARK: - Score Display

    private var scoreDisplay: some View {
        VStack(spacing: 8) {
            Text("\(viewModel.correctCount)/\(viewModel.hands.count)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)

            Text(isPerfect ? "Perfect Score!" : "Keep practicing!")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(isPerfect ? AppTheme.Colors.mintGreen : .orange)
        }
    }

    // MARK: - Result Message

    private var resultMessage: some View {
        Group {
            if isPerfect {
                Text("You've mastered Lesson \(viewModel.lesson.number): \(viewModel.lesson.title)")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Get all \(viewModel.hands.count) correct to complete this lesson. Review the material and try again.")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        if isPerfect && hasNextLesson {
            // Next Lesson (primary CTA when perfect and more lessons exist)
            Button {
                let nextLessonNumber = viewModel.lesson.number + 1
                // Pop quiz + content from path, then push next lesson's content
                if navigationPath.count >= 2 {
                    navigationPath.removeLast(2)
                } else {
                    navigationPath.removeLast(navigationPath.count)
                }
                navigationPath.append(AppScreen.trainingLessonContent(lessonNumber: nextLessonNumber))
            } label: {
                HStack {
                    Text("Next Lesson")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "667eea"))

            // Practice Again (secondary when perfect)
            Button {
                viewModel.reset()
            } label: {
                Text("Practice Again")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        } else if isPerfect {
            // Last lesson, perfect score — go back to lesson list
            Button {
                if navigationPath.count >= 2 {
                    navigationPath.removeLast(2)
                } else {
                    navigationPath.removeLast(navigationPath.count)
                }
            } label: {
                HStack {
                    Image(systemName: "list.bullet")
                    Text("Lesson List")
                }
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "667eea"))

            // Practice Again (secondary)
            Button {
                viewModel.reset()
            } label: {
                Text("Practice Again")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        } else {
            // Not perfect — try again
            Button {
                viewModel.reset()
            } label: {
                Text("Try Again")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "667eea"))

            // Back to Lessons
            Button {
                if navigationPath.count >= 2 {
                    navigationPath.removeLast(2)
                } else {
                    navigationPath.removeLast(navigationPath.count)
                }
            } label: {
                Text("Back to Lessons")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
}
