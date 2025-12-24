import Foundation

struct Hand: Identifiable {
    let id = UUID()
    var cards: [Card]

    init(cards: [Card]) {
        precondition(cards.count == 5, "A hand must have exactly 5 cards")
        self.cards = cards
    }

    /// Generate canonical key for database lookup
    /// Matches the React Native implementation exactly
    var canonicalKey: String {
        // Sort by rank value
        let sorted = cards.sorted { $0.rank.rawValue < $1.rank.rawValue }

        // Map suits to canonical letters (a, b, c, d) in order of appearance
        var suitMap: [Suit: String] = [:]
        let suitLetters = ["a", "b", "c", "d"]
        var nextSuitIndex = 0

        for card in sorted {
            if suitMap[card.suit] == nil {
                suitMap[card.suit] = suitLetters[nextSuitIndex]
                nextSuitIndex += 1
            }
        }

        // Build canonical key
        return sorted.map { card in
            "\(card.rank.display)\(suitMap[card.suit]!)"
        }.joined()
    }

    /// Deal a random 5-card hand
    static func deal() -> Hand {
        let shuffled = Card.shuffledDeck()
        return Hand(cards: Array(shuffled.prefix(5)))
    }

    /// Parse hold indices from bitmask (0-31)
    static func holdIndicesFromBitmask(_ bitmask: Int) -> [Int] {
        var indices: [Int] = []
        for i in 0..<5 {
            if (bitmask & (1 << i)) != 0 {
                indices.append(i)
            }
        }
        return indices
    }

    /// Convert hold indices to bitmask
    static func bitmaskFromHoldIndices(_ indices: [Int]) -> Int {
        var bitmask = 0
        for index in indices {
            bitmask |= (1 << index)
        }
        return bitmask
    }

    /// Get cards at specified indices
    func cardsAtIndices(_ indices: [Int]) -> [Card] {
        indices.compactMap { index in
            guard index >= 0 && index < cards.count else { return nil }
            return cards[index]
        }
    }
}
