# Video Poker Variants Research

This document covers **game overlay variants** — modifications applied on top of a standard base game. It is separate from `GAME_FAMILIES.md`, which covers base game pay table families (JoB, DDB, Deuces Wild, etc.).

The central question for each variant: **does it change optimal strategy?**

---

## Popularity Ranking (Type A + B Combined)

Rankings reflect casino floor presence and player recognition based on industry sources. Type C (fundamentally different base games) excluded.

| Rank | Variant | Type | Why |
|------|---------|------|-----|
| 1 | **Multi-Hand (Triple/Five/Ten Play)** | A | The dominant casino video poker format; virtually every machine is multi-hand |
| 2 | **Super Times Pay** | A | IGT's longest-running multiplier game; described as "one of the most popular of all time" and a "durable favorite" |
| 3 | **Ultimate X** | B | IGT calls it "without a doubt, the world's most popular video poker game"; main driver of play on multi-game cabinets |
| 4 | **Spin Poker** | A | Called a "monster hit" by IGT; spawned the Spin Poker Deluxe (20-line) expansion |
| 5 | **Hot Roll Poker** | A | Popular since 2014 introduction; dice-roll multiplier mechanic; spawned Super Hot Roll variant |
| 6 | **Standard Progressives** | A | Ubiquitous as an add-on layer; progressive meter on top of any base game |
| 7 | **Wild Wild Wild** | B | Moderate floor presence; well-known among serious video poker players; limited distribution in some regions |
| 8 | **Super Times Pay Hot Roll** | A | Combination of the two most popular Type A overlays; growing floor presence |
| 9 | **Dream Card Poker** | B | IGT's newer push (2018+); "attracting a broad demographic" per IGT; wild card in dealt hand |
| 10 | **Ultimate X Bonus Streak** | B | Extension of Ultimate X with multi-hand streak multipliers; targeted at existing UX players |
| 11 | **Double Super Times Pay** | A | Next evolution of Super Times Pay with two simultaneous multipliers |
| 12 | **Bonus Streak (standalone)** | A | Moderate floor presence; simpler streak bonus without UX multiplier complexity |
| 13 | **Quick Quads** | A | "Fiercely devout following" but never a broad hit; scattered U.S. placements |
| 14 | **Shockwave Poker** | B | Konami product; less common than IGT; accumulating multiplier resets on win |
| 15 | **Wheel Poker / Lucky Bonus Spin** | A | Found in some casinos; prize wheel bonus for certain hands |

### Tier summary

| Tier | Rank | Description |
|------|------|-------------|
| **Ubiquitous** | 1–2 | Found at virtually every casino with video poker |
| **Very Common** | 3–6 | Found at most major casinos; player recognition is near-universal |
| **Common** | 7–10 | Found at many casinos; well-known among regular video poker players |
| **Moderate** | 11–15 | Found in some casinos; niche appeal or regional distribution |

---

## Classification Framework

| Category | Definition | App implication |
|----------|------------|-----------------|
| **A — No strategy change** | Overlay applies equally to all hold outcomes; base game EV ordering is preserved | No new strategy needed; reuse existing strategy files |
| **B — Strategy-affecting overlay** | Overlay changes the EV of specific hold options differently; optimal hold can change | New strategy calculation or lookup required per overlay state |
| **C — Fundamentally different base game** | Different deck, wild card rules, or hand rankings | Separate strategy files; already partially covered in GAME_FAMILIES.md |

### Why multipliers alone don't change strategy (Category A)

When a fixed multiplier M applies to all outcomes equally:

```
Hold A: EV_A × M  vs.  Hold B: EV_B × M
```

Since M is a positive constant, the ordering (EV_A > EV_B) is unchanged. Optimal hold is identical to the base game.

This reasoning breaks down the moment M is **outcome-dependent** (Category B), because different holds yield different distributions of outcomes and therefore different expected multiplier values.

---

## Category A — No Strategy Change

