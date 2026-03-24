# Ultimate X EV Benchmark Test Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a developer-only button in Settings that deals a random Jacks-or-Better hand, assigns a random valid Ultimate X multiplier, computes optimal strategy using both the existing simplified formula and a new full on-the-fly E[K_awarded] formula, then displays results in a popup sheet.

**Architecture:** A new `HoldOutcomeCalculator` actor enumerates all draw-card combinations for each hold bitmask, calls `HandEvaluator` to classify the resulting hand, then averages the awarded multipliers to produce `E[K_awarded]`. A `UltimateXEVBenchmarkViewModel` orchestrates the computation, compares simplified vs. full results, and measures elapsed time. A `UltimateXEVBenchmarkView` sheet displays everything. The Settings page gets a `#if DEBUG` trigger button.

**Tech Stack:** Swift 6, SwiftUI, `@Observable`, actors, `ContinuousClock`, Swift Testing framework (`@Test`, `#expect`).

---

## Background: The Two Formulas

**Simplified formula** (existing `UltimateXStrategyService`):
```
Adjusted EV = 2 × base_EV + (M - 1)
```
Uses a constant "2" as a proxy for average future multiplier value; ignores that different holds produce different hand distributions (and thus different expected future multipliers).

**Full formula** (what this plan implements):
```
Full Adjusted EV(bitmask) = M × 2 × base_EV(bitmask) + E[K_awarded(bitmask)] - 1
```
Where:
- `M` = current multiplier
- `base_EV(bitmask)` = from `StrategyResult.holdEvs[String(bitmask)]`
- `E[K_awarded(bitmask)]` = average multiplier this hold will award on the next hand, computed by enumerating all possible draw outcomes

**Draw combination counts** (47 remaining cards after dealing 5):
- 4 held / 1 draw: C(47,1) = 47
- 3 held / 2 draws: C(47,2) = 1,081
- 2 held / 3 draws: C(47,3) = 16,215
- 1 held / 4 draws: C(47,4) = 178,365
- 0 held / 5 draws: C(47,5) = 1,533,939 → **skip** (never strategically optimal, very slow)
- 5 held / 0 draws: C(47,0) = 1 (evaluate hand as-is)

---

## File Structure

| Action | Path | Responsibility |
|--------|------|----------------|
| **Create** | `Services/HoldOutcomeCalculator.swift` | Enumerate draw combos, compute E[K_awarded] per hold bitmask |
| **Create** | `ViewModels/UltimateXEVBenchmarkViewModel.swift` | Generate random hand + M, call both services, time the full calculation |
| **Create** | `Views/Settings/UltimateXEVBenchmarkView.swift` | Sheet popup displaying benchmark results |
| **Modify** | `Views/Settings/SettingsView.swift` | Add trigger button in `#if DEBUG` Developer section |
| **Create** | `VideoPokerAcademyTests/HoldOutcomeCalculatorTests.swift` | Unit tests for the calculator |

All paths are relative to `ios-native/VideoPokerAcademy/VideoPokerAcademy/` (or `VideoPokerAcademyTests/`).

---

## Task 1: HoldOutcomeCalculator Tests (Red)

**Files:**
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/HoldOutcomeCalculatorTests.swift`

The tests confirm the calculator's two key behaviors: (a) deterministic E[K] for hold-all-five hands (0 draws, just evaluate the dealt hand), and (b) correct combination count for 1-draw holds.

- [ ] **Step 1: Write the failing tests**

```swift
import Testing
@testable import VideoPokerAcademy

struct HoldOutcomeCalculatorTests {

    // MARK: - E[K] for hold-all-five (zero draws, fully deterministic)

