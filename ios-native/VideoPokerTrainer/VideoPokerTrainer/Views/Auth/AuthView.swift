import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showForgotPassword = false
    @State private var networkMonitor = NetworkMonitor.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
            Spacer()

            // Logo/Title
            VStack(spacing: 8) {
                Image(systemName: "suit.spade.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "667eea"))

                Text("VP Academy")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Master Video Poker Strategy")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Form
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(isSignUp ? .newPassword : .password)

                // Forgot password link (only show when signing in)
                if !isSignUp {
                    HStack {
                        Spacer()
                        Button {
                            showForgotPassword = true
                        } label: {
                            Text("Forgot Password?")
                                .font(.caption)
                                .foregroundColor(Color(hex: "667eea"))
                        }
                    }
                }

                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(error.contains("created") ? .green : .red)
                        .multilineTextAlignment(.center)
                }

                // Offline indicator
                if !networkMonitor.isOnline {
                    Label("Sign in requires internet connection", systemImage: "wifi.slash")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                // Main action button
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
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "667eea"))
                .disabled(viewModel.isLoading || !networkMonitor.isOnline)
                .opacity(networkMonitor.isOnline ? 1.0 : 0.5)

                // Toggle sign up/sign in
                Button {
                    isSignUp.toggle()
                    viewModel.errorMessage = nil
                } label: {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.caption)
                }
            }
            .padding(.horizontal)

            Divider()
                .padding(.horizontal)

            // Magic link sign in
            Button {
                Task {
                    await viewModel.signInWithMagicLink(email: email)
                }
            } label: {
                HStack {
                    Image(systemName: "link.circle.fill")
                    Text("Send Magic Link")
                }
            }
            .buttonStyle(.bordered)
            .tint(Color(hex: "3498db"))
            .disabled(email.isEmpty || viewModel.isLoading || !networkMonitor.isOnline)
            .opacity(networkMonitor.isOnline ? 1.0 : 0.5)

            // Google Sign-In
            Button {
                Task {
                    await viewModel.signInWithGoogle()
                }
            } label: {
                HStack {
                    Image(systemName: "g.circle.fill")
                    Text("Continue with Google")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.primary)
            .disabled(viewModel.isLoading || !networkMonitor.isOnline)
            .opacity(networkMonitor.isOnline ? 1.0 : 0.5)

            #if DEBUG
            Divider()
                .padding(.horizontal)

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
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isLoading || !networkMonitor.isOnline)
            .opacity(networkMonitor.isOnline ? 1.0 : 0.5)
            #endif

                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $showForgotPassword) {
                ForgotPasswordView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    AuthView()
}
