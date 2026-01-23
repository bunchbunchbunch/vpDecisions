import SwiftUI

struct ChangePasswordView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var passwordUpdated = false

    private var isValid: Bool {
        newPassword.count >= 6 && newPassword == confirmPassword
    }

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let maxContentWidth: CGFloat = isLandscape ? min(500, geometry.size.width - 48) : .infinity

            ZStack {
                AppTheme.Gradients.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "key.fill")
                                .font(.system(size: isLandscape ? 40 : 50))
                                .foregroundColor(AppTheme.Colors.mintGreen)

                            Text("Change Password")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            Text("Enter your new password below")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding(.top, isLandscape ? 16 : 40)

                        if !passwordUpdated {
                            // Password inputs
                            VStack(spacing: 16) {
                                // New password
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("New Password")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppTheme.Colors.textSecondary)

                                    HStack {
                                        if showPassword {
                                            TextField("Enter new password", text: $newPassword)
                                                .foregroundColor(.white)
                                        } else {
                                            SecureField("Enter new password", text: $newPassword)
                                                .foregroundColor(.white)
                                        }

                                        Button {
                                            showPassword.toggle()
                                        } label: {
                                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                                .foregroundColor(AppTheme.Colors.textSecondary)
                                        }
                                    }
                                    .padding()
                                    .background(AppTheme.Colors.cardBackground)
                                    .cornerRadius(12)
                                }

                                // Confirm password
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Confirm Password")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppTheme.Colors.textSecondary)

                                    HStack {
                                        if showPassword {
                                            TextField("Confirm new password", text: $confirmPassword)
                                                .foregroundColor(.white)
                                        } else {
                                            SecureField("Confirm new password", text: $confirmPassword)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding()
                                    .background(AppTheme.Colors.cardBackground)
                                    .cornerRadius(12)
                                }

                                // Password requirements
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: newPassword.count >= 6 ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(newPassword.count >= 6 ? AppTheme.Colors.success : AppTheme.Colors.textSecondary)
                                            .font(.system(size: 16))
                                        Text("At least 6 characters")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppTheme.Colors.textSecondary)
                                    }

                                    HStack(spacing: 8) {
                                        Image(systemName: !confirmPassword.isEmpty && newPassword == confirmPassword ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(!confirmPassword.isEmpty && newPassword == confirmPassword ? AppTheme.Colors.success : AppTheme.Colors.textSecondary)
                                            .font(.system(size: 16))
                                        Text("Passwords match")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppTheme.Colors.textSecondary)
                                    }
                                }
                                .padding(.top, 8)

                                // Error message
                                if let errorMessage = authViewModel.errorMessage,
                                   !errorMessage.contains("successfully") {
                                    Text(errorMessage)
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.Colors.danger)
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 8)
                                }

                                // Update button
                                Button {
                                    Task {
                                        guard newPassword == confirmPassword else {
                                            authViewModel.errorMessage = "Passwords don't match"
                                            return
                                        }

                                        await authViewModel.updatePassword(newPassword: newPassword)
                                        if authViewModel.errorMessage?.contains("successfully") == true {
                                            passwordUpdated = true
                                        }
                                    }
                                } label: {
                                    if authViewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.darkGreen))
                                            .primaryButton(isEnabled: true)
                                    } else {
                                        Text("Update Password")
                                            .primaryButton(isEnabled: isValid)
                                    }
                                }
                                .disabled(!isValid || authViewModel.isLoading)
                                .padding(.top, 16)
                            }
                            .padding(.horizontal)
                        } else {
                            // Success state
                            VStack(spacing: 20) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: isLandscape ? 50 : 70))
                                    .foregroundColor(AppTheme.Colors.success)

                                Text("Password Updated!")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)

                                Text("Your password has been successfully updated.")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)

                                Button {
                                    dismiss()
                                } label: {
                                    Text("Continue")
                                        .primaryButton()
                                }
                                .padding(.horizontal)
                                .padding(.top, 16)
                            }
                            .padding()
                        }

                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: maxContentWidth)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Change Password")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChangePasswordView(authViewModel: AuthViewModel())
    }
}