    @Test("E[K] for hold-all-five full house is 12 (3-play)")
    func testEKForFullHouseIsMultiplier12() async throws {
        // Full house: AAA KK → K awarded = 12 (three-play table)
        let cards = [
            Card.from(string: "Ah")!, Card.from(string: "Ac")!,
            Card.from(string: "Ad")!, Card.from(string: "Kh")!,
            Card.from(string: "Kc")!
        ]
        let hand = Hand(cards: cards)
        let calc = HoldOutcomeCalculator()
        let ek = await calc.computeEK(
            hand: hand,
            holdBitmask: 31,    // hold all 5
            paytableId: "jacks-or-better-9-6",
            playCount: .three
        )
        #expect(ek == 12.0)
    }

    @Test("E[K] for hold-all-five no-win hand is 1")
    func testEKForNoWinHandIs1() async throws {
        // 7c 8d Jc Kc 2h — rainbow garbage, no win
        let cards = [
            Card.from(string: "7c")!, Card.from(string: "8d")!,
            Card.from(string: "Jc")!, Card.from(string: "Kc")!,
            Card.from(string: "2h")!
        ]
        let hand = Hand(cards: cards)
        let calc = HoldOutcomeCalculator()
        let ek = await calc.computeEK(
            hand: hand,
            holdBitmask: 31,
            paytableId: "jacks-or-better-9-6",
            playCount: .three
        )
        #expect(ek == 1.0)    // no win → multiplier = 1
    }

    @Test("E[K] for hold-all-five flush is 11 (3-play)")
    func testEKForFlushIs11() async throws {
        // 2h 5h 9h Jh Ah — flush
        let cards = [
            Card.from(string: "2h")!, Card.from(string: "5h")!,
            Card.from(string: "9h")!, Card.from(string: "Jh")!,
            Card.from(string: "Ah")!
        ]
        let hand = Hand(cards: cards)
        let calc = HoldOutcomeCalculator()
        let ek = await calc.computeEK(
            hand: hand,
            holdBitmask: 31,
            paytableId: "jacks-or-better-9-6",
            playCount: .three
        )
        #expect(ek == 11.0)
    }

    // MARK: - E[K] is always >= 1.0

    @Test("E[K] is always at least 1.0 for any hold")
    func testEKIsAtLeast1ForAnyHold() async throws {
        // Hold 4 cards (1 draw) — all 47 outcomes, worst case E[K] >= 1
        let cards = [
            Card.from(string: "Jh")!, Card.from(string: "Jd")!,
            Card.from(string: "9h")!, Card.from(string: "8h")!,
            Card.from(string: "7h")!
        ]
        let hand = Hand(cards: cards)
        let calc = HoldOutcomeCalculator()

        // Hold JJ (bitmask = 0b00011 = 3)
        let ekJJ = await calc.computeEK(
            hand: hand,
            holdBitmask: 3,
            paytableId: "jacks-or-better-9-6",
            playCount: .three
        )
        #expect(ekJJ >= 1.0)

        // Hold 4-card flush (indices 2,3,4 = bitmask 0b11100 = 28)
        let ekFlush = await calc.computeEK(
            hand: hand,
            holdBitmask: 28,
            paytableId: "jacks-or-better-9-6",
            playCount: .three
        )
        #expect(ekFlush >= 1.0)
    }

    // MARK: - Known approximate values from analysis

    @Test("E[K] for hold JJ draw 3 is approximately 2.46")
    func testEKForJJApprox246() async throws {
        // J♥J♦ 9♥8♥7♥ — hold JJ (bitmask 3 = indices 0,1)
        let cards = [
            Card.from(string: "Jh")!, Card.from(string: "Jd")!,
            Card.from(string: "9h")!, Card.from(string: "8h")!,
            Card.from(string: "7h")!
        ]
        let hand = Hand(cards: cards)
        let calc = HoldOutcomeCalculator()
        let ek = await calc.computeEK(
            hand: hand,
            holdBitmask: 3,
            paytableId: "jacks-or-better-9-6",
            playCount: .three
        )
        // Approximate: Two Pair 38.6%×3 + Three of Kind 11.4%×4 + Full House 3.2%×12
        //              + Quads 0.4%×2 + No Win 46.4%×1 ≈ 2.46
        #expect(ek >= 2.0 && ek <= 3.5)
    }
}
```

- [ ] **Step 2: Confirm tests fail (HoldOutcomeCalculator doesn't exist yet)**

```bash
cd ios-native/VideoPokerAcademy && xcodebuild test \
  -scheme VideoPokerAcademy -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing VideoPokerAcademyTests/HoldOutcomeCalculatorTests 2>&1 | tail -20
