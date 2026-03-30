# WWW Pay Table Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the Rust strategy calculator so WWW (Wild Wild Wild) variants use the correct boosted max-bet pay tables with tiered five-of-a-kind payouts instead of naively reusing base pay table values.

**Architecture:** Add tiered five-of-a-kind fields to the PayTable struct, then replace the current WWW auto-derivation logic with a system that loads the base pay table and applies game-specific overrides sourced from the documented pay tables in `docs/www-pay-tables.md`. Update the WWW hand evaluator to resolve five-of-a-kind payouts by rank tier.

**Tech Stack:** Rust (single file: `scripts/rust_calculator/src/main.rs`)

**Reference:** `docs/www-pay-tables.md` contains all 12 WWW game pay tables with base (1-coin) and max bet (5-coin) values.

---

## File Map

- **Modify:** `scripts/rust_calculator/src/main.rs`
  - Lines 55-90: PayTable struct — add tiered 5oK fields
  - Lines ~190-2314: get_paytable() — add new pay tables, fix SDB four_2_4
  - Lines 2318-2352: WWW construction match arm — call apply_www_overrides
  - Lines 2358-2444: get_all_paytable_ids() — no changes needed (WWW is dynamic)
  - Lines 2943-2980: get_www_quad_payout() — no changes needed
  - Lines 2982-3108: get_www_payout() — update 5oK resolution, add 5 deuces
  - Lines ~3774+: run_tests() — add WWW-specific test cases

---

### Task 1: Add tiered five-of-a-kind fields to PayTable struct

**Files:**
- Modify: `scripts/rust_calculator/src/main.rs:55-90` (struct definition)
- Modify: `scripts/rust_calculator/src/main.rs:190-2314` (all pay table definitions)

- [ ] **Step 1: Add new fields to PayTable struct (after line 86)**

After the existing `five_of_a_kind: Option<f64>,` field, add:

```rust
    // Tiered Five of a Kind payouts (for WWW)
    five_aces: Option<f64>,       // Five Aces
    five_2_4: Option<f64>,        // Five 2s,3s,4s (or 3s,4s,5s for deuces games)
    five_5_k: Option<f64>,        // Five 5s thru Ks (catch-all mid/low tier)
    five_jqk: Option<f64>,        // Five Js,Qs,Ks (SDB, SDDB)
    five_5_10: Option<f64>,       // Five 5s thru 10s (when five_jqk splits the range)
    five_deuces: Option<f64>,     // Five Deuces (4 natural + joker, WWW deuces games)
```

- [ ] **Step 2: Add `five_aces: None, five_2_4: None, five_5_k: None, five_jqk: None, five_5_10: None, five_deuces: None,` to EVERY existing pay table definition**

There are ~120+ pay table definitions in get_paytable(). Each one currently ends with a line like:
```rust
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
```
or with actual values. After each `five_of_a_kind` field, add the six new None fields. For pay tables that already have `five_of_a_kind` values (deuces wild, joker poker, etc.), the new fields are still None.

Use a find-and-replace approach: replace every occurrence of the pattern:
```
five_of_a_kind: None,
            min_pair_rank:
```
with:
```
five_of_a_kind: None,
            five_aces: None, five_2_4: None, five_5_k: None, five_jqk: None, five_5_10: None, five_deuces: None,
            min_pair_rank:
```

And similarly for lines where five_of_a_kind has a `Some(...)` value.

- [ ] **Step 3: Build and verify no compile errors**

Run: `cd scripts/rust_calculator && cargo build --release 2>&1 | tail -5`
Expected: Successful build

- [ ] **Step 4: Run existing tests to verify no regressions**

Run: `cd scripts/rust_calculator && ./target/release/vp_calculator test 2>&1 | tail -5`
Expected: All existing tests pass

---

### Task 2: Add missing base pay tables and fix SDB

**Files:**
- Modify: `scripts/rust_calculator/src/main.rs` (get_paytable function, get_all_paytable_ids function)

- [ ] **Step 1: Fix super-double-bonus-9-5 — set four_2_4 to Some(80.0)**

At line ~931, change:
```rust
four_aces: Some(160.0), four_2_4: None, four_5_k: Some(50.0), four_jqk: Some(120.0),
```
to:
```rust
four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: Some(120.0),
```

