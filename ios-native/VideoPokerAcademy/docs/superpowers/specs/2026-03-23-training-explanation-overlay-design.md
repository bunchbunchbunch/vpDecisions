# Training Mode: Post-Submit Explanation Overlay

**Date:** 2026-03-23
**Status:** Approved

---

## Overview

After the user submits their hold selection in a training lesson, an explanation panel replaces the pay table area (portrait) or overlays the card area (landscape). The panel shows whether the answer was correct, the lesson explanation text from `training-mode-plan.md`, and the optimal hold. When incorrect, it also shows a side-by-side "You Held / Optimal Hold" card comparison.

---

## Trigger

`TrainingLessonQuizViewModel.showFeedback == true` (set by `submit()`)

---

## Portrait Layout

**File:** `VideoPokerAcademy/Views/Training/TrainingLessonQuizView.swift`

**Placement:** `TrainingExplanationView` replaces `CompactPayTableView` at the top of the `ScrollView` in `portraitQuizLayout`. Conditionally swapped:

```swift
if viewModel.showFeedback {
    TrainingExplanationView(...)
} else {
    CompactPayTableView(...)
}
```

The cards area below is **unchanged** — the hand stays visible with the user's selections still highlighted.

**Existing UI to remove (search by content, line numbers are approximate):**
- The floating feedback pill inside the cards `ZStack` (~lines 456–474, showing "Correct!" / "Incorrect" + EV Lost) → **removed**, consolidated into `TrainingExplanationView`
- The explanation card at the bottom of the `ScrollView` (~lines 583–600, yellow "💡 Explanation" label) → **removed**, consolidated into `TrainingExplanationView`
- The `EV options table` (~lines 497–579) → **preserved**. Its existing render condition (`showFeedback && strategyResult != nil`) is unchanged — do not modify it when removing the feedback pill.

**Height:** `TrainingExplanationView` is flexible height. The surrounding `ScrollView` handles overflow — no internal scrolling in the component.

### Correct answer (portrait)
```
┌──────────────────────────────────────┐
│  ✓ CORRECT          (green banner)   │
├──────────────────────────────────────┤
│  💡 LESSON                           │
│  Low pair is better than unsuited AK │
│  — pairs give draws to trips.        │
│                                      │
│  OPTIMAL HOLD                        │
│  [ 6♥ ]  [ 6♦ ]   (blue borders)    │
└──────────────────────────────────────┘
[ cards stay visible below, unchanged  ]
[ EV options table (if strategy avail) ]
```

### Incorrect answer (portrait)
```
┌──────────────────────────────────────┐
│  ✗ INCORRECT  ·  EV Lost: 0.043 (red)│
├──────────────────────────────────────┤
│  💡 LESSON                           │
│  Low pair is better than unsuited AK │
│  — pairs give draws to trips.        │
│                                      │
│  YOU HELD           OPTIMAL HOLD     │
│  [ A♠ ][ K♣ ]      [ 6♥ ][ 6♦ ]    │
│  (red borders)      (green borders)  │
└──────────────────────────────────────┘
[ cards stay visible below, unchanged  ]
[ EV options table (if strategy avail) ]
```

---

## Landscape Layout

**File:** `VideoPokerAcademy/Views/Training/TrainingLessonQuizView.swift`

**Placement:** The right card area is wrapped in a `ZStack`. When `showFeedback` is true, `TrainingExplanationView` layers on top with `.frame(maxWidth: .infinity, maxHeight: .infinity)` covering the cards entirely.

**Left panel:** Unchanged — progress bar, hand count, EV options table preserved.

**Next button:** Stays at the bottom of the right `VStack` as a sibling of the `ZStack`, not inside it. Structural sketch:
```swift
VStack {
    ZStack {
        cardsAreaView()              // existing cards
        if viewModel.showFeedback {
            TrainingExplanationView(...) // overlay
        }
    }
    actionButton()                   // always below ZStack, always tappable
}
```

**Existing UI to remove in landscape:**
- The existing explanation card in the left panel's `ScrollView` → **removed**
- The floating feedback pill in the landscape card area → **removed**
- EV options table in the left panel → **preserved**