```
Expected: compile error — `HoldOutcomeCalculator` not found.

---

## Task 2: HoldOutcomeCalculator Implementation (Green)

**Files:**
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Services/HoldOutcomeCalculator.swift`

- [ ] **Step 1: Create the file**

```swift
import Foundation

/// Computes E[K_awarded] — the expected Ultimate X multiplier awarded on the next hand —
/// by enumerating all possible draw outcomes for a given hold bitmask.
///
/// For a hold bitmask, held cards are fixed; the remaining 47 undealt cards form the draw pool.
/// All C(47, drawCount) combinations are evaluated. The average multiplier across all outcomes
/// is E[K_awarded].
///
/// Skip bitmask=0 (discard all, 1.5M combos). All other bitmasks run efficiently.
actor HoldOutcomeCalculator {

    /// Compute E[K_awarded] for a specific hold bitmask.
    /// Returns 1.0 if bitmask == 0 (discard all — skipped for performance).
    func computeEK(
        hand: Hand,
        holdBitmask: Int,
        paytableId: String,
        playCount: UltimateXPlayCount
    ) async -> Double {
        guard holdBitmask != 0 else { return 1.0 }

        let heldIndices = Hand.holdIndicesFromBitmask(holdBitmask)
        let heldCards = heldIndices.map { hand.cards[$0] }
        let drawCount = 5 - heldCards.count

        // Build remaining deck: all 52 cards minus the 5 dealt cards
        let dealtSet = Set(hand.cards.map { "\($0.rank.rawValue)\($0.suit.rawValue)" })
        let remainingDeck = Card.createDeck().filter { card in
            !dealtSet.contains("\(card.rank.rawValue)\(card.suit.rawValue)")
        }

        // drawCount == 0: evaluate the hand as-is
        if drawCount == 0 {
            let result = await HandEvaluator.shared.evaluateDealtHand(
                hand: hand,
                paytableId: paytableId
            )
            let multiplier = UltimateXMultiplierTable.multiplier(
                for: result.handName ?? "",
                playCount: playCount
            )
            return Double(multiplier)
        }

        // Enumerate and evaluate all combinations in batch
        return await batchEvaluate(
            heldIndices: heldIndices,
            heldCards: heldCards,
            remainingDeck: remainingDeck,
            drawCount: drawCount,
            paytableId: paytableId,
            playCount: playCount
        )
    }

    private func batchEvaluate(
        heldIndices: [Int],
        heldCards: [Card],
        remainingDeck: [Card],
        drawCount: Int,
        paytableId: String,
        playCount: UltimateXPlayCount
    ) async -> Double {
        var totalMultiplier: Double = 0
        var comboCount: Int = 0

        // Collect all combination index arrays first (sync)
        var allCombos: [[Int]] = []
        enumerateCombinationIndices(n: remainingDeck.count, k: drawCount) { indices in
            allCombos.append(indices)
        }

        // Evaluate each combo (async actor calls)
        for indices in allCombos {
            let drawnCards = indices.map { remainingDeck[$0] }
            var finalCards = Array(repeating: Card(rank: .ace, suit: .hearts), count: 5)
            for (pos, card) in zip(heldIndices, heldCards) {
                finalCards[pos] = card
            }
            var drawIdx = 0
            for pos in 0..<5 {
                if !heldIndices.contains(pos) {
                    finalCards[pos] = drawnCards[drawIdx]
                    drawIdx += 1
                }
            }
            let drawHand = Hand(cards: finalCards)
            let result = await HandEvaluator.shared.evaluateDealtHand(
                hand: drawHand,
                paytableId: paytableId
            )
            let multiplier = UltimateXMultiplierTable.multiplier(
                for: result.handName ?? "",
                playCount: playCount
            )
            totalMultiplier += Double(multiplier)
            comboCount += 1
        }

        guard comboCount > 0 else { return 1.0 }
        return totalMultiplier / Double(comboCount)
    }

    /// Generate all C(n, k) combinations of indices [0..<n] using a callback.
    /// Iterative algorithm — avoids recursion and large intermediate allocations.
    private func enumerateCombinationIndices(n: Int, k: Int, handler: ([Int]) -> Void) {
        guard k > 0, k <= n else {
            if k == 0 { handler([]) }
            return
        }
        var indices = Array(0..<k)
        while true {
            handler(indices)
            // Find rightmost index that can be incremented
            var i = k - 1
            while i >= 0 && indices[i] == n - k + i { i -= 1 }
            if i < 0 { break }
            indices[i] += 1
            for j in (i + 1)..<k { indices[j] = indices[j - 1] + 1 }
        }
    }
}
```

