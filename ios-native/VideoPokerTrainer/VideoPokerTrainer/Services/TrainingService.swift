import Foundation

// MARK: - Training Service

actor TrainingService {
    static let shared = TrainingService()

    private var lessonsCache: [Lesson]?
    private var progressCache: [String: LessonProgress] = [:]
    private var drillStatsCache: [String: DrillStats] = [:]

    private init() {}

    // MARK: - Lessons

    /// Load all lessons from bundled JSON files
    func loadLessons() async -> [Lesson] {
        if let cached = lessonsCache {
            return cached
        }

        var lessons: [Lesson] = []

        let lessonFiles = [
            "job-made-hands",
            "job-high-cards",
            "job-penalty-cards"
        ]

        for filename in lessonFiles {
            if let lesson = loadLesson(from: filename) {
                lessons.append(lesson)
            }
        }

        lessons.sort { $0.order < $1.order }
        lessonsCache = lessons
        return lessons
    }

    /// Load a single lesson from a JSON file
    private func loadLesson(from filename: String) -> Lesson? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Lessons") else {
            print("TrainingService: Could not find lesson file: \(filename).json")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let lesson = try JSONDecoder().decode(Lesson.self, from: data)
            return lesson
        } catch {
            print("TrainingService: Failed to decode lesson \(filename): \(error)")
            return nil
        }
    }

    /// Get a specific lesson by ID
    func lesson(for id: String) async -> Lesson? {
        let lessons = await loadLessons()
        return lessons.first { $0.id == id }
    }

    // MARK: - Lesson Progress

    /// Get progress for all lessons
    func getAllProgress() async -> [String: LessonProgress] {
        if !progressCache.isEmpty {
            return progressCache
        }

        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "lesson_progress"),
           let progress = try? JSONDecoder().decode([String: LessonProgress].self, from: data) {
            progressCache = progress
            return progress
        }

        return [:]
    }

    /// Get progress for a specific lesson
    func progress(for lessonId: String) async -> LessonProgress {
        let allProgress = await getAllProgress()
        return allProgress[lessonId] ?? LessonProgress.initial(lessonId: lessonId)
    }

    /// Update progress for a lesson
    func updateProgress(_ progress: LessonProgress) async {
        progressCache[progress.lessonId] = progress

        // Save to UserDefaults
        if let data = try? JSONEncoder().encode(progressCache) {
            UserDefaults.standard.set(data, forKey: "lesson_progress")
        }
    }

    /// Record a quiz attempt
    func recordQuizAttempt(lessonId: String, score: Int, passed: Bool) async {
        var progress = await progress(for: lessonId)
        progress.attempts += 1
        progress.lastAttemptAt = Date()

        if score > progress.bestScore {
            progress.bestScore = score
        }

        if passed && progress.status != .completed {
            progress.status = .completed
            progress.completedAt = Date()
        } else if progress.status == .notStarted {
            progress.status = .inProgress
        }

        await updateProgress(progress)
    }

    // MARK: - Drills

    /// Get all available drills
    nonisolated func getAllDrills() -> [Drill] {
        Drill.allDrills
    }

    /// Get a specific drill by ID
    nonisolated func drill(for id: String) -> Drill? {
        Drill.drill(for: id)
    }

    // MARK: - Drill Stats

    /// Get stats for all drills
    func getAllDrillStats() async -> [String: DrillStats] {
        if !drillStatsCache.isEmpty {
            return drillStatsCache
        }

        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "drill_stats"),
           let stats = try? JSONDecoder().decode([String: DrillStats].self, from: data) {
            drillStatsCache = stats
            return stats
        }

        return [:]
    }

    /// Get stats for a specific drill
    func stats(for drillId: String) async -> DrillStats {
        let allStats = await getAllDrillStats()
        return allStats[drillId] ?? DrillStats.initial(drillId: drillId)
    }

    /// Update stats for a drill
    func updateStats(_ stats: DrillStats) async {
        drillStatsCache[stats.drillId] = stats

        // Save to UserDefaults
        if let data = try? JSONEncoder().encode(drillStatsCache) {
            UserDefaults.standard.set(data, forKey: "drill_stats")
        }
    }

    /// Record a completed drill session
    func recordDrillSession(drillId: String, correct: Int, total: Int, evLost: Double) async {
        var stats = await stats(for: drillId)
        stats.recordSession(correct: correct, total: total, evLost: evLost)
        await updateStats(stats)
    }

    // MARK: - Generate Drill Hands

    /// Generate hands for a drill session by filtering for specific categories
    func generateDrillHands(drill: Drill, paytableId: String, count: Int) async -> [DrillHand] {
        var hands: [DrillHand] = []
        var attempts = 0
        let maxAttempts = count * 20  // Limit attempts to avoid infinite loop

        while hands.count < count && attempts < maxAttempts {
            attempts += 1

            // Deal a random hand
            let hand = Hand.deal()

            // Look up strategy
            guard let strategyResult = try? await StrategyService.shared.lookup(hand: hand, paytableId: paytableId) else {
                continue
            }

            // Get the category of the optimal hold
            let optimalHoldIndices = hand.canonicalIndicesToOriginal(strategyResult.bestHoldIndices)
            let category = HandCategory.categorize(hand: hand, holdIndices: optimalHoldIndices)

            // Check if this category matches the drill's target categories
            if drill.categories.contains(category) {
                let drillHand = DrillHand.create(
                    hand: hand,
                    strategyResult: strategyResult,
                    category: category
                )
                hands.append(drillHand)
            }
        }

        return hands
    }

    // MARK: - Training Summary

    /// Get overall training progress summary
    func getTrainingSummary() async -> TrainingSummary {
        let lessons = await loadLessons()
        let allProgress = await getAllProgress()
        let allDrillStats = await getAllDrillStats()

        let completedLessons = allProgress.values.filter { $0.status == .completed }.count
        let totalDrillSessions = allDrillStats.values.reduce(0) { $0 + $1.totalSessions }
        let totalDrillHands = allDrillStats.values.reduce(0) { $0 + $1.totalHands }
        let drillAccuracy = allDrillStats.values.reduce(0.0) { total, stats in
            guard stats.totalHands > 0 else { return total }
            return total + stats.accuracy
        } / max(1, Double(allDrillStats.count))

        return TrainingSummary(
            totalLessons: lessons.count,
            completedLessons: completedLessons,
            totalDrillSessions: totalDrillSessions,
            totalDrillHands: totalDrillHands,
            drillAccuracy: drillAccuracy
        )
    }
}

// MARK: - Training Summary

struct TrainingSummary {
    let totalLessons: Int
    let completedLessons: Int
    let totalDrillSessions: Int
    let totalDrillHands: Int
    let drillAccuracy: Double

    var lessonsProgress: Double {
        guard totalLessons > 0 else { return 0 }
        return Double(completedLessons) / Double(totalLessons) * 100
    }
}