Do the same for super-double-bonus-8-5, super-double-bonus-7-5, and super-double-bonus-6-5.

- [ ] **Step 1b: Fix triple-double-bonus-9-7 — set three_of_a_kind to 2.0**

At line ~1146, the base TDB 9-7 has `three_of_a_kind: 3.0` but standard TDB 9-7 pays 2 for 3oK. Change to `three_of_a_kind: 2.0`.

- [ ] **Step 2: Add super-double-double-bonus-8-5 pay table**

Add after the Super Double Bonus section. SDDB has both kicker AND face kicker bonuses. The base (non-WWW) per-coin values from the screenshot's 1-coin column:

```rust
        // ====== SUPER DOUBLE DOUBLE BONUS (SDDB) ======
        "super-double-double-bonus-8-5" => Some(Paytable {
            id: id.to_string(),
            name: "Super Double Double Bonus 8/5".to_string(),
            game_family: GameFamily::SuperDoubleDoubleBonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 8.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: Some(400.0), four_2_4_with_kicker: Some(160.0),
            four_aces_with_face: Some(320.0), four_jqk_with_face: Some(160.0),
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            five_aces: None, five_2_4: None, five_5_k: None, five_jqk: None, five_5_10: None, five_deuces: None,
            min_pair_rank: 9,
        }),
```

- [ ] **Step 3: Add deuces-wild-bonus-9-4 pay table (Bonus Deuces Wild)**

Add after the Deuces Wild section. The base (non-WWW) per-coin values. Note: `four_deuces` covers both "4 Deuces + Ace" (400) and plain "4 Deuces" (200) — the code uses the higher value as a known limitation.

```rust
        // ====== DEUCES WILD BONUS (Bonus Deuces Wild) ======
        "deuces-wild-bonus-9-4" => Some(Paytable {
            id: id.to_string(),
            name: "Deuces Wild Bonus 9/4/4/3".to_string(),
            game_family: GameFamily::DeucesWildBonusPoker,
            royal_flush: 800.0, straight_flush: 9.0, four_of_a_kind: 4.0,
            full_house: 4.0, flush: 3.0, straight: 1.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(400.0), wild_royal: Some(25.0), five_of_a_kind: Some(15.0),
            five_aces: None, five_2_4: None, five_5_k: None, five_jqk: None, five_5_10: None, five_deuces: None,
            min_pair_rank: 0,
        }),
```

- [ ] **Step 4: Add new IDs to get_all_paytable_ids()**

Add `"super-double-double-bonus-8-5"` and `"deuces-wild-bonus-9-4"` to the appropriate sections.

- [ ] **Step 5: Build and run tests**

Run: `cd scripts/rust_calculator && cargo build --release && ./target/release/vp_calculator test 2>&1 | tail -5`
Expected: Build succeeds, all tests pass

---

### Task 3: Implement apply_www_overrides function

**Files:**
- Modify: `scripts/rust_calculator/src/main.rs` (add new function before the WWW match arm around line ~2318)

- [ ] **Step 1: Create the apply_www_overrides function**

Add this function before the `get_paytable` match arm for `www-` IDs. All values are the max-bet per-coin payouts from `docs/www-pay-tables.md` (column 5 ÷ 5). Only fields that DIFFER from the base are overridden.

