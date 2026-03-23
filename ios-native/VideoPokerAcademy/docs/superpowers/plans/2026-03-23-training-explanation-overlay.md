# Training Mode Explanation Overlay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** After the user submits their hold selection in a training lesson, replace the pay table area (portrait) or overlay the card area (landscape) with a panel showing correct/incorrect status, the lesson explanation text, and the optimal hold — including a "You Held / Optimal Hold" comparison when the answer is wrong.

**Architecture:** A new standalone `TrainingExplanationView` component handles all rendering. `TrainingLessonQuizView` is modified to swap in this component in portrait (replacing `CompactPayTableView`) and layer it as a `ZStack` overlay in landscape. Existing feedback pill and explanation card are removed; the EV options table is preserved unchanged.

**Tech Stack:** Swift 6, SwiftUI, `@Observable`/`ObservableObject` (existing pattern), existing `Card.displayText` / `card.suit.color` for card rendering

---

## File Map

| Action | File |
|--------|------|
| **Create** | `VideoPokerAcademy/Views/Training/TrainingExplanationView.swift` |
| **Modify** | `VideoPokerAcademy/Views/Training/TrainingLessonQuizView.swift` |
| **Test** | No new unit tests (pure SwiftUI layout; verified via screenshot) |

---

## Task 1: Create `TrainingExplanationView` — Banner + Lesson Section

**Files:**
- Create: `VideoPokerAcademy/Views/Training/TrainingExplanationView.swift`

- [ ] **Step 1: Create the file with the component signature and banner**

```swift
// VideoPokerAcademy/Views/Training/TrainingExplanationView.swift
import SwiftUI

struct TrainingExplanationView: View {
    let isCorrect: Bool
    let evLost: Double            // 0 when correct or no EV data
    let explanation: String
    let optimalHoldCards: [String]  // card strings e.g. ["6h", "6d"]; empty = discard all
    let userHeldCards: [String]     // card strings e.g. ["As", "Kc"]; empty = user drew all
    let allCards: [String]          // full 5-card hand; ignored when showFullHand == false
    let showFullHand: Bool          // true in landscape, false in portrait

    var body: some View {
        VStack(spacing: 0) {
            bannerView
            VStack(alignment: .leading, spacing: 8) {
                lessonSection
                if showFullHand {
                    fullHandRow
                        .frame(maxWidth: .infinity)
                }
                holdChipsSection
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(showFullHand
                      ? Color(hex: "0d0d1f").opacity(0.97)
                      : Color(hex: "1a1a3e"))
        )
    }

    // MARK: - Banner

    private var bannerView: some View {
        HStack {
            Spacer()
            if isCorrect {
                Text("✓ CORRECT")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(1)
            } else {
                if evLost > 0 {
                    Text("✗ INCORRECT  ·  EV Lost: \(String(format: "%.3f", evLost))")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(0.5)
                } else {
                    Text("✗ INCORRECT")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(1)
                }
            }
            Spacer()
        }
        .frame(minHeight: 44)
        .background(isCorrect ? Color(hex: "2ecc71") : Color(hex: "e74c3c"))
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: 10,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 10
        ))
    }

    // MARK: - Lesson Section

    private var lessonSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("LESSON", systemImage: "lightbulb.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(hex: "f1c40f"))
                .tracking(1)

            Text(explanation)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
```

- [ ] **Step 2: Build to check for compile errors**

Run: `mcp__xcodebuildmcp__build_sim_name_proj` (project: VideoPokerAcademy, sim: iPhone 16)
Expected: Build succeeds. Fix any errors before continuing.

---

## Task 2: Add Full-Hand Row and Hold Chips Section

> **Before writing any code in this task:** Read `VideoPokerAcademy/Models/Card.swift` to check exact `Rank` and `Suit` property names (e.g. `display`, `code`, `symbol`, `color`) and whether a `Card.from(string:)` or `card.string` property already exists. The plan's fallbacks are based on the most likely naming — verify before writing.

**Files:**
- Modify: `VideoPokerAcademy/Views/Training/TrainingExplanationView.swift`

- [ ] **Step 1: Add the mini card chip helper and full-hand row**

Add the following inside `TrainingExplanationView`, after `lessonSection`:

