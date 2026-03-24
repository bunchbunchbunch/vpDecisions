import Testing
@testable import VideoPokerAcademy

struct HoldOutcomeCalculatorTests {

    @Test("E[K] for hold-all-five full house is 12 (3-play)")
    func testEKForFullHouseIsMultiplier12() async throws {
        // Full house: AAA KK → K awarded = 12 (three-play table)
        let cards = [
            Card.from(string: "Ah")!, Card.from(string: "Ac")!,
            Card.from(string: "Ad")!, Card.from(string: "Kh")!,
            Card.from(string: "Kc")!
        ]
        let hand = Hand(cards: cards)
        let calc = HoldOutcomeCalculator()
        let ek = await calc.computeEK(
            hand: hand,
            holdBitmask: 31,    // hold all 5
            paytableId: "jacks-or-better-9-6",
            playCount: .three
        )
        #expect(ek == 12.0)
    }

    @Test("E[K] for hold-all-five no-win hand is 1")
    func testEKForNoWinHandIs1() async throws {
        // 7c 8d Jc Kc 2h — rainbow garbage, no win
        let cards = [
            Card.from(string: "7c")!, Card.from(string: "8d")!,
            Card.from(string: "Jc")!, Card.from(string: "Kc")!,
            Card.from(string: "2h")!
        ]
        let hand = Hand(cards: cards)
        let calc = HoldOutcomeCalculator()
        let ek = await calc.computeEK(
            hand: hand,
            holdBitmask: 31,
            paytableId: "jacks-or-better-9-6",
            playCount: .three
        )
        #expect(ek == 1.0)    // no win → multiplier = 1
    }

    @Test("E[K] for hold-all-five flush is 11 (3-play)")
    func testEKForFlushIs11() async throws {
        // 2h 5h 9h Jh Ah — flush
        let cards = [
            Card.from(string: "2h")!, Card.from(string: "5h")!,
            Card.from(string: "9h")!, Card.from(string: "Jh")!,
            Card.from(string: "Ah")!
        ]
        let hand = Hand(cards: cards)
        let calc = HoldOutcomeCalculator()
        let ek = await calc.computeEK(
            hand: hand,
            holdBitmask: 31,
            paytableId: "jacks-or-better-9-6",
            playCount: .three
        )
        #expect(ek == 11.0)
    }

    @Test("E[K] is always at least 1.0 for any hold")
    func testEKIsAtLeast1ForAnyHold() async throws {
        let cards = [
            Card.from(string: "Jh")!, Card.from(string: "Jd")!,
            Card.from(string: "9h")!, Card.from(string: "8h")!,
            Card.from(string: "7h")!
        ]
        let hand = Hand(cards: cards)
        let calc = HoldOutcomeCalculator()

        // Hold 7h,8h (canonical indices 0,1 → bitmask 0b00011 = 3)
        let ekLow = await calc.computeEK(
            hand: hand,
            holdBitmask: 3,
            paytableId: "jacks-or-better-9-6",
            playCount: .three
        )
        #expect(ekLow >= 1.0)

        // Hold 9h,Jd,Jh (canonical indices 2,3,4 → bitmask 0b11100 = 28)
        let ekHigh = await calc.computeEK(
            hand: hand,
            holdBitmask: 28,
            paytableId: "jacks-or-better-9-6",
            playCount: .three
        )
        #expect(ekHigh >= 1.0)
    }

    @Test("E[K] for hold JJ draw 3 is approximately 2.46")
    func testEKForJJApprox246() async throws {
        // J♥J♦ 9♥8♥7♥ — hold JJ (bitmask 24 = canonical positions 3,4 = Jd,Jh)
        let cards = [
            Card.from(string: "Jh")!, Card.from(string: "Jd")!,
            Card.from(string: "9h")!, Card.from(string: "8h")!,
            Card.from(string: "7h")!
        ]
        let hand = Hand(cards: cards)
        let calc = HoldOutcomeCalculator()
        let ek = await calc.computeEK(
            hand: hand,
            holdBitmask: 24,
            paytableId: "jacks-or-better-9-6",
            playCount: .three
        )
        // Expected ~2.46 based on probability-weighted outcomes
        #expect(ek >= 2.3 && ek <= 2.6)
    }

    @Test("E[K] for bitmask 0 (discard all) returns 1.0")
    func testEKForDiscardAllReturns1() async throws {
        let cards = [
            Card.from(string: "Jh")!, Card.from(string: "Jd")!,
            Card.from(string: "9h")!, Card.from(string: "8h")!,
            Card.from(string: "7h")!
        ]
        let hand = Hand(cards: cards)
        let calc = HoldOutcomeCalculator()
        let ek = await calc.computeEK(
            hand: hand,
            holdBitmask: 0,
            paytableId: "jacks-or-better-9-6",
            playCount: .three
        )
        #expect(ek == 1.0)    // discard all skipped for performance → returns 1.0
    }
}
