import Testing
@testable import VideoPokerAcademy

struct UltimateXMultiplierTableTests {

    // MARK: - JacksOrBetter group

    @Test("JoB 3-play: Full House = 12, Flush = 11, Straight = 7")
    func testJoBThreePlay() {
        #expect(UltimateXMultiplierTable.multiplier(for: "full house",    playCount: .three, family: .jacksOrBetter) == 12)
        #expect(UltimateXMultiplierTable.multiplier(for: "flush",         playCount: .three, family: .jacksOrBetter) == 11)
        #expect(UltimateXMultiplierTable.multiplier(for: "straight",      playCount: .three, family: .jacksOrBetter) == 7)
        #expect(UltimateXMultiplierTable.multiplier(for: "four of a kind",playCount: .three, family: .jacksOrBetter) == 2)
        #expect(UltimateXMultiplierTable.multiplier(for: "royal flush",   playCount: .three, family: .jacksOrBetter) == 2)
    }

    @Test("JoB 5-play: Four of a Kind = 3")
    func testJoBFivePlayQuads() {
        #expect(UltimateXMultiplierTable.multiplier(for: "four of a kind", playCount: .five, family: .jacksOrBetter) == 3)
        #expect(UltimateXMultiplierTable.multiplier(for: "royal flush",    playCount: .five, family: .jacksOrBetter) == 2)
    }

    @Test("JoB 10-play: Royal = 7, Straight Flush = 7, Four of a Kind = 3")
    func testJoBTenPlay() {
        #expect(UltimateXMultiplierTable.multiplier(for: "royal flush",    playCount: .ten, family: .jacksOrBetter) == 7)
        #expect(UltimateXMultiplierTable.multiplier(for: "straight flush", playCount: .ten, family: .jacksOrBetter) == 7)
        #expect(UltimateXMultiplierTable.multiplier(for: "four of a kind", playCount: .ten, family: .jacksOrBetter) == 3)
    }

    // MARK: - BonusPoker group

    @Test("BonusPoker 3-play: Straight = 8 (not 7), Flush = 11")
    func testBonusPokerThreePlay() {
        #expect(UltimateXMultiplierTable.multiplier(for: "straight", playCount: .three, family: .bonusPoker) == 8)
        #expect(UltimateXMultiplierTable.multiplier(for: "flush",    playCount: .three, family: .bonusPoker) == 11)
    }

    @Test("BonusPoker 10-play: Royal = 4, Four Aces = 4, Four 5-K = 3")
    func testBonusPokerTenPlay() {
        #expect(UltimateXMultiplierTable.multiplier(for: "royal flush", playCount: .ten, family: .bonusPoker) == 4)
        #expect(UltimateXMultiplierTable.multiplier(for: "four aces",   playCount: .ten, family: .bonusPoker) == 4)
        #expect(UltimateXMultiplierTable.multiplier(for: "four 5-k",    playCount: .ten, family: .bonusPoker) == 3)
    }

    // MARK: - DoubleBonus group

    @Test("DoubleBonus 3-play: Flush = 10 (not 11), Straight = 8")
    func testDoubleBonusThreePlay() {
        #expect(UltimateXMultiplierTable.multiplier(for: "flush",    playCount: .three, family: .doubleBonus) == 10)
        #expect(UltimateXMultiplierTable.multiplier(for: "straight", playCount: .three, family: .doubleBonus) == 8)
    }

    @Test("DoubleBonus 10-play: Royal = 4, Four Aces = 4, Four 5-K = 3")
    func testDoubleBonusTenPlay() {
        #expect(UltimateXMultiplierTable.multiplier(for: "royal flush", playCount: .ten, family: .doubleBonus) == 4)
        #expect(UltimateXMultiplierTable.multiplier(for: "four aces",   playCount: .ten, family: .doubleBonus) == 4)
        #expect(UltimateXMultiplierTable.multiplier(for: "four 5-k",    playCount: .ten, family: .doubleBonus) == 3)
    }

    @Test("DDB family uses DoubleBonus group: Flush = 10")
    func testDDBFamily() {
        #expect(UltimateXMultiplierTable.multiplier(for: "flush", playCount: .three, family: .doubleDoubleBonus) == 10)
        #expect(UltimateXMultiplierTable.multiplier(for: "flush", playCount: .three, family: .ddbPlus) == 10)
    }

    // MARK: - TripleDoubleBonus group

    @Test("TripleDoubleBonus: All quads flat 2x across all play counts")
    func testTripleDoubleBonusQuadsFlat() {
        for playCount in UltimateXPlayCount.allCases {
            #expect(UltimateXMultiplierTable.multiplier(for: "royal flush",    playCount: playCount, family: .tripleDoubleBonus) == 2)
            #expect(UltimateXMultiplierTable.multiplier(for: "four of a kind", playCount: playCount, family: .tripleDoubleBonus) == 2)
            #expect(UltimateXMultiplierTable.multiplier(for: "four aces",      playCount: playCount, family: .tripleDoubleBonus) == 2)
        }
    }

