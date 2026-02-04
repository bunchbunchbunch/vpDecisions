import Foundation

@MainActor
class TrainingLessonListViewModel: ObservableObject {
    @Published var lessons: [TrainingLesson] = []
    @Published var scores: [Int: TrainingLessonScore] = [:]
    @Published var isLoading = true

    private let progressStore = TrainingProgressStore.shared

    func load() {
        lessons = TrainingLesson.allLessons
        refreshScores()
        isLoading = false
    }

    func refreshScores() {
        progressStore.loadIfNeeded()
        var updated: [Int: TrainingLessonScore] = [:]
        for lesson in lessons {
            updated[lesson.number] = progressStore.score(for: lesson.number)
        }
        scores = updated
    }

    func scoreFor(_ lessonNumber: Int) -> TrainingLessonScore {
        scores[lessonNumber] ?? TrainingLessonScore()
    }

    var completedCount: Int {
        scores.values.filter { $0.completed }.count
    }

    var totalCount: Int {
        lessons.count
    }

    var recommendedLessonNumber: Int {
        progressStore.recommendedLesson()
    }

    var hasCompletedAll: Bool {
        completedCount == totalCount && totalCount > 0
    }

    func statusFor(_ lessonNumber: Int) -> TrainingLessonStatus {
        let score = scoreFor(lessonNumber)
        if score.completed {
            return .completed
        } else if score.attempts > 0 {
            return .inProgress
        } else {
            return .notStarted
        }
    }
}

enum TrainingLessonStatus {
    case notStarted
    case inProgress
    case completed
}