**The landscape overlay includes both:**
1. A full 5-card hand row (for context, since the actual cards are hidden behind the overlay)
2. The hold chip comparison below it

### Full-hand card highlighting in landscape (incorrect answer)
These rules apply **only to the full-hand row** — they are independent of the YOU HELD / OPTIMAL HOLD chip sections below, which follow their own coloring (YOU HELD = always red, OPTIMAL HOLD = always green).

| Card state | Full-hand row border |
|------|--------|
| User held AND it's in optimal hold (correct hold) | Green border |
| User held AND it's NOT in optimal hold (wrong hold) | Red border |
| User did NOT hold AND it IS in optimal hold (missed) | Green border, dimmed background |
| User did NOT hold AND it's NOT in optimal hold (correct discard) | No border, dimmed |

**When `optimalHoldCards` is empty (discard all):** No card is "in optimal hold", so every held card = red border, every non-held card = no border + dimmed. The table applies literally.

### Full-hand card highlighting in landscape (correct answer)
All held cards: blue borders. All non-held (correctly discarded): `.clear` border (visually borderless), 40% opacity. The "missed optimal" state is impossible when `isCorrect == true` by definition.

### Correct answer (landscape overlay)
```
┌────────────────┬────────────────────────────┐
│  Left panel    │  ✓ CORRECT   (green)        │
│  (unchanged)   │  💡 LESSON                  │
│                │  Low pair is better...      │
│                │  [6♥][6♦][A♠][K♣][3♠]  ←full hand
│  [Next →]      │  (6♥ 6♦ = blue, others dim) │
│  (below ZStack)│  OPTIMAL HOLD               │
│                │  [ 6♥ ][ 6♦ ]  (blue)      │
└────────────────┴────────────────────────────┘
```

### Incorrect answer (landscape overlay)
```
┌────────────────┬────────────────────────────┐
│  Left panel    │  ✗ INCORRECT · EV Lost:0.043│
│  (unchanged)   │  💡 LESSON                  │
│                │  Low pair is better...      │
│                │  [6♥][6♦][A♠][K♣][3♠]  ←full hand
│  [Next →]      │  6♥6♦=green border+dimmed   │
│  (below ZStack)│  (missed optimal, not held) │
│                │  A♠K♣=red (wrong hold)      │
│                │  3♠=no border+dimmed        │
│                │  YOU HELD    OPTIMAL HOLD   │
│                │  [A♠][K♣]    [6♥][6♦]      │
└────────────────┴────────────────────────────┘
```
The full-hand highlighting table is authoritative. The diagram comments above map directly to the table rows.

---

## Orientation Handling

`showFullHand` is computed at the **call site** from `GeometryReader` (the existing `currentlyLandscape` calculation: `geometry.size.width > geometry.size.height`). The component re-evaluates automatically on rotation since the parent view already re-renders on geometry change.

---

## Data Sources

| Field | Source |
|-------|--------|
| Correct/Incorrect | `viewModel.isCorrect` |
| EV Lost | `viewModel.evLost`; shown only when `evLost > 0` |
| Lesson text | `viewModel.currentHand.practiceHand.explanation` |
| Optimal hold cards | `viewModel.currentHand.practiceHand.holdCards` (e.g. `["6h", "6d"]`; empty array = discard all) |
| User's held cards | `viewModel.selectedIndices.sorted().map { viewModel.currentHand.hand.cards[$0] }` (same string format, e.g. `"Ah"`, `"Kc"`) |
| Full hand (landscape) | `viewModel.currentHand.hand.cards` (all 5 in deal order) |

---

## New Component: `TrainingExplanationView`

**File:** `Views/Training/TrainingExplanationView.swift`

```swift
struct TrainingExplanationView: View {
    let isCorrect: Bool
    let evLost: Double            // 0 when correct or no EV data
    let explanation: String
    let optimalHoldCards: [String]  // empty = discard all
    let userHeldCards: [String]     // empty = user drew all
    let allCards: [String]          // always pass the full 5-card hand; ignored when showFullHand == false
    let showFullHand: Bool          // true in landscape, false in portrait
}
```