```swift
    // MARK: - Full Hand Row (landscape only)

    private var fullHandRow: some View {
        HStack(spacing: 8) {
            ForEach(Array(allCards.enumerated()), id: \.offset) { index, cardString in
                let isHeld = userHeldCards.contains(cardString)
                let isOptimal = optimalHoldCards.contains(cardString)
                miniChip(cardString: cardString, borderColor: fullHandBorderColor(isHeld: isHeld, isOptimal: isOptimal))
                    .opacity(fullHandOpacity(isHeld: isHeld, isOptimal: isOptimal))
            }
        }
        .padding(.top, 0)
    }

    private func fullHandBorderColor(isHeld: Bool, isOptimal: Bool) -> Color {
        if isCorrect {
            return isHeld ? Color(hex: "3498db") : .clear
        }
        // Incorrect
        if isHeld && isOptimal  { return Color(hex: "2ecc71") }
        if isHeld && !isOptimal { return Color(hex: "e74c3c") }
        if !isHeld && isOptimal { return Color(hex: "2ecc71") }
        return .clear  // not held, not optimal
    }

    private func fullHandOpacity(isHeld: Bool, isOptimal: Bool) -> Double {
        if isCorrect { return isHeld ? 1.0 : 0.4 }
        // Incorrect: dimmed if not held and not optimal
        if !isHeld && !isOptimal { return 0.4 }
        if !isHeld && isOptimal  { return 0.4 }  // green border but dimmed bg
        return 1.0
    }

    // MARK: - Hold Chips Section

    @ViewBuilder
    private var holdChipsSection: some View {
        if isCorrect {
            VStack(alignment: .leading, spacing: 4) {
                Text("OPTIMAL HOLD")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1)
                chipRow(cards: optimalHoldCards, borderColor: Color(hex: "3498db"))
            }
        } else {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YOU HELD")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(hex: "e74c3c"))
                        .tracking(1)
                    chipRow(cards: userHeldCards, borderColor: Color(hex: "e74c3c"), emptyLabel: "DREW ALL")
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("OPTIMAL HOLD")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(hex: "2ecc71"))
                        .tracking(1)
                    chipRow(cards: optimalHoldCards, borderColor: Color(hex: "2ecc71"), emptyLabel: "DRAW ALL")
                }
            }
        }
    }

    private func chipRow(cards: [String], borderColor: Color, emptyLabel: String = "DRAW ALL") -> some View {
        Group {
            if cards.isEmpty {
                Text(emptyLabel)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            } else {
                HStack(spacing: 4) {
                    ForEach(Array(cards.enumerated()), id: \.offset) { _, cardString in
                        miniChip(cardString: cardString, borderColor: borderColor)
                    }
                }
            }
        }
    }

    // MARK: - Mini Card Chip

    private func miniChip(cardString: String, borderColor: Color) -> some View {
        // Parse the card string using the same Card model logic
        // cardString format: "Ah", "Kc", "6h", "Td", etc.
        let card = Card.from(string: cardString)
        return ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: "2c3e50"))
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(borderColor, lineWidth: 2)
            if let card = card {
                Text(card.displayText)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(card.suit.color)
            } else {
                Text(cardString)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 32, height: 40)
    }
```

- [ ] **Step 2: Check if `Card.from(string:)` exists in the codebase**

Search for how the app parses card strings (e.g. "Ah") into `Card` objects. Look in `Card.swift`, `Hand.swift`, or any training model files:

```
Grep for: "from(string" or "init.*string" in Models/
```

If a `Card.from(string:)` or equivalent doesn't exist, add a static helper to `Card.swift`:

```swift
// In Card.swift — add this static method
static func from(string: String) -> Card? {
    guard string.count >= 2 else { return nil }
    let rankStr = String(string.dropLast())
    let suitStr = String(string.last!)
    guard let rank = Rank.allCases.first(where: { $0.display.lowercased() == rankStr.lowercased() || $0.shortCode?.lowercased() == rankStr.lowercased() }),
          let suit = Suit.allCases.first(where: { $0.code.lowercased() == suitStr.lowercased() }) else { return nil }
    return Card(rank: rank, suit: suit)
}
```

Adapt as needed to match the existing `Rank` and `Suit` enum definitions in `Card.swift`.

- [ ] **Step 3: Build and fix any errors**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: Build succeeds. Common issues: `UnevenRoundedRectangle` requires iOS 16+, `Card.from` parsing.

---

## Task 3: Wire Up Portrait Layout in `TrainingLessonQuizView`

**Files:**
- Modify: `VideoPokerAcademy/Views/Training/TrainingLessonQuizView.swift`

