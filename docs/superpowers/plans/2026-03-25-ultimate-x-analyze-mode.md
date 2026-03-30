# Ultimate X Analyze Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an `AnalyzerStartView` start screen and full Ultimate X strategy display to Analyze mode, with a corrected EV formula using `HoldOutcomeCalculator`.

**Architecture:** `AnalyzerStartView` (mirrors PlayStartView style) lets the user pick game + Standard/Ult X + multiplier (1-12) + play count, then navigates to `HandAnalyzerView` via `navigationPath.append(viewModel)` (same pattern as `SimulationStartView`). `UltimateXStrategyService` is fixed to use `multiplier × 2.0 × baseEV + eKAwarded - 1.0` via `HoldOutcomeCalculator`. `HandAnalyzerView` shows a 4-column UX results table when UX mode is active.

**Tech Stack:** SwiftUI, Swift 6 strict concurrency, @Observable / ObservableObject, `NavigationPath`, `HoldOutcomeCalculator` (actor), `UltimateXStrategyService` (actor).

---

## File Map

| File | Change |
|------|--------|
| `Models/UltimateXModels.swift` | Add `holdEKs: [String: Double]` to `UltimateXStrategyResult`; add `holdOptions(for:)` helper |
| `Services/UltimateXStrategyService.swift` | Fix formula: use `HoldOutcomeCalculator`; remove wrong shortcut for multiplier=1 |
| `Views/Play/UltimateXStrategyPanel.swift` | No change (analyzer builds its own results table inline) |
| `ViewModels/AnalyzerViewModel.swift` | Add `Hashable` conformance (object identity) |
| `Views/Analyzer/HandAnalyzerView.swift` | Change `@StateObject` → `@ObservedObject`, add `init(viewModel:)`, add `uxResultsView` |
| `Views/Home/HomeView.swift` | Change `.analyzer` destination to `AnalyzerStartView`; add `navigationDestination(for: AnalyzerViewModel.self)` |
| `Views/Analyzer/AnalyzerStartView.swift` | **CREATE** — game selector, variant chips, multiplier stepper, play count chips, navigate button |
| `VideoPokerAcademyTests/UltimateXStrategyServiceTests.swift` | **CREATE** — tests for `UltimateXStrategyResult` model + formula |

---

## Context for Implementers

**Key formula** (correct):
```
adjustedEV = Double(currentMultiplier) × 2.0 × baseEV + eKAwarded - 1.0
```
- `currentMultiplier` = multiplier active on THIS hand (user-entered in analyzer; avg of lines in play mode)
- `2.0` = UX costs 2 coins per line, so all EVs scale by 2
- `eKAwarded` = E[K] = expected multiplier this hold awards for NEXT hand, computed by `HoldOutcomeCalculator`
- `-1.0` = normalize to net EV per 1-coin-equivalent

**What was wrong** in `UltimateXStrategyService`: `2.0 * baseEV + Double(multiplier - 1)` adds a *constant* to all holds, so ranking never differs from base EV. The correct formula multiplies `baseEV` by the multiplier, which makes high-EV holds even more attractive at higher multipliers. Rankings change when `eKAwarded` varies between holds (e.g., holds that tend to produce winning hands award better multipliers for next hand).

**`HoldOutcomeCalculator` performance**:
- bitmask=0 (draw all): uses pre-computed table, instant
- 1-card holds: uses pre-computed table, instant
- 2-card holds: C(47,3)=16,215 combos per bitmask — fast
- 3+ card holds: ≤C(47,2)=1,081 combos — very fast

Total for 32 bitmasks: acceptable for analyzer (completes in <1s).

**Navigation pattern** (matches `SimulationStartView`):
```swift
// AnalyzerStartView
navigationPath.append(viewModel)  // viewModel: AnalyzerViewModel

// HomeView
.navigationDestination(for: AnalyzerViewModel.self) { vm in
    HandAnalyzerView(viewModel: vm)
}
```

