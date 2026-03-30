# Ultimate X Quiz & Simulation Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Ultimate X variant support to Quiz mode (multiplier-aware grading + EV table) and Simulation mode (per-line multiplier chain applied to payouts).

**Architecture:** Quiz mode assigns a random multiplier per hand from the UX multiplier table and grades answers against the UX-optimal hold. Simulation mode maintains a per-line multiplier array (like PlayViewModel) that evolves hand-by-hand — base strategy is used for hold decisions (performance), but multipliers are applied to payouts. Both modes add a Variant selector (Standard / Ult X) and Play Count selector to their respective start screens.

**Tech Stack:** Swift 6, SwiftUI, `@MainActor` ObservableObject, `UltimateXStrategyService` (actor), `HoldOutcomeCalculator` (actor), `UltimateXMultiplierTable` (static struct)

---

## Key Concepts for Implementers

### UX Formula
`adjustedEV = currentMultiplier × 2.0 × baseEV + E[K_awarded] - 1.0`

The `2.0` factor accounts for UX requiring 2 coins per credit per line (vs 1 for standard). `E[K_awarded]` is the expected multiplier the next hand will receive, based on enumerated draw outcomes.

### Multiplier Assignment (Quiz)
`UltimateXMultiplierTable.possibleMultipliers(for:family:)` returns all distinct multiplier values that can be awarded for a game family + play count. For quiz, randomly pick one of these values per hand. At JoB 3-play, possible values are `[1, 2, 3, 4, 7, 11, 12]`.

### Multiplier Chain (Simulation)
After each hand is drawn, the multiplier awarded to each LINE is deterministic:
```swift
UltimateXMultiplierTable.multiplier(for: handName, playCount: playCount, family: family)
```
Full House → 12×, Flush → 11×, Straight → 7×, Three of a Kind → 4×, Two Pair → 3×, Pair/no win → 2×/1×. That line's multiplier applies to the NEXT hand.

### UX Bet Structure
UX requires 2 coins per credit per line. `betPerHand` doubles vs standard:
```swift
let coinsPerLine = isUltimateX ? 10 : 5  // UX: 10 coins/line, standard: 5
let betPerHand = Double(coinsPerLine * linesPerHand) * denomination.rawValue
```

### Key Files to Read Before Starting
- `VideoPokerAcademy/Models/UltimateXModels.swift` — `UltimateXStrategyResult`, `UltimateXMultiplierTable`, `UltimateXPlayCount`
- `VideoPokerAcademy/Services/UltimateXStrategyService.swift` — `lookup()` actor method
- `VideoPokerAcademy/Models/SimulationModels.swift` — `SimulationConfig`, `SimulationRun`, `SingleHandResult`
- `VideoPokerAcademy/ViewModels/SimulationViewModel.swift` — existing simulation logic (especially `runSingleSimulation`, `getOptimalHold`, `evaluateHand`)
- `VideoPokerAcademy/ViewModels/QuizViewModel.swift` — `QuizHand`, `loadQuiz()`, `submit()`
- `VideoPokerAcademy/Views/Home/HomeView.swift` — `AppScreen` enum, `QuizStartView` struct (lines ~530-790), `destinationView(for:)`
- `VideoPokerAcademy/Views/Quiz/QuizPlayView.swift` — `evOptionsTable(for:)`, `feedbackOverlay(for:)`, `cardsAreaView()`
- `VideoPokerAcademy/Views/Simulation/SimulationStartView.swift` — existing config sections
- `VideoPokerAcademy/Views/Analyzer/AnalyzerStartView.swift` — reference for variant+play count chip pattern

---

## File Map

| File | Change |
|------|--------|
| `VideoPokerAcademy/ViewModels/QuizViewModel.swift` | Add `currentMultiplier`/`uxResult` to `QuizHand`; add UX params to `QuizViewModel`; update `loadQuiz()` and `submit()` |
| `VideoPokerAcademy/Models/SimulationModels.swift` | Add `isUltimateXMode`/`playCount` to `SimulationConfig`; update `totalWagered` |
| `VideoPokerAcademy/ViewModels/SimulationViewModel.swift` | Add UX config vars; update `startSimulation()`, `runSingleSimulation()`, `getOptimalHold()` |
| `VideoPokerAcademy/Views/Home/HomeView.swift` | Add `isUltimateXMode`/`playCount` to `AppScreen.quizPlay`; add variant+play count sections to `QuizStartView`; update `destinationView(for:)` |
| `VideoPokerAcademy/Views/Quiz/QuizPlayView.swift` | Show multiplier badge; show UX EV table in feedback |
| `VideoPokerAcademy/Views/Simulation/SimulationStartView.swift` | Add variant+play count section |
| `VideoPokerAcademy/VideoPokerAcademyTests/UltimateXQuizTests.swift` | New: test UX quiz hand grading |

