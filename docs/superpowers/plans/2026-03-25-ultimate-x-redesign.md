# Ultimate X Play Mode Redesign

> **For agentic workers:** Use superpowers:subagent-driven-development to execute task-by-task.

**Goal:** Redesign UX play mode: flatten variant selector to Standard/Ult X, derive play count from line selection, add per-hand multiplier badges in mini-hand grid, show strategy panel only after draw with on-the-fly calculation for user's actual hold.

**Architecture:** `PlayVariant` becomes a simple 2-case enum (no associated value). `UltimateXPlayCount` is derived from `lineCount` at call sites. `PlayHandResult` gains `appliedMultiplier`/`earnedMultiplier` fields. Multiplier badges move into `MiniHandView`. Strategy panel restricted to result phase.

---

## Task 1: Flatten `PlayVariant` and update `PlaySettings` / `PlayHandResult`

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/PlayModels.swift`
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/UltimateXPlayModeTests.swift`

### Background

`PlayVariant` currently has `.ultimateX(playCount: UltimateXPlayCount)`. This becomes just `.ultimateX` (no associated value). The play count for table lookups is derived from `settings.lineCount` via a new `effectiveUXPlayCount` computed property on `PlaySettings`.

- [ ] **Step 1: Replace `PlayVariant` enum (lines 5–34)**

```swift
// MARK: - Play Variant

enum PlayVariant: String, Codable, Equatable, Hashable {
    case standard
    case ultimateX

    var isUltimateX: Bool { self == .ultimateX }

    var coinsPerLine: Int { isUltimateX ? 10 : 5 }

    var displayName: String {
        switch self {
        case .standard:  return "Standard"
        case .ultimateX: return "Ult X"
        }
    }
}
```

- [ ] **Step 2: Update `PlaySettings` computed properties**

Replace `effectiveLineCount`:
```swift
var effectiveLineCount: Int { lineCount.rawValue }
```

Add `effectiveUXPlayCount`:
```swift
/// Derives UltimateXPlayCount from lineCount for table lookups. Only meaningful when variant == .ultimateX.
var effectiveUXPlayCount: UltimateXPlayCount {
    switch lineCount {
    case .one, .three:          return .three
    case .five:                 return .five
    case .ten, .oneHundred:     return .ten
    }
}
```

Replace `statsPaytableKey`:
```swift
var statsPaytableKey: String {
    switch variant {
    case .standard:  return selectedPaytableId
    case .ultimateX: return selectedPaytableId + "-ux-\(effectiveUXPlayCount.rawValue)play"
    }
}
```

Remove `var uxPlayCount` references in `PlaySettings` (the old `variant.uxPlayCount` calls) — they'll be replaced by `effectiveUXPlayCount` in other tasks.

- [ ] **Step 3: Add `appliedMultiplier` and `earnedMultiplier` to `PlayHandResult`**

```swift
struct PlayHandResult: Identifiable, Codable {
    let id: UUID
    let lineNumber: Int
    let finalHand: [CardData]
    let handName: String?
    let payout: Int
    let winningIndices: [Int]
    let appliedMultiplier: Int  // Multiplier applied to THIS hand's payout (1 if none)
    let earnedMultiplier: Int   // Multiplier this hand earns for NEXT hand (1 if no qualifying win)

    init(
        lineNumber: Int,
        finalHand: [Card],
        handName: String?,
        payout: Int,
        winningIndices: [Int],
        appliedMultiplier: Int = 1,
        earnedMultiplier: Int = 1
    ) {
        self.id = UUID()
        self.lineNumber = lineNumber
        self.finalHand = finalHand.map { CardData(rank: $0.rank, suit: $0.suit) }
        self.handName = handName
        self.payout = payout
        self.winningIndices = winningIndices
        self.appliedMultiplier = appliedMultiplier
        self.earnedMultiplier = earnedMultiplier
    }
}
```

Since `PlayHandResult` is `Codable` and old persisted `ActiveHandState` JSON won't have these fields, add a custom `init(from:)` using `decodeIfPresent` with default 1:

```swift
enum CodingKeys: String, CodingKey {
    case id, lineNumber, finalHand, handName, payout, winningIndices
    case appliedMultiplier, earnedMultiplier
}

init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(UUID.self, forKey: .id)
    lineNumber = try c.decode(Int.self, forKey: .lineNumber)
    finalHand = try c.decode([CardData].self, forKey: .finalHand)
    handName = try c.decodeIfPresent(String.self, forKey: .handName)
    payout = try c.decode(Int.self, forKey: .payout)
    winningIndices = try c.decode([Int].self, forKey: .winningIndices)
    appliedMultiplier = try c.decodeIfPresent(Int.self, forKey: .appliedMultiplier) ?? 1
    earnedMultiplier = try c.decodeIfPresent(Int.self, forKey: .earnedMultiplier) ?? 1
}
```