```rust
/// Apply WWW-specific pay table overrides for the max-bet feature.
/// Values are per-coin max-bet payouts from docs/www-pay-tables.md.
fn apply_www_overrides(base_id: &str, pt: &mut Paytable) {
    // Always set wild royal to natural royal payout
    if pt.wild_royal.is_none() {
        pt.wild_royal = Some(pt.royal_flush);
    }

    match base_id {
        // === JACKS OR BETTER 9-6 ===
        // Boosted: 4oK 25→30, FH 9→11, ST 4→5
        "jacks-or-better-9-6" => {
            pt.four_of_a_kind = 30.0;
            pt.full_house = 11.0;
            pt.straight = 5.0;
            pt.five_aces = Some(800.0);
            pt.five_2_4 = Some(320.0);
            pt.five_5_k = Some(100.0);
            pt.five_of_a_kind = Some(100.0); // fallback
        },

        // === BONUS POKER 8-5 ===
        // Boosted: four_5_k 25→29, FH 8→9, FL 5→6
        "bonus-poker-8-5" => {
            pt.four_5_k = Some(29.0);
            pt.full_house = 9.0;
            pt.flush = 6.0;
            pt.five_aces = Some(800.0);
            pt.five_2_4 = Some(320.0);
            pt.five_5_k = Some(100.0);
            pt.five_of_a_kind = Some(100.0);
        },

        // === BONUS POKER DELUXE 9-6 ===
        // No boosts to standard hands
        "bonus-poker-deluxe-9-6" => {
            pt.five_aces = Some(800.0);
            pt.five_2_4 = Some(320.0);
            pt.five_5_k = Some(100.0);
            pt.five_of_a_kind = Some(100.0);
        },

        // === DOUBLE BONUS 9-7-5 ===
        // No boosts to standard hands
        "double-bonus-9-7-5" => {
            pt.five_aces = Some(800.0);
            pt.five_2_4 = Some(320.0);
            pt.five_5_k = Some(100.0);
            pt.five_of_a_kind = Some(100.0);
        },

        // === DOUBLE DOUBLE BONUS 9-6 ===
        // No boosts to standard hands
        "double-double-bonus-9-6" => {
            pt.five_aces = Some(800.0);
            pt.five_2_4 = Some(320.0);
            pt.five_5_k = Some(100.0);
            pt.five_of_a_kind = Some(100.0);
        },

        // === TRIPLE DOUBLE BONUS 9-7 ===
        // Boosted: 3oK 2→3 (base fix in Task 2 changes base from 3→2)
        "triple-double-bonus-9-7" => {
            pt.three_of_a_kind = 3.0;
            pt.five_aces = Some(800.0);
            pt.five_2_4 = Some(400.0); // TDB unique: higher than standard 320
            pt.five_5_k = Some(100.0);
            pt.five_of_a_kind = Some(100.0);
        },

        // === DEUCES WILD (NSUD / Illinois) ===
        // Boosted: four_deuces 200→250, SF 10→11, 4oK 4→5
        "deuces-wild-nsud" | "deuces-wild-illinois" => {
            pt.four_deuces = Some(250.0);
            pt.straight_flush = 11.0;
            pt.four_of_a_kind = 5.0;
            pt.five_deuces = Some(800.0);
            // 5oK stays at 16 (no boost)
        },

        // === DEUCES WILD BONUS 9/4/4/3 (Bonus Deuces Wild) ===
        // Boosted: four_deuces 400→500, SF 9→12
        // Tiered 5oK: 5 Aces=80, 5 3s-5s=40, 5 6s-Ks=20
        "deuces-wild-bonus-9-4" => {
            pt.four_deuces = Some(500.0);
            pt.straight_flush = 12.0;
            pt.five_deuces = Some(800.0);
            pt.five_aces = Some(80.0);
            pt.five_2_4 = Some(40.0);  // 3s,4s,5s in deuces context
            pt.five_5_k = Some(20.0);  // 6s thru Ks
            pt.five_of_a_kind = Some(20.0); // fallback
        },

        // === SUPER DOUBLE BONUS 9-5 ===
        // No boosts to standard hands; 4-tier 5oK
        "super-double-bonus-9-5" => {
            pt.five_aces = Some(400.0);
            pt.five_jqk = Some(240.0);
            pt.five_2_4 = Some(160.0);
            pt.five_5_10 = Some(100.0);
            pt.five_5_k = Some(100.0); // fallback
            pt.five_of_a_kind = Some(100.0);
        },

        // === SUPER DOUBLE DOUBLE BONUS 8-5 ===
        // No boosts to standard hands; 4-tier 5oK
        "super-double-double-bonus-8-5" => {
            pt.five_aces = Some(800.0);
            pt.five_jqk = Some(640.0);
            pt.five_2_4 = Some(320.0);
            pt.five_5_10 = Some(100.0);
            pt.five_5_k = Some(100.0);
            pt.five_of_a_kind = Some(100.0);
        },

        // === DOUBLE DOUBLE BONUS PLUS 9-6 ===
        // No boosts to standard hands
        "ddb-plus-9-6" => {
            pt.five_aces = Some(800.0);
            pt.five_2_4 = Some(320.0);
            pt.five_5_k = Some(100.0);
            pt.five_of_a_kind = Some(100.0);
        },

        // === SUPER BONUS DEUCES WILD ===
        // Boosted: four_deuces 400→400 (same), 5oK+deuce stays 160, 5oK stays 15
        // No boosts to standard hands
        "super-bonus-deuces-10" | "super-bonus-deuces-9" | "super-bonus-deuces-8" => {
            pt.five_deuces = Some(800.0);
            // five_of_a_kind stays at 160 (5oK with deuce)
            // Plain 5oK (no deuce) = 15, stored as five_5_k fallback
            pt.five_5_k = Some(15.0);
        },

        // Fallback: derive 5oK from best bonus quad payout (existing behavior)
        _ => {
            if pt.five_of_a_kind.is_none() {
                pt.five_of_a_kind = Some(
                    pt.four_aces_with_kicker
                        .or(pt.four_aces)
                        .unwrap_or(pt.four_of_a_kind)
                );
            }
        },
    }
}
```

