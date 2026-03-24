import LocalAuthentication
import SwiftUI

struct SettingsView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var audioService = AudioService.shared
    @StateObject private var hapticService = HapticService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showDeleteFinalConfirmation = false
    @State private var showAuthenticationError = false
    @State private var authenticationErrorMessage = ""
    #if DEBUG
    @State private var showEVBenchmark = false
    #endif

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let maxContentWidth: CGFloat = isLandscape ? min(600, geometry.size.width - 48) : .infinity

            ZStack {
                AppTheme.Gradients.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // User Profile Card
                        userProfileCard

                        // Account Settings
                        settingsSection(title: "Account") {
                            NavigationLink {
                                EditProfileView(authViewModel: authViewModel)
                            } label: {
                                SettingsRowContent(icon: "person.circle", title: "Edit Profile", subtitle: "Update your display name", showChevron: true)
                            }

                            NavigationLink {
                                ChangePasswordView(authViewModel: authViewModel)
                            } label: {
                                SettingsRowContent(icon: "key", title: "Change Password", subtitle: "Update your password", showChevron: true)
                            }

                            Button {
                                if let url = URL(string: "https://apps.apple.com/app/id6760155052?action=write-review") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                SettingsRowContent(icon: "star.bubble", title: "Rate the App", subtitle: "Enjoying VP Academy? Leave us a review!", showChevron: true)
                            }

                            Button {
                                showDeleteConfirmation = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 18))
                                        .foregroundColor(AppTheme.Colors.danger)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Delete Account")
                                            .font(.system(size: 15))
                                            .foregroundColor(AppTheme.Colors.danger)

                                        Text("Permanently delete your account and data")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.Colors.textSecondary)
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                        }

                        // Sound & Haptics
                        settingsSection(title: "Sound & Haptics") {
                            ForEach(SoundMode.allCases, id: \.self) { mode in
                                Button {
                                    audioService.soundMode = mode
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: audioService.soundMode == mode ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 18))
                                            .foregroundColor(audioService.soundMode == mode ? AppTheme.Colors.mintGreen : AppTheme.Colors.textSecondary)
                                            .frame(width: 24)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(mode.label)
                                                .font(.system(size: 15))
                                                .foregroundColor(.white)

                                            Text(mode.description)
                                                .font(.system(size: 12))
                                                .foregroundColor(AppTheme.Colors.textSecondary)
                                        }

                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                            }

                            if audioService.soundMode != .alwaysOff {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Volume: \(Int(audioService.volume * 100))%")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.Colors.textSecondary)

                                    HStack {
                                        Image(systemName: "speaker.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.Colors.textSecondary)

                                        Slider(value: $audioService.volume, in: 0...1, step: 0.1)
                                            .tint(AppTheme.Colors.mintGreen)

                                        Image(systemName: "speaker.wave.3.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.Colors.textSecondary)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)

                                Button {
                                    audioService.play(.correct)
                                } label: {
                                    HStack {
                                        Image(systemName: "play.circle")
                                            .foregroundColor(AppTheme.Colors.mintGreen)
                                        Text("Test Sound")
                                            .foregroundColor(AppTheme.Colors.mintGreen)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                }
                            }

                            SettingsToggleRow(
                                icon: "iphone.radiowaves.left.and.right",
                                title: "Haptic Feedback",
                                subtitle: nil,
                                isOn: $hapticService.isEnabled
                            )

                            if hapticService.isEnabled {
                                Button {
                                    hapticService.trigger(.success)
                                } label: {
                                    HStack {
                                        Image(systemName: "hand.tap")
                                            .foregroundColor(AppTheme.Colors.mintGreen)
                                        Text("Test Haptic")
                                            .foregroundColor(AppTheme.Colors.mintGreen)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                }
                            }
                        }

                        // Data & Storage
                        settingsSection(title: "Data & Storage") {
                            NavigationLink {
                                OfflineDataView()
                            } label: {
                                SettingsRowContent(icon: "internaldrive", title: "Offline Data", subtitle: "Manage downloaded strategy data and storage preferences.", showChevron: true)
                            }
                        }

                        // Help & Tours
                        settingsSection(title: "Help & Tours") {
                            NavigationLink {
                                TourSettingsView()
                            } label: {
                                SettingsRowContent(icon: "questionmark.circle", title: "Product Tours", subtitle: "Replay guided tours to learn app features.", showChevron: true)
                            }
                        }

                        // Reset
                        Button {
                            resetToDefaults()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .foregroundColor(AppTheme.Colors.danger)
                                Text("Reset to Defaults")
                                    .foregroundColor(AppTheme.Colors.danger)
                            }
                        }
                        .padding(.top, 8)

                        // About
                        settingsSection(title: "About") {
                            HStack {
                                Text("Version")
                                    .foregroundColor(.white)
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("VP Academy")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Master optimal video poker strategy through practice and learning.")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }

                        #if DEBUG
                        // Developer Tools
                        settingsSection(title: "Developer") {
                            Button {
                                RatingPromptService.shared.forceShow()
                            } label: {
                                SettingsRowContent(
                                    icon: "star.bubble",
                                    title: "Preview Rating Prompt",
                                    subtitle: "Bypasses time gate — debug only",
                                    showChevron: false
                                )
                            }

                        }
                        .padding(.top, 8)
                        #endif

                        // Sign Out Button
                        Button {
                            Task {
                                await authViewModel.signOut()
                            }
                        } label: {
                            Text("Sign Out")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(AppTheme.Colors.danger)
                                .cornerRadius(28)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .frame(maxWidth: maxContentWidth)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Settings")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Continue", role: .destructive) {
                showDeleteFinalConfirmation = true
            }
        } message: {
            Text("This will permanently delete your account, hand history, mastery scores, and all associated data. This action cannot be undone.")
        }
        .alert("Are you sure?", isPresented: $showDeleteFinalConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete My Account", role: .destructive) {
                authenticateAndDelete()
            }
        } message: {
            Text("This is your last chance. Your account and all data will be permanently deleted.")
        }
        .alert("Authentication Required", isPresented: $showAuthenticationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authenticationErrorMessage)
        }
        #if DEBUG
        .sheet(isPresented: $showEVBenchmark) {
            UltimateXEVBenchmarkView()
        }
        #endif
    }

    // MARK: - Biometric Authentication for Account Deletion

    private func authenticateAndDelete() {
        let context = LAContext()
        var error: NSError?

        // Check if biometric/passcode authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Confirm account deletion"
            ) { success, authError in
                DispatchQueue.main.async {
                    if success {
                        Task {
                            await authViewModel.deleteAccount()
                        }
                    } else {
                        if let error = authError as? LAError, error.code == .userCancel {
                            // User cancelled - do nothing
                        } else {
                            authenticationErrorMessage = "Authentication failed. Please try again to delete your account."
                            showAuthenticationError = true
                        }
                    }
                }
            }
        } else {
            // Device doesn't support authentication - show error
            authenticationErrorMessage = "Device authentication is not available. Please set up Face ID, Touch ID, or a passcode in Settings."
            showAuthenticationError = true
        }
    }

    // MARK: - User Profile Card

    private var userEmail: String {
        authViewModel.currentUser?.email ?? "User"
    }

    private var userInitial: String {
        String(userEmail.prefix(1).uppercased())
    }

    private var userProfileCard: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(AppTheme.Colors.mintGreen)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(userInitial)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.darkGreen)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(userEmail)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.cardBackground)
        )
    }

    // MARK: - Settings Section

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.Colors.cardBackground)
            )
        }
    }

    private func resetToDefaults() {
        audioService.soundMode = .alwaysOn
        audioService.volume = 0.7
        hapticService.isEnabled = true
    }
}

// MARK: - Settings Row Components

struct SettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var showChevron: Bool = false

    var body: some View {
        Button { } label: {
            SettingsRowContent(icon: icon, title: title, subtitle: subtitle, showChevron: showChevron)
        }
    }
}

struct SettingsRowContent: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var showChevron: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.white)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }

            Spacer()

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.white)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppTheme.Colors.mintGreen)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        SettingsView(authViewModel: AuthViewModel())
    }
}
