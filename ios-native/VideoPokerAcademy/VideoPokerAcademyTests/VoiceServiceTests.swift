import Testing
@testable import VideoPokerAcademy

@MainActor
struct VoiceServiceTests {

    private func makeService() -> VoiceService {
        VoiceService(
            speechService: SpeechSynthesisService(),
            strategyService: StrategyService.shared,
            gameFamily: .jacksOrBetter,
            paytableId: "jacks-or-better-9-6"
        )
    }

    @Test("initial listeningState is idle")
    func testInitialStateIsIdle() {
        let service = makeService()
        #expect(service.listeningState == .idle)
    }

    @Test("ListeningState equality: same cases equal")
    func testListeningStateEquality() {
        #expect(VoiceService.ListeningState.idle == .idle)
        #expect(VoiceService.ListeningState.listening == .listening)
        #expect(VoiceService.ListeningState.processing == .processing)
        #expect(VoiceService.ListeningState.error("x") == .error("x"))
    }

    @Test("ListeningState inequality: different cases not equal")
    func testListeningStateInequality() {
        #expect(VoiceService.ListeningState.idle != .listening)
        #expect(VoiceService.ListeningState.error("a") != .error("b"))
    }

    @Test("stopListening from idle is a no-op")
    func testStopListeningFromIdleIsNoOp() {
        defer { AudioService.shared.resume() }
        AudioService.shared.resume()
        let service = makeService()
        service.stopListening()
        #expect(service.listeningState == .idle)
    }
}
