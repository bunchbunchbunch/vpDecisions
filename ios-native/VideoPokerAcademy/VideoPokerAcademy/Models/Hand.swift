import Foundation

struct Hand: Identifiable {
    let id = UUID()
    var cards: [Card]

    init(cards: [Card]) {
        assert(cards.count == 5, "A hand must have exactly 5 cards")
        self.cards = cards
    }

    /// Generate canonical key for database lookup
    /// Matches the React Native implementation exactly
    /// Jokers sort to the end and are encoded as "Ww"
    var canonicalKey: String {
        let naturals = cards.filter { $0.rank != .joker }
        let jokerCount = cards.count - naturals.count

        let sorted = naturals.sorted {
            if $0.rank.rawValue != $1.rank.rawValue {
                return $0.rank.rawValue < $1.rank.rawValue
            }
            return $0.suit.rawValue < $1.suit.rawValue
        }

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

        let naturalKey = sorted.map { "\($0.rank.display)\(suitMap[$0.suit]!)" }.joined()
        let jokerSuffix = String(repeating: "Ww", count: jokerCount)
        return naturalKey + jokerSuffix
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
    /// Canonical order: sorted naturals first, then jokers at the end
    func canonicalIndicesToOriginal(_ canonicalIndices: [Int]) -> [Int] {
        let naturalsWithOriginal = cards.enumerated()
            .filter { $0.element.rank != .joker }
            .map { (original: $0.offset, card: $0.element) }

        let sortedNaturals = naturalsWithOriginal.sorted {
            if $0.card.rank.rawValue != $1.card.rank.rawValue {
                return $0.card.rank.rawValue < $1.card.rank.rawValue
            }
            return $0.card.suit.rawValue < $1.card.suit.rawValue
        }

        let jokerOriginals = cards.enumerated()
            .filter { $0.element.rank == .joker }
            .map { $0.offset }

        // Canonical order: sorted naturals, then jokers
        let canonicalToOriginal = sortedNaturals.map { $0.original } + jokerOriginals

        return canonicalIndices.compactMap { ci -> Int? in
            guard ci >= 0 && ci < canonicalToOriginal.count else { return nil }
            return canonicalToOriginal[ci]
        }
    }

    /// Convert indices from original deal order to canonical (sorted) order
    /// Needed when comparing user selection against database best hold
    /// Canonical order: sorted naturals first, then jokers at the end
    func originalIndicesToCanonical(_ originalIndices: [Int]) -> [Int] {
        let naturalsWithOriginal = cards.enumerated()
            .filter { $0.element.rank != .joker }
            .map { (original: $0.offset, card: $0.element) }

        let sortedNaturals = naturalsWithOriginal.sorted {
            if $0.card.rank.rawValue != $1.card.rank.rawValue {
                return $0.card.rank.rawValue < $1.card.rank.rawValue
            }
            return $0.card.suit.rawValue < $1.card.suit.rawValue
        }

        let jokerOriginals = cards.enumerated()
            .filter { $0.element.rank == .joker }
            .map { $0.offset }

        // Build reverse mapping: original index -> canonical index
        let canonicalToOriginal = sortedNaturals.map { $0.original } + jokerOriginals
        var originalToCanonical: [Int: Int] = [:]
        for (canonicalIndex, originalIndex) in canonicalToOriginal.enumerated() {
            originalToCanonical[originalIndex] = canonicalIndex
        }

        return originalIndices.compactMap { originalIndex -> Int? in
            guard originalIndex >= 0 && originalIndex < cards.count else { return nil }
            return originalToCanonical[originalIndex]
        }
    }
}
