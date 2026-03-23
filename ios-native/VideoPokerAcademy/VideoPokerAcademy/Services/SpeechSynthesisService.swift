import AVFoundation

@MainActor
@Observable
final class SpeechSynthesisService: NSObject {

    // MARK: - Observable State

    private(set) var isSpeaking: Bool = false

    // MARK: - Private

    private let synthesizer = AVSpeechSynthesizer()

    // MARK: - Init

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Public API

    func speak(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 1.0
        synthesizer.speak(utterance)
        // isSpeaking set to true by didStart delegate callback
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        // isSpeaking reset by didCancel delegate callback
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechSynthesisService: AVSpeechSynthesizerDelegate {

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