**SourceKit false positives**: "Cannot find type X in scope" IDE errors appear after edits. They are NOT real — builds always pass. Do not chase IDE errors that disappear on build.

---

## Task 1: Fix Formula in `UltimateXStrategyService` + Extend Result Model

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/UltimateXModels.swift`
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Services/UltimateXStrategyService.swift`
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/UltimateXStrategyServiceTests.swift`

- [ ] **Step 1: Write failing test for model formula**

Create `UltimateXStrategyServiceTests.swift`:

```swift
import Testing
@testable import VideoPokerAcademy

struct UltimateXStrategyServiceTests {

    // Test that UltimateXStrategyResult.holdOptions(for:) correctly reconstructs hold options
    // and that the formula adjustedEV = multiplier * 2.0 * baseEV + eKAwarded - 1.0 holds.
    @Test("holdOptions correctly reconstructs from holdEKs")
    func holdOptionsReconstructsCorrectly() throws {
        // Build a minimal StrategyResult
        let baseResult = StrategyResult(
            bestHold: 31,
            bestEv: 0.8,
            holdEvs: ["31": 0.8, "0": 0.35, "15": 0.6]
        )
        // Compute expected adjustedEVs manually:
        // bitmask 31: multiplier=3, baseEV=0.8, eK=1.5 → 3*2.0*0.8 + 1.5 - 1.0 = 5.3
        // bitmask 15: multiplier=3, baseEV=0.6, eK=1.2 → 3*2.0*0.6 + 1.2 - 1.0 = 3.8
        // bitmask  0: multiplier=3, baseEV=0.35, eK=1.0 → 3*2.0*0.35 + 1.0 - 1.0 = 2.1
        let uxResult = UltimateXStrategyResult(
            baseResult: baseResult,
            currentMultiplier: 3,
            playCount: .ten,
            adjustedBestHold: 31,
            adjustedBestEv: 5.3,
            adjustedHoldEvs: ["31": 5.3, "15": 3.8, "0": 2.1],
            holdEKs: ["31": 1.5, "15": 1.2, "0": 1.0]
        )
        let hand = Hand(cards: [
            Card(rank: .ace,   suit: .spades),
            Card(rank: .king,  suit: .spades),
            Card(rank: .queen, suit: .spades),
            Card(rank: .jack,  suit: .spades),
            Card(rank: .ten,   suit: .clubs),
        ])

        let options = uxResult.holdOptions(for: hand)

        // Sorted descending by adjustedEV
        #expect(options.count == 3)
        #expect(options[0].adjustedEV == 5.3)
        #expect(options[0].eKAwarded == 1.5)
        #expect(options[0].baseEV == 0.8)

        // Formula check for every option
        for opt in options {
            let expected = 3.0 * 2.0 * opt.baseEV + opt.eKAwarded - 1.0
            #expect(abs(opt.adjustedEV - expected) < 0.001)
        }
    }

