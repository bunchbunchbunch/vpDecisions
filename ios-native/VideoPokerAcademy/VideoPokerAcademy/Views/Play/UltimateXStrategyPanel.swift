import SwiftUI

struct UltimateXStrategyPanel: View {
    let topHolds: [UltimateXHoldOption]
    let selectedIndices: Set<Int>
    let dealtCards: [Card]
    let isComputing: Bool
    let userHold: UltimateXHoldOption?
    let isComputingUserHold: Bool
    let avgMultiplier: Double
    var isLandscape: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            strategySection
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Strategy Section

    @ViewBuilder
    private var strategySection: some View {
        if isComputing {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white.opacity(0.6))
                Text("Computing optimal holds\u{2026}")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
        } else if !topHolds.isEmpty {
            holdsList
        }
    }

    private var holdsList: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Top Holds")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))

            if !isLandscape {
                // Column headers (portrait only)
                HStack(spacing: 4) {
                    Text("") // rank placeholder
                        .frame(width: 24)
                    Text("Cards Kept")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.3))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Base")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.3))
                        .frame(width: 44, alignment: .trailing)
                    Text("×Mult")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.3))
                        .frame(width: 38, alignment: .trailing)
                    Text("Score")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.3))
                        .frame(width: 44, alignment: .trailing)
                    Text("") // checkmark placeholder
                        .frame(width: 15)
                }
                .padding(.horizontal, 6)
            }

            ForEach(Array(topHolds.enumerated()), id: \.element.id) { rank, hold in
                HoldRow(
                    rank: rank + 1,
                    hold: hold,
                    dealtCards: dealtCards,
                    isSelected: Set(hold.holdIndices) == selectedIndices,
                    label: nil,
                    avgMultiplier: avgMultiplier,
                    isLandscape: isLandscape
                )
            }

            if isComputingUserHold {
                HStack {
                    ProgressView().scaleEffect(0.7)
                    Text("Computing your hold\u{2026}")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.vertical, 4)
            } else if let userHold {
                Divider().background(Color.white.opacity(0.15))
                HoldRow(
                    rank: nil,
                    hold: userHold,
                    dealtCards: dealtCards,
                    isSelected: true,
                    label: "Your Hold",
                    avgMultiplier: avgMultiplier,
                    isLandscape: isLandscape
                )
            }
        }
    }
}

// MARK: - HoldRow

private struct HoldRow: View {
    let rank: Int?
    let hold: UltimateXHoldOption
    let dealtCards: [Card]
    let isSelected: Bool
    let label: String?
    let avgMultiplier: Double
    var isLandscape: Bool = false

    private var rankLabel: String {
        if let label { return label }
        if let rank { return "#\(rank)" }
        return "#0"
    }

    private var cardLabel: String {
        guard !hold.holdIndices.isEmpty else { return "Draw All" }
        return hold.holdIndices.compactMap { i -> String? in
            guard i < dealtCards.count else { return nil }
            let c = dealtCards[i]
            return "\(c.rank.display)\(c.suit.symbol)"
        }.joined(separator: " ")
    }

    var body: some View {
        if isLandscape {
            landscapeBody
        } else {
            portraitBody
        }
    }

    // Original table-row layout (portrait)
    private var portraitBody: some View {
        HStack(spacing: 4) {
            Text(rankLabel)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(label != nil ? Color(hex: "00FF9F").opacity(0.7) : .white.opacity(0.4))
                .frame(width: label != nil ? nil : 24, alignment: .leading)

            Text(cardLabel)
                .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? Color(hex: "00FF9F") : .white)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(String(format: "%.3f", hold.baseEV))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 44, alignment: .trailing)

            Text(String(format: "%.2f×", avgMultiplier))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(avgMultiplier > 1.005 ? Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8) : .white.opacity(0.5))
                .frame(width: 38, alignment: .trailing)

            Text(String(format: "%.3f", hold.adjustedEV))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor((rank == 1 && label == nil) ? Color(hex: "FFD700") : .white.opacity(0.6))
                .frame(width: 44, alignment: .trailing)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "00FF9F"))
                    .frame(width: 15)
            } else {
                Spacer().frame(width: 15)
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isSelected ? Color(hex: "00FF9F").opacity(0.08) : Color.clear)
        )
    }

    // 2-line layout (landscape)
    private var landscapeBody: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Line 1: rank/label + cards + checkmark
            HStack(spacing: 6) {
                Text(rankLabel)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(label != nil ? Color(hex: "00FF9F").opacity(0.7) : .white.opacity(0.4))
                    .frame(minWidth: 24, alignment: .leading)
                Text(cardLabel)
                    .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? Color(hex: "00FF9F") : .white)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "00FF9F"))
                }
            }
            // Line 2: stats
            HStack(spacing: 8) {
                Text(String(format: "%.3f", hold.baseEV))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                Text("·")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.2))
                Text(String(format: "×%.2f", avgMultiplier))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(avgMultiplier > 1.005 ? Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8) : .white.opacity(0.4))
                Text("·")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.2))
                Text(String(format: "%.3f", hold.adjustedEV))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor((rank == 1 && label == nil) ? Color(hex: "FFD700") : .white.opacity(0.5))
            }
            .padding(.leading, 4)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isSelected ? Color(hex: "00FF9F").opacity(0.08) : Color.clear)
        )
    }
}