- [ ] **Step 2: Build to confirm it compiles**

Use `mcp__xcodebuildmcp__build_sim_name_proj` with scheme `VideoPokerAcademy`.

Expected: build succeeds.

- [ ] **Step 3: Run the tests**

Use `mcp__xcodebuildmcp__test_sim_name_proj`. Filter to `HoldOutcomeCalculatorTests`.

Expected: all 4 tests pass.

**If tests fail:** Read the failure messages carefully.
- If E[K] values are wrong for the zero-draw case, check how `HandEvaluator.evaluateDealtHand` is called and how `UltimateXMultiplierTable.multiplier(for:playCount:)` matches hand names.
- If the approximation test fails, adjust the tolerance (range check is already generous: 2.0–3.5).
- If it times out on the 1-draw test, check whether `allCombos` is being built correctly.

- [ ] **Step 4: Commit**

```bash
git add ios-native/VideoPokerAcademy/VideoPokerAcademy/Services/HoldOutcomeCalculator.swift
git add ios-native/VideoPokerAcademy/VideoPokerAcademyTests/HoldOutcomeCalculatorTests.swift
git commit -m "feat: add HoldOutcomeCalculator for Ultimate X E[K_awarded] computation"
```

---

## Task 3: UltimateXEVBenchmarkViewModel

**Files:**
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/UltimateXEVBenchmarkViewModel.swift`

This ViewModel generates a random hand + multiplier, calls both services, measures elapsed time for the full computation, and exposes results to the view.

- [ ] **Step 1: Create the ViewModel**

```swift
import Foundation
import SwiftUI

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

    /// E[K_awarded] for the top holds
    let topHoldDetails: [HoldDetail]

    /// Whether simplified and full formulas agree on the best hold
    var formulasAgree: Bool { simplifiedBestHold == fullBestHold }

    /// Whether full formula differs from base strategy
    var fullDiffersFromBase: Bool { fullBestHold != baseBestHold }

    /// Elapsed time for full E[K] computation
    let computationTimeMs: Double

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

        // 2. Random valid UX multiplier (pick any — include M=1 for ~1/7 chance)
        let validMultipliers = UltimateXMultiplierTable.possibleMultipliers(for: playCount)
        let multiplier = validMultipliers.randomElement()!

        // 3. Get base strategy result (all 32 hold EVs)
        guard let baseStrategyResult = try await StrategyService.shared.lookup(
            hand: hand,
            paytableId: paytableId
        ) else {
            throw BenchmarkError.strategyNotAvailable
        }

        let calculator = HoldOutcomeCalculator()

        // 4. Measure full E[K] computation time across all non-zero bitmasks
        let clock = ContinuousClock()
        var holdDetails: [EVBenchmarkResult.HoldDetail] = []

        let elapsed = await clock.measure {
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
        }

        // 5. Find best holds for each formula
        let fullBest = holdDetails.max(by: { $0.fullAdjustedEV < $1.fullAdjustedEV })!
        let simplifiedBest = holdDetails.max(by: { $0.simplifiedAdjustedEV < $1.simplifiedAdjustedEV })!

        // Mark best holds
        for i in holdDetails.indices {
            holdDetails[i].isFullBest = holdDetails[i].bitmask == fullBest.bitmask
            holdDetails[i].isSimplifiedBest = holdDetails[i].bitmask == simplifiedBest.bitmask
        }

        // 6. Top 5 holds by full EV for display
        let topHolds = holdDetails
            .sorted { $0.fullAdjustedEV > $1.fullAdjustedEV }
            .prefix(5)
            .map { $0 }

        let timeMs = Double(elapsed.components.seconds) * 1000.0
               + Double(elapsed.components.attoseconds) / 1e15

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
```

`formulasAgree` and `fullDiffersFromBase` on `EVBenchmarkResult` are computed properties (shown in the struct definition above) — they are NOT passed to the initializer.

- [ ] **Step 2: Build**

Use `mcp__xcodebuildmcp__build_sim_name_proj`. Fix any Swift 6 concurrency warnings (e.g., `ContinuousClock.measure` closure may need `@Sendable`).

Expected: build succeeds.

---

## Task 4: UltimateXEVBenchmarkView

**Files:**
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Settings/UltimateXEVBenchmarkView.swift`

