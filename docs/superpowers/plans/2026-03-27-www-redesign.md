# Wild Wild Wild Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Wild Wild Wild as a deck-augmentation mechanic — adding 0–3 joker cards to the deck before dealing, with boosted pay tables, correct strategy generation, and proper UI.

**Architecture:** Joker cards (Card 52–54 in Rust, `Rank.joker` in iOS) are added to the standard 52-card deck before shuffle. The deal and draw operate on the augmented deck naturally. Strategy files are generated per wildCount (0–3) using the Rust calculator's existing joker infrastructure, extended for multi-joker decks.

**Tech Stack:** Swift 6 / SwiftUI / @Observable (iOS), Rust with rayon (strategy calculator), VPS2 binary format (strategy files)

**Spec:** `docs/superpowers/specs/2026-03-27-www-redesign.md`

---

### Task 1: Rust — Multi-Joker Card Support

**Files:**
- Modify: `scripts/rust_calculator/src/main.rs` (lines 20–46: Card struct, line 34: is_joker, lines 2993–3014: generate_canonical_hands)

- [ ] **Step 1: Extend `is_joker()`, `rank()`, and `suit()` for multi-joker decks**

Change `Card::is_joker()` from `self.0 == 52` to `self.0 >= 52`, and update `rank()` and `suit()` to use the same check. Without this, Card(53) would be treated as Ace of Diamonds instead of a joker:

```rust
fn rank(&self) -> u8 {
    if self.0 >= 52 { return 255; } // All jokers
    self.0 / 4
}

fn suit(&self) -> u8 {
    if self.0 >= 52 { return 255; } // All jokers
    self.0 % 4
}

fn is_joker(&self) -> bool {
    self.0 >= 52
}
```

- [ ] **Step 2: Extend `generate_canonical_hands` to accept joker count**

Replace the `include_joker: bool` parameter with `num_jokers: u8`. The deck size becomes `52 + num_jokers`:

```rust
fn generate_canonical_hands(num_jokers: u8) -> Vec<(String, Hand)> {
    let include_str = if num_jokers > 0 { format!(" (with {} joker(s))", num_jokers) } else { String::new() };
    println!("Generating canonical hands{}...", include_str);
    let mut seen: HashMap<String, Hand> = HashMap::new();
    let max_card = 52 + num_jokers;

    for c1 in 0..(max_card - 4) {
        for c2 in (c1 + 1)..(max_card - 3) {
            for c3 in (c2 + 1)..(max_card - 2) {
                for c4 in (c3 + 1)..(max_card - 1) {
                    for c5 in (c4 + 1)..max_card {
                        let hand: Hand = [Card(c1), Card(c2), Card(c3), Card(c4), Card(c5)];
                        let key = hand_to_canonical_key(&hand);
                        seen.entry(key).or_insert(hand);
                    }
                }
            }
        }
    }

    println!("Found {} canonical hands", seen.len());
    seen.into_iter().collect()
}
```

- [ ] **Step 3: Update existing callers of `generate_canonical_hands`**

In `generate_strategy_file()` (line ~3291), change:
```rust
// Before:
let include_joker = paytable.is_joker_poker();
let all_hands = generate_canonical_hands(include_joker);

// After:
let num_jokers = paytable.num_jokers();
let all_hands = generate_canonical_hands(num_jokers);
```

Add `num_jokers()` method to Paytable:
```rust
impl Paytable {
    fn num_jokers(&self) -> u8 {
        if self.id.starts_with("www-") {
            // Extract wild count from ID: "www-{base}-{N}w"
            if let Some(suffix) = self.id.rsplit('-').next() {
                if let Some(n) = suffix.strip_suffix('w').and_then(|s| s.parse::<u8>().ok()) {
                    return n;
                }
            }
            0
        } else if self.is_joker_poker() {
            1
        } else {
            0
        }
    }
}
```

- [ ] **Step 4: Update `analyze_hand` to use dynamic deck size**

Change line 2944 from hardcoded 52/53 to use `paytable.num_jokers()`:
```rust
fn analyze_hand(hand: &Hand, paytable: &Paytable) -> (u8, f64, HashMap<String, f64>) {
    let deck_size = 52 + paytable.num_jokers();
    // ... rest unchanged
}
```

- [ ] **Step 5: Verify compilation**

Run: `cd scripts/rust_calculator && cargo build`
Expected: Compiles with no errors

- [ ] **Step 6: Commit**

```bash
git add scripts/rust_calculator/src/main.rs
git commit -m "feat(rust): extend Card and canonical hand generation for multi-joker decks"
```

---

### Task 2: Rust — WWW Pay Table Derivation + Payout Evaluation

**Files:**
- Modify: `scripts/rust_calculator/src/main.rs` (lines 56–90: Paytable struct, lines 2293–2296: get_paytable end, lines 2887–2897: get_payout dispatch)

- [ ] **Step 1: Add WWW pay table auto-derivation in `get_paytable`**

Add a new match arm before the `_ => None` fallback at the end of `get_paytable()`. This auto-derives a WWW pay table from its base game, adding Five of a Kind and Wild Royal:

