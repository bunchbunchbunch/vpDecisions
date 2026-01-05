import SwiftUI

/// A small card view for multi-hand grid display using actual card images
struct MiniCardView: View {
    let card: Card?  // nil = show card back
    let isWinning: Bool
    let cardWidth: CGFloat

    private let aspectRatio: CGFloat = 2.5 / 3.5

    var body: some View {
        ZStack {
            if let card = card {
                // Face-up card using actual card image
                Image(card.imageName)
                    .resizable()
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .frame(width: cardWidth)
                    .cornerRadius(4)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            } else {
                // Card back
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .frame(width: cardWidth)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(hex: "0f3460").opacity(0.5), lineWidth: 0.5)
                    )
                    .overlay(
                        // Simple diamond pattern for card back
                        Image(systemName: "diamond.fill")
                            .font(.system(size: cardWidth * 0.35))
                            .foregroundColor(Color(hex: "e94560").opacity(0.3))
                    )
                    .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
            }
        }
    }
}

#Preview {
    HStack(spacing: -8) {
        // Sample hand with overlapping cards
        MiniCardView(card: Card(rank: .ace, suit: .spades), isWinning: true, cardWidth: 40)
        MiniCardView(card: Card(rank: .king, suit: .hearts), isWinning: true, cardWidth: 40)
        MiniCardView(card: Card(rank: .queen, suit: .diamonds), isWinning: false, cardWidth: 40)
        MiniCardView(card: Card(rank: .jack, suit: .clubs), isWinning: false, cardWidth: 40)
        MiniCardView(card: Card(rank: .ten, suit: .spades), isWinning: false, cardWidth: 40)
    }
    .padding()
    .background(Color(hex: "2d5016"))
}

#Preview("Card Backs") {
    HStack(spacing: -8) {
        ForEach(0..<5, id: \.self) { _ in
            MiniCardView(card: nil, isWinning: false, cardWidth: 40)
        }
    }
    .padding()
    .background(Color(hex: "2d5016"))
}
