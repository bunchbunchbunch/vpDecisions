# Ultimate X Per-Family Multiplier Tables Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single JoB-only Ultimate X multiplier table with per-game-family tables so that E[K] and strategy adjustments are correct for all game families (Bonus Poker, Double Bonus, Triple Double Bonus, Deuces Wild, etc.).

**Architecture:** Add an internal `MultiplierGroup` concept to `UltimateXMultiplierTable` that maps `GameFamily` to the correct set of per-play-count multiplier dictionaries. Update the public `multiplier(for:playCount:)` and `possibleMultipliers(for:playCount:)` APIs to accept a `GameFamily` parameter. Update the two callers (`HoldOutcomeCalculator`, `UltimateXEVBenchmarkViewModel`) to resolve family from `paytableId` and pass it through.

**Tech Stack:** Swift 6, Swift Testing framework (`@Test`, `#expect`)

---

## Background: Correct Multiplier Values by Group

Sourced from Wizard of Odds (IGT-provided tables). Groups where values are identical share one table.

### Group 1 — JacksOrBetter
Families: `jacksOrBetter`, `tensOrBetter`, `bonusPokerDeluxe`, `allAmerican`

| Hand | 3-play | 5-play | 10-play |
|------|--------|--------|---------|
| Royal Flush | 2 | 2 | 7 |
| Straight Flush | 2 | 2 | 7 |
| Four of a Kind (any) | 2 | 3 | 3 |
| Full House | 12 | 12 | 12 |
| Flush | 11 | 11 | 11 |
| Straight | 7 | 7 | 7 |
| Three of a Kind | 4 | 4 | 4 |
| Two Pair | 3 | 3 | 3 |
| Jacks or Better | 2 | 2 | 2 |
| Tens or Better | 2 | 2 | 2 |
| No win | 1 | 1 | 1 |

Note: JoB paytables have no bonus quad rows, so `HandEvaluator` returns "Four of a Kind" for all quads. All quad-specific entries ("Four Aces", etc.) should also map to the same value as "Four of a Kind" as a safety net.

### Group 2 — BonusPoker
Families: `bonusPoker`, `bonusPokerPlus`

| Hand | 3-play | 5-play | 10-play |
|------|--------|--------|---------|
| Royal Flush | 2 | 2 | 4 |
| Straight Flush | 2 | 2 | 4 |
| Four Aces (any kicker) | 2 | 2 | 4 |
| Four 2-4 (any kicker) | 2 | 2 | 4 |
| Four 5-K | 2 | 3 | 3 |
| Four of a Kind (fallback) | 2 | 3 | 3 |
| Full House | 12 | 12 | 12 |
| Flush | 11 | 11 | 11 |
| Straight | 8 | 8 | 8 |
| Three of a Kind | 4 | 4 | 4 |
| Two Pair | 3 | 3 | 3 |
| Jacks or Better | 2 | 2 | 2 |
| No win | 1 | 1 | 1 |

### Group 3 — DoubleBonus
Families: `doubleBonus`, `doubleDoubleBonus`, `superDoubleBonus`, `doubleJackpot`, `doubleDoubleJackpot`, `acesBonus`, `acesAndEights`, `acesAndFaces`, `bonusAcesFaces`, `superAces`, `royalAcesBonus`, `whiteHotAces`, `ddbAcesFaces`, `ddbPlus`

| Hand | 3-play | 5-play | 10-play |
|------|--------|--------|---------|
| Royal Flush | 2 | 2 | 4 |
| Straight Flush | 2 | 2 | 4 |
| Four Aces (any kicker) | 2 | 2 | 4 |
| Four 2-4 (any kicker) | 2 | 2 | 4 |
| Four 5-K | 2 | 3 | 3 |
| Four of a Kind (fallback) | 2 | 3 | 3 |
| Full House | 12 | 12 | 12 |
| Flush | 10 | 10 | 10 |
| Straight | 8 | 8 | 8 |
| Three of a Kind | 4 | 4 | 4 |
| Two Pair | 3 | 3 | 3 |
| Jacks or Better | 2 | 2 | 2 |
| No win | 1 | 1 | 1 |

Note: Confirmed for Double Bonus and Double Double Bonus by Wizard of Odds. Remaining families in this group are unconfirmed in published sources but are reasonable defaults given their similar hand structures. The only difference from BonusPoker is Flush (10x vs 11x).

### Group 4 — TripleDoubleBonus
Families: `tripleDoubleBonus`, `tripleBonus`, `tripleBonusPlus`, `tripleTripleBonus`

