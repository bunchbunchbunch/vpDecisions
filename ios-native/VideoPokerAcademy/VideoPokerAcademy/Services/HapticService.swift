import UIKit

enum HapticType {
    case light
    case medium
    case heavy
    case success
    case error
    case warning
}

class HapticService: ObservableObject {
    static let shared = HapticService()

    @Published var isEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "hapticsEnabled")
        }
    }

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        // Load saved setting
        isEnabled = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true

        // Prepare generators
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        notificationGenerator.prepare()
    }

    func trigger(_ type: HapticType) {
        guard isEnabled else { return }

        switch type {
        case .light:
            lightGenerator.impactOccurred()
        case .medium:
            mediumGenerator.impactOccurred()
        case .heavy:
            heavyGenerator.impactOccurred()
        case .success:
            notificationGenerator.notificationOccurred(.success)
        case .error:
            notificationGenerator.notificationOccurred(.error)
        case .warning:
            notificationGenerator.notificationOccurred(.warning)
        }
    }
}
