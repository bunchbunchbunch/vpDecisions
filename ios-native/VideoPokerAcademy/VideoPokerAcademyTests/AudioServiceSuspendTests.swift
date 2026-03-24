import Testing
@testable import VideoPokerAcademy

@MainActor
struct AudioServiceSuspendTests {

    @Test("suspend sets isSuspended to true")
    func testSuspendSetsSuspendedFlag() {
        defer { AudioService.shared.resume() }
        AudioService.shared.resume()  // ensure clean state (idempotent with guard)
        AudioService.shared.suspend()
        #expect(AudioService.shared.isSuspended == true)
    }

    @Test("resume clears isSuspended flag")
    func testResumeClearsSuspendedFlag() {
        defer { AudioService.shared.resume() }
        AudioService.shared.suspend()
        AudioService.shared.resume()
        #expect(AudioService.shared.isSuspended == false)
    }

    @Test("play is a no-op while suspended")
    func testPlayDoesNothingWhileSuspended() {
        defer { AudioService.shared.resume() }
        AudioService.shared.suspend()
        // Should not crash — just a no-op
        AudioService.shared.play(.buttonTap)
        #expect(AudioService.shared.isSuspended == true)
    }
}
