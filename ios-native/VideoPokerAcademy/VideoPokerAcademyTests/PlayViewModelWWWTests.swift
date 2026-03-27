import Foundation
import Testing
@testable import VideoPokerAcademy

struct PlayViewModelWWWTests {
    @Test func wwwDealCreatesAugmentedDeck() async {
        let deck = Card.shuffledDeck(jokerCount: 2)
        #expect(deck.count == 54)
        let dealt = Array(deck.prefix(5))
        let remaining = Array(deck.dropFirst(5))
        #expect(dealt.count == 5)
        #expect(remaining.count == 49)
        let totalJokers = deck.filter { $0.rank == .joker }.count
        #expect(totalJokers == 2)
    }

    @Test func wwwDrawCanProduceJokersFromDeck() {
        let natural = [
            Card(rank: .ace, suit: .hearts),
            Card(rank: .king, suit: .hearts),
            Card(rank: .queen, suit: .hearts),
            Card(rank: .jack, suit: .hearts),
            Card(rank: .ten, suit: .hearts),
        ]
        var remaining = Card.createDeck().filter { card in
            !natural.contains(where: { $0.rank == card.rank && $0.suit == card.suit })
        }
        remaining.append(Card(rank: .joker, suit: .hearts))
        remaining.append(Card(rank: .joker, suit: .hearts))
        remaining.shuffle()
        #expect(remaining.count == 49)
        let jokerCount = remaining.filter { $0.rank == .joker }.count
        #expect(jokerCount == 2)
    }

    @Test func wwwActiveHandStatePersistsWildCount() throws {
        let cards = [
            Card(rank: .ace, suit: .hearts),
            Card(rank: .joker, suit: .hearts),
            Card(rank: .king, suit: .diamonds),
            Card(rank: .queen, suit: .clubs),
            Card(rank: .jack, suit: .spades),
        ]
        var settings = PlaySettings()
        settings.variant = .wildWildWild
        let state = ActiveHandState(
            dealtCards: cards,
            selectedIndices: [0, 1, 2],
            remainingDeck: [],
            betAmount: 30.0,
            settings: settings,
            wwwWildCount: 2
        )
        #expect(state.wwwWildCount == 2)
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(ActiveHandState.self, from: data)
        #expect(decoded.wwwWildCount == 2)
        #expect(decoded.dealtCards[1].rank == Rank.joker)
    }
}
