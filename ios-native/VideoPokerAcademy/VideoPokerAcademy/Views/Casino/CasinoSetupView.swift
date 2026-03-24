import SwiftUI

struct PaytableNavTarget: Identifiable, Hashable {
    let id: String
}

struct CasinoSetupView: View {

    // MARK: - State

    @State private var selectedPaytableId: String
    @State private var navigationTarget: PaytableNavTarget? = nil

    // MARK: - Init

    init(initialPaytableId: String = PayTable.lastSelectedId) {
        _selectedPaytableId = State(initialValue: initialPaytableId)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("Voice Mode")
                    .font(.largeTitle)
                    .bold()

                Text("BETA")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }

            // Beta disclaimer
            Text("Voice Mode is under active development. Recognition accuracy may vary — always verify the strategy before playing.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(8)

            Text("Select the game you're playing:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Popular games section
            VStack(alignment: .leading, spacing: 8) {
                Text("Popular Games")
                    .font(.caption)
                    .foregroundColor(.secondary)

                FlowLayout(spacing: 8) {
                    ForEach(PayTable.popularPaytables, id: \.id) { game in
                        GameChip(
                            title: game.name,
                            isSelected: selectedPaytableId == game.id
                        ) {
                            selectedPaytableId = game.id
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            GameSelectorView(selectedPaytableId: $selectedPaytableId)

            Button("Start Voice Mode") {
                navigationTarget = PaytableNavTarget(id: selectedPaytableId)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .navigationTitle("Voice Mode")
        .navigationDestination(item: $navigationTarget) { target in
            CasinoModeView(paytableId: target.id)
        }
    }
}
