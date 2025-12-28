# Formula-Based Video Poker Calculator Implementation Notes

## Goal
Implement a formula-based approach for calculating optimal video poker strategy for Jacks or Better 9/6 that is:
1. **100% accurate** - matches brute force enumeration exactly (within floating point precision)
2. **Significantly faster** - targeting 100-1000x speedup
3. **Fully validated** - tested against all canonical hands

## Approach

### Phase 1: Establish Correct Baseline ✓
- Built infrastructure with both brute-force and formula-based methods
- Currently: Both use enumeration to ensure 100% matching
- Running: Full validation on all 204,087 canonical hands

### Phase 2: Implement Formula-Based Calculations (In Progress)

The key insight: Many hand patterns have probabilities that can be calculated combinatorially without full enumeration.

#### Strategy: Hybrid Approach

Given the complexity of video poker (flushes, straights, royals), use a hybrid approach:

1. **Full Enumeration for Complex Patterns** (small % of cases):
   - 4-card straight flush draws
   - 4-card royal flush draws
   - Complex straight/flush interactions
   - Any pattern where formula logic would be error-prone

2. **Formula-Based for Common Patterns** (majority of cases):
   - Pairs (most common hold)
   - Two pair
   - Three of a kind
   - High cards with no flush/straight potential
   - Simple draws

#### Key Formulas by Pattern

##### Holding a Pair (e.g., 5♥5♦) + Drawing 3 Cards

Total draws: C(47,3) = 16,215

Outcomes to calculate:
1. **Four of a Kind**: Need both remaining cards of pair rank + any other
   - Ways: 2 × 45 = 90 (2 remaining 5s, choose 2, then any of 45 others... wait, need all 3 cards)
   - Actually: C(2,2) × C(45,1) = 1 × 45 = 45 ways
   - Probability: 45 / 16,215

2. **Full House**: Need 1 of pair + 2 of another rank
   - For each other rank: C(2,1) × C(cards_of_that_rank, 2)
   - Sum over all other ranks in deck
   - Complex: depends on which cards from original hand

3. **Three of a Kind**: Need 1 of pair + 2 non-matching
   - Ways: C(2,1) × (C(45,2) - ways_to_make_two_pair_or_full_house)
   - Or enumerate directly

4. **Two Pair**: Need 2 of one other rank + 1 non-matching
   - For each other rank: C(cards_of_that_rank, 2) × C(other_cards, 1)

**Challenge**: The exact number of cards available for each rank depends on the original hand composition.

##### Holding Two Pair (e.g., 5♥5♦ 6♥6♦) + Drawing 1 Card

Total draws: 47

Much simpler:
1. **Four of a Kind**: Draw one of 4 remaining cards of either pair rank
2. **Full House**: Draw one of 4 remaining cards of either pair rank
   Wait, if we have 5-5-6-6, full house needs: one more 5 or one more 6
   - Ways: 2 + 2 = 4 (2 remaining 5s + 2 remaining 6s)
3. **Nothing improved**: All other 43 cards

##### Holding Three of a Kind (e.g., 5♥5♦5♠) + Drawing 2 Cards

Total draws: C(47,2) = 1,081

1. **Four of a Kind**: Draw the last card of trips rank + any other
   - Ways: 1 × 46 = 46

2. **Full House**: Draw 2 of same rank (pair)
   - For each other rank: C(cards_of_that_rank, 2)
   - Sum over 12 other ranks

### Phase 3: Incremental Implementation & Validation

For each formula implemented:
1. Code the formula
2. Test on specific test hands
3. Run against larger subset of canonical hands
4. Fix any discrepancies
5. Move to next pattern

### Phase 4: Performance Optimization

Once all formulas are correct:
1. Profile to identify remaining bottlenecks
2. Add caching for repeated calculations
3. Optimize combinatorial functions
4. Benchmark final speedup

## Current Status

- **Baseline validator running**: Validating that enumeration-based approach is 100% correct
- **Next**: Implement formula for pair + 3 draw (most common case)
- **Target**: Each formula must match brute force within 1e-9 (floating point precision)

## Testing Strategy

1. **Unit tests**: Individual formulas tested on known hands
2. **Integration tests**: Full hand evaluation tested on sample hands
3. **Exhaustive validation**: All canonical hands tested
4. **Performance benchmarks**: Compare speed against brute force

## Notes

- Jacks or Better 9/6 Payouts:
  - Royal Flush: 800
  - Straight Flush: 50
  - Four of a Kind: 25
  - Full House: 9
  - Flush: 6
  - Straight: 4
  - Three of a Kind: 3
  - Two Pair: 2
  - Jacks or Better: 1
  - Nothing: 0

- Canonical hands: 204,087 (suit-symmetric equivalence classes)
- Total evaluations for full validation: 204,087 × 32 = 6,530,784
