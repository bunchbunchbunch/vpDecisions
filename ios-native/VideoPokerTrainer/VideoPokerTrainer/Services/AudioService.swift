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

class AudioService: ObservableObject {
    static let shared = AudioService()

    @Published var isEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "soundEnabled")
        }
    }

    @Published var volume: Float = 0.7 {
        didSet {
            UserDefaults.standard.set(volume, forKey: "soundVolume")
            updatePlayerVolumes()
        }
    }

    private var players: [SoundEffect: AVAudioPlayer] = [:]

    private init() {
        // Load saved settings
        isEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        volume = UserDefaults.standard.object(forKey: "soundVolume") as? Float ?? 0.7

        // Configure audio session
        configureAudioSession()

        // Preload all sounds
        preloadSounds()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    private func preloadSounds() {
        for sound in SoundEffect.allCases {
            if let url = Bundle.main.url(forResource: sound.filename, withExtension: "mp3", subdirectory: "Sounds") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    player.volume = volume
                    players[sound] = player
                } catch {
                    print("Failed to load sound \(sound.rawValue): \(error)")
                }
            } else {
                print("Sound file not found: \(sound.filename).mp3")
            }
        }
    }

    private func updatePlayerVolumes() {
        for player in players.values {
            player.volume = volume
        }
    }

    func play(_ sound: SoundEffect) {
        guard isEnabled else { return }

        if let player = players[sound] {
            player.currentTime = 0
            player.play()
        }
    }
}