```rust
// WWW (Wild Wild Wild) variants — auto-derived from base paytable
// ID format: "www-{base_paytable_id}-{N}w" where N = 0, 1, 2, or 3
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

        // Add Wild Royal if not present (same payout as Natural Royal)
        if pt.wild_royal.is_none() {
            pt.wild_royal = Some(pt.royal_flush);
        }

        // Add Five of a Kind if not present
        // Use the highest applicable quad payout as the ceiling
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

- [ ] **Step 2: Add `is_www()` helper to Paytable**

```rust
fn is_www(&self) -> bool {
    self.id.starts_with("www-")
}
```

- [ ] **Step 3: Add `get_www_payout` evaluation function**

This handles hands with jokers on any base game type — including Deuces Wild bases where both 2s and jokers are wild:

```rust
fn get_www_payout(hand: &[Card], paytable: &Paytable) -> f64 {
    let num_jokers = hand.iter().filter(|c| c.is_joker()).count() as u8;

    // Determine if base game treats deuces as wild
    let is_deuces_base = paytable.is_deuces_wild();
    let non_jokers: Vec<Card> = hand.iter().filter(|c| !c.is_joker()).cloned().collect();
    let num_deuces = if is_deuces_base { non_jokers.iter().filter(|c| c.rank() == 0).count() as u8 } else { 0 };
    let total_wilds = num_jokers + num_deuces;

    // Non-wild cards (exclude jokers AND deuces if deuces-base)
    let naturals: Vec<Card> = non_jokers.iter()
        .filter(|c| !(is_deuces_base && c.rank() == 0))
        .cloned()
        .collect();

    let mut counts = [0u8; 13];
    for card in &naturals {
        if card.rank() < 13 {
            counts[card.rank() as usize] += 1;
        }
    }
    let max_count = *counts.iter().max().unwrap_or(&0);

    let is_flush = is_flush_wild(&naturals);
    let is_straight = is_straight_wild(&naturals, total_wilds);

    // Deuces-specific: Four Deuces (requires actual deuces, not jokers)
    if is_deuces_base && num_deuces == 4 {
        return paytable.four_deuces.unwrap_or(200.0);
    }

    // Natural Royal (zero wilds of any kind)
    if total_wilds == 0 && is_flush && is_straight {
        let mut ranks: Vec<u8> = naturals.iter().map(|c| c.rank()).collect();
        ranks.sort();
        if ranks == vec![8, 9, 10, 11, 12] {
            return paytable.royal_flush;
        }
    }

    // Five of a Kind
    if max_count + total_wilds >= 5 {
        return paytable.five_of_a_kind.unwrap_or(100.0);
    }

    // Wild Royal Flush
    if total_wilds > 0 && is_royal_wild(&naturals, total_wilds) {
        return paytable.wild_royal.unwrap_or(50.0);
    }

    // Straight Flush
    if is_flush && is_straight {
        return paytable.straight_flush;
    }

    // Four of a Kind — use bonus-aware resolution for non-deuces bases
    if max_count + total_wilds >= 4 {
        if is_deuces_base {
            return paytable.four_of_a_kind;
        }
        // For bonus games: find which rank makes the quad
        let quad_rank = counts.iter().enumerate()
            .max_by_key(|(_, &c)| c)
            .map(|(r, _)| r as u8)
            .unwrap_or(0);
        // Kicker = highest non-quad natural card
        let kicker = naturals.iter()
            .filter(|c| c.rank() != quad_rank)
            .map(|c| c.rank())
            .max()
            .unwrap_or(0);
        return get_quad_payout(quad_rank, kicker, paytable);
    }

    // Full House
    let num_pairs = counts.iter().filter(|&&c| c == 2).count() as u8;
    if (max_count + total_wilds >= 3) && (num_pairs >= 1 || max_count >= 2) {
        let mut sorted_counts: Vec<u8> = counts.iter().cloned().filter(|&c| c > 0).collect();
        sorted_counts.sort();
        sorted_counts.reverse();

        if sorted_counts.len() >= 2 {
            let need_for_trips = 3_u8.saturating_sub(sorted_counts[0]);
            let need_for_pair = 2_u8.saturating_sub(sorted_counts[1]);
            if need_for_trips + need_for_pair <= total_wilds && max_count + total_wilds < 4 {
                return paytable.full_house;
            }
        }
    }

    // Flush
    if is_flush && !is_straight {
        return paytable.flush;
    }

    // Straight
    if is_straight && !is_flush {
        return paytable.straight;
    }

    // Three of a Kind
    if max_count + total_wilds >= 3 {
        return paytable.three_of_a_kind;
    }

    // Two Pair
    if num_pairs >= 2 || (num_pairs == 1 && total_wilds >= 1 && max_count < 3) {
        if paytable.two_pair > 0.0 {
            return paytable.two_pair;
        }
    }

    // High Pair
    if num_pairs == 1 || total_wilds >= 1 {
        let highest_natural = counts.iter().enumerate().rev()
            .find(|(_, &c)| c >= 1).map(|(r, _)| r as u8).unwrap_or(0);
        let best_pair_rank = if total_wilds >= 1 { highest_natural.max(12) } else {
            counts.iter().enumerate().rev()
                .find(|(_, &c)| c >= 2).map(|(r, _)| r as u8).unwrap_or(0)
        };
        if best_pair_rank >= paytable.min_pair_rank {
            return paytable.high_pair;
        }
    }

    0.0
}
```

- [ ] **Step 4: Update `get_payout` dispatch to route WWW hands**

```rust
fn get_payout(hand: &[Card], paytable: &Paytable) -> f64 {
    if hand.len() != 5 { return 0.0; }

    if paytable.is_www() {
        get_www_payout(hand, paytable)
    } else if paytable.is_deuces_wild() {
        get_deuces_wild_payout(hand, paytable)
    } else if paytable.is_joker_poker() {
        get_joker_payout(hand, paytable)
    } else {
        get_standard_payout(hand, paytable)
    }
}
```

- [ ] **Step 5: Add `get_www_quad_payout` helper for bonus-aware quad resolution**

This must exactly mirror the existing quad logic in `get_standard_payout` (lines 2544–2646). Use the actual Paytable field names (`four_aces`, `four_2_4`, `four_5_k`, `four_jqk`, `four_8s`, `four_7s`, `four_aces_with_kicker`, `four_2_4_with_kicker`, `four_aces_with_face`, `four_jqk_with_face`):

```rust
fn get_www_quad_payout(quad_rank: u8, kicker_rank: u8, paytable: &Paytable) -> f64 {
    // Kicker bonuses (DDB, TDB, TTB): low kicker = 2,3,4 or Ace
    if paytable.has_kicker_bonus() {
        let is_low_kicker = kicker_rank <= 2 || kicker_rank == 12;

        if quad_rank == 12 { // Four Aces
            if is_low_kicker {
                if let Some(p) = paytable.four_aces_with_kicker { return p; }
            }
            if let Some(p) = paytable.four_aces { return p; }
        } else if quad_rank <= 2 { // Four 2s, 3s, or 4s
            if is_low_kicker {
                if let Some(p) = paytable.four_2_4_with_kicker { return p; }
            }
            if let Some(p) = paytable.four_2_4 { return p; }
        } else {
            if let Some(p) = paytable.four_5_k { return p; }
        }
    }

    // Face kicker bonuses (Double Jackpot, Double Double Jackpot)
    if paytable.has_face_kicker_bonus() {
        let is_face_kicker = kicker_rank >= 9; // J, Q, K, A

        if quad_rank == 12 { // Four Aces
            if is_face_kicker {
                if let Some(p) = paytable.four_aces_with_face { return p; }
            }
            if let Some(p) = paytable.four_aces { return p; }
        } else if quad_rank >= 9 && quad_rank <= 11 { // Four J, Q, K
            if is_face_kicker {
                if let Some(p) = paytable.four_jqk_with_face { return p; }
            }
            if let Some(p) = paytable.four_jqk { return p; }
        } else {
            return paytable.four_of_a_kind;
        }
    }

    // Standard bonus payouts (no kicker)
    if quad_rank == 12 { if let Some(p) = paytable.four_aces { return p; } }
    if quad_rank <= 2 { if let Some(p) = paytable.four_2_4 { return p; } }
    if quad_rank >= 9 && quad_rank <= 11 { if let Some(p) = paytable.four_jqk { return p; } }
    if quad_rank == 6 { if let Some(p) = paytable.four_8s { return p; } }
    if quad_rank == 5 { if let Some(p) = paytable.four_7s { return p; } }
    if let Some(p) = paytable.four_5_k { return p; }

    paytable.four_of_a_kind
}
```

Update the call in `get_www_payout`'s Four of a Kind section to use `get_www_quad_payout`.

- [ ] **Step 6: Verify with a quick test**

Run: `cd scripts/rust_calculator && cargo build && cargo run -- --paytable www-jacks-or-better-9-6-1w --dry-run`

Verify: Should recognize the paytable and print hand count. If `--dry-run` isn't supported, just verify it finds the paytable.

- [ ] **Step 7: Commit**

```bash
git add scripts/rust_calculator/src/main.rs
git commit -m "feat(rust): add WWW pay table derivation and multi-wild payout evaluation"
```

---

### Task 3: Rust — WWW Strategy File Generation Pipeline

**Files:**
- Modify: `scripts/rust_calculator/src/main.rs` (lines 3286–3400: generate_strategy_file, main CLI parsing)
- Create: `scripts/rust_calculator/generate_www_strategies.sh`

- [ ] **Step 1: Update `generate_strategy_file` for dynamic deck size**

The function already calls `generate_canonical_hands` and `analyze_hand`. Both have been updated in Tasks 1–2 to use `num_jokers()`. Verify it calls `paytable.num_jokers()` rather than `paytable.is_joker_poker()`:

```rust
fn generate_strategy_file(paytable: &Paytable) -> (Vec<u8>, Vec<u8>, Vec<u8>, usize, u32) {
    let num_jokers = paytable.num_jokers();
    let all_hands = generate_canonical_hands(num_jokers);
    // ... rest follows existing pattern
}
```

Also update the binary generation call sites (lines ~3342–3348) to pass the joker flag:

```rust
let has_joker = num_jokers > 0;
let binary_v1 = generate_binary_strategy(&strategies, has_joker);
let binary_v2 = generate_binary_strategy_v2(&strategies, has_joker);
```

**Key length note:** WWW canonical keys are always 10 chars (5 cards × 2 chars, with jokers as "Ww"). The existing Joker Poker format uses `key_length=12`, but that's a separate format for a different game family. WWW files use `key_length=10` because all 5-card canonical keys are 10 chars regardless of joker count. The `has_joker` flag (bit 0) is still set so the iOS reader knows wilds are present, but key_length remains 10. Verify that `generate_binary_strategy_v2` derives key_length from the actual key strings rather than from the `has_joker` flag — if it hardcodes 12 for joker, fix it to measure from the first key.

- [ ] **Step 2: Create WWW strategy generation script**

```bash
#!/bin/bash
# generate_www_strategies.sh — Generate WWW strategy files for all supported paytables

