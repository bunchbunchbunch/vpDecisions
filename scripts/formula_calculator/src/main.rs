use itertools::Itertools;
use std::collections::HashMap;
use std::time::Instant;

// Card representation: 0-51 (rank * 4 + suit)
// Ranks: 0=2, 1=3, 2=4, 3=5, 4=6, 5=7, 6=8, 7=9, 8=T, 9=J, 10=Q, 11=K, 12=A
// Suits: 0=hearts, 1=diamonds, 2=clubs, 3=spades

#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
struct Card(u8);

impl Card {
    fn rank(&self) -> u8 {
        self.0 / 4
    }

    fn suit(&self) -> u8 {
        self.0 % 4
    }

    fn rank_char(&self) -> char {
        match self.rank() {
            0 => '2', 1 => '3', 2 => '4', 3 => '5', 4 => '6',
            5 => '7', 6 => '8', 7 => '9', 8 => 'T',
            9 => 'J', 10 => 'Q', 11 => 'K', 12 => 'A',
            _ => '?'
        }
    }

    fn suit_char(&self) -> char {
        match self.suit() {
            0 => 'h', 1 => 'd', 2 => 'c', 3 => 's',
            _ => '?'
        }
    }
}

type Hand = [Card; 5];

// Jacks or Better 9/6 payouts
const ROYAL_FLUSH: f64 = 800.0;
const STRAIGHT_FLUSH: f64 = 50.0;
const FOUR_OF_KIND: f64 = 25.0;
const FULL_HOUSE: f64 = 9.0;
const FLUSH: f64 = 6.0;
const STRAIGHT: f64 = 4.0;
const THREE_OF_KIND: f64 = 3.0;
const TWO_PAIR: f64 = 2.0;
const JACKS_OR_BETTER: f64 = 1.0;

// Utility functions
fn binomial(n: u64, k: u64) -> u64 {
    if k > n { return 0; }
    if k == 0 || k == n { return 1; }
    let k = if k > n - k { n - k } else { k };

    let mut result = 1u64;
    for i in 0..k {
        result = result * (n - i) / (i + 1);
    }
    result
}

fn is_flush(hand: &[Card]) -> bool {
    if hand.len() != 5 { return false; }
    let suit = hand[0].suit();
    hand.iter().all(|c| c.suit() == suit)
}

fn is_straight(hand: &[Card]) -> bool {
    if hand.len() != 5 { return false; }
    let mut ranks: Vec<u8> = hand.iter().map(|c| c.rank()).collect();
    ranks.sort();

    // Regular straight
    let is_regular = ranks.windows(2).all(|w| w[1] == w[0] + 1);

    // Wheel (A-2-3-4-5) = ranks [0,1,2,3,12]
    let is_wheel = ranks == vec![0, 1, 2, 3, 12];

    is_regular || is_wheel
}

fn get_rank_counts(hand: &[Card]) -> [u8; 13] {
    let mut counts = [0u8; 13];
    for card in hand {
        counts[card.rank() as usize] += 1;
    }
    counts
}

fn is_royal(hand: &[Card]) -> bool {
    if !is_flush(hand) || !is_straight(hand) { return false; }
    let mut ranks: Vec<u8> = hand.iter().map(|c| c.rank()).collect();
    ranks.sort();
    ranks == vec![8, 9, 10, 11, 12] // T, J, Q, K, A
}

fn get_payout(hand: &[Card]) -> f64 {
    if hand.len() != 5 { return 0.0; }

    let flush = is_flush(hand);
    let straight = is_straight(hand);
    let counts = get_rank_counts(hand);

    // Royal Flush
    if is_royal(hand) {
        return ROYAL_FLUSH;
    }

    // Straight Flush
    if flush && straight {
        return STRAIGHT_FLUSH;
    }

    // Count pairs, trips, quads
    let mut pairs = 0;
    let mut pair_ranks = Vec::new();
    let mut trips = 0;
    let mut quads = 0;

    for (rank, &count) in counts.iter().enumerate() {
        match count {
            2 => {
                pairs += 1;
                pair_ranks.push(rank as u8);
            }
            3 => trips += 1,
            4 => quads += 1,
            _ => {}
        }
    }

    // Four of a kind
    if quads > 0 {
        return FOUR_OF_KIND;
    }

    // Full House
    if trips > 0 && pairs > 0 {
        return FULL_HOUSE;
    }

    // Flush
    if flush {
        return FLUSH;
    }

    // Straight
    if straight {
        return STRAIGHT;
    }

    // Three of a kind
    if trips > 0 {
        return THREE_OF_KIND;
    }

    // Two Pair
    if pairs >= 2 {
        return TWO_PAIR;
    }

    // Jacks or Better (high pair)
    if pairs == 1 {
        let rank = pair_ranks[0];
        if rank >= 9 { // J, Q, K, A
            return JACKS_OR_BETTER;
        }
    }

    0.0
}

