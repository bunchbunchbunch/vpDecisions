import Foundation

/// Static tour content definitions for all screens
struct TourContent {

    /// Get the tour steps for a specific tour
    static func steps(for tourId: TourId) -> [TourStep] {
        switch tourId {
        case .home: return homeSteps
        case .playStart: return playStartSteps
        case .playGame: return playGameSteps
        case .quizStart: return quizStartSteps
        case .quizPlay: return quizPlaySteps
        case .analyzer: return analyzerSteps
        }
    }

    // MARK: - Home Screen Tour (3 steps)

    static let homeSteps: [TourStep] = [
        TourStep(
            targetId: "playModeButton",
            title: "Practice with Virtual Money",
            message: "Play video poker with adjustable stakes and get real-time strategy feedback.",
            position: .below,
            spotlightPadding: 4,
            cornerRadius: 16
        ),
        TourStep(
            targetId: "quizModeButton",
            title: "Test Your Knowledge",
            message: "Challenge yourself with random hands and track your progress.",
            position: .below,
            spotlightPadding: 4,
            cornerRadius: 16
        ),
        TourStep(
            targetId: "analyzerButton",
            title: "Analyze Any Hand",
            message: "Enter any hand to see the optimal strategy and expected value.",
            position: .below,
            spotlightPadding: 4,
            cornerRadius: 16
        )
    ]

    // MARK: - Play Start Screen Tour (4 steps)

    static let playStartSteps: [TourStep] = [
        TourStep(
            targetId: "gameSelector",
            title: "Choose Your Game",
            message: "Select from popular games or browse all variants.",
            position: .below,
            spotlightPadding: 8,
            cornerRadius: 12
        ),
        TourStep(
            targetId: "linesSelector",
            title: "Number of Hands",
            message: "Play 1, 5, 10, or 100 hands at once.",
            position: .below,
            spotlightPadding: 8,
            cornerRadius: 12
        ),
        TourStep(
            targetId: "denominationSelector",
            title: "Set Your Stakes",
            message: "Choose your bet amount per hand.",
            position: .above,
            spotlightPadding: 8,
            cornerRadius: 12
        ),
        TourStep(
            targetId: "optimalFeedbackToggle",
            title: "Learn as You Play",
            message: "Enable to see the best play after each hand.",
            position: .above,
            spotlightPadding: 8,
            cornerRadius: 12
        )
    ]

    // MARK: - Play Game Screen Tour (4 steps)

    static let playGameSteps: [TourStep] = [
        TourStep(
            targetId: "balanceArea",
            title: "Your Bankroll",
            message: "Track your virtual balance here.",
            position: .below,
            spotlightPadding: 8,
            cornerRadius: 8
        ),
        TourStep(
            targetId: "cardsArea",
            title: "Select Cards to Hold",
            message: "Tap or swipe across cards to hold them.",
            position: .above,
            spotlightPadding: 8,
            cornerRadius: 16
        ),
        TourStep(
            targetId: "actionButton",
            title: "Deal & Draw",
            message: "Deal new hands or draw replacement cards.",
            position: .above,
            spotlightPadding: 8,
            cornerRadius: 12
        ),
        TourStep(
            targetId: "paytableButton",
            title: "View Paytable",
            message: "Tap to see the full paytable for this game.",
            position: .below,
            spotlightPadding: 4,
            cornerRadius: 8
        )
    ]

    // MARK: - Quiz Start Screen Tour (3 steps)

    static let quizStartSteps: [TourStep] = [
        TourStep(
            targetId: "quizGameSelector",
            title: "Select a Game",
            message: "Choose which video poker variant to practice.",
            position: .below,
            spotlightPadding: 8,
            cornerRadius: 12
        ),
        TourStep(
            targetId: "quizSizeSelector",
            title: "Quiz Length",
            message: "Pick 10, 25, or 100 hands per quiz.",
            position: .above,
            spotlightPadding: 8,
            cornerRadius: 12
        ),
        TourStep(
            targetId: "startQuizButton",
            title: "Begin Your Quiz",
            message: "Test your strategy knowledge!",
            position: .above,
            spotlightPadding: 8,
            cornerRadius: 12
        )
    ]

    // MARK: - Quiz Play Screen Tour (3 steps)

    static let quizPlaySteps: [TourStep] = [
        TourStep(
            targetId: "progressBar",
            title: "Track Progress",
            message: "See how many hands you've completed.",
            position: .below,
            spotlightPadding: 8,
            cornerRadius: 8
        ),
        TourStep(
            targetId: "quizCardsArea",
            title: "Select Your Hold",
            message: "Tap or swipe to choose which cards to keep.",
            position: .above,
            spotlightPadding: 8,
            cornerRadius: 16
        ),
        TourStep(
            targetId: "submitButton",
            title: "Submit Your Answer",
            message: "Confirm your hold selection.",
            position: .above,
            spotlightPadding: 8,
            cornerRadius: 12
        )
    ]

    // MARK: - Analyzer Screen Tour (3 steps)

    static let analyzerSteps: [TourStep] = [
        TourStep(
            targetId: "cardGrid",
            title: "Build Your Hand",
            message: "Tap cards to select up to 5 for analysis.",
            position: .above,
            spotlightPadding: 8,
            cornerRadius: 12
        ),
        TourStep(
            targetId: "selectedCardsBar",
            title: "Your Hand",
            message: "Selected cards appear here. Tap Clear to start over.",
            position: .below,
            spotlightPadding: 8,
            cornerRadius: 12
        ),
        TourStep(
            targetId: "analyzerGameSelector",
            title: "Change Game",
            message: "Switch between different video poker variants.",
            position: .below,
            spotlightPadding: 8,
            cornerRadius: 12
        )
    ]
}