- [ ] **Step 2: Build to verify the function compiles**

Run: `cd scripts/rust_calculator && cargo build --release 2>&1 | tail -5`
Expected: Successful build

---

### Task 4: Wire up apply_www_overrides in WWW construction

**Files:**
- Modify: `scripts/rust_calculator/src/main.rs:2318-2352` (the `www-` match arm)

- [ ] **Step 1: Replace the existing WWW auto-derivation with apply_www_overrides**

Replace the current code at lines ~2318-2352:

```rust
        id if id.starts_with("www-") => {
            let without_prefix = id.trim_start_matches("www-");
            let base_id = if let Some(pos) = without_prefix.rfind('-') {
                &without_prefix[..pos]
            } else {
                without_prefix
            };

            if let Some(mut pt) = get_paytable(base_id) {
                pt.id = id.to_string();
                pt.name = format!("WWW {}", pt.name);

                // Add Wild Royal if not present (same payout as Natural Royal)
                if pt.wild_royal.is_none() {
                    pt.wild_royal = Some(pt.royal_flush);
                }

                // Add Five of a Kind if not present
                if pt.five_of_a_kind.is_none() {
                    pt.five_of_a_kind = Some(
                        pt.four_aces_with_kicker
                            .or(pt.four_aces)
                            .unwrap_or(pt.four_of_a_kind)
                    );
                }

                Some(pt)
            } else {
                eprintln!("Warning: base paytable '{}' not found for WWW variant '{}'", base_id, id);
                None
            }
        },
```

With:

```rust
        id if id.starts_with("www-") => {
            // Strip "www-" prefix and "-Nw" suffix to get base ID
            let without_prefix = id.trim_start_matches("www-");
            let base_id = if let Some(pos) = without_prefix.rfind('-') {
                &without_prefix[..pos]
            } else {
                without_prefix
            };

            if let Some(mut pt) = get_paytable(base_id) {
                pt.id = id.to_string();
                pt.name = format!("WWW {}", pt.name);
                apply_www_overrides(base_id, &mut pt);
                Some(pt)
            } else {
                eprintln!("Warning: base paytable '{}' not found for WWW variant '{}'", base_id, id);
                None
            }
        },
```

- [ ] **Step 2: Build and run existing tests**

Run: `cd scripts/rust_calculator && cargo build --release && ./target/release/vp_calculator test 2>&1 | tail -5`
Expected: Build succeeds, existing tests pass (no WWW tests exist yet)

---

### Task 5: Update get_www_payout for tiered five-of-a-kind and five deuces

**Files:**
- Modify: `scripts/rust_calculator/src/main.rs` — get_www_payout() function and add helper

- [ ] **Step 1: Add get_www_five_of_a_kind_payout helper function**

Add before get_www_payout():

