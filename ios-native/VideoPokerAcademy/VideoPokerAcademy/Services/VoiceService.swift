import Speech
import AVFoundation
import AudioToolbox
import MediaPlayer

@MainActor
@Observable
final class VoiceService {

    // MARK: - State

    enum ListeningState: Equatable {
        case idle
        case listening
        case processing
        case error(String)
    }

    private(set) var listeningState: ListeningState = .idle
    private(set) var lastTranscript: String = ""
    private(set) var lastResponse: String = ""
    private(set) var currentTranscript: String = ""
    private(set) var lastHand: Hand? = nil
    private(set) var lastStrategyResult: StrategyResult? = nil

    // MARK: - Dependencies

    private let speechService: SpeechSynthesisService
    private let strategyService: StrategyService
    private let gameFamily: GameFamily
    private let paytableId: String

    // MARK: - Private — Speech Recognition

    private var recognizer: SFSpeechRecognizer?
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // MARK: - Private — Volume Button KVO

    private var audioSessionObserver: NSKeyValueObservation?
    private var kvoDebounceTask: Task<Void, Never>?
    private static let kvoDebounceMs: UInt64 = 300
    private let volumeView = MPVolumeView(frame: CGRect(x: -2000, y: -2000, width: 1, height: 1))

    // MARK: - Private — Accumulator (text carried across auto-restarts)

    private var recognitionAccumulator: String = ""

    // MARK: - Private — Timers

    private var listenWindowTask: Task<Void, Never>?
    private static let listenWindowSec: Double = 30

    // MARK: - Init

    init(speechService: SpeechSynthesisService, strategyService: StrategyService, gameFamily: GameFamily, paytableId: String) {
        self.speechService = speechService
        self.strategyService = strategyService
        self.gameFamily = gameFamily
        self.paytableId = paytableId
    }

    // MARK: - Public API

    /// Start listening window (called on volume button press)
    func startListening() {
        guard listeningState == .idle else { return }
        recognitionAccumulator = ""
        AudioService.shared.suspend()
        listeningState = .listening
        AudioServicesPlaySystemSound(1103) // iOS "begin recording" chime
        startRecognition()
        scheduleListenWindow()
    }

    /// Cancel any active listening (or process accumulated transcript if available)
    func stopListening() {
        let pending = [recognitionAccumulator, currentTranscript]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        recognitionAccumulator = ""
        stopRecognitionInternal()
        listenWindowTask?.cancel()
        listenWindowTask = nil
        currentTranscript = ""
        if !pending.isEmpty {
            print("[VoiceService] stopListening: processing \"\(pending)\"")
            handleTranscript(pending)
        } else {
            AudioService.shared.resume()
            listeningState = .idle
        }
    }

    // MARK: - Volume Button KVO

    func startVolumeButtonMonitoring() {
        let session = AVAudioSession.sharedInstance()
        // .playback + .mixWithOthers is more reliable for outputVolume KVO than .ambient
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        // Add volumeView to window so its slider subview is accessible
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) ?? UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first {
            window.addSubview(volumeView)
        }

        // Set to 0.5 so there's room to go up OR down before first press
        setSystemVolume(0.5)

