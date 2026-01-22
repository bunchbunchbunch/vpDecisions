import SwiftUI

struct WelcomeView: View {
    @Binding var showAuth: Bool

    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.Gradients.background
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo
                VStack(spacing: 16) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppTheme.Colors.mintGreen)

                    Text("Video Poker")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Academy")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.white)
                }

                Spacer()

                // Headline
                VStack(spacing: 8) {
                    Text("Play Smarter.")
                        .font(.system(size: 36, weight: .regular))
                        .foregroundColor(.white)

                    Text("Win Better.")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)

                    Text("Train your video poker skills with proven\nstrategies and real-time feedback.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }

                Spacer()

                // Get Started button
                Button {
                    showAuth = true
                } label: {
                    Text("Get Started")
                        .primaryButton()
                }
                .padding(.horizontal, AppTheme.Layout.paddingLarge)
                .padding(.bottom, AppTheme.Layout.paddingLarge)
            }
        }
    }
}

#Preview {
    WelcomeView(showAuth: .constant(false))
}
