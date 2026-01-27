import Foundation

// MARK: - Drill Model

struct Drill: Identifiable {
    let id: String                    // "high-pair-vs-4flush"
    let title: String                 // "High Pair vs 4-Flush"
    let description: String
    let categories: [HandCategory]    // Categories to filter for
    let handsPerSession: Int          // 10

    var iconName: String {
        switch id {
        case "high-pair-vs-4flush": return "suit.diamond.fill"
        case "low-pair-vs-4straight": return "arrow.left.arrow.right"
        case "3royal-vs-made": return "crown.fill"
        case "high-cards-basics": return "textformat"
        case "garbage-hands": return "trash.fill"
        default: return "questionmark.circle"
        }
    }
}

// MARK: - Drill Session

struct DrillSession: Identifiable {
    let id: UUID
    let drillId: String
    let paytableId: String
    let startedAt: Date
    var hands: [DrillHand]
    var currentIndex: Int
    var correctCount: Int
    var totalEvLost: Double
    var completedAt: Date?

    var isComplete: Bool {
        currentIndex >= hands.count
    }

    var handsCompleted: Int {
        min(currentIndex, hands.count)
    }

    var accuracy: Double {
        guard handsCompleted > 0 else { return 0 }
        return Double(correctCount) / Double(handsCompleted) * 100
    }

    static func start(drillId: String, paytableId: String, hands: [DrillHand]) -> DrillSession {
        DrillSession(
            id: UUID(),
            drillId: drillId,
            paytableId: paytableId,
            startedAt: Date(),
            hands: hands,
            currentIndex: 0,
            correctCount: 0,
            totalEvLost: 0,
            completedAt: nil
        )
    }
}

// MARK: - Drill Hand

struct DrillHand: Identifiable {
    let id: UUID
    let hand: Hand
    let strategyResult: StrategyResult
    let category: HandCategory
    var userHold: [Int]?
    var isCorrect: Bool?
    var evLost: Double?

    static func create(hand: Hand, strategyResult: StrategyResult, category: HandCategory) -> DrillHand {
        DrillHand(
            id: UUID(),
            hand: hand,
            strategyResult: strategyResult,
            category: category,
            userHold: nil,
            isCorrect: nil,
            evLost: nil
        )
    }
}

// MARK: - Drill Stats (persistent per-drill stats)

struct DrillStats: Codable, Identifiable {
    var id: String { drillId }
    let drillId: String
    var totalSessions: Int
    var totalHands: Int
    var correctHands: Int
    var totalEvLost: Double
    var bestStreak: Int
    var currentStreak: Int
    var lastPlayedAt: Date?

    enum CodingKeys: String, CodingKey {
        case drillId = "drill_id"
        case totalSessions = "total_sessions"
        case totalHands = "total_hands"
        case correctHands = "correct_hands"
        case totalEvLost = "total_ev_lost"
        case bestStreak = "best_streak"
        case currentStreak = "current_streak"
        case lastPlayedAt = "last_played_at"
    }

    var accuracy: Double {
        guard totalHands > 0 else { return 0 }
        return Double(correctHands) / Double(totalHands) * 100
    }

    static func initial(drillId: String) -> DrillStats {
        DrillStats(
            drillId: drillId,
            totalSessions: 0,
            totalHands: 0,
            correctHands: 0,
            totalEvLost: 0,
            bestStreak: 0,
            currentStreak: 0,
            lastPlayedAt: nil
        )
    }

    mutating func recordSession(correct: Int, total: Int, evLost: Double) {
        totalSessions += 1
        totalHands += total
        correctHands += correct
        totalEvLost += evLost
        lastPlayedAt = Date()

        // Update streak
        if correct == total {
            currentStreak += 1
            if currentStreak > bestStreak {
                bestStreak = currentStreak
            }
        } else {
            currentStreak = 0
        }
    }
}

// MARK: - Predefined Drills

extension Drill {
    static let allDrills: [Drill] = [
        Drill(
            id: "high-pair-vs-4flush",
            title: "High Pair vs 4-Flush",
            description: "Practice the classic dilemma: keep a high pair or draw to a flush?",
            categories: [.highPairs, .fourToFlush],
            handsPerSession: 10
        ),
        Drill(
            id: "low-pair-vs-4straight",
            title: "Low Pair vs 4-Straight",
            description: "When to keep a low pair versus drawing to a straight.",
            categories: [.lowPairs, .openEndedStraight, .insideStraight],
            handsPerSession: 10
        ),
        Drill(
            id: "3royal-vs-made",
            title: "3-Royal vs Made Hand",
            description: "Should you break a made hand to draw for a royal flush?",
            categories: [.threeToRoyal, .madeHands],
            handsPerSession: 10
        ),
        Drill(
            id: "high-cards-basics",
            title: "High Card Holds",
            description: "Master holding the right high cards when you have nothing else.",
            categories: [.highCards],
            handsPerSession: 10
        ),
        Drill(
            id: "garbage-hands",
            title: "Garbage Hand Triage",
            description: "Learn when to discard everything versus holding a single card.",
            categories: [.discardAll, .mixedDecisions],
            handsPerSession: 10
        )
    ]

    static func drill(for id: String) -> Drill? {
        allDrills.first { $0.id == id }
    }
}
