# Ultimate X Play Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Ultimate X as a selectable variant in Play Mode — with a variant picker in PlayStartView, 2× bet cost, per-line multiplier tracking, and a top-5 optimal holds panel using the full EV formula.

**Architecture:** `PlayVariant` is a new enum stored in `PlaySettings`; when set to `.ultimateX(playCount:)`, it changes `coinsPerLine` to 10, drives effective line count, and activates per-line multiplier tracking in `PlayViewModel`. A new `UltimateXStrategyPanel` view replaces the standard EV table when UX is active.

**Tech Stack:** Swift 6, SwiftUI, Swift Testing (`@Test`, `#expect`), XcodeBuildMCP

---

## File Map

| File | Change |
|------|--------|
| `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/PlayModels.swift` | Add `PlayVariant` enum, `UltimateXHoldOption` struct; update `PlaySettings` |
| `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/PlayStartView.swift` | Add variant section; conditionally hide Lines section |
| `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/PlayViewModel.swift` | Multiplier state, UX bet/payout logic, top-5 strategy computation |
| `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/PlayView.swift` | Wire `UltimateXStrategyPanel`; UX multiplier display |
| `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/UltimateXStrategyPanel.swift` | New file: multiplier badge row + top-5 hold list |
| `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/UltimateXPlayModeTests.swift` | New file: unit tests for multiplier logic and bet calculation |

---

## Background

### How Ultimate X Works in Play Mode

- **Bet cost**: 2× normal → `coinsPerLine = 10` (vs. standard 5)
- **Lines**: 3-play, 5-play, or 10-play (multi-hand)
- **Multipliers**: Each line tracks a multiplier (1–12) that applies to the CURRENT hand's payout. After payout, the multiplier is updated based on what hand was won on that line.
- **Next-hand multiplier source**: `UltimateXMultiplierTable.multiplier(for: handName, playCount:, family:)`
- **Strategy**: Optimal hold is determined by `avg_multiplier × 2 × base_EV + E[K] - 1` where `avg_multiplier` = average of all line multipliers, and `E[K]` comes from `HoldOutcomeCalculator.computeEK()`
- **Session reset**: Multipliers reset to all-1s when PlayView disappears (user exits)

### Key Formula

```
adjustedEV(hold) = avg_multiplier × 2.0 × base_EV(hold) + eK_awarded(hold) - 1.0
```

Where:
- `avg_multiplier` = sum of `ultimateXMultipliers` / count (default 1.0 when none)
- `base_EV(hold)` = from strategy file (`StrategyResult.holdEvs[bitmask]`)
- `eK_awarded(hold)` = from `HoldOutcomeCalculator.computeEK(hand, holdBitmask, paytableId, playCount)`

### Stats Key Convention

UX stats are stored separately: `paytableId + "-ux-3play"`, `"-ux-5play"`, `"-ux-10play"`.

---

## Task 1: Add `PlayVariant` and update `PlayModels.swift`

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/PlayModels.swift`
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/UltimateXPlayModeTests.swift`

- [ ] **Step 1: Add `PlayVariant` enum and `UltimateXHoldOption` to `PlayModels.swift`**

Open `PlayModels.swift`. After the `import Foundation` line and before `// MARK: - Bet Denomination`, add:

```swift
// MARK: - Play Variant

enum PlayVariant: Codable, Equatable, Hashable {
    case standard
    case ultimateX(playCount: UltimateXPlayCount)

    var isUltimateX: Bool {
        if case .ultimateX = self { return true }
        return false
    }

    var uxPlayCount: UltimateXPlayCount? {
        if case .ultimateX(let pc) = self { return pc }
        return nil
    }

    var coinsPerLine: Int { isUltimateX ? 10 : 5 }

    /// Suffix appended to paytableId when storing stats for this variant.
    var statsKeySuffix: String {
        switch self {
        case .standard: return ""
        case .ultimateX(let pc): return "-ux-\(pc.rawValue)play"
        }
    }

    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .ultimateX(let pc): return "UX \(pc.displayName)"
        }
    }
}

// MARK: - Ultimate X Hold Option

/// One hold candidate in the top-5 Ultimate X strategy display.
struct UltimateXHoldOption: Identifiable {
    let id: Int              // bitmask
    let holdIndices: [Int]   // original (not canonical) indices
    let baseEV: Double
    let eKAwarded: Double
    let adjustedEV: Double   // avgMultiplier × 2 × baseEV + eKAwarded - 1
}
```

- [ ] **Step 2: Update `PlaySettings` to include `variant`**

In `PlayModels.swift`, find `struct PlaySettings: Codable` and make the following changes:

**Before:**
```swift
struct PlaySettings: Codable {
    var denomination: BetDenomination = .one
    var lineCount: LineCount = .one
    var showOptimalFeedback: Bool = true
    var selectedPaytableId: String = PayTable.lastSelectedId

    // Always bet 5 coins per line (max bet)
    var coinsPerLine: Int { 5 }

    var totalBetCredits: Int {
        lineCount.rawValue * coinsPerLine
    }

    var totalBetDollars: Double {
        Double(totalBetCredits) * denomination.rawValue
    }
}
```

