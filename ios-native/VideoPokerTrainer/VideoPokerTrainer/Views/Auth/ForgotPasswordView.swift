import SwiftUI

struct ForgotPasswordView: View {
    @StateObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var emailSent = false
    @State private var networkMonitor = NetworkMonitor.shared

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let maxContentWidth: CGFloat = isLandscape ? min(450, geometry.size.width - 48) : .infinity

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: isLandscape ? 50 : 60))
                            .foregroundColor(Color(hex: "667eea"))

                        Text("Reset Password")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Enter your email and we'll send you a link to reset your password")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, isLandscape ? 20 : 40)

                    if !emailSent {
                        // Email input
                        VStack(spacing: 16) {
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .padding(.horizontal)

                            // Error message
                            if let errorMessage = viewModel.errorMessage,
                               !errorMessage.contains("sent") {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                            }

                            // Offline indicator
                            if !networkMonitor.isOnline {
                                Label("Password reset requires internet connection", systemImage: "wifi.slash")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal)
                            }

                            // Send reset button
                            Button {
                                Task {
                                    await viewModel.resetPassword(email: email)
                                    if viewModel.errorMessage?.contains("sent") == true {
                                        emailSent = true
                                    }
                                }
                            } label: {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else {
                                    Text("Send Reset Link")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(hex: "667eea"))
                            .disabled(email.isEmpty || viewModel.isLoading || !networkMonitor.isOnline)
                            .opacity(networkMonitor.isOnline ? 1.0 : 0.5)
                            .padding(.horizontal)
                        }
                    } else {
                        // Success state
                        VStack(spacing: 16) {
                            Image(systemName: "envelope.circle.fill")
                                .font(.system(size: isLandscape ? 60 : 80))
                                .foregroundColor(.green)

                            Text("Check Your Email!")
                                .font(.title3)
                                .fontWeight(.bold)

                            Text("We've sent a password reset link to:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(email)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: "667eea"))

                            Text("Click the link in the email to reset your password.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.top, 8)

                            Button {
                                dismiss()
                            } label: {
                                Text("Back to Login")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(hex: "667eea"))
                            .padding(.horizontal)
                            .padding(.top, 24)
                        }
                        .padding()
                    }

                    Spacer(minLength: 20)

                    // Back button
                    if !emailSent {
                        Button {
                            dismiss()
                        } label: {
                            Text("Back to Login")
                                .foregroundColor(Color(hex: "667eea"))
                        }
                        .padding(.bottom, isLandscape ? 20 : 40)
                    }
                }
                .frame(maxWidth: maxContentWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    ForgotPasswordView(viewModel: AuthViewModel())
}