| Hand | 3-play | 5-play | 10-play |
|------|--------|--------|---------|
| Royal Flush | 2 | 2 | 2 |
| Straight Flush | 2 | 2 | 2 |
| Four of a Kind (all variants) | 2 | 2 | 2 |
| Full House | 12 | 12 | 12 |
| Flush | 10 | 10 | 10 |
| Straight | 8 | 8 | 8 |
| Three of a Kind | 4 | 4 | 4 |
| Two Pair | 3 | 3 | 3 |
| Jacks or Better | 2 | 2 | 2 |
| No win | 1 | 1 | 1 |

Note: All quads are flat 2x regardless of play count. Confirmed for Triple Double Bonus. `tripleBonus`, `tripleBonusPlus`, `tripleTripleBonus` use this as a reasonable default.

### Group 5 — DeucesWild
Families: `deucesWild`, `looseDeuces`

| Hand | 3-play | 5-play | 10-play |
|------|--------|--------|---------|
| Natural Royal Flush | 2 | 2 | 4 |
| Four Deuces | 2 | 2 | 4 |
| Wild Royal Flush | 2 | 2 | 4 |
| Five of a Kind | 2 | 3 | 3 |
| Straight Flush | 12 | 12 | 12 |
| Four of a Kind | 7 | 7 | 7 |
| Full House | 5 | 5 | 5 |
| Flush | 5 | 5 | 5 |
| Straight | 3 | 3 | 3 |
| Three of a Kind | 2 | 2 | 2 |
| No win | 1 | 1 | 1 |

---

## File Map

| File | Change |
|------|--------|
| `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/UltimateXModels.swift` | Replace single-table with per-group tables; add `GameFamily` param to public API |
| `ios-native/VideoPokerAcademy/VideoPokerAcademy/Services/HoldOutcomeCalculator.swift` | Resolve `GameFamily` once from `paytableId`; pass to multiplier call |
| `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/UltimateXEVBenchmarkViewModel.swift` | Pass `GameFamily` to `possibleMultipliers` |
| `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/UltimateXMultiplierTableTests.swift` | New test file for all multiplier table correctness |

Files that use `UltimateXMultiplierTable.maxMultiplier` only (`UltimateXStrategyService.swift`, `AnalyzerViewModel.swift`) — **no changes needed**, max is still 12 across all groups.

---

## Task 1: New multiplier table tests (failing)

**Files:**
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/UltimateXMultiplierTableTests.swift`

- [ ] **Step 1: Create the test file**

```swift
import Testing
@testable import VideoPokerAcademy

struct UltimateXMultiplierTableTests {

    // MARK: - JacksOrBetter group

    @Test("JoB 3-play: Full House = 12, Flush = 11, Straight = 7")
    func testJoBThreePlay() {
        #expect(UltimateXMultiplierTable.multiplier(for: "full house",    playCount: .three, family: .jacksOrBetter) == 12)
        #expect(UltimateXMultiplierTable.multiplier(for: "flush",         playCount: .three, family: .jacksOrBetter) == 11)
        #expect(UltimateXMultiplierTable.multiplier(for: "straight",      playCount: .three, family: .jacksOrBetter) == 7)
        #expect(UltimateXMultiplierTable.multiplier(for: "four of a kind",playCount: .three, family: .jacksOrBetter) == 2)
        #expect(UltimateXMultiplierTable.multiplier(for: "royal flush",   playCount: .three, family: .jacksOrBetter) == 2)
    }

    @Test("JoB 5-play: Four of a Kind = 3")
    func testJoBFivePlayQuads() {
        #expect(UltimateXMultiplierTable.multiplier(for: "four of a kind", playCount: .five, family: .jacksOrBetter) == 3)
        #expect(UltimateXMultiplierTable.multiplier(for: "royal flush",    playCount: .five, family: .jacksOrBetter) == 2)
    }

    @Test("JoB 10-play: Royal = 7, Straight Flush = 7, Four of a Kind = 3")
    func testJoBTenPlay() {
        #expect(UltimateXMultiplierTable.multiplier(for: "royal flush",    playCount: .ten, family: .jacksOrBetter) == 7)
        #expect(UltimateXMultiplierTable.multiplier(for: "straight flush", playCount: .ten, family: .jacksOrBetter) == 7)
        #expect(UltimateXMultiplierTable.multiplier(for: "four of a kind", playCount: .ten, family: .jacksOrBetter) == 3)
    }