**After:**
```swift
struct PlaySettings: Codable {
    var denomination: BetDenomination = .one
    var lineCount: LineCount = .one
    var showOptimalFeedback: Bool = true
    var selectedPaytableId: String = PayTable.lastSelectedId
    var variant: PlayVariant = .standard

    var coinsPerLine: Int { variant.coinsPerLine }

    /// For UX, uses the play count from the variant; otherwise uses lineCount.
    var effectiveLineCount: Int {
        variant.uxPlayCount?.rawValue ?? lineCount.rawValue
    }

    var totalBetCredits: Int {
        effectiveLineCount * coinsPerLine
    }

    var totalBetDollars: Double {
        Double(totalBetCredits) * denomination.rawValue
    }

    /// The stats key suffix for this variant (appended to paytableId).
    var statsPaytableKey: String {
        settings.selectedPaytableId + variant.statsKeySuffix
    }
}
```

Wait — `settings.selectedPaytableId` is a self-reference. Use `selectedPaytableId` directly:

```swift
    var statsPaytableKey: String {
        selectedPaytableId + variant.statsKeySuffix
    }
```

- [ ] **Step 3: Write failing unit tests**

Create `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/UltimateXPlayModeTests.swift`:

```swift
import Testing
@testable import VideoPokerAcademy

struct UltimateXPlayModeTests {

    // MARK: - PlayVariant

    @Test("Standard variant has coinsPerLine = 5")
    func testStandardCoinsPerLine() {
        let variant = PlayVariant.standard
        #expect(variant.coinsPerLine == 5)
    }

    @Test("UX variant has coinsPerLine = 10")
    func testUXCoinsPerLine() {
        let variant = PlayVariant.ultimateX(playCount: .three)
        #expect(variant.coinsPerLine == 10)
    }

    @Test("UX variant statsKeySuffix matches expected pattern")
    func testStatsKeySuffix() {
        #expect(PlayVariant.ultimateX(playCount: .three).statsKeySuffix == "-ux-3play")
        #expect(PlayVariant.ultimateX(playCount: .five).statsKeySuffix == "-ux-5play")
        #expect(PlayVariant.ultimateX(playCount: .ten).statsKeySuffix == "-ux-10play")
        #expect(PlayVariant.standard.statsKeySuffix == "")
    }

    // MARK: - PlaySettings

    @Test("Standard settings: effectiveLineCount equals lineCount.rawValue")
    func testStandardEffectiveLineCount() {
        var settings = PlaySettings()
        settings.lineCount = .five
        settings.variant = .standard
        #expect(settings.effectiveLineCount == 5)
    }

    @Test("UX settings: effectiveLineCount equals UX play count, ignores lineCount")
    func testUXEffectiveLineCount() {
        var settings = PlaySettings()
        settings.lineCount = .one  // should be ignored for UX
        settings.variant = .ultimateX(playCount: .three)
        #expect(settings.effectiveLineCount == 3)
    }

    @Test("UX settings: totalBetCredits is effectiveLineCount × 10")
    func testUXTotalBetCredits() {
        var settings = PlaySettings()
        settings.variant = .ultimateX(playCount: .five)
        #expect(settings.totalBetCredits == 50)  // 5 lines × 10 coins
    }

    @Test("Standard settings: totalBetCredits is lineCount × 5")
    func testStandardTotalBetCredits() {
        var settings = PlaySettings()
        settings.lineCount = .five
        settings.variant = .standard
        #expect(settings.totalBetCredits == 25)  // 5 lines × 5 coins
    }

    @Test("statsPaytableKey appends variant suffix")
    func testStatsPaytableKey() {
        var settings = PlaySettings()
        settings.selectedPaytableId = "jacks-or-better-9-6"
        settings.variant = .ultimateX(playCount: .three)
        #expect(settings.statsPaytableKey == "jacks-or-better-9-6-ux-3play")
    }

    @Test("Standard statsPaytableKey has no suffix")
    func testStandardStatsPaytableKey() {
        var settings = PlaySettings()
        settings.selectedPaytableId = "jacks-or-better-9-6"
        settings.variant = .standard
        #expect(settings.statsPaytableKey == "jacks-or-better-9-6")
    }
}
```

- [ ] **Step 4: Add backward-compatible `init(from:)` to `PlaySettings`**

