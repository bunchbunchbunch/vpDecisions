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

    /// Convert indices from canonical (sorted) order to original deal order
    /// The database stores hold bitmasks in sorted order, but we display cards in deal order
    func canonicalIndicesToOriginal(_ canonicalIndices: [Int]) -> [Int] {
        // Get the sorted version of the hand (same sorting used for canonical key)
        let sorted = cards.sorted { $0.rank.rawValue < $1.rank.rawValue }

        // For each canonical index, find the card in sorted order,
        // then find that card's position in the original deal order
        return canonicalIndices.compactMap { canonicalIndex -> Int? in
            guard canonicalIndex >= 0 && canonicalIndex < sorted.count else { return nil }
            let cardAtCanonicalIndex = sorted[canonicalIndex]
            // Find this card in the original hand
            return cards.firstIndex { $0.rank == cardAtCanonicalIndex.rank && $0.suit == cardAtCanonicalIndex.suit }
        }
    }

    /// Convert indices from original deal order to canonical (sorted) order
    /// Needed when comparing user selection against database best hold
    func originalIndicesToCanonical(_ originalIndices: [Int]) -> [Int] {
        // Get the sorted version of the hand
        let sorted = cards.sorted { $0.rank.rawValue < $1.rank.rawValue }

        // For each original index, find the card in the original hand,
        // then find that card's position in the sorted order
        return originalIndices.compactMap { originalIndex -> Int? in
            guard originalIndex >= 0 && originalIndex < cards.count else { return nil }
            let cardAtOriginalIndex = cards[originalIndex]
            // Find this card in the sorted hand
            return sorted.firstIndex { $0.rank == cardAtOriginalIndex.rank && $0.suit == cardAtOriginalIndex.suit }
        }
    }
}