    // MARK: - BonusPoker group

    @Test("BonusPoker 3-play: Straight = 8 (not 7), Flush = 11")
    func testBonusPokerThreePlay() {
        #expect(UltimateXMultiplierTable.multiplier(for: "straight", playCount: .three, family: .bonusPoker) == 8)
        #expect(UltimateXMultiplierTable.multiplier(for: "flush",    playCount: .three, family: .bonusPoker) == 11)
    }

    @Test("BonusPoker 10-play: Royal = 4, Four Aces = 4, Four 5-K = 3")
    func testBonusPokerTenPlay() {
        #expect(UltimateXMultiplierTable.multiplier(for: "royal flush", playCount: .ten, family: .bonusPoker) == 4)
        #expect(UltimateXMultiplierTable.multiplier(for: "four aces",   playCount: .ten, family: .bonusPoker) == 4)
        #expect(UltimateXMultiplierTable.multiplier(for: "four 5-k",    playCount: .ten, family: .bonusPoker) == 3)
    }

    // MARK: - DoubleBonus group

    @Test("DoubleBonus 3-play: Flush = 10 (not 11), Straight = 8")
    func testDoubleBonusThreePlay() {
        #expect(UltimateXMultiplierTable.multiplier(for: "flush",    playCount: .three, family: .doubleBonus) == 10)
        #expect(UltimateXMultiplierTable.multiplier(for: "straight", playCount: .three, family: .doubleBonus) == 8)
    }

    @Test("DoubleBonus 10-play: Royal = 4, Four Aces = 4, Four 5-K = 3")
    func testDoubleBonusTenPlay() {
        #expect(UltimateXMultiplierTable.multiplier(for: "royal flush", playCount: .ten, family: .doubleBonus) == 4)
        #expect(UltimateXMultiplierTable.multiplier(for: "four aces",   playCount: .ten, family: .doubleBonus) == 4)
        #expect(UltimateXMultiplierTable.multiplier(for: "four 5-k",    playCount: .ten, family: .doubleBonus) == 3)
    }

    @Test("DDB family uses DoubleBonus group: Flush = 10")
    func testDDBFamily() {
        #expect(UltimateXMultiplierTable.multiplier(for: "flush", playCount: .three, family: .doubleDoubleBonus) == 10)
        #expect(UltimateXMultiplierTable.multiplier(for: "flush", playCount: .three, family: .ddbPlus) == 10)
    }

    // MARK: - TripleDoubleBonus group

    @Test("TripleDoubleBonus: All quads flat 2x across all play counts")
    func testTripleDoubleBonusQuadsFlat() {
        for playCount in UltimateXPlayCount.allCases {
            #expect(UltimateXMultiplierTable.multiplier(for: "royal flush",    playCount: playCount, family: .tripleDoubleBonus) == 2)
            #expect(UltimateXMultiplierTable.multiplier(for: "four of a kind", playCount: playCount, family: .tripleDoubleBonus) == 2)
            #expect(UltimateXMultiplierTable.multiplier(for: "four aces",      playCount: playCount, family: .tripleDoubleBonus) == 2)
        }
    }

    @Test("TripleDoubleBonus: Flush = 10, Straight = 8, Full House = 12")
    func testTripleDoubleBonusMiddleHands() {
        #expect(UltimateXMultiplierTable.multiplier(for: "full house", playCount: .three, family: .tripleDoubleBonus) == 12)
        #expect(UltimateXMultiplierTable.multiplier(for: "flush",      playCount: .three, family: .tripleDoubleBonus) == 10)
        #expect(UltimateXMultiplierTable.multiplier(for: "straight",   playCount: .three, family: .tripleDoubleBonus) == 8)
    }

    // MARK: - DeucesWild group

    // IMPORTANT: HandEvaluator.evaluateDeucesWild returns "Natural Royal" and "Wild Royal"
    // (NOT "Natural Royal Flush" / "Wild Royal Flush"). Keys must match exactly after lowercasing.

