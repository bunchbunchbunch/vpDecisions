# UX Quiz Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix three UX quiz issues: card display, EV table columns/row-limit, and lazy UX loading.

**Architecture:** Task 1 fixes `uxEvOptionsTable` in `QuizPlayView.swift` (pure UI, no ViewModel changes). Task 2 refactors `QuizViewModel.loadQuiz()` to defer UX lookups — compute hand 0 before quiz starts, prefetch hands 1–N in background, with a safety net in `submit()` for edge cases. Tasks are independent and can be done in either order.

**Tech Stack:** Swift 6, SwiftUI, `@MainActor`, `async/await`, Swift Testing framework (`@Test`, `#expect`), XcodeBuildMCP for build/test.

---

## File Structure

| File | Change |
|------|--------|
| `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Quiz/QuizPlayView.swift` | Replace `uxEvOptionsTable` body: card display, columns, row limit |
| `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/QuizViewModel.swift` | Lazy UX loading: split `loadQuiz`, add helpers, safety net in `submit` |
| `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/UltimateXQuizTests.swift` | Tests for lazy loading and isComputingHandUX |

---

## Background: Key Types

**`UltimateXHoldOption`** (in `PlayModels.swift`):
```swift
struct UltimateXHoldOption: Identifiable {
    let id: Int           // bitmask
    let holdIndices: [Int]
    let baseEV: Double
    let eKAwarded: Double
    let adjustedEV: Double
}
```

**`UltimateXStrategyResult`** (in `UltimateXModels.swift`):
- `holdOptions(for hand: Hand) -> [UltimateXHoldOption]` — sorted by adjustedEV, highest first, uses original-position indices
- `rankForAdjustedOption(at index: Int) -> Int` — index is position in `holdOptions(for:)` array (0 = best), handles ties
- `isAdjustedHoldTiedForBest(_ canonicalIndices: [Int]) -> Bool`
- `adjustedBestHoldIndices: [Int]`, `adjustedBestEv: Double`

**Card display** (correct pattern used in `baseEvOptionsTable`):
```swift
Text(card.displayText)          // e.g. "A", "K", "10"
    .foregroundColor(card.suit.color)  // .red for hearts/diamonds, .primary for clubs/spades
```

**Wrong pattern** currently in `uxEvOptionsTable` (to be replaced):
```swift
Text("\(card.rank.display)\(card.suit.code)")
    .foregroundColor(card.suit == .hearts || card.suit == .diamonds ? .red : .primary)
```

---

