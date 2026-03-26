# Ultimate X Play Mode Design

**Date:** 2026-03-25
**Status:** Ready for implementation

---

## Overview

Add Ultimate X as a selectable variant in Play Mode. Players pick a variant type (Standard or Ultimate X with 3/5/10-play) alongside game family and pay table. Play mode then handles the 2× bet cost, per-line multiplier tracking, and displays top-5 optimal holds computed using the full Ultimate X EV formula.

---

## User-Facing Changes

### PlayStartView — New "Variant" Section

A new chip-based selector appears between the game selector and lines section:

```
Variant
[Standard]  [UX 3-Play]  [UX 5-Play]  [UX 10-Play]
```

- When any UX variant is selected, the **"Lines" section is hidden** (play count is determined by the variant).
- The start button label shows the effective bet amount (e.g., "Start Playing — $30/hand").

### PlayView — Multiplier Badges + Strategy Panel

When UX is active, two new elements appear below the dealt cards:

**1. Multiplier Badge Row:**
```
Line 1   Line 2   Line 3
 12×       1×       4×
```
Shows the multiplier currently active for each line (applying to THIS hand's payout).

**2. Top-5 Optimal Holds Panel** (visible when "Show Optimal Play Feedback" is on):
```
Avg multiplier: 5.7×

 #  Hold             Adj EV
 1  K♠ K♦           8.42   ← best
 2  K♠ K♦ 9♣        7.81
 3  K♠ K♦ 9♣ Q♥     6.55
 4  K♠               5.12
 5  K♠ K♦ 9♣ Q♥ 7♣  4.98
```

The currently-selected hold is highlighted.

---

## Data Model Changes

### `PlayVariant` (new, in `PlayModels.swift`)

```swift
enum PlayVariant: Codable, Equatable {
    case standard
    case ultimateX(playCount: UltimateXPlayCount)

    var isUltimateX: Bool { if case .ultimateX = self { return true }; return false }
    var uxPlayCount: UltimateXPlayCount? { if case .ultimateX(let pc) = self { return pc }; return nil }
    var coinsPerLine: Int { isUltimateX ? 10 : 5 }
    var statsKeySuffix: String { ... }  // "" for standard, "-ux-3play" etc. for UX
}
```

### `PlaySettings` updates

- Add `var variant: PlayVariant = .standard`
- Replace hardcoded `coinsPerLine: Int { 5 }` with `var coinsPerLine: Int { variant.coinsPerLine }`
- Add `var effectiveLineCount: Int`:
  - Returns `variant.uxPlayCount?.rawValue ?? lineCount.rawValue`
- Update `totalBetCredits` to use `effectiveLineCount`
- Update stats key to include variant suffix: `paytableId + variant.statsKeySuffix`

### `UltimateXHoldOption` (new struct, in `PlayModels.swift`)

```swift
struct UltimateXHoldOption: Identifiable {
    let id: Int  // bitmask
    let holdIndices: [Int]
    let baseEV: Double
    let eKAwarded: Double
    let adjustedEV: Double  // avgMultiplier × 2 × baseEV + eKAwarded - 1
}
```

---

## PlayViewModel Changes

### New State

```swift
var ultimateXMultipliers: [Int] = []         // one per line, 1–12; empty when standard
var ultimateXTopHolds: [UltimateXHoldOption] = []  // computed after each deal
var isComputingUXStrategy = false
```

### Multiplier Lifecycle

- **Init**: When PlayView appears with UX variant, call `initializeUXMultipliers()`
  → `ultimateXMultipliers = Array(repeating: 1, count: playCount.rawValue)`
- **Reset**: When PlayView disappears (user exits) → `ultimateXMultipliers = []`
- **Update after draw**: For each line i, look up `UltimateXMultiplierTable.multiplier(for: result.handName ?? "no win", playCount:, family:)`

### Bet Calculation

Uses `settings.effectiveLineCount` and `settings.coinsPerLine` — no special-casing needed once `PlaySettings` is updated.

### Draw Phase

In `performStandardDraw()`, when variant is UX:
- Payout for line i = `base_credits × ultimateXMultipliers[i]`
  (multiplier applied **before** updating for next hand)
- After all lines resolved, update `ultimateXMultipliers[i]` from each `lineResults[i].handName`

### Strategy Computation

New method `computeUXTopHolds()` called after `deal()`:

```
1. Get StrategyResult (all holdEvs) from StrategyService
2. Filter out bitmask=0, sort by base EV descending, take top 5
3. For each of the 5 bitmasks:
   a. Compute eK = await HoldOutcomeCalculator().computeEK(hand, holdBitmask, paytableId, playCount)
   b. avgM = average of ultimateXMultipliers (default 1.0 if empty)
   c. adjustedEV = avgM × 2 × baseEV + eK - 1
4. Sort top 5 by adjustedEV descending
5. Publish to ultimateXTopHolds
```

Runs concurrently with deal animation (fire-and-forget Task).

---

## New View: `UltimateXStrategyPanel.swift`

Location: `Views/Play/UltimateXStrategyPanel.swift`

Inputs:
- `multipliers: [Int]` — per-line values
- `topHolds: [UltimateXHoldOption]`
- `selectedIndices: Set<Int>` — user's current hold
- `dealtCards: [Card]`
- `isComputing: Bool` — show spinner while top-5 compute

Layout:
- Multiplier badge row (collapsible for 10-play)
- Loading indicator while `isComputing`
- Once loaded: ranked hold list with card abbreviations and adjusted EV

---

## Stats Tracking

`PlayStats` is persisted with key `"playStats_" + paytableId + variant.statsKeySuffix`.

Examples:
- Standard JoB 9/6: `playStats_jacks-or-better-9-6`
- UX 3-play JoB 9/6: `playStats_jacks-or-better-9-6-ux-3play`
- UX 5-play JoB 9/6: `playStats_jacks-or-better-9-6-ux-5play`

---

## Decisions Captured

| Decision | Choice | Reason |
|----------|--------|--------|
| Multiplier persistence | Reset on PlayView exit | Simple, consistent; no cross-session confusion |
| EV formula | Full: M×2×baseEV + E[K]−1 | More accurate; matches benchmark work |
| Stats tracking | Separate per-variant | Mixed stats would corrupt return % reporting |
| Strategy scope | Top 5 by base EV | Computationally feasible; rarely is rank 6+ ever optimal |
| Variant selector location | PlayStartView (not GameSelectorView) | GameSelectorView is shared; UX is play-mode-only |
| Lines section | Hidden when UX active | UX play count replaces line selection |

---

## Out of Scope (This Feature)

- UX in Quiz or Training mode
- UX in Simulator
- EK table population (separate task; full formula degrades gracefully to simplified when E[K]=1.0)
- UX Bonus Streak variant