// BRUTE FORCE METHOD
fn calculate_hold_ev_brute(hand: &Hand, hold_mask: u8) -> f64 {
    let mut held: Vec<Card> = Vec::with_capacity(5);
    for i in 0..5 {
        if hold_mask & (1 << i) != 0 {
            held.push(hand[i]);
        }
    }

    let num_to_draw = 5 - held.len();

    if num_to_draw == 0 {
        let final_hand: [Card; 5] = held.clone().try_into().unwrap();
        return get_payout(&final_hand);
    }

    // Build remaining deck
    let mut deck: Vec<Card> = Vec::with_capacity(47);
    for card_idx in 0..52u8 {
        let card = Card(card_idx);
        if !hand.contains(&card) {
            deck.push(card);
        }
    }

    // Calculate EV by enumerating all draws
    let mut total_payout = 0.0;
    let mut count = 0u64;

    for draw in deck.iter().combinations(num_to_draw) {
        let mut final_hand = held.clone();
        for &card in &draw {
            final_hand.push(*card);
        }
        let final_arr: [Card; 5] = final_hand.try_into().unwrap();
        total_payout += get_payout(&final_arr);
        count += 1;
    }

    total_payout / count as f64
}

// FORMULA-BASED METHOD
#[derive(Debug, Clone)]
struct DeckComposition {
    // For each rank, count how many cards of each suit remain
    rank_suit_counts: [[u8; 4]; 13], // [rank][suit] -> count
    // For each rank, total count
    rank_counts: [u8; 13],
    // For each suit, total count
    suit_counts: [u8; 4],
    // Total cards in deck
    total: u8,
}

impl DeckComposition {
    fn from_hand_and_held(hand: &Hand, held: &[Card]) -> Self {
        let mut rank_suit_counts = [[0u8; 4]; 13];
        let mut rank_counts = [0u8; 13];
        let mut suit_counts = [0u8; 4];

        // Start with full deck
        for rank in 0..13 {
            for suit in 0..4 {
                rank_suit_counts[rank][suit] = 1;
            }
            rank_counts[rank] = 4;
        }
        for suit in 0..4 {
            suit_counts[suit] = 13;
        }

        // Remove ALL cards from original hand (not just held cards)
        for card in hand {
            let r = card.rank() as usize;
            let s = card.suit() as usize;
            rank_suit_counts[r][s] = 0;
            rank_counts[r] -= 1;
            suit_counts[s] -= 1;
        }

        let total = 47u8; // Always 47 cards remaining after removing 5-card hand

        Self {
            rank_suit_counts,
            rank_counts,
            suit_counts,
            total,
        }
    }
}

fn calculate_hold_ev_formula(hand: &Hand, hold_mask: u8) -> f64 {
    let mut held: Vec<Card> = Vec::with_capacity(5);
    for i in 0..5 {
        if hold_mask & (1 << i) != 0 {
            held.push(hand[i]);
        }
    }

    let num_to_draw = 5 - held.len();

    if num_to_draw == 0 {
        let final_hand: [Card; 5] = held.clone().try_into().unwrap();
        return get_payout(&final_hand);
    }

    let deck = DeckComposition::from_hand_and_held(hand, &held);
    let total_draws = binomial(deck.total as u64, num_to_draw as u64);

    // Analyze held cards
    let held_ranks = get_rank_counts(&held.iter().cloned().collect::<Vec<_>>());
    let held_suits: Vec<u8> = held.iter().map(|c| c.suit()).collect();

    // Count occurrences in held cards
    let mut rank_counts_held = [0u8; 13];
    for card in &held {
        rank_counts_held[card.rank() as usize] += 1;
    }

    let mut suit_counts_held = [0u8; 4];
    for card in &held {
        suit_counts_held[card.suit() as usize] += 1;
    }

    // Accumulate expected value for each hand type
    let mut ev = 0.0;

    // IMPORTANT: We need to count each possible final hand exactly once
    // This requires careful enumeration formulas

    // For now, let's implement this by actually enumerating
    // but using smarter logic for common patterns

    // I'll start with a direct enumeration approach that's correct
    // then optimize specific patterns

    ev = calculate_ev_by_enumeration(&held, &deck, num_to_draw);

    ev
}

