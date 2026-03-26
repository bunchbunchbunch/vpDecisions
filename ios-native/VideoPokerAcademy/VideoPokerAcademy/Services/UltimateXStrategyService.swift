import Foundation

/// Service for calculating Ultimate X strategy with multiplier adjustments
///
/// Ultimate X strategy differs from base game strategy because the current multiplier
/// affects the EV of each hold option. The adjustment formula is:
///
///     Adjusted EV = multiplier × 2 × (Base EV) + E[K_awarded] - 1.0
///
/// The "2" coefficient accounts for the 2-coin-per-line bet cost in Ultimate X.
/// "multiplier" is the current active multiplier on this hand.
/// "E[K_awarded]" is the expected next-hand multiplier awarded by this hold,
/// computed via HoldOutcomeCalculator by enumerating all draw outcomes.
/// "-1.0" normalizes to net EV per coin-equivalent.
actor UltimateXStrategyService {
    static let shared = UltimateXStrategyService()

    private init() {}

    /// Calculate the optimal Ultimate X strategy for a hand with a given multiplier
    /// - Parameters:
    ///   - hand: The 5-card hand to analyze
    ///   - paytableId: The paytable to use for base EV calculations
    ///   - currentMultiplier: The current multiplier (1-12, where 1 = no multiplier)
    ///   - playCount: The Ultimate X play configuration (3, 5, or 10)
    /// - Returns: The Ultimate X strategy result with adjusted EVs
    func lookup(
        hand: Hand,
        paytableId: String,
        currentMultiplier: Double,
        playCount: UltimateXPlayCount
    ) async throws -> UltimateXStrategyResult? {
        guard let baseResult = try await StrategyService.shared.lookup(
            hand: hand,
            paytableId: paytableId
        ) else {
            return nil
        }

        let calculator = HoldOutcomeCalculator()
        var adjustedHoldEvs: [String: Double] = [:]
        var holdEKs: [String: Double] = [:]
        var bestAdjustedHold = 0
        var bestAdjustedEv = -Double.infinity

        for (key, baseEv) in baseResult.holdEvs {
            guard let bitmask = Int(key) else { continue }
            let eK = await calculator.computeEK(
                hand: hand,
                holdBitmask: bitmask,
                paytableId: paytableId,
                playCount: playCount
            )
            let adjustedEv = currentMultiplier * 2.0 * baseEv + eK - 1.0
            adjustedHoldEvs[key] = adjustedEv
            holdEKs[key] = eK

            if adjustedEv > bestAdjustedEv {
                bestAdjustedEv = adjustedEv
                bestAdjustedHold = bitmask
            }
        }

        return UltimateXStrategyResult(
            baseResult: baseResult,
            currentMultiplier: currentMultiplier,
            playCount: playCount,
            adjustedBestHold: bestAdjustedHold,
            adjustedBestEv: bestAdjustedEv,
            adjustedHoldEvs: adjustedHoldEvs,
            holdEKs: holdEKs
        )
    }

    /// Check if the strategy differs between base game and Ultimate X at a given multiplier
    /// This is useful for identifying "transitional" hands where multipliers matter
    func doesStrategyDiffer(
        hand: Hand,
        paytableId: String,
        currentMultiplier: Double,
        playCount: UltimateXPlayCount
    ) async throws -> Bool {
        guard let result = try await lookup(
            hand: hand,
            paytableId: paytableId,
            currentMultiplier: currentMultiplier,
            playCount: playCount
        ) else {
            return false
        }
        return result.strategyDiffers
    }

    /// Find the multiplier threshold where strategy changes for a hand
    /// Returns nil if strategy never changes (rare)
    func findStrategyChangeThreshold(
        hand: Hand,
        paytableId: String,
        playCount: UltimateXPlayCount
    ) async throws -> Int? {
        // Get base strategy
        guard let baseResult = try await StrategyService.shared.lookup(
            hand: hand,
            paytableId: paytableId
        ) else {
            return nil
        }

        // Check each multiplier level from 2 to 12
        for multiplier in 2...UltimateXMultiplierTable.maxMultiplier {
            if let result = try await lookup(
                hand: hand,
                paytableId: paytableId,
                currentMultiplier: Double(multiplier),
                playCount: playCount
            ) {
                if result.adjustedBestHold != baseResult.bestHold {
                    return multiplier
                }
            }
        }

        return nil // Strategy never changes for this hand
    }
}