```rust
/// Resolve tiered five-of-a-kind payout by rank.
/// For deuces games, rank grouping shifts: five_2_4 covers 3s,4s,5s (since 2s are wild).
fn get_www_five_of_a_kind_payout(rank: u8, paytable: &Paytable) -> f64 {
    let is_deuces = paytable.is_deuces_wild();
    let fallback = paytable.five_of_a_kind.unwrap_or(100.0);

    if rank == 12 {
        // Aces
        return paytable.five_aces.unwrap_or(fallback);
    }

    if is_deuces {
        // Deuces games: five_2_4 covers 3s,4s,5s (ranks 1,2,3)
        if rank >= 1 && rank <= 3 {
            return paytable.five_2_4.unwrap_or(fallback);
        }
        // Everything else (6s thru Ks, ranks 4-11)
        return paytable.five_5_k.unwrap_or(fallback);
    }

    // Non-deuces games: five_2_4 covers 2s,3s,4s (ranks 0,1,2)
    if rank <= 2 {
        return paytable.five_2_4.unwrap_or(fallback);
    }

    // Js,Qs,Ks (ranks 9,10,11) — only meaningful for SDB/SDDB
    if rank >= 9 && rank <= 11 {
        return paytable.five_jqk
            .or(paytable.five_5_k)
            .unwrap_or(fallback);
    }

    // 5s thru 10s (ranks 3-8) — or 5s thru Ks if no five_jqk
    if paytable.five_5_10.is_some() && rank >= 3 && rank <= 8 {
        return paytable.five_5_10.unwrap_or(fallback);
    }

    paytable.five_5_k.unwrap_or(fallback)
}
```

- [ ] **Step 2: Update get_www_payout to handle Five Deuces (before Four Deuces check)**

In get_www_payout(), before the existing `if is_deuces_base && num_deuces == 4` check, add:

```rust
    // Five Deuces (4 natural deuces + joker)
    if is_deuces_base && num_deuces == 4 && num_jokers >= 1 {
        if let Some(five_d) = paytable.five_deuces {
            return five_d;
        }
    }
```

This ensures that when all 4 natural deuces are present AND there's at least one joker, it returns the five_deuces payout (800) instead of falling through to four_deuces (250).

- [ ] **Step 3: Replace the flat five_of_a_kind resolution with tiered resolution**

Find the existing Five of a Kind check in get_www_payout():
```rust
    // Five of a Kind
    if max_count + total_wilds >= 5 {
        return paytable.five_of_a_kind.unwrap_or(100.0);
    }
```

Replace with:
```rust
    // Five of a Kind — use tiered payout by rank
    if max_count + total_wilds >= 5 {
        // Find the rank that forms the five-of-a-kind
        let five_rank = counts.iter().enumerate()
            .max_by_key(|(_, &c)| c)
            .map(|(r, _)| r as u8)
            .unwrap_or(0);
        return get_www_five_of_a_kind_payout(five_rank, paytable);
    }
```

- [ ] **Step 4: Build and run tests**

Run: `cd scripts/rust_calculator && cargo build --release && ./target/release/vp_calculator test 2>&1 | tail -5`
Expected: Build succeeds, all tests pass

---

### Task 6: Add WWW-specific test cases

**Files:**
- Modify: `scripts/rust_calculator/src/main.rs` — run_tests() function

- [ ] **Step 1: Add test cases for tiered five-of-a-kind in JoB WWW**

Add to the test cases vector (use `make_hand` with a joker card — rank 13, suit 0 is the convention for joker):

```rust
        // ============= WWW TIERED FIVE OF A KIND =============
        TestCase {
            name: "WWW: Five Aces (Ah Ad Ac As Joker) - JoB",
            hand: make_hand([(12, 0), (12, 1), (12, 2), (12, 3), (255, 0)]),
            tests: vec![
                ("www-jacks-or-better-9-6-1w", 800.0),  // Five Aces = 800
            ],
        },
        TestCase {
            name: "WWW: Five 3s (3h 3d 3c 3s Joker) - JoB",
            hand: make_hand([(1, 0), (1, 1), (1, 2), (1, 3), (255, 0)]),
            tests: vec![
                ("www-jacks-or-better-9-6-1w", 320.0),  // Five 2s-4s = 320
            ],
        },
        TestCase {
            name: "WWW: Five Kings (Kh Kd Kc Ks Joker) - JoB",
            hand: make_hand([(11, 0), (11, 1), (11, 2), (11, 3), (255, 0)]),
            tests: vec![
                ("www-jacks-or-better-9-6-1w", 100.0),  // Five 5s-Ks = 100
            ],
        },
```

- [ ] **Step 2: Add test cases for boosted standard hands**

