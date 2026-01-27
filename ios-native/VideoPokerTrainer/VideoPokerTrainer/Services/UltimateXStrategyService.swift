import Foundation

/// Service for calculating Ultimate X strategy with multiplier adjustments
///
/// Ultimate X strategy differs from base game strategy because the current multiplier
/// affects the EV of each hold option. The adjustment formula is:
///
///     Adjusted EV = 2 × (Base EV) + (Multiplier - 1)
///
/// The "2" coefficient approximates the average multiplier you'll earn on winning hands,
/// and "(Multiplier - 1)" represents the additional value from the current multiplier.
///
/// When the multiplier is 1 (no multiplier active), the strategy is the same as base game.
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
        currentMultiplier: Int,
        playCount: UltimateXPlayCount
    ) async throws -> UltimateXStrategyResult? {
        // Get the base strategy result
        guard let baseResult = try await StrategyService.shared.lookup(
            hand: hand,
            paytableId: paytableId
        ) else {
            return nil
        }

        // If multiplier is 1, the strategy is the same as base game
        // But we still need to return the adjusted structure for consistency
        if currentMultiplier == 1 {
            return UltimateXStrategyResult(
                baseResult: baseResult,
                currentMultiplier: 1,
                playCount: playCount,
                adjustedBestHold: baseResult.bestHold,
                adjustedBestEv: baseResult.bestEv,
                adjustedHoldEvs: baseResult.holdEvs
            )
        }

        // Calculate adjusted EVs for all hold options
        var adjustedHoldEvs: [String: Double] = [:]
        var bestAdjustedHold = 0
        var bestAdjustedEv = -Double.infinity

        for (key, baseEv) in baseResult.holdEvs {
            // Apply the Ultimate X adjustment formula:
            // Adjusted EV = 2 × (Base EV) + (Multiplier - 1)
            //
            // Explanation:
            // - Base EV already accounts for the probability-weighted payouts
            // - The "2×" factor represents that winning hands generate multipliers
            //   averaging around 2x for future hands
            // - "(Multiplier - 1)" represents the extra value from the current
            //   multiplier beyond the base 1x payout
            let adjustedEv = calculateAdjustedEv(baseEv: baseEv, multiplier: currentMultiplier)
            adjustedHoldEvs[key] = adjustedEv

            if adjustedEv > bestAdjustedEv {
                bestAdjustedEv = adjustedEv
                if let bitmask = Int(key) {
                    bestAdjustedHold = bitmask
                }
            }
        }

        return UltimateXStrategyResult(
            baseResult: baseResult,
            currentMultiplier: currentMultiplier,
            playCount: playCount,
            adjustedBestHold: bestAdjustedHold,
            adjustedBestEv: bestAdjustedEv,
            adjustedHoldEvs: adjustedHoldEvs
        )
    }

    /// Calculate the adjusted EV for a hold option given the current multiplier
    /// Formula: Adjusted EV = 2 × (Base EV) + (Multiplier - 1)
    private func calculateAdjustedEv(baseEv: Double, multiplier: Int) -> Double {
        return 2.0 * baseEv + Double(multiplier - 1)
    }

    /// Check if the strategy differs between base game and Ultimate X at a given multiplier
    /// This is useful for identifying "transitional" hands where multipliers matter
    func doesStrategyDiffer(
        hand: Hand,
        paytableId: String,
        currentMultiplier: Int,
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
                currentMultiplier: multiplier,
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