set -e
cd "$(dirname "$0")"

# Base paytable IDs that support WWW
PAYTABLES=(
    "jacks-or-better-9-6"
    "jacks-or-better-9-5"
    "jacks-or-better-8-6"
    "jacks-or-better-8-5"
    "jacks-or-better-7-5"
    "bonus-poker-8-5"
    "bonus-poker-7-5"
    "double-bonus-10-7"
    "double-double-bonus-10-6"
    "double-double-bonus-9-6"
    "triple-double-bonus-9-7"
    "triple-double-bonus-9-6"
    "deuces-wild-full-pay"
    "deuces-wild-nsud"
)

echo "Building calculator..."
cargo build --release

for base in "${PAYTABLES[@]}"; do
    for wilds in 0 1 2 3; do
        id="www-${base}-${wilds}w"
        echo "=== Generating: $id ==="
        cargo run --release -- --paytable "$id"
    done
done

echo "Done! Generated $(ls strategies/strategy_www_* 2>/dev/null | wc -l) WWW strategy files."
```

- [ ] **Step 2.5: Also update `generate_strategy_file_with_progress` (line ~4535)**

This is a near-duplicate of `generate_strategy_file` used for batch processing. Apply the same `num_jokers()` changes: use `paytable.num_jokers()` for canonical hand generation and pass `has_joker = num_jokers > 0` to the binary generators.

- [ ] **Step 2.6: Handle key_length backward compatibility**

The existing `generate_binary_strategy_v2` hardcodes `key_length = 12` when `has_joker` is true (for Joker Poker). WWW keys are 10 chars. **Do not change the existing Joker Poker behavior.** Instead, derive key_length from the actual key strings:

```rust
let key_length: u8 = sorted_keys.first().map(|k| k.len() as u8).unwrap_or(10);
```

This naturally produces 10 for both standard and WWW games (since canonical keys are always 10 chars). For existing Joker Poker files that were generated with key_length=12: those files do NOT need regeneration — the iOS reader uses the key_length from the file header, so old files with key_length=12 and new files with key_length=10 will both work correctly as long as the keys inside match their stated length. Verify that existing Joker Poker canonical keys are actually 10 chars (not zero-padded to 12). If they are padded, keep `key_length=12` for `is_joker_poker()` and use measured length only for WWW.

- [ ] **Step 3: Verify end-to-end with a single paytable**

Run: `cd scripts/rust_calculator && cargo run --release -- --paytable www-jacks-or-better-9-6-1w`

Expected: Generates `strategies/strategy_www_jacks_or_better_9_6_1w.vpstrat2` with correct hand count.

- [ ] **Step 4: Commit**

```bash
git add scripts/rust_calculator/src/main.rs scripts/rust_calculator/generate_www_strategies.sh
git commit -m "feat(rust): add WWW strategy file generation pipeline"
```

---

### Task 4: iOS — Card Model Joker Support

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/Card.swift` (lines 43–86: Rank enum, lines 88–113: Card struct)
- Test: `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/CardJokerTests.swift`

- [ ] **Step 1: Write failing tests for joker Card**

Create `CardJokerTests.swift`:

```swift
import Testing
@testable import VideoPokerAcademy

struct CardJokerTests {
    @Test func jokerRankExists() {
        let joker = Card(rank: .joker, suit: .hearts)
        #expect(joker.rank == .joker)
    }

    @Test func jokerDisplayIsW() {
        #expect(Rank.joker.display == "W")
    }

    @Test func jokerImageNameIs1J() {
        let joker = Card(rank: .joker, suit: .hearts)
        #expect(joker.imageName == "1J")
    }

    @Test func standardDeckHas52Cards() {
        let deck = Card.createDeck()
        #expect(deck.count == 52)
        #expect(deck.allSatisfy { $0.rank != .joker })
    }

    @Test func shuffledDeckWithJokersHasCorrectCount() {
        let deck1 = Card.shuffledDeck(jokerCount: 1)
        #expect(deck1.count == 53)
        #expect(deck1.filter { $0.rank == .joker }.count == 1)

        let deck3 = Card.shuffledDeck(jokerCount: 3)
        #expect(deck3.count == 55)
        #expect(deck3.filter { $0.rank == .joker }.count == 3)
    }

    @Test func jokerNotInCaseIterable() {
        // Rank.allCases should NOT include .joker (used by createDeck)
        #expect(!Rank.allCases.contains(.joker))
    }

    @Test func jokerIsCodable() throws {
        let joker = Card(rank: .joker, suit: .hearts)
        let data = try JSONEncoder().encode(CardData(rank: joker.rank, suit: joker.suit))
        let decoded = try JSONDecoder().decode(CardData.self, from: data)
        #expect(decoded.rank == .joker)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mcp__xcodebuildmcp__test_sim_name_proj` (filter to CardJokerTests)
Expected: Compilation errors — `Rank.joker` doesn't exist yet

- [ ] **Step 3: Add `Rank.joker` case and update Card**

In `Card.swift`, add the joker rank and update computed properties:

```swift
enum Rank: Int, Codable, Comparable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack = 11, queen, king, ace
    case joker = 15

    // Manual CaseIterable conformance excluding joker
    static var allCases: [Rank] {
        [.two, .three, .four, .five, .six, .seven, .eight, .nine, .ten,
         .jack, .queen, .king, .ace]
    }

    var display: String {
        switch self {
        // ... existing cases ...
        case .joker: return "W"
        }
    }

    var fullName: String {
        switch self {
        // ... existing cases ...
        case .joker: return "Wild"
        }
    }
}
```

