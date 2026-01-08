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

    /// Get all bitmasks that are tied for best EV (within floating point tolerance)
    /// Uses chain comparison (each consecutive pair) to match rankForOption behavior
    var tiedForBestBitmasks: [Int] {
        let sorted = sortedHoldOptions
        guard !sorted.isEmpty else { return [] }

        let tolerance = 0.0001
        var tiedBitmasks: [Int] = [sorted[0].bitmask]
        var previousEv = sorted[0].ev

        // Use chain comparison: each option is tied if within tolerance of the previous
        for i in 1..<sorted.count {
            if abs(sorted[i].ev - previousEv) < tolerance {
                tiedBitmasks.append(sorted[i].bitmask)
                previousEv = sorted[i].ev
            } else {
                break  // Once we find a gap, stop adding to tied list
            }
        }

        return tiedBitmasks
    }

    /// Check if a given hold (in canonical order) is tied for best
    func isHoldTiedForBest(_ canonicalIndices: [Int]) -> Bool {
        let userBitmask = Hand.bitmaskFromHoldIndices(canonicalIndices)
        return tiedForBestBitmasks.contains(userBitmask)
    }

    /// Get the rank for a hold option at a given index, accounting for ties
    /// Returns the rank number (1-based) where tied EVs share the same rank
    func rankForOption(at index: Int) -> Int {
        let sorted = sortedHoldOptions
        guard index < sorted.count else { return index + 1 }

        let tolerance = 0.0001
        var rank = 1
        var previousEv: Double? = nil

        for i in 0...index {
            if let prevEv = previousEv {
                // Only increment rank if EV is meaningfully different
                if abs(sorted[i].ev - prevEv) >= tolerance {
                    rank = i + 1
                }
            }
            previousEv = sorted[i].ev
        }

        return rank
    }

    /// Get hold options sorted by EV, with user's selection prioritized among ties
    /// - Parameter userCanonicalIndices: The user's hold indices in canonical order
    /// - Returns: Sorted options with user's selection first among any tied EVs
    func sortedHoldOptionsPrioritizingUser(_ userCanonicalIndices: [Int]) -> [(bitmask: Int, ev: Double, indices: [Int])] {
        let tolerance = 0.0001
        let userIndicesSorted = userCanonicalIndices.sorted()

        return sortedHoldOptions.sorted { a, b in
            // First sort by EV (descending)
            if abs(a.ev - b.ev) >= tolerance {
                return a.ev > b.ev
            }
            // If EVs are tied, prioritize user's selection
            let aIsUserSelection = a.indices.sorted() == userIndicesSorted
            let bIsUserSelection = b.indices.sorted() == userIndicesSorted
            if aIsUserSelection != bIsUserSelection {
                return aIsUserSelection
            }
            // Otherwise maintain original order
            return false
        }
    }

    /// Get the rank for a hold option at a given index in a user-prioritized list
    func rankForOption(at index: Int, inUserPrioritizedList options: [(bitmask: Int, ev: Double, indices: [Int])]) -> Int {
        guard index < options.count else { return index + 1 }

        let tolerance = 0.0001
        var rank = 1
        var previousEv: Double? = nil

        for i in 0...index {
            if let prevEv = previousEv {
                if abs(options[i].ev - prevEv) >= tolerance {
                    rank = i + 1
                }
            }
            previousEv = options[i].ev
        }

        return rank
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
