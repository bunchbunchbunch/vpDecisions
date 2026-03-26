# Ultimate X E[K] Pre-computation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pre-compute E[K_awarded] for draw-all and single-card hold scenarios across all 5 multiplier groups and 3 play counts, embedding 210 values in a static Swift lookup table so `HoldOutcomeCalculator` returns instant results for the two most expensive cases.

**Architecture:** `UltimateXEKTable` is a static lookup struct with stub values (1.0) until `EKTableGenerator` (DEBUG-only actor) is run via a Settings button, prints 210 computed values as Swift code to the console, and the developer pastes that output into the table. `HoldOutcomeCalculator` is then updated to use the table for `bitmask=0` and single-card holds instead of live computation.

**Tech Stack:** Swift 6, Swift Testing (`@Test`, `#expect`), XcodeBuildMCP

---

## Background

### Why pre-compute?

Two hold patterns are expensive:
- **Draw-all (bitmask=0):** C(47,5) = 1,533,939 combos. Currently returns hardcoded `1.0` (incorrect).
- **Single-card hold:** C(47,4) = 178,365 combos. Slow for every call.

All other holds (2–5 cards) draw ≤3 cards: max C(47,3) = 16,215 — fast enough for live computation.

### Value scope

**5 multiplier groups × 3 play counts × 14 scenarios = 210 values**

| Group index | Families |
|-------------|----------|
| 0 — JacksOrBetter | jacksOrBetter, tensOrBetter, bonusPokerDeluxe, allAmerican |
| 1 — BonusPoker | bonusPoker, bonusPokerPlus |
| 2 — DoubleBonus | doubleBonus, doubleDoubleBonus, superDoubleBonus, doubleJackpot, doubleDoubleJackpot, acesBonus, acesAndEights, acesAndFaces, bonusAcesFaces, superAces, royalAcesBonus, whiteHotAces, ddbAcesFaces, ddbPlus |
| 3 — TripleDoubleBonus | tripleDoubleBonus, tripleBonus, tripleBonusPlus, tripleTripleBonus |
| 4 — DeucesWild | deucesWild, looseDeuces |

All paytables within a group share identical E[K] values: same multiplier table, same hand names from HandEvaluator.

### Representative paytables for generation

| Group | Paytable ID |
|-------|-------------|
| JacksOrBetter | `jacks-or-better-9-6` |
| BonusPoker | `bonus-poker-8-5` |
| DoubleBonus | `double-bonus-10-7` |
| TripleDoubleBonus | `triple-double-bonus-9-6` |
| DeucesWild | `deuces-wild-full-pay` |

### Array layout in tableData

```
tableData[groupIndex][playCountIndex][scenarioIndex]

groupIndex:     0=JoB, 1=BonusPoker, 2=DoubleBonus, 3=TripleDoubleBonus, 4=DeucesWild
playCountIndex: 0=three, 1=five, 2=ten
scenarioIndex:  0=drawAll, 1=two, 2=three, 3=four, 4=five, 5=six,
                6=seven, 7=eight, 8=nine, 9=ten, 10=jack, 11=queen, 12=king, 13=ace
```

`rankScenarioIndex(rank) = rank.rawValue - 1` (two.rawValue=2 → index 1, ace.rawValue=14 → index 13)

### Canonical hands used by the generator

**Draw-all:** `[3♠, 6♥, 9♦, Q♣, K♠]` — no deuces, no pairs, no flush/straight potential.

**Single-card hold (rank R):** held card at position 0, fillers at 1–4.
- Fillers: `3♥, 6♦, 9♣, Q♥` — bumped by 1 if they conflict with target rank.
- Example: rank=three → use `4♥` instead of `3♥`.

---

## File Map