    @Test("DeucesWild 3-play: Straight Flush = 12, Four of a Kind = 7, Full House = 5")
    func testDeucesWildThreePlay() {
        #expect(UltimateXMultiplierTable.multiplier(for: "straight flush",  playCount: .three, family: .deucesWild) == 12)
        #expect(UltimateXMultiplierTable.multiplier(for: "four of a kind",  playCount: .three, family: .deucesWild) == 7)
        #expect(UltimateXMultiplierTable.multiplier(for: "full house",      playCount: .three, family: .deucesWild) == 5)
        #expect(UltimateXMultiplierTable.multiplier(for: "flush",           playCount: .three, family: .deucesWild) == 5)
        #expect(UltimateXMultiplierTable.multiplier(for: "straight",        playCount: .three, family: .deucesWild) == 3)
        #expect(UltimateXMultiplierTable.multiplier(for: "three of a kind", playCount: .three, family: .deucesWild) == 2)
        #expect(UltimateXMultiplierTable.multiplier(for: "wild royal",      playCount: .three, family: .deucesWild) == 2)   // matches HandEvaluator output
        #expect(UltimateXMultiplierTable.multiplier(for: "natural royal",   playCount: .three, family: .deucesWild) == 2)   // matches HandEvaluator output
        #expect(UltimateXMultiplierTable.multiplier(for: "four deuces",     playCount: .three, family: .deucesWild) == 2)
    }

    @Test("DeucesWild 5-play: Five of a Kind = 3")
    func testDeucesWildFivePlayFiveOfAKind() {
        #expect(UltimateXMultiplierTable.multiplier(for: "five of a kind", playCount: .five,  family: .deucesWild) == 3)
        #expect(UltimateXMultiplierTable.multiplier(for: "five of a kind", playCount: .three, family: .deucesWild) == 2)
    }

    @Test("DeucesWild 10-play: Natural Royal = 4, Four Deuces = 4")
    func testDeucesWildTenPlay() {
        #expect(UltimateXMultiplierTable.multiplier(for: "natural royal",  playCount: .ten, family: .deucesWild) == 4)   // matches HandEvaluator output
        #expect(UltimateXMultiplierTable.multiplier(for: "four deuces",    playCount: .ten, family: .deucesWild) == 4)
        #expect(UltimateXMultiplierTable.multiplier(for: "wild royal",     playCount: .ten, family: .deucesWild) == 4)   // matches HandEvaluator output
        #expect(UltimateXMultiplierTable.multiplier(for: "straight flush", playCount: .ten, family: .deucesWild) == 12)
    }

    @Test("LooseDeuces uses DeucesWild group")
    func testLooseDeucesUsesDeucesWildGroup() {
        #expect(UltimateXMultiplierTable.multiplier(for: "straight flush", playCount: .three, family: .looseDeuces) == 12)
        #expect(UltimateXMultiplierTable.multiplier(for: "four of a kind", playCount: .three, family: .looseDeuces) == 7)
    }

    // MARK: - possibleMultipliers

    @Test("JoB possibleMultipliers: contains 11 and 12, not 5")
    func testPossibleMultipliersJoB() {
        let multipliers = UltimateXMultiplierTable.possibleMultipliers(for: .three, family: .jacksOrBetter)
        #expect(multipliers.contains(11))
        #expect(multipliers.contains(12))
        #expect(!multipliers.contains(5))
    }

    @Test("DeucesWild possibleMultipliers: contains 12 and 7, not 11")
    func testPossibleMultipliersDeucesWild() {
        let multipliers = UltimateXMultiplierTable.possibleMultipliers(for: .three, family: .deucesWild)
        #expect(multipliers.contains(12))
        #expect(multipliers.contains(7))
        #expect(!multipliers.contains(11))
    }

    // MARK: - Unknown hands fall back to 1

    @Test("Unknown hand name returns 1 (no multiplier)")
    func testUnknownHandReturnsOne() {
        #expect(UltimateXMultiplierTable.multiplier(for: "garbage hand", playCount: .three, family: .jacksOrBetter) == 1)
        #expect(UltimateXMultiplierTable.multiplier(for: "garbage hand", playCount: .three, family: .deucesWild) == 1)
    }
}
```

- [ ] **Step 2: Add test file to Xcode project**

The test file must be added to the `VideoPokerAcademyTests` target. Open Xcode → VideoPokerAcademyTests group → Add Files → select the new file, ensuring "VideoPokerAcademyTests" target is checked.

- [ ] **Step 3: Build and confirm tests fail**

Run: `mcp__xcodebuildmcp__test_sim_name_proj` with scheme `VideoPokerAcademy`, simulator `iPhone 16`
Expected: compile errors — `multiplier(for:playCount:family:)` doesn't exist yet.

---

## Task 2: Implement per-family multiplier tables in `UltimateXModels.swift`

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/UltimateXModels.swift`

- [ ] **Step 1: Replace `UltimateXMultiplierTable` with per-family implementation**