- [ ] **Step 4: Fix compile errors from old `PlayVariant` usage**

Search the entire project for `ultimateX(playCount:)` and `variant.uxPlayCount` and fix each:
- `settings.variant.uxPlayCount` → `settings.effectiveUXPlayCount` (wrapped in `settings.variant.isUltimateX ?` guard)
- `PlayVariant.ultimateX(playCount: .three)` → `PlayVariant.ultimateX`
- `settings.variant == .ultimateX(playCount: .five)` → `settings.variant == .ultimateX`

Also fix `initializeUXMultipliers()` in `PlayViewModel`:
```swift
func initializeUXMultipliers() {
    guard settings.variant.isUltimateX else { return }
    ultimateXMultipliers = Array(repeating: 1, count: settings.effectiveLineCount)
    ultimateXTopHolds = []
}
```

And `computeUXTopHolds()` — replace `guard let pc = settings.variant.uxPlayCount` with:
```swift
guard settings.variant.isUltimateX else { return }
let pc = settings.effectiveUXPlayCount
```

- [ ] **Step 5: Update `UltimateXPlayModeTests.swift`**

Replace old `.ultimateX(playCount:)` references with `.ultimateX`. Replace `statsKeySuffix` tests with `statsPaytableKey` tests. Add `effectiveUXPlayCount` tests:

```swift
@Test("effectiveUXPlayCount: 1-line maps to .three")
func testUXPlayCountOne() {
    var s = PlaySettings(); s.variant = .ultimateX; s.lineCount = .one
    #expect(s.effectiveUXPlayCount == .three)
}
@Test("effectiveUXPlayCount: 100-line maps to .ten")
func testUXPlayCountHundred() {
    var s = PlaySettings(); s.variant = .ultimateX; s.lineCount = .oneHundred
    #expect(s.effectiveUXPlayCount == .ten)
}
@Test("PlayHandResult defaults multipliers to 1")
func testHandResultDefaults() {
    let r = PlayHandResult(lineNumber: 1, finalHand: [], handName: nil, payout: 0, winningIndices: [])
    #expect(r.appliedMultiplier == 1)
    #expect(r.earnedMultiplier == 1)
}
@Test("PlaySettings.statsPaytableKey: UX 5-line")
func testStatsKeyUX5Line() {
    var s = PlaySettings(); s.variant = .ultimateX; s.selectedPaytableId = "job-9-6"; s.lineCount = .five
    #expect(s.statsPaytableKey == "job-9-6-ux-5play")
}
@Test("PlaySettings.effectiveLineCount: UX same as lineCount")
func testEffectiveLineCountUX() {
    var s = PlaySettings(); s.variant = .ultimateX; s.lineCount = .ten
    #expect(s.effectiveLineCount == 10)
}
```

- [ ] **Step 6: Build and test**

```
mcp__xcodebuildmcp__build_sim_name_proj
mcp__xcodebuildmcp__test_sim_name_proj
```

---

