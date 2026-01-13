import SwiftUI

/// View showing available bundled strategy data
struct OfflineDataView: View {
    @State private var availablePaytables: [String] = []
    @State private var isLoading = true

    var body: some View {
        List {
            Section {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    ForEach(PayTable.allPayTables, id: \.id) { paytable in
                        HStack {
                            Text(paytable.name)
                                .font(.body)

                            Spacer()

                            if availablePaytables.contains(paytable.id) {
                                Label("Available", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Label("Not Available", systemImage: "xmark.circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Text("Strategy Data")
            } footer: {
                Text("Strategy data is bundled with the app for offline access.")
            }
        }
        .navigationTitle("Strategy Data")
        .task {
            await loadAvailablePaytables()
        }
    }

    private func loadAvailablePaytables() async {
        isLoading = true
        availablePaytables = await BinaryStrategyStoreV2.shared.getAvailablePaytables()
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        OfflineDataView()
    }
}
