import Foundation

@MainActor
@Observable
final class CasinoModeViewModel {

    // MARK: - State

    private(set) var isSessionActive: Bool = false
    var listeningState: VoiceService.ListeningState { voiceService.listeningState }
    var lastResponse: String { voiceService.lastResponse }
    var currentTranscript: String { voiceService.currentTranscript }
    var lastHand: Hand? { voiceService.lastHand }
    var lastStrategyResult: StrategyResult? { voiceService.lastStrategyResult }
    var errorMessage: String? {
        if case .error(let msg) = voiceService.listeningState { return msg }
        return nil
    }

    // MARK: - Dependencies

    let paytableId: String
    let gameFamily: GameFamily
    private let voiceService: VoiceService
    private let speechService: SpeechSynthesisService

    // MARK: - Init

    init(paytableId: String) {
        self.paytableId = paytableId
        self.gameFamily = PayTable.allPayTables.first(where: { $0.id == paytableId })?.family ?? .jacksOrBetter
        self.speechService = SpeechSynthesisService()
        self.voiceService = VoiceService(
            speechService: speechService,
            strategyService: StrategyService.shared,
            gameFamily: gameFamily,
            paytableId: paytableId
        )
    }

    // MARK: - Public API

    func startSession() {
        guard !isSessionActive else { return }
        isSessionActive = true
        voiceService.startVolumeButtonMonitoring()
    }

    func endSession() {
        guard isSessionActive else { return }
        voiceService.stopVolumeButtonMonitoring()
        voiceService.stopListening()
        speechService.stop()
        isSessionActive = false
    }

    func toggleListening() {
        switch voiceService.listeningState {
        case .idle:       voiceService.startListening()
        case .listening:  voiceService.stopListening()
        case .processing: break
        case .error:      voiceService.stopListening()
        }
    }

}