## Task 1: Fix `uxEvOptionsTable` UI

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Quiz/QuizPlayView.swift` (lines ~673–737)

### Changes

Three bugs to fix in `uxEvOptionsTable`:
1. **Card display**: `card.rank.display + card.suit.code` → `card.displayText + card.suit.color`
2. **Columns**: add Base EV and E[K] columns (currently only shows Adj EV)
3. **Row limit**: 15 rows → top 5 + user's pick if outside top 5

The column layout should match `UltimateXStrategyPanel` in play mode:
- **Rank** (36pt wide, left-aligned)
- **Hold** (flex, left-aligned, bold if best)
- **Base** (50pt, right-aligned, `.caption` + `.secondary`)
- **E[K]** (44pt, right-aligned, `.caption` + gold `Color(hex: "FFD700")`)
- **Adj EV** (56pt, right-aligned, bold if best)

Row backgrounds:
- Best hold: `Color(hex: "667eea").opacity(0.2)` (matches `baseEvOptionsTable`)
- User's wrong pick: `Color(hex: "FFA726").opacity(0.3)` (matches `baseEvOptionsTable`)
- All others: `Color(.systemGray6)`

- [ ] **Step 1: Read current `uxEvOptionsTable`**

Open `QuizPlayView.swift` and find `uxEvOptionsTable` (around line 673). Confirm the three bugs are present:
- Line ~714: `Text("\(card.rank.display)\(card.suit.code)")` with manual `.red` color check
- Header line ~688: only shows "Adj EV"
- Line ~696: `.prefix(15)`

- [ ] **Step 2: Replace `uxEvOptionsTable` implementation**

Replace the entire `uxEvOptionsTable` function (from `private func uxEvOptionsTable` to its closing `}`) with:

```swift
private func uxEvOptionsTable(for quizHand: QuizHand, uxResult: UltimateXStrategyResult) -> some View {
    let holdOpts = uxResult.holdOptions(for: quizHand.hand)
    let userCanonicalHold = quizHand.hand.originalIndicesToCanonical(quizHand.userHoldIndices)
    let userBitmask = Hand.bitmaskFromHoldIndices(userCanonicalHold)

    // Top 5 + user's pick if outside top 5
    let top5 = Array(holdOpts.prefix(5))
    let userInTop5 = top5.contains { $0.id == userBitmask }
    let displayedOpts: [UltimateXHoldOption]
    if !userInTop5, let userOpt = holdOpts.first(where: { $0.id == userBitmask }) {
        displayedOpts = top5 + [userOpt]
    } else {
        displayedOpts = top5
    }

    return VStack(spacing: 8) {
        // Header
        HStack {
            Text("Rank")
                .font(.caption).fontWeight(.bold)
                .frame(width: 36, alignment: .leading)
            Text("Hold")
                .font(.caption).fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Base")
                .font(.caption).fontWeight(.bold)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)
            Text("E[K]")
                .font(.caption).fontWeight(.bold)
                .foregroundColor(Color(hex: "FFD700"))
                .frame(width: 44, alignment: .trailing)
            Text("Adj EV")
                .font(.caption).fontWeight(.bold)
                .frame(width: 56, alignment: .trailing)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Color(.systemGray5)).cornerRadius(8)

        // Rows
        VStack(spacing: 4) {
            ForEach(Array(displayedOpts.enumerated()), id: \.element.id) { idx, option in
                let actualIndex = holdOpts.firstIndex { $0.id == option.id } ?? idx
                let isBest = actualIndex == 0
                let isUserSelection = option.id == userBitmask
                let optionCards = option.holdIndices.map { quizHand.hand.cards[$0] }

                HStack(spacing: 8) {
                    // Rank (handles ties)
                    Text("\(uxResult.rankForAdjustedOption(at: actualIndex))")
                        .font(.subheadline)
                        .fontWeight(isBest ? .bold : .regular)
                        .frame(width: 36, alignment: .leading)

                    // Hold cards
                    if optionCards.isEmpty {
                        Text("Discard All")
                            .font(.subheadline)
                            .fontWeight(isBest ? .bold : .regular)
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

                    // Base EV
                    Text(String(format: "%.3f", option.baseEV))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .trailing)

                    // E[K] (expected multiplier awarded)
                    Text(String(format: "%.2f×", option.eKAwarded))
                        .font(.caption)
                        .foregroundColor(Color(hex: "FFD700"))
                        .frame(width: 44, alignment: .trailing)

                    // Adj EV
                    Text(String(format: "%.3f", option.adjustedEV))
                        .font(.subheadline)
                        .fontWeight(isBest ? .bold : .regular)
                        .frame(width: 56, alignment: .trailing)
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(
                    isUserSelection && !viewModel.isCorrect
                        ? Color(hex: "FFA726").opacity(0.3)
                        : (isBest ? Color(hex: "667eea").opacity(0.2) : Color(.systemGray6))
                )
                .cornerRadius(6)
            }
        }
    }
    .padding(.vertical, 4)
}
```

- [ ] **Step 3: Build**

```
mcp__xcodebuildmcp__build_sim_name_proj
  project_path: /Users/johnbunch/bbb/vpDecisions/ios-native/VideoPokerAcademy/VideoPokerAcademy.xcodeproj
  simulator_name: iPhone 16
```
Expected: BUILD SUCCEEDED. Fix any errors before proceeding.

- [ ] **Step 4: Run tests**

```
mcp__xcodebuildmcp__test_sim_name_proj
  project_path: /Users/johnbunch/bbb/vpDecisions/ios-native/VideoPokerAcademy/VideoPokerAcademy.xcodeproj
  simulator_name: iPhone 16
```
Expected: All tests pass.

- [ ] **Step 5: Visual verification**

Boot simulator, launch app, navigate to Quiz → select a game → toggle "Ult X" → play a hand and submit. Verify:
- Cards show with suit colors (red/black), not raw text like "TC"
- EV table shows 5 columns: Rank, Hold, Base, E[K], Adj EV
- At most 6 rows (5 + possible user's pick)

```
mcp__xcodebuildmcp__boot_simulator
mcp__xcodebuildmcp__install_app
mcp__xcodebuildmcp__launch_app
mcp__xcodebuildmcp__screenshot
```

---

## Task 2: Lazy UX Loading

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/QuizViewModel.swift`
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/UltimateXQuizTests.swift`

### Design

**Current (slow):** `loadQuiz()` computes all 25 UX lookups serially before showing the quiz.

**New (fast):**
1. Phase 1: deal and look up base strategy for all 25 hands (fast — local binary file). Assign random multipliers. Set `hands`.
2. Phase 2: compute UX for hand 0 only. Then set `isLoading = false` — quiz becomes visible.
3. Phase 3: background `Task` prefetches UX for hands 1–N while user plays.
4. Safety net: if user somehow submits before UX is ready, `submit()` computes it on-demand.

**New published state:** `@Published var isComputingHandUX: Bool = false`
- `true` only during the rare safety-net case (user submits before prefetch finishes)
- Used by view to disable the Submit button during that brief wait

**Prefetch task lifecycle:**
- Started after `isLoading = false` in `loadQuiz()`
- Cancelled in `reset()`
- Does not need to restart in `next()` — it keeps running until all hands are computed

- [ ] **Step 1: Write the failing tests**

In `UltimateXQuizTests.swift`, add:

```swift
@Test("loadQuiz sets isLoading to false without computing all UX upfront")
func testLoadQuizCompletesWithoutAllUX() async throws {
    // In UX mode, loadQuiz should finish with only hand 0 having uxResult set.
    // Hands 1+ are computed in background — so after loadQuiz returns,
    // at least hand 0 must have a uxResult, and isLoading must be false.
    let vm = QuizViewModel(
        paytableId: PayTable.jacksOrBetter96.id,
        quizSize: 3,
        isUltimateXMode: true,
        ultimateXPlayCount: .ten
    )
    await vm.loadQuiz()
    #expect(!vm.isLoading)
    #expect(!vm.hands.isEmpty)
    #expect(vm.hands[0].uxResult != nil)
}

