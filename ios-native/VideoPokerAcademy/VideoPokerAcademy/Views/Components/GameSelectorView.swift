import SwiftUI

struct GameSelectorView: View {
    @Binding var selectedPaytableId: String
    @State private var selectedFamily: GameFamily = .jacksOrBetter

    var body: some View {
        VStack(spacing: 12) {
            familyPickerSection
            paytablePickerSection
        }
        .onAppear {
            initializeSelectedFamily()
        }
        .onChange(of: selectedPaytableId) { _, newId in
            if let paytable = PayTable.allPayTables.first(where: { $0.id == newId }) {
                selectedFamily = paytable.family
            }
            PayTable.lastSelectedId = newId
        }
    }

    private func initializeSelectedFamily() {
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
                ForEach(GameFamilyCategory.displayOrder) { category in
                    Section(category.displayName) {
                        ForEach(GameFamily.families(for: category)) { family in
                            Button {
                                selectedFamily = family
                                let familyPaytables = sortedPaytables(for: family)
                                if !familyPaytables.contains(where: { $0.id == selectedPaytableId }),
                                   let first = familyPaytables.first {
                                    selectedPaytableId = first.id
                                }
                            } label: {
                                HStack {
                                    Text(family.displayName)
                                    if selectedFamily == family {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedFamily.displayName)
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

            let variants = sortedPaytables(for: selectedFamily)

            Menu {
                ForEach(variants) { paytable in
                    Button {
                        selectedPaytableId = paytable.id
                    } label: {
                        HStack {
                            Text(paytable.variantDisplayName)
                            if selectedPaytableId == paytable.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    if let selectedPaytable = PayTable.allPayTables.first(where: { $0.id == selectedPaytableId }) {
                        Text(selectedPaytable.variantDisplayName)
                            .foregroundColor(.primary)
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
    }

    // MARK: - Helpers

    /// Returns paytables for a family sorted by return percentage descending.
    /// Paytables with unknown return percentage are sorted to the end.
    private func sortedPaytables(for family: GameFamily) -> [PayTable] {
        PayTable.paytables(for: family).sorted { a, b in
            let aReturn = a.returnPercentage ?? -1
            let bReturn = b.returnPercentage ?? -1
            return aReturn > bReturn
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
