import SwiftUI

struct CardView: View {
    let card: Card
    var isSelected: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Card image
                Image(card.imageName)
                    .resizable()
                    .aspectRatio(2.5/3.5, contentMode: .fit)
                    .cornerRadius(8)
                    .shadow(color: isSelected ? Color.yellow.opacity(0.8) : Color.black.opacity(0.2),
                            radius: isSelected ? 8 : 4,
                            x: 0,
                            y: isSelected ? -4 : 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 3)
                    )
            }
            .offset(y: isSelected ? -10 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)

            // HELD label (always reserve space, but only show when selected)
            Text("HELD")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.yellow)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.black.opacity(isSelected ? 0.7 : 0))
                .cornerRadius(4)
                .opacity(isSelected ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

// Card text display (for results, etc.)
struct CardText: View {
    let card: Card

    var body: some View {
        Text(card.displayText)
            .font(.system(.body, design: .monospaced))
            .fontWeight(.bold)
            .foregroundColor(card.suit.color)
    }
}

// Display a row of cards as text
struct CardListText: View {
    let cards: [Card]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(cards.enumerated()), id: \.offset) { _, card in
                CardText(card: card)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Single card
        CardView(card: Card(rank: .ace, suit: .spades), isSelected: false)
            .frame(width: 80)

        // Selected card
        CardView(card: Card(rank: .king, suit: .hearts), isSelected: true)
            .frame(width: 80)

        // Card text
        CardText(card: Card(rank: .queen, suit: .diamonds))

        // Card list
        CardListText(cards: [
            Card(rank: .ace, suit: .spades),
            Card(rank: .king, suit: .hearts),
            Card(rank: .queen, suit: .diamonds),
            Card(rank: .jack, suit: .clubs),
            Card(rank: .ten, suit: .spades)
        ])
    }
    .padding()
}