**This is required to prevent a crash** on first launch for users with existing saved settings (which won't have a `variant` key). Swift's synthesized `Codable` throws on missing keys — add a custom decoder.

In `PlayModels.swift`, add a custom decoder inside `PlaySettings`:

```swift
// Custom decoder to safely handle existing saved settings that pre-date the `variant` field.
// Swift's synthesized decoder throws DecodingError for missing keys with no default.
init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    denomination = try container.decodeIfPresent(BetDenomination.self, forKey: .denomination) ?? .one
    lineCount = try container.decodeIfPresent(LineCount.self, forKey: .lineCount) ?? .one
    showOptimalFeedback = try container.decodeIfPresent(Bool.self, forKey: .showOptimalFeedback) ?? true
    selectedPaytableId = try container.decodeIfPresent(String.self, forKey: .selectedPaytableId) ?? PayTable.lastSelectedId
    variant = try container.decodeIfPresent(PlayVariant.self, forKey: .variant) ?? .standard
}
```

The synthesized `encode(to:)` is unaffected. `CodingKeys` is still auto-synthesized because Swift generates it when you add a custom `init(from:)` without also providing `encode(to:)`.

- [ ] **Step 5: Add test file to Xcode project**

Add `UltimateXPlayModeTests.swift` to the `VideoPokerAcademyTests` target (not the app target). In Xcode: right-click `VideoPokerAcademyTests` → Add Files.

- [ ] **Step 6: Build**

```
mcp__xcodebuildmcp__build_sim_name_proj
```
Scheme: `VideoPokerAcademy`, simulator: `iPhone 16 Pro Max`
Expected: clean build (or only errors about missing stuff — fix those first).

- [ ] **Step 7: Run tests — confirm they pass**

```
mcp__xcodebuildmcp__test_sim_name_proj
```
Expected: all `UltimateXPlayModeTests` pass.

- [ ] **Step 8: Commit**

```bash
git add ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/PlayModels.swift
git add ios-native/VideoPokerAcademy/VideoPokerAcademyTests/UltimateXPlayModeTests.swift
git commit -m "feat: add PlayVariant enum and UX-aware PlaySettings fields"
```

---

## Task 2: Update `PlayStartView` — variant selector UI

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/PlayStartView.swift`

- [ ] **Step 1: Add a `variantSection` computed property**

In `PlayStartView`, after the `denominationSection` computed property (around line 209), add:

```swift
// MARK: - Variant Section

private var variantSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("Variant")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(AppTheme.Colors.textSecondary)

        FlowLayout(spacing: 8) {
            // Standard chip
            SelectionChip(
                title: "Standard",
                isSelected: settings.variant == .standard
            ) {
                settings.variant = .standard
            }

            // UX chips for each play count
            ForEach(UltimateXPlayCount.allCases, id: \.self) { playCount in
                SelectionChip(
                    title: "UX \(playCount.displayName)",
                    isSelected: settings.variant == .ultimateX(playCount: playCount)
                ) {
                    settings.variant = .ultimateX(playCount: playCount)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        // Bet cost note for UX
        if settings.variant.isUltimateX {
            Text("2× bet cost · \(settings.variant.uxPlayCount?.rawValue ?? 0) simultaneous hands")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
```

- [ ] **Step 2: Update `portraitLayout` to include variant section and conditionally hide lines**

Find the `portraitLayout` computed property. Modify its `VStack` content:

**Before:**
```swift
VStack(alignment: .leading, spacing: 24) {
    headerSection
    popularGamesSection
    allGamesSection
    linesSection
    denominationSection
    optimalFeedbackToggle
    Spacer(minLength: 20)
    startButtonSection
        .frame(maxWidth: .infinity)
}
```

**After:**
```swift
VStack(alignment: .leading, spacing: 24) {
    headerSection
    popularGamesSection
    allGamesSection
    variantSection
    if settings.variant == .standard {
        linesSection
    }
    denominationSection
    optimalFeedbackToggle
    Spacer(minLength: 20)
    startButtonSection
        .frame(maxWidth: .infinity)
}
```

- [ ] **Step 3: Update `landscapeLayout` similarly**

In `landscapeLayout`, find where `allGamesSection` and `linesSection` appear in the left column's `VStack`. Apply the same change: add `variantSection` after `allGamesSection`, and conditionally show `linesSection`.

**Find in the left column VStack:**
```swift
                allGamesSection
                Spacer(minLength: 10)
                linesSection
```

**Replace with:**
```swift
                allGamesSection
                Spacer(minLength: 10)
                variantSection
                Spacer(minLength: 10)
                if settings.variant == .standard {
                    linesSection
                }
```

- [ ] **Step 4: Update `startButtonSection` to show correct bet info when UX**

Find `startButtonSection`. The button currently shows "Start Playing". Wrap the label to show bet context:

Find:
```swift
Text("Start Playing")
    .primaryButton()
```

Replace with:
```swift
if settings.variant.isUltimateX {
    Text("Start Playing · \(settings.totalBetDollars.formatted(.currency(code: "USD")))/hand")
        .primaryButton()
} else {
    Text("Start Playing")
        .primaryButton()
}
```

- [ ] **Step 5: Build**

```
mcp__xcodebuildmcp__build_sim_name_proj
```
Expected: clean build.

- [ ] **Step 6: Visual verification — take a screenshot**

```
mcp__xcodebuildmcp__boot_simulator
mcp__xcodebuildmcp__install_app
mcp__xcodebuildmcp__launch_app
```

Navigate to Play Start screen. Take screenshot to verify:
- Variant chips appear ("Standard", "UX 3-Play", "UX 5-Play", "UX 10-Play")
- Lines section visible when Standard selected
- Lines section hidden when UX variant selected
- Start button shows bet amount when UX active

```
mcp__xcodebuildmcp__screenshot
```

- [ ] **Step 7: Commit**

```bash
git add ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/PlayStartView.swift
git commit -m "feat: add variant selector to PlayStartView with UX play count chips"
```

---

## Task 3: Update `PlayViewModel` — multiplier state and UX draw logic

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/PlayViewModel.swift`
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/UltimateXPlayModeTests.swift`

### Background

`performStandardDraw()` currently loops `settings.lineCount.rawValue` times and calls `calculatePayout(handName:)` which returns credits based on the base paytable. For UX mode, payout per line must be multiplied by `ultimateXMultipliers[lineIndex]` before that multiplier is updated for the next hand.

The `loadPersistedData()` and `updateSettings()` methods load stats using `settings.selectedPaytableId`. These need to use `settings.statsPaytableKey` instead.

- [ ] **Step 1: Add UX multiplier state to `PlayViewModel`**

Find the `// MARK: - Published State` section (near the top of `PlayViewModel`). After the `showDealtWinner` / `dealtWinnerName` lines, add:

```swift
// Ultimate X state
@Published var ultimateXMultipliers: [Int] = []  // per-line, 1–12; empty when standard
@Published var ultimateXTopHolds: [UltimateXHoldOption] = []
@Published var isComputingUXStrategy = false
```

- [ ] **Step 2: Add `initializeUXMultipliers()` and `resetUXState()` methods**

After `endSession()` in the `// MARK: - Stats Management` section, add:

```swift
// MARK: - Ultimate X State

func initializeUXMultipliers() {
    guard let pc = settings.variant.uxPlayCount else { return }
    ultimateXMultipliers = Array(repeating: 1, count: pc.rawValue)
    ultimateXTopHolds = []
}

func resetUXState() {
    ultimateXMultipliers = []
    ultimateXTopHolds = []
    isComputingUXStrategy = false
}
```

- [ ] **Step 3: Fix stats key in `loadPersistedData()`**

Find `loadPersistedData()`:

```swift
self.allTimeStats = await PlayPersistence.shared.loadStats(for: settings.selectedPaytableId)
```

Replace with:
```swift
self.allTimeStats = await PlayPersistence.shared.loadStats(for: settings.statsPaytableKey)
```

- [ ] **Step 4: Fix stats key in `updateSettings()`**

Find `updateSettings(_ newSettings: PlaySettings)`:

```swift
if newSettings.selectedPaytableId != settings.selectedPaytableId {
    allTimeStats = await PlayPersistence.shared.loadStats(for: newSettings.selectedPaytableId)
}
```

Replace with:
```swift
if newSettings.selectedPaytableId != settings.selectedPaytableId
    || newSettings.variant != settings.variant {
    allTimeStats = await PlayPersistence.shared.loadStats(for: newSettings.statsPaytableKey)
}
```

- [ ] **Step 5: Fix stats save in `endSession()`**

Find `endSession()`:

```swift
await PlayPersistence.shared.saveStats(allTimeStats)
```

This already works because `allTimeStats.paytableId` was set when loaded. Verify that `PlayPersistence.saveStats` uses `stats.paytableId` as the key — it does (`statsKeyPrefix + stats.paytableId`). So `PlayStats.paytableId` must be set to `statsPaytableKey` when the stats are first created.

In `PlayPersistence.loadStats(for paytableId: String)`:
```swift
return PlayStats(paytableId: paytableId)
```
The `paytableId` parameter here will now receive the variant-suffixed key (e.g., `"jacks-or-better-9-6-ux-3play"`). This is correct — no change needed to `PlayPersistence`.

- [ ] **Step 6: Update `performStandardDraw()` to apply UX multipliers**

Find `performStandardDraw()`. The current loop iterates `settings.lineCount.rawValue` times. Replace it to use `effectiveLineCount` and apply multipliers:

**Find the entire loop in `performStandardDraw()`:**
```swift
for lineNum in 0..<settings.lineCount.rawValue {
    let (finalHand, newDeck) = performDraw(
        dealtCards: dealtCards,
        heldIndices: selectedIndices,
        deck: deckCopy
    )
    deckCopy = newDeck

    let evaluation = evaluateFinalHand(finalHand)
    let payout = calculatePayout(handName: evaluation.handName)

    let result = PlayHandResult(
        lineNumber: lineNum + 1,
        finalHand: finalHand,
        handName: evaluation.handName,
        payout: payout,
        winningIndices: evaluation.winningIndices
    )
    results.append(result)
}
```

**Replace with:**
```swift
let isUX = settings.variant.isUltimateX
let uxPlayCount = settings.variant.uxPlayCount
let family = currentPaytable?.family ?? .jacksOrBetter

for lineNum in 0..<settings.effectiveLineCount {
    let (finalHand, newDeck) = performDraw(
        dealtCards: dealtCards,
        heldIndices: selectedIndices,
        deck: deckCopy
    )
    deckCopy = newDeck

    let evaluation = evaluateFinalHand(finalHand)
    let basePayout = calculatePayout(handName: evaluation.handName)

    // For UX: multiply payout by the active multiplier for this line
    let lineMultiplier = (isUX && lineNum < ultimateXMultipliers.count)
        ? ultimateXMultipliers[lineNum] : 1
    let payout = basePayout * lineMultiplier

    let result = PlayHandResult(
        lineNumber: lineNum + 1,
        finalHand: finalHand,
        handName: evaluation.handName,
        payout: payout,
        winningIndices: evaluation.winningIndices
    )
    results.append(result)
}

// After all lines resolved: update UX multipliers for next hand
if isUX, let pc = uxPlayCount {
    for (i, result) in results.enumerated() where i < ultimateXMultipliers.count {
        ultimateXMultipliers[i] = UltimateXMultiplierTable.multiplier(
            for: result.handName ?? "no win",
            playCount: pc,
            family: family
        )
    }
}
```

- [ ] **Step 7: Update the `draw()` method — also handle 100-play guard**

In `draw()`, find:

```swift
if settings.lineCount == .oneHundred {
    await performHundredPlayDraw()
} else {
    await performStandardDraw()
}
```

UX is always multi-line, never 100-play. The existing condition stays correct since `effectiveLineCount` never equals 100 for UX — but add a guard comment for clarity:

```swift
// UX is never 100-play; effectiveLineCount is 3/5/10 for UX variants
if settings.lineCount == .oneHundred && !settings.variant.isUltimateX {
    await performHundredPlayDraw()
} else {
    await performStandardDraw()
}
```

- [ ] **Step 8: Add tests for multiplier update logic**

In `UltimateXPlayModeTests.swift`, add:

```swift
// MARK: - Multiplier table lookup

@Test("Multiplier table returns 12 for full house in JoB 3-play")
func testMultiplierFullHouseJoB3Play() {
    let m = UltimateXMultiplierTable.multiplier(
        for: "full house",
        playCount: .three,
        family: .jacksOrBetter
    )
    #expect(m == 12)
}

@Test("Multiplier table returns 1 for no-win")
func testMultiplierNoWin() {
    let m = UltimateXMultiplierTable.multiplier(
        for: "no win",
        playCount: .three,
        family: .jacksOrBetter
    )
    #expect(m == 1)
}

@Test("Multiplier table returns 1 for unknown hand name")
func testMultiplierUnknownHand() {
    let m = UltimateXMultiplierTable.multiplier(
        for: "",
        playCount: .three,
        family: .jacksOrBetter
    )
    #expect(m == 1)
}
```

- [ ] **Step 9: Build and test**

```
mcp__xcodebuildmcp__build_sim_name_proj
mcp__xcodebuildmcp__test_sim_name_proj
```
Expected: all tests pass.

- [ ] **Step 10: Commit**

```bash
git add ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/PlayViewModel.swift
git add ios-native/VideoPokerAcademy/VideoPokerAcademyTests/UltimateXPlayModeTests.swift
git commit -m "feat: add UX multiplier state and multiplied payout logic to PlayViewModel"
```

---

## Task 4: Update `PlayViewModel` — top-5 UX strategy computation

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/PlayViewModel.swift`

### Background

After dealing cards in UX mode, we compute the top-5 optimal holds using:
1. All 31 non-discard hold bitmasks from the strategy file, sorted by base EV
2. For each of the top 5, compute `E[K]` via `HoldOutcomeCalculator.computeEK()`
3. Apply: `adjustedEV = avg_multiplier × 2 × base_EV + eK - 1`
4. Sort top 5 by `adjustedEV` descending

This runs as a fire-and-forget `Task` after deal, so it doesn't block the deal animation. `isComputingUXStrategy` shows a spinner while computing.

- [ ] **Step 1: Add `computeUXTopHolds()` method to `PlayViewModel`**

Find the `// MARK: - Private Helpers` section. After `lookupOptimalStrategy()`, add:

```swift
/// Computes the top-5 optimal holds for Ultimate X using the full EV formula.
/// Fires as a background Task after deal; updates ultimateXTopHolds when done.
private func computeUXTopHolds() async {
    guard let pc = settings.variant.uxPlayCount else { return }

    let hand = Hand(cards: dealtCards)
    let paytableId = settings.selectedPaytableId

    // 1. Get base strategy result (all holdEvs)
    guard let baseResult = try? await StrategyService.shared.lookup(
        hand: hand,
        paytableId: paytableId
    ) else { return }

    // 2. Pick top-5 bitmasks by base EV (skip bitmask 0 = discard all)
    let topBitmasks = baseResult.holdEvs
        .compactMap { key, ev -> (bitmask: Int, ev: Double)? in
            guard let bitmask = Int(key), bitmask != 0 else { return nil }
            return (bitmask: bitmask, ev: ev)
        }
        .sorted { $0.ev > $1.ev }
        .prefix(5)
        .map { $0.bitmask }

    // 3. Average multiplier across all lines
    let avgMultiplier: Double = ultimateXMultipliers.isEmpty
        ? 1.0
        : Double(ultimateXMultipliers.reduce(0, +)) / Double(ultimateXMultipliers.count)

    let calculator = HoldOutcomeCalculator()
    var holdOptions: [UltimateXHoldOption] = []

    for bitmask in topBitmasks {
        guard let baseEV = baseResult.holdEvs[String(bitmask)] else { continue }

        let eK = await calculator.computeEK(
            hand: hand,
            holdBitmask: bitmask,
            paytableId: paytableId,
            playCount: pc
        )
        let adjustedEV = avgMultiplier * 2.0 * baseEV + eK - 1.0

        // Convert canonical indices back to original positions for display
        let canonicalIndices = Hand.holdIndicesFromBitmask(bitmask)
        let originalIndices = hand.canonicalIndicesToOriginal(canonicalIndices).sorted()

        holdOptions.append(UltimateXHoldOption(
            id: bitmask,
            holdIndices: originalIndices,
            baseEV: baseEV,
            eKAwarded: eK,
            adjustedEV: adjustedEV
        ))
    }

    // 4. Sort by adjustedEV descending
    holdOptions.sort { $0.adjustedEV > $1.adjustedEV }

    ultimateXTopHolds = holdOptions
    isComputingUXStrategy = false
}
```

- [ ] **Step 2: Call `computeUXTopHolds()` from `deal()`**

In `deal()`, find `await lookupOptimalStrategy()`. After it, add:

```swift
// For UX mode: fire-and-forget top-5 strategy computation
if settings.variant.isUltimateX {
    isComputingUXStrategy = true
    ultimateXTopHolds = []
    Task {
        await computeUXTopHolds()
    }
}
```

- [ ] **Step 3: Reset UX top holds in `newHand()`**

In `newHand()`, after `strategyResult = nil`, add:

```swift
ultimateXTopHolds = []
isComputingUXStrategy = false
```

- [ ] **Step 4: Initialize UX multipliers on PlayView appear**

In PlayView (next task), `initializeUXMultipliers()` will be called on `.onAppear`. To support this, make sure `initializeUXMultipliers()` is callable from the view — it's already a public (internal) method on `PlayViewModel` from Task 3.

- [ ] **Step 5: Build**

```
mcp__xcodebuildmcp__build_sim_name_proj
```
Expected: clean build.

- [ ] **Step 6: Commit**

```bash
git add ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/PlayViewModel.swift
git commit -m "feat: add computeUXTopHolds() - top-5 optimal holds using full UX EV formula"
```

---

## Task 5: Create `UltimateXStrategyPanel.swift`

**Files:**
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/UltimateXStrategyPanel.swift`

This view shows:
1. A row of multiplier badges (one per line)
2. A spinner while computing
3. Once computed: top-5 holds with adjusted EVs, highlighting the user's current selection

- [ ] **Step 1: Create the file**

```swift
import SwiftUI

struct UltimateXStrategyPanel: View {
    let multipliers: [Int]
    let topHolds: [UltimateXHoldOption]
    let selectedIndices: Set<Int>
    let dealtCards: [Card]
    let isComputing: Bool
    let phase: PlayPhase

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !multipliers.isEmpty {
                multiplierRow
            }

            if phase == .dealt || phase == .result {
                strategySection
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Multiplier Row

    private var multiplierRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Active Multipliers")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))

            HStack(spacing: 6) {
                ForEach(multipliers.indices, id: \.self) { i in
                    MultiplierBadge(multiplier: multipliers[i], lineNumber: i + 1)
                }
            }
        }
    }

    // MARK: - Strategy Section

    @ViewBuilder
    private var strategySection: some View {
        if isComputing {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white.opacity(0.6))
                Text("Computing optimal holds…")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
        } else if !topHolds.isEmpty {
            holdsList
        }
    }

    private var holdsList: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Top Holds")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))

            ForEach(Array(topHolds.enumerated()), id: \.element.id) { rank, hold in
                HoldRow(
                    rank: rank + 1,
                    hold: hold,
                    dealtCards: dealtCards,
                    isSelected: Set(hold.holdIndices) == selectedIndices
                )
            }
        }
    }
}

// MARK: - MultiplierBadge

private struct MultiplierBadge: View {
    let multiplier: Int
    let lineNumber: Int

    var isActive: Bool { multiplier > 1 }

    var body: some View {
        VStack(spacing: 2) {
            Text("\(multiplier)×")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isActive ? Color(hex: "FFD700") : .white.opacity(0.4))
            Text("L\(lineNumber)")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive
                    ? Color(hex: "FFD700").opacity(0.15)
                    : Color.white.opacity(0.05)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(
                    isActive ? Color(hex: "FFD700").opacity(0.4) : Color.clear,
                    lineWidth: 1
                )
        )
    }
}