The existing `portraitQuizLayout` (lines ~98–132) needs three changes:
1. Swap `CompactPayTableView` → `TrainingExplanationView` when `showFeedback`
2. Remove `feedbackOverlay` from the cards `ZStack` (lines ~401–407)
3. Remove `explanationCard` from the scroll view (lines ~121–124)

- [ ] **Step 1: Replace the pay table block in `portraitQuizLayout`**

Find this block (lines ~105–109):
```swift
if let paytable = PayTable.allPayTables.first(where: { $0.id == viewModel.paytableId }) {
    CompactPayTableView(paytable: paytable)
        .padding(.horizontal)
        .padding(.bottom, 8)
}
```

Replace with:
```swift
if viewModel.showFeedback, let currentHand = viewModel.currentHand {
    TrainingExplanationView(
        isCorrect: viewModel.isCorrect,
        evLost: viewModel.evLost,
        explanation: currentHand.practiceHand.explanation,
        optimalHoldCards: currentHand.practiceHand.holdCards,
        userHeldCards: viewModel.selectedIndices.sorted().map { currentHand.hand.cards[$0].string },
        allCards: currentHand.hand.cards.map { $0.string },
        showFullHand: false
    )
    .padding(.horizontal)
    .padding(.bottom, 8)
} else if let paytable = PayTable.allPayTables.first(where: { $0.id == viewModel.paytableId }) {
    CompactPayTableView(paytable: paytable)
        .padding(.horizontal)
        .padding(.bottom, 8)
}
```

> **Note:** Use the correct property to get a card's string representation. Search for how `holdCards` is stored in `TrainingPracticeHand` — it may already be `[String]` (e.g. `"6h"`), or it may be `[Card]`. If `holdCards` is `[Card]`, map it via `.map { "\($0.rank.display)\($0.suit.code)" }`. Use the same format for `userHeldCards` and `allCards`. Verify by reading `TrainingLesson.swift`.

- [ ] **Step 2: Remove `feedbackOverlay` from the portrait cards `ZStack`**

In `cardsAreaView`, find (lines ~401–407):
```swift
// Feedback overlay
VStack {
    Spacer()
    if viewModel.showFeedback, let currentHand = viewModel.currentHand {
        feedbackOverlay(for: currentHand)
            .padding(.bottom, 8)
    }
}
```
Delete this entire block.

- [ ] **Step 3: Remove `explanationCard` from the portrait scroll view**

In `portraitQuizLayout`, find (lines ~121–124):
```swift
explanationCard(for: currentHand)
    .padding(.horizontal)
    .padding(.top, 8)
```
Delete these two lines (the `explanationCard` call and its padding modifiers). Leave the `evOptionsTable` block above it intact.

- [ ] **Step 4: Build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: Succeeds. If `card.string` doesn't exist, find the correct property/method from `Card.swift`.

- [ ] **Step 5: Screenshot portrait — correct answer**

```
mcp__xcodebuildmcp__boot_simulator
mcp__xcodebuildmcp__install_app
mcp__xcodebuildmcp__launch_app
mcp__xcodebuildmcp__screenshot
```

Navigate to a training lesson, answer correctly, tap Submit. Verify:
- Pay table replaced by explanation panel with green banner
- "OPTIMAL HOLD" chips visible
- Cards still visible below
- EV table still visible below cards (if strategy loaded)

- [ ] **Step 6: Screenshot portrait — incorrect answer**

Answer a hand incorrectly, tap Submit. Verify:
- Red banner with EV Lost
- "YOU HELD / OPTIMAL HOLD" two-column comparison
- Cards still visible below

---

## Task 4: Wire Up Landscape Layout in `TrainingLessonQuizView`

**Files:**
- Modify: `VideoPokerAcademy/Views/Training/TrainingLessonQuizView.swift`

The existing `landscapeQuizLayout` right side (lines ~171–181) wraps the cards in a `VStack`. We need to:
1. Wrap `landscapeCardsArea` in a `ZStack` with the overlay
2. Remove `feedbackOverlay` from inside `landscapeCardsArea`
3. Remove `explanationCard` from the left panel's `ScrollView`

- [ ] **Step 1: Wrap the landscape card area in a `ZStack` with the overlay**

In `landscapeQuizLayout`, find the right-side VStack (lines ~171–181):
```swift
// Right side: Cards and action button
VStack(spacing: 4) {
    Spacer(minLength: 0)

    landscapeCardsArea(width: rightWidth - 8, height: geometry.size.height * 0.60)

    actionButton
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
}
```

