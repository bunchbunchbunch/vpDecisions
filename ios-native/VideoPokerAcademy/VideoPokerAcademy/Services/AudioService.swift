import AVFoundation
import Foundation

enum SoundEffect: String, CaseIterable {
    case cardSelect = "card-select"
    case cardFlip = "card-flip"
    case coinPayout = "coin-payout"
    case bigWin = "big-win"
    case submit = "submit"
    case correct = "correct"
    case incorrect = "incorrect"
    case nextHand = "next-hand"
    case quizComplete = "quiz-complete"
    case buttonTap = "button-tap"
    case dealtWinner = "dealt-winner"

    var filename: String {
        rawValue
    }
}

enum SoundMode: String, CaseIterable {
    case alwaysOff = "off"
    case alwaysOn = "on"
    case respectSilentMode = "silent"

    var label: String {
        switch self {
        case .alwaysOff: return "Always Off"
        case .alwaysOn: return "Always On"
        case .respectSilentMode: return "Respect Silent Mode"
        }
    }

    var description: String {
        switch self {
        case .alwaysOff: return "Sound effects are disabled"
        case .alwaysOn: return "Plays even when device is on silent"
        case .respectSilentMode: return "No sound when device is on silent"
        }
    }
}

class AudioService: ObservableObject {
    static let shared = AudioService()

    @Published var soundMode: SoundMode = .alwaysOn {
        didSet {
            UserDefaults.standard.set(soundMode.rawValue, forKey: "soundMode")
            configureAudioSession()
        }
    }

    @Published var volume: Float = 0.7 {
        didSet {
            UserDefaults.standard.set(volume, forKey: "soundVolume")
            updatePlayerVolumes()
        }
    }

    private var players: [SoundEffect: AVAudioPlayer] = [:]
    private let playerLock = NSLock()

    private init() {
        // Load saved settings
        if let rawMode = UserDefaults.standard.string(forKey: "soundMode"),
           let mode = SoundMode(rawValue: rawMode) {
            soundMode = mode
        } else {
            // Migrate from old isEnabled setting
            let wasEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
            soundMode = wasEnabled ? .alwaysOn : .alwaysOff
        }
        volume = UserDefaults.standard.object(forKey: "soundVolume") as? Float ?? 0.7

        // Configure audio session
        configureAudioSession()

        // Preload all sounds
        preloadSounds()
    }

    private func configureAudioSession() {
        do {
            switch soundMode {
            case .alwaysOff:
                // No need to configure session when sound is off
                break
            case .alwaysOn:
                try AVAudioSession.sharedInstance().setCategory(
                    .playback,
                    mode: .default,
                    options: [.mixWithOthers]
                )
                try AVAudioSession.sharedInstance().setActive(true)
            case .respectSilentMode:
                try AVAudioSession.sharedInstance().setCategory(
                    .ambient,
                    mode: .default,
                    options: [.mixWithOthers]
                )
                try AVAudioSession.sharedInstance().setActive(true)
            }
        } catch {
            debugLog("Failed to configure audio session: \(error)")
        }
    }

    private func preloadSounds() {
        debugNSLog("🔊 AudioService: Starting to preload sounds...")
        playerLock.lock()
        defer { playerLock.unlock() }

        for sound in SoundEffect.allCases {
            // Try without subdirectory first (files copied to bundle root)
            var url = Bundle.main.url(forResource: sound.filename, withExtension: "mp3")

            // Fallback to subdirectory if needed
            if url == nil {
                url = Bundle.main.url(forResource: sound.filename, withExtension: "mp3", subdirectory: "Sounds")
            }

            if let url = url {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    player.volume = volume
                    players[sound] = player
                    debugNSLog("🔊 AudioService: Loaded %@", sound.rawValue)
                } catch {
                    debugNSLog("🔊 AudioService: Failed to load %@: %@", sound.rawValue, error.localizedDescription)
                }
            } else {
                debugNSLog("🔊 AudioService: File not found: %@.mp3", sound.filename)
            }
        }
        debugNSLog("🔊 AudioService: Preloaded %d sounds", players.count)
    }

    private func updatePlayerVolumes() {
        playerLock.lock()
        defer { playerLock.unlock() }

        for player in players.values {
            player.volume = volume
        }
    }

    func play(_ sound: SoundEffect) {
        guard soundMode != .alwaysOff else { return }

        // Play sound on background queue to avoid blocking UI during rapid gestures
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }

            self.playerLock.lock()
            guard let player = self.players[sound] else {
                self.playerLock.unlock()
                return
            }
            player.currentTime = 0
            player.play()
            self.playerLock.unlock()
        }
    }
}