---

## Task 1: Quiz — Model & ViewModel

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/QuizViewModel.swift`
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/UltimateXQuizTests.swift`

### Background
`QuizHand` currently holds only base strategy data. `QuizViewModel` constructs quiz hands in `loadQuiz()` by calling `StrategyService.shared.lookup()`. `submit()` checks the user's hold against `strategyResult.isHoldTiedForBest()`.

For UX mode, each quiz hand needs a randomly-assigned multiplier and a precomputed `UltimateXStrategyResult`. The `submit()` function must grade against the UX-optimal hold instead of the base hold.

- [ ] **Step 1: Write failing test**

Create `VideoPokerAcademyTests/UltimateXQuizTests.swift`:

```swift
import Testing
import Foundation
@testable import VideoPokerAcademy

@Suite("Ultimate X Quiz Tests")
struct UltimateXQuizTests {

    // MARK: - QuizHand

    @Test("QuizHand defaults: currentMultiplier = 1.0, uxResult = nil")
    func testQuizHandDefaults() async throws {
        let hand = Hand.deal()
        let paytableId = PayTable.jacksOrBetter96.id
        guard let result = try await StrategyService.shared.lookup(hand: hand, paytableId: paytableId) else {
            return  // Skip if no strategy available
        }
        let quizHand = QuizHand(hand: hand, strategyResult: result)
        #expect(quizHand.currentMultiplier == 1.0)
        #expect(quizHand.uxResult == nil)
    }

    // MARK: - QuizViewModel UX mode

    @Test("QuizViewModel initializes with UX params")
    func testQuizViewModelUXInit() {
        let vm = QuizViewModel(
            paytableId: PayTable.jacksOrBetter96.id,
            isUltimateXMode: true,
            ultimateXPlayCount: .ten
        )
        #expect(vm.isUltimateXMode == true)
        #expect(vm.ultimateXPlayCount == .ten)
    }

    @Test("QuizViewModel initializes with standard defaults")
    func testQuizViewModelStandardInit() {
        let vm = QuizViewModel(paytableId: PayTable.jacksOrBetter96.id)
        #expect(vm.isUltimateXMode == false)
        #expect(vm.ultimateXPlayCount == .ten)
    }
}
```

- [ ] **Step 2: Run test — expect it to fail** (QuizHand missing fields, QuizViewModel missing params)

```bash
xcodebuild test -scheme VideoPokerAcademy \
  -destination 'platform=iOS Simulator,id=E03325C2-ADAF-4036-B8E1-E9972F1BCDCC' \
  -only-testing:VideoPokerAcademyTests/UltimateXQuizTests 2>&1 | grep -E "error:|FAILED|passed|failed"
```

- [ ] **Step 3: Add `currentMultiplier` and `uxResult` to `QuizHand`**

In `QuizViewModel.swift`, update the `QuizHand` struct (top of file):

```swift
struct QuizHand: Identifiable {
    let id = UUID()
    let hand: Hand
    let strategyResult: StrategyResult
    var currentMultiplier: Double = 1.0           // UX: multiplier active for this hand
    var uxResult: UltimateXStrategyResult? = nil  // UX: adjusted strategy result
    var userHoldIndices: [Int] = []
    var isCorrect: Bool = false
    var category: HandCategory = .mixedDecisions
}
```

- [ ] **Step 4: Add UX properties and params to `QuizViewModel`**

Add stored properties after `let weakSpotsMode: Bool`:

```swift
let isUltimateXMode: Bool
let ultimateXPlayCount: UltimateXPlayCount
```

Update `init` to:

```swift
init(paytableId: String, weakSpotsMode: Bool = false, quizSize: Int = 25,
     isUltimateXMode: Bool = false, ultimateXPlayCount: UltimateXPlayCount = .ten) {
    self.paytableId = paytableId
    self.weakSpotsMode = weakSpotsMode
    self.quizSize = quizSize
    self.isUltimateXMode = isUltimateXMode
    self.ultimateXPlayCount = ultimateXPlayCount
    debugNSLog("📊 QuizViewModel initialized with paytableId: %@, quizSize: %d", paytableId, quizSize)
}
```

- [ ] **Step 5: Run tests — expect passing now**

```bash
xcodebuild test -scheme VideoPokerAcademy \
  -destination 'platform=iOS Simulator,id=E03325C2-ADAF-4036-B8E1-E9972F1BCDCC' \
  -only-testing:VideoPokerAcademyTests/UltimateXQuizTests 2>&1 | grep -E "error:|FAILED|passed|failed"
```

- [ ] **Step 6: Update `loadQuiz()` to populate UX fields**