## Task 2: Update `PlayStartView` — 2-chip selector, always-visible lines, plain start button

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/PlayStartView.swift`

- [ ] **Step 1: Rewrite `variantSection`**

Replace the existing `variantSection` with:
```swift
private var variantSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("Variant")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(AppTheme.Colors.textSecondary)

        FlowLayout(spacing: 8) {
            SelectionChip(title: "Standard", isSelected: settings.variant == .standard) {
                settings.variant = .standard
            }
            SelectionChip(title: "Ult X", isSelected: settings.variant == .ultimateX) {
                settings.variant = .ultimateX
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        if settings.variant == .ultimateX {
            Text("2\u{00D7} bet cost \u{00B7} \(settings.lineCount.rawValue) simultaneous hands")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
```

- [ ] **Step 2: Remove conditional `linesSection` in `portraitLayout`**

Find `if settings.variant == .standard { linesSection }` and replace with just `linesSection`.

- [ ] **Step 3: Remove conditional `linesSection` in `landscapeLayout`**

Same change in landscape left column.

- [ ] **Step 4: Simplify `startButtonSection` — remove cost label**

Find the `if settings.variant.isUltimateX { Text("Start Playing · ...") } else { Text("Start Playing") }` block and replace with plain `Text("Start Playing").primaryButton()`.

- [ ] **Step 5: Build and visual verify**

```
mcp__xcodebuildmcp__build_sim_name_proj
mcp__xcodebuildmcp__boot_simulator
mcp__xcodebuildmcp__install_app
mcp__xcodebuildmcp__launch_app
mcp__xcodebuildmcp__screenshot
```

---

## Task 3: Multiplier badges in MiniHandView + PlayViewModel draw logic

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/MiniHandView.swift`
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/MultiHandGrid.swift`
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/PlayViewModel.swift`
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/PlayView.swift`

### Background

From the real casino screenshot:
- **Lower-left badge**: Shows `"Nx"` (e.g., "12X") — the multiplier ACTIVE for this hand. Shows whenever multiplier > 1 during BOTH dealt and result phases.
- **Upper-left badge**: Shows `"NEXT HAND Nx"` — the multiplier THIS hand EARNED for next time. Shows only when earnedMultiplier > 1, only during result phase.

For dealt phase (before draw), `appliedMultiplier` isn't set on results yet — we show badges using `ultimateXMultipliers[lineIndex]` directly.

For result phase, we use `result.appliedMultiplier` and `result.earnedMultiplier`.

- [ ] **Step 1: Update `performStandardDraw()` to populate multiplier fields**

In the loop, the line:
```swift
let result = PlayHandResult(lineNumber: lineNum + 1, finalHand: finalHand, handName: evaluation.handName, payout: payout, winningIndices: evaluation.winningIndices)
```

Update to:
```swift
let earnedMultiplier = isUX && uxPlayCount != nil
    ? UltimateXMultiplierTable.multiplier(for: evaluation.handName ?? "no win", playCount: settings.effectiveUXPlayCount, family: family)
    : 1

let result = PlayHandResult(
    lineNumber: lineNum + 1,
    finalHand: finalHand,
    handName: evaluation.handName,
    payout: payout,
    winningIndices: evaluation.winningIndices,
    appliedMultiplier: lineMultiplier,
    earnedMultiplier: earnedMultiplier
)
```

Then REMOVE the separate post-loop multiplier update (since `earnedMultiplier` is now captured in the result):
```swift
// After all lines resolved: update UX multipliers for next hand using earnedMultiplier from results
if isUX {
    for (i, result) in results.enumerated() where i < ultimateXMultipliers.count {
        ultimateXMultipliers[i] = result.earnedMultiplier
    }
}
```

- [ ] **Step 2: Update `MiniHandView` to accept and show multiplier badges**

Read `MiniHandView.swift` first. Add two new optional parameters:
```swift
var appliedMultiplier: Int = 1
var earnedMultiplier: Int = 1
```

In the body, overlay badges on the card stack:

**Lower-left badge** (active multiplier): overlay on the hand VStack, shown when `appliedMultiplier > 1`:
```swift
.overlay(alignment: .bottomLeading) {
    if appliedMultiplier > 1 {
        Text("\(appliedMultiplier)\u{00D7}")
            .font(.system(size: 11, weight: .black))
            .foregroundColor(Color(hex: "FFD700"))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.7))
            .cornerRadius(4)
            .padding(3)
    }
}
```

**Upper-left badge** (next hand multiplier): shown when `earnedMultiplier > 1` AND phase is `.result`. Since `MiniHandView` doesn't have `phase`, pass `earnedMultiplier > 1` as a bool `showNextHandMultiplier: Bool = false`:
```swift
.overlay(alignment: .topLeading) {
    if showNextHandMultiplier {
        VStack(alignment: .leading, spacing: 1) {
            Text("NEXT")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
            Text("HAND")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
            Text("\(earnedMultiplier)\u{00D7}")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(Color(hex: "FFD700"))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .background(Color.black.opacity(0.75))
        .cornerRadius(4)
        .padding(3)
    }
}
```

- [ ] **Step 3: Update `MultiHandGrid` to pass multiplier data**

In `miniHandForIndex(_:cardWidth:)`, when passing results to `MiniHandView`, add the multiplier fields:

For pre-draw (card backs): pass `appliedMultiplier` from the caller's multiplier array.
For post-draw: pass `result.appliedMultiplier` and `showNextHandMultiplier: result.earnedMultiplier > 1`.

`MultiHandGrid` needs a new parameter: `multipliers: [Int] = []` for the pre-draw state.

- [ ] **Step 4: Update `PlayView` to thread multiplier data**

In portrait and landscape layout where `MultiHandGrid` is called:
- Pass `multipliers: viewModel.ultimateXMultipliers` to `MultiHandGrid`
- For 1-line UX main card area: add multiplier badge overlay showing `viewModel.ultimateXMultipliers.first ?? 1`

- [ ] **Step 5: Build and test**

```
mcp__xcodebuildmcp__build_sim_name_proj
mcp__xcodebuildmcp__test_sim_name_proj
```

---

## Task 4: Strategy panel — result phase only + on-the-fly user hold

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/UltimateXStrategyPanel.swift`
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/PlayViewModel.swift`
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/PlayView.swift`

### Background

Currently the panel shows during `.dealt` AND `.result`. We want `.result` only.

After draw, the user's actual hold (captured as `userHoldBitmask`) may not be in the pre-computed top 5. If not, compute E[K] on-the-fly and add it as a 6th item, re-sorted by adjustedEV. Mark it distinctly as "Your Hold".

- [ ] **Step 1: Remove multiplier row from `UltimateXStrategyPanel`**

Delete `multiplierRow` and the `if !multipliers.isEmpty { multiplierRow }` block. Remove `multipliers: [Int]` parameter. Remove `MultiplierBadge` private struct (no longer needed here).

- [ ] **Step 2: Add `userHold` and `isComputingUserHold` to `UltimateXStrategyPanel`**

New parameters:
```swift
let userHold: UltimateXHoldOption?       // User's actual hold, if it wasn't in top-5
let isComputingUserHold: Bool            // True while on-the-fly computation is in progress
```

In `holdsList`, after the top holds, add:
```swift
if isComputingUserHold {
    HStack {
        ProgressView().scaleEffect(0.7)
        Text("Computing your hold…")
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.5))
    }
} else if let userHold {
    Divider().background(Color.white.opacity(0.15))
    HoldRow(rank: nil, hold: userHold, dealtCards: dealtCards,
            isSelected: true, label: "Your Hold")
}
```

Update `HoldRow` to accept an optional `rank: Int?` and an optional `label: String?` parameter (to show "Your Hold" instead of "#N").

- [ ] **Step 3: Update panel display condition in `PlayView`**

Change `viewModel.settings.variant.isUltimateX && viewModel.settings.showOptimalFeedback` to also require `viewModel.phase == .result`. Remove the `phase` parameter from `UltimateXStrategyPanel` (no longer needed for gating — the panel always shows its full content).

Portrait:
```swift
if viewModel.settings.variant.isUltimateX
    && viewModel.settings.showOptimalFeedback
    && viewModel.phase == .result {
    UltimateXStrategyPanel(
        topHolds: viewModel.ultimateXTopHolds,
        selectedIndices: viewModel.selectedIndices,
        dealtCards: viewModel.dealtCards,
        isComputing: viewModel.isComputingUXStrategy,
        userHold: viewModel.ultimateXUserHold,
        isComputingUserHold: viewModel.isComputingUXUserHold
    )
    .padding(.horizontal)
} else if ...
```

Same change for landscape.

- [ ] **Step 4: Add user hold computation to `PlayViewModel`**

New state:
```swift
@Published var ultimateXUserHold: UltimateXHoldOption? = nil
@Published var isComputingUXUserHold = false
```

New method `computeUXUserHoldIfNeeded()` called after draw completes (in `performStandardDraw` after `lineResults` is set, or in a post-draw hook):

```swift
private func computeUXUserHoldIfNeeded() async {
    guard settings.variant.isUltimateX else { return }
    // Compute bitmask from selectedIndices (the hold used for the draw)
    let hand = Hand(cards: dealtCards)
    let heldOriginalIndices = Array(selectedIndices).sorted()
    let canonicalIndices = hand.originalIndicesToCanonical(heldOriginalIndices)
    let userBitmask = Hand.bitmaskFromHoldIndices(canonicalIndices)

    // Check if user's hold is already in top-5
    if ultimateXTopHolds.contains(where: { $0.id == userBitmask }) {
        ultimateXUserHold = nil
        return
    }

    // Not in top-5 — compute on the fly
    isComputingUXUserHold = true
    defer { isComputingUXUserHold = false }

    guard let baseResult = try? await StrategyService.shared.lookup(hand: hand, paytableId: settings.selectedPaytableId) else { return }
    guard let baseEV = baseResult.holdEvs[String(userBitmask)] else { return }

    let pc = settings.effectiveUXPlayCount
    let avgMultiplier: Double = ultimateXMultipliers.isEmpty
        ? 1.0
        : Double(ultimateXMultipliers.reduce(0, +)) / Double(ultimateXMultipliers.count)

    let eK = await HoldOutcomeCalculator().computeEK(hand: hand, holdBitmask: userBitmask, paytableId: settings.selectedPaytableId, playCount: pc)
    let adjustedEV = avgMultiplier * 2.0 * baseEV + eK - 1.0

    let canonicalIdxs = Hand.holdIndicesFromBitmask(userBitmask)
    let originalIdxs = hand.canonicalIndicesToOriginal(canonicalIdxs).sorted()

    ultimateXUserHold = UltimateXHoldOption(id: userBitmask, holdIndices: originalIdxs, baseEV: baseEV, eKAwarded: eK, adjustedEV: adjustedEV)
}
```

Wire this into `performStandardDraw()`: after `lineResults = results`, fire:
```swift
if settings.variant.isUltimateX {
    Task { await computeUXUserHoldIfNeeded() }
}
```

Reset in `newHand()`:
```swift
ultimateXUserHold = nil
isComputingUXUserHold = false
```

Check what `Hand.originalIndicesToCanonical` and `Hand.bitmaskFromHoldIndices` are called in the codebase — use whatever exists.

- [ ] **Step 5: Build and test**

```
mcp__xcodebuildmcp__build_sim_name_proj
mcp__xcodebuildmcp__test_sim_name_proj
```

---

## Task 5: 100-play UX multiplier support

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/PlayViewModel.swift`
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/PlayView.swift` (tally view area)

### Background

`performHundredPlayDraw()` currently handles standard 100-play. For UX 100-play, we need to:
1. Apply the 100 per-line multipliers to each hand's payout
2. Update the 100 multipliers from results
3. Show the average next-hand multiplier somewhere in the tally view

- [ ] **Step 1: Update `draw()` to route 100-play UX correctly**

Currently:
```swift
if settings.lineCount == .oneHundred && !settings.variant.isUltimateX {
    await performHundredPlayDraw()
} else {
    await performStandardDraw()
}
```

Change to:
```swift
if settings.lineCount == .oneHundred {
    await performHundredPlayDraw()
} else {
    await performStandardDraw()
}
```

- [ ] **Step 2: Update `performHundredPlayDraw()` to apply UX multipliers**

Read the method carefully. Add UX multiplier logic similar to `performStandardDraw()`:
- Before each line's payout: `let lineMultiplier = (isUX && i < ultimateXMultipliers.count) ? ultimateXMultipliers[i] : 1`
- After payout: `payout = basePayout * lineMultiplier`
- After all 100 lines resolved: update `ultimateXMultipliers[i] = result.earnedMultiplier` for each line

For the `HundredPlayTallyResult` aggregation — tally payout is the SUM of all 100 payouts. With multipliers each line pays differently, so we can't use a simple `count * payPerHand` formula. Adapt the tally to sum actual payouts.

- [ ] **Step 3: Show average next-hand multiplier in tally view**

Find where the 100-play tally result is shown in `PlayView` (search for `HundredPlayTallyView` or similar).

Add a computed property to `PlayViewModel`:
```swift
var averageNextHandMultiplier: Double {
    guard !ultimateXMultipliers.isEmpty else { return 1.0 }
    return Double(ultimateXMultipliers.reduce(0, +)) / Double(ultimateXMultipliers.count)
}
```

In the tally view, when `settings.variant.isUltimateX`, show:
```swift
Text(String(format: "Avg next-hand multiplier: %.1f×", viewModel.averageNextHandMultiplier))
    .font(.system(size: 13))
    .foregroundColor(Color(hex: "FFD700"))
```

- [ ] **Step 4: Build and test**

```
mcp__xcodebuildmcp__build_sim_name_proj
mcp__xcodebuildmcp__test_sim_name_proj
```

---

## Notes

- `Hand.originalIndicesToCanonical` may not exist — check `HoldOutcomeCalculator.swift` for how bitmasks are built from held indices; use same pattern
- `Hand.bitmaskFromHoldIndices` — check if this exists; may need to be computed inline
- The `UXThreePlayResultsRow` fallback is now truly dead code (since `LineCount.three` exists) — can be removed in a cleanup pass
- `PlayVariant` old Codable format (`{"ultimateX": {"playCount": 3}}`) will fail to decode into the new `String`-backed enum — `PlaySettings.init(from:)` uses `decodeIfPresent` which falls back to `.standard` gracefully