    @Test("TripleDoubleBonus: Flush = 10, Straight = 8, Full House = 12")
    func testTripleDoubleBonusMiddleHands() {
        #expect(UltimateXMultiplierTable.multiplier(for: "full house", playCount: .three, family: .tripleDoubleBonus) == 12)
        #expect(UltimateXMultiplierTable.multiplier(for: "flush",      playCount: .three, family: .tripleDoubleBonus) == 10)
        #expect(UltimateXMultiplierTable.multiplier(for: "straight",   playCount: .three, family: .tripleDoubleBonus) == 8)
    }

    // MARK: - DeucesWild group

    // IMPORTANT: HandEvaluator.evaluateDeucesWild returns "Natural Royal" and "Wild Royal"
    // (NOT "Natural Royal Flush" / "Wild Royal Flush"). Keys must match exactly after lowercasing.

    @Test("DeucesWild 3-play: Straight Flush = 12, Four of a Kind = 7, Full House = 5")
    func testDeucesWildThreePlay() {
        #expect(UltimateXMultiplierTable.multiplier(for: "straight flush",  playCount: .three, family: .deucesWild) == 12)
        #expect(UltimateXMultiplierTable.multiplier(for: "four of a kind",  playCount: .three, family: .deucesWild) == 7)
        #expect(UltimateXMultiplierTable.multiplier(for: "full house",      playCount: .three, family: .deucesWild) == 5)
        #expect(UltimateXMultiplierTable.multiplier(for: "flush",           playCount: .three, family: .deucesWild) == 5)
        #expect(UltimateXMultiplierTable.multiplier(for: "straight",        playCount: .three, family: .deucesWild) == 3)
        #expect(UltimateXMultiplierTable.multiplier(for: "three of a kind", playCount: .three, family: .deucesWild) == 2)
        #expect(UltimateXMultiplierTable.multiplier(for: "wild royal",      playCount: .three, family: .deucesWild) == 2)
        #expect(UltimateXMultiplierTable.multiplier(for: "natural royal",   playCount: .three, family: .deucesWild) == 2)
        #expect(UltimateXMultiplierTable.multiplier(for: "four deuces",     playCount: .three, family: .deucesWild) == 2)
    }

    @Test("DeucesWild 5-play: Five of a Kind = 3")
    func testDeucesWildFivePlayFiveOfAKind() {
        #expect(UltimateXMultiplierTable.multiplier(for: "five of a kind", playCount: .five,  family: .deucesWild) == 3)
        #expect(UltimateXMultiplierTable.multiplier(for: "five of a kind", playCount: .three, family: .deucesWild) == 2)
    }

    @Test("DeucesWild 10-play: Natural Royal = 4, Four Deuces = 4")
    func testDeucesWildTenPlay() {
        #expect(UltimateXMultiplierTable.multiplier(for: "natural royal",  playCount: .ten, family: .deucesWild) == 4)
        #expect(UltimateXMultiplierTable.multiplier(for: "four deuces",    playCount: .ten, family: .deucesWild) == 4)
        #expect(UltimateXMultiplierTable.multiplier(for: "wild royal",     playCount: .ten, family: .deucesWild) == 4)
        #expect(UltimateXMultiplierTable.multiplier(for: "straight flush", playCount: .ten, family: .deucesWild) == 12)
    }

    @Test("LooseDeuces uses DeucesWild group")
    func testLooseDeucesUsesDeucesWildGroup() {
        #expect(UltimateXMultiplierTable.multiplier(for: "straight flush", playCount: .three, family: .looseDeuces) == 12)
        #expect(UltimateXMultiplierTable.multiplier(for: "four of a kind", playCount: .three, family: .looseDeuces) == 7)
    }

    // MARK: - possibleMultipliers

    @Test("JoB possibleMultipliers: contains 11 and 12, not 5")
    func testPossibleMultipliersJoB() {
        let multipliers = UltimateXMultiplierTable.possibleMultipliers(for: .three, family: .jacksOrBetter)
        #expect(multipliers.contains(11))
        #expect(multipliers.contains(12))
        #expect(!multipliers.contains(5))
    }

    @Test("DeucesWild possibleMultipliers: contains 12 and 7, not 11")
    func testPossibleMultipliersDeucesWild() {
        let multipliers = UltimateXMultiplierTable.possibleMultipliers(for: .three, family: .deucesWild)
        #expect(multipliers.contains(12))
        #expect(multipliers.contains(7))
        #expect(!multipliers.contains(11))
    }

    // MARK: - Unknown hands fall back to 1

    @Test("Unknown hand name returns 1 (no multiplier)")
    func testUnknownHandReturnsOne() {
        #expect(UltimateXMultiplierTable.multiplier(for: "garbage hand", playCount: .three, family: .jacksOrBetter) == 1)
        #expect(UltimateXMultiplierTable.multiplier(for: "garbage hand", playCount: .three, family: .deucesWild) == 1)
    }
}