Inside the `while foundHands.count < quizSize` loop, after `let quizHand = QuizHand(hand: hand, strategyResult: result)`, replace the append logic with:

```swift
if isUltimateXMode {
    let family = PayTable.allPayTables.first(where: { $0.id == paytableId })?.family ?? .jacksOrBetter
    let possibleMults = UltimateXMultiplierTable.possibleMultipliers(for: ultimateXPlayCount, family: family)
    let multiplier = Double(possibleMults.randomElement() ?? 1)
    if let uxResult = try? await UltimateXStrategyService.shared.lookup(
        hand: hand,
        paytableId: paytableId,
        currentMultiplier: multiplier,
        playCount: ultimateXPlayCount
    ) {
        var uxHand = QuizHand(hand: hand, strategyResult: result)
        uxHand.currentMultiplier = multiplier
        uxHand.uxResult = uxResult
        foundHands.append(uxHand)
        loadingProgress = foundHands.count
    }
    // else: UX lookup failed for this hand — loop will retry with a fresh hand
} else {
    foundHands.append(QuizHand(hand: hand, strategyResult: result))
    loadingProgress = foundHands.count
}
```

Note: The existing `if foundHands.count == 0 { debugNSLog(...) }` block can remain just before this new block.

- [ ] **Step 7: Update `submit()` to use UX-optimal hold in UX mode**

In `submit()`, replace the `let correct = ...` line and the `canonicalBestHold`/`correctHold` block with:

```swift
// Determine correct hold: UX-adjusted in UX mode, base strategy otherwise
let correct: Bool
if isUltimateXMode, let uxResult = currentHand.uxResult {
    correct = uxResult.isAdjustedHoldTiedForBest(userCanonicalHold)
} else {
    correct = currentHand.strategyResult.isHoldTiedForBest(userCanonicalHold)
}

// For category assignment, use UX-adjusted best hold in UX mode
let canonicalBestHold: [Int]
if isUltimateXMode, let uxResult = currentHand.uxResult {
    canonicalBestHold = uxResult.adjustedBestHoldIndices
} else {
    canonicalBestHold = currentHand.strategyResult.bestHoldIndices
}
let correctHold = currentHand.hand.canonicalIndicesToOriginal(canonicalBestHold).sorted()
```

Replace the `evLost` calculation block (`if !correct { ... }`) with:

```swift
evLost = 0
if !correct {
    if isUltimateXMode, let uxResult = currentHand.uxResult {
        if let userAdjustedEv = uxResult.adjustedHoldEvs[String(userBitmask)] {
            evLost = uxResult.adjustedBestEv - userAdjustedEv
        }
    } else {
        if let userEv = currentHand.strategyResult.holdEvs[String(userBitmask)] {
            evLost = currentHand.strategyResult.bestEv - userEv
        }
    }
}
```

Note: `userBitmask` is already computed earlier in `submit()` at the debug logging block. Remove the duplicate `let userCanonicalHold` / `let userCanonicalBitmask` lines inside `if !correct` that were there before.

- [ ] **Step 8: Build and verify no errors**

```bash
xcodebuild build -scheme VideoPokerAcademy \
  -destination 'platform=iOS Simulator,id=E03325C2-ADAF-4036-B8E1-E9972F1BCDCC' \
  2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 9: Run all tests**

```bash
xcodebuild test -scheme VideoPokerAcademy \
  -destination 'platform=iOS Simulator,id=E03325C2-ADAF-4036-B8E1-E9972F1BCDCC' \
  2>&1 | grep -E "error:|FAILED|Test Suite.*passed|Test Suite.*failed" | tail -10
```

Expected: all suites pass.

---

## Task 2: Quiz — UI

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Home/HomeView.swift`
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Quiz/QuizPlayView.swift`

### Background
`AppScreen.quizPlay` needs two new associated values. `HomeView.QuizStartView` (a private struct defined inside HomeView.swift) needs variant + play count selectors. `QuizPlayView` needs a multiplier badge above the cards and a UX EV table when in feedback mode.

- [ ] **Step 1: Update `AppScreen.quizPlay` case in `HomeView.swift`**

Change (near the top of HomeView.swift):

```swift
// OLD:
case quizPlay(paytableId: String, weakSpotsMode: Bool, quizSize: Int)

// NEW:
case quizPlay(paytableId: String, weakSpotsMode: Bool, quizSize: Int, isUltimateXMode: Bool, playCount: UltimateXPlayCount)
```

- [ ] **Step 2: Update `destinationView(for:)` to pass new params**

```swift
// OLD:
case .quizPlay(let paytableId, let weakSpotsMode, let quizSize):
    QuizPlayView(
        viewModel: QuizViewModel(
            paytableId: paytableId,
            weakSpotsMode: weakSpotsMode,
            quizSize: quizSize
        ),
        navigationPath: $navigationPath
    )

