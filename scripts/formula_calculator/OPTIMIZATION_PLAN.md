# Video Poker Formula Optimization Plan

## Strategy: Incremental Formula Implementation

Rather than trying to formula-ize everything at once, implement and validate formulas incrementally, starting with the simplest cases.

## Priority Order (Simplest → Most Complex)

### Level 1: Trivial Cases (0 enumeration needed)
- [ ] **Hold all 5 cards**: Just return payout of the hand (no drawing)
- [ ] **Hold nothing**: Could pre-compute or use formula for expected value of random 5-card hand

### Level 2: Simple Made Hands (minimal enumeration)
- [ ] **Holding 4 of a kind + kicker**: Only draws 1 card
  - Can easily enumerate 47 possibilities
  - Or use formula: probability of each final hand type

- [ ] **Holding Full House**: Drawing 1 card
  - 47 possibilities, easy to enumerate or formula

- [ ] **Holding Flush/Straight**: Drawing 1 card
  - 47 possibilities

### Level 3: Common Drawing Hands (can optimize)
- [ ] **Holding a Pair**: Draw 3 cards (16,215 combinations)
  - **HIGH IMPACT** - most common hold in Jacks or Better
  - Formula for:
    - Four of a kind probability
    - Full house probability
    - Three of a kind probability
    - Two pair probability
  - Challenge: Exact probabilities depend on deck composition

- [ ] **Holding Two Pair**: Draw 1 card (47 combinations)
  - Simple enumeration or formula

- [ ] **Holding Three of a Kind**: Draw 2 cards (1,081 combinations)
  - Formula for quads, full house, trips

### Level 4: Drawing Hands (medium complexity)
- [ ] **Holding 4-card Flush** (not straight flush):
  - Draw 1 card (47 possibilities)
  - Simple: count suited cards in deck

- [ ] **Holding 4-card Straight** (not flush):
  - Draw 1 card
  - Count cards that complete straight

- [ ] **Holding 3-card combinations**:
  - Various patterns
  - May still enumerate C(47,2) = 1,081

### Level 5: Complex Cases (keep enumeration)
- [ ] **4-card Straight Flush draw**: Too complex, keep enumeration
- [ ] **4-card Royal draw**: Critical hand, keep enumeration for accuracy
- [ ] **Complex partial straights/flushes**: Keep enumeration

## Implementation Approach

For each level:
1. Identify the pattern
2. Implement formula OR optimized enumeration
3. Create test cases
4. Validate against brute force on:
   - Specific test hands
   - 100 random canonical hands
   - 1,000 random canonical hands
   - All canonical hands with that pattern
5. Fix any discrepancies
6. Move to next level

## Expected Speedup by Level

- Level 1: Instant (0 vs millions of operations)
- Level 2: 100-1000x faster (47 vs millions)
- Level 3: 10-100x faster (formulas vs 16K combinations)
- Level 4: 10-50x faster
- Level 5: Same speed (keep enumeration for correctness)

## Overall Strategy

**Goal**: Achieve significant speedup on COMMON cases while maintaining 100% accuracy

**Approach**: Hybrid system
- Use formulas where we can guarantee accuracy
- Use enumeration for complex edge cases
- Prioritize optimizing frequent patterns (pairs, high cards)

## Validation Philosophy

- **Correctness > Speed**: If in doubt, enumerate
- **Test thoroughly**: Each formula must match brute force exactly
- **Incremental validation**: Test each pattern type separately

##Current Focus

Starting with **Level 3: Holding a Pair** since it's the most common and highest impact case.

### Holding a Pair - Detailed Formula Plan

When holding a pair (e.g., 5♥5♦) and discarding 3 cards:

**Setup:**
- Held: 2 cards of rank R
- Deck: 47 cards total
  - 2 more cards of rank R
  - 45 cards of other ranks (distributed across 12 ranks)
- Draw: 3 cards from deck
- Total possible draws: C(47,3) = 16,215

**Outcomes (must be mutually exclusive and exhaustive):**

1. **Four of a Kind**
   - Need: 2 more of rank R + any 3rd card
   - Ways: C(2,2) × C(45,1) = 1 × 45 = 45
   - EV contribution: (45/16215) × 25

2. **Full House**
   - Need: 1 more of rank R + 2 of another rank S
   - For each other rank S in deck:
     - If 4 cards of rank S in deck: C(1,1) × C(4,2) = 1 × 6 = 6
     - If 3 cards of rank S in deck: C(1,1) × C(3,2) = 1 × 3 = 3
   - Must account for which cards were in original hand!
   - This is where it gets tricky...

Actually, this reveals the core challenge: **We need exact deck composition, which depends on the original hand.**

### Revised Approach: Precompute Deck Composition

For each hold pattern:
1. Build exact deck composition (which ranks/suits available)
2. Use formulas based on that specific composition
3. Cache common compositions if helpful

This is still a "formula" approach because we're not enumerating all draw combinations - we're calculating probabilities based on known deck state.

## Next Steps

1. Implement pair-holding formula with exact deck tracking
2. Validate on test hands
3. Expand to other patterns
4. Full validation once confident