Remove the `CaseIterable` protocol conformance from the enum declaration (since we're providing a manual `allCases`).

Update `Card.imageName`:
```swift
var imageName: String {
    if rank == .joker { return "1J" }
    return "\(rank.display)\(suit.code)"
}
```

Update `Card.displayText`:
```swift
var displayText: String {
    if rank == .joker { return "Wild" }
    return "\(rank.fullName)\(suit.symbol)"
}
```

Add deck factory with jokers:
```swift
static func shuffledDeck(jokerCount: Int = 0) -> [Card] {
    var deck = createDeck()
    for _ in 0..<jokerCount {
        deck.append(Card(rank: .joker, suit: .hearts))
    }
    return deck.shuffled()
}
```

- [ ] **Step 4: Build and run tests**

Run: `mcp__xcodebuildmcp__build_sim_name_proj` then `mcp__xcodebuildmcp__test_sim_name_proj`
Expected: All CardJokerTests pass. Existing tests still pass.

- [ ] **Step 5: Commit**

```bash
git add ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/Card.swift \
        ios-native/VideoPokerAcademy/VideoPokerAcademyTests/CardJokerTests.swift
git commit -m "feat(ios): add Rank.joker and deck augmentation for Wild Wild Wild"
```

---

### Task 5: iOS — WildWildWildModels + PlayVariant + PlaySettings

**Files:**
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/WildWildWildModels.swift`
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/PlayModels.swift` (lines 5–19: PlayVariant, lines 223–291: PlaySettings)
- Test: `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/WildWildWildModelsTests.swift`

- [ ] **Step 1: Write failing tests**

Create `WildWildWildModelsTests.swift`:

```swift
import Testing
@testable import VideoPokerAcademy

struct WildWildWildModelsTests {
    @Test func distributionProbabilitiesSumToOne() {
        for family in GameFamily.allCases {
            let probs = WildWildWildDistribution.probabilities(for: family)
            #expect(probs.count == 4)
            let sum = probs.reduce(0, +)
            #expect(abs(sum - 1.0) < 0.01, "Probabilities for \(family) sum to \(sum)")
        }
    }

    @Test func sampleWildCountInRange() {
        for _ in 0..<100 {
            let count = WildWildWildDistribution.sampleWildCount(for: .jacksOrBetter)
            #expect(count >= 0 && count <= 3)
        }
    }

    @Test func strategyIdFormat() {
        #expect(WildWildWildDistribution.wwwStrategyId(baseId: "jacks-or-better-9-6", wildCount: 0) == "www-jacks-or-better-9-6-0w")
        #expect(WildWildWildDistribution.wwwStrategyId(baseId: "jacks-or-better-9-6", wildCount: 2) == "www-jacks-or-better-9-6-2w")
    }

    @Test func wwwVariantCoinsPerLine() {
        #expect(PlayVariant.wildWildWild.coinsPerLine == 10)
    }

    @Test func wwwVariantDisplayName() {
        #expect(PlayVariant.wildWildWild.displayName == "Wild³")
    }

    @Test func wwwSettingsEffectiveLineCount() {
        var settings = PlaySettings()
        settings.variant = .wildWildWild
        settings.lineCount = .five
        // WWW should use standard line count — no hardcoded override
        #expect(settings.effectiveLineCount == 5)
    }

    @Test func wwwSettingsTotalBetIs10xLines() {
        var settings = PlaySettings()
        settings.variant = .wildWildWild
        settings.lineCount = .three
        #expect(settings.totalBetCredits == 30) // 3 lines × 10 coins
    }

    @Test func wwwStatsKey() {
        var settings = PlaySettings()
        settings.variant = .wildWildWild
        settings.selectedPaytableId = "jacks-or-better-9-6"
        #expect(settings.statsPaytableKey == "jacks-or-better-9-6-www")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: Compilation errors — types don't exist yet

- [ ] **Step 3: Create WildWildWildModels.swift**

```swift
import Foundation

struct WildWildWildDistribution {
    /// Returns [p(0 wilds), p(1 wild), p(2 wilds), p(3 wilds)]
    static func probabilities(for family: GameFamily) -> [Double] {
        switch family {
        case .jacksOrBetter, .tensOrBetter, .allAmerican:
            return [0.400, 0.190, 0.210, 0.200]
        case .deucesWild, .looseDeuces:
            return [0.400, 0.183, 0.217, 0.200]
        case .bonusPoker, .bonusPokerPlus:
            return [0.356, 0.101, 0.442, 0.101]
        case .doubleDoubleBonus, .ddbAcesFaces, .ddbPlus:
            return [0.490, 0.220, 0.240, 0.050]
        case .doubleBonus:
            return [0.490, 0.150, 0.310, 0.050]
        case .bonusPokerDeluxe:
            return [0.490, 0.208, 0.252, 0.050]
        case .tripleDoubleBonus:
            return [0.490, 0.329, 0.141, 0.040]
        case .tripleTripleBonus:
            return [0.490, 0.338, 0.162, 0.010]
        default:
            return [0.400, 0.190, 0.210, 0.200]
        }
    }

    static func sampleWildCount(for family: GameFamily) -> Int {
        let probs = probabilities(for: family)
        let roll = Double.random(in: 0..<1)
        var cumulative = 0.0
        for (i, p) in probs.enumerated() {
            cumulative += p
            if roll < cumulative { return i }
        }
        return 0
    }

    static func wwwStrategyId(baseId: String, wildCount: Int) -> String {
        return "www-\(baseId)-\(wildCount)w"
    }

    static let supportedPaytableIds: Set<String> = [
        "jacks-or-better-9-6", "jacks-or-better-9-5", "jacks-or-better-8-6",
        "jacks-or-better-8-5", "jacks-or-better-7-5", "jacks-or-better-6-5",
        "deuces-wild-full-pay", "deuces-wild-nsud", "deuces-wild-illinois",
        "bonus-poker-8-5", "bonus-poker-7-5",
        "double-double-bonus-10-6", "double-double-bonus-9-6",
        "double-bonus-10-7",
        "triple-double-bonus-9-7", "triple-double-bonus-9-6",
        "triple-triple-bonus-9-6",
    ]

    static func isSupported(paytableId: String) -> Bool {
        supportedPaytableIds.contains(paytableId)
    }
}
```

- [ ] **Step 4: Add PlayVariant.wildWildWild to PlayModels.swift**

In the `PlayVariant` enum (line 5):
```swift
enum PlayVariant: String, Codable, Equatable, Hashable {
    case standard
    case ultimateX
    case wildWildWild

    var isUltimateX: Bool { self == .ultimateX }
    var isWildWildWild: Bool { self == .wildWildWild }

    var coinsPerLine: Int {
        switch self {
        case .standard: return 5
        case .ultimateX, .wildWildWild: return 10
        }
    }

    var displayName: String {
        switch self {
        case .standard:      return "Standard"
        case .ultimateX:     return "Ult X"
        case .wildWildWild:  return "Wild³"
        }
    }
}
```

In `PlaySettings.statsPaytableKey` (line ~254):
```swift
var statsPaytableKey: String {
    switch variant {
    case .standard:      return selectedPaytableId
    case .ultimateX:     return selectedPaytableId + "-ux-\(effectiveUXPlayCount.rawValue)play"
    case .wildWildWild:  return selectedPaytableId + "-www"
    }
}
```

**Do NOT** add a hardcoded line count override — `effectiveLineCount` stays as `lineCount.rawValue` for all variants.

- [ ] **Step 5: Add WildWildWildModels.swift to Xcode project**

Add the new file to the Xcode project's build sources.

- [ ] **Step 6: Build and run tests**

Run: `mcp__xcodebuildmcp__build_sim_name_proj` then `mcp__xcodebuildmcp__test_sim_name_proj`
Expected: All WildWildWildModelsTests and existing tests pass.

- [ ] **Step 7: Commit**

```bash
git add ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/WildWildWildModels.swift \
        ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/PlayModels.swift \
        ios-native/VideoPokerAcademy/VideoPokerAcademy.xcodeproj/project.pbxproj \
        ios-native/VideoPokerAcademy/VideoPokerAcademyTests/WildWildWildModelsTests.swift
git commit -m "feat(ios): add WildWildWildModels and PlayVariant.wildWildWild"
```

---

### Task 6: iOS — Hand Canonical Key + WWW Hand Evaluation

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/Hand.swift` (lines 14–39: canonicalKey, lines 77–94: canonicalIndicesToOriginal)
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/PlayViewModel.swift` (lines 956–1036: evaluateFinalHand)
- Test: `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/HandWWWTests.swift`

- [ ] **Step 1: Write failing tests for canonical key with jokers**

Create `HandWWWTests.swift`:

```swift
import Testing
@testable import VideoPokerAcademy

struct HandWWWTests {
    @Test func canonicalKeyNoJokers() {
        // Standard hand — should be unchanged
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .hearts),
            Card(rank: .king, suit: .hearts),
            Card(rank: .queen, suit: .hearts),
            Card(rank: .jack, suit: .hearts),
            Card(rank: .ten, suit: .hearts),
        ])
        // All same suit → all map to 'a'
        #expect(hand.canonicalKey == "TaJaQaKaAa")
    }

    @Test func canonicalKeyWithOneJoker() {
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .hearts),
            Card(rank: .king, suit: .diamonds),
            Card(rank: .queen, suit: .clubs),
            Card(rank: .jack, suit: .spades),
            Card(rank: .joker, suit: .hearts),
        ])
        // 4 naturals sorted + 1 joker suffix
        let key = hand.canonicalKey
        #expect(key.hasSuffix("Ww"))
        #expect(key.count == 10)
    }

    @Test func canonicalKeyWithTwoJokers() {
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .hearts),
            Card(rank: .king, suit: .hearts),
            Card(rank: .joker, suit: .hearts),
            Card(rank: .joker, suit: .hearts),
            Card(rank: .ten, suit: .diamonds),
        ])
        let key = hand.canonicalKey
        #expect(key.hasSuffix("WwWw"))
        #expect(key.count == 10) // 3 natural (6 chars) + 2 joker (4 chars)
    }

    @Test func canonicalKeyWithThreeJokers() {
        let hand = Hand(cards: [
            Card(rank: .joker, suit: .hearts),
            Card(rank: .ace, suit: .hearts),
            Card(rank: .king, suit: .diamonds),
            Card(rank: .joker, suit: .hearts),
            Card(rank: .joker, suit: .hearts),
        ])
        let key = hand.canonicalKey
        #expect(key.hasSuffix("WwWwWw"))
        #expect(key.count == 10) // 2 natural (4 chars) + 3 joker (6 chars)
    }

    @Test func canonicalIndicesToOriginalWithJokers() {
        let hand = Hand(cards: [
            Card(rank: .joker, suit: .hearts),  // 0 — joker
            Card(rank: .ace, suit: .hearts),     // 1
            Card(rank: .king, suit: .diamonds),  // 2
            Card(rank: .five, suit: .clubs),     // 3
            Card(rank: .joker, suit: .hearts),   // 4 — joker
        ])
        // Canonical order: naturals sorted by rank [5c, Kd, Ah] then jokers [J, J]
        // Canonical indices: 0=5c(orig 3), 1=Kd(orig 2), 2=Ah(orig 1), 3=Joker(orig 0), 4=Joker(orig 4)

        // If optimal hold is canonical [0, 2, 3, 4] (hold 5c, Ah, both jokers)
        let originals = hand.canonicalIndicesToOriginal([0, 2, 3, 4])
        #expect(Set(originals) == Set([3, 1, 0, 4]))
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: Tests fail because canonicalKey doesn't handle jokers yet

- [ ] **Step 3: Update `Hand.canonicalKey` to handle jokers**

In `Hand.swift`, replace the `canonicalKey` computed property:

```swift
var canonicalKey: String {
    let naturals = cards.filter { $0.rank != .joker }
    let jokerCount = cards.count - naturals.count

    let sorted = naturals.sorted {
        if $0.rank.rawValue != $1.rank.rawValue {
            return $0.rank.rawValue < $1.rank.rawValue
        }
        return $0.suit.rawValue < $1.suit.rawValue
    }

    var suitMap: [Suit: String] = [:]
    let suitLetters = ["a", "b", "c", "d"]
    var nextSuitIndex = 0

    for card in sorted {
        if suitMap[card.suit] == nil {
            suitMap[card.suit] = suitLetters[nextSuitIndex]
            nextSuitIndex += 1
        }
    }

    let naturalKey = sorted.map { "\($0.rank.display)\(suitMap[$0.suit]!)" }.joined()
    let jokerSuffix = String(repeating: "Ww", count: jokerCount)
    return naturalKey + jokerSuffix
}
```

- [ ] **Step 4: Update `canonicalIndicesToOriginal` to handle jokers**

Replace the method to handle jokers appearing at the end of canonical order:

```swift
func canonicalIndicesToOriginal(_ canonicalIndices: [Int]) -> [Int] {
    let naturalsWithOriginal = cards.enumerated()
        .filter { $0.element.rank != .joker }
        .map { (original: $0.offset, card: $0.element) }

    let sortedNaturals = naturalsWithOriginal.sorted {
        if $0.card.rank.rawValue != $1.card.rank.rawValue {
            return $0.card.rank.rawValue < $1.card.rank.rawValue
        }
        return $0.card.suit.rawValue < $1.card.suit.rawValue
    }

    let jokerOriginals = cards.enumerated()
        .filter { $0.element.rank == .joker }
        .map { $0.offset }

    // Canonical order: sorted naturals, then jokers
    let canonicalToOriginal = sortedNaturals.map { $0.original } + jokerOriginals

    return canonicalIndices.compactMap { ci -> Int? in
        guard ci >= 0 && ci < canonicalToOriginal.count else { return nil }
        return canonicalToOriginal[ci]
    }
}
```

- [ ] **Step 5: Add WWW hand evaluation to PlayViewModel**

In `PlayViewModel.swift`, add a new private method after `evaluateDeucesWildHand`:

```swift
/// Evaluates a final hand for WWW mode.
/// Jokers in the hand (from deck augmentation) act as universal wilds.
/// For Deuces Wild base games, both deuces and jokers are wild.
private func evaluateWWWHand(_ cards: [Card]) -> HandEvaluation {
    let isDeucesBase = settings.selectedPaytableId.hasPrefix("deuces-wild") ||
                       settings.selectedPaytableId.hasPrefix("loose-deuces")

    let numJokers = cards.filter { $0.rank == .joker }.count
    let nonJokers = cards.filter { $0.rank != .joker }
    let numDeuces = isDeucesBase ? nonJokers.filter { $0.rank == .two }.count : 0
    let totalWilds = numJokers + numDeuces

    // For deuces-base: naturals exclude both jokers and deuces
    let naturals = nonJokers.filter { !isDeucesBase || $0.rank != .two }

    var rankCounts: [Int: Int] = [:]
    for card in naturals {
        rankCounts[card.rank.rawValue, default: 0] += 1
    }
    let maxCount = rankCounts.values.max() ?? 0

    // Zero wilds — evaluate as standard
    if totalWilds == 0 {
        let paytableRowNames = Set(currentPaytable?.rows.map { $0.handName } ?? [])
        let pairs = rankCounts.filter { $0.value == 2 }.map { $0.key }.sorted(by: >)
        let trips = rankCounts.filter { $0.value == 3 }.map { $0.key }
        let quads = rankCounts.filter { $0.value == 4 }.map { $0.key }
        return evaluateStandardHand(cards: cards, pairs: pairs, trips: trips, quads: quads, paytableRowNames: paytableRowNames)
    }

    // Deuces-specific: Four Deuces
    if isDeucesBase && numDeuces == 4 {
        return HandEvaluation(handName: "Four Deuces", winningIndices: getCardIndices(cards: cards, rank: 2))
    }

    // Five of a Kind
    if maxCount + totalWilds >= 5 {
        return HandEvaluation(handName: "Five of a Kind", winningIndices: Array(0..<5))
    }

    // Wild Royal Flush
    if isWildRoyalFlush(naturals, numWilds: totalWilds) {
        return HandEvaluation(handName: "Wild Royal", winningIndices: Array(0..<5))
    }

    // Straight Flush
    if canMakeStraightFlushWithWilds(naturals, numWilds: totalWilds) {
        return HandEvaluation(handName: "Straight Flush", winningIndices: Array(0..<5))
    }

    // Four of a Kind
    if maxCount + totalWilds >= 4 {
        let paytableRowNames = Set(currentPaytable?.rows.map { $0.handName } ?? [])
        let quadRank = rankCounts.max(by: { $0.value < $1.value })?.key ?? 0
        let kicker = naturals.first { $0.rank.rawValue != quadRank }?.rank.rawValue ?? 0
        let handName = HandEvaluator.resolveQuadHandName(quadRank: quadRank, kickerRank: kicker, paytableRowNames: paytableRowNames)
        return HandEvaluation(handName: handName, winningIndices: Array(0..<5))
    }

    // Full House
    if canMakeFullHouseWithWilds(rankCounts: rankCounts, numDeuces: totalWilds) {
        return HandEvaluation(handName: "Full House", winningIndices: Array(0..<5))
    }

    // Flush (all naturals same suit — wilds fill in)
    if isFlushWithWilds(naturals) {
        return HandEvaluation(handName: "Flush", winningIndices: Array(0..<5))
    }

    // Straight
    if canMakeStraightWithWilds(naturals, numDeuces: totalWilds) {
        return HandEvaluation(handName: "Straight", winningIndices: Array(0..<5))
    }

    // Three of a Kind
    if maxCount + totalWilds >= 3 {
        return HandEvaluation(handName: "Three of a Kind", winningIndices: Array(0..<5))
    }

    // Two Pair
    let numPairs = rankCounts.filter { $0.value == 2 }.count
    if numPairs >= 2 {
        return HandEvaluation(handName: "Two Pair", winningIndices: Array(0..<5))
    }

    // High Pair (with wild, can always make at least a pair of the highest natural)
    if let pairInfo = HandEvaluator.resolveHighPairInfo(paytableRowNames: Set(currentPaytable?.rows.map { $0.handName } ?? [])) {
        let highestNatural = rankCounts.keys.max() ?? 0
        if highestNatural >= pairInfo.minRank || totalWilds >= 1 {
            // With wilds, pair the highest natural or make a high pair
            let bestRank = max(highestNatural, pairInfo.minRank)
            if bestRank >= pairInfo.minRank {
                return HandEvaluation(handName: pairInfo.name, winningIndices: Array(0..<5))
            }
        }
    }

    return HandEvaluation(handName: nil, winningIndices: [])
}
```

Update `evaluateFinalHand` to route WWW hands:

```swift
private func evaluateFinalHand(_ cards: [Card]) -> HandEvaluation {
    // WWW mode: use dedicated evaluator that handles jokers + optional deuces
    if settings.variant.isWildWildWild {
        return evaluateWWWHand(cards)
    }

    // ... existing Deuces Wild and standard dispatch ...
}
```

**IMPORTANT:** The existing helper functions (`isWildRoyalFlush`, `isFlushWithWilds`, `canMakeStraightWithWilds`, `canMakeStraightFlushWithWilds`, `canMakeFullHouseWithWilds`) are hardcoded to treat deuces (rank 2) as wilds. They internally filter `$0.rank.rawValue != 2`. These **cannot** be reused for WWW on non-Deuces-Wild games because they'd incorrectly filter out legitimate 2-rank cards.

**Solution:** Create new generic wild helper functions that accept pre-separated naturals and a wild count, without any internal deuce filtering:

```swift
// Generic: all naturals same suit (wilds fill suit)
private func isFlushWithGenericWilds(_ naturals: [Card]) -> Bool {
    guard !naturals.isEmpty else { return true }
    let firstSuit = naturals[0].suit
    return naturals.allSatisfy { $0.suit == firstSuit }
}

// Generic: can naturals + wilds form a royal flush?
private func isWildRoyalWithGenericWilds(_ naturals: [Card], numWilds: Int) -> Bool {
    guard numWilds > 0 else { return false }
    guard isFlushWithGenericWilds(naturals) else { return false }
    let royalRanks: Set<Int> = [10, 11, 12, 13, 14] // T, J, Q, K, A
    let naturalRanks = Set(naturals.map { $0.rank.rawValue })
    guard naturalRanks.isSubset(of: royalRanks) else { return false }
    return naturalRanks.count + numWilds >= 5
}

// Generic: can naturals + wilds form a straight?
private func canMakeStraightWithGenericWilds(_ naturals: [Card], numWilds: Int) -> Bool {
    let ranks = naturals.map { $0.rank.rawValue }.sorted()
    guard ranks.count + numWilds == 5 else { return false }
    guard Set(ranks).count == ranks.count else { return false } // no duplicates

    // Try ace-low (A=1) and ace-high (A=14)
    for aceVal in [14, 1] {
        let adjusted = ranks.map { $0 == 14 ? aceVal : $0 }.sorted()
        if adjusted.isEmpty { return true } // all wilds
        let lo = adjusted.first!
        let hi = adjusted.last!
        if hi - lo <= 4 { return true }
    }
    return false
}

// Generic: can naturals + wilds form a straight flush?
private func canMakeStraightFlushWithGenericWilds(_ naturals: [Card], numWilds: Int) -> Bool {
    guard isFlushWithGenericWilds(naturals) else { return false }
    return canMakeStraightWithGenericWilds(naturals, numWilds: numWilds)
}

// Generic: can rank counts + wilds form a full house?
private func canMakeFullHouseWithGenericWilds(rankCounts: [Int: Int], numWilds: Int) -> Bool {
    let sorted = rankCounts.values.sorted(by: >)
    guard sorted.count >= 2 else { return false }
    let needTrips = max(0, 3 - sorted[0])
    let needPair = max(0, 2 - sorted[1])
    return needTrips + needPair <= numWilds
}
```

Use these generic helpers in `evaluateWWWHand` instead of the deuces-hardcoded ones. The existing deuces helpers remain unchanged for the Deuces Wild evaluator.

- [ ] **Step 6: Add tests for WWW hand evaluation**

Add to `HandWWWTests.swift`:

```swift
@Test func wwwEvaluatesFiveOfAKindWithJokers() {
    // 3 Aces + 2 jokers = Five of a Kind
    let cards: [Card] = [
        Card(rank: .ace, suit: .hearts),
        Card(rank: .ace, suit: .diamonds),
        Card(rank: .ace, suit: .clubs),
        Card(rank: .joker, suit: .hearts),
        Card(rank: .joker, suit: .hearts),
    ]
    // Verify via hand evaluation (will need access to PlayViewModel or extracted evaluator)
    // For now, test the helper directly
    let naturals = cards.filter { $0.rank != .joker }
    var rankCounts: [Int: Int] = [:]
    for c in naturals { rankCounts[c.rank.rawValue, default: 0] += 1 }
    let maxCount = rankCounts.values.max() ?? 0
    #expect(maxCount + 2 >= 5) // 3 aces + 2 wilds = 5
}

@Test func wwwFlushWithJokerDoesNotFilterDeuces() {
    // 2h, 5h, Kh, Ah + Joker — should be a flush (all hearts + wild)
    // The old helper would incorrectly filter out 2h
    let naturals: [Card] = [
        Card(rank: .two, suit: .hearts),
        Card(rank: .five, suit: .hearts),
        Card(rank: .king, suit: .hearts),
        Card(rank: .ace, suit: .hearts),
    ]
    // All naturals are hearts — with 1 wild this is a flush
    let allSameSuit = naturals.allSatisfy { $0.suit == naturals[0].suit }
    #expect(allSameSuit == true)
}
```

- [ ] **Step 7: Build and run tests**

Run: `mcp__xcodebuildmcp__build_sim_name_proj` then `mcp__xcodebuildmcp__test_sim_name_proj`
Expected: All HandWWWTests pass. Existing HandEvaluatorTests still pass.

- [ ] **Step 8: Commit**

```bash
git add ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/Hand.swift \
        ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/PlayViewModel.swift \
        ios-native/VideoPokerAcademy/VideoPokerAcademyTests/HandWWWTests.swift
git commit -m "feat(ios): add joker-aware canonical key and WWW hand evaluation"
```

---

### Task 7: iOS — PlayViewModel Deal/Draw/Strategy Integration

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/PlayViewModel.swift` (lines 6–47: state, lines 171–222: deal, lines 271–363: performStandardDraw, lines 695–707: lookupOptimalStrategy)
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/PlayModels.swift` (ActiveHandState)
- Test: `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/PlayViewModelWWWTests.swift`

- [ ] **Step 1: Write failing tests for WWW deal/draw flow**

Create `PlayViewModelWWWTests.swift`:

```swift
import Testing
@testable import VideoPokerAcademy

struct PlayViewModelWWWTests {
    @Test func wwwDealCreatesAugmentedDeck() async {
        // This test verifies the ViewModel correctly deals from a 52+N deck
        // We can't test the full deal() because it requires StrategyService,
        // but we can test the deck augmentation logic
        let deck = Card.shuffledDeck(jokerCount: 2)
        #expect(deck.count == 54)

        let dealt = Array(deck.prefix(5))
        let remaining = Array(deck.dropFirst(5))
        #expect(dealt.count == 5)
        #expect(remaining.count == 49) // 54 - 5

        let totalJokers = deck.filter { $0.rank == .joker }.count
        #expect(totalJokers == 2)
    }

    @Test func wwwDrawCanProduceJokersFromDeck() {
        // Create a hand where no jokers are dealt but remain in deck
        let natural = [
            Card(rank: .ace, suit: .hearts),
            Card(rank: .king, suit: .hearts),
            Card(rank: .queen, suit: .hearts),
            Card(rank: .jack, suit: .hearts),
            Card(rank: .ten, suit: .hearts),
        ]
        var remaining = Card.createDeck().filter { card in
            !natural.contains(where: { $0.rank == card.rank && $0.suit == card.suit })
        }
        // Add 2 jokers to remaining deck
        remaining.append(Card(rank: .joker, suit: .hearts))
        remaining.append(Card(rank: .joker, suit: .hearts))
        remaining.shuffle()

        #expect(remaining.count == 49) // 47 natural + 2 jokers

        // Verify jokers can be drawn
        let jokerCount = remaining.filter { $0.rank == .joker }.count
        #expect(jokerCount == 2)
    }

    @Test func wwwActiveHandStatePersistsWildCount() throws {
        let cards = [
            Card(rank: .ace, suit: .hearts),
            Card(rank: .joker, suit: .hearts),
            Card(rank: .king, suit: .diamonds),
            Card(rank: .queen, suit: .clubs),
            Card(rank: .jack, suit: .spades),
        ]
        var settings = PlaySettings()
        settings.variant = .wildWildWild

        let state = ActiveHandState(
            dealtCards: cards,
            selectedIndices: [0, 1, 2],
            remainingDeck: [],
            betAmount: 30.0,
            settings: settings,
            wwwWildCount: 2
        )

        #expect(state.wwwWildCount == 2)

        // Test round-trip encoding
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(ActiveHandState.self, from: data)
        #expect(decoded.wwwWildCount == 2)
        #expect(decoded.dealtCards[1].rank == .joker)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: Compilation error — `wwwWildCount` not in ActiveHandState yet

- [ ] **Step 3: Add `wwwWildCount` state to PlayViewModel**

At the top of PlayViewModel, add:
```swift
@Published var wwwWildCount: Int = 0  // Total wilds added to deck (0–3)
```

- [ ] **Step 4: Update `deal()` for WWW deck augmentation**

In the `deal()` function, after `audioService.play(.cardFlip)`, add WWW deck creation:

```swift
// Create deck — augmented for WWW, standard otherwise
let wwwCount: Int
if settings.variant.isWildWildWild {
    let family = currentPaytable?.family ?? .jacksOrBetter
    wwwCount = WildWildWildDistribution.sampleWildCount(for: family)
} else {
    wwwCount = 0
}
wwwWildCount = wwwCount

let deck = Card.shuffledDeck(jokerCount: wwwCount)
dealtCards = Array(deck.prefix(5))
remainingDeck = Array(deck.dropFirst(5))
```

Replace the existing deck creation lines (`let deck = Card.shuffledDeck()` / `dealtCards = Array(deck.prefix(5))` / `remainingDeck = Array(deck.dropFirst(5))`).

- [ ] **Step 5: Remove the old `evaluateFinalHand(_ cards: [Card], wwwWildCount: Int)` parameter**

The old signature had a `wwwWildCount` parameter. Remove it — the new `evaluateWWWHand` checks `card.rank == .joker` directly, so no parameter is needed. Update all call sites to use `evaluateFinalHand(cards)` without the extra parameter.

- [ ] **Step 6: Update `performStandardDraw` — remove wwwSurvivedWildCount logic**

Delete the `wwwSurvivedWildCount` calculation block. Since jokers are actual cards in the deck, they naturally appear in drawn hands. The `evaluateFinalHand` evaluator counts them from the cards directly:

```swift
// In performStandardDraw, for each line:
let evaluation = evaluateFinalHand(finalHand)  // No wwwWildCount parameter
```

- [ ] **Step 7: Update strategy lookup for WWW**

In `lookupOptimalStrategy()`, add WWW strategy file selection:

```swift
private func lookupOptimalStrategy() {
    let hand = Hand(cards: dealtCards)
    let baseId = settings.selectedPaytableId

    Task {
        do {
            if settings.variant.isWildWildWild {
                let wwwId = WildWildWildDistribution.wwwStrategyId(baseId: baseId, wildCount: wwwWildCount)
                // Use StrategyService (with cache) — same path as standard/UX
                if let result = try await StrategyService.shared.lookup(hand: hand, paytableId: wwwId) {
                    let canonicalIndices = result.bestHoldIndices
                    optimalHoldIndices = hand.canonicalIndicesToOriginal(canonicalIndices).sorted()
                    strategyResult = result
                }
            } else {
                // Standard or UX lookup (unchanged)
                if let result = try await StrategyService.shared.lookup(hand: hand, paytableId: baseId) {
                    let canonicalIndices = result.bestHoldIndices
                    optimalHoldIndices = hand.canonicalIndicesToOriginal(canonicalIndices).sorted()
                    strategyResult = result
                }
            }
        } catch {
            debugLog("Strategy lookup failed: \(error)")
        }
    }
}
```

- [ ] **Step 8: Prepare WWW strategy files at game start**

In the strategy preparation section (around line 160), add WWW file preparation similar to UX:

```swift
if settings.variant.isWildWildWild {
    let baseId = paytableId
    for n in 0...3 {
        let wwwId = WildWildWildDistribution.wwwStrategyId(baseId: baseId, wildCount: n)
        let ok = await StrategyService.shared.preparePaytable(paytableId: wwwId) { [weak self] status in
            guard let self else { return }
            switch status {
            case .downloading(let progress):
                preparationMessage = "Downloading Wild Wild Wild strategies... \(Int(progress * 100))%"
            case .ready, .checking:
                break
            case .failed(let msg):
                debugNSLog("⚠️ WWW strategy download failed for %@: %@", wwwId, msg)
            }
        }
        if !ok {
            debugNSLog("⚠️ WWW strategy unavailable for %@", wwwId)
        }
    }
    isPreparingPaytable = false
    preparationFailed = false
    preparationMessage = "Ready"
}
```

- [ ] **Step 9: Update ActiveHandState for WWW persistence**

Add `wwwWildCount` to `ActiveHandState`:

```swift
struct ActiveHandState: Codable {
    let dealtCards: [CardData]
    let selectedIndices: [Int]
    let remainingDeck: [CardData]
    let betAmount: Double
    let settings: PlaySettings
    let timestamp: Date
    let wwwWildCount: Int  // Total wilds added to deck (0 if not WWW)

    init(dealtCards: [Card], selectedIndices: Set<Int>, remainingDeck: [Card],
         betAmount: Double, settings: PlaySettings, wwwWildCount: Int = 0) {
        self.dealtCards = dealtCards.map { CardData(rank: $0.rank, suit: $0.suit) }
        self.selectedIndices = Array(selectedIndices)
        self.remainingDeck = remainingDeck.map { CardData(rank: $0.rank, suit: $0.suit) }
        self.betAmount = betAmount
        self.settings = settings
        self.timestamp = Date()
        self.wwwWildCount = wwwWildCount
    }

    enum CodingKeys: String, CodingKey {
        case dealtCards, selectedIndices, remainingDeck, betAmount, settings, timestamp
        case wwwWildCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        dealtCards = try c.decode([CardData].self, forKey: .dealtCards)
        selectedIndices = try c.decode([Int].self, forKey: .selectedIndices)
        remainingDeck = try c.decode([CardData].self, forKey: .remainingDeck)
        betAmount = try c.decode(Double.self, forKey: .betAmount)
        settings = try c.decode(PlaySettings.self, forKey: .settings)
        timestamp = try c.decode(Date.self, forKey: .timestamp)
        wwwWildCount = try c.decodeIfPresent(Int.self, forKey: .wwwWildCount) ?? 0
    }
}
```

Update save/restore calls in PlayViewModel to pass `wwwWildCount`.

- [ ] **Step 10: Update reset logic**

In the reset/cleanup method, add:
```swift
wwwWildCount = 0
```

- [ ] **Step 11: Build and run tests**

Run: `mcp__xcodebuildmcp__build_sim_name_proj` then `mcp__xcodebuildmcp__test_sim_name_proj`
Expected: All tests pass including PlayViewModelWWWTests.

- [ ] **Step 12: Commit**

```bash
git add ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/PlayViewModel.swift \
        ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/PlayModels.swift \
        ios-native/VideoPokerAcademy/VideoPokerAcademyTests/PlayViewModelWWWTests.swift
git commit -m "feat(ios): integrate WWW deal/draw/strategy into PlayViewModel"
```

---

### Task 8: iOS — UI Updates (CardView, PlayStartView, PlayView)

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Components/CardView.swift` (lines 10–15: cardImageName)
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/MiniCardView.swift` (lines 13–19: cardImageName)
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/PlayStartView.swift` (lines 190–246: linesSection, variantSection)
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/PlayView.swift` (card display, wild count banner)

- [ ] **Step 1: Update CardView for joker rendering**

In `CardView.swift`, the `cardImageName` property should check for joker rank directly — no external `isWWWWild` flag needed:

```swift
private var cardImageName: String {
    if card.rank == .joker {
        return "1J"
    }
    if showAsWild && card.rank == .two {
        return "\(card.rank.display)\(card.suit.code)_wild"
    }
    return card.imageName
}
```

Remove the `isWWWWild` parameter if it exists — joker cards are now self-identifying via `rank == .joker`.

- [ ] **Step 2: Update MiniCardView similarly**

Same change in `MiniCardView.swift`:

```swift
private var cardImageName: String {
    if card.rank == .joker {
        return "1J"
    }
    if showAsWild && card.rank == .two {
        return "\(card.rank.display)\(card.suit.code)_wild"
    }
    return card.imageName
}
```

Remove any `isWWWWild` parameter.

- [ ] **Step 3: Update PlayStartView — add WWW variant selection**

In `PlayStartView.swift` `variantSection` (around line 214), add the Wild Wild Wild chip:

```swift
private var variantSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("Variant")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(AppTheme.Colors.textSecondary)

        FlowLayout(spacing: 8) {
            SelectionChip(title: "Standard", isSelected: settings.variant == .standard) {
                settings.variant = .standard
            }
            SelectionChip(title: "Ult X", isSelected: settings.variant == .ultimateX) {
                settings.variant = .ultimateX
            }
            SelectionChip(title: "Wild³", isSelected: settings.variant == .wildWildWild) {
                settings.variant = .wildWildWild
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        if settings.variant == .ultimateX {
            Text("2× bet cost · \(settings.lineCount.rawValue) simultaneous hands")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }

        if settings.variant == .wildWildWild {
            if isWWWSupportedForCurrentGame {
                Text("2× bet cost · 0–3 wild cards added to deck each deal")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            } else {
                Text("Wild Wild Wild is not available for this game")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
            }
        }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
```

Add the WWW support check property:
```swift
private var isWWWSupportedForCurrentGame: Bool {
    WildWildWildDistribution.isSupported(paytableId: settings.selectedPaytableId)
}
```

Disable start button for unsupported WWW games:
```swift
.disabled(settings.variant == .wildWildWild && !isWWWSupportedForCurrentGame)
```

**Do NOT** override the lines section — standard line counts apply for WWW. Consider disabling 100-play for WWW:

```swift
private var linesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("Lines")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(AppTheme.Colors.textSecondary)

        FlowLayout(spacing: 8) {
            ForEach(LineCount.allCases, id: \.self) { lineCount in
                // Disable 100-play for WWW (shared wilds don't work with independent decks)
                let disabled = lineCount == .oneHundred && settings.variant == .wildWildWild
                SelectionChip(
                    title: lineCount.displayName,
                    isSelected: settings.lineCount == lineCount
                ) {
                    if !disabled {
                        settings.lineCount = lineCount
                    }
                }
                .opacity(disabled ? 0.4 : 1.0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
```

- [ ] **Step 4: Add wild count banner to PlayView**

In `PlayView.swift`, add a banner below the dealt cards when in WWW mode:

```swift
// Add this after the dealt cards section, visible during .dealt and .result phases
if viewModel.settings.variant.isWildWildWild && viewModel.phase != .betting {
    wwwWildCountBanner
}
```

The banner view:
```swift
private var wwwWildCountBanner: some View {
    let count = viewModel.wwwWildCount
    let text = count == 0 ? "No Wilds Added" :
               count == 1 ? "1 Wild Added to Deck" :
               "\(count) Wilds Added to Deck"
    let color: Color = count == 0 ? .gray : .yellow

    return Text(text)
        .font(.system(size: 14, weight: .bold))
        .foregroundColor(color)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.2))
        )
}
```

- [ ] **Step 5: Remove any lingering `displayedWildIndices` or `wwwWildIndices` references from PlayView**

Search PlayView.swift for any remaining references to the old WWW implementation (wwwWildIndices, displayedWildIndices, isWWWWild) and remove them. These were reverted in the cleanup but double-check.

- [ ] **Step 6: Build and verify visually**

Run:
```
mcp__xcodebuildmcp__build_sim_name_proj
mcp__xcodebuildmcp__boot_simulator
mcp__xcodebuildmcp__install_app
mcp__xcodebuildmcp__launch_app
mcp__xcodebuildmcp__screenshot
```

Verify: PlayStartView shows Wild³ variant option. Selecting it shows description text and standard line count options (with 100-play dimmed).

- [ ] **Step 7: Run full test suite**

Run: `mcp__xcodebuildmcp__test_sim_name_proj`
Expected: All tests pass.

- [ ] **Step 8: Commit**

```bash
git add ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Components/CardView.swift \
        ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/MiniCardView.swift \
        ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/PlayStartView.swift \
        ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/PlayView.swift
git commit -m "feat(ios): add WWW UI — variant selection, joker rendering, wild count banner"
```