fn calculate_ev_by_enumeration(held: &[Card], deck: &DeckComposition, num_to_draw: usize) -> f64 {
    // Build actual deck
    let mut deck_cards = Vec::new();
    for rank in 0..13 {
        for suit in 0..4 {
            if deck.rank_suit_counts[rank][suit] > 0 {
                deck_cards.push(Card((rank * 4 + suit) as u8));
            }
        }
    }

    let mut total_payout = 0.0;
    let count = binomial(deck.total as u64, num_to_draw as u64);

    for draw in deck_cards.iter().combinations(num_to_draw) {
        let mut final_hand = held.to_vec();
        for &card in &draw {
            final_hand.push(*card);
        }
        let final_arr: [Card; 5] = final_hand.try_into().unwrap();
        total_payout += get_payout(&final_arr);
    }

    total_payout / count as f64
}

// Test validation
fn test_hand(hand: &Hand, description: &str) {
    println!("\nTesting: {}", description);
    let hand_str: String = hand.iter()
        .map(|c| format!("{}{}", c.rank_char(), c.suit_char()))
        .collect::<Vec<_>>()
        .join(" ");
    println!("Hand: {}", hand_str);

    let mut max_diff = 0.0;
    let mut total_diff = 0.0;
    let mut mismatches = Vec::new();

    for hold_mask in 0..32u8 {
        let ev_brute = calculate_hold_ev_brute(hand, hold_mask);
        let ev_formula = calculate_hold_ev_formula(hand, hold_mask);

        let diff = (ev_brute - ev_formula).abs();
        if diff > max_diff {
            max_diff = diff;
        }
        total_diff += diff;

        if diff > 0.000001 {
            mismatches.push((hold_mask, ev_brute, ev_formula, diff));
        }
    }

    println!("Max difference: {:.10}", max_diff);
    println!("Avg difference: {:.10}", total_diff / 32.0);

    if !mismatches.is_empty() {
        println!("MISMATCHES FOUND: {}", mismatches.len());
        for (mask, brute, formula, diff) in mismatches.iter().take(5) {
            println!("  Hold mask {:05b}: Brute={:.8}, Formula={:.8}, Diff={:.10}",
                     mask, brute, formula, diff);
        }
    } else {
        println!("✓ All hold patterns match!");
    }
}

fn hand_to_canonical_key(hand: &Hand) -> String {
    let mut sorted: Vec<Card> = hand.to_vec();
    sorted.sort_by_key(|c| c.rank());

    let mut suit_map: HashMap<u8, char> = HashMap::new();
    let suit_letters = ['a', 'b', 'c', 'd'];
    let mut next_suit = 0;

    let mut key = String::with_capacity(10);
    for card in &sorted {
        key.push(card.rank_char());

        let suit_char = *suit_map.entry(card.suit()).or_insert_with(|| {
            let c = suit_letters[next_suit];
            next_suit += 1;
            c
        });
        key.push(suit_char);
    }

    key
}

fn generate_test_hands() -> Vec<Hand> {
    vec![
        // Pair of Jacks
        [Card(36), Card(37), Card(0), Card(4), Card(8)], // Jh Jd 2h 3h 4h
        // Pair of 5s
        [Card(12), Card(13), Card(0), Card(4), Card(8)], // 5h 5d 2h 3h 4h
        // Two Pair
        [Card(12), Card(13), Card(16), Card(17), Card(0)], // 5h 5d 6h 6d 2h
        // Three of a kind
        [Card(12), Card(13), Card(14), Card(0), Card(4)], // 5h 5d 5c 2h 3h
        // Four card flush
        [Card(0), Card(4), Card(8), Card(12), Card(17)], // 2h 3h 4h 5h 6d
        // Four card straight
        [Card(12), Card(16), Card(20), Card(24), Card(0)], // 5h 6h 7h 8h 2h
        // High cards
        [Card(36), Card(40), Card(44), Card(48), Card(0)], // Jh Qh Kh Ah 2h
        // Royal draw (4 card)
        [Card(32), Card(36), Card(40), Card(44), Card(0)], // Th Jh Qh Kh 2h
        // Made straight
        [Card(12), Card(16), Card(20), Card(24), Card(28)], // 5h 6h 7h 8h 9h
        // Made flush
        [Card(0), Card(4), Card(8), Card(12), Card(16)], // 2h 3h 4h 5h 6h
    ]
}

