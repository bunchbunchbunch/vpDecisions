import SwiftUI

struct WelcomeView: View {
    @Binding var showAuth: Bool

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                // Background gradient
                AppTheme.Gradients.background
                    .ignoresSafeArea()

                if isLandscape {
                    // Landscape: side by side layout
                    HStack(spacing: 32) {
                        // Left: Logo
                        VStack(spacing: 16) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppTheme.Colors.mintGreen)

                            Text("Video Poker")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)

                            Text("Academy")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)

                        // Right: Content + button
                        VStack(spacing: 16) {
                            Spacer()

                            VStack(spacing: 8) {
                                Text("Play Smarter.")
                                    .font(.system(size: 28, weight: .regular))
                                    .foregroundColor(.white)

                                Text("Win Better.")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)

                                Text("Train your video poker skills with proven strategies and real-time feedback.")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 4)
                            }

                            Spacer()

                            Button {
                                showAuth = true
                            } label: {
                                Text("Get Started")
                                    .primaryButton()
                            }
                            .padding(.bottom, 16)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                    }
                    .padding()
                } else {
                    // Portrait: vertical layout
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
    }
}

#Preview {
    WelcomeView(showAuth: .constant(false))
}
