import Foundation

// MARK: - Training Lesson Model

struct TrainingLesson: Identifiable {
    var id: Int { number }
    let number: Int
    let title: String
    let keyConcept: String
    let whatToLearn: [String]
    let commonMistakes: [String]
    let practiceHands: [TrainingPracticeHand]
}

struct TrainingPracticeHand: Identifiable {
    var id: Int { number }
    let number: Int
    let cards: [String]        // ["7h", "8h", "9h", "4d", "2s"]
    let holdCards: [String]    // ["7h", "8h", "9h"] or [] for draw all
    let explanation: String

    /// Convert card strings to Card objects
    func getCards() -> [Card]? {
        guard cards.count == 5 else { return nil }
        return cards.compactMap { Card(from: $0) }
    }

    /// Indices in the cards array that should be held (from lesson plan)
    var holdIndices: [Int] {
        holdCards.compactMap { holdCard in
            cards.firstIndex(of: holdCard)
        }.sorted()
    }
}

// MARK: - Training Progress

struct TrainingLessonScore: Codable {
    var bestScore: Int = 0
    var totalHands: Int = 0
    var attempts: Int = 0
    var completed: Bool = false
    var lastAttemptDate: Date?
}

@MainActor
final class TrainingProgressStore: ObservableObject {
    static let shared = TrainingProgressStore()
    private let key = "training_lesson_progress_v2"
    private var cache: [Int: TrainingLessonScore] = [:]
    private var loaded = false
    @Published private(set) var changeCount = 0

    private init() {}

    func loadIfNeeded() {
        guard !loaded else { return }
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Int: TrainingLessonScore].self, from: data) {
            cache = decoded
        }
        loaded = true
    }

    func score(for lessonNumber: Int) -> TrainingLessonScore {
        loadIfNeeded()
        return cache[lessonNumber] ?? TrainingLessonScore()
    }

    func recordAttempt(lessonNumber: Int, score: Int, totalHands: Int) {
        loadIfNeeded()
        var existing = cache[lessonNumber] ?? TrainingLessonScore()
        existing.attempts += 1
        existing.totalHands = totalHands
        existing.lastAttemptDate = Date()
        if score > existing.bestScore {
            existing.bestScore = score
        }
        if score == totalHands {
            existing.completed = true
        }
        cache[lessonNumber] = existing
        save()
        changeCount += 1
    }

    /// Returns the recommended next lesson (first incomplete, or 1 if none started)
    func recommendedLesson() -> Int {
        loadIfNeeded()
        for i in 1...16 {
            let s = cache[i] ?? TrainingLessonScore()
            if !s.completed {
                return i
            }
        }
        return 1 // All complete, suggest review from start
    }

    func completedCount() -> Int {
        loadIfNeeded()
        return cache.values.filter { $0.completed }.count
    }

    private func save() {
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
