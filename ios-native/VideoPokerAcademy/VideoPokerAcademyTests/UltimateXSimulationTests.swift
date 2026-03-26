import Testing
import Foundation
@testable import VideoPokerAcademy

@Suite("Ultimate X Simulation Tests")
struct UltimateXSimulationTests {

    @Test("SimulationConfig defaults: isUltimateXMode = false")
    func testSimulationConfigDefaults() {
        let config = SimulationConfig.default
        #expect(config.isUltimateXMode == false)
        #expect(config.playCount == .ten)
    }

    @Test("SimulationConfig totalWagered doubles in UX mode")
    func testSimulationConfigTotalWageredUX() {
        let standard = SimulationConfig(
            paytableId: PayTable.jacksOrBetter96.id,
            denomination: .quarter,
            linesPerHand: 10,
            handsPerSimulation: 100,
            numberOfSimulations: 1,
            isUltimateXMode: false,
            playCount: .ten
        )
        let ux = SimulationConfig(
            paytableId: PayTable.jacksOrBetter96.id,
            denomination: .quarter,
            linesPerHand: 10,
            handsPerSimulation: 100,
            numberOfSimulations: 1,
            isUltimateXMode: true,
            playCount: .ten
        )
        // UX bet is 2× standard (10 coins/line vs 5 coins/line)
        #expect(abs(ux.totalWagered - standard.totalWagered * 2) < 0.001)
    }

    @MainActor
    @Test("SimulationViewModel stores UX config vars")
    func testSimulationViewModelUXVars() {
        let vm = SimulationViewModel()
        #expect(vm.isUltimateXMode == false)
        #expect(vm.ultimateXPlayCount == .ten)
        vm.isUltimateXMode = true
        vm.ultimateXPlayCount = .three
        #expect(vm.isUltimateXMode == true)
        #expect(vm.ultimateXPlayCount == .three)
    }
}