```rust
        // ============= WWW BOOSTED STANDARD HANDS =============
        TestCase {
            name: "WWW: Four of a Kind (7h 7d 7c 7s 5h) - JoB boosted",
            hand: make_hand([(5, 0), (5, 1), (5, 2), (5, 3), (3, 0)]),
            tests: vec![
                ("www-jacks-or-better-9-6-0w", 30.0),   // 4oK boosted from 25 to 30
            ],
        },
        TestCase {
            name: "WWW: Full House (Ah Ad Ac 5s 5h) - JoB boosted",
            hand: make_hand([(12, 0), (12, 1), (12, 2), (3, 3), (3, 0)]),
            tests: vec![
                ("www-jacks-or-better-9-6-0w", 11.0),   // FH boosted from 9 to 11
            ],
        },
        TestCase {
            name: "WWW: Straight (5h 6d 7c 8s 9h) - JoB boosted",
            hand: make_hand([(3, 0), (4, 1), (5, 2), (6, 3), (7, 0)]),
            tests: vec![
                ("www-jacks-or-better-9-6-0w", 5.0),    // ST boosted from 4 to 5
            ],
        },
```

- [ ] **Step 3: Add test cases for SDB four-tier five-of-a-kind**

```rust
        TestCase {
            name: "WWW: Five Jacks (Jh Jd Jc Js Joker) - SDB 4-tier",
            hand: make_hand([(9, 0), (9, 1), (9, 2), (9, 3), (255, 0)]),
            tests: vec![
                ("www-super-double-bonus-9-5-1w", 240.0), // Five JQK = 240
            ],
        },
        TestCase {
            name: "WWW: Five 7s (7h 7d 7c 7s Joker) - SDB 4-tier",
            hand: make_hand([(5, 0), (5, 1), (5, 2), (5, 3), (255, 0)]),
            tests: vec![
                ("www-super-double-bonus-9-5-1w", 100.0), // Five 5s-10s = 100
            ],
        },
```

- [ ] **Step 4: Add test case for DW five deuces**

```rust
        TestCase {
            name: "WWW: Five Deuces (2h 2d 2c 2s Joker) - DW",
            hand: make_hand([(0, 0), (0, 1), (0, 2), (0, 3), (255, 0)]),
            tests: vec![
                ("www-deuces-wild-nsud-1w", 800.0), // Five Deuces = 800
            ],
        },
```

- [ ] **Step 5: Add test case for TDB unique five_2_4 value**

```rust
        TestCase {
            name: "WWW: Five 4s (4h 4d 4c 4s Joker) - TDB higher tier",
            hand: make_hand([(2, 0), (2, 1), (2, 2), (2, 3), (255, 0)]),
            tests: vec![
                ("www-triple-double-bonus-9-7-1w", 400.0), // TDB Five 2s-4s = 400 (not 320)
                ("www-jacks-or-better-9-6-1w", 320.0),     // JoB Five 2s-4s = 320
            ],
        },
```

- [ ] **Step 6: Build and run all tests**

Run: `cd scripts/rust_calculator && cargo build --release && ./target/release/vp_calculator test 2>&1`
Expected: All tests pass, including new WWW-specific tests

---

## Known Limitations (out of scope)

1. **"4 Deuces + Ace" vs plain "4 Deuces"** — DWB and SBDW have separate payouts for these, but the code uses a single `four_deuces` field. The higher value is used for all 4-deuce hands.
2. **SBDW "5oK + 1 Deuce" vs "5oK"** — SBDW distinguishes 5oK containing a natural deuce (160) from 5oK without (15). Currently uses 160 for all 5oK. The `five_5_k = Some(15.0)` override partially addresses this for 5oK formed entirely from non-deuce naturals + jokers.
3. **DDB Plus "4 5s-Ks w/ Ace kicker"** — DDBP has a special kicker bonus for quads 5-K with an Ace. No struct field exists for this; it falls through to the standard four_5_k payout.
4. **SDDB quad resolution** — SDDB has both low-kicker AND face-kicker bonuses simultaneously. The current get_www_quad_payout() checks kicker bonuses first, which may not correctly resolve 4 Aces w/ J,Q,K to the face kicker payout (320 instead of plain 160).
5. **Unknown wild distributions** — SDB, SDDB, DDBP, and SBDW have correct pay tables but no known wild card distributions, so strategies cannot be generated for them yet.
6. **Pay table variants** — Only one pay table per game is implemented (the one from the screenshots). Other pay table variants (e.g., JoB 9-5, DDB 8-5) would need their own WWW overrides.
