import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var username = ""
    @State private var isSignUp = false
    @State private var showForgotPassword = false
    @State private var networkMonitor = NetworkMonitor.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient (dark green to black)
                AppTheme.Gradients.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Login/Register Segmented Control
                        HStack(spacing: 0) {
                            Button {
                                isSignUp = false
                            } label: {
                                Text("Login")
                                    .font(.system(size: AppTheme.Typography.headline, weight: .semibold))
                                    .foregroundColor(isSignUp ? AppTheme.Colors.textSecondary : .black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(isSignUp ? AppTheme.Colors.buttonSecondary : .white)
                            }

                            Button {
                                isSignUp = true
                            } label: {
                                Text("Register")
                                    .font(.system(size: AppTheme.Typography.headline, weight: .semibold))
                                    .foregroundColor(isSignUp ? .black : AppTheme.Colors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(isSignUp ? .white : AppTheme.Colors.buttonSecondary)
                            }
                        }
                        .cornerRadius(AppTheme.Layout.cornerRadiusButton)
                        .padding(.horizontal, AppTheme.Layout.paddingLarge)
                        .padding(.top, AppTheme.Layout.paddingXLarge)

                        // Form fields
                        VStack(alignment: .leading, spacing: 16) {
                            if isSignUp {
                                // Full Name
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Full Name*")
                                        .font(.system(size: AppTheme.Typography.callout))
                                        .foregroundColor(.white)

                                    TextField("Enter full name", text: $fullName)
                                        .inputField()
                                        .textContentType(.name)
                                }

                                // Username
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Username*")
                                        .font(.system(size: AppTheme.Typography.callout))
                                        .foregroundColor(.white)

                                    TextField("Enter username", text: $username)
                                        .inputField()
                                        .textContentType(.username)
                                        .autocapitalization(.none)
                                }
                            }

                            // Email
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email Address\(isSignUp ? "*" : "")")
                                    .font(.system(size: AppTheme.Typography.callout))
                                    .foregroundColor(.white)

                                TextField("", text: $email)
                                    .inputField()
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                            }

                            // Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password\(isSignUp ? "*" : "")")
                                    .font(.system(size: AppTheme.Typography.callout))
                                    .foregroundColor(.white)

                                SecureField("**********", text: $password)
                                    .inputField()
                                    .textContentType(isSignUp ? .newPassword : .password)
                            }

                            if isSignUp {
                                // Confirm Password
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Confirm Password*")
                                        .font(.system(size: AppTheme.Typography.callout))
                                        .foregroundColor(.white)

                                    SecureField("**********", text: $confirmPassword)
                                        .inputField()
                                        .textContentType(.newPassword)
                                }
                            }

                            // Forgot password link (login only)
                            if !isSignUp {
                                HStack {
                                    Spacer()
                                    Button {
                                        showForgotPassword = true
                                    } label: {
                                        Text("Forgot Password?")
                                            .font(.system(size: AppTheme.Typography.callout))
                                            .foregroundColor(AppTheme.Colors.mintGreen)
                                            .underline()
                                    }
                                }
                            }

                            // Error message
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(error.contains("created") ? AppTheme.Colors.success : AppTheme.Colors.danger)
                                    .multilineTextAlignment(.center)
                            }

                            // Get Started button
                            Button {
                                Task {
                                    if isSignUp {
                                        await viewModel.signUpWithEmail(email: email, password: password)
                                    } else {
                                        await viewModel.signInWithEmail(email: email, password: password)
                                    }
                                }
                            } label: {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: AppTheme.Layout.buttonHeight)
                                } else {
                                    Text("Get Started")
                                        .primaryButton(isEnabled: networkMonitor.isOnline)
                                }
                            }
                            .disabled(viewModel.isLoading || !networkMonitor.isOnline)

                            // Or login with divider
                            HStack {
                                Rectangle()
                                    .fill(AppTheme.Colors.textTertiary)
                                    .frame(height: 1)

                                Text("Or login with")
                                    .font(.system(size: AppTheme.Typography.callout))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                    .padding(.horizontal, 8)

                                Rectangle()
                                    .fill(AppTheme.Colors.textTertiary)
                                    .frame(height: 1)
                            }
                            .padding(.top, 8)

                            // Social login buttons
                            HStack(spacing: 16) {
                                // Google
                                Button {
                                    Task {
                                        await viewModel.signInWithGoogle()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "g.circle.fill")
                                        Text("Google")
                                    }
                                    .secondaryButton(isEnabled: networkMonitor.isOnline)
                                }
                                .disabled(viewModel.isLoading || !networkMonitor.isOnline)

                                // Magic Link
                                Button {
                                    Task {
                                        await viewModel.signInWithMagicLink(email: email)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "link.circle.fill")
                                        Text("Magic Link")
                                    }
                                    .secondaryButton(isEnabled: networkMonitor.isOnline && !email.isEmpty)
                                }
                                .disabled(email.isEmpty || viewModel.isLoading || !networkMonitor.isOnline)
                            }

                            #if DEBUG
                            // Quick login for dev
                            Button {
                                Task {
                                    await viewModel.quickLogin()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "bolt.fill")
                                    Text("Quick Login (Dev)")
                                }
                                .secondaryButton(isEnabled: networkMonitor.isOnline)
                            }
                            .disabled(viewModel.isLoading || !networkMonitor.isOnline)
                            #endif
                        }
                        .padding(.horizontal, AppTheme.Layout.paddingLarge)
                    }
                }
            }
            .navigationDestination(isPresented: $showForgotPassword) {
                ForgotPasswordView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    AuthView()
}