// NEW:
case .quizPlay(let paytableId, let weakSpotsMode, let quizSize, let isUltimateXMode, let playCount):
    QuizPlayView(
        viewModel: QuizViewModel(
            paytableId: paytableId,
            weakSpotsMode: weakSpotsMode,
            quizSize: quizSize,
            isUltimateXMode: isUltimateXMode,
            ultimateXPlayCount: playCount
        ),
        navigationPath: $navigationPath
    )
```

- [ ] **Step 3: Build — expect one error (missing isUltimateXMode at call site)**

```bash
xcodebuild build -scheme VideoPokerAcademy \
  -destination 'platform=iOS Simulator,id=E03325C2-ADAF-4036-B8E1-E9972F1BCDCC' \
  2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Expected: one error where `AppScreen.quizPlay(...)` is called in the `startQuiz` button action of `QuizStartView`.

- [ ] **Step 4: Add UX state vars to `QuizStartView`**

In `QuizStartView` (the private struct inside HomeView.swift, around line 536), add after the existing `@State private var selectedQuizSize: Int = 25`:

```swift
@State private var isUltimateXMode: Bool = false
@State private var ultimateXPlayCount: UltimateXPlayCount = .ten
```

- [ ] **Step 5: Add `variantSection` and `playCountSection` to `QuizStartView`**

Add these computed properties to `QuizStartView`:

```swift
// MARK: - Variant Section

private var variantSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("Variant")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(AppTheme.Colors.textSecondary)
        FlowLayout(spacing: 8) {
            SelectionChip(title: "Standard", isSelected: !isUltimateXMode) {
                isUltimateXMode = false
            }
            SelectionChip(title: "Ult X", isSelected: isUltimateXMode) {
                isUltimateXMode = true
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}

// MARK: - Play Count Section

private var playCountSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("Play Count")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(AppTheme.Colors.textSecondary)
        FlowLayout(spacing: 8) {
            ForEach(UltimateXPlayCount.allCases) { count in
                SelectionChip(
                    title: count.displayName,
                    isSelected: ultimateXPlayCount == count
                ) {
                    ultimateXPlayCount = count
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
```

- [ ] **Step 6: Add variant and play count sections to portrait and landscape layouts**

In `portraitLayout`, add after `quizSizeSection`:

```swift
variantSection
if isUltimateXMode {
    playCountSection
}
```

In `landscapeLayout`, in the right column `VStack`, add after `quizSizeSection`:

```swift
Spacer(minLength: 8)
variantSection
if isUltimateXMode {
    playCountSection
    Spacer(minLength: 8)
}
```

- [ ] **Step 7: Update the start quiz button action to pass new params**

Replace:
```swift
navigationPath.append(AppScreen.quizPlay(
    paytableId: selectedPaytable.id,
    weakSpotsMode: weakSpotsMode,
    quizSize: selectedQuizSize
))
```

With:
```swift
navigationPath.append(AppScreen.quizPlay(
    paytableId: selectedPaytable.id,
    weakSpotsMode: weakSpotsMode,
    quizSize: selectedQuizSize,
    isUltimateXMode: isUltimateXMode,
    playCount: ultimateXPlayCount
))
```

- [ ] **Step 8: Build — expect BUILD SUCCEEDED**

