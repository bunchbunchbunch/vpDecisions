# Wild Wild Wild — Redesign Spec

**Date:** 2026-03-27
**Status:** Draft

## Problem

The previous WWW implementation was built on a fundamentally wrong model: it randomly designated dealt card positions as wild (jokers). In reality, WWW adds joker cards to the **deck** before dealing — they probabilistically end up in both the dealt hand and the remaining draw pile.

## Correct Mechanic

1. Player selects WWW variant, bets **10 coins/line** (5 for play + 5 feature fee)
2. Game samples `wildCount` (0–3) from per-family probability distribution
3. `wildCount` joker cards added to the 52-card deck → **52+N card deck**
4. Deck shuffled, 5 cards dealt — some may be jokers
5. Player sees hand + "N Wilds Added" indicator; holds/draws
6. Each line draws from remaining **47+N card deck** (may contain undealt jokers)
7. Final hands evaluated with jokers as universal wilds
8. Payouts from **boosted pay table**, calculated at 5-coin level

## Architecture

### iOS — Card Model

Add `Rank.joker` (rawValue 15) to the existing Rank enum. Joker cards use an arbitrary suit (e.g., `.hearts`) since suit is meaningless for wilds.

```swift
enum Rank: Int, CaseIterable, Codable, Comparable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack = 11, queen, king, ace
    case joker = 15
}
```

New deck factory:

```swift
static func shuffledDeck(jokerCount: Int = 0) -> [Card] {
    var deck = createDeck()
    for _ in 0..<jokerCount {
        deck.append(Card(rank: .joker, suit: .hearts))
    }
    return deck.shuffled()
}
```

`CaseIterable` conformance must exclude `.joker` so standard deck creation is unaffected.

### iOS — PlayVariant

```swift
case wildWildWild

var coinsPerLine: Int {
    case .ultimateX, .wildWildWild: return 10
    case .standard: return 5
}
```

