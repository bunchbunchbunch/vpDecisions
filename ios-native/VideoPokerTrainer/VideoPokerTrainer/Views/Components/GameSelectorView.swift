import SwiftUI

struct GameSelectorView: View {
    @Binding var selectedPaytableId: String
    @State private var selectedTab: SelectorTab = .popular
    @State private var selectedFamily: GameFamily = .jacksOrBetter
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var availablePaytableIds: Set<String> = []
    @State private var isCheckingAvailability = false

    enum SelectorTab: String, CaseIterable {
        case popular = "Popular"
        case allGames = "All Games"
    }

    /// Whether the currently selected game is available (online or has offline data)
    private var isSelectedGameAvailable: Bool {
        networkMonitor.isOnline || availablePaytableIds.contains(selectedPaytableId)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Tab selector (segmented control)
            Picker("", selection: $selectedTab) {
                ForEach(SelectorTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            // Content based on tab
            if selectedTab == .popular {
                popularGamesView
            } else {
                allGamesView
            }

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
            // Sync family when paytable changes (e.g., from Popular tab)
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

    private var popularGamesView: some View {
        Picker("Popular Games", selection: $selectedPaytableId) {
            ForEach(PayTable.popularPaytables) { paytable in
                Text(paytable.name).tag(paytable.id)
            }
        }
        .pickerStyle(.menu)
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private var allGamesView: some View {
        VStack(spacing: 10) {
            // Family picker
            Picker("Game Type", selection: $selectedFamily) {
                ForEach(GameFamily.allCases) { family in
                    Text(family.displayName).tag(family)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)

            // Paytable picker (filtered by family)
            let familyPaytables = PayTable.paytables(for: selectedFamily)
            Picker("Paytable", selection: $selectedPaytableId) {
                ForEach(familyPaytables) { paytable in
                    Text(paytable.variantName).tag(paytable.id)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .onChange(of: selectedFamily) { _, newFamily in
            // Auto-select first paytable when family changes (if current isn't in family)
            let familyPaytables = PayTable.paytables(for: newFamily)
            if !familyPaytables.contains(where: { $0.id == selectedPaytableId }),
               let first = familyPaytables.first {
                selectedPaytableId = first.id
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
