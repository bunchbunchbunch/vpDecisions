import SwiftUI

struct LessonCompleteView: View {
    @ObservedObject var viewModel: LessonViewModel
    @Binding var navigationPath: NavigationPath
    @Binding var showQuiz: Bool

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            VStack(spacing: 24) {
                Spacer()

                // Result icon
                resultIcon

                // Score
                scoreDisplay

                // Message
                resultMessage

                Spacer()

                // Action buttons
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

    // MARK: - Result Icon

    private var resultIcon: some View {
        ZStack {
            Circle()
                .fill(viewModel.quizPassed ? AppTheme.Colors.mintGreen.opacity(0.2) : Color.orange.opacity(0.2))
                .frame(width: 100, height: 100)

            Image(systemName: viewModel.quizPassed ? "checkmark.circle.fill" : "arrow.counterclockwise.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(viewModel.quizPassed ? AppTheme.Colors.mintGreen : .orange)
        }
    }

    // MARK: - Score Display

    private var scoreDisplay: some View {
        VStack(spacing: 8) {
            Text("\(viewModel.quizScore)/\(viewModel.quizHands.count)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)

            Text(viewModel.quizPassed ? "You passed!" : "Keep practicing!")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(viewModel.quizPassed ? AppTheme.Colors.mintGreen : .orange)
        }
    }

    // MARK: - Result Message

    private var resultMessage: some View {
        Group {
            if viewModel.quizPassed {
                Text("You've mastered the concepts in this lesson.")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            } else if let lesson = viewModel.lesson {
                Text("You need \(lesson.passingScore)/\(lesson.quizSize) to pass. Review the lesson and try again.")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        if viewModel.quizPassed {
            // Continue to next lesson or back to hub
            Button {
                navigationPath.removeLast()
            } label: {
                Text("Continue")
                    .primaryButton()
            }
        } else {
            // Retry or review lesson
            Button {
                viewModel.retryQuiz()
            } label: {
                Text("Try Again")
                    .primaryButton()
            }

            Button {
                showQuiz = false
            } label: {
                Text("Review Lesson")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.Colors.mintGreen)
            }
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
