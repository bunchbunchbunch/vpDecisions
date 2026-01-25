import Foundation

// MARK: - Simulation Configuration

struct SimulationConfig {
    var paytableId: String
    var denomination: BetDenomination
    var linesPerHand: Int
    var handsPerSimulation: Int
    var numberOfSimulations: Int

    static let `default` = SimulationConfig(
        paytableId: PayTable.jacksOrBetter96.id,
        denomination: .quarter,
        linesPerHand: 10,
        handsPerSimulation: 1000,
        numberOfSimulations: 100
    )

    /// Total number of individual hands that will be simulated
    var totalHands: Int {
        handsPerSimulation * numberOfSimulations * linesPerHand
    }

    /// Total amount that will be wagered
    var totalWagered: Double {
        let betPerHand = Double(5 * linesPerHand) * denomination.rawValue
        return betPerHand * Double(handsPerSimulation * numberOfSimulations)
    }
}

// MARK: - Simulation Run

struct SimulationRun: Identifiable {
    let id = UUID()
    let runNumber: Int
    var handsPlayed: Int = 0
    var totalBet: Double = 0
    var totalWon: Double = 0
    var biggestWin: Double = 0
    var biggestLoss: Double = 0
    var winsOver2000: Int = 0  // W2G taxable wins
    var bankrollHistory: [Double] = []
    var winsByHandType: [String: Int] = [:]

    var netResult: Double {
        totalWon - totalBet
    }

    var rtp: Double {
        guard totalBet > 0 else { return 0 }
        return (totalWon / totalBet) * 100
    }
}

// MARK: - Simulation Results

struct SimulationResults {
    let config: SimulationConfig
    var runs: [SimulationRun]
    var isComplete: Bool
    var isCancelled: Bool

    // Aggregate stats across all runs
    var overallTotalBet: Double {
        runs.reduce(0) { $0 + $1.totalBet }
    }

    var overallTotalWon: Double {
        runs.reduce(0) { $0 + $1.totalWon }
    }

    var overallNetResult: Double {
        overallTotalWon - overallTotalBet
    }

    var overallRTP: Double {
        guard overallTotalBet > 0 else { return 0 }
        return (overallTotalWon / overallTotalBet) * 100
    }

    var avgNetResult: Double {
        guard !runs.isEmpty else { return 0 }
        return overallNetResult / Double(runs.count)
    }

    var bestRun: SimulationRun? {
        runs.max(by: { $0.netResult < $1.netResult })
    }

    var worstRun: SimulationRun? {
        runs.min(by: { $0.netResult < $1.netResult })
    }

    var biggestWin: Double {
        runs.map { $0.biggestWin }.max() ?? 0
    }

    var biggestLoss: Double {
        runs.map { $0.biggestLoss }.min() ?? 0
    }

    var rtpDistribution: [Double] {
        runs.map { $0.rtp }
    }

    var totalHandsPlayed: Int {
        runs.reduce(0) { $0 + $1.handsPlayed }
    }

    var totalWins: Int {
        runs.reduce(0) { total, run in
            total + run.winsByHandType.values.reduce(0, +)
        }
    }

    var totalWinsOver2000: Int {
        runs.reduce(0) { $0 + $1.winsOver2000 }
    }

    var aggregatedWinsByHandType: [String: Int] {
        var result: [String: Int] = [:]
        for run in runs {
            for (handType, count) in run.winsByHandType {
                result[handType, default: 0] += count
            }
        }
        return result
    }
}

// MARK: - Simulation Phase

enum SimulationPhase: Equatable {
    case configuration
    case running
    case results
}

// MARK: - Simulation Progress

struct SimulationProgress {
    var currentRun: Int = 0
    var totalRuns: Int = 0
    var currentHand: Int = 0
    var handsPerRun: Int = 0
    var startTime: Date?
    var statusMessage: String?

    var overallProgress: Double {
        guard totalRuns > 0, handsPerRun > 0 else { return 0 }
        let completedHands = (currentRun * handsPerRun) + currentHand
        let totalHands = totalRuns * handsPerRun
        return Double(completedHands) / Double(totalHands)
    }

    var elapsedTime: TimeInterval {
        guard let start = startTime else { return 0 }
        return Date().timeIntervalSince(start)
    }

    var estimatedRemainingTime: TimeInterval {
        guard overallProgress > 0 else { return 0 }
        let elapsed = elapsedTime
        let totalEstimated = elapsed / overallProgress
        return totalEstimated - elapsed
    }
}

// MARK: - Single Hand Result

struct SingleHandResult {
    let handName: String?
    let payout: Int  // In credits
}

// MARK: - Hands Per Simulation Options

enum HandsPerSimulation: Int, CaseIterable {
    case oneHundred = 100
    case fiveHundred = 500
    case oneThousand = 1000
    case fiveThousand = 5000

    var displayName: String {
        switch self {
        case .oneHundred: return "100"
        case .fiveHundred: return "500"
        case .oneThousand: return "1,000"
        case .fiveThousand: return "5,000"
        }
    }
}

// MARK: - Number of Simulations Options

enum NumberOfSimulations: Int, CaseIterable {
    case one = 1
    case ten = 10
    case fifty = 50
    case oneHundred = 100

    var displayName: String {
        switch self {
        case .one: return "1"
        case .ten: return "10"
        case .fifty: return "50"
        case .oneHundred: return "100"
        }
    }
}