// MARK: - HoldRow

private struct HoldRow: View {
    let rank: Int
    let hold: UltimateXHoldOption
    let dealtCards: [Card]
    let isSelected: Bool

    private var cardLabel: String {
        guard !hold.holdIndices.isEmpty else { return "Draw All" }
        return hold.holdIndices.compactMap { i -> String? in
            guard i < dealtCards.count else { return nil }
            let c = dealtCards[i]
            return "\(c.rank.shortName)\(c.suit.symbol)"
        }.joined(separator: " ")
    }

    var body: some View {
        HStack(spacing: 8) {
            // Rank badge
            Text("#\(rank)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
                .frame(width: 24, alignment: .leading)

            // Card labels
            Text(cardLabel)
                .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? Color(hex: "00FF9F") : .white)
                .lineLimit(1)

            Spacer()

            // Adjusted EV
            Text(String(format: "%.2f", hold.adjustedEV))
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(rank == 1 ? Color(hex: "FFD700") : .white.opacity(0.6))

            // Selected indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "00FF9F"))
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isSelected ? Color(hex: "00FF9F").opacity(0.08) : Color.clear)
        )
    }
}
```

Note: `Rank.shortName` and `Suit.symbol` may not exist yet. Check `Hand.swift` or `Models/Hand.swift` for existing card display helpers. If they don't exist, use `rank.displayName` and `suit.rawValue` or equivalent. Look at how `CardView.swift` renders card labels and use the same approach.

- [ ] **Step 2: Verify card display helpers exist**

Search for how cards are labeled in existing UI:

```bash
grep -n "shortName\|symbol\|displayName" ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/Hand.swift
grep -n "rank.*display\|suit.*symbol" ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Components/CardView.swift
```

Adjust `cardLabel` in `HoldRow` to use the actual card label properties from the codebase. Common patterns:
- `c.rank.symbol` → "A", "K", "Q"...
- `c.suit.symbol` → "♠", "♥", "♦", "♣"
- Or `c.rank.displayName` if symbol doesn't exist

- [ ] **Step 3: Add file to Xcode project**

Add to `VideoPokerAcademy` target, in the `Views/Play` group.

- [ ] **Step 4: Build**

```
mcp__xcodebuildmcp__build_sim_name_proj
```
Fix any compilation errors (missing card label properties, etc.).

- [ ] **Step 5: Commit**

```bash
git add "ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/UltimateXStrategyPanel.swift"
git commit -m "feat: create UltimateXStrategyPanel with multiplier badges and top-5 hold list"
```

---

## Task 6: Wire everything in `PlayView.swift`

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/PlayView.swift`

