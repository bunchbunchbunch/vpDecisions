import Testing
@testable import VideoPokerAcademy

struct ResponseFormatterTests {

    private func result(hold indices: [Int], ev: Double = 1.0) -> StrategyResult {
        StrategyResult(
            bestHold: Hand.bitmaskFromHoldIndices(indices),
            bestEv: ev,
            holdEvs: [:]
        )
    }

    // MARK: - Hold All Five (made hands)

    @Test("royal flush — hold all five")
    func testRoyalFlush() {
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .spades), Card(rank: .king, suit: .spades),
            Card(rank: .queen, suit: .spades), Card(rank: .jack, suit: .spades),
            Card(rank: .ten, suit: .spades)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3,4], ev: 800), gameFamily: .jacksOrBetter)
        #expect(r == "Royal flush. Hold all five.")
    }

    @Test("straight flush — hold all five")
    func testStraightFlush() {
        let hand = Hand(cards: [
            Card(rank: .nine, suit: .hearts), Card(rank: .eight, suit: .hearts),
            Card(rank: .seven, suit: .hearts), Card(rank: .six, suit: .hearts),
            Card(rank: .five, suit: .hearts)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3,4], ev: 50), gameFamily: .jacksOrBetter)
        #expect(r == "Straight flush. Hold all five.")
    }

    @Test("four of a kind — hold all five")
    func testFourOfAKind() {
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .spades), Card(rank: .ace, suit: .hearts),
            Card(rank: .ace, suit: .diamonds), Card(rank: .ace, suit: .clubs),
            Card(rank: .king, suit: .spades)
        ])
        // Strategy holds all 5 (kicker included) — response says "Hold all five"
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3,4], ev: 25), gameFamily: .jacksOrBetter)
        #expect(r == "Four of a kind. Hold all five.")
    }

    @Test("full house — hold all five")
    func testFullHouse() {
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .spades), Card(rank: .ace, suit: .hearts),
            Card(rank: .ace, suit: .diamonds), Card(rank: .king, suit: .clubs),
            Card(rank: .king, suit: .spades)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3,4], ev: 9), gameFamily: .jacksOrBetter)
        #expect(r == "Full house. Hold all five.")
    }

    @Test("flush — hold all five")
    func testFlush() {
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .hearts), Card(rank: .nine, suit: .hearts),
            Card(rank: .seven, suit: .hearts), Card(rank: .four, suit: .hearts),
            Card(rank: .two, suit: .hearts)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3,4], ev: 6), gameFamily: .jacksOrBetter)
        #expect(r == "Flush. Hold all five.")
    }

    @Test("straight — hold all five")
    func testStraight() {
        let hand = Hand(cards: [
            Card(rank: .nine, suit: .spades), Card(rank: .eight, suit: .hearts),
            Card(rank: .seven, suit: .diamonds), Card(rank: .six, suit: .clubs),
            Card(rank: .five, suit: .spades)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3,4], ev: 4), gameFamily: .jacksOrBetter)
        #expect(r == "Straight. Hold all five.")
    }

    // MARK: - Discard All

    @Test("discard all")
    func testDiscardAll() {
        let hand = Hand(cards: [
            Card(rank: .seven, suit: .clubs), Card(rank: .four, suit: .hearts),
            Card(rank: .two, suit: .spades), Card(rank: .nine, suit: .diamonds),
            Card(rank: .jack, suit: .hearts)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [], ev: 0.36), gameFamily: .jacksOrBetter)
        #expect(r == "No made hand. Discard everything.")
    }

    // MARK: - Pairs / Trips (partial holds)

    @Test("high pair — jacks")
    func testHighPair() {
        let hand = Hand(cards: [
            Card(rank: .jack, suit: .hearts), Card(rank: .jack, suit: .diamonds),
            Card(rank: .seven, suit: .clubs), Card(rank: .four, suit: .spades),
            Card(rank: .two, suit: .hearts)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1], ev: 1.54), gameFamily: .jacksOrBetter)
        #expect(r == "Pair of jacks. Hold the two jacks.")
    }

    @Test("low pair")
    func testLowPair() {
        let hand = Hand(cards: [
            Card(rank: .four, suit: .hearts), Card(rank: .four, suit: .diamonds),
            Card(rank: .king, suit: .clubs), Card(rank: .nine, suit: .spades),
            Card(rank: .two, suit: .hearts)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1], ev: 0.82), gameFamily: .jacksOrBetter)
        #expect(r == "Low pair. Hold the two fours.")
    }

    @Test("three of a kind")
    func testThreeOfAKind() {
        let hand = Hand(cards: [
            Card(rank: .queen, suit: .hearts), Card(rank: .queen, suit: .diamonds),
            Card(rank: .queen, suit: .clubs), Card(rank: .king, suit: .spades),
            Card(rank: .two, suit: .hearts)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2], ev: 4), gameFamily: .jacksOrBetter)
        #expect(r == "Three queens. Hold the three queens.")
    }

    @Test("two pair")
    func testTwoPair() {
        let hand = Hand(cards: [
            Card(rank: .jack, suit: .hearts), Card(rank: .jack, suit: .diamonds),
            Card(rank: .four, suit: .clubs), Card(rank: .four, suit: .spades),
            Card(rank: .two, suit: .hearts)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3], ev: 2.6), gameFamily: .jacksOrBetter)
        #expect(r == "Two pair. Hold the jacks and fours.")
    }

    // MARK: - Draws

    @Test("four to a royal")
    func testFourToRoyal() {
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .spades), Card(rank: .king, suit: .spades),
            Card(rank: .queen, suit: .spades), Card(rank: .jack, suit: .spades),
            Card(rank: .two, suit: .hearts)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3], ev: 18.4), gameFamily: .jacksOrBetter)
        #expect(r == "Four to a royal. Hold the ace, king, queen, and jack.")
    }

    @Test("four to a flush")
    func testFourToFlush() {
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .hearts), Card(rank: .ten, suit: .hearts),
            Card(rank: .eight, suit: .hearts), Card(rank: .four, suit: .hearts),
            Card(rank: .two, suit: .clubs)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3], ev: 1.22), gameFamily: .jacksOrBetter)
        #expect(r == "Four to a flush. Hold the ace, ten, eight, and four.")
    }

    // MARK: - Wild Card Games

    @Test("wild game: natural royal flush is labeled correctly")
    func testWildGameNaturalRoyal() {
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .spades), Card(rank: .king, suit: .spades),
            Card(rank: .queen, suit: .spades), Card(rank: .jack, suit: .spades),
            Card(rank: .ten, suit: .spades)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3,4], ev: 800), gameFamily: .deucesWild)
        #expect(r == "Natural royal flush. Hold all five.")
    }

    @Test("four of a kind — partial hold, discard kicker")
    func testFourOfAKindPartialHold() {
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .spades), Card(rank: .ace, suit: .hearts),
            Card(rank: .ace, suit: .diamonds), Card(rank: .ace, suit: .clubs),
            Card(rank: .king, suit: .spades)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3]), gameFamily: .jacksOrBetter)
        #expect(r == "Four of a kind. Hold the four aces.")
    }

    @Test("wild game: four deuces — hold all five")
    func testWildGameFourDeuces() {
        let hand = Hand(cards: [
            Card(rank: .two, suit: .spades), Card(rank: .two, suit: .hearts),
            Card(rank: .two, suit: .diamonds), Card(rank: .two, suit: .clubs),
            Card(rank: .ace, suit: .spades)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3,4]), gameFamily: .deucesWild)
        #expect(r == "Four deuces. Hold all five.")
    }

    @Test("wild game: five of a kind — hold all five")
    func testWildGameFiveOfAKind() {
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .spades), Card(rank: .ace, suit: .hearts),
            Card(rank: .ace, suit: .diamonds), Card(rank: .ace, suit: .clubs),
            Card(rank: .two, suit: .spades)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3,4]), gameFamily: .deucesWild)
        #expect(r == "Five of a kind. Hold all five.")
    }

    @Test("wild game: hold instruction names held deuce as wild two")
    func testWildGameHoldInstructionWithWild() {
        let hand = Hand(cards: [
            Card(rank: .queen, suit: .hearts), Card(rank: .queen, suit: .diamonds),
            Card(rank: .two, suit: .clubs),
            Card(rank: .king, suit: .spades),
            Card(rank: .ace, suit: .hearts)
        ])
        // 2 queens + wild deuce = three of a kind
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2]), gameFamily: .deucesWild)
        #expect(r == "Three of a kind. Hold the two queens and the wild two.")
    }

    // MARK: - Spoken rank names use words not digits

    @Test("numeric rank spoken as word, not digit")
    func testNumericRankAsWord() {
        let hand = Hand(cards: [
            Card(rank: .two, suit: .hearts), Card(rank: .two, suit: .diamonds),
            Card(rank: .king, suit: .clubs), Card(rank: .nine, suit: .spades),
            Card(rank: .seven, suit: .hearts)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1], ev: 0.82), gameFamily: .jacksOrBetter)
        #expect(r.contains("two"))
        #expect(!r.contains("2"))
    }
}
