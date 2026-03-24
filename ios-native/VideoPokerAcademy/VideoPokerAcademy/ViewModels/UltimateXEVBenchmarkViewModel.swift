import Foundation

// MARK: - Result Model

struct EVBenchmarkResult {
    let hand: Hand
    let multiplier: Int

    /// Base strategy (M=1): best hold bitmask and EV
    let baseBestHold: Int
    let baseEV: Double

    /// Simplified formula: 2 × base_EV + (M - 1) per hold
    let simplifiedBestHold: Int
    let simplifiedBestEV: Double

    /// Full E[K_awarded] formula: M × 2 × base_EV + E[K] - 1 per hold
    let fullBestHold: Int
    let fullBestEV: Double

    /// Top holds sorted by full EV (for display)
    let topHoldDetails: [HoldDetail]

    /// Elapsed time for full E[K] computation
    let computationTimeMs: Double

    /// Time spent per hold-size bucket (key = number of cards held, 1–5)
    let timingByHoldSize: [Int: Double]

    /// How many bitmasks had E[K] computed (out of 31 possible)
    let evaluatedHoldCount: Int

    /// Whether simplified and full formulas agree on the best hold
    var formulasAgree: Bool { simplifiedBestHold == fullBestHold }

    /// Whether full formula differs from base strategy
    var fullDiffersFromBase: Bool { fullBestHold != baseBestHold }

    struct HoldDetail {
        let bitmask: Int
        let heldIndices: [Int]
        let baseEV: Double
        let eKAwarded: Double
        let simplifiedAdjustedEV: Double
        let fullAdjustedEV: Double
        var isFullBest: Bool
        var isSimplifiedBest: Bool
    }
}

// MARK: - ViewModel

@Observable
@MainActor
final class UltimateXEVBenchmarkViewModel {
    var isRunning = false
    var result: EVBenchmarkResult?
    var errorMessage: String?

    private let paytableId = "jacks-or-better-9-6"
    private let playCount: UltimateXPlayCount = .three

    /// Only compute E[K] for the top-N holds by base EV.
    /// Holds ranked below this threshold are extremely unlikely to become
    /// optimal under the full formula since base_EV is weighted by M×2.
    private let topNHolds = 5

    func runBenchmark() async {
        isRunning = true
        result = nil
        errorMessage = nil

        do {
            result = try await computeBenchmark()
        } catch {
            errorMessage = error.localizedDescription
        }

        isRunning = false
    }

    private func computeBenchmark() async throws -> EVBenchmarkResult {
        // 1. Random hand
        let hand = Hand.deal()

        // 2. Random valid UX multiplier from [1, 2, 3, 4, 7, 11, 12]
        let validMultipliers = UltimateXMultiplierTable.possibleMultipliers(for: playCount)
        guard let multiplier = validMultipliers.randomElement() else {
            throw BenchmarkError.strategyNotAvailable
        }

        // 3. Get base strategy result (all 32 hold EVs)
        guard let baseStrategyResult = try await StrategyService.shared.lookup(
            hand: hand,
            paytableId: paytableId
        ) else {
            throw BenchmarkError.strategyNotAvailable
        }

        // 4. Select top-N bitmasks by base EV (skip bitmask 0 = discard all)
        let candidateBitmasks = baseStrategyResult.holdEvs
            .compactMap { key, value -> (bitmask: Int, ev: Double)? in
                guard let bitmask = Int(key), bitmask != 0 else { return nil }
                return (bitmask: bitmask, ev: value)
            }
            .sorted { $0.ev > $1.ev }
            .prefix(topNHolds)
            .map { $0.bitmask }

        let calculator = HoldOutcomeCalculator()

        // 5. Compute E[K] for each candidate, tracking per-hold-size timing
        let clock = ContinuousClock()
        let start = clock.now
        var holdDetails: [EVBenchmarkResult.HoldDetail] = []
        var timingByHoldSize: [Int: Double] = [:]
        let attosecondsPerMillisecond: Double = 1_000_000_000_000_000

        for bitmask in candidateBitmasks {
            guard let baseEVForHold = baseStrategyResult.holdEvs[String(bitmask)] else { continue }

            let holdSize = bitmask.nonzeroBitCount
            let holdStart = clock.now

            let eK = await calculator.computeEK(
                hand: hand,
                holdBitmask: bitmask,
                paytableId: paytableId,
                playCount: playCount
            )

            let holdElapsed = clock.now - holdStart
            let holdMs = Double(holdElapsed.components.seconds) * 1000.0
                + Double(holdElapsed.components.attoseconds) / attosecondsPerMillisecond
            timingByHoldSize[holdSize, default: 0] += holdMs

            let simplifiedEV = 2.0 * baseEVForHold + Double(multiplier - 1)
            let fullEV = Double(multiplier) * 2.0 * baseEVForHold + eK - 1.0

            holdDetails.append(EVBenchmarkResult.HoldDetail(
                bitmask: bitmask,
                heldIndices: Hand.holdIndicesFromBitmask(bitmask),
                baseEV: baseEVForHold,
                eKAwarded: eK,
                simplifiedAdjustedEV: simplifiedEV,
                fullAdjustedEV: fullEV,
                isFullBest: false,
                isSimplifiedBest: false
            ))
        }

        let elapsed = clock.now - start

        // 6. Find best holds for each formula
        guard let fullBest = holdDetails.max(by: { $0.fullAdjustedEV < $1.fullAdjustedEV }),
              let simplifiedBest = holdDetails.max(by: { $0.simplifiedAdjustedEV < $1.simplifiedAdjustedEV }) else {
            throw BenchmarkError.strategyNotAvailable
        }

        // Mark best holds
        for i in holdDetails.indices {
            holdDetails[i].isFullBest = holdDetails[i].bitmask == fullBest.bitmask
            holdDetails[i].isSimplifiedBest = holdDetails[i].bitmask == simplifiedBest.bitmask
        }

        // 7. Top 5 holds by full EV for display
        let topHolds = Array(holdDetails.sorted { $0.fullAdjustedEV > $1.fullAdjustedEV }.prefix(5))

        // 8. Total time in milliseconds
        let timeMs = Double(elapsed.components.seconds) * 1000.0
            + Double(elapsed.components.attoseconds) / attosecondsPerMillisecond

        return EVBenchmarkResult(
            hand: hand,
            multiplier: multiplier,
            baseBestHold: baseStrategyResult.bestHold,
            baseEV: baseStrategyResult.bestEv,
            simplifiedBestHold: simplifiedBest.bitmask,
            simplifiedBestEV: simplifiedBest.simplifiedAdjustedEV,
            fullBestHold: fullBest.bitmask,
            fullBestEV: fullBest.fullAdjustedEV,
            topHoldDetails: topHolds,
            computationTimeMs: timeMs,
            timingByHoldSize: timingByHoldSize,
            evaluatedHoldCount: candidateBitmasks.count
        )
    }
}

// MARK: - Errors

enum BenchmarkError: LocalizedError {
    case strategyNotAvailable

    var errorDescription: String? {
        switch self {
        case .strategyNotAvailable:
            return "Strategy data not available. Download Jacks or Better 9/6 first."
        }
    }
}