### Super Times Pay
**Manufacturer:** IGT
**Base game:** Any standard game (most commonly JoB, DDB)
**Mechanism:** Costs 2× the normal max bet. At deal time, a random multiplier is revealed before you see your cards: 1×, 2×, 4×, 8×, or 10×. After draw, payout = base payout × multiplier.
**Why no strategy change:** The multiplier is revealed before holds but applies equally to all possible outcomes of any hold decision. M × EV_A vs M × EV_B — M cancels.
**Return (9/6 JoB base):** ~99.79% (the extra bet cost is approximately offset by the expected multiplier value)
**Casino prevalence:** Extremely common. One of the most widely installed IGT games.
**Notes:**
- The 2× bet requirement effectively doubles stakes while keeping return percentage similar
- Some casinos offer "Super Times Pay Hot Roll" — same mechanic, but the multiplier is revealed via an animated dice roll. Still no strategy change.

---

### Super Times Pay Hot Roll
**Manufacturer:** IGT
**Mechanism:** Same as Super Times Pay, but multiplier is determined by rolling virtual dice. Dice result is visible before holds.
**Why no strategy change:** Same as Super Times Pay — the multiplier applies to all outcomes equally, regardless of which cards you hold.
**Notes:** The dice animation makes the multiplier feel more "active" but the math is identical.

---

### Spin Poker
**Manufacturer:** IGT
**Mechanism:** Multi-hand variant (typically 3, 5, or 9 simultaneous hands). All hands share the initial 5-card deal and the same hold decisions. Each hand draws independently from its own deck.
**Why no strategy change:** You make one set of hold decisions that applies identically across all lines. The independent draws don't affect which cards to hold — strategy is identical to single-line play on the base game.
**Return:** Same as underlying base game
**Casino prevalence:** Very common
**Notes:** Not to be confused with Wild Wild Wild, which is also Triple Play but adds wild cards.

---

### Triple Play / Five Play / Ten Play / Fifty Play / Hundred Play
**Manufacturer:** IGT and others
**Mechanism:** Same as Spin Poker — multiple independent hands sharing one deal and one set of hold decisions.
**Why no strategy change:** Identical reasoning to Spin Poker.
**Return:** Same as underlying base game
**Casino prevalence:** Ubiquitous. Multi-line is the dominant video poker format in modern casinos.
**Notes:**
- 100-play has very high short-term variance
- The app already supports 1/5/10/100 line counts; strategy is already unified with single-line

---

### Streak Poker / Bonus Streak
**Manufacturer:** Various
**Mechanism:** Bonus credits awarded for winning multiple consecutive hands. The streak bonus is a flat reward independent of what hand type you win.
**Why no strategy change:** The streak bonus does not discriminate between hold options. Whether you hold a pair or a 4-card flush, the probability of *winning something* changes, but the bonus amount is fixed per consecutive win count. The EV ordering of hold options is unchanged.
**Return:** Slightly above base game (bonus streak EV is additive)
**Casino prevalence:** Moderate

---

### Lucky Bonus Spin / Wheel Poker
**Manufacturer:** Various
**Mechanism:** Certain winning hands award a bonus spin on a prize wheel. Wheel outcome is random.
**Why no strategy change:** The wheel bonus is triggered by winning a hand, not by which specific cards you held. Hold decisions don't affect wheel probability or outcome.
**Casino prevalence:** Moderate
**Notes:** Some variants award the spin for specific hands (e.g., "four of a kind earns a spin"), which is a flat bonus on top of the four-of-a-kind payout — still doesn't affect strategy.

---

### Standard Progressives
**Manufacturer:** Various
**Mechanism:** Royal flush jackpot accumulates until hit. Jackpot is displayed on a meter.
**Why (usually) no strategy change:** At typical jackpot levels, the base pay table strategy is optimal. The royal flush is already factored into EV at its base payout; incremental jackpot value rarely changes which cards to hold.
**Exception:** At very large jackpots (roughly 3× the normal royal flush payout or higher), holding 4-card royal flush draws over made hands can become correct. This threshold depends on the base game.
**Casino prevalence:** Ubiquitous
**Notes:** For app purposes, standard progressive play is treated as the base game strategy unless jackpot tracking is implemented.

---

### Quick Quads
**Manufacturer:** IGT
**Mechanism:** Bonus payout when four-of-a-kind is made from specific card combinations (e.g., 4 aces dealt pat). Flat bonus on top of normal four-of-a-kind payout.
**Why no strategy change:** The bonus is applied to completed hands. Hold decisions that lead to four-of-a-kind are already favored in standard strategy; the bonus is additive on a hand type that's already well-optimized.
**Impact:** Negligible strategy difference at most