@Test("isComputingHandUX starts as false")
func testIsComputingHandUXDefault() {
    let vm = QuizViewModel(
        paytableId: PayTable.jacksOrBetter96.id,
        isUltimateXMode: true,
        ultimateXPlayCount: .ten
    )
    #expect(!vm.isComputingHandUX)
}
```

- [ ] **Step 2: Run tests to verify they fail**

```
mcp__xcodebuildmcp__test_sim_name_proj
  project_path: /Users/johnbunch/bbb/vpDecisions/ios-native/VideoPokerAcademy/VideoPokerAcademy.xcodeproj
  simulator_name: iPhone 16
```
Expected: `testLoadQuizCompletesWithoutAllUX` fails (or doesn't exist yet); `testIsComputingHandUXDefault` fails because `isComputingHandUX` doesn't exist yet.

- [ ] **Step 3: Add `isComputingHandUX` and prefetch state to `QuizViewModel`**

Add these properties after the existing `@Published var showSwipeTip` line:

```swift
@Published var isComputingHandUX: Bool = false

private var uxPrefetchTask: Task<Void, Never>?
```

- [ ] **Step 4: Add `computeUX(for:)` helper**

Add this private method to `QuizViewModel` (in the `// MARK: - Helpers` section):

```swift
/// Computes and stores the UX strategy result for the hand at `index`.
/// No-op if uxResult is already set or index is out of bounds.
private func computeUX(for index: Int) async {
    guard index < hands.count, hands[index].uxResult == nil else { return }
    let quizHand = hands[index]
    if let uxResult = try? await UltimateXStrategyService.shared.lookup(
        hand: quizHand.hand,
        paytableId: paytableId,
        currentMultiplier: quizHand.currentMultiplier,
        playCount: ultimateXPlayCount
    ) {
        hands[index].uxResult = uxResult
    }
}
```

- [ ] **Step 5: Add `startUXPrefetch(from:)` helper**

Add this private method in the `// MARK: - Helpers` section:

```swift
/// Starts a background Task that computes UX results for hands starting at `startIndex`.
/// Cancels any existing prefetch task first.
private func startUXPrefetch(from startIndex: Int) {
    uxPrefetchTask?.cancel()
    uxPrefetchTask = Task { [weak self] in
        guard let self else { return }
        for i in startIndex..<self.hands.count {
            guard !Task.isCancelled else { return }
            await self.computeUX(for: i)
        }
    }
}
```

- [ ] **Step 6: Refactor `loadQuiz()` to use lazy loading**

Find the `loadQuiz()` function. Replace the UX-mode hand-finding inner block. The current code (lines ~121–136) does a UX lookup inside the hand-finding loop:

```swift
if isUltimateXMode {
    let family = ...
    let possibleMults = ...
    let multiplier = ...
    if let uxResult = try? await UltimateXStrategyService.shared.lookup(...) {
        var uxHand = QuizHand(hand: hand, strategyResult: result)
        uxHand.currentMultiplier = multiplier
        uxHand.uxResult = uxResult
        foundHands.append(uxHand)
        loadingProgress = foundHands.count
    }
    // If UX lookup failed, skip this hand
} else { ... }
```

Replace that entire `if isUltimateXMode { ... } else { ... }` block with:

```swift
if isUltimateXMode {
    // Assign multiplier now; UX result computed lazily
    let family = PayTable.allPayTables.first(where: { $0.id == paytableId })?.family ?? .jacksOrBetter
    let possibleMults = UltimateXMultiplierTable.possibleMultipliers(for: ultimateXPlayCount, family: family)
    var quizHand = QuizHand(hand: hand, strategyResult: result)
    quizHand.currentMultiplier = Double(possibleMults.randomElement() ?? 1)
    foundHands.append(quizHand)
    loadingProgress = foundHands.count
} else {
    let quizHand = QuizHand(hand: hand, strategyResult: result)
    foundHands.append(quizHand)
    loadingProgress = foundHands.count
}
```

