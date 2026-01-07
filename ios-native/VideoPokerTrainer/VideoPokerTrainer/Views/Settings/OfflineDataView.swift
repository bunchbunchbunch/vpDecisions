import SwiftUI

/// View model data for a paytable in the list
struct PaytableListItem: Identifiable {
    let id: String
    let name: String
    let isBundled: Bool  // Included with app
    var storageMode: PaytableStorageMode
    var isLoaded: Bool  // Currently in SQLite
}

struct OfflineDataView: View {
    @State private var paytables: [PaytableListItem] = []
    @State private var isLoading = true
    @State private var defaultMode: PaytableStorageMode = PaytablePreferences.shared.defaultStorageMode
    @State private var showDeleteConfirmation = false
    @State private var paytableToDelete: PaytableListItem?
    @State private var totalStorageUsed: Int64 = 0

    var body: some View {
        List {
            // Storage overview section
            Section {
                HStack {
                    Label("Storage Used", systemImage: "internaldrive")
                    Spacer()
                    Text(formatBytes(totalStorageUsed))
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Storage")
            }

            // Default preference section
            Section {
                Picker("Default for New Downloads", selection: $defaultMode) {
                    Text("Ready (Faster)").tag(PaytableStorageMode.ready)
                    Text("Compressed (Saves Space)").tag(PaytableStorageMode.compressed)
                }
                .onChange(of: defaultMode) { _, newValue in
                    PaytablePreferences.shared.defaultStorageMode = newValue
                }
            } header: {
                Text("Preferences")
            } footer: {
                Text("Ready: Strategy stays uncompressed for instant access. Compressed: Clears on app close, re-decompresses each session.")
            }

            // Paytables section
            Section {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    ForEach($paytables) { $paytable in
                        PaytableRow(
                            paytable: $paytable,
                            onToggleMode: { toggleStorageMode(for: paytable) },
                            onDelete: { confirmDelete(paytable) },
                            onDownload: { downloadPaytable(paytable) }
                        )
                    }
                }
            } header: {
                Text("Strategy Data")
            } footer: {
                Text("Toggle between Ready and Compressed modes based on your preference.")
            }
        }
        .navigationTitle("Offline Data")
        .task {
            await loadPaytables()
        }
        .refreshable {
            await loadPaytables()
        }
        .alert("Delete Strategy Data?", isPresented: $showDeleteConfirmation, presenting: paytableToDelete) { paytable in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deletePaytable(paytable)
                }
            }
        } message: { paytable in
            Text("This will remove the uncompressed strategy data for \(paytable.name). It will be re-decompressed when you next play this game.")
        }
    }

    // MARK: - Data Loading

    private func loadPaytables() async {
        isLoading = true

        // Get bundled paytables from StrategyService
        let bundledIds = [
            "jacks-or-better-9-6",
            "double-double-bonus-9-6",
            "triple-double-bonus-9-6",
            "deuces-wild-nsud"
        ]

        // Get what's currently loaded in SQLite
        let loadedPaytables = await LocalStrategyStore.shared.getAvailablePaytables()
        let loadedIds = Set(loadedPaytables.map { $0.paytableId })

        // Get storage size
        totalStorageUsed = await LocalStrategyStore.shared.getDatabaseSize()

        // Build the list
        var items: [PaytableListItem] = []

        for paytable in PayTable.allPayTables {
            let isBundled = bundledIds.contains(paytable.id)
            let isLoaded = loadedIds.contains(paytable.id)
            let currentMode = PaytablePreferences.shared.getStorageMode(for: paytable.id)

            items.append(PaytableListItem(
                id: paytable.id,
                name: paytable.name,
                isBundled: isBundled,
                storageMode: currentMode,
                isLoaded: isLoaded
            ))
        }

        paytables = items
        isLoading = false
    }

    // MARK: - Actions

    private func toggleStorageMode(for paytable: PaytableListItem) {
        let newMode: PaytableStorageMode = paytable.storageMode == .ready ? .compressed : .ready
        PaytablePreferences.shared.setStorageMode(newMode, for: paytable.id)

        // Update local state
        if let index = paytables.firstIndex(where: { $0.id == paytable.id }) {
            paytables[index].storageMode = newMode
        }
    }

    private func confirmDelete(_ paytable: PaytableListItem) {
        paytableToDelete = paytable
        showDeleteConfirmation = true
    }

    private func deletePaytable(_ paytable: PaytableListItem) async {
        await LocalStrategyStore.shared.deletePaytable(paytableId: paytable.id)
        await loadPaytables()  // Refresh the list
    }

    private func downloadPaytable(_ paytable: PaytableListItem) {
        // TODO: Implement download from Supabase
        // For now, show that it's not implemented
        NSLog("Download not yet implemented for: %@", paytable.id)
    }

    // MARK: - Helpers

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Paytable Row

struct PaytableRow: View {
    @Binding var paytable: PaytableListItem
    let onToggleMode: () -> Void
    let onDelete: () -> Void
    let onDownload: () -> Void

    var body: some View {
        HStack {
            Text(paytable.name)
                .font(.body)

            Spacer()

            // Action buttons
            if !paytable.isBundled && !paytable.isLoaded {
                // Download button for non-bundled, not-yet-downloaded paytables
                Button {
                    onDownload()
                } label: {
                    Label("Download", systemImage: "arrow.down.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            } else {
                // Mode toggle for bundled or downloaded paytables
                Menu {
                    Button {
                        if paytable.storageMode != .ready {
                            onToggleMode()
                        }
                    } label: {
                        Label("Ready", systemImage: paytable.storageMode == .ready ? "checkmark" : "")
                    }

                    Button {
                        if paytable.storageMode != .compressed {
                            onToggleMode()
                        }
                    } label: {
                        Label("Compressed", systemImage: paytable.storageMode == .compressed ? "checkmark" : "")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(paytable.storageMode == .ready ? "Ready" : "Compressed")
                            .font(.caption)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(paytable.storageMode == .ready ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .foregroundColor(paytable.storageMode == .ready ? .green : .orange)
                    .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        OfflineDataView()
    }
}