- [ ] **Step 1: Initialize UX multipliers on appear and reset on disappear**

Find `mainContent` → the `.onAppear` and `.onDisappear` handlers (or the GeometryReader's `.onAppear`).

In `PlayView.body`, find `.onDisappear` (it currently only invalidates a timer). Add:

```swift
.onAppear {
    if viewModel.settings.variant.isUltimateX {
        viewModel.initializeUXMultipliers()
    }
}
.onDisappear {
    countingTimer?.invalidate()
    countingTimer = nil
    viewModel.resetUXState()
}
```

Note: there's already a `.onDisappear` in `PlayView.body`. Find it and add `viewModel.resetUXState()` inside it.

- [ ] **Step 2: Add `UltimateXStrategyPanel` in portrait layout bottom section**

In `portraitLayout`, find:

```swift
// EV Options Table (scrollable when visible)
if viewModel.settings.showOptimalFeedback && viewModel.phase == .result {
    ScrollView {
        evOptionsTable
            .padding(.horizontal)
    }
    .frame(maxHeight: 180)
}
```

Replace with:

```swift
// UX Strategy Panel (dealt phase + result phase) or standard EV table (result only)
if viewModel.settings.variant.isUltimateX && viewModel.settings.showOptimalFeedback {
    UltimateXStrategyPanel(
        multipliers: viewModel.ultimateXMultipliers,
        topHolds: viewModel.ultimateXTopHolds,
        selectedIndices: viewModel.selectedIndices,
        dealtCards: viewModel.dealtCards,
        isComputing: viewModel.isComputingUXStrategy,
        phase: viewModel.phase
    )
    .padding(.horizontal)
} else if viewModel.settings.showOptimalFeedback && viewModel.phase == .result {
    ScrollView {
        evOptionsTable
            .padding(.horizontal)
    }
    .frame(maxHeight: 180)
}
```

- [ ] **Step 3: Create `UXThreePlayResultsRow` for 3-play display**

In `UltimateXStrategyPanel.swift`, add at the bottom of the file (outside `UltimateXStrategyPanel`):

```swift
struct UXThreePlayResultsRow: View {
    let results: [PlayHandResult]
    let multipliers: [Int]
    let denomination: Double
    let phase: PlayPhase

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                VStack(spacing: 2) {
                    // Multiplier badge
                    let multiplier = i < multipliers.count ? multipliers[i] : 1
                    Text("\(multiplier)×")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(multiplier > 1 ? Color(hex: "FFD700") : .white.opacity(0.4))

                    // Hand result (if in result phase)
                    if phase == .result, i < results.count {
                        let result = results[i]
                        Text(result.handName ?? "")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                        Text(result.payout > 0 ? "+\(result.payout)" : "")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(result.payout > 0 ? Color(hex: "00FF9F") : .clear)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.05))
                )
            }
        }
        .padding(.horizontal, 8)
    }
}
```

Build after this step to verify `UXThreePlayResultsRow` compiles before it is referenced.

```
mcp__xcodebuildmcp__build_sim_name_proj
```

- [ ] **Step 4: Update multi-hand display in portrait layout**

The portrait layout currently checks `viewModel.settings.lineCount != .one` to show `MultiHandGrid`. For UX 3/5/10-play, `effectiveLineCount` is 3/5/10 but `lineCount` may still be `.one` (default). Update the condition to use `effectiveLineCount`.

Find:
```swift
} else if viewModel.settings.lineCount != .one {
    MultiHandGrid(
        lineCount: viewModel.settings.lineCount,
        results: gridResults,
        phase: viewModel.phase,
        denomination: viewModel.settings.denomination.rawValue,
        showAsWild: viewModel.currentPaytable?.isDeucesWild ?? false
    )
}
```

Replace with:

```swift
} else if viewModel.settings.effectiveLineCount > 1 {
    if let lineCount = LineCount(rawValue: viewModel.settings.effectiveLineCount) {
        MultiHandGrid(
            lineCount: lineCount,
            results: gridResults,
            phase: viewModel.phase,
            denomination: viewModel.settings.denomination.rawValue,
            showAsWild: viewModel.currentPaytable?.isDeucesWild ?? false
        )
    } else {
        // UX 3-play: simple 3-line result strip (LineCount has no .three case)
        UXThreePlayResultsRow(
            results: viewModel.lineResults,
            multipliers: viewModel.ultimateXMultipliers,
            denomination: viewModel.settings.denomination.rawValue,
            phase: viewModel.phase
        )
    }
}
```

- [ ] **Step 5: Update landscape layout — multi-hand grid condition**

In `landscapeLeftColumn` (around line 442 in PlayView.swift), find:

```swift
} else if viewModel.settings.lineCount != .one {
    MultiHandGrid(
        lineCount: viewModel.settings.lineCount,
        results: gridResults,
        phase: viewModel.phase,
        denomination: viewModel.settings.denomination.rawValue,
        showAsWild: viewModel.currentPaytable?.isDeucesWild ?? false
    )
    .padding(.horizontal, 8)
}
```

Replace with the same pattern as Step 3:

```swift
} else if viewModel.settings.effectiveLineCount > 1 {
    if let lineCount = LineCount(rawValue: viewModel.settings.effectiveLineCount) {
        MultiHandGrid(
            lineCount: lineCount,
            results: gridResults,
            phase: viewModel.phase,
            denomination: viewModel.settings.denomination.rawValue,
            showAsWild: viewModel.currentPaytable?.isDeucesWild ?? false
        )
        .padding(.horizontal, 8)
    } else {
        UXThreePlayResultsRow(
            results: viewModel.lineResults,
            multipliers: viewModel.ultimateXMultipliers,
            denomination: viewModel.settings.denomination.rawValue,
            phase: viewModel.phase
        )
        .padding(.horizontal, 8)
    }
}
```

- [ ] **Step 6: Update landscape layout — strategy panel**

In `landscapeLeftColumn`, find the EV strategy section (around line 461):

```swift
// Strategy/EV options table (when feedback is shown)
if viewModel.settings.showOptimalFeedback && viewModel.phase == .result {
    landscapeEvOptionsTable
        .padding(.horizontal, 8)
}
```

Replace with:

```swift
// Strategy panel — UX shows top-5 during dealt+result; standard shows EV table at result
if viewModel.settings.variant.isUltimateX && viewModel.settings.showOptimalFeedback {
    UltimateXStrategyPanel(
        multipliers: viewModel.ultimateXMultipliers,
        topHolds: viewModel.ultimateXTopHolds,
        selectedIndices: viewModel.selectedIndices,
        dealtCards: viewModel.dealtCards,
        isComputing: viewModel.isComputingUXStrategy,
        phase: viewModel.phase
    )
    .padding(.horizontal, 8)
} else if viewModel.settings.showOptimalFeedback && viewModel.phase == .result {
    landscapeEvOptionsTable
        .padding(.horizontal, 8)
}
```

- [ ] **Step 7: Build**

```
mcp__xcodebuildmcp__build_sim_name_proj
```
Fix any issues.

- [ ] **Step 8: Run all tests**

```
mcp__xcodebuildmcp__test_sim_name_proj
```
Expected: all tests pass.

- [ ] **Step 9: Visual verification — full UX gameplay flow**

```
mcp__xcodebuildmcp__boot_simulator
mcp__xcodebuildmcp__install_app
mcp__xcodebuildmcp__launch_app
mcp__xcodebuildmcp__screenshot
```

1. Navigate to Play → tap "UX 3-Play" → confirm Lines section is hidden, bet shows 2× cost
2. Tap "Start Playing" → deal a hand
3. Verify: multiplier badges show, strategy panel computes (spinner) then shows top-5 holds
4. Hold some cards, draw → verify line payouts show correctly, multipliers update
5. Deal next hand → verify updated multipliers appear in strategy computation

Take screenshots at each stage to verify correctness.

- [ ] **Step 10: Commit**

```bash
git add ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/PlayView.swift
git add "ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/UltimateXStrategyPanel.swift"
git commit -m "feat: wire UltimateXStrategyPanel and UX multiplier display in PlayView"
```

---

## Task 7: Final integration — `ActiveHandState` and persistence compatibility

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/PlayModels.swift`

### Background

`ActiveHandState` (used for background save/restore) includes `settings: PlaySettings`. Since `PlaySettings` now has `variant: PlayVariant`, and `PlayVariant` uses an associated value enum (`ultimateX(playCount:)`), `Codable` conformance needs verification. Swift synthesizes `Codable` for enums with associated values only when the associated types are also `Codable`. `UltimateXPlayCount` has `rawValue: Int` and needs `Codable`.

- [ ] **Step 1: Add `Codable` to `UltimateXPlayCount` if missing**

In `UltimateXModels.swift`, find:

```swift
enum UltimateXPlayCount: Int, CaseIterable, Identifiable {
```

Ensure `Codable` is included:

```swift
enum UltimateXPlayCount: Int, CaseIterable, Identifiable, Codable {
```

- [ ] **Step 2: Build and verify `PlaySettings` encodes/decodes cleanly**

Add a quick test to `UltimateXPlayModeTests.swift`:

```swift
@Test("PlaySettings with UX variant round-trips through Codable")
func testPlaySettingsCodable() throws {
    var settings = PlaySettings()
    settings.variant = .ultimateX(playCount: .five)
    settings.selectedPaytableId = "jacks-or-better-9-6"

    let data = try JSONEncoder().encode(settings)
    let decoded = try JSONDecoder().decode(PlaySettings.self, from: data)
    #expect(decoded.variant == .ultimateX(playCount: .five))
    #expect(decoded.selectedPaytableId == "jacks-or-better-9-6")
}
```

- [ ] **Step 3: Build and run tests**

```
mcp__xcodebuildmcp__build_sim_name_proj
mcp__xcodebuildmcp__test_sim_name_proj
```
Expected: all tests pass including the new Codable round-trip test.

- [ ] **Step 4: Full regression test pass**

Run the full test suite:

```
mcp__xcodebuildmcp__test_sim_name_proj
```
Expected: all existing tests pass (no regressions in standard play mode).

- [ ] **Step 5: Commit**

```bash
git add ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/PlayModels.swift
git add ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/UltimateXModels.swift
git add ios-native/VideoPokerAcademy/VideoPokerAcademyTests/UltimateXPlayModeTests.swift
git commit -m "feat: ensure UX variant persists correctly through Codable + final integration"
```

---

## Notes for Implementer

### Card display in `HoldRow`

Check `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Components/CardView.swift` and `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/Hand.swift` for how rank and suit are displayed. The `CardView` uses rank/suit properties — use whatever exists there. Common patterns in this codebase:
- Rank symbol: likely `rank.symbol` or a `displayChar` property
- Suit symbol: likely `suit.symbol` returning "♠"/"♥"/"♦"/"♣"

### EK Table stubs

The `UltimateXEKTable` is still populated with stubs (1.0). For draw-all and single-card holds, `HoldOutcomeCalculator` returns 1.0, which degrades the full formula to approximately the simplified formula. This is acceptable for now. See `docs/superpowers/plans/2026-03-25-ultimate-x-ek-precomputation.md` for the task to populate real values.

### Standard play mode regression

The changes to `PlaySettings` are backward-compatible:
- `variant` defaults to `.standard`
- `coinsPerLine` returns `5` for standard (same as before)
- `effectiveLineCount` returns `lineCount.rawValue` for standard (same behavior)
- Existing stats keys are unchanged for standard (suffix is "")

**Backward compatibility**: The custom `init(from:)` decoder was added in Task 1, Step 4. Existing `PlaySettings` JSON (without `variant` key) will decode safely with `.standard` as the fallback.
