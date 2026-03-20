import Foundation

// MARK: - Review Item (for spaced repetition review queue)

struct ReviewItem: Identifiable, Codable {
    let id: UUID
    let handKey: String               // Canonical key from HandAttempt
    let cards: [String]               // Card strings for display
    let handCategory: String          // Category raw value
    let paytableId: String
    let correctHold: [Int]            // Optimal hold indices
    var mistakeCount: Int             // Aggregated from attempts
    var totalEvLost: Double           // Sum of ev_difference
    var easeFactor: Double            // SM-2 ease factor (starts at 2.5)
    var intervalDays: Int             // SM-2 interval
    var nextReviewAt: Date?           // When to review next
    var lastReviewedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case handKey = "hand_key"
        case cards
        case handCategory = "hand_category"
        case paytableId = "paytable_id"
        case correctHold = "correct_hold"
        case mistakeCount = "mistake_count"
        case totalEvLost = "total_ev_lost"
        case easeFactor = "ease_factor"
        case intervalDays = "interval_days"
        case nextReviewAt = "next_review_at"
        case lastReviewedAt = "last_reviewed_at"
    }

    var category: HandCategory? {
        HandCategory(rawValue: handCategory)
    }

    /// Priority score for sorting (higher = more urgent to review)
    var priorityScore: Double {
        Double(mistakeCount) * totalEvLost
    }

    /// Whether this item is due for review
    var isDue: Bool {
        guard let nextReview = nextReviewAt else { return true }
        return nextReview <= Date()
    }

    /// Convert card strings to Card objects
    func getCards() -> [Card]? {
        guard cards.count == 5 else { return nil }
        return cards.compactMap { Card(from: $0) }
    }

    /// Create a review item from aggregated mistake data
    static func create(
        handKey: String,
        cards: [String],
        category: String,
        paytableId: String,
        correctHold: [Int],
        mistakeCount: Int,
        totalEvLost: Double
    ) -> ReviewItem {
        ReviewItem(
            id: UUID(),
            handKey: handKey,
            cards: cards,
            handCategory: category,
            paytableId: paytableId,
            correctHold: correctHold,
            mistakeCount: mistakeCount,
            totalEvLost: totalEvLost,
            easeFactor: 2.5,
            intervalDays: 1,
            nextReviewAt: nil,
            lastReviewedAt: nil
        )
    }

    // MARK: - SM-2 Algorithm Update

    /// Update spaced repetition state after a review
    /// - Parameter quality: 0-5 rating (0-2 = wrong, 3 = hard, 4 = good, 5 = easy)
    mutating func updateSM2(quality: Int) {
        let q = max(0, min(5, quality))

        // Update ease factor
        let efDelta = 0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02)
        easeFactor = max(1.3, easeFactor + efDelta)

        // Update interval
        if q < 3 {
            // Failed - reset interval
            intervalDays = 1
        } else {
            // Passed
            switch intervalDays {
            case 1:
                intervalDays = 6
            default:
                intervalDays = Int(Double(intervalDays) * easeFactor)
            }
        }

        // Update review dates
        lastReviewedAt = Date()
        nextReviewAt = Calendar.current.date(byAdding: .day, value: intervalDays, to: Date())
    }
}

// MARK: - Review Session

struct ReviewSession: Identifiable {
    let id: UUID
    let paytableId: String
    let startedAt: Date
    var items: [ReviewItem]
    var currentIndex: Int
    var correctCount: Int
    var completedAt: Date?

    var isComplete: Bool {
        currentIndex >= items.count
    }

    var itemsCompleted: Int {
        min(currentIndex, items.count)
    }

    var accuracy: Double {
        guard itemsCompleted > 0 else { return 0 }
        return Double(correctCount) / Double(itemsCompleted) * 100
    }

    static func start(paytableId: String, items: [ReviewItem]) -> ReviewSession {
        ReviewSession(
            id: UUID(),
            paytableId: paytableId,
            startedAt: Date(),
            items: items,
            currentIndex: 0,
            correctCount: 0,
            completedAt: nil
        )
    }
}

// MARK: - Review Stats

struct ReviewStats: Codable {
    var totalReviews: Int
    var correctReviews: Int
    var itemsInQueue: Int
    var itemsMastered: Int  // Items with intervalDays > 30
    var lastReviewDate: Date?

    enum CodingKeys: String, CodingKey {
        case totalReviews = "total_reviews"
        case correctReviews = "correct_reviews"
        case itemsInQueue = "items_in_queue"
        case itemsMastered = "items_mastered"
        case lastReviewDate = "last_review_date"
    }

    var accuracy: Double {
        guard totalReviews > 0 else { return 0 }
        return Double(correctReviews) / Double(totalReviews) * 100
    }

    static var empty: ReviewStats {
        ReviewStats(
            totalReviews: 0,
            correctReviews: 0,
            itemsInQueue: 0,
            itemsMastered: 0,
            lastReviewDate: nil
        )
    }
}