```bash
xcodebuild build -scheme VideoPokerAcademy \
  -destination 'platform=iOS Simulator,id=E03325C2-ADAF-4036-B8E1-E9972F1BCDCC' \
  2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

- [ ] **Step 9: Add multiplier badge to `QuizPlayView`**

In `QuizPlayView.swift`, `QuizViewModel` needs to expose `isUltimateXMode` and the current hand's multiplier. Add a computed property to `QuizViewModel`:

```swift
/// Multiplier display string for the current hand (UX mode only)
var currentMultiplierDisplay: String? {
    guard isUltimateXMode, let hand = currentHand else { return nil }
    return String(format: "%.0f×", hand.currentMultiplier)
}
```

In `QuizPlayView`, add a `multiplierBadge` computed property:

```swift
@ViewBuilder
private var multiplierBadge: some View {
    if let display = viewModel.currentMultiplierDisplay {
        Text(display)
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundColor(Color(hex: "FFD700"))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(hex: "FFD700").opacity(0.15))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(hex: "FFD700").opacity(0.4), lineWidth: 1)
            )
    }
}
```

In `cardsAreaView(geometry:)`, add the badge inside the `ZStack`, above the cards (between the dealt winner overlay and the cards). Add a `VStack` at the top:

```swift
// Multiplier badge (UX mode only)
VStack {
    if viewModel.isUltimateXMode, let display = viewModel.currentMultiplierDisplay {
        HStack {
            Spacer()
            Text(display)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "FFD700"))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(hex: "FFD700").opacity(0.15))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(hex: "FFD700").opacity(0.4), lineWidth: 1)
                )
            Spacer()
        }
        .padding(.top, 8)
    }
    Spacer()
}
```

Do the same in `landscapeCardsArea()` — add above the `Spacer()` that precedes the cards row.

- [ ] **Step 10: Add UX EV table in feedback**

In `evOptionsTable(for:)`, replace the entire function with a version that shows UX data when available:

```swift
private func evOptionsTable(for quizHand: QuizHand) -> some View {
    if viewModel.isUltimateXMode, let uxResult = quizHand.uxResult {
        return AnyView(uxEvOptionsTable(for: quizHand, uxResult: uxResult))
    } else {
        return AnyView(baseEvOptionsTable(for: quizHand))
    }
}
```

Extract the existing logic into `baseEvOptionsTable(for:)` (just rename `evOptionsTable` body). Add `uxEvOptionsTable(for:uxResult:)`:

```swift
private func uxEvOptionsTable(for quizHand: QuizHand, uxResult: UltimateXStrategyResult) -> some View {
    let holdOpts = uxResult.holdOptions(for: quizHand.hand)
    let userCanonicalHold = quizHand.hand.originalIndicesToCanonical(quizHand.userHoldIndices)
    let userBitmask = Hand.bitmaskFromHoldIndices(userCanonicalHold)

    return VStack(spacing: 8) {
        // Table header
        HStack {
            Text("Rank")
                .font(.caption).fontWeight(.bold)
                .frame(width: 40, alignment: .leading)
            Text("Hold")
                .font(.caption).fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Adj EV")
                .font(.caption).fontWeight(.bold)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Color(.systemGray5)).cornerRadius(8)

        // Rows (up to 15)
        VStack(spacing: 4) {
            ForEach(Array(holdOpts.prefix(15).enumerated()), id: \.offset) { index, option in
                let optionCards = option.holdIndices.map { quizHand.hand.cards[$0] }
                let isBest = index == 0
                let isUserSelection = option.id == userBitmask

                HStack(spacing: 8) {
                    Text("\(uxResult.rankForAdjustedOption(at: index))")
                        .font(.subheadline)
                        .fontWeight(isBest ? .bold : .regular)
                        .frame(width: 40, alignment: .leading)

                    if optionCards.isEmpty {
                        Text("Discard All")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        HStack(spacing: 4) {
                            ForEach(optionCards, id: \.id) { card in
                                Text("\(card.rank.display)\(card.suit.code)")
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundColor(card.suit == .hearts || card.suit == .diamonds ? .red : .primary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Text(String(format: "%.3f", option.adjustedEV))
                        .font(.system(size: 13, design: .monospaced))
                        .frame(width: 70, alignment: .trailing)
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(
                    isBest ? Color.green.opacity(0.15) :
                    isUserSelection ? Color.orange.opacity(0.15) :
                    Color(.systemGray6)
                )
                .cornerRadius(6)
            }
        }
    }
}
```

- [ ] **Step 11: Build and run all tests**

```bash
xcodebuild build -scheme VideoPokerAcademy \
  -destination 'platform=iOS Simulator,id=E03325C2-ADAF-4036-B8E1-E9972F1BCDCC' \
  2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
xcodebuild test -scheme VideoPokerAcademy \
  -destination 'platform=iOS Simulator,id=E03325C2-ADAF-4036-B8E1-E9972F1BCDCC' \
  2>&1 | grep -E "error:|FAILED|Test Suite.*passed|Test Suite.*failed" | tail -10
```

---

## Task 3: Simulation — Models & ViewModel

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/SimulationModels.swift`
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/SimulationViewModel.swift`

### Background
`SimulationConfig` is a simple struct with no UX fields. `SimulationViewModel.runSingleSimulation()` always uses base strategy and applies no multipliers to payouts. For UX mode, we need per-line multiplier arrays that update each hand, and `betPerHand` must double.

**Performance decision:** `UltimateXStrategyService.lookup()` is slow (~100ms per hand) because it enumerates draw outcomes. In simulation with 1000 hands per run, calling it every hand would take ~100 seconds per run. Therefore, we use **base strategy** for hold decisions in simulation UX mode — strategy only differs meaningfully when multiplier is high, which is a small fraction of hands. The simulation still correctly shows UX-mode return% because multipliers are applied to payouts.

- [ ] **Step 1: Write failing test**

Add to `UltimateXQuizTests.swift` (or create `UltimateXSimulationTests.swift` — create a new file):

Create `VideoPokerAcademyTests/UltimateXSimulationTests.swift`:

```swift
import Testing
import Foundation
@testable import VideoPokerAcademy

@Suite("Ultimate X Simulation Tests")
struct UltimateXSimulationTests {

    @Test("SimulationConfig defaults: isUltimateXMode = false")
    func testSimulationConfigDefaults() {
        let config = SimulationConfig.default
        #expect(config.isUltimateXMode == false)
        #expect(config.playCount == .ten)
    }

    @Test("SimulationConfig totalWagered doubles in UX mode")
    func testSimulationConfigTotalWageredUX() {
        let standard = SimulationConfig(
            paytableId: PayTable.jacksOrBetter96.id,
            denomination: .quarter,
            linesPerHand: 10,
            handsPerSimulation: 100,
            numberOfSimulations: 1,
            isUltimateXMode: false,
            playCount: .ten
        )
        let ux = SimulationConfig(
            paytableId: PayTable.jacksOrBetter96.id,
            denomination: .quarter,
            linesPerHand: 10,
            handsPerSimulation: 100,
            numberOfSimulations: 1,
            isUltimateXMode: true,
            playCount: .ten
        )
        // UX bet is 2× standard (10 coins/line vs 5 coins/line)
        #expect(abs(ux.totalWagered - standard.totalWagered * 2) < 0.001)
    }

    @MainActor
    @Test("SimulationViewModel stores UX config vars")
    func testSimulationViewModelUXVars() {
        let vm = SimulationViewModel()
        #expect(vm.isUltimateXMode == false)
        #expect(vm.ultimateXPlayCount == .ten)
        vm.isUltimateXMode = true
        vm.ultimateXPlayCount = .three
        #expect(vm.isUltimateXMode == true)
        #expect(vm.ultimateXPlayCount == .three)
    }
}
```

- [ ] **Step 2: Run test — expect to fail** (new fields don't exist yet)

```bash
xcodebuild test -scheme VideoPokerAcademy \
  -destination 'platform=iOS Simulator,id=E03325C2-ADAF-4036-B8E1-E9972F1BCDCC' \
  -only-testing:VideoPokerAcademyTests/UltimateXSimulationTests 2>&1 | grep -E "error:|FAILED|passed|failed"
```

- [ ] **Step 3: Update `SimulationConfig` in `SimulationModels.swift`**

Add fields and update `totalWagered`:

```swift
struct SimulationConfig {
    var paytableId: String
    var denomination: BetDenomination
    var linesPerHand: Int
    var handsPerSimulation: Int
    var numberOfSimulations: Int
    var isUltimateXMode: Bool = false          // NEW
    var playCount: UltimateXPlayCount = .ten   // NEW

    static let `default` = SimulationConfig(
        paytableId: PayTable.jacksOrBetter96.id,
        denomination: .quarter,
        linesPerHand: 10,
        handsPerSimulation: 1000,
        numberOfSimulations: 100
    )

    var totalHands: Int {
        handsPerSimulation * numberOfSimulations * linesPerHand
    }

    var totalWagered: Double {
        let coinsPerLine = isUltimateXMode ? 10 : 5  // UX: 2 coins/credit → 10 total
        let betPerHand = Double(coinsPerLine * linesPerHand) * denomination.rawValue
        return betPerHand * Double(handsPerSimulation * numberOfSimulations)
    }
}
```

- [ ] **Step 4: Add UX config vars to `SimulationViewModel`**

After `@Published var selectedNumSims: Int = 100`, add:

```swift
@Published var isUltimateXMode: Bool = false
@Published var ultimateXPlayCount: UltimateXPlayCount = .ten
```

- [ ] **Step 5: Run tests — expect passing**

```bash
xcodebuild test -scheme VideoPokerAcademy \
  -destination 'platform=iOS Simulator,id=E03325C2-ADAF-4036-B8E1-E9972F1BCDCC' \
  -only-testing:VideoPokerAcademyTests/UltimateXSimulationTests 2>&1 | grep -E "error:|FAILED|passed|failed"
```

- [ ] **Step 6: Pass UX config to `SimulationConfig` in `startSimulation()`**

In `startSimulation()`, update the config construction:

```swift
config = SimulationConfig(
    paytableId: selectedPaytableId,
    denomination: selectedDenomination,
    linesPerHand: selectedLinesPerHand,
    handsPerSimulation: selectedHandsPerSim,
    numberOfSimulations: selectedNumSims,
    isUltimateXMode: isUltimateXMode,
    playCount: ultimateXPlayCount
)
```

Also update `totalWageredSummary` and `configSummary` computed properties to use `config`-based calculation. The `configSummary` currently computes its own bet — update `totalWageredSummary` to delegate to `SimulationConfig.totalWagered`:

```swift
var totalWageredSummary: String {
    // Build a preview config from current selections to get the right bet
    let previewConfig = SimulationConfig(
        paytableId: selectedPaytableId,
        denomination: selectedDenomination,
        linesPerHand: selectedLinesPerHand,
        handsPerSimulation: selectedHandsPerSim,
        numberOfSimulations: selectedNumSims,
        isUltimateXMode: isUltimateXMode,
        playCount: ultimateXPlayCount
    )
    return formatCurrency(previewConfig.totalWagered) + " total wagered"
}
```

- [ ] **Step 7: Update `runSingleSimulation()` with UX multiplier chain**

In `runSingleSimulation(runNumber:paytableId:denomination:linesPerHand:handsPerSimulation:)`, add `isUltimateX: Bool` and `playCount: UltimateXPlayCount` parameters:

```swift
private func runSingleSimulation(
    runNumber: Int,
    paytableId: String,
    denomination: BetDenomination,
    linesPerHand: Int,
    handsPerSimulation: Int,
    isUltimateX: Bool,
    playCount: UltimateXPlayCount
) async -> SimulationRun {
```

In the function body, at the top before the `bankroll` var:

```swift
// UX: each line maintains its own multiplier state across hands
var lineMultipliers = Array(repeating: 1, count: linesPerHand)

// UX: bet is 2× coins per line (10 coins vs 5 for standard)
let coinsPerLine = isUltimateX ? 10 : 5
let betPerHand = Double(coinsPerLine * linesPerHand) * denomination.rawValue
```

Remove the existing `let betPerHand = Double(5 * linesPerHand) * denomination.rawValue` line.

In the inner `for _ in 0..<linesPerHand` loop, replace:

```swift
// OLD:
let result = evaluateHand(finalHand, paytableId: paytableId)
let payoutCredits = result.payout
let payoutDollars = Double(payoutCredits) * denomination.rawValue

// NEW:
let result = evaluateHand(finalHand, paytableId: paytableId)
let lineMultiplier = isUltimateX ? lineMultipliers[lineIdx] : 1
let payoutCredits = result.payout * lineMultiplier
let payoutDollars = Double(payoutCredits) * denomination.rawValue
```

Note: rename the loop variable from `_` to `lineIdx` to access the index:
```swift
for lineIdx in 0..<linesPerHand {
```

After `lineWinnings += payoutDollars`, add:

```swift
// UX: update this line's multiplier for next hand
if isUltimateX {
    let family = PayTable.allPayTables.first(where: { $0.id == paytableId })?.family ?? .jacksOrBetter
    lineMultipliers[lineIdx] = UltimateXMultiplierTable.multiplier(
        for: result.handName ?? "",
        playCount: playCount,
        family: family
    )
}
```

- [ ] **Step 8: Update the `simulationTask` call in `startSimulation()` to pass UX params**

In the `Task.detached` closure inside `startSimulation()`, add the new params to `runSingleSimulation`:

```swift
let run = await self?.runSingleSimulation(
    runNumber: runNum,
    paytableId: paytableId,
    denomination: denomination,
    linesPerHand: linesPerHand,
    handsPerSimulation: handsPerSim,
    isUltimateX: config.isUltimateXMode,
    playCount: config.playCount
)
```

Capture the new config values before the `Task.detached` block:
```swift
let isUltimateX = config.isUltimateXMode
let playCount = config.playCount
```

Then pass `isUltimateX: isUltimateX, playCount: playCount` to the call.

- [ ] **Step 9: Build and run all tests**

```bash
xcodebuild build -scheme VideoPokerAcademy \
  -destination 'platform=iOS Simulator,id=E03325C2-ADAF-4036-B8E1-E9972F1BCDCC' \
  2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
xcodebuild test -scheme VideoPokerAcademy \
  -destination 'platform=iOS Simulator,id=E03325C2-ADAF-4036-B8E1-E9972F1BCDCC' \
  2>&1 | grep -E "error:|FAILED|Test Suite.*passed|Test Suite.*failed" | tail -10
```

---

## Task 4: Simulation — UI

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Simulation/SimulationStartView.swift`

### Background
`SimulationStartView` holds a `@StateObject private var viewModel = SimulationViewModel()`. We need to add variant + play count selectors. The existing pattern uses `@Binding` on `viewModel` properties.

Note: `SimulationResultsView` doesn't need changes — return% is already calculated as `totalWon / totalBet`, which naturally reflects the 2× bet in UX mode.

- [ ] **Step 1: Add variant and play count sections to `SimulationStartView`**

Add a `variantSection` view:

```swift
private var variantSection: some View {
    VStack(alignment: .leading, spacing: 8) {
        Text("Variant")
            .font(.subheadline)
            .foregroundColor(.secondary)

        HStack(spacing: 8) {
            Button {
                viewModel.isUltimateXMode = false
            } label: {
                Text("Standard")
                    .font(.subheadline).fontWeight(.medium)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.Colors.simulation)
            .opacity(!viewModel.isUltimateXMode ? 1.0 : 0.5)
            .background(!viewModel.isUltimateXMode ? AppTheme.Colors.simulation.opacity(0.15) : Color.clear)
            .cornerRadius(8)

            Button {
                viewModel.isUltimateXMode = true
            } label: {
                Text("Ult X")
                    .font(.subheadline).fontWeight(.medium)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.Colors.simulation)
            .opacity(viewModel.isUltimateXMode ? 1.0 : 0.5)
            .background(viewModel.isUltimateXMode ? AppTheme.Colors.simulation.opacity(0.15) : Color.clear)
            .cornerRadius(8)
        }
    }
}
```

Add a `playCountSection` view (only shown in UX mode):

```swift
private var playCountSection: some View {
    VStack(alignment: .leading, spacing: 8) {
        Text("Play Count")
            .font(.subheadline)
            .foregroundColor(.secondary)

        HStack(spacing: 8) {
            ForEach(UltimateXPlayCount.allCases) { count in
                Button {
                    viewModel.ultimateXPlayCount = count
                } label: {
                    Text(count.displayName)
                        .font(.subheadline).fontWeight(.medium)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.Colors.simulation)
                .opacity(viewModel.ultimateXPlayCount == count ? 1.0 : 0.5)
                .background(viewModel.ultimateXPlayCount == count ? AppTheme.Colors.simulation.opacity(0.15) : Color.clear)
                .cornerRadius(8)
            }
        }
    }
}
```

- [ ] **Step 2: Insert sections into the configuration VStack**

In the `body`, inside the main `VStack(spacing: 20)` that holds the configuration options, add after the "Lines per Hand" section:

```swift
// Variant selector
variantSection

// Play count (UX only)
if viewModel.isUltimateXMode {
    playCountSection
}
```

- [ ] **Step 3: Build**

```bash
xcodebuild build -scheme VideoPokerAcademy \
  -destination 'platform=iOS Simulator,id=E03325C2-ADAF-4036-B8E1-E9972F1BCDCC' \
  2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Run all tests**

```bash
xcodebuild test -scheme VideoPokerAcademy \
  -destination 'platform=iOS Simulator,id=E03325C2-ADAF-4036-B8E1-E9972F1BCDCC' \
  2>&1 | grep -E "error:|FAILED|Test Suite.*passed|Test Suite.*failed" | tail -10
```

- [ ] **Step 5: Boot simulator and visual check**

```bash
# Boot and launch simulator
xcrun simctl boot E03325C2-ADAF-4036-B8E1-E9972F1BCDCC 2>/dev/null || true
xcodebuild build -scheme VideoPokerAcademy \
  -destination 'platform=iOS Simulator,id=E03325C2-ADAF-4036-B8E1-E9972F1BCDCC' \
  -configuration Debug 2>&1 | tail -5
# Install and launch
xcrun simctl install booted "$(find ~/Library/Developer/Xcode/DerivedData -name 'VideoPokerAcademy.app' -path '*/Debug-iphonesimulator/*' | head -1)"
xcrun simctl launch booted com.bunchbunchbunch.VideoPokerAcademy
# Take screenshot (wait a moment for launch)
sleep 3
xcrun simctl io booted screenshot /tmp/sim_check.png
open /tmp/sim_check.png
```

Verify:
- Quiz start screen shows Variant selector below Quiz Size
- Simulation start screen shows Variant selector below Lines per Hand
- Selecting "Ult X" reveals Play Count chips
- Quiz feedback table shows adjusted EVs in UX mode

---

## Testing Checklist

After all 4 tasks are complete, verify these behaviors manually:

**Quiz UX mode:**
- [ ] Gold multiplier badge appears on the felt area for each quiz hand
- [ ] Correct/Incorrect grading uses UX-optimal hold (not base strategy)
- [ ] EV Lost shows adjusted EV difference
- [ ] Feedback EV table shows "Adj EV" column with UX-adjusted values, green = best hold, orange = user's hold
- [ ] Changing play count (3/5/10/100) is passed through to quiz

**Simulation UX mode:**
- [ ] "Ult X" variant button visible in SimulationStartView
- [ ] Total Wagered summary shows 2× amount vs standard (same game, same config, UX shows double)
- [ ] Simulation runs without crashing (try small: 10 hands/sim × 1 sim × 1 line)
- [ ] Return% result is in the expected range for the game (for JoB 9/6 UX, expect ~99.5-100.5% RTP over enough hands)
