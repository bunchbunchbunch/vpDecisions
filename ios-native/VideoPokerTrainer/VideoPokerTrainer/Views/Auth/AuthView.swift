import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var isSignUp = false
    @State private var showForgotPassword = false
    @State private var networkMonitor = NetworkMonitor.shared

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isLandscape = geometry.size.width > geometry.size.height
                let maxContentWidth: CGFloat = isLandscape ? min(440, geometry.size.width - 48) : .infinity

                ZStack {
                    AppTheme.Gradients.background
                        .ignoresSafeArea()

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Header with logo
                            headerSection
                                .padding(.top, isLandscape ? 20 : 40)
                                .padding(.bottom, 32)

                            // Main content card
                            VStack(spacing: 24) {
                                // Mode toggle
                                modeToggle

                                // Form fields
                                formFields

                                // Primary action button
                                primaryActionButton

                                // Divider
                                dividerWithText("or continue with")
                                    .padding(.top, 8)

                                // Social login buttons
                                socialLoginButtons
                            }
                            .padding(24)
                            .background(AppTheme.Colors.cardBackground.opacity(0.6))
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                            .padding(.horizontal, 20)

                            Spacer(minLength: 40)
                        }
                        .frame(maxWidth: maxContentWidth)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationDestination(isPresented: $showForgotPassword) {
                ForgotPasswordView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // App icon
            Image(systemName: "play.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.Colors.mintGreen, AppTheme.Colors.mintGreen.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: AppTheme.Colors.mintGreen.opacity(0.3), radius: 20, x: 0, y: 10)

            VStack(spacing: 4) {
                Text(isSignUp ? "Create Account" : "Welcome Back")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text(isSignUp ? "Start your training journey" : "Sign in to continue")
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSignUp)
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        HStack(spacing: 0) {
            toggleButton(title: "Sign In", isActive: !isSignUp) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isSignUp = false
                }
            }

            toggleButton(title: "Sign Up", isActive: isSignUp) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isSignUp = true
                }
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.3))
        .cornerRadius(14)
    }

    private func toggleButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isActive ? .black : AppTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isActive ? AppTheme.Colors.mintGreen : Color.clear)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Form Fields

    private var formFields: some View {
        VStack(spacing: 16) {
            if isSignUp {
                // Full Name field
                inputField(
                    icon: "person.fill",
                    placeholder: "Full Name",
                    text: $fullName,
                    contentType: .name
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }

            // Email field
            inputField(
                icon: "envelope.fill",
                placeholder: "Email",
                text: $email,
                contentType: .emailAddress,
                keyboardType: .emailAddress,
                autocapitalization: .never
            )

            // Password field
            secureInputField(
                icon: "lock.fill",
                placeholder: "Password",
                text: $password,
                contentType: isSignUp ? .newPassword : .password
            )

            if isSignUp {
                // Confirm Password field
                secureInputField(
                    icon: "lock.fill",
                    placeholder: "Confirm Password",
                    text: $confirmPassword,
                    contentType: .newPassword
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }

            // Forgot password link (login only)
            if !isSignUp {
                HStack {
                    Spacer()
                    Button {
                        showForgotPassword = true
                    } label: {
                        Text("Forgot Password?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.Colors.mintGreen)
                    }
                }
                .padding(.top, -4)
            }

            // Error/Success message
            if let message = viewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: message.contains("created") || message.contains("success") ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                    Text(message)
                        .font(.system(size: 14))
                }
                .foregroundColor(message.contains("created") || message.contains("success") ? AppTheme.Colors.success : AppTheme.Colors.danger)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSignUp)
    }

    private func inputField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        contentType: UITextContentType? = nil,
        keyboardType: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .sentences
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(width: 24)

            TextField(placeholder, text: text)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .textContentType(contentType)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func secureInputField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        contentType: UITextContentType? = nil
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(width: 24)

            SecureField(placeholder, text: text)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .textContentType(contentType)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Primary Action Button

    private var primaryActionButton: some View {
        Button {
            Task {
                if isSignUp {
                    if password != confirmPassword {
                        viewModel.errorMessage = "Passwords don't match"
                        return
                    }
                    await viewModel.signUpWithEmail(email: email, password: password)
                } else {
                    await viewModel.signInWithEmail(email: email, password: password)
                }
            }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text(isSignUp ? "Create Account" : "Sign In")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: networkMonitor.isOnline
                        ? [AppTheme.Colors.mintGreen, AppTheme.Colors.mintGreen.opacity(0.85)]
                        : [Color.gray, Color.gray.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(14)
            .shadow(color: networkMonitor.isOnline ? AppTheme.Colors.mintGreen.opacity(0.3) : .clear, radius: 12, x: 0, y: 6)
        }
        .disabled(viewModel.isLoading || !networkMonitor.isOnline)
        .animation(.easeInOut(duration: 0.2), value: isSignUp)
    }

    // MARK: - Divider

    private func dividerWithText(_ text: String) -> some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 1)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.Colors.textTertiary)

            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 1)
        }
    }

    // MARK: - Social Login Buttons

    private var socialLoginButtons: some View {
        VStack(spacing: 12) {
            // Apple Sign In
            Button {
                Task { await viewModel.signInWithApple() }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18, weight: .medium))
                    Text("Continue with Apple")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.black)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(viewModel.isLoading || !networkMonitor.isOnline)

            // Google Sign In - styled like official Google button
            Button {
                Task { await viewModel.signInWithGoogle() }
            } label: {
                HStack(spacing: 12) {
                    // Google "G" logo with official colors
                    googleLogo
                        .frame(width: 18, height: 18)

                    Text("Continue with Google")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(white: 0.25))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
            }
            .disabled(viewModel.isLoading || !networkMonitor.isOnline)
        }
    }

    // Google's official "G" logo with brand colors
    private var googleLogo: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                // Blue arc (right side)
                Circle()
                    .trim(from: 0.625, to: 0.875)
                    .stroke(Color(red: 66/255, green: 133/255, blue: 244/255), lineWidth: size * 0.18)
                // Green arc (bottom)
                Circle()
                    .trim(from: 0.875, to: 1.0)
                    .stroke(Color(red: 52/255, green: 168/255, blue: 83/255), lineWidth: size * 0.18)
                Circle()
                    .trim(from: 0.0, to: 0.125)
                    .stroke(Color(red: 52/255, green: 168/255, blue: 83/255), lineWidth: size * 0.18)
                // Yellow arc (left-bottom)
                Circle()
                    .trim(from: 0.125, to: 0.375)
                    .stroke(Color(red: 251/255, green: 188/255, blue: 5/255), lineWidth: size * 0.18)
                // Red arc (top-left)
                Circle()
                    .trim(from: 0.375, to: 0.625)
                    .stroke(Color(red: 234/255, green: 67/255, blue: 53/255), lineWidth: size * 0.18)
                // Horizontal bar (blue)
                Rectangle()
                    .fill(Color(red: 66/255, green: 133/255, blue: 244/255))
                    .frame(width: size * 0.5, height: size * 0.18)
                    .offset(x: size * 0.15)
            }
            .rotationEffect(.degrees(-90))
        }
    }
}

#Preview {
    AuthView()
}