Replace the entire `UltimateXMultiplierTable` struct (lines 22–115) with the following. Keep all other structs/enums in the file untouched.

```swift
// MARK: - Ultimate X Multiplier Table

/// Per-game-family multiplier tables for Ultimate X poker.
/// Multiplier values sourced from Wizard of Odds (IGT-provided tables).
struct UltimateXMultiplierTable {

    // MARK: - Public API

    /// Returns the multiplier for a given hand name, play count, and game family.
    static func multiplier(for handName: String, playCount: UltimateXPlayCount, family: GameFamily) -> Int {
        let normalized = handName.lowercased()
        let group = multiplierGroup(for: family)
        switch playCount {
        case .three: return group.threePlay[normalized] ?? 1
        case .five:  return group.fivePlay[normalized]  ?? 1
        case .ten:   return group.tenPlay[normalized]   ?? 1
        }
    }

    /// Returns all distinct multiplier values that can be awarded for a game family and play count.
    static func possibleMultipliers(for playCount: UltimateXPlayCount, family: GameFamily) -> [Int] {
        let group = multiplierGroup(for: family)
        let table: [String: Int]
        switch playCount {
        case .three: table = group.threePlay
        case .five:  table = group.fivePlay
        case .ten:   table = group.tenPlay
        }
        return Array(Set(table.values)).sorted()
    }

    /// Maximum possible multiplier across all game families and play counts.
    static let maxMultiplier = 12

    // MARK: - Group Mapping

    private static func multiplierGroup(for family: GameFamily) -> MultiplierGroup {
        switch family {
        case .jacksOrBetter, .tensOrBetter, .bonusPokerDeluxe, .allAmerican:
            return .jacksOrBetter
        case .bonusPoker, .bonusPokerPlus:
            return .bonusPoker
        case .doubleBonus, .doubleDoubleBonus, .superDoubleBonus,
             .doubleJackpot, .doubleDoubleJackpot,
             .acesBonus, .acesAndEights, .acesAndFaces, .bonusAcesFaces,
             .superAces, .royalAcesBonus, .whiteHotAces,
             .ddbAcesFaces, .ddbPlus:
            return .doubleBonus
        case .tripleDoubleBonus, .tripleBonus, .tripleBonusPlus, .tripleTripleBonus:
            return .tripleDoubleBonus
        case .deucesWild, .looseDeuces:
            return .deucesWild
        }
    }

    // MARK: - Multiplier Group Data

    private struct MultiplierGroup {
        let threePlay: [String: Int]
        let fivePlay:  [String: Int]
        let tenPlay:   [String: Int]
    }

    // MARK: Group 1: Jacks or Better
    // Source: Wizard of Odds — confirmed for JoB, BonusPokerDeluxe, AllAmerican, TensOrBetter
    // Note: "tens or better" included here because tensOrBetter family maps to this group.
    //       Non-JoB groups do not need this key since tensOrBetter is never assigned to them.
    // Note: "no win": 1 is included explicitly so possibleMultipliers() returns 1 via Set(table.values).

    private static let jacksOrBetter = MultiplierGroup(
        threePlay: [
            "royal flush": 2, "straight flush": 2,
            "four of a kind": 2, "four aces": 2, "four 2-4": 2, "four 5-k": 2,
            "four aces + 2-4": 2, "four 2-4 + a-4": 2,
            "four aces + face": 2, "four j-k": 2, "four j-k + a-4": 2,
            "four face": 2, "four face + a-k": 2, "four k/q/j": 2, "four k/q/j + face": 2,
            "four 2-10": 2, "four 2-6/9-k": 2, "four sevens": 2, "four aces/eights": 2,
            "four 2-4 + 2-4": 2,
            "full house": 12, "flush": 11, "straight": 7,
            "three of a kind": 4, "two pair": 3,
            "jacks or better": 2, "tens or better": 2, "no win": 1,
        ],
        fivePlay: [
            "royal flush": 2, "straight flush": 2,
            "four of a kind": 3, "four aces": 3, "four 2-4": 3, "four 5-k": 3,
            "four aces + 2-4": 3, "four 2-4 + a-4": 3,
            "four aces + face": 3, "four j-k": 3, "four j-k + a-4": 3,
            "four face": 3, "four face + a-k": 3, "four k/q/j": 3, "four k/q/j + face": 3,
            "four 2-10": 3, "four 2-6/9-k": 3, "four sevens": 3, "four aces/eights": 3,
            "four 2-4 + 2-4": 3,
            "full house": 12, "flush": 11, "straight": 7,
            "three of a kind": 4, "two pair": 3,
            "jacks or better": 2, "tens or better": 2, "no win": 1,
        ],
        tenPlay: [
            "royal flush": 7, "straight flush": 7,
            "four of a kind": 3, "four aces": 3, "four 2-4": 3, "four 5-k": 3,
            "four aces + 2-4": 3, "four 2-4 + a-4": 3,
            "four aces + face": 3, "four j-k": 3, "four j-k + a-4": 3,
            "four face": 3, "four face + a-k": 3, "four k/q/j": 3, "four k/q/j + face": 3,
            "four 2-10": 3, "four 2-6/9-k": 3, "four sevens": 3, "four aces/eights": 3,
            "four 2-4 + 2-4": 3,
            "full house": 12, "flush": 11, "straight": 7,
            "three of a kind": 4, "two pair": 3,
            "jacks or better": 2, "tens or better": 2, "no win": 1,
        ]
    )

    // MARK: Group 2: Bonus Poker
    // Source: Wizard of Odds — Straight 8x (not 7x), RF 10-play 4x (not 7x)

    private static let bonusPoker = MultiplierGroup(
        threePlay: [
            "royal flush": 2, "straight flush": 2,
            "four aces": 2, "four aces + 2-4": 2, "four aces + face": 2,
            "four 2-4": 2, "four 2-4 + a-4": 2, "four 2-4 + 2-4": 2,
            "four 5-k": 2, "four of a kind": 2,
            "four j-k": 2, "four j-k + a-4": 2, "four face": 2,
            "four face + a-k": 2, "four k/q/j": 2, "four k/q/j + face": 2,
            "four 2-10": 2, "four 2-6/9-k": 2, "four sevens": 2, "four aces/eights": 2,
            "full house": 12, "flush": 11, "straight": 8,
            "three of a kind": 4, "two pair": 3, "jacks or better": 2, "no win": 1,
        ],
        fivePlay: [
            "royal flush": 2, "straight flush": 2,
            "four aces": 2, "four aces + 2-4": 2, "four aces + face": 2,
            "four 2-4": 2, "four 2-4 + a-4": 2, "four 2-4 + 2-4": 2,
            "four 5-k": 3, "four of a kind": 3,
            "four j-k": 3, "four j-k + a-4": 3, "four face": 3,
            "four face + a-k": 3, "four k/q/j": 3, "four k/q/j + face": 3,
            "four 2-10": 3, "four 2-6/9-k": 3, "four sevens": 3, "four aces/eights": 3,
            "full house": 12, "flush": 11, "straight": 8,
            "three of a kind": 4, "two pair": 3, "jacks or better": 2, "no win": 1,
        ],
        tenPlay: [
            "royal flush": 4, "straight flush": 4,
            "four aces": 4, "four aces + 2-4": 4, "four aces + face": 4,
            "four 2-4": 4, "four 2-4 + a-4": 4, "four 2-4 + 2-4": 4,
            "four 5-k": 3, "four of a kind": 3,
            "four j-k": 3, "four j-k + a-4": 3, "four face": 3,
            "four face + a-k": 3, "four k/q/j": 3, "four k/q/j + face": 3,
            "four 2-10": 3, "four 2-6/9-k": 3, "four sevens": 3, "four aces/eights": 3,
            "full house": 12, "flush": 11, "straight": 8,
            "three of a kind": 4, "two pair": 3, "jacks or better": 2, "no win": 1,
        ]
    )

    // MARK: Group 3: Double Bonus
    // Source: Wizard of Odds — Flush 10x (not 11x), Straight 8x, RF 10-play 4x

    private static let doubleBonus = MultiplierGroup(
        threePlay: [
            "royal flush": 2, "straight flush": 2,
            "four aces": 2, "four aces + 2-4": 2, "four aces + face": 2,
            "four 2-4": 2, "four 2-4 + a-4": 2, "four 2-4 + 2-4": 2,
            "four 5-k": 2, "four of a kind": 2,
            "four j-k": 2, "four j-k + a-4": 2, "four face": 2,
            "four face + a-k": 2, "four k/q/j": 2, "four k/q/j + face": 2,
            "four 2-10": 2, "four 2-6/9-k": 2, "four sevens": 2, "four aces/eights": 2,
            "full house": 12, "flush": 10, "straight": 8,
            "three of a kind": 4, "two pair": 3, "jacks or better": 2, "no win": 1,
        ],
        fivePlay: [
            "royal flush": 2, "straight flush": 2,
            "four aces": 2, "four aces + 2-4": 2, "four aces + face": 2,
            "four 2-4": 2, "four 2-4 + a-4": 2, "four 2-4 + 2-4": 2,
            "four 5-k": 3, "four of a kind": 3,
            "four j-k": 3, "four j-k + a-4": 3, "four face": 3,
            "four face + a-k": 3, "four k/q/j": 3, "four k/q/j + face": 3,
            "four 2-10": 3, "four 2-6/9-k": 3, "four sevens": 3, "four aces/eights": 3,
            "full house": 12, "flush": 10, "straight": 8,
            "three of a kind": 4, "two pair": 3, "jacks or better": 2, "no win": 1,
        ],
        tenPlay: [
            "royal flush": 4, "straight flush": 4,
            "four aces": 4, "four aces + 2-4": 4, "four aces + face": 4,
            "four 2-4": 4, "four 2-4 + a-4": 4, "four 2-4 + 2-4": 4,
            "four 5-k": 3, "four of a kind": 3,
            "four j-k": 3, "four j-k + a-4": 3, "four face": 3,
            "four face + a-k": 3, "four k/q/j": 3, "four k/q/j + face": 3,
            "four 2-10": 3, "four 2-6/9-k": 3, "four sevens": 3, "four aces/eights": 3,
            "full house": 12, "flush": 10, "straight": 8,
            "three of a kind": 4, "two pair": 3, "jacks or better": 2, "no win": 1,
        ]
    )

    // MARK: Group 4: Triple Double Bonus
    // Source: Wizard of Odds — ALL quads flat 2x regardless of play count

    private static let tripleDoubleBonus = MultiplierGroup(
        threePlay: [
            "royal flush": 2, "straight flush": 2,
            "four aces": 2, "four aces + 2-4": 2, "four aces + face": 2,
            "four 2-4": 2, "four 2-4 + a-4": 2, "four 2-4 + 2-4": 2,
            "four 5-k": 2, "four of a kind": 2,
            "four j-k": 2, "four j-k + a-4": 2, "four face": 2,
            "four face + a-k": 2, "four k/q/j": 2, "four k/q/j + face": 2,
            "four 2-10": 2, "four 2-6/9-k": 2, "four sevens": 2, "four aces/eights": 2,
            "full house": 12, "flush": 10, "straight": 8,
            "three of a kind": 4, "two pair": 3, "jacks or better": 2, "no win": 1,
        ],
        fivePlay: [
            "royal flush": 2, "straight flush": 2,
            "four aces": 2, "four aces + 2-4": 2, "four aces + face": 2,
            "four 2-4": 2, "four 2-4 + a-4": 2, "four 2-4 + 2-4": 2,
            "four 5-k": 2, "four of a kind": 2,
            "four j-k": 2, "four j-k + a-4": 2, "four face": 2,
            "four face + a-k": 2, "four k/q/j": 2, "four k/q/j + face": 2,
            "four 2-10": 2, "four 2-6/9-k": 2, "four sevens": 2, "four aces/eights": 2,
            "full house": 12, "flush": 10, "straight": 8,
            "three of a kind": 4, "two pair": 3, "jacks or better": 2, "no win": 1,
        ],
        tenPlay: [
            "royal flush": 2, "straight flush": 2,
            "four aces": 2, "four aces + 2-4": 2, "four aces + face": 2,
            "four 2-4": 2, "four 2-4 + a-4": 2, "four 2-4 + 2-4": 2,
            "four 5-k": 2, "four of a kind": 2,
            "four j-k": 2, "four j-k + a-4": 2, "four face": 2,
            "four face + a-k": 2, "four k/q/j": 2, "four k/q/j + face": 2,
            "four 2-10": 2, "four 2-6/9-k": 2, "four sevens": 2, "four aces/eights": 2,
            "full house": 12, "flush": 10, "straight": 8,
            "three of a kind": 4, "two pair": 3, "jacks or better": 2, "no win": 1,
        ]
    )

    // MARK: Group 5: Deuces Wild
    // Source: Wizard of Odds — completely different structure; SF=12x, 4oK=7x, FH=Flush=5x
    // KEY NOTE: HandEvaluator.evaluateDeucesWild returns "Natural Royal" and "Wild Royal"
    // (not "Natural Royal Flush" / "Wild Royal Flush"). Keys must match after lowercasing.

    private static let deucesWild = MultiplierGroup(
        threePlay: [
            "natural royal": 2, "four deuces": 2, "wild royal": 2,   // exact HandEvaluator strings
            "five of a kind": 2, "straight flush": 12, "four of a kind": 7,
            "full house": 5, "flush": 5, "straight": 3, "three of a kind": 2,
            "no win": 1,
        ],
        fivePlay: [
            "natural royal": 2, "four deuces": 2, "wild royal": 2,
            "five of a kind": 3, "straight flush": 12, "four of a kind": 7,
            "full house": 5, "flush": 5, "straight": 3, "three of a kind": 2,
            "no win": 1,
        ],
        tenPlay: [
            "natural royal": 4, "four deuces": 4, "wild royal": 4,
            "five of a kind": 3, "straight flush": 12, "four of a kind": 7,
            "full house": 5, "flush": 5, "straight": 3, "three of a kind": 2,
            "no win": 1,
        ]
    )
}
```

