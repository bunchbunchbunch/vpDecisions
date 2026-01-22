import SwiftUI

struct SettingsView: View {
    @StateObject private var audioService = AudioService.shared
    @StateObject private var hapticService = HapticService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.Gradients.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // User Profile Card
                    userProfileCard

                    // Account Settings
                    settingsSection(title: "Account Settings") {
                        SettingsRow(icon: "person", title: "Edit Profile", subtitle: "Update name, bio, and photo", showChevron: true)
                        SettingsRow(icon: "lock", title: "Change Password", subtitle: "Update your password", showChevron: true)
                        SettingsRow(icon: "globe", title: "Language & Region", subtitle: "English (US)", showChevron: true)
                    }

                    // Notifications
                    settingsSection(title: "Notifications") {
                        SettingsToggleRow(
                            icon: "bell",
                            title: "Push Notifications",
                            subtitle: "Receive push notifications",
                            isOn: .constant(true)
                        )
                        SettingsToggleRow(
                            icon: "envelope",
                            title: "Email Notifications",
                            subtitle: "Get updates via email",
                            isOn: .constant(false)
                        )
                    }

                    // Sound & Haptics
                    settingsSection(title: "Sound & Haptics") {
                        SettingsToggleRow(
                            icon: "speaker.wave.2",
                            title: "Sound Effects",
                            subtitle: nil,
                            isOn: $audioService.isEnabled
                        )

                        if audioService.isEnabled {
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

                    // Sign Out Button
                    Button {
                        // Sign out action - handled by parent
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
    }

    // MARK: - User Profile Card

    private var userProfileCard: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(AppTheme.Colors.mintGreen)
                .frame(width: 50, height: 50)
                .overlay(
                    Text("A")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.darkGreen)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("John Bunch")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text("john@email.com")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
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
        audioService.isEnabled = true
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
        SettingsView()
    }
}