Replace with:
```swift
// Right side: Cards and action button
VStack(spacing: 4) {
    Spacer(minLength: 0)

    ZStack {
        landscapeCardsArea(width: rightWidth - 8, height: geometry.size.height * 0.60)

        if viewModel.showFeedback, let currentHand = viewModel.currentHand {
            TrainingExplanationView(
                isCorrect: viewModel.isCorrect,
                evLost: viewModel.evLost,
                explanation: currentHand.practiceHand.explanation,
                optimalHoldCards: currentHand.practiceHand.holdCards,
                userHeldCards: viewModel.selectedIndices.sorted().map { currentHand.hand.cards[$0].string },
                allCards: currentHand.hand.cards.map { $0.string },
                showFullHand: true
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    .frame(width: rightWidth - 8, height: geometry.size.height * 0.60)

    actionButton
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
}
```

- [ ] **Step 2: Remove `feedbackOverlay` from `landscapeCardsArea`**

In `landscapeCardsArea` (lines ~314–321), find:
```swift
if viewModel.showFeedback, let currentHand = viewModel.currentHand {
    feedbackOverlay(for: currentHand)
        .padding(.bottom, 4)
} else if viewModel.showSwipeTip {
```

Remove only the feedback branch, keeping the swipe tip:
```swift
if viewModel.showSwipeTip {
```
(i.e. delete the `if viewModel.showFeedback` branch and its closing `} else`)

- [ ] **Step 3: Remove `explanationCard` from the left panel `ScrollView`**

In `landscapeQuizLayout`, find (lines ~158–159):
```swift
explanationCard(for: currentHand)
```
Delete that line and any associated padding modifiers. Leave the `evOptionsTable` call above it.

- [ ] **Step 4: Build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: Succeeds.

- [ ] **Step 5: Screenshot landscape — correct answer**

Rotate simulator to landscape. Answer a hand correctly, tap Submit. Verify:
- Overlay covers right card area
- Green banner at top of overlay
- Full 5-card hand row visible (held cards blue-bordered, others dimmed)
- "OPTIMAL HOLD" chips below
- Left panel and Next button unaffected

- [ ] **Step 6: Screenshot landscape — incorrect answer**

Answer incorrectly in landscape. Verify:
- Red banner with EV Lost
- Full hand row with correct highlighting (wrong holds = red, missed optimal = green/dimmed, correct discards = dimmed)
- "YOU HELD / OPTIMAL HOLD" chip comparison below hand row

---

## Task 5: Cleanup — Remove Dead Code

**Files:**
- Modify: `VideoPokerAcademy/Views/Training/TrainingLessonQuizView.swift`

- [ ] **Step 1: Delete the `feedbackOverlay` method**

Find and delete the entire `feedbackOverlay(for:)` method (lines ~456–474):
```swift
private func feedbackOverlay(for quizHand: TrainingQuizHand) -> some View {
    ...
}
```

- [ ] **Step 2: Delete the `explanationCard` method**

Find and delete the entire `explanationCard(for:)` method (lines ~583–600):
```swift
private func explanationCard(for quizHand: TrainingQuizHand) -> some View {
    ...
}
```

- [ ] **Step 3: Build to confirm no remaining references**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: Succeeds with no unused-function warnings. If any references remain, remove them.

- [ ] **Step 4: Full screenshot regression — portrait and landscape, both correct and incorrect**

Take 4 screenshots verifying no visual regressions:
1. Portrait, correct answer
2. Portrait, incorrect answer
3. Landscape, correct answer
4. Landscape, incorrect answer

---

## Task 6: Run Tests

- [ ] **Step 1: Run the full test suite**

Run: `mcp__xcodebuildmcp__test_sim_name_proj`
Expected: All tests pass. Fix any failures before considering this done.

---

## Notes for Implementer

**Card string format:** `TrainingPracticeHand.holdCards` is `[String]` with values like `"6h"`, `"Kd"`. `Card.displayText` returns `"6♥"` format (rank full name + suit symbol). Verify that `Card.from(string:)` (or whatever parsing method exists) correctly handles these strings.

**`card.string` property:** The plan uses `.map { $0.string }` to convert `Card` objects back to strings for the overlay. Check if this property exists on `Card`; if not, use `.map { "\($0.rank.display)\($0.suit.code)" }` instead.

**`UnevenRoundedRectangle`:** Available from iOS 16. The project targets iOS 17+, so this is fine.

**Spec reference:** `docs/superpowers/specs/2026-03-23-training-explanation-overlay-design.md`