    @Test("strategyDiffers is true when adjustedBestHold != baseResult.bestHold")
    func strategyDiffersWhenHoldChanges() throws {
        let baseResult = StrategyResult(bestHold: 31, bestEv: 0.8, holdEvs: ["31": 0.8, "15": 0.9])
        let uxResult = UltimateXStrategyResult(
            baseResult: baseResult,
            currentMultiplier: 5,
            playCount: .ten,
            adjustedBestHold: 15,   // different from base best (31)
            adjustedBestEv: 8.0,
            adjustedHoldEvs: ["31": 7.0, "15": 8.0],
            holdEKs: ["31": 1.0, "15": 1.1]
        )
        #expect(uxResult.strategyDiffers == true)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mcp__xcodebuildmcp__test_sim_name_proj` with scheme `VideoPokerAcademy`
Expected: FAIL — `UltimateXStrategyResult` init doesn't accept `holdEKs` parameter yet

- [ ] **Step 3: Add `holdEKs` to `UltimateXStrategyResult` in `UltimateXModels.swift`**

Find `struct UltimateXStrategyResult` (around line 273). Add the new field and helper method:

```swift
struct UltimateXStrategyResult {
    let baseResult: StrategyResult
    let currentMultiplier: Int
    let playCount: UltimateXPlayCount
    let adjustedBestHold: Int
    let adjustedBestEv: Double
    let adjustedHoldEvs: [String: Double]
    let holdEKs: [String: Double]   // ADD THIS: E[K_awarded] per hold bitmask string key

    // ... existing computed properties unchanged ...

    /// Build UltimateXHoldOption array sorted by adjustedEV, with original-position hold indices.
    /// Use this in views that need per-hold baseEV and eKAwarded for display.
    func holdOptions(for hand: Hand) -> [UltimateXHoldOption] {
        sortedAdjustedHoldOptions.compactMap { item in
            guard let baseEV = baseResult.holdEvs[String(item.bitmask)],
                  let eK = holdEKs[String(item.bitmask)] else { return nil }
            let originalIndices = hand.canonicalIndicesToOriginal(item.indices).sorted()
            return UltimateXHoldOption(
                id: item.bitmask,
                holdIndices: originalIndices,
                baseEV: baseEV,
                eKAwarded: eK,
                adjustedEV: item.ev
            )
        }
    }
}
```

**Important**: The `holdEKs` field is new. The only place `UltimateXStrategyResult` is constructed is in `UltimateXStrategyService.swift` (two call sites in the `lookup()` method). Both must be updated in Step 4.

- [ ] **Step 4: Fix formula in `UltimateXStrategyService.swift`**

Replace the entire `lookup()` method body. The current method has two problems:
1. A `if currentMultiplier == 1 { ... }` shortcut that returns wrong data (ignores eKAwarded entirely)
2. The formula `2.0 * baseEV + Double(multiplier - 1)` adds a constant, never changes ranking

New `lookup()`:

```swift
func lookup(
    hand: Hand,
    paytableId: String,
    currentMultiplier: Int,
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
        // Correct formula: adjustedEV = multiplier × 2.0 × baseEV + eKAwarded - 1.0
        // - multiplier × 2.0 × baseEV: scales base return by multiplier (UX bets 2 coins)
        // - eKAwarded: expected multiplier awarded for NEXT hand from this hold
        // - -1.0: normalize to net EV per coin-equivalent
        let adjustedEv = Double(currentMultiplier) * 2.0 * baseEv + eK - 1.0
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
```

Also **delete** the private `calculateAdjustedEv(baseEv:multiplier:)` method — it's no longer used.

- [ ] **Step 5: Build to verify compilation**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Run tests**

Run: `mcp__xcodebuildmcp__test_sim_name_proj`
Expected: All tests pass including the new `UltimateXStrategyServiceTests`

---

## Task 2: Make `AnalyzerViewModel` Hashable + Update `HandAnalyzerView`

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/AnalyzerViewModel.swift`
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Analyzer/HandAnalyzerView.swift`

### Part A: AnalyzerViewModel Hashable

- [ ] **Step 1: Add Hashable conformance to AnalyzerViewModel**

At the bottom of `AnalyzerViewModel.swift`, after the class definition, add:

```swift
// MARK: - Hashable (object identity — required for NavigationPath.append)
extension AnalyzerViewModel: Hashable {
    static func == (lhs: AnalyzerViewModel, rhs: AnalyzerViewModel) -> Bool {
        lhs === rhs
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
```

### Part B: HandAnalyzerView updates

`HandAnalyzerView` currently has `@StateObject private var viewModel = AnalyzerViewModel()`. We need it to accept an externally-created viewmodel (so `AnalyzerStartView` can configure and pass one in), while keeping the same game-selector UI.

- [ ] **Step 2: Change `@StateObject` to `@ObservedObject` and add init**

In `HandAnalyzerView.swift`:

Change:
```swift
@StateObject private var viewModel = AnalyzerViewModel()
@Environment(\.dismiss) private var dismiss
@State private var selectedFamily: GameFamily = (PayTable.allPayTables.first(where: { $0.id == PayTable.lastSelectedId }) ?? PayTable.jacksOrBetter96).family
@State private var selectedPaytableId: String = PayTable.lastSelectedId
```

To:
```swift
@ObservedObject var viewModel: AnalyzerViewModel
@Environment(\.dismiss) private var dismiss
@State private var selectedFamily: GameFamily
@State private var selectedPaytableId: String

init(viewModel: AnalyzerViewModel) {
    self.viewModel = viewModel
    let paytableId = viewModel.selectedPaytable.id
    _selectedPaytableId = State(initialValue: paytableId)
    _selectedFamily = State(initialValue: viewModel.selectedPaytable.family)
}
```

Also update the `#Preview` at the bottom:
```swift
#Preview {
    NavigationStack {
        HandAnalyzerView(viewModel: AnalyzerViewModel())
    }
}
```

Also update the `.onAppear` block — it currently syncs from `PayTable.lastSelectedId`. Change it to use the viewmodel's paytable instead:
```swift
.onAppear {
    let vmPaytableId = viewModel.selectedPaytable.id
    if selectedPaytableId != vmPaytableId {
        selectedPaytableId = vmPaytableId
        selectedFamily = viewModel.selectedPaytable.family
    }
}
```

- [ ] **Step 3: Add `uxResultsView` method**

Add a new private method to `HandAnalyzerView`. Place it near the existing `resultsTable` method (around line 897):

```swift
// MARK: - Ultimate X Results View

private func uxResultsView(hand: Hand, uxResult: UltimateXStrategyResult) -> some View {
    let holdOptions = uxResult.holdOptions(for: hand)

    return ScrollView {
        VStack(spacing: 12) {
            // Header: multiplier + play count badges
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "multiply.circle.fill")
                        .foregroundColor(Color(hex: "FFD700"))
                    Text("\(uxResult.currentMultiplier)× multiplier")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "FFD700"))
                }
                Text("·")
                    .foregroundColor(.secondary)
                Text(uxResult.playCount.displayName)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Spacer()
                if uxResult.strategyDiffers {
                    Label("Strategy changed!", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray5))
            .cornerRadius(8)

            // Best UX hold summary
            VStack(spacing: 8) {
                Text("Best UX Hold")
                    .font(.headline)
                    .foregroundColor(.secondary)

                let bestHoldOriginal = hand.canonicalIndicesToOriginal(uxResult.adjustedBestHoldIndices)
                HStack(spacing: 6) {
                    if bestHoldOriginal.isEmpty {
                        Text("Draw all 5 cards")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(bestHoldOriginal, id: \.self) { index in
                            Text(hand.cards[index].displayText)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(hand.cards[index].suit.color)
                        }
                    }
                }

                Text("Score: \(String(format: "%.4f", uxResult.adjustedBestEv))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "27ae60"))
            }
            .padding()
            .background(Color(hex: "667eea").opacity(0.1))
            .cornerRadius(12)

            // All hold options: 4-column table
            VStack(spacing: 8) {
                // Column headers
                HStack {
                    Text("Rank")
                        .font(.caption).fontWeight(.bold)
                        .frame(width: 40, alignment: .leading)
                    Text("Hold")
                        .font(.caption).fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Base")
                        .font(.caption).fontWeight(.bold)
                        .frame(width: 52, alignment: .trailing)
                    Text("E[K]")
                        .font(.caption).fontWeight(.bold)
                        .frame(width: 44, alignment: .trailing)
                    Text("Score")
                        .font(.caption).fontWeight(.bold)
                        .frame(width: 52, alignment: .trailing)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .cornerRadius(8)

                // Rows (show top 15 sorted by adjustedEV)
                VStack(spacing: 4) {
                    ForEach(Array(holdOptions.prefix(15).enumerated()), id: \.offset) { index, option in
                        let rank = index + 1
                        let isBest = rank == 1
                        let optionCards = option.holdIndices.map { hand.cards[$0] }

                        HStack {
                            Text("\(rank)")
                                .font(.subheadline)
                                .fontWeight(isBest ? .bold : .regular)
                                .frame(width: 40, alignment: .leading)

                            if optionCards.isEmpty {
                                Text("Draw all")
                                    .font(.subheadline)
                                    .italic()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                HStack(spacing: 4) {
                                    ForEach(optionCards, id: \.id) { card in
                                        Text(card.displayText)
                                            .font(.subheadline)
                                            .foregroundColor(card.suit.color)
                                            .fontWeight(isBest ? .bold : .regular)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Text(String(format: "%.3f", option.baseEV))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 52, alignment: .trailing)

                            Text(String(format: "%.2f×", option.eKAwarded))
                                .font(.caption)
                                .foregroundColor(Color(hex: "FFD700").opacity(0.85))
                                .frame(width: 44, alignment: .trailing)

                            Text(String(format: "%.3f", option.adjustedEV))
                                .font(.subheadline)
                                .fontWeight(isBest ? .bold : .regular)
                                .frame(width: 52, alignment: .trailing)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isBest ? Color(hex: "667eea").opacity(0.2) : Color(.systemGray6))
                        .cornerRadius(6)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .padding()
    }
    .background(Color(.systemBackground))
}
```

- [ ] **Step 4: Update portrait layout to show UX results when active**

In `portraitLayout`, find the results section (around line 91):
```swift
if viewModel.showResults, let hand = viewModel.hand, let result = viewModel.strategyResult {
    Divider()
    resultsTable(hand: hand, result: result)
        .tourTarget("resultsTable")
}
```

Replace with:
```swift
if viewModel.showResults, let hand = viewModel.hand {
    Divider()
    if viewModel.isUltimateXMode, let uxResult = viewModel.ultimateXResult {
        uxResultsView(hand: hand, uxResult: uxResult)
            .tourTarget("resultsTable")
    } else if let result = viewModel.strategyResult {
        resultsTable(hand: hand, result: result)
            .tourTarget("resultsTable")
    }
}
```

- [ ] **Step 5: Update landscape layout to show UX results when active**

In `landscapeLayout`, find the results section (around line 296):
```swift
if viewModel.showResults, let hand = viewModel.hand, let result = viewModel.strategyResult {
    resultsTable(hand: hand, result: result)
        .tourTarget("resultsTable")
        .frame(width: geometry.size.width * 0.48)
} else {
    VStack { ... }
    .frame(width: geometry.size.width * 0.48)
}
```

Replace with:
```swift
if viewModel.showResults, let hand = viewModel.hand {
    Group {
        if viewModel.isUltimateXMode, let uxResult = viewModel.ultimateXResult {
            uxResultsView(hand: hand, uxResult: uxResult)
        } else if let result = viewModel.strategyResult {
            resultsTable(hand: hand, result: result)
        }
    }
    .tourTarget("resultsTable")
    .frame(width: geometry.size.width * 0.48)
} else {
    VStack {
        Spacer()
        Text("Select 5 cards")
            .font(.subheadline)
            .foregroundColor(.secondary)
        Spacer()
    }
    .frame(width: geometry.size.width * 0.48)
}
```

- [ ] **Step 6: Build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: BUILD SUCCEEDED. Fix any errors before continuing.

- [ ] **Step 7: Run tests**

Run: `mcp__xcodebuildmcp__test_sim_name_proj`
Expected: All tests pass

---

## Task 3: Create `AnalyzerStartView`

**Files:**
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Analyzer/AnalyzerStartView.swift`

The start screen mirrors `PlayStartView` and `QuizStartView` style. The user selects:
- Popular game shortcuts + All Games dropdown
- Variant: Standard | Ult X chips
- (when Ult X) Multiplier stepper 1-12
- (when Ult X) Play count chips: 3-Play / 5-Play / 10-Play
- "Analyze Hand" button → creates `AnalyzerViewModel`, configures it, appends to `navigationPath`

- [ ] **Step 1: Create the file**

Create `AnalyzerStartView.swift` in `Views/Analyzer/`:

```swift
import SwiftUI

struct AnalyzerStartView: View {
    @Binding var navigationPath: NavigationPath
    @State private var selectedPaytableId: String = PayTable.lastSelectedId
    @State private var isUltimateXMode: Bool = false
    @State private var ultimateXMultiplier: Int = 1
    @State private var ultimateXPlayCount: UltimateXPlayCount = .ten

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            ZStack {
                AppTheme.Gradients.background
                    .ignoresSafeArea()
                if isLandscape {
                    landscapeLayout(geometry: geometry)
                } else {
                    portraitLayout
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Analyze")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Portrait Layout

    private var portraitLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                popularGamesSection
                allGamesSection
                variantSection
                if isUltimateXMode {
                    multiplierSection
                    playCountSection
                }
                Spacer(minLength: 20)
                startButtonSection
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }

    // MARK: - Landscape Layout

    private func landscapeLayout(geometry: GeometryProxy) -> some View {
        let availableHeight = geometry.size.height - 16

        return HStack(alignment: .top, spacing: 20) {
            // Left column: header + game selection + variant
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    compactHeaderSection
                    Spacer(minLength: 10)
                    popularGamesSection
                    Spacer(minLength: 10)
                    allGamesSection
                    Spacer(minLength: 10)
                    variantSection
                    Spacer(minLength: 8)
                }
                .frame(minHeight: availableHeight)
            }
            .frame(width: (geometry.size.width - 48) * 0.55)

            // Right column: UX options + start button
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    if isUltimateXMode {
                        multiplierSection
                        Spacer(minLength: 10)
                        playCountSection
                        Spacer(minLength: 10)
                    }
                    startButtonSection
                    Spacer(minLength: 8)
                }
                .frame(minHeight: availableHeight)
            }
            .frame(width: (geometry.size.width - 48) * 0.45)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Compact Header (landscape)

    private var compactHeaderSection: some View {
        HStack(spacing: 12) {
            Image("chip-blue")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text("Analyze")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text("Find optimal strategy for any hand.")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            Spacer()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 16) {
            Image("chip-blue")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
            VStack(alignment: .leading, spacing: 4) {
                Text("Analyze")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("Find optimal strategy for any hand.")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            Spacer()
        }
    }

    // MARK: - Popular Games

    private var popularGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular Games")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
            FlowLayout(spacing: 8) {
                ForEach(PayTable.popularPaytables, id: \.id) { game in
                    GameChip(title: game.name, isSelected: selectedPaytableId == game.id) {
                        selectedPaytableId = game.id
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - All Games

    private var allGamesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("All Games")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
            GameSelectorView(selectedPaytableId: $selectedPaytableId)
        }
    }

    // MARK: - Variant

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

    // MARK: - Multiplier Stepper

    private var multiplierSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Multiplier")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
            HStack(spacing: 20) {
                Button {
                    if ultimateXMultiplier > 1 { ultimateXMultiplier -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(ultimateXMultiplier > 1 ? AppTheme.Colors.mintGreen : .gray.opacity(0.4))
                }
                .disabled(ultimateXMultiplier <= 1)

                Text("\(ultimateXMultiplier)×")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "FFD700"))
                    .frame(minWidth: 56, alignment: .center)

                Button {
                    if ultimateXMultiplier < 12 { ultimateXMultiplier += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(ultimateXMultiplier < 12 ? AppTheme.Colors.mintGreen : .gray.opacity(0.4))
                }
                .disabled(ultimateXMultiplier >= 12)

                Text("(1–12)")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Play Count

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

    // MARK: - Start Button

    private var startButtonSection: some View {
        VStack(spacing: 12) {
            Button {
                navigateToAnalyzer()
            } label: {
                Text("Analyze Hand")
                    .primaryButton()
            }
            Button("Back to Menu") {
                navigationPath.removeLast()
            }
            .foregroundColor(AppTheme.Colors.mintGreen)
            .underline()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Navigation

    private func navigateToAnalyzer() {
        let vm = AnalyzerViewModel()
        if let paytable = PayTable.allPayTables.first(where: { $0.id == selectedPaytableId }) {
            vm.selectedPaytable = paytable
        }
        vm.isUltimateXMode = isUltimateXMode
        if isUltimateXMode {
            vm.ultimateXMultiplier = ultimateXMultiplier
            vm.ultimateXPlayCount = ultimateXPlayCount
        }
        navigationPath.append(vm)
    }
}

#Preview {
    NavigationStack {
        AnalyzerStartView(navigationPath: .constant(NavigationPath()))
    }
}
```

- [ ] **Step 2: Add the new file to the Xcode project**

The file needs to be added to the Xcode project target. Run a build — if it fails with "no such module" or "file not found" for `AnalyzerStartView`, the file needs to be added to the `.xcodeproj`. Use `mcp__xcodebuildmcp__discover_projects` to find the project, then verify the file is included. In this codebase, new files in the source tree are typically auto-included by the build system if placed in the correct directory. If not, manually add via the project file.

- [ ] **Step 3: Build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: BUILD SUCCEEDED. Fix any compilation errors.

---

## Task 4: Wire Up Navigation in `HomeView`

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Home/HomeView.swift`

- [ ] **Step 1: Add `navigationDestination` for `AnalyzerViewModel`**

In `HomeView.body`, the `NavigationStack` has:
```swift
.navigationDestination(for: AppScreen.self) { screen in
    destinationView(for: screen)
}
.navigationDestination(for: SimulationViewModel.self) { vm in
    SimulationContainerView(viewModel: vm, navigationPath: $navigationPath)
}
```

Add after the `SimulationViewModel` destination:
```swift
.navigationDestination(for: AnalyzerViewModel.self) { vm in
    HandAnalyzerView(viewModel: vm)
}
```

- [ ] **Step 2: Change `.analyzer` destination to `AnalyzerStartView`**

In `destinationView(for:)`, change:
```swift
case .analyzer:
    HandAnalyzerView()
```

To:
```swift
case .analyzer:
    AnalyzerStartView(navigationPath: $navigationPath)
```

- [ ] **Step 3: Build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: BUILD SUCCEEDED. Fix any errors before proceeding.

- [ ] **Step 4: Run all tests**

Run: `mcp__xcodebuildmcp__test_sim_name_proj`
Expected: All tests pass

- [ ] **Step 5: Boot simulator and launch app for visual verification**

```
mcp__xcodebuildmcp__boot_simulator
mcp__xcodebuildmcp__install_app
mcp__xcodebuildmcp__launch_app
mcp__xcodebuildmcp__screenshot
```

Verify:
1. Tapping "Analyze" from home screen shows `AnalyzerStartView` (not the old hand grid)
2. "Standard" chip is selected by default; "Ult X" chip shows multiplier + play count options when selected
3. Tapping "Analyze Hand" navigates to `HandAnalyzerView`
4. Selecting 5 cards in Standard mode shows the existing base EV results table
5. Selecting 5 cards in Ult X mode (after going back and setting UX mode) shows the UX results table with 4 columns: Rank / Hold / Base / E[K] / Score

If any visual issues, capture logs: `mcp__xcodebuildmcp__capture_logs`

---

## Add New File to Xcode Project

**Important**: New `.swift` files added to the `Views/Analyzer/` directory must be registered in the Xcode project file (`VideoPokerAcademy.xcodeproj/project.pbxproj`). The build will fail with "file not found" if not registered.

To add `AnalyzerStartView.swift` to the project:
1. After creating the file, run a build
2. If the build fails because the file is not found in target, look at how other files in `Views/Analyzer/` are registered in `project.pbxproj`
3. Add the file reference following the same pattern (copy an existing entry for `HandAnalyzerView.swift`, change the UUID and filename)

The UUIDs in `project.pbxproj` must be unique 24-hex-character strings. Generate by replacing digits in an existing UUID pattern.
