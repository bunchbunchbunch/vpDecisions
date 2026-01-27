import Foundation

@MainActor
class TrainingHubViewModel: ObservableObject {
    @Published var lessons: [Lesson] = []
    @Published var lessonProgress: [String: LessonProgress] = [:]
    @Published var drills: [Drill] = []
    @Published var drillStats: [String: DrillStats] = [:]
    @Published var reviewDueCount: Int = 0
    @Published var trainingSummary: TrainingSummary?
    @Published var isLoading = true

    private let paytableId: String

    init(paytableId: String = PayTable.jacksOrBetter96.id) {
        self.paytableId = paytableId
    }

    func load() async {
        isLoading = true

        async let lessonsTask = TrainingService.shared.loadLessons()
        async let progressTask = TrainingService.shared.getAllProgress()
        async let drillStatsTask = TrainingService.shared.getAllDrillStats()
        async let reviewCountTask = ReviewQueueService.shared.getDueCount(paytableId: paytableId)
        async let summaryTask = TrainingService.shared.getTrainingSummary()

        let (loadedLessons, loadedProgress, loadedDrillStats, loadedReviewCount, loadedSummary) = await (
            lessonsTask, progressTask, drillStatsTask, reviewCountTask, summaryTask
        )

        lessons = loadedLessons
        lessonProgress = loadedProgress
        drills = TrainingService.shared.getAllDrills()
        drillStats = loadedDrillStats
        reviewDueCount = loadedReviewCount
        trainingSummary = loadedSummary

        isLoading = false
    }

    func progressFor(_ lessonId: String) -> LessonProgress {
        lessonProgress[lessonId] ?? LessonProgress.initial(lessonId: lessonId)
    }

    func statsFor(_ drillId: String) -> DrillStats {
        drillStats[drillId] ?? DrillStats.initial(drillId: drillId)
    }

    var completedLessonsCount: Int {
        lessonProgress.values.filter { $0.status == .completed }.count
    }

    var totalLessonsCount: Int {
        lessons.count
    }

    var hasCompletedAllLessons: Bool {
        completedLessonsCount >= totalLessonsCount && totalLessonsCount > 0
    }
}