- [ ] **Step 2: Build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: compile error — callers still pass the old 2-argument `multiplier(for:playCount:)`. That's expected; fix in Tasks 3 and 4.

---

## Task 3: Update `HoldOutcomeCalculator` to pass `GameFamily`

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Services/HoldOutcomeCalculator.swift`

The actor already receives `paytableId`. Resolve `GameFamily` once at the top of `computeEK`, then pass it to `multiplier(for:playCount:family:)`. This avoids a dictionary lookup on every iteration of the inner loop.

- [ ] **Step 1: Update `computeEK`**

In `computeEK(hand:holdBitmask:paytableId:playCount:)`, add family resolution after the `guard holdBitmask != 0` line, and thread it through both multiplier call sites:

```swift
func computeEK(
    hand: Hand,
    holdBitmask: Int,
    paytableId: String,
    playCount: UltimateXPlayCount
) async -> Double {
    guard holdBitmask != 0 else { return 1.0 }

    // Resolve family once — avoids per-iteration lookup in inner loop
    let family = PayTable.allPayTables.first(where: { $0.id == paytableId })?.family ?? .jacksOrBetter

    let canonicalIndices = Hand.holdIndicesFromBitmask(holdBitmask)
    // ... rest of function unchanged until the two multiplier call sites ...

    // In the drawCount == 0 branch (hold all 5):
    let multiplier = UltimateXMultiplierTable.multiplier(
        for: result.handName ?? "",
        playCount: playCount,
        family: family          // ← add this
    )

    // In the inner loop:
    let multiplier = UltimateXMultiplierTable.multiplier(
        for: result.handName ?? "",
        playCount: playCount,
        family: family          // ← add this
    )
```

- [ ] **Step 2: Build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: one remaining compile error in `UltimateXEVBenchmarkViewModel`.

---

## Task 4: Update `UltimateXEVBenchmarkViewModel` to pass `GameFamily`

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/UltimateXEVBenchmarkViewModel.swift`

The view model already has `paytableId`. Replace the `possibleMultipliers` call to include family.

- [ ] **Step 1: Update `possibleMultipliers` call**

Find line ~86 (the comment and call to `possibleMultipliers`) and update both:

```swift
// Resolve family for this paytable
let family = PayTable.allPayTables.first(where: { $0.id == paytableId })?.family ?? .jacksOrBetter

// 2. Random valid UX multiplier (set varies by game family)
let validMultipliers = UltimateXMultiplierTable.possibleMultipliers(for: playCount, family: family)
```

- [ ] **Step 2: Build — must be clean**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: clean build, zero errors.

---

## Task 5: Run tests and verify

- [ ] **Step 1: Run all tests**

Run: `mcp__xcodebuildmcp__test_sim_name_proj`
Expected: all tests pass, including the new `UltimateXMultiplierTableTests` and the existing `HoldOutcomeCalculatorTests`.

Existing `HoldOutcomeCalculatorTests` passes `paytableId: "jacks-or-better-9-6"` — the full house test expects `12.0` which is still correct for JoB.

- [ ] **Step 2: Verify in benchmark tool (optional smoke test)**

Boot simulator, install, launch, navigate to Settings → Developer → UX EV Benchmark.
Run a benchmark on a Deuces Wild game and confirm the E[K] values look plausible (straight flush = 12x in deuces wild should dominate).

Run:
```
mcp__xcodebuildmcp__boot_simulator
mcp__xcodebuildmcp__install_app
mcp__xcodebuildmcp__launch_app
mcp__xcodebuildmcp__screenshot
```
