import SwiftUI

struct EditProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var isSaving = false
    @State private var showSuccessMessage = false

    private var userEmail: String {
        authViewModel.currentUser?.email ?? "No email"
    }

    var body: some View {
        ZStack {
            AppTheme.Gradients.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Profile Avatar
                    VStack(spacing: 12) {
                        Circle()
                            .fill(AppTheme.Colors.mintGreen)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(avatarInitial)
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(AppTheme.Colors.darkGreen)
                            )

                        Text("Edit Profile")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)

                    // Form Fields
                    VStack(spacing: 20) {
                        // Display Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Display Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.Colors.textSecondary)

                            TextField("Enter your name", text: $fullName)
                                .foregroundColor(.white)
                                .padding()
                                .background(AppTheme.Colors.cardBackground)
                                .cornerRadius(12)
                        }

                        // Email (Read-only)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.Colors.textSecondary)

                            HStack {
                                Text(userEmail)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                            }
                            .padding()
                            .background(AppTheme.Colors.cardBackground.opacity(0.5))
                            .cornerRadius(12)

                            Text("Email cannot be changed")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }

                        // Success message
                        if showSuccessMessage {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.Colors.success)
                                Text("Profile updated successfully!")
                                    .foregroundColor(AppTheme.Colors.success)
                            }
                            .font(.system(size: 14))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.Colors.success.opacity(0.15))
                            .cornerRadius(12)
                        }

                        // Error message
                        if let errorMessage = authViewModel.errorMessage,
                           !errorMessage.contains("successfully") {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.Colors.danger)
                                .multilineTextAlignment(.center)
                        }

                        // Save Button
                        Button {
                            Task {
                                isSaving = true
                                await authViewModel.updateProfile(fullName: fullName)
                                isSaving = false

                                if authViewModel.errorMessage?.contains("successfully") == true {
                                    showSuccessMessage = true
                                    authViewModel.errorMessage = nil

                                    // Auto-dismiss after success
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        dismiss()
                                    }
                                }
                            }
                        } label: {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.darkGreen))
                                    .primaryButton()
                            } else {
                                Text("Save Changes")
                                    .primaryButton(isEnabled: !fullName.isEmpty)
                            }
                        }
                        .disabled(fullName.isEmpty || isSaving)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Edit Profile")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            // Load existing name from user metadata if available
            if let existingName = authViewModel.currentUser?.userMetadata["full_name"]?.stringValue {
                fullName = existingName
            }
        }
    }

    private var avatarInitial: String {
        if !fullName.isEmpty {
            return String(fullName.prefix(1).uppercased())
        }
        return String(userEmail.prefix(1).uppercased())
    }
}

#Preview {
    NavigationStack {
        EditProfileView(authViewModel: AuthViewModel())
    }
}
