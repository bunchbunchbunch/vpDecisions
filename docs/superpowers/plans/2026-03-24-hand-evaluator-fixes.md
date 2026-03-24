# Hand Evaluator Bug Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix six bugs in hand evaluation logic that cause $0 payouts for 14+ game families and broken wild card detection.

**Architecture:** Add two `static nonisolated` helper functions to `HandEvaluator` that resolve quad hand names and high pair info from paytable row names (data-driven, not string-matching on paytable IDs). Update `PlayViewModel`, `SimulationViewModel`, and `HandEvaluator` evaluation paths to use these helpers and fix routing/naming bugs.

**Tech Stack:** Swift 6, SwiftUI, Swift Testing framework (`@Test`, `#expect`)

---

## Files Modified

| File | Changes |
|------|---------|
| `Services/HandEvaluator.swift` | Add `resolveQuadHandName` + `resolveHighPairInfo` static helpers; fix routing; fix name literals; update `evaluateJacksOrBetter`/`evaluateTensOrBetter` |
| `ViewModels/PlayViewModel.swift` | Fix routing, quad names, high pair, wild flush detection; remove `getFourOfAKindName` |
| `ViewModels/SimulationViewModel.swift` | Same fixes as PlayViewModel |
| `VideoPokerAcademyTests/HandEvaluatorTests.swift` | NEW — unit tests for helpers and routing |

---

## Bug Summary

| # | Bug | Impact |
|---|-----|--------|
| 1 | `getFourOfAKindName` uses paytable ID string matching → wrong names for 14 game families | $0 payout for quads |
| 2 | `evaluateFinalHand` routes `loose-deuces-*` to standard evaluator | All payouts wrong |
| 3 | `evaluateDeucesWildHand` uses `isFlush` not wild-aware version | Wild flushes pay as Three of a Kind |
| 4 | High pair detection hardcoded to "Jacks or Better" | Kings or Better / Pair of Aces pay $0 |
| 5 | `HandEvaluator.evaluateDealtHand` only routes 2 of 15 deuces wild variants | Banner/training broken |
| 6 | `HandEvaluator.evaluateDeucesWild` uses wrong name literals | Banner shows wrong hand name |

---

## Task 1: Add Shared Helpers to HandEvaluator + Tests

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Services/HandEvaluator.swift`
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/HandEvaluatorTests.swift`

- [ ] **Step 1: Add `resolveQuadHandName` static helper to HandEvaluator.swift**

Insert after line 11 (after `private init() {}`):

