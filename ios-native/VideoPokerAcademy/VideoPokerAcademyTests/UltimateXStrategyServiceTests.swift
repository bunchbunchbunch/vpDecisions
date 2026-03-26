import Testing
@testable import VideoPokerAcademy

struct UltimateXStrategyServiceTests {

    @Test("holdOptions correctly reconstructs hold options from holdEKs")
    func holdOptionsReconstructsCorrectly() throws {
        let baseResult = StrategyResult(
            bestHold: 31,
            bestEv: 0.8,
            holdEvs: ["31": 0.8, "0": 0.35, "15": 0.6]
        )
        // bitmask 31: 3*2.0*0.8 + 1.5 - 1.0 = 5.3
        // bitmask 15: 3*2.0*0.6 + 1.2 - 1.0 = 3.8
        // bitmask  0: 3*2.0*0.35 + 1.0 - 1.0 = 2.1
        let uxResult = UltimateXStrategyResult(
            baseResult: baseResult,
            currentMultiplier: 3,
            playCount: .ten,
            adjustedBestHold: 31,
            adjustedBestEv: 5.3,
            adjustedHoldEvs: ["31": 5.3, "15": 3.8, "0": 2.1],
            holdEKs: ["31": 1.5, "15": 1.2, "0": 1.0]
        )
        let hand = Hand(cards: [
            Card(rank: .ace,   suit: .spades),
            Card(rank: .king,  suit: .spades),
            Card(rank: .queen, suit: .spades),
            Card(rank: .jack,  suit: .spades),
            Card(rank: .ten,   suit: .clubs),
        ])

        let options = uxResult.holdOptions(for: hand)

        #expect(options.count == 3)
        #expect(options[0].adjustedEV == 5.3)
        #expect(options[0].eKAwarded == 1.5)
        #expect(options[0].baseEV == 0.8)

        // Formula check for every option
        for opt in options {
            let expected = 3.0 * 2.0 * opt.baseEV + opt.eKAwarded - 1.0
            #expect(abs(opt.adjustedEV - expected) < 0.001)
        }
    }

    @Test("strategyDiffers is true when adjusted best hold differs from base best")
    func strategyDiffersWhenHoldChanges() throws {
        let baseResult = StrategyResult(bestHold: 31, bestEv: 0.8, holdEvs: ["31": 0.8, "15": 0.9])
        let uxResult = UltimateXStrategyResult(
            baseResult: baseResult,
            currentMultiplier: 5,
            playCount: .ten,
            adjustedBestHold: 15,
            adjustedBestEv: 8.0,
            adjustedHoldEvs: ["31": 7.0, "15": 8.0],
            holdEKs: ["31": 1.0, "15": 1.1]
        )
        #expect(uxResult.strategyDiffers == true)
    }
}