---

## Category B — Strategy-Affecting Overlays

### Wild Wild Wild
**Manufacturer:** IGT
**Base game:** Triple Play (3 hands, shared deal)
**Mechanism:** After the initial 5-card deal, the game randomly awards 0, 1, 2, or 3 wild cards that are **substituted into the existing hand** (replacing dealt cards with wilds). The wilds appear on all 3 lines simultaneously. Wild cards substitute for any card.
**Why strategy changes:** The wild cards are real cards in your evaluated hand. A hand with a wild is a fundamentally different hand requiring its own optimal evaluation. The optimal hold for `A♠ A♦ K♣ 7♥ [W]` differs from `A♠ A♦ K♣ 7♥ 3♠`.

**Strategy rules by wild count:**
- **0 wilds:** Standard base game strategy (typically 9/6 JoB)
- **1 wild:** Must evaluate the hand treating the wild as whatever card maximizes the best hold. E.g., a wild + 4 unpaired cards might make a wild royal flush draw more valuable than anything else.
- **2 wilds:** Two wilds guarantee at least three-of-a-kind. Optimal holds focus on improving to straight flush, four-of-a-kind, or royal flush.
- **3 wilds:** Three wilds guarantee at least four-of-a-kind. Hold decisions focus on completing a wild royal flush or five-of-a-kind.

**Wild probability distribution (from Wizard of Odds analysis):**

| Base Game | 0 wilds | 1 wild | 2 wilds | 3 wilds | Avg. trigger frequency |
|-----------|---------|--------|---------|---------|------------------------|
| 9/6 Jacks or Better | 40% | 19% | 21% | 20% | Every 1.67 hands |
| Bonus Poker | ~40% | ~19% | ~21% | ~20% | Every 1.67 hands |
| Deuces Wild / DDB | higher | lower | lower | lower | Every 1.96 hands |

Key observation: the distribution is surprisingly uniform — when wilds trigger, 1, 2, and 3 wilds are roughly equally likely. Nearly **60% of hands** involve at least one wild on JoB 9/6. This is far more frequent than most players expect.

*(Additional data being collected in `wild_wild_wild_stats.md`.)*

**Return:** Varies by configuration; typically 97–100%+ depending on base pay table
**Casino prevalence:** Common; major casino staple
**Implementation complexity:** High — requires strategy evaluation for each (wild count, hand) combination. With 0 wilds, use existing strategy files. With 1–3 wilds, need either new strategy files or on-the-fly hand evaluation incorporating wild substitution.

---

### Ultimate X
**Manufacturer:** IGT
**Mechanism:** Multi-hand game (3/5/10 play). Winning hands award multipliers (2×–12×) that apply to the **next hand** on that specific line. Costs 2× normal max bet.
**Why strategy changes:** The current hand's hold decision determines the probability distribution of winning hand types, which determines the expected multiplier for the *next* hand. This means current hold decisions have downstream EV implications beyond the immediate payout.

**The key math:**
```
Adjusted EV = 2 × (Base EV) + (Multiplier) − 1
```

When a multiplier > 1 is active: EVs scale up, and relative ordering can shift (e.g., a sure two-pair is worth more with a 12× multiplier than a risky straight flush draw).
When multiplier = 1: strategy is identical to base game (formula collapses to 2 × Base EV − 0 = same ordering).

**Status:** Already modeled (`UltimateXModels.swift`, `UltimateXStrategyService.swift`). Implementation plan in `docs/ULTIMATE_X_IMPLEMENTATION_PLAN.md`.
**Casino prevalence:** Very common; one of the most popular multi-hand variants

---

### Dream Card Poker
**Manufacturer:** IGT
**Mechanism:** For a 10-credit wager (vs. standard 5), the game randomly deals 4 regular cards and 1 "Dream Card" — a wild card that substitutes for any card. When the feature does not trigger, all 5 cards are standard.
**Why strategy changes:** When the Dream Card is present, it is part of your actual 5-card hand. The optimal hold with a wild card in position N differs from the same 4 base cards without it. Identical reasoning to Wild Wild Wild with exactly 1 wild.
**Return:** Exceeds 99% with optimal play
**Casino prevalence:** Growing; IGT actively promoting as of 2018–present
**Implementation complexity:** Medium — two strategies needed: standard base game (no wild) and 1-wild strategy. Simpler than Wild Wild Wild because wild count is always 0 or 1.

