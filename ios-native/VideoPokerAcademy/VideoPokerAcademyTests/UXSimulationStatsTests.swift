import Testing
import Foundation
@testable import VideoPokerAcademy

@Suite("UX Simulation Stats Tests")
struct UXSimulationStatsTests {

    // MARK: - UXBigWin

    @Test("UXBigWin stores hand name, multiplier, and payout")
    func testUXBigWin() {
        let win = UXBigWin(handName: "Royal Flush", multiplier: 12, payoutDollars: 9375.0)
        #expect(win.handName == "Royal Flush")
        #expect(win.multiplier == 12)
        #expect(win.payoutDollars == 9375.0)
    }

    // MARK: - SimulationRun defaults

    @Test("SimulationRun defaults: uxTopWins empty, uxMultiplierDistribution empty")
    func testSimulationRunUXDefaults() {
        let run = SimulationRun(runNumber: 0)
        #expect(run.uxTopWins.isEmpty)
        #expect(run.uxMultiplierDistribution.isEmpty)
    }

    // MARK: - SimulationResults aggregation

    @Test("SimulationResults aggregates multiplier distribution across runs")
    func testAggregatedMultiplierDistribution() {
        var run1 = SimulationRun(runNumber: 0)
        run1.uxMultiplierDistribution = [1: 8, 2: 2]
        var run2 = SimulationRun(runNumber: 1)
        run2.uxMultiplierDistribution = [1: 5, 3: 3]

        let results = SimulationResults(
            config: SimulationConfig.default,
            runs: [run1, run2],
            isComplete: true,
            isCancelled: false
        )

        let dist = results.aggregatedUXMultiplierDistribution
        #expect(dist[1] == 13)
        #expect(dist[2] == 2)
        #expect(dist[3] == 3)
    }

    @Test("SimulationResults topUXBigWins returns top 5 sorted by payout")
    func testTopUXBigWins() {
        var run1 = SimulationRun(runNumber: 0)
        run1.uxTopWins = [
            UXBigWin(handName: "Royal Flush", multiplier: 12, payoutDollars: 9375.0),
            UXBigWin(handName: "Four Aces", multiplier: 4, payoutDollars: 500.0)
        ]
        var run2 = SimulationRun(runNumber: 1)
        run2.uxTopWins = [
            UXBigWin(handName: "Straight Flush", multiplier: 11, payoutDollars: 2750.0),
            UXBigWin(handName: "Royal Flush", multiplier: 7, payoutDollars: 5468.75),
            UXBigWin(handName: "Full House", multiplier: 12, payoutDollars: 180.0),
            UXBigWin(handName: "Four Aces", multiplier: 7, payoutDollars: 875.0),
        ]

        let results = SimulationResults(
            config: SimulationConfig.default,
            runs: [run1, run2],
            isComplete: true,
            isCancelled: false
        )

        let top = results.topUXBigWins
        #expect(top.count == 5)
        #expect(top[0].payoutDollars == 9375.0)
        #expect(top[1].payoutDollars == 5468.75)
        #expect(top[2].payoutDollars == 2750.0)
    }
}
