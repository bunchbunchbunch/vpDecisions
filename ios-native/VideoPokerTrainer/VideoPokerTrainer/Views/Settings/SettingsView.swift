import SwiftUI

struct SettingsView: View {
    @StateObject private var audioService = AudioService.shared
    @StateObject private var hapticService = HapticService.shared

    var body: some View {
        List {
            // Sound & Haptics Section
            Section {
                // Sound toggle
                Toggle(isOn: $audioService.isEnabled) {
                    Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                }

                // Volume slider
                if audioService.isEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Volume: \(Int(audioService.volume * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: "speaker.fill")
                                .foregroundColor(.secondary)

                            Slider(value: $audioService.volume, in: 0...1, step: 0.1)

                            Image(systemName: "speaker.wave.3.fill")
                                .foregroundColor(.secondary)
                        }
                    }

                    // Test sound button
                    Button {
                        audioService.play(.correct)
                    } label: {
                        Label("Test Sound", systemImage: "play.circle")
                    }
                }

                // Haptic toggle
                Toggle(isOn: $hapticService.isEnabled) {
                    Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
                }

                if hapticService.isEnabled {
                    Button {
                        hapticService.trigger(.success)
                    } label: {
                        Label("Test Haptic", systemImage: "hand.tap")
                    }
                }
            } header: {
                Text("Sound & Haptics")
            }

            // Data & Storage Section
            Section {
                NavigationLink {
                    OfflineDataView()
                } label: {
                    Label("Offline Data", systemImage: "internaldrive")
                }
            } header: {
                Text("Data & Storage")
            } footer: {
                Text("Manage downloaded strategy data and storage preferences.")
            }

            // Help & Tours Section
            Section {
                NavigationLink {
                    TourSettingsView()
                } label: {
                    Label("Product Tours", systemImage: "questionmark.circle")
                }
            } header: {
                Text("Help & Tours")
            } footer: {
                Text("Replay guided tours to learn app features.")
            }

            // Reset Section
            Section {
                Button(role: .destructive) {
                    resetToDefaults()
                } label: {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                }
            }

            // About Section
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("VP Trainer")
                        .font(.headline)
                    Text("Master optimal video poker strategy through practice and spaced repetition.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Settings")
    }

    private func resetToDefaults() {
        audioService.isEnabled = true
        audioService.volume = 0.7
        hapticService.isEnabled = true
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