```swift
    // MARK: - Shared Resolution Helpers

    /// Data-driven quad hand name resolution. Checks paytable row names to find the correct
    /// hand name for a given quad rank and kicker, without relying on paytable ID strings.
    static nonisolated func resolveQuadHandName(
        quadRank: Int,
        kickerRank: Int,
        paytableRowNames: Set<String>
    ) -> String {
        // Aces
        if quadRank == 14 {
            if kickerRank >= 2 && kickerRank <= 4 && paytableRowNames.contains("Four Aces + 2-4") {
                return "Four Aces + 2-4"
            }
            if kickerRank >= 11 && paytableRowNames.contains("Four Aces + Face") {
                return "Four Aces + Face"
            }
            if paytableRowNames.contains("Four Aces") { return "Four Aces" }
            if paytableRowNames.contains("Four Aces/Eights") { return "Four Aces/Eights" }
        }

        // Face cards (J/Q/K = ranks 11-13)
        if quadRank >= 11 && quadRank <= 13 {
            if kickerRank >= 11 && paytableRowNames.contains("Four Face + A-K") {
                return "Four Face + A-K"
            }
            if kickerRank >= 11 && paytableRowNames.contains("Four K/Q/J + Face") {
                return "Four K/Q/J + Face"
            }
            if (kickerRank == 14 || (kickerRank >= 2 && kickerRank <= 4)) && paytableRowNames.contains("Four J-K + A-4") {
                return "Four J-K + A-4"
            }
            if paytableRowNames.contains("Four J-K") { return "Four J-K" }
            if paytableRowNames.contains("Four K/Q/J") { return "Four K/Q/J" }
            if paytableRowNames.contains("Four Face") { return "Four Face" }
            if paytableRowNames.contains("Four 5-K") { return "Four 5-K" }
            if paytableRowNames.contains("Four 2-6/9-K") { return "Four 2-6/9-K" }
        }

        // Eights (special case for Aces & Eights)
        if quadRank == 8 && paytableRowNames.contains("Four Aces/Eights") {
            return "Four Aces/Eights"
        }

        // Sevens (special case for Aces & Eights)
        if quadRank == 7 && paytableRowNames.contains("Four Sevens") {
            return "Four Sevens"
        }

        // Low ranks (2-4)
        if quadRank >= 2 && quadRank <= 4 {
            if kickerRank >= 2 && kickerRank <= 4 && paytableRowNames.contains("Four 2-4 + 2-4") {
                return "Four 2-4 + 2-4"
            }
            if (kickerRank == 14 || (kickerRank >= 2 && kickerRank <= 4)) && paytableRowNames.contains("Four 2-4 + A-4") {
                return "Four 2-4 + A-4"
            }
            if paytableRowNames.contains("Four 2-4") { return "Four 2-4" }
            if paytableRowNames.contains("Four 2-10") { return "Four 2-10" }
            if paytableRowNames.contains("Four 2-6/9-K") { return "Four 2-6/9-K" }
        }

        // Remaining ranks (5-10 not yet matched, or J-K without specific row)
        if paytableRowNames.contains("Four 5-K") { return "Four 5-K" }
        if quadRank <= 10 && paytableRowNames.contains("Four 2-10") { return "Four 2-10" }
        if ((quadRank >= 2 && quadRank <= 6) || (quadRank >= 9 && quadRank <= 13)) &&
            paytableRowNames.contains("Four 2-6/9-K") {
            return "Four 2-6/9-K"
        }

        return "Four of a Kind"
    }

    /// Returns the high pair row name and minimum qualifying rank for the given paytable,
    /// or nil if no pair qualifies (e.g. pure deuces wild variants).
    static nonisolated func resolveHighPairInfo(
        paytableRowNames: Set<String>
    ) -> (name: String, minRank: Int)? {
        if paytableRowNames.contains("Pair of Aces") { return ("Pair of Aces", 14) }
        if paytableRowNames.contains("Kings or Better") { return ("Kings or Better", 13) }
        if paytableRowNames.contains("Jacks or Better") { return ("Jacks or Better", 11) }
        if paytableRowNames.contains("Tens or Better") { return ("Tens or Better", 10) }
        return nil
    }
```

- [ ] **Step 2: Write failing tests in HandEvaluatorTests.swift**

