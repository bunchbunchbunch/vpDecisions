import Testing
@testable import VideoPokerAcademy

@MainActor
struct CasinoModeViewModelTests {

    private func makeViewModel() -> CasinoModeViewModel {
        CasinoModeViewModel(paytableId: "jacks-or-better-9-6")
    }

    // MARK: - Initial State

    @Test("initial isSessionActive is false")
    func testInitialIsSessionActiveFalse() {
        let vm = makeViewModel()
        #expect(vm.isSessionActive == false)
    }

    @Test("initial listeningState is idle")
    func testInitialListeningStateIsIdle() {
        let vm = makeViewModel()
        #expect(vm.listeningState == .idle)
    }

    @Test("initial lastResponse is empty")
    func testInitialLastResponseIsEmpty() {
        let vm = makeViewModel()
        #expect(vm.lastResponse == "")
    }

    @Test("initial errorMessage is nil")
    func testInitialErrorMessageIsNil() {
        let vm = makeViewModel()
        #expect(vm.errorMessage == nil)
    }

    // MARK: - startSession

    @Test("startSession sets isSessionActive to true")
    func testStartSessionSetsActive() {
        let vm = makeViewModel()
        vm.startSession()
        #expect(vm.isSessionActive == true)
    }

    @Test("startSession clears errorMessage")
    func testStartSessionClearsErrorMessage() {
        let vm = makeViewModel()
        vm.startSession()
        #expect(vm.errorMessage == nil)
    }

    @Test("startSession is idempotent — calling twice does not change state unexpectedly")
    func testStartSessionIsIdempotent() {
        let vm = makeViewModel()
        vm.startSession()
        vm.startSession() // second call should be a no-op
        #expect(vm.isSessionActive == true)
        #expect(vm.errorMessage == nil)
    }

    // MARK: - endSession

    @Test("endSession sets isSessionActive to false")
    func testEndSessionSetsInactive() {
        let vm = makeViewModel()
        vm.startSession()
        vm.endSession()
        #expect(vm.isSessionActive == false)
    }

    @Test("endSession from inactive state is a no-op and does not crash")
    func testEndSessionFromInactiveIsNoOp() {
        let vm = makeViewModel()
        // Should not crash or change any unexpected state
        vm.endSession()
        #expect(vm.isSessionActive == false)
    }

    // MARK: - State propagation (via computed properties)

    @Test("listeningState is idle when voice service is idle")
    func testListeningStateIsIdleInitially() {
        let vm = makeViewModel()
        #expect(vm.listeningState == .idle)
    }

    @Test("errorMessage is nil when voice service is idle")
    func testErrorMessageIsNilWhenIdle() {
        let vm = makeViewModel()
        #expect(vm.errorMessage == nil)
    }

    @Test("currentTranscript is empty initially")
    func testCurrentTranscriptIsEmptyInitially() {
        let vm = makeViewModel()
        #expect(vm.currentTranscript == "")
    }
}
