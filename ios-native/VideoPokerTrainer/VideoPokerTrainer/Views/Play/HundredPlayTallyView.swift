import SwiftUI

/// Compact tally view for 100-play mode showing hand type counts and subtotals
struct HundredPlayTallyView: View {
    let tallyResults: [HundredPlayTallyResult]
    let denomination: Double

    // Use two columns when more than 3 results (fits up to 8 in 4 rows)
    private var useTwoColumns: Bool {
        tallyResults.count > 3
    }

    var body: some View {
        if tallyResults.isEmpty {
            // Pre-draw or no wins - empty placeholder (maintains layout)
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                if useTwoColumns {
                    twoColumnLayout
                } else {
                    singleColumnLayout
                }
            }
        }
    }

    private var singleColumnLayout: some View {
        VStack(spacing: 6) {
            ForEach(tallyResults) { result in
                compactTallyRow(result: result)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var twoColumnLayout: some View {
        // Column-first order: top-to-bottom, then left-to-right
        let rowCount = (tallyResults.count + 1) / 2

        return VStack(spacing: 6) {
            ForEach(0..<rowCount, id: \.self) { rowIndex in
                let leftIndex = rowIndex
                let rightIndex = rowIndex + rowCount

                HStack(spacing: 8) {
                    compactTallyRow(result: tallyResults[leftIndex])

                    if rightIndex < tallyResults.count {
                        compactTallyRow(result: tallyResults[rightIndex])
                    } else {
                        Spacer()
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func compactTallyRow(result: HundredPlayTallyResult) -> some View {
        let subtotalDollars = Double(result.subtotal) * denomination
        let badgeColors = winBadgeColors(for: result.handName)

        HStack(spacing: 6) {
            // Hand name badge
            Text(abbreviatedHandName(result.handName))
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: badgeColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .lineLimit(1)

            Spacer(minLength: 2)

            // Count × pay = subtotal (compact)
            Text("\(result.count)×\(result.payPerHand)=\(formatCompactCurrency(subtotalDollars))")
                .font(.caption2)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }

    private func abbreviatedHandName(_ name: String) -> String {
        // Abbreviate longer hand names for compact display
        switch name {
        case "Jacks or Better": return "Jacks+"
        case "Tens or Better": return "Tens+"
        case "Three of a Kind": return "3 of Kind"
        case "Four of a Kind": return "4 of Kind"
        case "Five of a Kind": return "5 of Kind"
        case "Full House": return "Full House"
        case "Straight Flush": return "Str Flush"
        case "Royal Flush": return "Royal"
        case "Natural Royal": return "Nat Royal"
        case "Wild Royal": return "Wild Royal"
        case "Four Deuces": return "4 Deuces"
        case "Four Aces": return "4 Aces"
        case "Four Aces + 2-4": return "4A+2-4"
        case "Four 2-4": return "4 2-4"
        case "Four 2-4 + A-4": return "4 2-4+A"
        case "Four 5-K": return "4 5-K"
        default: return name
        }
    }

    private func winBadgeColors(for handName: String) -> [Color] {
        switch handName {
        case "Jacks or Better", "Tens or Better":
            return [Color(hex: "B388FF"), Color(hex: "9575CD")]
        case "Two Pair":
            return [Color(hex: "81D4FA"), Color(hex: "4FC3F7")]
        case "Three of a Kind":
            return [Color(hex: "FFEE58"), Color(hex: "FDD835")]
        case "Straight":
            return [Color(hex: "F06292"), Color(hex: "EC407A")]
        case "Flush":
            return [Color(hex: "66BB6A"), Color(hex: "43A047")]
        case "Full House":
            return [Color(hex: "5C6BC0"), Color(hex: "3F51B5")]
        case _ where handName.contains("Four"):
            return [Color(hex: "F8BBD9"), Color(hex: "F48FB1")]
        case "Straight Flush":
            return [Color(hex: "7E57C2"), Color(hex: "5E35B1")]
        case "Royal Flush", "Natural Royal", "Wild Royal":
            return [Color(hex: "EF5350"), Color(hex: "E53935")]
        case "Five of a Kind":
            return [Color(hex: "FFB74D"), Color(hex: "FF9800")]
        case "Four Deuces":
            return [Color(hex: "4DD0E1"), Color(hex: "00BCD4")]
        default:
            return [Color(hex: "FFD700"), Color(hex: "FFA500")]
        }
    }

    private func formatCompactCurrency(_ amount: Double) -> String {
        if amount >= 1000 {
            return String(format: "$%.0fk", amount / 1000)
        } else if amount == floor(amount) {
            return String(format: "$%.0f", amount)
        } else {
            return String(format: "$%.2f", amount)
        }
    }
}

#Preview("Few Results - Single Column") {
    HundredPlayTallyView(
        tallyResults: [
            HundredPlayTallyResult(handName: "Full House", payPerHand: 45, count: 2, subtotal: 90),
            HundredPlayTallyResult(handName: "Three of a Kind", payPerHand: 15, count: 8, subtotal: 120),
        ],
        denomination: 1.0
    )
    .frame(height: 150)
    .padding()
}

#Preview("Many Results - Two Columns") {
    HundredPlayTallyView(
        tallyResults: [
            HundredPlayTallyResult(handName: "Four Aces + 2-4", payPerHand: 2000, count: 1, subtotal: 2000),
            HundredPlayTallyResult(handName: "Four Aces", payPerHand: 800, count: 1, subtotal: 800),
            HundredPlayTallyResult(handName: "Full House", payPerHand: 45, count: 3, subtotal: 135),
            HundredPlayTallyResult(handName: "Flush", payPerHand: 30, count: 5, subtotal: 150),
            HundredPlayTallyResult(handName: "Three of a Kind", payPerHand: 15, count: 12, subtotal: 180),
            HundredPlayTallyResult(handName: "Two Pair", payPerHand: 10, count: 18, subtotal: 180),
            HundredPlayTallyResult(handName: "Jacks or Better", payPerHand: 5, count: 25, subtotal: 125)
        ],
        denomination: 1.0
    )
    .frame(height: 150)
    .padding()
}

#Preview("No Wins") {
    HundredPlayTallyView(
        tallyResults: [],
        denomination: 1.0
    )
    .frame(height: 150)
    .padding()
}