```swift
import Testing
@testable import VideoPokerAcademy

// MARK: - resolveQuadHandName Tests

@Suite("HandEvaluator.resolveQuadHandName")
struct ResolveQuadHandNameTests {

    // MARK: Standard single-tier games
    @Test func jacobsOrBetter_returnsGenericFourOfAKind() {
        let rows: Set<String> = ["Royal Flush", "Straight Flush", "Four of a Kind", "Full House",
                                  "Flush", "Straight", "Three of a Kind", "Two Pair", "Jacks or Better"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 7, paytableRowNames: rows) == "Four of a Kind")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 8, kickerRank: 5, paytableRowNames: rows) == "Four of a Kind")
    }

    // MARK: Bonus Poker family (Four Aces / Four 2-4 / Four 5-K)
    @Test func bonusPoker_acesReturnFourAces() {
        let rows: Set<String> = ["Four Aces", "Four 2-4", "Four 5-K", "Full House", "Flush",
                                  "Straight", "Three of a Kind", "Two Pair", "Jacks or Better"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 7, paytableRowNames: rows) == "Four Aces")
    }

    @Test func bonusPoker_lowRanksReturnFour2_4() {
        let rows: Set<String> = ["Four Aces", "Four 2-4", "Four 5-K", "Full House", "Flush",
                                  "Straight", "Three of a Kind", "Two Pair", "Jacks or Better"]
        for rank in [2, 3, 4] {
            #expect(HandEvaluator.resolveQuadHandName(quadRank: rank, kickerRank: 9, paytableRowNames: rows) == "Four 2-4")
        }
    }

    @Test func bonusPoker_midHighRanksReturnFour5K() {
        let rows: Set<String> = ["Four Aces", "Four 2-4", "Four 5-K", "Full House", "Flush",
                                  "Straight", "Three of a Kind", "Two Pair", "Jacks or Better"]
        for rank in [5, 7, 8, 10, 11, 13] {
            #expect(HandEvaluator.resolveQuadHandName(quadRank: rank, kickerRank: 9, paytableRowNames: rows) == "Four 5-K")
        }
    }

    // MARK: DDB — kicker-sensitive
    @Test func ddb_acesWithLowKickerReturnFourAcesPlus2_4() {
        let rows: Set<String> = ["Four Aces + 2-4", "Four 2-4 + A-4", "Four Aces", "Four 2-4", "Four 5-K",
                                  "Full House", "Flush", "Straight", "Three of a Kind", "Two Pair", "Jacks or Better"]
        for kicker in [2, 3, 4] {
            #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: kicker, paytableRowNames: rows) == "Four Aces + 2-4")
        }
    }

    @Test func ddb_acesWithHighKickerReturnFourAces() {
        let rows: Set<String> = ["Four Aces + 2-4", "Four 2-4 + A-4", "Four Aces", "Four 2-4", "Four 5-K",
                                  "Full House", "Flush", "Straight", "Three of a Kind", "Two Pair", "Jacks or Better"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 9, paytableRowNames: rows) == "Four Aces")
    }

    @Test func ddb_lowRankWithAceOrLowKickerReturnFour2_4PlusA_4() {
        let rows: Set<String> = ["Four Aces + 2-4", "Four 2-4 + A-4", "Four Aces", "Four 2-4", "Four 5-K",
                                  "Full House", "Flush", "Straight", "Three of a Kind", "Two Pair", "Jacks or Better"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 3, kickerRank: 14, paytableRowNames: rows) == "Four 2-4 + A-4")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 3, kickerRank: 4, paytableRowNames: rows) == "Four 2-4 + A-4")
    }

    // MARK: Super Aces / White Hot Aces (no kicker rows)
    @Test func superAces_eightQuadsReturnFour5K() {
        let rows: Set<String> = ["Four Aces", "Four 2-4", "Four 5-K", "Full House", "Flush",
                                  "Straight", "Three of a Kind", "Two Pair", "Jacks or Better"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 8, kickerRank: 5, paytableRowNames: rows) == "Four 5-K")
    }

    // MARK: Aces & Eights
    @Test func acesAndEights_acesReturnFourAcesEights() {
        let rows: Set<String> = ["Four Aces/Eights", "Four Sevens", "Four 2-6/9-K", "Full House", "Flush",
                                  "Straight", "Three of a Kind", "Two Pair", "Jacks or Better"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 5, paytableRowNames: rows) == "Four Aces/Eights")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 8, kickerRank: 5, paytableRowNames: rows) == "Four Aces/Eights")
    }

    @Test func acesAndEights_sevensReturnFourSevens() {
        let rows: Set<String> = ["Four Aces/Eights", "Four Sevens", "Four 2-6/9-K"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 7, kickerRank: 5, paytableRowNames: rows) == "Four Sevens")
    }

    @Test func acesAndEights_otherRanksReturnFour2_6_9_K() {
        let rows: Set<String> = ["Four Aces/Eights", "Four Sevens", "Four 2-6/9-K"]
        for rank in [2, 3, 5, 6, 9, 10, 11, 13] {
            #expect(HandEvaluator.resolveQuadHandName(quadRank: rank, kickerRank: 5, paytableRowNames: rows) == "Four 2-6/9-K")
        }
    }

    // MARK: Aces & Faces / Bonus Aces & Faces
    @Test func acesAndFaces_acesReturnFourAces() {
        let rows: Set<String> = ["Four Aces", "Four J-K", "Four 2-10"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 7, paytableRowNames: rows) == "Four Aces")
    }

    @Test func acesAndFaces_faceCardsReturnFourJK() {
        let rows: Set<String> = ["Four Aces", "Four J-K", "Four 2-10"]
        for rank in [11, 12, 13] {
            #expect(HandEvaluator.resolveQuadHandName(quadRank: rank, kickerRank: 7, paytableRowNames: rows) == "Four J-K")
        }
    }

    @Test func acesAndFaces_lowRanksReturnFour2_10() {
        let rows: Set<String> = ["Four Aces", "Four J-K", "Four 2-10"]
        for rank in [2, 5, 8, 10] {
            #expect(HandEvaluator.resolveQuadHandName(quadRank: rank, kickerRank: 7, paytableRowNames: rows) == "Four 2-10")
        }
    }

    // MARK: Super Double Bonus
    @Test func superDoubleBonus_acesWithFaceKicker() {
        let rows: Set<String> = ["Four Aces + Face", "Four Face + A-K", "Four Aces", "Four Face", "Four 2-10"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 12, paytableRowNames: rows) == "Four Aces + Face")
    }

    @Test func superDoubleBonus_acesWithLowKicker() {
        let rows: Set<String> = ["Four Aces + Face", "Four Face + A-K", "Four Aces", "Four Face", "Four 2-10"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 7, paytableRowNames: rows) == "Four Aces")
    }

    @Test func superDoubleBonus_faceWithHighKicker() {
        let rows: Set<String> = ["Four Aces + Face", "Four Face + A-K", "Four Aces", "Four Face", "Four 2-10"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 11, kickerRank: 14, paytableRowNames: rows) == "Four Face + A-K")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 11, kickerRank: 13, paytableRowNames: rows) == "Four Face + A-K")
    }

    @Test func superDoubleBonus_faceWithLowKicker() {
        let rows: Set<String> = ["Four Aces + Face", "Four Face + A-K", "Four Aces", "Four Face", "Four 2-10"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 11, kickerRank: 7, paytableRowNames: rows) == "Four Face")
    }

    // MARK: Double Jackpot
    @Test func doubleJackpot_acesWithFaceKicker() {
        let rows: Set<String> = ["Four Aces + Face", "Four Aces", "Four K/Q/J + Face", "Four K/Q/J", "Four 2-10"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 13, paytableRowNames: rows) == "Four Aces + Face")
    }

    @Test func doubleJackpot_faceWithFaceKicker() {
        let rows: Set<String> = ["Four Aces + Face", "Four Aces", "Four K/Q/J + Face", "Four K/Q/J", "Four 2-10"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 13, kickerRank: 14, paytableRowNames: rows) == "Four K/Q/J + Face")
    }

    @Test func doubleJackpot_faceWithLowKicker() {
        let rows: Set<String> = ["Four Aces + Face", "Four Aces", "Four K/Q/J + Face", "Four K/Q/J", "Four 2-10"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 13, kickerRank: 7, paytableRowNames: rows) == "Four K/Q/J")
    }

    // MARK: DDB Aces & Faces
    @Test func ddbAcesFaces_acesWithFaceKicker() {
        let rows: Set<String> = ["Four Aces + Face", "Four J-K + A-4", "Four Aces", "Four J-K", "Four 2-10"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 11, paytableRowNames: rows) == "Four Aces + Face")
    }

    @Test func ddbAcesFaces_faceWithLowKicker() {
        let rows: Set<String> = ["Four Aces + Face", "Four J-K + A-4", "Four Aces", "Four J-K", "Four 2-10"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 12, kickerRank: 14, paytableRowNames: rows) == "Four J-K + A-4")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 12, kickerRank: 3, paytableRowNames: rows) == "Four J-K + A-4")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 12, kickerRank: 7, paytableRowNames: rows) == "Four J-K")
    }

    // MARK: DDB Plus (abbreviated IDs, must fall through correctly)
    @Test func ddbPlus_usesKickerRows() {
        let rows: Set<String> = ["Four Aces + 2-4", "Four 2-4 + A-4", "Four Aces", "Four 2-4", "Four 5-K"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 2, paytableRowNames: rows) == "Four Aces + 2-4")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 3, kickerRank: 14, paytableRowNames: rows) == "Four 2-4 + A-4")
    }
}

// MARK: - resolveHighPairInfo Tests

@Suite("HandEvaluator.resolveHighPairInfo")
struct ResolveHighPairInfoTests {
    @Test func jacksOrBetter_returnsJOB() {
        let rows: Set<String> = ["Four of a Kind", "Full House", "Flush", "Straight",
                                  "Three of a Kind", "Two Pair", "Jacks or Better"]
        let info = HandEvaluator.resolveHighPairInfo(paytableRowNames: rows)
        #expect(info?.name == "Jacks or Better")
        #expect(info?.minRank == 11)
    }

    @Test func tensOrBetter_returnsTOB() {
        let rows: Set<String> = ["Four of a Kind", "Full House", "Flush", "Straight",
                                  "Three of a Kind", "Two Pair", "Tens or Better"]
        let info = HandEvaluator.resolveHighPairInfo(paytableRowNames: rows)
        #expect(info?.name == "Tens or Better")
        #expect(info?.minRank == 10)
    }

    @Test func tripleBonus_returnsKingsOrBetter() {
        let rows: Set<String> = ["Four Aces", "Four 2-4", "Four 5-K", "Full House", "Flush",
                                  "Straight", "Three of a Kind", "Two Pair", "Kings or Better"]
        let info = HandEvaluator.resolveHighPairInfo(paytableRowNames: rows)
        #expect(info?.name == "Kings or Better")
        #expect(info?.minRank == 13)
    }

    @Test func royalAcesBonus_returnsPairOfAces() {
        let rows: Set<String> = ["Four Aces", "Four 2-4", "Four 5-K", "Full House", "Flush",
                                  "Straight", "Three of a Kind", "Two Pair", "Pair of Aces"]
        let info = HandEvaluator.resolveHighPairInfo(paytableRowNames: rows)
        #expect(info?.name == "Pair of Aces")
        #expect(info?.minRank == 14)
    }

    @Test func deucesWild_returnsNil() {
        let rows: Set<String> = ["Natural Royal", "Four Deuces", "Wild Royal", "Five of a Kind",
                                  "Straight Flush", "Four of a Kind", "Full House", "Flush",
                                  "Straight", "Three of a Kind"]
        #expect(HandEvaluator.resolveHighPairInfo(paytableRowNames: rows) == nil)
    }
}
```

