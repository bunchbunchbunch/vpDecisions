import Foundation

struct MasteryScore: Codable, Identifiable {
    var id: UUID?
    let userId: UUID
    let paytableId: String
    let category: String
    var easeFactor: Double
    var intervalDays: Int
    var totalAttempts: Int
    var correctAttempts: Int
    var masteryScore: Double
    var lastReviewedAt: Date?
    var nextReviewAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case paytableId = "paytable_id"
        case category
        case easeFactor = "ease_factor"
        case intervalDays = "interval_days"
        case totalAttempts = "total_attempts"
        case correctAttempts = "correct_attempts"
        case masteryScore = "mastery_score"
        case lastReviewedAt = "last_reviewed_at"
        case nextReviewAt = "next_review_at"
        case updatedAt = "updated_at"
    }

    var handCategory: HandCategory? {
        HandCategory(rawValue: category)
    }

    var isDue: Bool {
        guard let nextReview = nextReviewAt else { return true }
        return nextReview <= Date()
    }

    var accuracy: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(correctAttempts) / Double(totalAttempts) * 100
    }

    static func defaultScore(userId: UUID, paytableId: String, category: HandCategory) -> MasteryScore {
        MasteryScore(
            id: nil,
            userId: userId,
            paytableId: paytableId,
            category: category.rawValue,
            easeFactor: 2.5,
            intervalDays: 1,
            totalAttempts: 0,
            correctAttempts: 0,
            masteryScore: 0,
            lastReviewedAt: nil,
            nextReviewAt: nil,
            updatedAt: nil
        )
    }
}

// MARK: - Hand Attempt (for logging to Supabase)
struct HandAttempt: Codable {
    let userId: UUID
    let handKey: String
    let handCategory: String
    let paytableId: String
    let userHold: [Int]
    let optimalHold: [Int]
    let isCorrect: Bool
    let evDifference: Double
    let responseTimeMs: Int?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case handKey = "hand_key"
        case handCategory = "hand_category"
        case paytableId = "paytable_id"
        case userHold = "user_hold"
        case optimalHold = "optimal_hold"
        case isCorrect = "is_correct"
        case evDifference = "ev_difference"
        case responseTimeMs = "response_time_ms"
    }
}

// MARK: - Strategy Result (from Supabase lookup)
struct StrategyResult: Codable {
    let bestHold: Int
    let bestEv: Double
    let holdEvs: [String: Double]

    enum CodingKeys: String, CodingKey {
        case bestHold = "best_hold"
        case bestEv = "best_ev"
        case holdEvs = "hold_evs"
    }

    var bestHoldIndices: [Int] {
        Hand.holdIndicesFromBitmask(bestHold)
    }

    /// Get all hold options sorted by EV (highest first)
    var sortedHoldOptions: [(bitmask: Int, ev: Double, indices: [Int])] {
        holdEvs.compactMap { key, ev in
            guard let bitmask = Int(key) else { return nil }
            return (bitmask: bitmask, ev: ev, indices: Hand.holdIndicesFromBitmask(bitmask))
        }.sorted { $0.ev > $1.ev }
    }
}

// MARK: - User Profile
struct UserProfile: Codable {
    let id: UUID
    let email: String?
    let fullName: String?
    let avatarUrl: String?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case updatedAt = "updated_at"
    }
}
