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

        let calculator = HoldOutcomeCalculator()

        // 4. Measure full E[K] computation time across all non-zero bitmasks
        // Use timestamp approach to avoid @Sendable closure capture issues with Swift 6
        let clock = ContinuousClock()
        let start = clock.now
        var holdDetails: [EVBenchmarkResult.HoldDetail] = []

        // Bitmask 0 (discard all) is excluded — HoldOutcomeCalculator skips it for
        // performance (C(47,5) = 1.5M combos) and it is never the optimal hold.
        for bitmask in 1...31 {
            guard let baseEVForHold = baseStrategyResult.holdEvs[String(bitmask)] else {
                continue
            }
            let eK = await calculator.computeEK(
                hand: hand,
                holdBitmask: bitmask,
                paytableId: paytableId,
                playCount: playCount
            )
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

        // 5. Find best holds for each formula
        guard let fullBest = holdDetails.max(by: { $0.fullAdjustedEV < $1.fullAdjustedEV }),
              let simplifiedBest = holdDetails.max(by: { $0.simplifiedAdjustedEV < $1.simplifiedAdjustedEV }) else {
            throw BenchmarkError.strategyNotAvailable
        }

        // Mark best holds
        for i in holdDetails.indices {
            holdDetails[i].isFullBest = holdDetails[i].bitmask == fullBest.bitmask
            holdDetails[i].isSimplifiedBest = holdDetails[i].bitmask == simplifiedBest.bitmask
        }

        // 6. Top 5 holds by full EV for display
        let topHolds = Array(holdDetails.sorted { $0.fullAdjustedEV > $1.fullAdjustedEV }.prefix(5))

        // 7. Compute time in milliseconds
        let attosecondsPerMillisecond: Double = 1_000_000_000_000_000
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
            computationTimeMs: timeMs
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
