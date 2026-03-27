import Testing
@testable import VideoPokerAcademy

struct HandWWWTests {
    @Test func canonicalKeyNoJokers() {
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .hearts),
            Card(rank: .king, suit: .hearts),
            Card(rank: .queen, suit: .hearts),
            Card(rank: .jack, suit: .hearts),
            Card(rank: .ten, suit: .hearts),
        ])
        #expect(hand.canonicalKey == "TaJaQaKaAa")
    }

    @Test func canonicalKeyWithOneJoker() {
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .hearts),
            Card(rank: .king, suit: .diamonds),
            Card(rank: .queen, suit: .clubs),
            Card(rank: .jack, suit: .spades),
            Card(rank: .joker, suit: .hearts),
        ])
        let key = hand.canonicalKey
        #expect(key.hasSuffix("Ww"))
        #expect(key.count == 10)
    }

    @Test func canonicalKeyWithTwoJokers() {
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .hearts),
            Card(rank: .king, suit: .hearts),
            Card(rank: .joker, suit: .hearts),
            Card(rank: .joker, suit: .hearts),
            Card(rank: .ten, suit: .diamonds),
        ])
        let key = hand.canonicalKey
        #expect(key.hasSuffix("WwWw"))
        #expect(key.count == 10)
    }

    @Test func canonicalKeyWithThreeJokers() {
        let hand = Hand(cards: [
            Card(rank: .joker, suit: .hearts),
            Card(rank: .ace, suit: .hearts),
            Card(rank: .king, suit: .diamonds),
            Card(rank: .joker, suit: .hearts),
            Card(rank: .joker, suit: .hearts),
        ])
        let key = hand.canonicalKey
        #expect(key.hasSuffix("WwWwWw"))
        #expect(key.count == 10)
    }

    @Test func canonicalIndicesToOriginalWithJokers() {
        let hand = Hand(cards: [
            Card(rank: .joker, suit: .hearts),
            Card(rank: .ace, suit: .hearts),
            Card(rank: .king, suit: .diamonds),
            Card(rank: .five, suit: .clubs),
            Card(rank: .joker, suit: .hearts),
        ])
        let originals = hand.canonicalIndicesToOriginal([0, 2, 3, 4])
        #expect(Set(originals) == Set([3, 1, 0, 4]))
    }
}
