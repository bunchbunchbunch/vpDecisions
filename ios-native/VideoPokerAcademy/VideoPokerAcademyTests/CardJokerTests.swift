import Foundation
import Testing
@testable import VideoPokerAcademy

struct CardJokerTests {
    @Test func jokerRankExists() {
        let joker = Card(rank: .joker, suit: .hearts)
        #expect(joker.rank == .joker)
    }

    @Test func jokerDisplayIsW() {
        #expect(Rank.joker.display == "W")
    }

    @Test func jokerImageNameIs1J() {
        let joker = Card(rank: .joker, suit: .hearts)
        #expect(joker.imageName == "1J")
    }

    @Test func standardDeckHas52Cards() {
        let deck = Card.createDeck()
        #expect(deck.count == 52)
        #expect(deck.allSatisfy { $0.rank != .joker })
    }

    @Test func shuffledDeckWithJokersHasCorrectCount() {
        let deck1 = Card.shuffledDeck(jokerCount: 1)
        #expect(deck1.count == 53)
        #expect(deck1.filter { $0.rank == .joker }.count == 1)

        let deck3 = Card.shuffledDeck(jokerCount: 3)
        #expect(deck3.count == 55)
        #expect(deck3.filter { $0.rank == .joker }.count == 3)
    }

    @Test func jokerNotInCaseIterable() {
        #expect(!Rank.allCases.contains(.joker))
    }

    @Test func jokerIsCodable() throws {
        let joker = Card(rank: .joker, suit: .hearts)
        let data = try JSONEncoder().encode(CardData(rank: joker.rank, suit: joker.suit))
        let decoded = try JSONDecoder().decode(CardData.self, from: data)
        #expect(decoded.rank == .joker)
    }
}
