import StoreKit
import SwiftUI

struct RatingPromptView: View {
    @ObservedObject private var service = RatingPromptService.shared
    @State private var screen: Screen = .prompt
    @State private var feedbackText = ""
    @State private var isSubmitting = false

    private enum Screen { case prompt, feedback }

    var body: some View {
        ZStack {
            AppTheme.Gradients.background
                .ignoresSafeArea()

            switch screen {
            case .prompt:
                promptScreen
            case .feedback:
                feedbackScreen
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Screen 1: Prompt

    private var promptScreen: some View {
        VStack(spacing: 28) {
            Image(systemName: "star.fill")
                .font(.system(size: 52))
                .foregroundColor(.yellow)

            VStack(spacing: 12) {
                Text("Enjoying Video Poker Academy?")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Your rating helps other players find the app.")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button {
                    requestReview()
                    service.dismiss()
                } label: {
                    Text("Yes, love it! ★")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppTheme.Colors.mintGreen)
                        .cornerRadius(26)
                }

                Button {
                    screen = .feedback
                } label: {
                    Text("Not really")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding(32)
    }

    // MARK: - Screen 2: Feedback Form

    private var feedbackScreen: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What could we do better?")
                .font(.title2.bold())
                .foregroundColor(.white)

            TextEditor(text: $feedbackText)
                .frame(minHeight: 120)
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
                .overlay(alignment: .topLeading) {
                    if feedbackText.isEmpty {
                        Text("Share your thoughts...")
                            .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.6))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }

            HStack {
                Button("Skip") {
                    service.dismiss()
                }
                .foregroundColor(AppTheme.Colors.textSecondary)

                Spacer()

                Button("Send Feedback") {
                    isSubmitting = true
                    Task {
                        await service.submitFeedback(feedbackText)
                        isSubmitting = false
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isSendEnabled ? AppTheme.Colors.mintGreen : Color.gray.opacity(0.5))
                .cornerRadius(22)
                .disabled(!isSendEnabled)
            }
        }
        .padding(32)
    }

    // MARK: - Helpers

    private var isSendEnabled: Bool {
        !feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSubmitting
    }

    private func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}

#Preview {
    RatingPromptView()
}