---

### Ultimate X Bonus Streak
**Manufacturer:** IGT
**Mechanism:** Extension of Ultimate X. When players double the wager to 10 credits, winning hands award multipliers (2×, 3×, or 4×) that apply to a **random number of consecutive subsequent hands** rather than just one.
**Why strategy changes:** Same as Ultimate X — current hold decisions affect the probability of winning (which triggers multiplier), which affects future EV. The multi-hand streak duration adds additional complexity but the core logic mirrors Ultimate X.
**Return:** Exceeds 99% with optimal play
**Casino prevalence:** Growing; positioned as an upgrade path for Ultimate X players
**Implementation complexity:** Medium-High — requires tracking streak duration per line in addition to multiplier value

---

### Double Super Times Pay
**Manufacturer:** IGT
**Mechanism:** Seven-credit bet activates two simultaneous random multipliers per hand. Both multipliers apply to the final payout.
**Why no strategy change:** Both multipliers apply equally to all possible outcomes of any hold decision. Same M₁×M₂ cancellation logic as single Super Times Pay.
**Return:** Similar to Super Times Pay (~99%+ on full-pay base games)
**Casino prevalence:** Moderate; positioned as a higher-variance evolution of Super Times Pay

---

### Shockwave Poker
**Manufacturer:** Konami
**Mechanism:** A multiplier accumulates by 1× each hand you don't win. When you win a hand, the accumulated multiplier applies to that payout and resets to 1×.
**Why strategy changes:** When the accumulated multiplier is high, the expected value of winning *anything* (even a low pair) increases dramatically. This can shift strategy toward more conservative holds (a guaranteed pair over a risky draw) when the multiplier is large.
**Return:** Depends on configuration
**Casino prevalence:** Moderate; less common than IGT products
**Implementation complexity:** Medium — multiplier state is simple (integer), but strategy adjustment requires real-time EV recalculation for each multiplier level

---

### Wild Card Poker (Random Wild Rank)
**Mechanism:** At the start of each hand, a random card rank is declared wild for that hand (e.g., "6s are wild this hand").
**Why strategy changes:** The wild rank changes the effective hand composition. Holding a 6 (or cards that draw to a wild-assisted hand) has different EV when 6s are wild vs. a different rank.
**Casino prevalence:** Less common; seen in some video poker-adjacent machines
**Implementation complexity:** High — essentially a new strategy evaluation for each possible wild rank designation

---

## Category C — Fundamentally Different Base Games

These are not overlays on a standard 52-card game. They belong in `GAME_FAMILIES.md` for strategy file purposes, but are included here for completeness.

### Joker Wild (Joker Poker)
**Deck:** 53 cards (52 standard + 1 joker)
**Wild card:** Joker is fully wild
**Strategy impact:** Completely different. Five-of-a-kind is a hand (beats royal flush). Different minimum qualifying hand depending on variant (Kings or Better vs. Two Pair or Better).
**Common pay tables:** Kings or Better (~100.64%), Two Pair or Better (~99.92%)
**Casino prevalence:** Common, declining in newer casinos

---

### Double Joker Wild
**Deck:** 54 cards (52 + 2 jokers)
**Wild cards:** Both jokers
**Strategy impact:** Different again from single-joker games; more wilds → different hand frequency distributions
**Casino prevalence:** Less common

---

### Sevens Wild
**Deck:** 52 cards
**Wild cards:** All four 7s
**Strategy impact:** Functionally similar to Deuces Wild (4 wild cards), but 7s are a mid-rank card rather than lowest rank. Different probability distributions for straights and flushes incorporating wild 7s.
**Casino prevalence:** Rare in modern casinos

---

### One-Eyed Jacks Wild
**Deck:** 52 cards
**Wild cards:** J♠ and J♥ (the "one-eyed" jacks) — 2 wild cards
**Strategy impact:** Only 2 wilds (vs. 4 in Deuces/Sevens). Strategy differs significantly from non-wild games; wild jacks can substitute for missing straight/flush cards.
**Casino prevalence:** Rare; historically found in home games