Standard line counts (1, 3, 5, 10). No 100-play for WWW (shared wilds don't make sense with independent decks).

### iOS — PlayViewModel Deal Flow

```swift
func deal() {
    // 1. Sample wild count
    let wildCount = WildWildWildDistribution.sampleWildCount(for: family)
    wwwWildCount = wildCount

    // 2. Create augmented deck
    let deck = Card.shuffledDeck(jokerCount: wildCount)

    // 3. Deal normally — jokers land wherever they land
    dealtCards = Array(deck.prefix(5))
    remainingDeck = Array(deck.dropFirst(5))

    // 4. Count how many jokers ended up in dealt hand (for display)
    wwwJokersInHand = dealtCards.filter { $0.rank == .joker }.count

    // 5. Strategy lookup uses wildCount to pick the right file
    lookupOptimalStrategy()
}
```

Key state:
- `wwwWildCount: Int` — total wilds added to deck (0–3), shown in UI banner
- No `wwwWildIndices` — joker positions are implicit (they're actual Card objects)

### iOS — Hand Evaluation

New evaluator for hands containing jokers (adapted from Rust `get_joker_payout`):

```swift
func evaluateWWWHand(_ cards: [Card]) -> HandEvaluation {
    let numJokers = cards.filter { $0.rank == .joker }.count
    let naturals = cards.filter { $0.rank != .joker }
    // Count ranks of natural cards, check flush/straight with wilds
    // Evaluate: Natural Royal → Five of a Kind → Wild Royal →
    //   Straight Flush → Four of a Kind → Full House → Flush →
    //   Straight → Three of a Kind → Two Pair → High Pair
}
```

This handles both:
- Jokers dealt in the initial hand
- Jokers drawn from the remaining deck
- Both counted together naturally since they're actual Card objects

### iOS — Pay Table

WWW uses a boosted pay table derived from the base game:
- **Five of a Kind** added (payout = best quad payout for that game)
- **Wild Royal Flush** added (payout = standard Royal Flush value)
- Other payouts may have small boosts (TBD — source from Wizard of Odds)
- With 0 wilds, Five of a Kind and Wild Royal are unreachable but still in table

Implementation: `PayTable.wwwBoosted(from:)` factory method that derives the modified table.

### iOS — Strategy Lookup

4 strategy files per base paytable:
- `www-{paytableId}-0w.vpstrat2` — 52-card deck, boosted pay table
- `www-{paytableId}-1w.vpstrat2` — 53-card deck, boosted pay table
- `www-{paytableId}-2w.vpstrat2` — 54-card deck, boosted pay table
- `www-{paytableId}-3w.vpstrat2` — 55-card deck, boosted pay table

Canonical key: natural cards sorted by rank/suit with canonical suit letters + "Ww" per joker.
Always 10 chars (N natural cards × 2 + N jokers × 2 = 5 cards × 2 = 10).

At deal time:
1. Use `wwwWildCount` to select the correct strategy file
2. Generate canonical key from dealt hand (jokers become "Ww")
3. Look up best hold; map canonical indices back to deal order

### iOS — UI

- **Wild count banner**: "2 Wilds Added to Deck!" displayed after deal
- **Joker cards**: Render with existing "1J" image asset
- **Line count**: Standard picker (1, 3, 5, 10) — no "fixed 3" restriction
- **Bet display**: Shows 10-coin per line structure
- **CardView**: Check `card.rank == .joker` instead of external `isWWWWild` flag

### iOS — ActiveHandState Persistence

Track `wwwWildCount` for state restoration. No need for `wwwWildIndices` since jokers are actual cards in the dealt hand that persist naturally through `CardData`.

`CardData` needs to support `Rank.joker` for serialization.

### Rust Calculator — Strategy Generation

**Deck generation**: Extend `generate_canonical_hands(num_jokers: u8)` to produce all unique 5-card hands from a 52+N deck.

**EV calculation**: `calculate_hold_ev` with `deck_size = 52 + num_jokers`. The remaining deck after a hold naturally contains the correct number of undealt jokers.

**Payout evaluation**: Route WWW hands through a `get_www_payout` function that:
- Handles multi-joker (0–3) evaluation
- Preserves base-game bonus quad structure (Four Aces with 2-4 kicker, etc.)
- Uses boosted pay table values

**Pay table derivation** (auto from base):
```rust
id if id.starts_with("www-") => {
    let base = get_paytable(base_id);
    base.wild_royal = Some(base.royal_flush);
    base.five_of_a_kind = Some(best_quad_payout);
    // Additional boosts TBD
}
```

**File generation**: For each supported base paytable × 4 wild counts = 4 VPS2 files.

### Wild Count Distribution

Per-family probabilities (unchanged from previous research):

| Family | 0 wilds | 1 wild | 2 wilds | 3 wilds |
|--------|---------|--------|---------|---------|
| Jacks or Better | 40.0% | 19.0% | 21.0% | 20.0% |
| Deuces Wild | 40.0% | 18.3% | 21.7% | 20.0% |
| Bonus Poker | 35.6% | 10.1% | 44.2% | 10.1% |
| Double Double Bonus | 49.0% | 22.0% | 24.0% | 5.0% |
| Double Bonus | 49.0% | 15.0% | 31.0% | 5.0% |
| Bonus Poker Deluxe | 49.0% | 20.8% | 25.2% | 5.0% |
| Triple Double Bonus | 49.0% | 32.9% | 14.1% | 4.0% |
| Triple Triple Bonus | 49.0% | 33.8% | 16.2% | 1.0% |

## Open Questions

1. **Exact boosted pay table values** — The Rust heuristic (Five of a Kind = best quad, Wild Royal = Royal) is a reasonable starting point. Need to source exact values from Wizard of Odds or game analysis.
2. **0-wild boosted pay table** — Do payouts change even when 0 wilds are added? The ~52% return figure for 0 wilds on 9-6 JoB (≈104% on 5-coin basis vs 99.54% standard) suggests a slight boost. Needs verification.
3. **Bonus quad handling with jokers** — When a joker completes Four Aces, does the kicker bonus apply? The joker acts as the optimal kicker? Need to verify game rules.

## Key Differences from Previous Implementation

| Aspect | Previous (Wrong) | Redesign (Correct) |
|--------|-------------------|---------------------|
| Where wilds go | Random positions in dealt hand | Added to deck before shuffle |
| Deck size | Always 52 | 52 + N (53–55) |
| Wilds in draw pile | No | Yes — can draw jokers |
| Coins per line | 5 | 10 (5 bet + 5 fee) |
| Line count | Fixed at 3 | Standard options (1, 3, 5, 10) |
| Hand evaluation | Deuces-wild evaluator hack | Proper joker evaluator |
| Card representation | Normal cards flagged as wild | Actual joker Card objects |
| Pay table | Unmodified base | Boosted with Five of a Kind, Wild Royal |
