import Foundation

@MainActor
class LessonViewModel: ObservableObject {
    @Published var lesson: Lesson?
    @Published var progress: LessonProgress
    @Published var isLoading = true
    @Published var error: String?

    // Quiz state
    @Published var quizHands: [PracticeHand] = []
    @Published var currentQuizIndex: Int = 0
    @Published var selectedIndices: Set<Int> = []
    @Published var correctCount: Int = 0
    @Published var isQuizComplete: Bool = false
    @Published var showFeedback: Bool = false
    @Published var lastAnswerCorrect: Bool = false

    private let lessonId: String
    private let paytableId: String

    var currentHand: PracticeHand? {
        guard currentQuizIndex < quizHands.count else { return nil }
        return quizHands[currentQuizIndex]
    }

    var quizProgress: Double {
        guard !quizHands.isEmpty else { return 0 }
        return Double(currentQuizIndex) / Double(quizHands.count)
    }

    var quizScore: Int {
        correctCount
    }

    var quizPassed: Bool {
        guard let lesson = lesson else { return false }
        return correctCount >= lesson.passingScore
    }

    init(lessonId: String, paytableId: String = PayTable.jacksOrBetter96.id) {
        self.lessonId = lessonId
        self.paytableId = paytableId
        self.progress = LessonProgress.initial(lessonId: lessonId)
    }

    func load() async {
        isLoading = true
        error = nil

        do {
            guard let loadedLesson = await TrainingService.shared.lesson(for: lessonId) else {
                error = "Lesson not found"
                isLoading = false
                return
            }

            lesson = loadedLesson
            progress = await TrainingService.shared.progress(for: lessonId)

            // Prepare quiz hands (shuffle for variety)
            quizHands = loadedLesson.practiceHands.shuffled().prefix(loadedLesson.quizSize).map { $0 }

            isLoading = false
        }
    }

    func startQuiz() {
        currentQuizIndex = 0
        correctCount = 0
        selectedIndices = []
        isQuizComplete = false
        showFeedback = false

        // Mark as in progress if not already completed
        if progress.status == .notStarted {
            progress.status = .inProgress
            Task {
                await TrainingService.shared.updateProgress(progress)
            }
        }
    }

    func toggleCardSelection(_ index: Int) {
        guard !showFeedback else { return }
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }

    func submit() {
        guard let hand = currentHand else { return }

        // Check if answer is correct
        let userHold = Array(selectedIndices).sorted()
        let correctHold = hand.correctHold.sorted()

        lastAnswerCorrect = userHold == correctHold
        if lastAnswerCorrect {
            correctCount += 1
        }

        showFeedback = true

        // Play audio feedback
        Task {
            if lastAnswerCorrect {
                AudioService.shared.play(.correct)
            } else {
                AudioService.shared.play(.incorrect)
            }
        }
    }

    func next() {
        showFeedback = false
        selectedIndices = []
        currentQuizIndex += 1

        if currentQuizIndex >= quizHands.count {
            completeQuiz()
        }
    }

    private func completeQuiz() {
        isQuizComplete = true

        // Record attempt
        Task {
            await TrainingService.shared.recordQuizAttempt(
                lessonId: lessonId,
                score: correctCount,
                passed: quizPassed
            )

            // Refresh progress
            progress = await TrainingService.shared.progress(for: lessonId)
        }
    }

    func retryQuiz() {
        // Re-shuffle hands and restart
        if let lesson = lesson {
            quizHands = lesson.practiceHands.shuffled().prefix(lesson.quizSize).map { $0 }
        }
        startQuiz()
    }
}