A sheet view (triggered from Settings) showing: hand cards, multiplier, formula comparison, top holds, computation time.

- [ ] **Step 1: Create the view**

```swift
import SwiftUI

struct UltimateXEVBenchmarkView: View {
    @State private var viewModel = UltimateXEVBenchmarkViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.Gradients.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("UX EV Benchmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.Colors.mintGreen)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                Divider().background(Color.white.opacity(0.1))

                ScrollView {
                    VStack(spacing: 16) {
                        runButton

                        if viewModel.isRunning {
                            ProgressView("Computing full E[K] for all holds…")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .padding()
                        }

                        if let result = viewModel.result {
                            resultContent(result)
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(AppTheme.Colors.danger)
                                .padding()
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Run Button

    private var runButton: some View {
        Button {
            Task { await viewModel.runBenchmark() }
        } label: {
            HStack {
                if viewModel.isRunning {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "play.circle.fill")
                }
                Text(viewModel.isRunning ? "Running…" : "Run Benchmark")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(viewModel.isRunning ? Color.gray : AppTheme.Colors.mintGreen)
            .cornerRadius(25)
        }
        .disabled(viewModel.isRunning)
    }

    // MARK: - Result Content

    @ViewBuilder
    private func resultContent(_ result: EVBenchmarkResult) -> some View {
        // Hand display
        benchmarkSection(title: "Dealt Hand") {
            handView(result.hand)
        }

        // Multiplier
        benchmarkSection(title: "Multiplier") {
            HStack {
                Text("M = \(result.multiplier)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(result.multiplier > 1 ? AppTheme.Colors.mintGreen : .white)
                Spacer()
                Text("(\(UltimateXPlayCount.three.displayName) JoB 9/6)")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding()
        }

        // Strategy comparison
        benchmarkSection(title: "Strategy Comparison") {
            VStack(spacing: 8) {
                strategyRow(
                    label: "Base (M=1)",
                    bitmask: result.baseBestHold,
                    hand: result.hand,
                    ev: result.baseEV,
                    highlight: false
                )
                Divider().background(Color.white.opacity(0.1))
                strategyRow(
                    label: "Simplified: 2×EV + (M-1)",
                    bitmask: result.simplifiedBestHold,
                    hand: result.hand,
                    ev: result.simplifiedBestEV,
                    highlight: false
                )
                Divider().background(Color.white.opacity(0.1))
                strategyRow(
                    label: "Full: M×2×EV + E[K]-1",
                    bitmask: result.fullBestHold,
                    hand: result.hand,
                    ev: result.fullBestEV,
                    highlight: true
                )
                Divider().background(Color.white.opacity(0.1))

                HStack {
                    Image(systemName: result.formulasAgree ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.formulasAgree ? AppTheme.Colors.mintGreen : AppTheme.Colors.danger)
                    Text(result.formulasAgree
                         ? "Simplified and full formulas agree"
                         : "STRATEGY DIFFERS between formulas!")
                        .font(.system(size: 13, weight: result.formulasAgree ? .regular : .bold))
                        .foregroundColor(result.formulasAgree ? AppTheme.Colors.textSecondary : AppTheme.Colors.danger)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }

        // Top holds table
        benchmarkSection(title: "Top 5 Holds (Full Formula)") {
            VStack(spacing: 0) {
                // Header row
                HStack {
                    Text("Hold").frame(width: 100, alignment: .leading)
                    Text("E[K]").frame(width: 50, alignment: .trailing)
                    Text("Base EV").frame(width: 70, alignment: .trailing)
                    Text("Full EV").frame(width: 70, alignment: .trailing)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)

                ForEach(Array(result.topHoldDetails.enumerated()), id: \.offset) { _, detail in
                    HStack {
                        Text(holdDescription(detail.heldIndices, hand: result.hand))
                            .frame(width: 100, alignment: .leading)
                            .font(.system(size: 12, design: .monospaced))
                        Text(String(format: "%.2f", detail.eKAwarded))
                            .frame(width: 50, alignment: .trailing)
                        Text(String(format: "%.4f", detail.baseEV))
                            .frame(width: 70, alignment: .trailing)
                        Text(String(format: "%.4f", detail.fullAdjustedEV))
                            .frame(width: 70, alignment: .trailing)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(detail.isFullBest ? AppTheme.Colors.mintGreen : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(detail.isFullBest ? Color.white.opacity(0.05) : Color.clear)
                }
            }
        }

        // Computation time
        benchmarkSection(title: "Performance") {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Text("Full E[K] computation:")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Spacer()
                Text(String(format: "%.1f ms", result.computationTimeMs))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(result.computationTimeMs < 50 ? AppTheme.Colors.mintGreen : .orange)
            }
            .padding()
        }
    }

    // MARK: - Helper Views

    private func handView(_ hand: Hand) -> some View {
        HStack(spacing: 8) {
            ForEach(hand.cards) { card in
                Text(card.displayText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(card.suit.color)
                    .frame(minWidth: 40)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding()
    }

    private func strategyRow(label: String, bitmask: Int, hand: Hand, ev: Double, highlight: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Text(holdDescription(Hand.holdIndicesFromBitmask(bitmask), hand: hand))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(highlight ? AppTheme.Colors.mintGreen : .white)
            }
            Spacer()
            Text(String(format: "%.4f", ev))
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func holdDescription(_ indices: [Int], hand: Hand) -> String {
        if indices.isEmpty { return "Discard all" }
        if indices.count == 5 { return "Hold all" }
        return indices.map { hand.cards[$0].displayText }.joined(separator: " ")
    }

    private func benchmarkSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .textCase(.uppercase)
            VStack(spacing: 0) { content() }
                .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.Colors.cardBackground))
        }
    }
}
```