---

### Tens Wild / Aces Wild
**Deck:** 52 cards
**Wild cards:** All four 10s or all four aces
**Strategy impact:** Varies by which rank is wild. Aces wild is unusual because aces are also high-value non-wild cards in normal games.
**Casino prevalence:** Rare

---

## Summary Table

| Rank | Variant | Category | Strategy Change | Prevalence | App Priority |
|------|---------|----------|-----------------|------------|--------------|
| 1 | Triple/Five/Ten Play | A | No | ★★★★★ | Done |
| 2 | Super Times Pay | A | No | ★★★★★ | High (teach/explain) |
| 3 | **Ultimate X** | **B** | **Yes** | **★★★★★** | **In Progress** |
| 4 | Spin Poker | A | No | ★★★★★ | Low (multi-line already handled) |
| 5 | Hot Roll Poker | A | No | ★★★★ | Medium |
| 6 | Standard Progressive | A | No (usually) | ★★★★★ | Low |
| 7 | **Wild Wild Wild** | **B** | **Yes** | **★★★★** | **High** |
| 8 | Super Times Pay Hot Roll | A | No | ★★★★ | Medium |
| 9 | **Dream Card Poker** | **B** | **Yes** | **★★★** | **Medium** |
| 10 | **Ultimate X Bonus Streak** | **B** | **Yes** | **★★★** | **Medium** |
| 11 | Double Super Times Pay | A | No | ★★★ | Low |
| 12 | Bonus Streak (standalone) | A | No | ★★★ | Low |
| 13 | Quick Quads | A | Negligible | ★★★ | Low |
| 14 | **Shockwave Poker** | **B** | **Yes** | **★★** | **Low** |
| 15 | Wild Card Poker | B | Yes | ★★ | Low |
| 16 | Wheel Poker / Lucky Bonus Spin | A | No | ★★ | Low |

---

## Implementation Notes

### Category A variants
No new strategy files needed. The app can display correct information about these variants (explain the mechanic, show that base game strategy applies) without any strategy changes. These are good candidates for informational content in Training mode.

### Wild Wild Wild (priority Category B)
The app already supports Triple Play (3-line). The key work:
1. **0 wilds (40% of hands)**: Use existing base game strategy file (no change)
2. **1–3 wilds (60% of hands)**: Need either pre-computed strategy files per (wild_count, hand) or an on-the-fly wild card evaluator that substitutes the wild optimally

Pre-computed files are the simpler approach given the existing binary strategy store architecture. Three additional strategy variants per base game (1-wild, 2-wild, 3-wild). Each is still a standard strategy evaluation — just computed with wild substitution logic in the Rust generator.

### Dream Card Poker (Category B)
Simpler than Wild Wild Wild — only two states: 0 wilds (standard strategy) or 1 wild (wild-in-hand strategy). The 1-wild strategy file for Wild Wild Wild would be directly reusable here. Implementing Wild Wild Wild first effectively covers Dream Card Poker for free.

### Ultimate X (in progress)
Real-time EV adjustment approach already designed. See `ULTIMATE_X_IMPLEMENTATION_PLAN.md`.

### Joker Wild (Category C)
Requires 53-card deck support in the hand evaluator. The hand evaluator currently assumes 52 cards. This is a non-trivial change to `HandEvaluator.swift`.

---

## References

- [Wizard of Odds — Super Times Pay](https://wizardofodds.com/games/video-poker/super-times-pay/)
- [Wizard of Odds — Wild Wild Wild](https://wizardofodds.com/games/video-poker/wild-wild-wild/)
- [Wizard of Odds — Ultimate X](https://wizardofodds.com/games/video-poker/tables/ultimate-x/)
- [Wizard of Odds — Joker Wild](https://wizardofodds.com/games/video-poker/joker-wild/)
- [Video Poker for Winners — Variant Overview](https://www.videopokerforwinners.com/)
- Internal: `docs/ULTIMATE_X_IMPLEMENTATION_PLAN.md`
- Internal: `wild_wild_wild_stats.md` (in-progress wild distribution data collection)
