import Testing
@testable import VideoPokerAcademy

struct UltimateXEKTableTests {

    // MARK: - API completeness (pass with any values, including stubs)

    @Test("eKDrawAll returns a value for all family/playCount combinations")
    func testDrawAllAPIWorks() {
        for playCount in UltimateXPlayCount.allCases {
            let ek = UltimateXEKTable.eKDrawAll(playCount: playCount, family: .jacksOrBetter)
            #expect(ek >= 1.0)
        }
    }

    @Test("eKSingleCard returns a value for all rank/family/playCount combinations")
    func testSingleCardAPIWorks() {
        for rank in Rank.allCases {
            let ek = UltimateXEKTable.eKSingleCard(rank: rank, playCount: .three, family: .jacksOrBetter)
            #expect(ek >= 1.0)
        }
    }

    @Test("Same group families return identical E[K] values")
    func testSameGroupReturnsSameValue() {
        // acesAndFaces and doubleBonus map to group 2 (DoubleBonus)
        let db = UltimateXEKTable.eKDrawAll(playCount: .three, family: .doubleBonus)
        let af = UltimateXEKTable.eKDrawAll(playCount: .three, family: .acesAndFaces)
        #expect(db == af)

        // deucesWild and looseDeuces map to group 4
        let dw = UltimateXEKTable.eKDrawAll(playCount: .three, family: .deucesWild)
        let ld = UltimateXEKTable.eKDrawAll(playCount: .three, family: .looseDeuces)
        #expect(dw == ld)
    }

    // MARK: - Behavioral properties (FAIL with stubs=1.0, PASS with real values)

    @Test("JoB 3-play draw-all E[K] > 1.0 — winning hands push average above floor")
    func testJoBDrawAllAboveOne() {
        let ek = UltimateXEKTable.eKDrawAll(playCount: .three, family: .jacksOrBetter)
        #expect(ek > 1.0)
    }

    @Test("JoB 10-play draw-all E[K] > JoB 3-play — 10-play has higher multipliers")
    func testTenPlayHigherThanThreePlay() {
        let ten = UltimateXEKTable.eKDrawAll(playCount: .ten, family: .jacksOrBetter)
        let three = UltimateXEKTable.eKDrawAll(playCount: .three, family: .jacksOrBetter)
        #expect(ten > three)
    }

    @Test("JoB 3-play: holding Ace has higher E[K] than holding Two")
    func testAceBetterThanTwoJoB() {
        let ace = UltimateXEKTable.eKSingleCard(rank: .ace, playCount: .three, family: .jacksOrBetter)
        let two = UltimateXEKTable.eKSingleCard(rank: .two, playCount: .three, family: .jacksOrBetter)
        #expect(ace > two)
    }

    @Test("DeucesWild 3-play: holding a Two (wild card) has higher E[K] than holding a Three")
    func testDeucesWildWildCardBetter() {
        let deuce = UltimateXEKTable.eKSingleCard(rank: .two, playCount: .three, family: .deucesWild)
        let three = UltimateXEKTable.eKSingleCard(rank: .three, playCount: .three, family: .deucesWild)
        #expect(deuce > three)
    }
}
