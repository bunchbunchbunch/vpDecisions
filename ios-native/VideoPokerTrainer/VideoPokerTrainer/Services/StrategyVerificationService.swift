import Foundation

/// Service for A/B testing binary vs SQLite strategy lookup
/// Compares results to ensure binary format produces identical results
actor StrategyVerificationService {
    static let shared = StrategyVerificationService()

    struct VerificationResult {
        let paytableId: String
        let totalHands: Int
        let testedHands: Int
        let matchCount: Int
        let mismatchCount: Int
        let missingInBinary: Int
        let missingInSQLite: Int
        let evToleranceFailures: Int
        let durationMs: Double
        var mismatches: [MismatchDetail]

        var isSuccess: Bool {
            mismatchCount == 0 && evToleranceFailures == 0
        }

        var summary: String {
            """
            Verification for \(paytableId):
              Tested: \(testedHands) hands
              Matches: \(matchCount)
              Mismatches: \(mismatchCount)
              Missing in binary: \(missingInBinary)
              Missing in SQLite: \(missingInSQLite)
              EV tolerance failures: \(evToleranceFailures)
              Duration: \(String(format: "%.2f", durationMs))ms
              Result: \(isSuccess ? "PASS" : "FAIL")
            """
        }
    }

    struct MismatchDetail {
        let handKey: String
        let binaryHold: Int?
        let sqliteHold: Int?
        let binaryEv: Double?
        let sqliteEv: Double?
    }

    private init() {}

    // MARK: - Public API

    /// Verify binary format against SQLite for a paytable
    /// Compares a sample of hands (or all if sampleSize is nil)
    func verify(
        paytableId: String,
        sampleSize: Int? = nil,
        evTolerance: Double = 0.0001
    ) async -> VerificationResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Generate all canonical hand keys
        let allHandKeys = generateAllCanonicalKeys()
        let keysToTest: [String]

        if let sample = sampleSize, sample < allHandKeys.count {
            keysToTest = Array(allHandKeys.shuffled().prefix(sample))
        } else {
            keysToTest = allHandKeys
        }

        var matchCount = 0
        var mismatchCount = 0
        var missingInBinary = 0
        var missingInSQLite = 0
        var evToleranceFailures = 0
        var mismatches: [MismatchDetail] = []

        for handKey in keysToTest {
            let binaryResult = await BinaryStrategyStore.shared.lookup(paytableId: paytableId, handKey: handKey)
            let sqliteResult = await LocalStrategyStore.shared.lookup(paytableId: paytableId, handKey: handKey)

            switch (binaryResult, sqliteResult) {
            case (nil, nil):
                // Both missing - not counted as mismatch
                break

            case (nil, .some):
                missingInBinary += 1

            case (.some, nil):
                missingInSQLite += 1

            case let (.some(binary), .some(sqlite)):
                if binary.bestHold != sqlite.bestHold {
                    mismatchCount += 1
                    if mismatches.count < 10 {
                        mismatches.append(MismatchDetail(
                            handKey: handKey,
                            binaryHold: binary.bestHold,
                            sqliteHold: sqlite.bestHold,
                            binaryEv: binary.bestEv,
                            sqliteEv: sqlite.bestEv
                        ))
                    }
                } else if abs(binary.bestEv - sqlite.bestEv) > evTolerance {
                    evToleranceFailures += 1
                    if mismatches.count < 10 {
                        mismatches.append(MismatchDetail(
                            handKey: handKey,
                            binaryHold: binary.bestHold,
                            sqliteHold: sqlite.bestHold,
                            binaryEv: binary.bestEv,
                            sqliteEv: sqlite.bestEv
                        ))
                    }
                } else {
                    matchCount += 1
                }
            }
        }

        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

        return VerificationResult(
            paytableId: paytableId,
            totalHands: allHandKeys.count,
            testedHands: keysToTest.count,
            matchCount: matchCount,
            mismatchCount: mismatchCount,
            missingInBinary: missingInBinary,
            missingInSQLite: missingInSQLite,
            evToleranceFailures: evToleranceFailures,
            durationMs: duration,
            mismatches: mismatches
        )
    }

    /// Performance comparison between binary and SQLite lookups
    func benchmarkLookups(
        paytableId: String,
        iterations: Int = 10000
    ) async -> (binaryMs: Double, sqliteMs: Double, speedup: Double) {
        let allKeys = generateAllCanonicalKeys()
        let testKeys = Array(allKeys.shuffled().prefix(iterations))

        // Warm up caches
        _ = await BinaryStrategyStore.shared.lookup(paytableId: paytableId, handKey: testKeys[0])
        _ = await LocalStrategyStore.shared.lookup(paytableId: paytableId, handKey: testKeys[0])

        // Benchmark binary
        let binaryStart = CFAbsoluteTimeGetCurrent()
        for key in testKeys {
            _ = await BinaryStrategyStore.shared.lookup(paytableId: paytableId, handKey: key)
        }
        let binaryDuration = (CFAbsoluteTimeGetCurrent() - binaryStart) * 1000

        // Benchmark SQLite
        let sqliteStart = CFAbsoluteTimeGetCurrent()
        for key in testKeys {
            _ = await LocalStrategyStore.shared.lookup(paytableId: paytableId, handKey: key)
        }
        let sqliteDuration = (CFAbsoluteTimeGetCurrent() - sqliteStart) * 1000

        let speedup = sqliteDuration / binaryDuration

        NSLog("""
            Benchmark Results (\(iterations) lookups):
              Binary: \(String(format: "%.2f", binaryDuration))ms (\(String(format: "%.3f", binaryDuration/Double(iterations)))ms/lookup)
              SQLite: \(String(format: "%.2f", sqliteDuration))ms (\(String(format: "%.3f", sqliteDuration/Double(iterations)))ms/lookup)
              Speedup: \(String(format: "%.2f", speedup))x
            """)

        return (binaryDuration, sqliteDuration, speedup)
    }

    // MARK: - Canonical Key Generation

    /// Generate all 204,087 canonical hand keys
    private func generateAllCanonicalKeys() -> [String] {
        var keys: Set<String> = []
        let ranks: [Character] = ["2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A"]

        // Generate all 5-card combinations
        for c1 in 0..<48 {
            for c2 in (c1+1)..<49 {
                for c3 in (c2+1)..<50 {
                    for c4 in (c3+1)..<51 {
                        for c5 in (c4+1)..<52 {
                            let hand = [c1, c2, c3, c4, c5]
                            let key = handToCanonicalKey(hand: hand, ranks: ranks)
                            keys.insert(key)
                        }
                    }
                }
            }
        }

        return Array(keys)
    }

    /// Convert card indices to canonical key
    private func handToCanonicalKey(hand: [Int], ranks: [Character]) -> String {
        // Sort by rank
        let sorted = hand.sorted { (ranks[$0 / 4] < ranks[$1 / 4]) || (ranks[$0 / 4] == ranks[$1 / 4] && $0 < $1) }

        var suitMap: [Int: Character] = [:]
        let suitLetters: [Character] = ["a", "b", "c", "d"]
        var nextSuit = 0

        var key = ""
        for card in sorted {
            let rank = ranks[card / 4]
            let suit = card % 4

            let suitChar: Character
            if let existing = suitMap[suit] {
                suitChar = existing
            } else {
                suitChar = suitLetters[nextSuit]
                suitMap[suit] = suitChar
                nextSuit += 1
            }

            key.append(rank)
            key.append(suitChar)
        }

        return key
    }
}
