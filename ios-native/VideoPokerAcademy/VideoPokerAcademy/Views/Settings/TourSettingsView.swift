import SwiftUI

/// Settings view for managing product tours
struct TourSettingsView: View {
    @StateObject private var tourManager = TourManager.shared
    @State private var showResetAllAlert = false

    private let accentColor = Color(hex: "667eea")

    var body: some View {
        List {
            // Tours list
            Section {
                ForEach(TourId.allCases, id: \.self) { tourId in
                    tourRow(for: tourId)
                }
            } header: {
                Text("Available Tours")
            } footer: {
                Text("Tap \"Replay\" to see a tour again the next time you visit that screen.")
            }

            // Reset all section
            Section {
                Button {
                    showResetAllAlert = true
                } label: {
                    Label("Reset All Tours", systemImage: "arrow.counterclockwise")
                        .foregroundColor(accentColor)
                }
            } footer: {
                Text("This will reset all tours so they show again when you visit each screen.")
            }
        }
        .navigationTitle("Product Tours")
        .alert("Reset All Tours?", isPresented: $showResetAllAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset All") {
                tourManager.resetAllTours()
            }
        } message: {
            Text("All tours will be shown again when you visit their respective screens.")
        }
    }

    @ViewBuilder
    private func tourRow(for tourId: TourId) -> some View {
        let isCompleted = tourManager.hasCompletedTour(tourId)
        let stepCount = TourContent.steps(for: tourId).count

        HStack {
            // Icon
            Image(systemName: tourId.iconName)
                .font(.title3)
                .foregroundColor(isCompleted ? .secondary : accentColor)
                .frame(width: 32)

            // Tour info
            VStack(alignment: .leading, spacing: 2) {
                Text(tourId.displayName)
                    .font(.body)

                Text("\(stepCount) steps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status / Action
            if isCompleted {
                Button("Replay") {
                    tourManager.resetTour(tourId)
                }
                .font(.subheadline)
                .foregroundColor(accentColor)
            } else {
                Text("Not seen")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        TourSettingsView()
    }
}
