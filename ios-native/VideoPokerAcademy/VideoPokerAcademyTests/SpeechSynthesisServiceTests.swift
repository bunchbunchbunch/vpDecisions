import Testing
import AVFoundation
@testable import VideoPokerAcademy

@MainActor
struct SpeechSynthesisServiceTests {

    @Test("isSpeaking starts as false")
    func testInitialState() {
        let svc = SpeechSynthesisService()
        #expect(svc.isSpeaking == false)
    }

    @Test("didStart callback sets isSpeaking to true")
    func testDidStartSetsisSpeaking() async {
        let svc = SpeechSynthesisService()
        let utterance = AVSpeechUtterance(string: "test")
        svc.speechSynthesizer(AVSpeechSynthesizer(), didStart: utterance)
        await Task.yield()
        #expect(svc.isSpeaking == true)
    }

    @Test("stop() before any speech is a no-op")
    func testStopBeforeSpeechIsNoOp() {
        let svc = SpeechSynthesisService()
        // Should not crash
        svc.stop()
        #expect(svc.isSpeaking == false)
    }

    @Test("didFinish callback sets isSpeaking to false")
    func testDidFinishClearsIsSpeaking() async {
        let svc = SpeechSynthesisService()
        let utterance = AVSpeechUtterance(string: "test")
        svc.speechSynthesizer(AVSpeechSynthesizer(), didStart: utterance)
        await Task.yield()
        svc.speechSynthesizer(AVSpeechSynthesizer(), didFinish: utterance)
        await Task.yield()
        #expect(svc.isSpeaking == false)
    }

    @Test("didCancel callback sets isSpeaking to false")
    func testDidCancelClearsIsSpeaking() async {
        let svc = SpeechSynthesisService()
        let utterance = AVSpeechUtterance(string: "test")
        svc.speechSynthesizer(AVSpeechSynthesizer(), didStart: utterance)
        await Task.yield()
        svc.speechSynthesizer(AVSpeechSynthesizer(), didCancel: utterance)
        await Task.yield()
        #expect(svc.isSpeaking == false)
    }
}
