import Foundation

class SpacedRepetitionService {
    static let shared = SpacedRepetitionService()

    private init() {}

    /// SM-2 algorithm constants
    private let minEaseFactor: Double = 1.3
    private let defaultEaseFactor: Double = 2.5

    /// Calculate SM-2 update for a mastery score
    func calculateUpdate(score: MasteryScore, wasCorrect: Bool) -> MasteryScore {
        var updated = score

        // Update attempt counts
        updated.totalAttempts += 1
        if wasCorrect {
            updated.correctAttempts += 1
        }

        // Calculate mastery score as percentage correct
        updated.masteryScore = Double(updated.correctAttempts) / Double(updated.totalAttempts) * 100

        // SM-2 quality rating (0-5)
        // 4 = correct, 1 = incorrect
        let quality = wasCorrect ? 4 : 1

        // Update ease factor
        let newEaseFactor = updated.easeFactor + (0.1 - Double(5 - quality) * (0.08 + Double(5 - quality) * 0.02))
        updated.easeFactor = max(minEaseFactor, newEaseFactor)

        // Update interval
        if wasCorrect {
            switch updated.intervalDays {
            case 1:
                updated.intervalDays = 2
            case 2:
                updated.intervalDays = 6
            default:
                updated.intervalDays = Int(Double(updated.intervalDays) * updated.easeFactor)
            }
        } else {
            // Reset interval on wrong answer
            updated.intervalDays = 1
        }

        // Update review dates
        updated.lastReviewedAt = Date()
        updated.nextReviewAt = Calendar.current.date(
            byAdding: .day,
            value: updated.intervalDays,
            to: Date()
        )
        updated.updatedAt = Date()

        return updated
    }

    /// Get categories sorted by priority (due for review first, then by mastery)
    func getCategoriesByPriority(scores: [MasteryScore]) -> [MasteryScore] {
        return scores.sorted { a, b in
            // Due items first
            if a.isDue != b.isDue {
                return a.isDue
            }
            // Then by mastery (lowest first)
            return a.masteryScore < b.masteryScore
        }
    }

    /// Calculate overall mastery percentage
    func calculateOverallMastery(scores: [MasteryScore]) -> Double {
        guard !scores.isEmpty else { return 0 }

        let totalAttempts = scores.reduce(0) { $0 + $1.totalAttempts }
        let correctAttempts = scores.reduce(0) { $0 + $1.correctAttempts }

        guard totalAttempts > 0 else { return 0 }
        return Double(correctAttempts) / Double(totalAttempts) * 100
    }

    /// Get mastery level label
    func getMasteryLevel(percentage: Double) -> String {
        switch percentage {
        case 0..<20: return "Beginner"
        case 20..<40: return "Novice"
        case 40..<60: return "Intermediate"
        case 60..<80: return "Advanced"
        case 80..<95: return "Expert"
        default: return "Master"
        }
    }

    /// Get weak categories (below threshold or never practiced)
    func getWeakCategories(scores: [MasteryScore], threshold: Double = 80) -> [HandCategory] {
        let practiced = Set(scores.compactMap { $0.handCategory })
        let weak = scores.filter { $0.masteryScore < threshold }.compactMap { $0.handCategory }

        // Include unpracticed categories
        let unpracticed = HandCategory.allCases.filter { !practiced.contains($0) }

        return weak + unpracticed
    }
}
