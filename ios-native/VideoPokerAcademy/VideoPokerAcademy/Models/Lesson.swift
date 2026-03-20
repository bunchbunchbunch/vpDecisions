import Foundation

// MARK: - Lesson Model

struct Lesson: Identifiable, Codable {
    let id: String                    // "job-made-hands"
    let title: String                 // "Made Hands"
    let description: String
    let order: Int                    // Display order
    let sections: [LessonSection]     // Concept + Example sections
    let practiceHands: [PracticeHand] // Curated hands for quiz
    let passingScore: Int             // 8 out of 10

    var quizSize: Int {
        min(practiceHands.count, 10)
    }
}

// MARK: - Lesson Section

enum LessonSectionType: String, Codable {
    case concept
    case example
    case tip
}

struct LessonSection: Identifiable, Codable {
    let id: String
    let type: LessonSectionType
    let title: String?
    let content: String?              // Markdown text
    let exampleHand: ExampleHand?     // For guided examples
}

// MARK: - Example Hand (for guided examples in lessons)

struct ExampleHand: Codable {
    let cards: [String]               // ["Ah", "Kh", "Qh", "Jh", "9c"]
    let correctHold: [Int]            // Indices to hold (0-4)
    let explanation: String           // Why this is correct

    /// Convert card strings to Card objects
    func getCards() -> [Card]? {
        guard cards.count == 5 else { return nil }
        return cards.compactMap { Card(from: $0) }
    }
}

// MARK: - Practice Hand (for lesson quiz)

struct PracticeHand: Identifiable, Codable {
    let id: String
    let cards: [String]               // ["Ah", "Kh", "Qh", "Jh", "9c"]
    let correctHold: [Int]            // Indices to hold
    let category: String              // HandCategory raw value
    let explanation: String?          // Optional explanation

    /// Convert card strings to Card objects
    func getCards() -> [Card]? {
        guard cards.count == 5 else { return nil }
        return cards.compactMap { Card(from: $0) }
    }

    var handCategory: HandCategory? {
        HandCategory(rawValue: category)
    }
}

// MARK: - Lesson Progress

struct LessonProgress: Codable, Identifiable {
    var id: String { lessonId }
    let lessonId: String
    var status: LessonStatus
    var bestScore: Int
    var attempts: Int
    var completedAt: Date?
    var lastAttemptAt: Date?

    enum CodingKeys: String, CodingKey {
        case lessonId = "lesson_id"
        case status
        case bestScore = "best_score"
        case attempts
        case completedAt = "completed_at"
        case lastAttemptAt = "last_attempt_at"
    }

    static func initial(lessonId: String) -> LessonProgress {
        LessonProgress(
            lessonId: lessonId,
            status: .notStarted,
            bestScore: 0,
            attempts: 0,
            completedAt: nil,
            lastAttemptAt: nil
        )
    }
}

enum LessonStatus: String, Codable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
}

// MARK: - Card Extension for String Parsing

extension Card {
    /// Initialize a Card from a short string like "Ah", "2c", "Td"
    init?(from shortString: String) {
        guard shortString.count >= 2 else { return nil }

        let rankChar = String(shortString.prefix(shortString.count - 1))
        let suitChar = shortString.suffix(1).lowercased()

        // Parse rank
        let rank: Rank
        switch rankChar {
        case "2": rank = .two
        case "3": rank = .three
        case "4": rank = .four
        case "5": rank = .five
        case "6": rank = .six
        case "7": rank = .seven
        case "8": rank = .eight
        case "9": rank = .nine
        case "T", "10": rank = .ten
        case "J": rank = .jack
        case "Q": rank = .queen
        case "K": rank = .king
        case "A": rank = .ace
        default: return nil
        }

        // Parse suit
        let suit: Suit
        switch suitChar {
        case "h": suit = .hearts
        case "d": suit = .diamonds
        case "c": suit = .clubs
        case "s": suit = .spades
        default: return nil
        }

        self.init(rank: rank, suit: suit)
    }
}