- [ ] **Step 2: Build**

Use `mcp__xcodebuildmcp__build_sim_name_proj`. Fix any type errors.

Expected: build succeeds.

---

## Task 5: Wire Up the Settings Button

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Settings/SettingsView.swift`

Add a sheet trigger and a button inside the existing `#if DEBUG` Developer section.

- [ ] **Step 1: Read SettingsView.swift to confirm current structure**

The `#if DEBUG` section currently reads:
```swift
#if DEBUG
// Developer Tools
settingsSection(title: "Developer") {
    Button {
        RatingPromptService.shared.forceShow()
    } label: {
        SettingsRowContent(
            icon: "star.bubble",
            title: "Preview Rating Prompt",
            subtitle: "Bypasses time gate — debug only",
            showChevron: false
        )
    }
}
.padding(.top, 8)
#endif
```

- [ ] **Step 2: Add the sheet state property and the button**

Add `@State private var showEVBenchmark = false` near the other `@State` properties at the top of `SettingsView`.

Then add a second button inside the Developer `settingsSection`:

```swift
Divider().background(Color.white.opacity(0.1))

Button {
    showEVBenchmark = true
} label: {
    SettingsRowContent(
        icon: "function",
        title: "UX EV Benchmark",
        subtitle: "On-the-fly E[K] vs simplified formula",
        showChevron: false
    )
}
```

