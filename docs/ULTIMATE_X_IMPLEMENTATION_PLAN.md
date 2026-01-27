# Ultimate X Poker Implementation Plan

## Executive Summary

This document outlines the strategy generation approach and implementation plan for adding Ultimate X poker to the Video Poker Trainer app. Based on research and your preferences:

- **Target variant**: Classic IGT Ultimate X
- **Hand configurations**: 3-play, 5-play, 10-play
- **Initial base game**: Jacks or Better 9/6
- **Priority mode**: Analyzer first, then Play mode, then Quiz mode
- **Multiplier persistence**: Reset on app close
- **Strategy approach**: Real-time calculation using existing strategy files (recommended)

---

## Part 1: Understanding Ultimate X Poker

### How Ultimate X Works

Ultimate X is a multi-hand video poker variant where winning hands generate **multipliers** that apply to your **next** hand on that line.

**Basic Flow:**
1. Player bets 10 coins per line (2x normal max bet) to activate Ultimate X feature
2. Player is dealt 5 cards, selects holds, draws replacements (standard video poker)
3. Each line evaluates independently
4. Winning hands award a multiplier (2x-12x) for that line's **next** hand
5. Next hand's winnings on that line are multiplied by the stored multiplier
6. New multipliers replace old ones (they don't stack)

**Example:**
- Hand 1, Line 3: Win a Full House → awards 12x multiplier for Line 3
- Hand 2, Line 3: Win Three of a Kind (pays 3) → actual payout is 3 × 12 = 36
- Hand 2, Line 3: Also awards new 4x multiplier for next hand

### Multiplier Tables

Multipliers are determined by the **winning hand type**, not the paytable payouts. The multipliers are consistent across all Jacks or Better variants:

| Hand | 3-Play | 5-Play | 10-Play |
|------|--------|--------|---------|
| Royal Flush | 2 | 2 | 7 |
| Straight Flush | 2 | 2 | 7 |
| Four of a Kind | 2 | 3 | 3 |
| Full House | 12 | 12 | 12 |
| Flush | 11 | 11 | 11 |
| Straight | 7 | 7 | 7 |
| Three of a Kind | 4 | 4 | 4 |
| Two Pair | 3 | 3 | 3 |
| Jacks or Better | 2 | 2 | 2 |

**Return with Ultimate X active:**
- 3-play: ~99.30%
- 5-play: ~99.40%
- 10-play: ~99.42%

(Based on 8/6 Jacks or Better; your 9/6 version will be slightly higher)

### Why Strategy Changes

The key insight is that **multipliers affect future value, which changes current EV calculations**.

When you have a high multiplier active:
- Hands that are more likely to win *something* become more valuable
- You might hold a low pair over a 4-card straight because the guaranteed 2-pair/trips potential is worth more when multiplied

When you have no multiplier (1x):
- Strategy tilts toward hands that generate high multipliers (Full House = 12x, Flush = 11x)
- You might chase flushes/full houses more aggressively

**The adjustment formula:**
```
Adjusted Win = 2 × (Base Win) + (Multiplier) - 1
```

For example, with a 12x multiplier and a Full House (base win 9):
- Adjusted Win = 2 × 9 + 12 - 1 = 29

This formula is used to recalculate EVs for strategy decisions.

---

## Part 2: Strategy Generation Approaches

### Option A: Full Pre-computed Strategies (NOT Recommended)

**Approach:** Generate complete strategy files for every (hand × multiplier state) combination.

**Pros:**
- Fastest lookups at runtime
- Most accurate

**Cons:**
- File size explosion: ~2.6M hands × ~12 multiplier states = 31M+ entries
- File size: 50-100MB per game (vs current 1-3MB)
- Long generation time: 10-50 hours per game
- Storage burden on users

**Verdict:** Not recommended for initial implementation.

### Option B: Real-time Calculation (RECOMMENDED)

**Approach:** Use existing strategy files for base EVs, apply multiplier adjustments in real-time.

**How it works:**
1. Look up hand in existing strategy file → get EVs for all 32 hold options
2. For each hold option, calculate probability distribution of outcomes
3. Apply multiplier adjustment formula to each outcome's EV
4. Compare adjusted EVs to find optimal hold

**Pros:**
- No new strategy files needed (use existing 9/6 JoB file)
- Minimal storage impact
- Can add Ultimate X to any existing game instantly
- Easier to update/fix

**Cons:**
- Slightly slower lookups (still <10ms, acceptable)
- Requires outcome probability calculations

**Implementation complexity:** Medium

**Verdict:** Recommended approach. Leverages existing infrastructure.

### Option C: Threshold-based Exceptions (Hybrid)

**Approach:** Use base strategy + small exceptions table for multiplier-sensitive hands.

**How it works:**
1. Store a small table of "exception hands" where strategy changes based on multiplier
2. For most hands, use base strategy
3. For exception hands, check multiplier threshold and adjust

**Research finding:** The Wizard of Odds documents some exceptions:
- Suited 2JQA-9QKA with low pairs: threshold ≤1.2x
- Suited 2TJA-9TKA with low pairs: threshold ≤1.5x
- Unsuited 89TJ with medium pairs: threshold ≤1.6x

**Pros:**
- Very fast lookups
- Small additional storage

**Cons:**
- May miss some edge cases
- Requires comprehensive exception analysis
- Less accurate than real-time calculation

**Verdict:** Could be used as optimization later, but start with Option B.

---

## Part 3: Recommended Implementation Strategy

### Phase 1: Core Infrastructure

#### 1.1 Data Models

```swift
// New multiplier state model
struct UltimateXMultiplierState {
    var multipliers: [Int]  // One per line, values 1-12
    let playCount: PlayCount  // .three, .five, .ten

    static func initial(playCount: PlayCount) -> Self {
        UltimateXMultiplierState(
            multipliers: Array(repeating: 1, count: playCount.rawValue),
            playCount: playCount
        )
    }
}

enum PlayCount: Int {
    case three = 3
    case five = 5
    case ten = 10
}

// Multiplier table (hand type → multiplier awarded)
struct UltimateXMultiplierTable {
    let playCount: PlayCount

    func multiplierFor(handType: String) -> Int {
        // Returns multiplier based on hand type and play count
        // See table above
    }
}
```

#### 1.2 Strategy Calculation Service

```swift
actor UltimateXStrategyService {
    private let baseStrategyService: StrategyService

    /// Calculate optimal hold considering current multiplier
    func lookup(
        hand: Hand,
        currentMultiplier: Int,
        paytableId: String,
        playCount: PlayCount
    ) async throws -> UltimateXStrategyResult {
        // 1. Get base strategy result
        let baseResult = try await baseStrategyService.lookup(hand: hand, paytableId: paytableId)

        // 2. If multiplier is 1, base strategy is optimal (no adjustment needed)
        if currentMultiplier == 1 {
            return UltimateXStrategyResult(from: baseResult, multiplier: 1)
        }

        // 3. Apply multiplier adjustments
        return calculateAdjustedStrategy(
            hand: hand,
            baseResult: baseResult,
            multiplier: currentMultiplier,
            playCount: playCount
        )
    }

    private func calculateAdjustedStrategy(...) -> UltimateXStrategyResult {
        // Apply formula: Adjusted EV = 2 × (Base EV) + (Multiplier) - 1
        // for each hold option, then find new optimal
    }
}
```

#### 1.3 Outcome Probability Calculator

For accurate real-time calculation, we need to know the probability distribution of outcomes for each hold decision.

```swift
struct HoldOutcomeCalculator {
    /// Given a hand and hold mask, calculate probability of each outcome
    func calculateOutcomes(
        hand: Hand,
        holdMask: Int,
        paytable: PayTable
    ) -> [HandOutcome] {
        // Calculate combinations for each possible final hand
        // Return probability and payout for each outcome
    }
}

struct HandOutcome {
    let handType: String  // "Full House", "Flush", etc.
    let probability: Double
    let basePayout: Int
    let multiplierAwarded: Int
}
```

### Phase 2: Analyzer Mode Implementation

Since Analyzer is your priority, implement this first to validate the strategy calculations.

#### 2.1 UI Changes

```
┌─────────────────────────────────────────┐
│  Ultimate X Analyzer                    │
├─────────────────────────────────────────┤
│  Current Multiplier: [1x] [2x] [3x]... │  ← Picker/stepper
├─────────────────────────────────────────┤
│  Play Type: [3-Play] [5-Play] [10-Play] │
├─────────────────────────────────────────┤
│  [Card Selection UI - existing]         │
├─────────────────────────────────────────┤
│  Optimal Hold: K♠ K♦                    │
│  Base EV: 1.54                          │
│  Adjusted EV: 3.21 (with 2x multiplier) │
│                                         │
│  Hold Options:                          │
│  1. K♠ K♦     → Adj EV: 3.21  ← Best   │
│  2. K♠ K♦ 9♣  → Adj EV: 2.89           │
│  3. ...                                 │
│                                         │
│  Strategy Difference:                   │
│  ⚠️ With 1x: Hold K♠ K♦ 9♣ (trips draw)│
│  ✓ With 2x: Hold K♠ K♦ (pair better)   │
└─────────────────────────────────────────┘
```

#### 2.2 Key Features

1. **Multiplier selector**: Let user set hypothetical multiplier (1-12)
2. **Play count selector**: 3/5/10 affects multiplier tables
3. **Side-by-side comparison**: Show base strategy vs adjusted strategy
4. **Highlight differences**: Call out when multiplier changes optimal play
5. **Outcome breakdown**: Show probability of each result and its multiplier award

### Phase 3: Play Mode Implementation

#### 3.1 Game State Model

```swift
struct UltimateXGameState {
    var playCount: PlayCount
    var multiplierState: UltimateXMultiplierState
    var currentHand: Hand?
    var results: [LineResult]
    var totalBet: Int  // 10 coins per line

    mutating func applyResults(_ results: [LineResult]) {
        for (index, result) in results.enumerated() {
            if let handType = result.winningHand {
                multiplierState.multipliers[index] =
                    multiplierTable.multiplierFor(handType: handType)
            } else {
                multiplierState.multipliers[index] = 1  // Reset on loss
            }
        }
    }
}
```

#### 3.2 UI Layout (10-Play Example)

```
┌─────────────────────────────────────────────────┐
│  Ultimate X - Jacks or Better 9/6               │
│  Balance: $500.00    Bet: $12.50 (10×$0.25×5)  │
├─────────────────────────────────────────────────┤
│  Multipliers:                                   │
│  [2x][1x][12x][1x][1x][1x][3x][1x][1x][1x]    │  ← Shows next-hand multipliers
├─────────────────────────────────────────────────┤
│  [Main Hand Display - 5 cards]                  │
│                                                 │
│  Line Results (after draw):                     │
│  ┌───┬───┬───┬───┬───┐                        │
│  │ 1 │ 2 │ 3 │ 4 │ 5 │ (lines 1-5)            │
│  │2x │   │12x│   │   │ multiplier applied      │
│  │JoB│   │FH │   │   │ result                  │
│  │ 2 │ 0 │108│ 0 │ 0 │ payout                  │
│  ├───┼───┼───┼───┼───┤                        │
│  │ 6 │ 7 │ 8 │ 9 │10 │ (lines 6-10)           │
│  │...│...│...│...│...│                        │
│  └───┴───┴───┴───┴───┘                        │
│  Total Won: $110.00                            │
├─────────────────────────────────────────────────┤
│  [DEAL] button                                  │
└─────────────────────────────────────────────────┘
```

#### 3.3 Key Play Mode Features

1. **Multiplier display**: Show current multipliers for all lines
2. **Payout calculation**: Base win × current multiplier
3. **New multiplier generation**: Update multipliers based on wins
4. **Strategy feedback**: Optional hint showing if multiplier affects decision
5. **Session reset**: All multipliers reset to 1x on app close

### Phase 4: Quiz Mode Implementation

#### 4.1 Quiz Types

1. **Standard Quiz with Multiplier Context**
   - Show hand + "Current multiplier: 3x"
   - Test if user knows the adjusted optimal hold

2. **Multiplier Threshold Quiz**
   - "At what multiplier does the optimal hold change for this hand?"
   - Advanced training for edge cases

3. **Comparison Quiz**
   - Show same hand at 1x and 6x multiplier
   - User identifies which (if any) has different optimal hold

#### 4.2 Quiz Hand Generation

```swift
struct UltimateXQuizHand {
    let hand: Hand
    let multiplier: Int
    let playCount: PlayCount
    let baseOptimalHold: Int
    let adjustedOptimalHold: Int
    let strategyDiffers: Bool  // True when multiplier changes optimal play
}

// Generate quiz hands with mix of:
// - Standard hands (strategy same at any multiplier)
// - Transitional hands (strategy changes at certain multipliers)
// - High-multiplier scenarios (12x, where strategy often differs)
```

---

## Part 4: Technical Implementation Details

### 4.1 File Structure

```
VideoPokerTrainer/
├── Features/
│   └── UltimateX/
│       ├── Models/
│       │   ├── UltimateXState.swift
│       │   ├── MultiplierTable.swift
│       │   └── PlayCount.swift
│       ├── Services/
│       │   ├── UltimateXStrategyService.swift
│       │   └── OutcomeProbabilityCalculator.swift
│       ├── ViewModels/
│       │   ├── UltimateXAnalyzerViewModel.swift
│       │   ├── UltimateXPlayViewModel.swift
│       │   └── UltimateXQuizViewModel.swift
│       └── Views/
│           ├── UltimateXAnalyzerView.swift
│           ├── UltimateXPlayView.swift
│           ├── MultiplierDisplayView.swift
│           └── UltimateXQuizView.swift
```

### 4.2 Calculation Performance

**Concern:** Real-time strategy calculation might be slow.

**Analysis:**
- Current lookup: O(log n) binary search, ~1ms
- With multiplier adjustment: Additional O(32 × outcomes) calculation
- Worst case: 32 holds × ~100 outcomes = 3,200 calculations
- Each calculation: Simple arithmetic
- Expected time: <10ms total

**Optimization if needed:**
- Cache recent calculations (same hand + multiplier)
- Pre-compute outcome probabilities (they're deterministic)
- Use SIMD for parallel EV calculations

### 4.3 Testing Strategy

1. **Unit tests for multiplier math**
   - Verify formula: Adjusted = 2 × Base + Multiplier - 1
   - Test multiplier table lookups

2. **Strategy comparison tests**
   - Compare calculated optimal holds against known Wizard of Odds examples
   - Test documented exception hands at threshold multipliers

3. **Integration tests**
   - Full hand evaluation with multiplier application
   - Multi-line payout calculations

4. **Edge case tests**
   - Multiplier of 1 (should match base strategy exactly)
   - Maximum multiplier (12x)
   - All lines winning simultaneously

---

## Part 5: Implementation Roadmap

### Milestone 1: Core Strategy Engine (1-2 weeks)
- [ ] Implement `OutcomeProbabilityCalculator`
- [ ] Implement `UltimateXStrategyService`
- [ ] Add multiplier tables for all play counts
- [ ] Unit tests for strategy calculations
- [ ] Validate against known examples

### Milestone 2: Analyzer Mode (1 week)
- [ ] Create `UltimateXAnalyzerViewModel`
- [ ] Build analyzer UI with multiplier selector
- [ ] Show side-by-side base vs adjusted strategy
- [ ] Highlight when strategy differs

### Milestone 3: Play Mode (2 weeks)
- [ ] Implement `UltimateXGameState`
- [ ] Create `UltimateXPlayViewModel`
- [ ] Build multiplier display UI
- [ ] Implement multi-line result calculation
- [ ] Add strategy feedback option
- [ ] Session persistence (within app lifecycle)

### Milestone 4: Quiz Mode (1 week)
- [ ] Create quiz hand generator with multiplier context
- [ ] Build quiz UI showing multiplier state
- [ ] Add multiplier-specific quiz types
- [ ] Track performance on transitional hands

### Milestone 5: Polish & Expand (ongoing)
- [ ] Add more base games (DDB, etc.)
- [ ] Performance optimization if needed
- [ ] User documentation/tutorials
- [ ] Sound/haptic feedback for multiplier wins

---

## Part 6: Open Questions & Decisions Needed

### Resolved (based on your input)
- ✅ Use Classic IGT Ultimate X (not Spin/Streak variants)
- ✅ Start with Jacks or Better 9/6
- ✅ Reset multipliers on app close
- ✅ Analyzer mode first
- ✅ 3/5/10 play configurations (not 1 or 100)

### Still Open
1. **Should Ultimate X be a separate tab/mode, or integrated into existing modes?**
   - Option A: Separate "Ultimate X" section with its own Play/Quiz/Analyzer
   - Option B: Toggle within existing modes to enable Ultimate X rules

2. **How to handle existing multi-line in Play mode?**
   - Current app supports 1/5/10/100 lines
   - Ultimate X only supports 3/5/10
   - Disable Ultimate X toggle when incompatible line count selected?

3. **Strategy feedback detail level?**
   - Simple: Just show optimal hold
   - Detailed: Show "Strategy differs from base game because..."

4. **Bankroll tracking with 2x bet?**
   - Ultimate X requires 10 coins/line (2x normal max)
   - Adjust denomination display? Show as separate bet amount?

---

## References

- [Wizard of Odds - Ultimate X Multiplier Tables](https://wizardofodds.com/games/video-poker/tables/ultimate-x/)
- [Wizard of Odds - Ultimate X Strategy](https://wizardofodds.com/games/video-poker/strategy/ultimate-x/bonus-poker/)
- [Wizard of Vegas - Ultimate X Strategy Math Discussion](https://wizardofvegas.com/forum/gambling/video-poker/39936-ultimate-x-strategy-math/)
- [Wizard of Vegas - Optimal Ultimate X Strategies](https://wizardofvegas.com/forum/gambling/video-poker/15348-optimal-ultimate-x-strategies-using-the-full-action-space/)

---

## Appendix A: Multiplier Tables for Other Games

### Double Double Bonus Multipliers

| Hand | 3-Play | 5-Play | 10-Play |
|------|--------|--------|---------|
| Royal Flush | 2 | 2 | 7 |
| Four Aces + 2-4 | 2 | 2 | 2 |
| Four 2-4 + A-4 | 2 | 2 | 2 |
| Four Aces | 2 | 2 | 2 |
| Four 2-4 | 2 | 3 | 3 |
| Four 5-K | 2 | 3 | 3 |
| Straight Flush | 2 | 2 | 7 |
| Full House | 12 | 12 | 12 |
| Flush | 10 | 10 | 10 |
| Straight | 6 | 6 | 6 |
| Three of a Kind | 4 | 4 | 4 |
| Two Pair | 3 | 3 | 3 |
| Jacks or Better | 2 | 2 | 2 |

### Bonus Poker Multipliers

| Hand | 3-Play | 5-Play | 10-Play |
|------|--------|--------|---------|
| Royal Flush | 2 | 2 | 7 |
| Straight Flush | 2 | 2 | 7 |
| Four Aces | 2 | 2 | 2 |
| Four 2-4 | 2 | 3 | 3 |
| Four 5-K | 2 | 3 | 3 |
| Full House | 12 | 12 | 12 |
| Flush | 11 | 11 | 11 |
| Straight | 7 | 7 | 7 |
| Three of a Kind | 4 | 4 | 4 |
| Two Pair | 3 | 3 | 3 |
| Jacks or Better | 2 | 2 | 2 |

(Additional multiplier tables can be added as more games are supported)
