import SwiftUI

struct GameSelectorView: View {
    @Binding var selectedPaytableId: String
    @State private var selectedFamily: GameFamily = .jacksOrBetter
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var availablePaytableIds: Set<String> = []
    @State private var isCheckingAvailability = false

    /// Whether the currently selected game is available (online or has offline data)
    private var isSelectedGameAvailable: Bool {
        networkMonitor.isOnline || availablePaytableIds.contains(selectedPaytableId)
    }

    /// Count of downloaded games for a given family
    private func downloadedCount(for family: GameFamily) -> Int {
        let familyPaytables = PayTable.paytables(for: family)
        return familyPaytables.filter { availablePaytableIds.contains($0.id) }.count
    }

    /// Total games for a given family
    private func totalCount(for family: GameFamily) -> Int {
        PayTable.paytables(for: family).count
    }

    /// Display name with download count
    private func familyDisplayName(for family: GameFamily) -> String {
        let downloaded = downloadedCount(for: family)
        let total = totalCount(for: family)
        return "\(family.displayName) (\(downloaded)/\(total))"
    }

    var body: some View {
        VStack(spacing: 12) {
            // Family picker dropdown with download counts
            familyPickerSection

            // Paytable picker showing downloaded and available games
            paytablePickerSection

            // Offline warning for unavailable game
            if !networkMonitor.isOnline && !isSelectedGameAvailable {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("This game requires download. Choose a different game or go online.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(10)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .onAppear {
            initializeSelectedFamily()
        }
        .task {
            await loadAvailablePaytables()
        }
        .onChange(of: selectedPaytableId) { _, newId in
            // Sync family when paytable changes
            if let paytable = PayTable.allPayTables.first(where: { $0.id == newId }) {
                selectedFamily = paytable.family
            }
        }
        .onChange(of: networkMonitor.isOnline) { _, _ in
            // Refresh availability when network status changes
            Task {
                await loadAvailablePaytables()
            }
        }
    }

    private func loadAvailablePaytables() async {
        isCheckingAvailability = true
        var available: Set<String> = []

        // Check each paytable for offline availability
        for paytable in PayTable.allPayTables {
            if await StrategyService.shared.hasOfflineData(paytableId: paytable.id) {
                available.insert(paytable.id)
            }
        }

        availablePaytableIds = available
        isCheckingAvailability = false
    }

    private func initializeSelectedFamily() {
        // Initialize selectedFamily based on current selection
        if let paytable = PayTable.allPayTables.first(where: { $0.id == selectedPaytableId }) {
            selectedFamily = paytable.family
        }
    }

    // MARK: - Family Picker

    private var familyPickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Game Family")
                .font(.caption)
                .foregroundColor(.secondary)

            Menu {
                ForEach(GameFamily.allCases) { family in
                    Button {
                        selectedFamily = family
                        // Auto-select first available paytable, or first if none available
                        let familyPaytables = PayTable.paytables(for: family)
                        if let firstAvailable = familyPaytables.first(where: { availablePaytableIds.contains($0.id) }) {
                            selectedPaytableId = firstAvailable.id
                        } else if let first = familyPaytables.first {
                            selectedPaytableId = first.id
                        }
                    } label: {
                        HStack {
                            Text(family.displayName)
                            Spacer()
                            let downloaded = downloadedCount(for: family)
                            let total = totalCount(for: family)
                            Text("\(downloaded)/\(total)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } label: {
                HStack {
                    Text(familyDisplayName(for: selectedFamily))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }

    // MARK: - Paytable Picker

    private var paytablePickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pay Table")
                .font(.caption)
                .foregroundColor(.secondary)

            let familyPaytables = PayTable.paytables(for: selectedFamily)

            Menu {
                // Downloaded games first
                let downloadedPaytables = familyPaytables.filter { availablePaytableIds.contains($0.id) }
                let notDownloadedPaytables = familyPaytables.filter { !availablePaytableIds.contains($0.id) }

                if !downloadedPaytables.isEmpty {
                    Section("Downloaded") {
                        ForEach(downloadedPaytables) { paytable in
                            Button {
                                selectedPaytableId = paytable.id
                            } label: {
                                HStack {
                                    Text(paytable.variantName)
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }

                if !notDownloadedPaytables.isEmpty {
                    Section("Not Downloaded") {
                        ForEach(notDownloadedPaytables) { paytable in
                            Button {
                                selectedPaytableId = paytable.id
                            } label: {
                                HStack {
                                    Text(paytable.variantName)
                                    Spacer()
                                    Image(systemName: "arrow.down.circle")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    if let selectedPaytable = PayTable.allPayTables.first(where: { $0.id == selectedPaytableId }) {
                        Text(selectedPaytable.variantName)
                            .foregroundColor(.primary)

                        if availablePaytableIds.contains(selectedPaytableId) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                        }
                    } else {
                        Text("Select a pay table")
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
        .onChange(of: selectedFamily) { _, newFamily in
            // Auto-select first paytable when family changes (if current isn't in family)
            let familyPaytables = PayTable.paytables(for: newFamily)
            if !familyPaytables.contains(where: { $0.id == selectedPaytableId }) {
                // Prefer downloaded paytable
                if let firstAvailable = familyPaytables.first(where: { availablePaytableIds.contains($0.id) }) {
                    selectedPaytableId = firstAvailable.id
                } else if let first = familyPaytables.first {
                    selectedPaytableId = first.id
                }
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedId = "jacks-or-better-9-6"

        var body: some View {
            VStack {
                GameSelectorView(selectedPaytableId: $selectedId)
                    .padding()

                Text("Selected: \(selectedId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    return PreviewWrapper()
}