fn main() {
    println!("Video Poker Formula-Based Calculator");
    println!("=====================================\n");

    // Test on sample hands
    println!("PHASE 1: Testing on sample hands");
    println!("=================================");

    for hand in generate_test_hands() {
        let desc = format!("{}{} {}{} {}{} {}{} {}{}",
            hand[0].rank_char(), hand[0].suit_char(),
            hand[1].rank_char(), hand[1].suit_char(),
            hand[2].rank_char(), hand[2].suit_char(),
            hand[3].rank_char(), hand[3].suit_char(),
            hand[4].rank_char(), hand[4].suit_char());
        test_hand(&hand, &desc);
    }

    println!("\n\nPHASE 2: Generating all canonical hands");
    println!("========================================");

    let start = Instant::now();
    let mut seen: HashMap<String, Hand> = HashMap::new();

    for c1 in 0..48u8 {
        for c2 in (c1 + 1)..49 {
            for c3 in (c2 + 1)..50 {
                for c4 in (c3 + 1)..51 {
                    for c5 in (c4 + 1)..52 {
                        let hand: Hand = [Card(c1), Card(c2), Card(c3), Card(c4), Card(c5)];
                        let key = hand_to_canonical_key(&hand);
                        seen.entry(key).or_insert(hand);
                    }
                }
            }
        }
    }

    let canonical_hands: Vec<Hand> = seen.values().cloned().collect();
    println!("Generated {} canonical hands in {:?}", canonical_hands.len(), start.elapsed());

    println!("\n\nPHASE 3: Exhaustive validation");
    println!("================================");
    println!("Testing all {} canonical hands...", canonical_hands.len());

    let start = Instant::now();
    let mut total_max_diff = 0.0;
    let mut hands_with_errors = 0;
    let mut error_hands = Vec::new();

    for (idx, hand) in canonical_hands.iter().enumerate() {
        if idx % 10000 == 0 {
            println!("Progress: {}/{} hands tested...", idx, canonical_hands.len());
        }

        let mut max_diff_for_hand = 0.0;

        for hold_mask in 0..32u8 {
            let ev_brute = calculate_hold_ev_brute(hand, hold_mask);
            let ev_formula = calculate_hold_ev_formula(hand, hold_mask);

            let diff = (ev_brute - ev_formula).abs();
            if diff > max_diff_for_hand {
                max_diff_for_hand = diff;
            }
        }

        if max_diff_for_hand > total_max_diff {
            total_max_diff = max_diff_for_hand;
        }

        if max_diff_for_hand > 0.000001 {
            hands_with_errors += 1;
            if error_hands.len() < 10 {
                error_hands.push((hand.clone(), max_diff_for_hand));
            }
        }
    }

    let elapsed = start.elapsed();
    println!("\nValidation complete in {:?}", elapsed);
    println!("Maximum difference across all hands: {:.10}", total_max_diff);
    println!("Hands with errors > 0.000001: {}", hands_with_errors);

    if hands_with_errors > 0 {
        println!("\nSample error hands:");
        for (hand, max_diff) in error_hands {
            let hand_str: String = hand.iter()
                .map(|c| format!("{}{}", c.rank_char(), c.suit_char()))
                .collect::<Vec<_>>()
                .join(" ");
            println!("  {} - max diff: {:.10}", hand_str, max_diff);
        }
    } else {
        println!("\n✓✓✓ ALL HANDS MATCH PERFECTLY! ✓✓✓");
    }

    // Benchmark
    println!("\n\nPHASE 4: Performance benchmark");
    println!("================================");

    let test_hand = canonical_hands[0];
    let iterations = 1000;

    let start = Instant::now();
    for _ in 0..iterations {
        for hold_mask in 0..32u8 {
            calculate_hold_ev_brute(&test_hand, hold_mask);
        }
    }
    let brute_time = start.elapsed();

    let start = Instant::now();
    for _ in 0..iterations {
        for hold_mask in 0..32u8 {
            calculate_hold_ev_formula(&test_hand, hold_mask);
        }
    }
    let formula_time = start.elapsed();

    println!("Brute force: {:?} for {} iterations ({} hold patterns each)",
             brute_time, iterations, 32);
    println!("Formula:     {:?} for {} iterations ({} hold patterns each)",
             formula_time, iterations, 32);

    if formula_time.as_nanos() > 0 {
        let speedup = brute_time.as_nanos() as f64 / formula_time.as_nanos() as f64;
        println!("Speedup: {:.2}x", speedup);
    }
}
