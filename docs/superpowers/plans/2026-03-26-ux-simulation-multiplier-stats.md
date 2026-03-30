# UX Simulation Multiplier Statistics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Display Ultimate X multiplier statistics (distribution + top 5 biggest multiplied wins) in the simulation results screen when UX mode is active.

**Architecture:** Two new fields on `SimulationRun` (`uxMultiplierDistribution: [Int: Int]` and `uxTopWins: [UXBigWin]`) are populated during `runSingleSimulation()`. `SimulationResults` aggregates them across runs. A new collapsible "ULTIMATE X MULTIPLIERS" section in `SimulationResultsView` shows a multiplier frequency chart and a top-wins ranked list — both gated on `config.isUltimateXMode`.

**Tech Stack:** Swift 6, SwiftUI Charts, `@MainActor` ObservableObject

---

## Key Concepts for Implementers

### What to track per line-hand

In `runSingleSimulation()`, inside the `for lineIdx in 0..<linesPerHand` loop, `lineMultiplier` is already computed:
```swift
let lineMultiplier = isUltimateX ? lineMultipliers[lineIdx] : 1
```

This is the multiplier that was *active* for this line on this hand (i.e., the one being applied to the payout). Track it after `payoutDollars` is computed.

### UXBigWin struct

```swift
struct UXBigWin: Equatable {
    let handName: String   // e.g., "Royal Flush"
    let multiplier: Int    // e.g., 12
    let payoutDollars: Double  // e.g., 9375.0
}
```

### Keeping top 5 efficiently

Append, sort descending by `payoutDollars`, trim to 5. This runs at most ~5 sorts per run, so performance is irrelevant.

```swift
run.uxTopWins.append(UXBigWin(handName: handName, multiplier: lineMultiplier, payoutDollars: payoutDollars))
run.uxTopWins.sort { $0.payoutDollars > $1.payoutDollars }
if run.uxTopWins.count > 5 { run.uxTopWins = Array(run.uxTopWins.prefix(5)) }
```