### Rendering rules

**Banner (always shown, ~44pt height):**
- Correct: background `#2ecc71`, "✓ CORRECT". Never show EV Lost on correct answers regardless of `evLost` value.
- Incorrect: background `#e74c3c`, "✗ INCORRECT" + "  ·  EV Lost: X.XXX" appended only when `evLost > 0` (3 decimal places). If answer is incorrect but `evLost == 0`, banner reads "✗ INCORRECT" with no EV suffix.

**Lesson section (always shown, 12pt internal padding):**
- Label: "💡 LESSON" in `#f1c40f`, 10pt, bold, letter-spaced
- Text: explanation string, white at 90% opacity, 12pt, 8pt gap below label

**Full-hand row (landscape only, `showFullHand == true`):**
- 5 mini card chips in deal order, 8pt gaps
- Apply highlighting per the tables above
- 8pt gap below row

**Hold chips section:**
- **Correct:** Single "OPTIMAL HOLD" column, blue (`#3498db`) bordered chips
- **Incorrect:** Two columns, "YOU HELD" (red `#e74c3c`) left and "OPTIMAL HOLD" (green `#2ecc71`) right. Columns are `HStack`-based, content-width (not equal-width). No maximum card count constraint — all held/optimal cards are shown. Chips wrap if needed.
- **Empty optimalHoldCards:** Render "DRAW ALL" in place of chips — white, 12pt, normal weight
- **Empty userHeldCards:** Render "DREW ALL" in the YOU HELD column — white, 12pt, normal weight. The OPTIMAL HOLD column still renders its chips normally.

**Section spacing:** 8pt between banner and lesson, 8pt between lesson and full-hand row, 8pt between full-hand row and hold chips, 12pt bottom padding inside the panel.

### Mini card chip style (used in overlay — NOT the full `CardView`)
- Size: ~32pt wide × 40pt tall
- Background: `#2c3e50`
- Border: colored per state (see above), 2pt width, 6pt corner radius
- Text: card string rendered as rank + suit symbol (e.g. "6♥"), bold, 13pt. Reuse the existing rank/suit parsing already used by `CardView` in the codebase — do not invent a new mapping.
- Red suits (♥ ♦) in red; black suits (♠ ♣) in white

---

## Integration Points

### `TrainingLessonQuizView.swift`

**Portrait (`portraitQuizLayout`):**
1. Swap `CompactPayTableView` → `TrainingExplanationView` as described above
2. Remove floating feedback pill from cards `ZStack`
3. Remove explanation card from scroll view

**Landscape (`landscapeQuizLayout`):**
1. Wrap the right card area in a `ZStack`
2. Add `TrainingExplanationView(..., showFullHand: true)` as top layer when `showFeedback`
3. Remove existing explanation card from the left panel `ScrollView`
4. Remove floating feedback pill from landscape card area
5. Next/Submit button remains **outside** the overlay `ZStack`, below the card area

---

## Visual Style Reference

| Element | Value |
|---------|-------|
| Correct banner bg | `#2ecc71` |
| Incorrect banner bg | `#e74c3c` |
| Panel background (portrait) | `#1a1a3e`, fully opaque |
| Panel background (landscape overlay) | `#0d0d1f` at 97% opacity. The mini card chips in the full-hand row are rendered as normal opaque content on top of this panel — they are not affected by the 3% transparency of the container. |
| Lesson label color | `#f1c40f` |
| Lesson text | white, 90% opacity |
| Optimal hold border (correct) | `#3498db` (blue) |
| Optimal hold border (incorrect) | `#2ecc71` (green) |
| You Held border | `#e74c3c` (red) |
| Dimmed card opacity | 40% |
| Internal padding | 12pt horizontal, 10pt vertical |
| Section gap | 8pt |
| Banner height | ~44pt |

All hex values are definitive; do not substitute SwiftUI named colors (`Color.green`, `Color.red`).

---

## Out of Scope

- Drill mode and JSON-based lessons (same `explanation` field exists; `TrainingExplanationView` can be reused later without changes)
- Transition animations (simple conditional swap on `showFeedback` is sufficient for v1)
- EV options table changes
