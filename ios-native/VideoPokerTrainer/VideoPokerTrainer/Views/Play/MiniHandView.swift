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
                            cardWidth: cardWidth
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
                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .padding(.bottom, -8)
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
        if dollars >= 1 {
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