Only append when `payoutDollars > 0` (don't clutter with losing hands).

### Multiplier distribution display

Show % of lines that had each multiplier value (sorted ascending). Use SwiftUI Charts `BarMark` with multiplier on Y-axis and % on X-axis (horizontal bars = easier to read labels). The data comes from `results.aggregatedUXMultiplierDistribution`.

### Top wins display

Ranked table: rank number, hand name colored by hand tier, gold `12×` badge, payout in green. Show up to 5 rows.

---

## File Map

| File | Change |
|------|--------|
| `VideoPokerAcademy/Models/SimulationModels.swift` | Add `UXBigWin` struct; add `uxTopWins` and `uxMultiplierDistribution` to `SimulationRun`; add two computed aggregates to `SimulationResults` |
| `VideoPokerAcademy/ViewModels/SimulationViewModel.swift` | Populate new fields in `runSingleSimulation()` inner loop |
| `VideoPokerAcademy/Views/Simulation/SimulationResultsView.swift` | Add collapsible "ULTIMATE X MULTIPLIERS" section |
| `VideoPokerAcademyTests/UXSimulationStatsTests.swift` | New: tests for model defaults and aggregation |

---

## Task 1: Models

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/SimulationModels.swift`
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/UXSimulationStatsTests.swift`

### Background

`SimulationModels.swift` currently has `SimulationRun` with `biggestWin: Double` but no UX-specific tracking. `SimulationResults` has aggregation helpers like `aggregatedWinsByHandType`.

- [ ] **Step 1: Write failing tests**

Create `VideoPokerAcademyTests/UXSimulationStatsTests.swift` and add it to `project.pbxproj` (follow the same pattern used for `UltimateXSimulationTests.swift`):

```swift
import Testing
import Foundation
@testable import VideoPokerAcademy

@Suite("UX Simulation Stats Tests")
struct UXSimulationStatsTests {

    // MARK: - UXBigWin

    @Test("UXBigWin stores hand name, multiplier, and payout")
    func testUXBigWin() {
        let win = UXBigWin(handName: "Royal Flush", multiplier: 12, payoutDollars: 9375.0)
        #expect(win.handName == "Royal Flush")
        #expect(win.multiplier == 12)
        #expect(win.payoutDollars == 9375.0)
    }

    // MARK: - SimulationRun defaults

    @Test("SimulationRun defaults: uxTopWins empty, uxMultiplierDistribution empty")
    func testSimulationRunUXDefaults() {
        let run = SimulationRun(runNumber: 0)
        #expect(run.uxTopWins.isEmpty)
        #expect(run.uxMultiplierDistribution.isEmpty)
    }

    // MARK: - SimulationResults aggregation

    @Test("SimulationResults aggregates multiplier distribution across runs")
    func testAggregatedMultiplierDistribution() {
        var run1 = SimulationRun(runNumber: 0)
        run1.uxMultiplierDistribution = [1: 8, 2: 2]
        var run2 = SimulationRun(runNumber: 1)
        run2.uxMultiplierDistribution = [1: 5, 3: 3]

        let results = SimulationResults(
            config: SimulationConfig.default,
            runs: [run1, run2],
            isComplete: true,
            isCancelled: false
        )

        let dist = results.aggregatedUXMultiplierDistribution
        #expect(dist[1] == 13)
        #expect(dist[2] == 2)
        #expect(dist[3] == 3)
    }

    @Test("SimulationResults topUXBigWins returns top 5 sorted by payout")
    func testTopUXBigWins() {
        var run1 = SimulationRun(runNumber: 0)
        run1.uxTopWins = [
            UXBigWin(handName: "Royal Flush", multiplier: 12, payoutDollars: 9375.0),
            UXBigWin(handName: "Four Aces", multiplier: 4, payoutDollars: 500.0)
        ]
        var run2 = SimulationRun(runNumber: 1)
        run2.uxTopWins = [
            UXBigWin(handName: "Straight Flush", multiplier: 11, payoutDollars: 2750.0),
            UXBigWin(handName: "Royal Flush", multiplier: 7, payoutDollars: 5468.75),
            UXBigWin(handName: "Full House", multiplier: 12, payoutDollars: 180.0),
            UXBigWin(handName: "Four Aces", multiplier: 7, payoutDollars: 875.0),
        ]

        let results = SimulationResults(
            config: SimulationConfig.default,
            runs: [run1, run2],
            isComplete: true,
            isCancelled: false
        )

        let top = results.topUXBigWins
        #expect(top.count == 5)
        #expect(top[0].payoutDollars == 9375.0)  // Royal × 12 first
        #expect(top[1].payoutDollars == 5468.75) // Royal × 7 second
        #expect(top[2].payoutDollars == 2750.0)  // SF × 11 third
    }
}
```

- [ ] **Step 2: Run tests — expect failure** (types don't exist yet)

```bash
xcodebuild test -scheme VideoPokerAcademy \
  -destination 'platform=iOS Simulator,id=E03325C2-ADAF-4036-B8E1-E9972F1BCDCC' \
  -only-testing:VideoPokerAcademyTests/UXSimulationStatsTests \
  2>&1 | grep -E "error:|FAILED|passed|failed"
```

- [ ] **Step 3: Add `UXBigWin` struct and new fields to `SimulationModels.swift`**

Add after the `SingleHandResult` struct (around line 175):

```swift
// MARK: - UX Big Win Record

struct UXBigWin: Equatable {
    let handName: String
    let multiplier: Int
    let payoutDollars: Double
}
```

In `SimulationRun`, add after `var winsByHandType: [String: Int] = [:]`:

```swift
// UX mode: multiplier tracking
var uxMultiplierDistribution: [Int: Int] = [:]  // multiplier value → count of line-hands
var uxTopWins: [UXBigWin] = []                   // top 5 biggest single-line payouts
```

In `SimulationResults`, add after `aggregatedWinsByHandType`:

```swift
/// Aggregated multiplier distribution across all runs (UX mode only)
var aggregatedUXMultiplierDistribution: [Int: Int] {
    var result: [Int: Int] = [:]
    for run in runs {
        for (multiplier, count) in run.uxMultiplierDistribution {
            result[multiplier, default: 0] += count
        }
    }
    return result
}

/// Top 5 biggest single-line payouts across all runs (UX mode only)
var topUXBigWins: [UXBigWin] {
    let all = runs.flatMap { $0.uxTopWins }
    return Array(all.sorted { $0.payoutDollars > $1.payoutDollars }.prefix(5))
}
```

- [ ] **Step 4: Run tests — expect passing**

```bash
xcodebuild test -scheme VideoPokerAcademy \
  -destination 'platform=iOS Simulator,id=E03325C2-ADAF-4036-B8E1-E9972F1BCDCC' \
  -only-testing:VideoPokerAcademyTests/UXSimulationStatsTests \
  2>&1 | grep -E "error:|FAILED|passed|failed"
```

Expected: 4 tests pass.

---

## Task 2: ViewModel — Populate UX Stats During Simulation

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/SimulationViewModel.swift`

### Background

In `runSingleSimulation()`, after `payoutDollars` is computed and `lineWinnings += payoutDollars` is called, there is already an `if isUltimateX` block that updates `lineMultipliers[lineIdx]`. Add the new tracking just before or inside that block.

The relevant variables already in scope:
- `lineMultiplier: Int` — the multiplier active this line-hand
- `result.handName: String?` — e.g., "Royal Flush"
- `payoutDollars: Double` — payout in dollars for this line

- [ ] **Step 1: Add multiplier distribution tracking in the `isUltimateX` block**

In `runSingleSimulation()`, in the `if isUltimateX` block (currently just updates `lineMultipliers`), add tracking before the multiplier update:

```swift
// UX: update this line's multiplier for next hand
if isUltimateX {
    // Track multiplier distribution (the multiplier that was active for this line-hand)
    run.uxMultiplierDistribution[lineMultiplier, default: 0] += 1

    // Track top wins (only non-zero payouts)
    if let handName = result.handName, payoutDollars > 0 {
        run.uxTopWins.append(UXBigWin(handName: handName, multiplier: lineMultiplier, payoutDollars: payoutDollars))
        run.uxTopWins.sort { $0.payoutDollars > $1.payoutDollars }
        if run.uxTopWins.count > 5 {
            run.uxTopWins = Array(run.uxTopWins.prefix(5))
        }
    }

    lineMultipliers[lineIdx] = UltimateXMultiplierTable.multiplier(
        for: result.handName ?? "",
        playCount: playCount,
        family: family
    )
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild build -scheme VideoPokerAcademy \
  -destination 'platform=iOS Simulator,id=E03325C2-ADAF-4036-B8E1-E9972F1BCDCC' \
  2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Run all tests**

```bash
xcodebuild test -scheme VideoPokerAcademy \
  -destination 'platform=iOS Simulator,id=E03325C2-ADAF-4036-B8E1-E9972F1BCDCC' \
  2>&1 | grep -E "error:|FAILED|Test Suite.*passed|Test Suite.*failed" | tail -10
```

Expected: all suites pass.

---

## Task 3: View — UX Multiplier Stats Section

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Simulation/SimulationResultsView.swift`

### Background

`SimulationResultsView` has:
- A `chartsSection` computed property that uses `chartToggle(title:icon:isExpanded:)` for collapsible sections
- Existing `@State private var showBankrollChart`, `showWinDistribution`, `showRunDetails` booleans
- `SimulationResults.config.isUltimateXMode` tells us whether UX mode was active

The new section goes **after** `statisticsGrid` and **before** `chartsSection` in the main VStack. Only shown when `results.config.isUltimateXMode == true`.

The section has two parts:
1. **Multiplier Distribution** — horizontal bar chart: X axis = % of hands, Y axis = multiplier value (e.g., "1×", "2×", "12×"). Uses SwiftUI Charts `BarMark`.
2. **Top 5 Wins** — ranked list: `#1  Royal Flush  12×  $9,375`

- [ ] **Step 1: Add `@State private var showUXStats = true` to `SimulationResultsView`**

After the existing `@State private var showRunDetails = false` line, add:

```swift
@State private var showUXStats = true
```

- [ ] **Step 2: Add `uxStatsSection` computed property**

Add this after the `chartsSection` computed property:

```swift
@ViewBuilder
private var uxStatsSection: some View {
    if let results = viewModel.results, results.config.isUltimateXMode {
        VStack(spacing: 16) {
            Text("ULTIMATE X MULTIPLIERS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            chartToggle(title: "Multiplier Distribution", icon: "waveform.badge.magnifyingglass", isExpanded: $showUXStats)

            if showUXStats {
                VStack(spacing: 16) {
                    multiplierDistributionChart(results: results)
                    topWinsList(results: results)
                }
                .padding(.bottom)
            }
        }
    }
}
```

- [ ] **Step 3: Add `multiplierDistributionChart` helper**

```swift
private func multiplierDistributionChart(results: SimulationResults) -> some View {
    let dist = results.aggregatedUXMultiplierDistribution
    guard !dist.isEmpty else { return AnyView(EmptyView()) }

    let total = dist.values.reduce(0, +)
    let sortedDist = dist.sorted { $0.key < $1.key }

    return AnyView(VStack(alignment: .leading, spacing: 8) {
        Text("% of Lines by Active Multiplier")
            .font(.caption)
            .foregroundColor(.secondary)

        Chart {
            ForEach(sortedDist, id: \.key) { multiplier, count in
                let pct = total > 0 ? Double(count) / Double(total) * 100 : 0
                BarMark(
                    x: .value("Frequency", pct),
                    y: .value("Multiplier", "\(multiplier)×")
                )
                .foregroundStyle(multiplierColor(multiplier).gradient)
                .annotation(position: .trailing) {
                    Text(String(format: "%.1f%%", pct))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .chartXAxisLabel("% of Lines")
        .frame(height: CGFloat(sortedDist.count) * 36 + 40)
    })
}
```

- [ ] **Step 4: Add `topWinsList` helper**

```swift
private func topWinsList(results: SimulationResults) -> some View {
    let wins = results.topUXBigWins
    guard !wins.isEmpty else { return AnyView(EmptyView()) }

    return AnyView(VStack(alignment: .leading, spacing: 8) {
        Text("Top Multiplied Wins")
            .font(.caption)
            .foregroundColor(.secondary)

        VStack(spacing: 4) {
            ForEach(Array(wins.enumerated()), id: \.offset) { rank, win in
                HStack(spacing: 10) {
                    Text("#\(rank + 1)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 28, alignment: .leading)

                    Text(win.handName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(handColor(win.handName))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("\(win.multiplier)×")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "FFD700"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "FFD700").opacity(0.15))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color(hex: "FFD700").opacity(0.4), lineWidth: 1)
                        )

                    Text(formatCurrency(win.payoutDollars))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(rank % 2 == 0 ? Color(.systemGray6) : Color.clear)
                .cornerRadius(6)
            }
        }
    })
}
```

- [ ] **Step 5: Add `multiplierColor` and `handColor` helpers**

```swift
private func multiplierColor(_ multiplier: Int) -> Color {
    switch multiplier {
    case 12: return .purple
    case 11: return .indigo
    case 7:  return .blue
    case 4:  return .teal
    case 3:  return .cyan
    case 2:  return AppTheme.Colors.simulation
    default: return Color(.systemGray3)
    }
}

private func handColor(_ handName: String) -> Color {
    switch handName {
    case "Royal Flush", "Natural Royal": return .purple
    case "Straight Flush":              return .blue
    case "Four of a Kind", "Four Aces", "Four 2-4", "Four 5-K", "Five of a Kind": return .indigo
    case "Full House", "Wild Royal":    return .teal
    case "Flush":                       return .cyan
    case "Straight":                    return .green
    default:                            return .primary
    }
}
```

- [ ] **Step 6: Insert `uxStatsSection` into the main body VStack**

In the main `VStack(spacing: 20)` inside `body`, add `uxStatsSection` after `statisticsGrid`:

```swift
// Statistics grid
statisticsGrid

// UX multiplier stats (UX mode only)
uxStatsSection

// Charts section
chartsSection
```

- [ ] **Step 7: Build**

```bash
xcodebuild build -scheme VideoPokerAcademy \
  -destination 'platform=iOS Simulator,id=E03325C2-ADAF-4036-B8E1-E9972F1BCDCC' \
  2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 8: Run all tests**

```bash
xcodebuild test -scheme VideoPokerAcademy \
  -destination 'platform=iOS Simulator,id=E03325C2-ADAF-4036-B8E1-E9972F1BCDCC' \
  2>&1 | grep -E "error:|FAILED|Test Suite.*passed|Test Suite.*failed" | tail -10
```

Expected: all suites pass.

---

## Testing Checklist

After all tasks complete, run a small UX simulation to visually verify:

```
Game: JoB 9/6, Denomination: $1, Lines: 3, Hands: 50, Sims: 1, Variant: Ult X, Play Count: 10
```

Verify:
- [ ] "ULTIMATE X MULTIPLIERS" section appears in results (not shown for standard mode)
- [ ] Multiplier distribution chart shows bars for each multiplier value that appeared (1×, 2×, 3× etc.)
- [ ] Percentages sum to ~100%
- [ ] Top wins table shows at most 5 rows with hand name, gold multiplier badge, and payout
- [ ] Standard simulation (Variant: Standard) does NOT show the UX stats section