        audioSessionObserver = session.observe(\.outputVolume, options: [.new, .old]) { [weak self, volumeView] _, change in
            guard let self, change.newValue != change.oldValue else { return }
            // Reset to center — capture volumeView directly to avoid main actor isolation issue
            if let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
                DispatchQueue.main.async { slider.value = 0.5 }
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.kvoDebounceTask?.cancel()
                self.kvoDebounceTask = Task { @MainActor [weak self] in
                    guard let self else { return }
                    try? await Task.sleep(nanoseconds: Self.kvoDebounceMs * 1_000_000)
                    guard !Task.isCancelled else { return }
                    self.handleVolumeButtonPress()
                }
            }
        }
    }

    func stopVolumeButtonMonitoring() {
        audioSessionObserver?.invalidate()
        audioSessionObserver = nil
        kvoDebounceTask?.cancel()
        kvoDebounceTask = nil
        volumeView.removeFromSuperview()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Private — Volume Reset

    private func setSystemVolume(_ value: Float) {
        guard let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider else { return }
        DispatchQueue.main.async {
            slider.value = value
        }
    }

    // MARK: - Private — Recognition Lifecycle

    private func startRecognition() {
        // Configure audio session for recording BEFORE accessing inputNode.
        // inputNode.outputFormat returns 0 Hz if the session isn't active + .playAndRecord.
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .measurement,
                                    options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            listeningState = .error("Microphone unavailable")
            AudioService.shared.resume()
            return
        }

        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard let recognizer, recognizer.isAvailable else {
            listeningState = .error("Speech recognition unavailable")
            AudioService.shared.resume()
            return
        }

        let engine = AVAudioEngine()
        audioEngine = engine
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        do {
            try engine.start()
        } catch {
            listeningState = .error("Microphone unavailable")
            AudioService.shared.resume()
            return
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let result {
                    let text = result.bestTranscription.formattedString
                    // Combine with anything heard in prior auto-restarted sessions
                    let combined = [self.recognitionAccumulator, text]
                        .filter { !$0.isEmpty }
                        .joined(separator: " ")
                    print("[VoiceService] partial=\(!result.isFinal) final=\(result.isFinal) combined=\"\(combined)\"")

                    // Don't process again if we already triggered handleTranscript
                    guard self.listeningState == .listening else { return }

                    // Show accumulated + current text in the UI
                    self.currentTranscript = combined

                    if result.isFinal {
                        // Guard: isFinal can fire with empty string on cancellation — ignore
                        guard !text.isEmpty else {
                            print("[VoiceService] isFinal was empty — ignoring cancellation artifact")
                            return
                        }
                        if (try? CardParser.parse(combined, gameFamily: self.gameFamily)) != nil {
                            // Have 5 cards — process
                            self.recognitionAccumulator = ""
                            self.lastTranscript = combined
                            self.currentTranscript = ""
                            self.handleTranscript(combined)
                        } else {
                            // Pause detected but not enough cards yet — accumulate and restart
                            print("[VoiceService] isFinal insufficient cards, accumulating \"\(combined)\" and restarting")
                            self.recognitionAccumulator = combined
                            self.stopRecognitionInternal()
                            self.startRecognition()
                        }
                    } else if (try? CardParser.parse(combined, gameFamily: self.gameFamily)) != nil {
                        // Eager parse: 5 cards in partial — process immediately before any revision
                        print("[VoiceService] eager parse: 5 cards found, processing now")
                        self.recognitionAccumulator = ""
                        self.lastTranscript = combined
                        self.currentTranscript = ""
                        self.handleTranscript(combined)
                    }
                } else if let error {
                    let nsError = error as NSError
                    // Code 1110 = no speech; treat as silence, not a real error
                    if nsError.code != 1110 {
                        self.currentTranscript = ""
                        self.listeningState = .error(error.localizedDescription)
                        self.stopRecognitionInternal()
                        AudioService.shared.resume()
                    }
                }
            }
        }
    }

    private func stopRecognitionInternal() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        recognizer = nil
    }

    // MARK: - Private — Transcript Handling

    private func handleTranscript(_ transcript: String) {
        recognitionAccumulator = ""
        listeningState = .processing
        stopRecognitionInternal()
        listenWindowTask?.cancel()
        listenWindowTask = nil

        Task { [weak self] in
            guard let self else { return }
            do {
                let cards = try CardParser.parse(transcript, gameFamily: gameFamily)
                let hand = Hand(cards: cards)
                let strategyResult = try await strategyService.bestHold(for: hand, paytableId: paytableId)
                let response = ResponseFormatter.format(hand: hand, result: strategyResult, gameFamily: gameFamily)
                await MainActor.run {
                    self.lastHand = hand
                    self.lastStrategyResult = strategyResult
                    self.lastResponse = response
                    self.listeningState = .idle
                    AudioServicesPlaySystemSound(1104) // iOS "end recording" chime
                    AudioService.shared.resume()
                    self.speechService.speak(response)
                }
            } catch {
                await MainActor.run {
                    self.listeningState = .error(error.localizedDescription)
                    AudioService.shared.resume()
                }
            }
        }
    }

    // MARK: - Private — Timer / Window

    private func scheduleListenWindow() {
        listenWindowTask?.cancel()
        listenWindowTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(Self.listenWindowSec * 1_000_000_000))
            guard !Task.isCancelled else { return }
            stopListening()
        }
    }

    // MARK: - Private — Button Handler

    private func handleVolumeButtonPress() {
        switch listeningState {
        case .idle:
            startListening()
        case .listening:
            stopListening()
        case .processing:
            break // ignore while processing
        case .error:
            listeningState = .idle
        }
    }
}