| File | Change |
|------|--------|
| `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/UltimateXEKTable.swift` | Create — lookup table (stub 1.0 values, replaced in Task 5) |
| `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/UltimateXEKTableTests.swift` | Create — behavioral tests (fail with stubs, pass after Task 5) |
| `ios-native/VideoPokerAcademy/VideoPokerAcademy/Services/EKTableGenerator.swift` | Create (#if DEBUG) — offline generator |
| `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Settings/SettingsView.swift` | Modify — add "Generate E[K] Table" button in DEBUG Developer section |
| `ios-native/VideoPokerAcademy/VideoPokerAcademy/Services/HoldOutcomeCalculator.swift` | Modify — use table for bitmask=0 and single-card holds |

---

## Task 1: Create stub `UltimateXEKTable.swift`

**Files:**
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/UltimateXEKTable.swift`

- [ ] **Step 1: Create the file**

```swift
import Foundation

/// Pre-computed E[K_awarded] values for Ultimate X poker.
///
/// E[K] is the expected multiplier awarded on the next hand, averaged over all
/// C(47, drawCount) draw outcomes for a given hold pattern.
///
/// Coverage:
///   - Draw-all (bitmask=0): C(47,5) = 1.53M outcomes per group/playCount
///   - Single-card hold (ranks two–ace): C(47,4) = 178K outcomes each
///
/// Values are identical for all paytables within the same multiplier group.
/// Generated offline using EKTableGenerator (Settings → Developer).
///
/// STUB: All values are 1.0 until EKTableGenerator output is pasted here (Task 5).
struct UltimateXEKTable {

    // MARK: - Public API

    /// E[K] when discarding all 5 cards.
    static func eKDrawAll(playCount: UltimateXPlayCount, family: GameFamily) -> Double {
        tableData[groupIndex(for: family)][playCountIndex(playCount)][0]
    }

    /// E[K] when holding exactly one card of the given rank.
    static func eKSingleCard(rank: Rank, playCount: UltimateXPlayCount, family: GameFamily) -> Double {
        tableData[groupIndex(for: family)][playCountIndex(playCount)][rankScenarioIndex(rank)]
    }

    // MARK: - Index Helpers

    private static func groupIndex(for family: GameFamily) -> Int {
        switch family {
        case .jacksOrBetter, .tensOrBetter, .bonusPokerDeluxe, .allAmerican:
            return 0
        case .bonusPoker, .bonusPokerPlus:
            return 1
        case .doubleBonus, .doubleDoubleBonus, .superDoubleBonus,
             .doubleJackpot, .doubleDoubleJackpot,
             .acesBonus, .acesAndEights, .acesAndFaces, .bonusAcesFaces,
             .superAces, .royalAcesBonus, .whiteHotAces,
             .ddbAcesFaces, .ddbPlus:
            return 2
        case .tripleDoubleBonus, .tripleBonus, .tripleBonusPlus, .tripleTripleBonus:
            return 3
        case .deucesWild, .looseDeuces:
            return 4
        }
    }

    private static func playCountIndex(_ playCount: UltimateXPlayCount) -> Int {
        switch playCount {
        case .three: return 0
        case .five:  return 1
        case .ten:   return 2
        }
    }

    /// scenarioIndex: 0=drawAll, 1=two, 2=three, ..., 13=ace
    private static func rankScenarioIndex(_ rank: Rank) -> Int {
        rank.rawValue - 1  // two.rawValue=2 → 1, ace.rawValue=14 → 13
    }

    // MARK: - Table Data
    //
    // Layout: tableData[groupIndex][playCountIndex][scenarioIndex]
    // Groups 0–4: JoB, BonusPoker, DoubleBonus, TripleDoubleBonus, DeucesWild
    // Play counts 0–2: three, five, ten
    // Scenarios 0–13: drawAll, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace
    //
    // STUB: Replace with EKTableGenerator output (Settings → Developer → Generate E[K] Table).

    private static let tableData: [[[Double]]] = Array(
        repeating: Array(repeating: Array(repeating: 1.0, count: 14), count: 3),
        count: 5
    )
}
```

- [ ] **Step 2: Add to Xcode project**

Open Xcode → VideoPokerAcademy group → Models → Add Files → select the new file, check "VideoPokerAcademy" target only.

- [ ] **Step 3: Build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj` scheme `VideoPokerAcademy`, simulator `iPhone 16 Pro Max`
Expected: clean build.

- [ ] **Step 4: Commit**

```bash
git add ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/UltimateXEKTable.swift
git commit -m "feat: add UltimateXEKTable stub (210 values, all 1.0 until generator runs)"
```

---

## Task 2: Write failing behavioral tests for the table

**Files:**
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/UltimateXEKTableTests.swift`

These tests check behavioral properties impossible to satisfy with stub 1.0 values. They FAIL now; they PASS after Task 5 populates real values.

- [ ] **Step 1: Create the test file**

```swift
import Testing
@testable import VideoPokerAcademy

struct UltimateXEKTableTests {

    // MARK: - API completeness (pass with any values, including stubs)

    @Test("eKDrawAll returns a value for all family/playCount combinations")
    func testDrawAllAPIWorks() {
        for playCount in UltimateXPlayCount.allCases {
            let ek = UltimateXEKTable.eKDrawAll(playCount: playCount, family: .jacksOrBetter)
            #expect(ek >= 1.0)
        }
    }

    @Test("eKSingleCard returns a value for all rank/family/playCount combinations")
    func testSingleCardAPIWorks() {
        for rank in Rank.allCases {
            let ek = UltimateXEKTable.eKSingleCard(rank: rank, playCount: .three, family: .jacksOrBetter)
            #expect(ek >= 1.0)
        }
    }

    @Test("Same group families return identical E[K] values")
    func testSameGroupReturnsSameValue() {
        // acesAndFaces and doubleBonus map to group 2 (DoubleBonus)
        let db = UltimateXEKTable.eKDrawAll(playCount: .three, family: .doubleBonus)
        let af = UltimateXEKTable.eKDrawAll(playCount: .three, family: .acesAndFaces)
        #expect(db == af)

        // deucesWild and looseDeuces map to group 4
        let dw = UltimateXEKTable.eKDrawAll(playCount: .three, family: .deucesWild)
        let ld = UltimateXEKTable.eKDrawAll(playCount: .three, family: .looseDeuces)
        #expect(dw == ld)
    }

    // MARK: - Behavioral properties (FAIL with stubs=1.0, PASS with real values)

    @Test("JoB 3-play draw-all E[K] > 1.0 — winning hands push average above floor")
    func testJoBDrawAllAboveOne() {
        let ek = UltimateXEKTable.eKDrawAll(playCount: .three, family: .jacksOrBetter)
        #expect(ek > 1.0)
    }

    @Test("JoB 10-play draw-all E[K] > JoB 3-play — 10-play has higher multipliers")
    func testTenPlayHigherThanThreePlay() {
        let ten = UltimateXEKTable.eKDrawAll(playCount: .ten, family: .jacksOrBetter)
        let three = UltimateXEKTable.eKDrawAll(playCount: .three, family: .jacksOrBetter)
        #expect(ten > three)
    }

    @Test("JoB 3-play: holding Ace has higher E[K] than holding Two")
    func testAceBetterThanTwoJoB() {
        let ace = UltimateXEKTable.eKSingleCard(rank: .ace, playCount: .three, family: .jacksOrBetter)
        let two = UltimateXEKTable.eKSingleCard(rank: .two, playCount: .three, family: .jacksOrBetter)
        #expect(ace > two)
    }

    @Test("DeucesWild 3-play: holding a Two (wild card) has higher E[K] than holding a Three")
    func testDeucesWildWildCardBetter() {
        let deuce = UltimateXEKTable.eKSingleCard(rank: .two, playCount: .three, family: .deucesWild)
        let three = UltimateXEKTable.eKSingleCard(rank: .three, playCount: .three, family: .deucesWild)
        #expect(deuce > three)
    }
}
```

- [ ] **Step 2: Add to Xcode project**

Add to `VideoPokerAcademyTests` target only (not the main app target).

- [ ] **Step 3: Run tests — confirm behavioral tests fail**

Run: `mcp__xcodebuildmcp__test_sim_name_proj`
Expected:
- `testDrawAllAPIWorks`, `testSingleCardAPIWorks`, `testSameGroupReturnsSameValue` → PASS (1.0 satisfies >= 1.0 and equality)
- `testJoBDrawAllAboveOne`, `testTenPlayHigherThanThreePlay`, `testAceBetterThanTwoJoB`, `testDeucesWildWildCardBetter` → FAIL (1.0 is not > 1.0)

- [ ] **Step 4: Commit**

```bash
git add ios-native/VideoPokerAcademy/VideoPokerAcademyTests/UltimateXEKTableTests.swift
git commit -m "test: add failing behavioral tests for UltimateXEKTable (pass after generator runs)"
```

---

## Task 3: Create `EKTableGenerator.swift` (DEBUG-only)

**Files:**
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Services/EKTableGenerator.swift`

- [ ] **Step 1: Create the file**

```swift
#if DEBUG
import Foundation

/// Offline generator for UltimateXEKTable pre-computed values.
///
/// Usage: Settings → Developer → "Generate E[K] Table"
/// Output: Swift code printed to Xcode console. Paste into UltimateXEKTable.swift.
///
/// Runtime: ~5–15 minutes on simulator (58M hand evaluations total).
actor EKTableGenerator {

    static let shared = EKTableGenerator()

    private static let representativePaytableIds = [
        "jacks-or-better-9-6",    // group 0: JacksOrBetter
        "bonus-poker-8-5",         // group 1: BonusPoker
        "double-bonus-10-7",       // group 2: DoubleBonus
        "triple-double-bonus-9-6", // group 3: TripleDoubleBonus
        "deuces-wild-full-pay",    // group 4: DeucesWild
    ]

    private static let groupNames = [
        "JacksOrBetter", "BonusPoker", "DoubleBonus", "TripleDoubleBonus", "DeucesWild"
    ]

    // MARK: - Entry Point

    /// Computes all 210 E[K] values and returns formatted Swift code for UltimateXEKTable.
    func generateAll() async -> String {
        var result: [[[Double]]] = []

        for groupIndex in 0..<5 {
            let paytableId = Self.representativePaytableIds[groupIndex]
            let groupName = Self.groupNames[groupIndex]
            var groupData: [[Double]] = []

            for playCount in UltimateXPlayCount.allCases {
                print("EKTableGenerator: group \(groupIndex + 1)/5 (\(groupName)), \(playCount.displayName)...")
                var scenarios: [Double] = []

                // Scenario 0: draw-all
                scenarios.append(await computeDrawAll(paytableId: paytableId, playCount: playCount))

                // Scenarios 1–13: hold rank two through ace
                for rank in Rank.allCases {
                    scenarios.append(await computeSingleCard(rank: rank, paytableId: paytableId, playCount: playCount))
                }

                groupData.append(scenarios)
            }

            result.append(groupData)
        }

        print("EKTableGenerator: complete.")
        return formatAsSwift(result)
    }

    // MARK: - Draw-All Computation (C(47,5) = 1,533,939 combos)

    private func computeDrawAll(paytableId: String, playCount: UltimateXPlayCount) async -> Double {
        let family = PayTable.allPayTables.first(where: { $0.id == paytableId })?.family ?? .jacksOrBetter

        // Fixed canonical hand: no deuces, no pairs, no flush/straight potential
        let hand = Hand(cards: [
            Card(rank: .three, suit: .spades),
            Card(rank: .six,   suit: .hearts),
            Card(rank: .nine,  suit: .diamonds),
            Card(rank: .queen, suit: .clubs),
            Card(rank: .king,  suit: .spades),
        ])

        let dealtKeys = Set(hand.cards.map { "\($0.rank.rawValue)_\($0.suit.rawValue)" })
        let remainingDeck = Card.createDeck().filter {
            !dealtKeys.contains("\($0.rank.rawValue)_\($0.suit.rawValue)")
        }

        var total: Double = 0
        var count = 0

        enumerateCombinations(n: remainingDeck.count, k: 5) { indices in
            let drawHand = Hand(cards: indices.map { remainingDeck[$0] })
            let result = HandEvaluator.shared.evaluateDealtHand(hand: drawHand, paytableId: paytableId)
            let m = UltimateXMultiplierTable.multiplier(for: result.handName ?? "", playCount: playCount, family: family)
            total += Double(m)
            count += 1
        }

        return total / Double(max(count, 1))
    }

    // MARK: - Single-Card Hold Computation (C(47,4) = 178,365 combos)

    private func computeSingleCard(rank: Rank, paytableId: String, playCount: UltimateXPlayCount) async -> Double {
        let family = PayTable.allPayTables.first(where: { $0.id == paytableId })?.family ?? .jacksOrBetter
        let hand = canonicalHand(for: rank)
        let heldPosition = 0  // held card is always at position 0

        let dealtKeys = Set(hand.cards.map { "\($0.rank.rawValue)_\($0.suit.rawValue)" })
        let remainingDeck = Card.createDeck().filter {
            !dealtKeys.contains("\($0.rank.rawValue)_\($0.suit.rawValue)")
        }

        var total: Double = 0
        var count = 0

        enumerateCombinations(n: remainingDeck.count, k: 4) { indices in
            let drawn = indices.map { remainingDeck[$0] }
            var finalCards = hand.cards
            var drawIdx = 0
            for pos in 0..<5 where pos != heldPosition {
                finalCards[pos] = drawn[drawIdx]
                drawIdx += 1
            }
            let drawHand = Hand(cards: finalCards)
            let result = HandEvaluator.shared.evaluateDealtHand(hand: drawHand, paytableId: paytableId)
            let m = UltimateXMultiplierTable.multiplier(for: result.handName ?? "", playCount: playCount, family: family)
            total += Double(m)
            count += 1
        }

        return total / Double(max(count, 1))
    }

    // MARK: - Canonical Hand Builder

    /// Canonical hand for single-card hold: target rank at position 0, fillers at 1–4.
    /// Fillers (3♥, 6♦, 9♣, Q♥) are bumped by 1 if they equal the target rank.
    private func canonicalHand(for rank: Rank) -> Hand {
        func filler(_ preferred: Rank, _ alternate: Rank) -> Rank {
            rank == preferred ? alternate : preferred
        }
        return Hand(cards: [
            Card(rank: rank,                         suit: .spades),
            Card(rank: filler(.three, .four),        suit: .hearts),
            Card(rank: filler(.six,   .seven),       suit: .diamonds),
            Card(rank: filler(.nine,  .eight),       suit: .clubs),
            Card(rank: filler(.queen, .king),        suit: .hearts),
        ])
    }

    // MARK: - Combination Enumerator

    private func enumerateCombinations(n: Int, k: Int, handler: ([Int]) -> Void) {
        guard k > 0, k <= n else {
            if k == 0 { handler([]) }
            return
        }
        var indices = Array(0..<k)
        while true {
            handler(indices)
            var i = k - 1
            while i >= 0 && indices[i] == n - k + i { i -= 1 }
            if i < 0 { break }
            indices[i] += 1
            for j in (i + 1)..<k { indices[j] = indices[j - 1] + 1 }
        }
    }

    // MARK: - Output Formatter

    private func formatAsSwift(_ data: [[[Double]]]) -> String {
        let date = ISO8601DateFormatter().string(from: Date())
        var lines = [
            "// Generated \(date) by EKTableGenerator",
            "// Representative paytables: JoB=jacks-or-better-9-6, BP=bonus-poker-8-5,",
            "//   DB=double-bonus-10-7, TDB=triple-double-bonus-9-6, DW=deuces-wild-full-pay",
            "// Scenario order: [drawAll, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace]",
            "private static let tableData: [[[Double]]] = [",
        ]

        let playCounts = ["three-play", "five-play", "ten-play"]

        for (gi, group) in data.enumerated() {
            lines.append("    // Group \(gi): \(Self.groupNames[gi])")
            lines.append("    [")
            for (pi, scenarios) in group.enumerated() {
                let vals = scenarios.map { String(format: "%.6f", $0) }.joined(separator: ", ")
                lines.append("        // \(playCounts[pi])")
                lines.append("        [\(vals)],")
            }
            lines.append("    ],")
        }

        lines.append("]")
        return lines.joined(separator: "\n")
    }
}
#endif
```

- [ ] **Step 2: Add to Xcode project**

Add to `VideoPokerAcademy` target only. `#if DEBUG` keeps it out of release builds.

- [ ] **Step 3: Build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: clean build.

- [ ] **Step 4: Commit**

```bash
git add ios-native/VideoPokerAcademy/VideoPokerAcademy/Services/EKTableGenerator.swift
git commit -m "feat: add EKTableGenerator (DEBUG) for offline E[K] pre-computation"
```

---

## Task 4: Wire generator into SettingsView developer section

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Settings/SettingsView.swift`

The existing `#if DEBUG` Developer section already has two buttons. Add a third for the generator.

- [ ] **Step 1: Add state variables to the `#if DEBUG` block (lines 13–15)**

Find:
```swift
#if DEBUG
@State private var showEVBenchmark = false
#endif
```

Replace with:
```swift
#if DEBUG
@State private var showEVBenchmark = false
@State private var isGeneratingEKTable = false
#endif
```

- [ ] **Step 2: Add generator button in the Developer settingsSection**

The Developer section has one `Divider()` (between the Rating Prompt button and the EV Benchmark button). Add the following after the closing `}` of the UX EV Benchmark `Button { } label: { }` block, before the Developer section's closing `}`:

```swift
            Divider()
                .background(Color.white.opacity(0.1))

            Button {
                guard !isGeneratingEKTable else { return }
                isGeneratingEKTable = true
                Task { @MainActor in
                    let output = await EKTableGenerator.shared.generateAll()
                    print("\n=== EKTableGenerator OUTPUT — paste into UltimateXEKTable.swift ===\n\(output)\n=== END ===\n")
                    isGeneratingEKTable = false
                }
            } label: {
                SettingsRowContent(
                    icon: isGeneratingEKTable ? "hourglass" : "tablecells",
                    title: isGeneratingEKTable ? "Generating E[K] Table..." : "Generate E[K] Table",
                    subtitle: "Outputs Swift code for UltimateXEKTable to Xcode console",
                    showChevron: false
                )
            }
```

- [ ] **Step 3: Build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: clean build.

- [ ] **Step 4: Verify button appears on simulator**

```
mcp__xcodebuildmcp__boot_simulator
mcp__xcodebuildmcp__install_app
mcp__xcodebuildmcp__launch_app
mcp__xcodebuildmcp__screenshot
```

Navigate to Settings → Developer section. Screenshot should show the "Generate E[K] Table" button.

- [ ] **Step 5: Commit**

```bash
git add ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Settings/SettingsView.swift
git commit -m "feat: add Generate E[K] Table button to DEBUG developer settings"
```

---

## Task 5: Run generator and populate table values

**Note:** This task requires running the app on a simulator and waiting ~5–15 minutes for computation to complete. The developer must be logged into the app to access Settings.

- [ ] **Step 1: Launch app on simulator (if not already running)**

```
mcp__xcodebuildmcp__boot_simulator
mcp__xcodebuildmcp__install_app
mcp__xcodebuildmcp__launch_app
```

- [ ] **Step 2: Tap "Generate E[K] Table" button**

Navigate to Settings (profile icon or tab) → scroll to Developer section → tap "Generate E[K] Table".

The button label changes to "Generating E[K] Table..." with a hourglass icon.

Progress lines print to the Xcode console every few seconds as each group/play-count completes.

- [ ] **Step 3: Wait for completion (~5–15 minutes)**

Take periodic screenshots to monitor. When the button reverts to "Generate E[K] Table", the computation is done.

Alternatively, monitor with:
```
mcp__xcodebuildmcp__capture_logs
```
Look for `EKTableGenerator: complete.` in the output.

- [ ] **Step 4: Extract and paste the generated code**

In the Xcode console (or captured logs), find the block between:
```
=== EKTableGenerator OUTPUT — paste into UltimateXEKTable.swift ===
```
and:
```
=== END ===
```

In `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/UltimateXEKTable.swift`, replace:

```swift
    private static let tableData: [[[Double]]] = Array(
        repeating: Array(repeating: Array(repeating: 1.0, count: 14), count: 3),
        count: 5
    )
```

With the full `private static let tableData: [[[Double]]] = [...]` block from the console output.

- [ ] **Step 5: Build and run tests**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: clean build.

Run: `mcp__xcodebuildmcp__test_sim_name_proj`
Expected: all `UltimateXEKTableTests` pass, including the four previously-failing behavioral tests.

- [ ] **Step 6: Commit**

```bash
git add ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/UltimateXEKTable.swift
git commit -m "feat: populate UltimateXEKTable with 210 pre-computed E[K] values"
```

---

## Task 6: Update `HoldOutcomeCalculator` to use the table

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Services/HoldOutcomeCalculator.swift`

Current `computeEK` starts:
```swift
    ) async -> Double {
        guard holdBitmask != 0 else { return 1.0 }

        // Resolve family once — avoids per-iteration lookup in inner loop
        let family = PayTable.allPayTables.first(where: { $0.id == paytableId })?.family ?? .jacksOrBetter

        let canonicalIndices = Hand.holdIndicesFromBitmask(holdBitmask)
        let originalIndices = hand.canonicalIndicesToOriginal(canonicalIndices)
        let drawCount = 5 - originalIndices.count
```

- [ ] **Step 1: Update the top of `computeEK`**

Replace those lines with:

```swift
    ) async -> Double {
        // Resolve family once — used for table lookups and inner-loop multiplier calls
        let family = PayTable.allPayTables.first(where: { $0.id == paytableId })?.family ?? .jacksOrBetter

        // Use pre-computed table for draw-all: C(47,5) = 1.53M combos
        guard holdBitmask != 0 else {
            return UltimateXEKTable.eKDrawAll(playCount: playCount, family: family)
        }

        let canonicalIndices = Hand.holdIndicesFromBitmask(holdBitmask)
        let originalIndices = hand.canonicalIndicesToOriginal(canonicalIndices)
        let drawCount = 5 - originalIndices.count

        // Use pre-computed table for single-card holds: C(47,4) = 178K combos
        if originalIndices.count == 1 {
            let heldCard = hand.cards[originalIndices[0]]
            return UltimateXEKTable.eKSingleCard(rank: heldCard.rank, playCount: playCount, family: family)
        }

        // For 2-5 card holds: live computation (fast — max C(47,3) = 16K combos)
```

The rest of `computeEK` (deck building, combo enumeration) is unchanged.

- [ ] **Step 2: Build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: clean build.

- [ ] **Step 3: Run all tests**

Run: `mcp__xcodebuildmcp__test_sim_name_proj`
Expected: all tests pass, including:
- `UltimateXEKTableTests` — all 7 tests pass
- `HoldOutcomeCalculatorTests` — existing full-house test (EK=12.0 for JoB) still passes since full-house is a hold-all-5 case, not affected

- [ ] **Step 4: Commit**

```bash
git add ios-native/VideoPokerAcademy/VideoPokerAcademy/Services/HoldOutcomeCalculator.swift
git commit -m "feat: use pre-computed E[K] table for draw-all and single-card holds"
```

---

## Task 7: Smoke test the benchmark tool

Verify end-to-end: HoldOutcomeCalculator now returns meaningful E[K] values for all bitmask cases.

- [ ] **Step 1: Run benchmark in simulator**

Launch app, navigate to Settings → Developer → UX EV Benchmark. Tap "Run Benchmark".

- [ ] **Step 2: Verify the results look plausible**

Expected:
- E[K] values for single-card holds in the range ~1.1–1.6 (not exactly 1.0)
- Timing for single-card hold rows shows microseconds, not seconds

- [ ] **Step 3: Final full test run**

Run: `mcp__xcodebuildmcp__test_sim_name_proj`
Expected: all tests pass (121+).