Then add `.sheet(isPresented: $showEVBenchmark) { UltimateXEVBenchmarkView() }` to the view's modifier chain (after the existing `.alert` modifiers).

The exact edits to make:

**In the `@State` block** (after `@State private var authenticationErrorMessage = ""`):
```swift
#if DEBUG
@State private var showEVBenchmark = false
#endif
```

**Inside the Developer settingsSection**, after the existing Rating Prompt button:
```swift
Divider().background(Color.white.opacity(0.1))

Button {
    showEVBenchmark = true
} label: {
    SettingsRowContent(
        icon: "function",
        title: "UX EV Benchmark",
        subtitle: "On-the-fly E[K] vs simplified formula",
        showChevron: false
    )
}
```

**After the last `.alert(...)` modifier** (before the closing `}`):
```swift
#if DEBUG
.sheet(isPresented: $showEVBenchmark) {
    UltimateXEVBenchmarkView()
}
#endif
```

- [ ] **Step 3: Build**

Use `mcp__xcodebuildmcp__build_sim_name_proj`.

Expected: build succeeds.

- [ ] **Step 4: Run all tests**

Use `mcp__xcodebuildmcp__test_sim_name_proj`.

Expected: all existing tests pass, all new `HoldOutcomeCalculatorTests` pass.

- [ ] **Step 5: Visual verification**

Boot simulator, install, launch, navigate to Settings, scroll to Developer section, verify the "UX EV Benchmark" row appears.

```
mcp__xcodebuildmcp__boot_simulator
mcp__xcodebuildmcp__install_app
mcp__xcodebuildmcp__launch_app
```

Navigate to Settings → Developer → tap "UX EV Benchmark" → tap "Run Benchmark" → verify the sheet shows hand cards, multiplier, strategy comparison, and computation time.

Use `mcp__xcodebuildmcp__screenshot` to capture the result.

---

## Known Implementation Notes

1. **`ContinuousClock.measure` return type**: Returns a `Duration`. Access as `elapsed.components` (`.seconds` and `.attoseconds`). Alternatively use `Date()` timestamps for simplicity.

2. **Swift 6 actor isolation**: `UltimateXEVBenchmarkViewModel` is `@MainActor`. The `HoldOutcomeCalculator` is a non-isolated actor. The `Task { await viewModel.runBenchmark() }` call from the view's button is correct.

3. **Memory for 1-held bitmasks**: `allCombos` for a 1-held bitmask (4 draws) is 178,365 `[Int]` arrays of 4 elements. At ~64 bytes per array, that's ~11MB — acceptable for a debug tool.

4. **`Card` hashability**: The deck deduplication uses `"\(rank.rawValue)\(suit.rawValue)"` strings since `Card` uses `UUID` for `id`. If `Card` gains a proper equatable by rank+suit in the future, this can be simplified.

5. **`Divider` in settings section**: The existing `settingsSection` uses `VStack(spacing: 0)` with no separators. Adding a `Divider` between buttons is consistent with iOS list style.

6. **`StrategyService` requires downloaded strategy file**: If the JoB 9/6 strategy isn't downloaded, `lookup` returns nil. The ViewModel handles this via `BenchmarkError.strategyNotAvailable`.