- [ ] **Step 3: Run tests to verify they fail (helpers not yet added)**

```
mcp__xcodebuildmcp__test_sim_name_proj
```
Expected: build failure or test failures for the new test cases.

- [ ] **Step 4: Add helpers to HandEvaluator.swift** (code in Step 1 above)

- [ ] **Step 5: Run tests to verify helpers pass**

```
mcp__xcodebuildmcp__test_sim_name_proj
```
Expected: all new tests green.

---

## Task 2: Fix PlayViewModel (Fixes 1–4)

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/PlayViewModel.swift`

### Fix 2: Loose-deuces routing + Fix 3: Wild flush in `evaluateFinalHand` / `evaluateDeucesWildHand`

- [ ] **Step 1: Add `isFlushWithWilds` private helper**

Add after the existing `isFlush` private helper:

```swift
private func isFlushWithWilds(_ cards: [Card]) -> Bool {
    let nonDeuces = cards.filter { $0.rank.rawValue != 2 }
    guard !nonDeuces.isEmpty else { return true }
    let firstSuit = nonDeuces[0].suit
    return nonDeuces.allSatisfy { $0.suit == firstSuit }
}
```

- [ ] **Step 2: Fix routing in `evaluateFinalHand` (line 688)**

Change:
```swift
if paytableId.contains("deuces-wild") {
```
To:
```swift
if paytableId.hasPrefix("deuces-wild") || paytableId.hasPrefix("loose-deuces") {
```

- [ ] **Step 3: Fix flush detection in `evaluateDeucesWildHand` (line 792)**

Change:
```swift
if isFlush(cards) {
    return HandEvaluation(handName: "Flush", winningIndices: Array(0..<5))
}
```
To:
```swift
if isFlushWithWilds(cards) {
    return HandEvaluation(handName: "Flush", winningIndices: Array(0..<5))
}
```

### Fix 1 + Fix 4: Data-driven quad names and high pair in `evaluateStandardHand`

- [ ] **Step 4: Update `evaluateFinalHand` to compute `paytableRowNames`**

Change the function body to compute row names and pass them:

```swift
private func evaluateFinalHand(_ cards: [Card]) -> HandEvaluation {
    let paytableId = settings.selectedPaytableId
    let paytableRowNames = Set(currentPaytable?.rows.map { $0.handName } ?? [])

    var rankCounts: [Int: Int] = [:]
    for card in cards {
        rankCounts[card.rank.rawValue, default: 0] += 1
    }

    let pairs = rankCounts.filter { $0.value == 2 }.map { $0.key }.sorted(by: >)
    let trips = rankCounts.filter { $0.value == 3 }.map { $0.key }
    let quads = rankCounts.filter { $0.value == 4 }.map { $0.key }
    let numDeuces = rankCounts[2, default: 0]

    if paytableId.hasPrefix("deuces-wild") || paytableId.hasPrefix("loose-deuces") {
        return evaluateDeucesWildHand(cards: cards, rankCounts: rankCounts, numDeuces: numDeuces)
    } else {
        return evaluateStandardHand(cards: cards, pairs: pairs, trips: trips, quads: quads, paytableRowNames: paytableRowNames)
    }
}
```

- [ ] **Step 5: Update `evaluateStandardHand` signature and quad/pair logic**

Replace the entire function:

```swift
private func evaluateStandardHand(cards: [Card], pairs: [Int], trips: [Int], quads: [Int], paytableRowNames: Set<String>) -> HandEvaluation {
    // Royal Flush
    if isRoyalFlush(cards) {
        return HandEvaluation(handName: "Royal Flush", winningIndices: Array(0..<5))
    }

    // Straight Flush
    if isStraightFlush(cards) {
        return HandEvaluation(handName: "Straight Flush", winningIndices: Array(0..<5))
    }

    // Four of a Kind (data-driven name resolution)
    if let quadRank = quads.first {
        let kicker = cards.first { $0.rank.rawValue != quadRank }?.rank.rawValue ?? 0
        let handName = HandEvaluator.resolveQuadHandName(quadRank: quadRank, kickerRank: kicker, paytableRowNames: paytableRowNames)
        return HandEvaluation(handName: handName, winningIndices: getCardIndices(cards: cards, rank: quadRank))
    }

    // Full House
    if !trips.isEmpty && !pairs.isEmpty {
        return HandEvaluation(handName: "Full House", winningIndices: Array(0..<5))
    }

    // Flush
    if isFlush(cards) {
        return HandEvaluation(handName: "Flush", winningIndices: Array(0..<5))
    }

    // Straight
    if isStraight(cards) {
        return HandEvaluation(handName: "Straight", winningIndices: Array(0..<5))
    }

    // Three of a Kind
    if let tripRank = trips.first {
        return HandEvaluation(handName: "Three of a Kind", winningIndices: getCardIndices(cards: cards, rank: tripRank))
    }

    // Two Pair
    if pairs.count >= 2 {
        let indices1 = getCardIndices(cards: cards, rank: pairs[0])
        let indices2 = getCardIndices(cards: cards, rank: pairs[1])
        return HandEvaluation(handName: "Two Pair", winningIndices: indices1 + indices2)
    }

    // High pair (data-driven: Jacks or Better / Tens or Better / Kings or Better / Pair of Aces)
    if let (pairName, minRank) = HandEvaluator.resolveHighPairInfo(paytableRowNames: paytableRowNames) {
        for pairRank in pairs {
            if pairRank >= minRank {
                return HandEvaluation(handName: pairName, winningIndices: getCardIndices(cards: cards, rank: pairRank))
            }
        }
    }

    return HandEvaluation(handName: nil, winningIndices: [])
}
```

- [ ] **Step 6: Remove `getFourOfAKindName` from PlayViewModel**

Delete the entire `getFourOfAKindName` function (lines 809–838).

- [ ] **Step 7: Build**

```
mcp__xcodebuildmcp__build_sim_name_proj
```
Fix any compilation errors (the old `paytableId: String` parameter references will need updating).

---

## Task 3: Fix SimulationViewModel (Fixes 1–4)

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/SimulationViewModel.swift`

Same fixes as PlayViewModel, adapted for SimulationViewModel's structure (returns `String?` not `HandEvaluation`).

- [ ] **Step 1: Add `isFlushWithWilds` private helper**

```swift
private func isFlushWithWilds(_ cards: [Card]) -> Bool {
    let nonDeuces = cards.filter { $0.rank.rawValue != 2 }
    guard !nonDeuces.isEmpty else { return true }
    let firstSuit = nonDeuces[0].suit
    return nonDeuces.allSatisfy { $0.suit == firstSuit }
}
```

- [ ] **Step 2: Fix routing in `evaluateHand` (line 300)**

Change:
```swift
if paytableId.contains("deuces-wild") {
```
To:
```swift
if paytableId.hasPrefix("deuces-wild") || paytableId.hasPrefix("loose-deuces") {
```

- [ ] **Step 3: Fix flush detection in `evaluateDeucesWildHand` (line 400)**

Change:
```swift
if isFlush(cards) {
    return "Flush"
}
```
To:
```swift
if isFlushWithWilds(cards) {
    return "Flush"
}
```

- [ ] **Step 4: Update `evaluateHand` to compute and thread `paytableRowNames`**

```swift
private func evaluateHand(_ cards: [Card], paytableId: String) -> SingleHandResult {
    var rankCounts: [Int: Int] = [:]
    for card in cards {
        rankCounts[card.rank.rawValue, default: 0] += 1
    }

    let pairs = rankCounts.filter { $0.value == 2 }.map { $0.key }.sorted(by: >)
    let trips = rankCounts.filter { $0.value == 3 }.map { $0.key }
    let quads = rankCounts.filter { $0.value == 4 }.map { $0.key }
    let numDeuces = rankCounts[2, default: 0]
    let paytableRowNames = Set(currentPaytable?.rows.map { $0.handName } ?? [])

    var handName: String?

    if paytableId.hasPrefix("deuces-wild") || paytableId.hasPrefix("loose-deuces") {
        handName = evaluateDeucesWildHand(cards: cards, rankCounts: rankCounts, numDeuces: numDeuces)
    } else {
        handName = evaluateStandardHand(cards: cards, pairs: pairs, trips: trips, quads: quads, paytableRowNames: paytableRowNames)
    }

    let payout = calculatePayout(handName: handName, paytableId: paytableId)
    return SingleHandResult(handName: handName, payout: payout)
}
```

- [ ] **Step 5: Update `evaluateStandardHand` signature and body**

```swift
private func evaluateStandardHand(cards: [Card], pairs: [Int], trips: [Int], quads: [Int], paytableRowNames: Set<String>) -> String? {
    if isRoyalFlush(cards) { return "Royal Flush" }
    if isStraightFlush(cards) { return "Straight Flush" }

    if let quadRank = quads.first {
        let kicker = cards.first { $0.rank.rawValue != quadRank }?.rank.rawValue ?? 0
        return HandEvaluator.resolveQuadHandName(quadRank: quadRank, kickerRank: kicker, paytableRowNames: paytableRowNames)
    }

    if !trips.isEmpty && !pairs.isEmpty { return "Full House" }
    if isFlush(cards) { return "Flush" }
    if isStraight(cards) { return "Straight" }
    if !trips.isEmpty { return "Three of a Kind" }
    if pairs.count >= 2 { return "Two Pair" }

    if let (pairName, minRank) = HandEvaluator.resolveHighPairInfo(paytableRowNames: paytableRowNames) {
        for pairRank in pairs {
            if pairRank >= minRank { return pairName }
        }
    }

    return nil
}
```

- [ ] **Step 6: Remove `getFourOfAKindName` from SimulationViewModel**

Delete the function at lines 417–445.

- [ ] **Step 7: Build**

```
mcp__xcodebuildmcp__build_sim_name_proj
```

---

## Task 4: Fix HandEvaluator Routing and Names (Fixes 5–6)

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Services/HandEvaluator.swift`

- [ ] **Step 1: Fix routing in `evaluateDealtHand` and add paytableRowNames**

Replace the `switch paytableId` block (lines 31–41):

```swift
// Compute paytable row names for data-driven evaluation
let paytableRowNames = Set(PayTable.allPayTables.first { $0.id == paytableId }?.rows.map { $0.handName } ?? [])

if paytableId.hasPrefix("deuces-wild") || paytableId.hasPrefix("loose-deuces") {
    return evaluateDeucesWild(hand: hand, rankCounts: rankCounts, numDeuces: numDeuces)
} else if paytableId.hasPrefix("tens-or-better") {
    return evaluateTensOrBetter(hand: hand, pairs: pairs, trips: trips, quads: quads, paytableRowNames: paytableRowNames)
} else {
    return evaluateJacksOrBetter(hand: hand, pairs: pairs, trips: trips, quads: quads, paytableRowNames: paytableRowNames)
}
```

- [ ] **Step 2: Update `evaluateJacksOrBetter` signature and quad/pair logic**

Add `paytableRowNames: Set<String>` parameter and update the quad and high pair checks:

```swift
nonisolated private func evaluateJacksOrBetter(hand: Hand, pairs: [Int], trips: [Int], quads: [Int], paytableRowNames: Set<String>) -> DealtWinnerResult {
```

Replace the Four of a Kind block:
```swift
// Four of a Kind
if let quadRank = quads.first {
    let kicker = hand.cards.first { $0.rank.rawValue != quadRank }?.rank.rawValue ?? 0
    let handName = HandEvaluator.resolveQuadHandName(quadRank: quadRank, kickerRank: kicker, paytableRowNames: paytableRowNames)
    return DealtWinnerResult(isWinner: true, handName: handName, winningIndices: getCardIndices(hand: hand, rank: quadRank))
}
```

Replace the high pair block:
```swift
// High pair (data-driven)
if let (pairName, minRank) = HandEvaluator.resolveHighPairInfo(paytableRowNames: paytableRowNames) {
    for pairRank in pairs {
        if pairRank >= minRank {
            return DealtWinnerResult(isWinner: true, handName: pairName, winningIndices: getCardIndices(hand: hand, rank: pairRank))
        }
    }
}
```

- [ ] **Step 3: Update `evaluateTensOrBetter` signature and quad/pair logic**

Same changes as `evaluateJacksOrBetter` — add `paytableRowNames: Set<String>` and use data-driven helpers for quads and high pair.

- [ ] **Step 4: Fix name literals in `evaluateDeucesWild` (Fix 6)**

Change:
```swift
handName: "Natural Royal Flush"
```
To:
```swift
handName: "Natural Royal"
```

Change:
```swift
handName: "Wild Royal Flush"
```
To:
```swift
handName: "Wild Royal"
```

- [ ] **Step 5: Build**

```
mcp__xcodebuildmcp__build_sim_name_proj
```

---

## Task 5: Full Build + Tests

- [ ] **Step 1: Full build**

```
mcp__xcodebuildmcp__build_sim_name_proj
```

- [ ] **Step 2: Run full test suite**

```
mcp__xcodebuildmcp__test_sim_name_proj
```

Expected: all tests green, including the new `HandEvaluatorTests`.

- [ ] **Step 3: Boot simulator and do a quick smoke test**

```
mcp__xcodebuildmcp__boot_simulator
mcp__xcodebuildmcp__install_app
mcp__xcodebuildmcp__launch_app
mcp__xcodebuildmcp__screenshot
```

Verify app launches without crash.