Then, after `hands = foundHands` and before `isLoading = false`, add the UX phase-2 block:

```swift
hands = foundHands

// UX mode: compute hand 0 before showing quiz; prefetch rest in background
if isUltimateXMode && !hands.isEmpty {
    await computeUX(for: 0)
}

isLoading = false
handStartTime = Date()
// ... rest of existing post-load code (audioService.play, checkDealtWinner) ...

// Start background prefetch for hands 1+
if isUltimateXMode {
    startUXPrefetch(from: 1)
}
```

The final lines of `loadQuiz()` after your edit should look like:

```swift
hands = foundHands

// UX mode: compute hand 0 before showing quiz
if isUltimateXMode && !hands.isEmpty {
    await computeUX(for: 0)
}

isLoading = false
handStartTime = Date()

// Play card flip sound for first hand
audioService.play(.cardFlip)

// Check if first hand is a dealt winner
await checkDealtWinner()

// Start background prefetch for hands 1+ (after checkDealtWinner)
if isUltimateXMode {
    startUXPrefetch(from: 1)
}
```

Note: `isLoading = false` is set AFTER hand 0 UX is computed — the loading spinner stays visible until the first hand is fully ready. This is intentional: the quiz should not appear until hand 0 is playable. The `startUXPrefetch` call goes AFTER `checkDealtWinner()` to avoid spawning two concurrent async tasks simultaneously.

- [ ] **Step 7: Add UX safety net to `submit()`**

The base `submit()` uses `currentHand.uxResult` directly. Add a guard at the top of `submit()`, right after the existing `guard let currentHand = currentHand, !showFeedback else { return }` line:

```swift
// Safety net: if UX result not yet ready (rare race condition), compute it first
if isUltimateXMode, currentHand.uxResult == nil {
    Task {
        isComputingHandUX = true
        await computeUX(for: currentIndex)
        isComputingHandUX = false
        submit()  // re-enter now that uxResult is ready
    }
    return
}
```

This handles the edge case where the user submits before the background prefetch reaches the current hand.

- [ ] **Step 8: Cancel prefetch in `reset()`**

In the existing `reset()` function, add after the last line:

```swift
uxPrefetchTask?.cancel()
uxPrefetchTask = nil
isComputingHandUX = false
```

- [ ] **Step 9: Disable Submit button during `isComputingHandUX`**

In `QuizPlayView.swift`, find the `actionButton` computed property. Add `.disabled(viewModel.isComputingHandUX)` to the button:

```swift
private var actionButton: some View {
    Button {
        if viewModel.showFeedback {
            viewModel.next()
        } else {
            viewModel.submit()
        }
    } label: {
        Text(buttonText)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
    }
    .buttonStyle(.borderedProminent)
    .tint(viewModel.showFeedback ? Color(hex: "3498db") : Color(hex: "667eea"))
    .disabled(viewModel.isComputingHandUX)
}
```

- [ ] **Step 10: Build**

```
mcp__xcodebuildmcp__build_sim_name_proj
  project_path: /Users/johnbunch/bbb/vpDecisions/ios-native/VideoPokerAcademy/VideoPokerAcademy.xcodeproj
  simulator_name: iPhone 16
```
Expected: BUILD SUCCEEDED. Fix any errors — common issues:
- `hands[index].uxResult` mutation: since `QuizHand` is a struct in an array, `hands[index].uxResult = uxResult` requires `self` to be mutable (it is — `QuizViewModel` is `@MainActor class`)
- `Task.isCancelled` in a `@MainActor` context: use `Task.checkCancellation()` or check `Task.isCancelled` with `guard` — the code above uses `guard !Task.isCancelled` which is valid

- [ ] **Step 11: Run tests**

```
mcp__xcodebuildmcp__test_sim_name_proj
  project_path: /Users/johnbunch/bbb/vpDecisions/ios-native/VideoPokerAcademy/VideoPokerAcademy.xcodeproj
  simulator_name: iPhone 16
```
Expected: All tests pass including the two new tests in `UltimateXQuizTests`.

- [ ] **Step 12: Visual verification of loading speed**

Boot simulator, navigate to Quiz → select a game → toggle "Ult X" → start quiz. The quiz should load significantly faster than before:
- Old: waited for 25 UX lookups (~25 seconds)
- New: waited for base strategy (fast) + 1 UX lookup (~1 second)

```
mcp__xcodebuildmcp__boot_simulator
mcp__xcodebuildmcp__install_app
mcp__xcodebuildmcp__launch_app
mcp__xcodebuildmcp__screenshot
```
