import SwiftUI

struct ResetPasswordView: View {
    @StateObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var passwordUpdated = false

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let maxContentWidth: CGFloat = isLandscape ? min(450, geometry.size.width - 48) : .infinity

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "key.fill")
                            .font(.system(size: isLandscape ? 50 : 60))
                            .foregroundColor(Color(hex: "667eea"))

                        Text("Create New Password")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Enter your new password below")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, isLandscape ? 20 : 40)

                    if !passwordUpdated {
                        // Password inputs
                        VStack(spacing: 16) {
                            // New password
                            HStack {
                                if showPassword {
                                    TextField("New Password", text: $newPassword)
                                } else {
                                    SecureField("New Password", text: $newPassword)
                                }

                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)

                            // Confirm password
                            HStack {
                                if showPassword {
                                    TextField("Confirm Password", text: $confirmPassword)
                                } else {
                                    SecureField("Confirm Password", text: $confirmPassword)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)

                            // Password requirements
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: newPassword.count >= 6 ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(newPassword.count >= 6 ? .green : .gray)
                                    Text("At least 6 characters")
                                        .font(.caption)
                                }

                                HStack {
                                    Image(systemName: !confirmPassword.isEmpty && newPassword == confirmPassword ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(!confirmPassword.isEmpty && newPassword == confirmPassword ? .green : .gray)
                                    Text("Passwords match")
                                        .font(.caption)
                                }
                            }
                            .padding(.horizontal)

                            // Error message
                            if let errorMessage = viewModel.errorMessage,
                               !errorMessage.contains("successfully") {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                            }

                            // Update button
                            Button {
                                Task {
                                    guard newPassword == confirmPassword else {
                                        viewModel.errorMessage = "Passwords don't match"
                                        return
                                    }

                                    await viewModel.updatePassword(newPassword: newPassword)
                                    if viewModel.errorMessage?.contains("successfully") == true {
                                        passwordUpdated = true
                                    }
                                }
                            } label: {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else {
                                    Text("Update Password")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(hex: "667eea"))
                            .disabled(newPassword.count < 6 || newPassword != confirmPassword || viewModel.isLoading)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    } else {
                        // Success state
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: isLandscape ? 60 : 80))
                                .foregroundColor(.green)

                            Text("Password Updated!")
                                .font(.title3)
                                .fontWeight(.bold)

                            Text("Your password has been successfully updated.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Button {
                                dismiss()
                            } label: {
                                Text("Continue")
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
                }
                .frame(maxWidth: maxContentWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    ResetPasswordView(viewModel: AuthViewModel())
}
