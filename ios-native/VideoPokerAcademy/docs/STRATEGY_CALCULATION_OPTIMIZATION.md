# Video Poker Strategy Calculation Optimization

## Problem Statement

The current Rust-based strategy calculator takes approximately 1 hour to calculate optimal strategy for a custom paytable. This is far too slow for on-device calculation or real-time strategy generation. Tools like WinPoker can calculate strategies for custom paytables in under 30 seconds.

## Current Implementation Analysis

**Location:** `/Users/johnbunch/Dropbox/ClaudePlayground/vpDecisions/scripts/rust_calculator/src/main.rs`

### Current Approach (Brute Force Enumeration)

1. **Generate canonical hands**: 134,459 equivalence classes representing all possible initial 5-card hands
2. **For each canonical hand**:
   - Evaluate all 32 possible hold patterns (bitmasks 0-31)
   - **For each hold pattern**:
     - Build remaining deck (47 cards after removing held cards)
     - **Enumerate ALL possible draws** using `itertools::combinations`
       - Example: Holding 2 cards requires C(47,3) = 16,215 combinations
       - Holding 1 card requires C(47,4) = 178,365 combinations
     - Sum payouts for all draws and divide by total combinations to get EV
3. **Uses parallel processing** with Rayon to analyze batches of hands concurrently

### Performance Bottleneck

The critical bottleneck is the **full enumeration of all draw combinations** for each hold pattern. This means:

- For 134,459 canonical hands × 32 hold patterns = ~4.3 million EV calculations
- Each EV calculation enumerates thousands to hundreds of thousands of draw combinations
- Total: Billions of individual hand evaluations

## Research Findings: Fast Calculation Techniques

### 1. Formula-Based Probability Calculation

**Key Insight from Wizard of Odds:**
> "I don't actually score any hand but use carefully chosen formulas to determine the probability of improving a hand. For example, with any pair and 3 singletons the probability of improving the hand to a two pair is always the same."

**Benefits:**
- Reduces calculation from "over a day" to "about one minute" for Jacks or Better
- Recognizes that identical mathematical scenarios occur repeatedly
- Uses combinatorial formulas instead of enumerating all possibilities

**Example Formula - Pair to Two Pair:**

Instead of enumerating all C(47,3) = 16,215 possible draws when holding a pair, use:
- Number of ways to make two pair = 3 × 2 × 44 / (3 × 2 × 1)
  - 3 remaining cards of the paired rank's mates
  - 2 cards from any other rank to make the second pair
  - 44 remaining cards for the kicker
- Probability = (ways to make two pair) / (total draw combinations)

### 2. Equivalence Class Reduction

**Already Implemented:** The current code uses canonical hands (134,459 classes vs 2,598,960 total hands)

**How it works:**
- Uses suit symmetry: A♠ K♠ Q♠ J♠ 10♠ is equivalent to A♥ K♥ Q♥ J♥ 10♥
- Reduces initial hands by ~19x

**Additional optimization opportunity:**
- The Wizard of Odds further reduces 2.6M hands to 191,659 distinct categories
- Could potentially apply similar grouping to our canonical set

### 3. Inclusion-Exclusion Algorithm with Lookup Tables

**Source:** DurangoBill's Video Poker page

**Key claim:**
> "An 'Inclusion-Exclusion' algorithm that constructs a look-up table would appear to be thousands of times faster than the brute force calculations. The 'Inclusion-Exclusion' algorithm uses a maximum of a couple of hundred addition/subtraction operations instead of trying the millions of draw combinations for each possible initial hand."

**How it works:**
- Pre-compute probabilities for common hand improvement patterns
- Store in lookup tables indexed by hand characteristics
- Use inclusion-exclusion principle to combine overlapping probabilities
- Example: P(straight OR flush) = P(straight) + P(flush) - P(straight flush)

### 4. Pattern Recognition and Categorical Formulas

