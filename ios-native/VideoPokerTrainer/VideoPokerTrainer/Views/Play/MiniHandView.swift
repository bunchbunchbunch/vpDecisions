import SwiftUI

/// A row of 5 overlapping mini cards with optional win overlay
struct MiniHandView: View {
    let lineNumber: Int
    let cards: [CardData]?  // nil = show card backs
    let handName: String?
    let payout: Int
    let winningIndices: [Int]
    let showAsCardBacks: Bool
    let denomination: Double
    let cardWidth: CGFloat
    var showAsWild: Bool = false

    // Overlap as percentage of card width (negative spacing)
    private var cardOverlap: CGFloat {
        -cardWidth * 0.25
    }

    var isWinner: Bool {
        payout > 0 && !showAsCardBacks
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Cards row
            HStack(spacing: cardOverlap) {
                ForEach(0..<5, id: \.self) { index in
                    if showAsCardBacks {
                        MiniCardView(card: nil, isWinning: false, cardWidth: cardWidth)
                    } else if let cards = cards, index < cards.count {
                        MiniCardView(
                            card: cards[index].toCard(),
                            isWinning: winningIndices.contains(index),
                            cardWidth: cardWidth,
                            showAsWild: showAsWild
                        )
                    } else {
                        MiniCardView(card: nil, isWinning: false, cardWidth: cardWidth)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: "2d5016").opacity(0.8))
            )
            .overlay(
                // Win overlay bar at bottom
                Group {
                    if isWinner {
                        winOverlay
                    }
                }
            )
        }
    }

    private var winOverlay: some View {
        VStack {
            Spacer()
            HStack(spacing: 4) {
                if let handName = handName {
                    Text(shortHandName(handName))
                        .font(.system(size: max(8, cardWidth * 0.22), weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                Text(formatPayout(payout))
                    .font(.system(size: max(9, cardWidth * 0.25), weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: winBadgeColors(for: handName),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .padding(.bottom, -8)
    }

    private func winBadgeColors(for handName: String?) -> [Color] {
        guard let handName = handName else {
            return [Color(hex: "FFD700"), Color(hex: "FFA500")]
        }
        switch handName {
        case "Jacks or Better", "Tens or Better":
            // Light Purple
            return [Color(hex: "B388FF"), Color(hex: "9575CD")]
        case "Two Pair":
            // Light Blue
            return [Color(hex: "81D4FA"), Color(hex: "4FC3F7")]
        case "Three of a Kind":
            // Yellow
            return [Color(hex: "FFEE58"), Color(hex: "FDD835")]
        case "Straight":
            // Dark Pink
            return [Color(hex: "F06292"), Color(hex: "EC407A")]
        case "Flush":
            // Green
            return [Color(hex: "66BB6A"), Color(hex: "43A047")]
        case "Full House":
            // Dark Blue
            return [Color(hex: "5C6BC0"), Color(hex: "3F51B5")]
        case _ where handName.contains("Four"):
            // Light Pink (Four of a Kind and variants)
            return [Color(hex: "F8BBD9"), Color(hex: "F48FB1")]
        case "Straight Flush":
            // Dark Purple
            return [Color(hex: "7E57C2"), Color(hex: "5E35B1")]
        case "Royal Flush", "Natural Royal", "Wild Royal":
            // Red
            return [Color(hex: "EF5350"), Color(hex: "E53935")]
        default:
            // Default gold
            return [Color(hex: "FFD700"), Color(hex: "FFA500")]
        }
    }

    private func shortHandName(_ name: String) -> String {
        // Abbreviate hand names for space
        switch name {
        case "Royal Flush": return "RF"
        case "Straight Flush": return "SF"
        case "Four of a Kind": return "4K"
        case "Full House": return "FH"
        case "Flush": return "FL"
        case "Straight": return "ST"
        case "Three of a Kind": return "3K"
        case "Two Pair": return "2P"
        case "Jacks or Better": return "JB"
        case "Tens or Better": return "TB"
        default:
            if name.hasPrefix("Four") { return "4K" }
            return String(name.prefix(2)).uppercased()
        }
    }

    private func formatPayout(_ credits: Int) -> String {
        let dollars = Double(credits) * denomination
        // Show cents only if the amount is not a whole dollar
        if dollars.truncatingRemainder(dividingBy: 1) == 0 {
            return "+$\(Int(dollars))"
        } else {
            return String(format: "+$%.2f", dollars)
        }
    }
}

#Preview("Winner") {
    MiniHandView(
        lineNumber: 1,
        cards: [
            CardData(rank: .ace, suit: .spades),
            CardData(rank: .ace, suit: .hearts),
            CardData(rank: .king, suit: .diamonds),
            CardData(rank: .queen, suit: .clubs),
            CardData(rank: .jack, suit: .spades)
        ],
        handName: "Jacks or Better",
        payout: 5,
        winningIndices: [0, 1],
        showAsCardBacks: false,
        denomination: 1.0,
        cardWidth: 40
    )
    .padding()
    .background(Color.gray.opacity(0.3))
}

#Preview("Card Backs") {
    MiniHandView(
        lineNumber: 1,
        cards: nil,
        handName: nil,
        payout: 0,
        winningIndices: [],
        showAsCardBacks: true,
        denomination: 1.0,
        cardWidth: 40
    )
    .padding()
    .background(Color.gray.opacity(0.3))
}

#Preview("No Win") {
    MiniHandView(
        lineNumber: 2,
        cards: [
            CardData(rank: .two, suit: .spades),
            CardData(rank: .five, suit: .hearts),
            CardData(rank: .seven, suit: .diamonds),
            CardData(rank: .nine, suit: .clubs),
            CardData(rank: .jack, suit: .spades)
        ],
        handName: nil,
        payout: 0,
        winningIndices: [],
        showAsCardBacks: false,
        denomination: 1.0,
        cardWidth: 40
    )
    .padding()
    .background(Color.gray.opacity(0.3))
}