Different hand patterns can be categorized and calculated with specific formulas:

**High Card / Partial Straights / Partial Flushes:**
- Formula depends on number of high cards, straight gaps, flush cards
- Can be computed combinatorially without enumeration

**Pairs:**
- Pair → Two Pair: Formula based on remaining ranks
- Pair → Three of a Kind: C(2, 2) × C(44, 1)
- Pair → Full House: C(2, 2) × C(3, 2) (for each other rank)
- Pair → Four of a Kind: C(2, 2) × 1

**Two Pair:**
- Two Pair → Full House: Known formula based on remaining cards of each rank

**Three of a Kind:**
- Three of a Kind → Four of a Kind: C(1, 1) × C(46, 1)
- Three of a Kind → Full House: Formula based on pairing any other rank

## Recommended Optimization Strategy

### Phase 1: Implement Formula-Based EV Calculation (Highest Impact)

**Goal:** Replace `itertools::combinations` enumeration with combinatorial formulas

**Implementation approach:**

1. **Categorize hold patterns** into types:
   - High cards only (0-4 high cards)
   - One pair + kickers
   - Two pair + kicker
   - Three of a kind + kickers
   - Straight draws (4-card, 3-card, inside, etc.)
   - Flush draws (4-card, 3-card)
   - Four of a kind + kicker
   - Full house
   - Straight/Flush/Royal patterns

2. **For each category, implement formula-based probability calculation:**

```rust
fn calculate_hold_ev_optimized(hand: &Hand, hold_mask: u8, game_type: GameType) -> f64 {
    let held_cards = extract_held_cards(hand, hold_mask);
    let hand_pattern = classify_hold_pattern(&held_cards);

    match hand_pattern {
        HoldPattern::OnePair { pair_rank, kickers } => {
            calculate_pair_ev(pair_rank, kickers, game_type)
        }
        HoldPattern::TwoPair { high_pair, low_pair, kicker } => {
            calculate_two_pair_ev(high_pair, low_pair, kicker, game_type)
        }
        HoldPattern::ThreeOfKind { rank, kickers } => {
            calculate_trips_ev(rank, kickers, game_type)
        }
        HoldPattern::FourCardFlush { cards } => {
            calculate_flush_draw_ev(cards, game_type)
        }
        HoldPattern::FourCardStraight { cards, inside } => {
            calculate_straight_draw_ev(cards, inside, game_type)
        }
        // ... etc for all patterns
    }
}

fn calculate_pair_ev(pair_rank: u8, kickers: Vec<Card>, game_type: GameType) -> f64 {
    let num_to_draw = 5 - 2 - kickers.len();
    let deck_size = 47 - kickers.len();

    // Calculate probability of each outcome using formulas

    // Four of a kind: 2 remaining cards of the pair rank, 1 kicker
    let prob_quads = if num_to_draw >= 2 {
        (2.0 / deck_size as f64) * ((deck_size - 1) as f64 / (deck_size - 1) as f64)
    } else {
        0.0
    };

    // Full house: 2 remaining of pair rank + 2 of any other rank
    let prob_full_house = calculate_full_house_from_pair(pair_rank, deck_size, num_to_draw);

    // Three of a kind: 2 remaining of pair rank + non-matching cards
    let prob_trips = calculate_trips_from_pair(pair_rank, deck_size, num_to_draw);

    // Two pair: 1 remaining of pair rank + 2 of another rank OR 2 cards from two different ranks
    let prob_two_pair = calculate_two_pair_from_pair(pair_rank, deck_size, num_to_draw);

    // Sum expected values
    let mut ev = 0.0;
    ev += prob_quads * get_payout_for_hand_type(HandType::FourOfKind, game_type);
    ev += prob_full_house * get_payout_for_hand_type(HandType::FullHouse, game_type);
    ev += prob_trips * get_payout_for_hand_type(HandType::ThreeOfKind, game_type);
    ev += prob_two_pair * get_payout_for_hand_type(HandType::TwoPair, game_type);

    // Add high pair vs low pair distinction for Jacks or Better variants
    if is_high_pair(pair_rank, game_type) {
        ev += (1.0 - prob_quads - prob_full_house - prob_trips - prob_two_pair)
              * get_payout_for_hand_type(HandType::JacksOrBetter, game_type);
    }

    ev
}
```

**Expected speedup:** 100-1000x (based on Wizard of Odds achieving "over a day" → "one minute")

### Phase 2: Build Lookup Tables for Common Scenarios

**Goal:** Pre-compute and cache probabilities for frequently-occurring patterns

**Implementation:**
1. Create static lookup tables for:
   - Straight draw probabilities (by gap pattern and number of draws)
   - Flush draw probabilities (by suited cards held and number of draws)
   - High card combinations (by number and ranks)

2. Index tables by relevant characteristics:
   ```rust
   struct StraightDrawLookup {
       // Index: [gap_pattern][num_draws] -> probability
       probabilities: HashMap<(u8, u8), f64>
   }

   struct FlushDrawLookup {
       // Index: [suited_cards][num_draws] -> probability
       probabilities: HashMap<(u8, u8), f64>
   }
   ```

**Expected additional speedup:** 2-5x

### Phase 3: Optimize Canonical Hand Generation

**Goal:** Reduce the number of distinct hands to analyze

**Current:** 134,459 canonical hands
**Target:** ~191,659 distinct categories (or fewer with better grouping)

**Approach:**
- Group hands by strategic equivalence, not just suit symmetry
- Example: Any "high card with 2-gap straight draw + 3-flush" has same strategy regardless of specific cards

**Expected speedup:** 1.5-2x

### Phase 4: Parallel Processing Optimization

**Current:** Using Rayon for batch processing
**Enhancement:** Optimize chunk sizes and load balancing based on hand complexity

**Expected speedup:** 1.2-1.5x (already mostly parallelized)

## Overall Expected Performance Improvement

**Conservative estimate:**
- Phase 1: 100x speedup
- Phase 2: 3x additional speedup
- Phase 3: 1.5x additional speedup
- **Total: ~450x faster**
- **1 hour → ~8 seconds**

**Optimistic estimate:**
- Phase 1: 500x speedup (matching "thousands of times faster" claim for Inclusion-Exclusion)
- Phase 2: 5x additional speedup
- Phase 3: 2x additional speedup
- **Total: ~5000x faster**
- **1 hour → <1 second**

## Feasibility of On-Device Calculation

With these optimizations:
- **Current:** 1 hour on desktop computer
- **Optimized:** 1-10 seconds on desktop computer
- **On iPhone:** 2-30 seconds (assuming 3-5x slower than desktop for single-threaded, but with multi-core can be similar)

**Conclusion:** On-device calculation for custom paytables becomes **feasible** with formula-based approach.

## Implementation Priority

1. **Start with Phase 1** - Implement formula-based calculation for most common hold patterns:
   - Pairs (most common)
   - High cards
   - Three of a kind
   - Two pair
   - Four-card flush/straight draws

2. **Validate accuracy** - Compare results against current brute-force implementation for sample hands

3. **Measure performance** - Profile to confirm expected speedups

4. **Expand coverage** - Add formulas for remaining patterns

5. **Build lookup tables** - Phase 2 for additional optimization

## References

- Wizard of Odds - Video Poker Probability: https://wizardofodds.com/ask-the-wizard/video-poker/probability/
- DurangoBill's Video Poker: http://www.durangobill.com/VideoPoker.html
- Wizard of Odds - Programming Video Poker Code: https://wizardofodds.com/article/programming-video-poker-code/
- Ethier, S.N. "The Doctrine of Chances" Chapter 17 - Video Poker (academic reference for mathematical foundations)
