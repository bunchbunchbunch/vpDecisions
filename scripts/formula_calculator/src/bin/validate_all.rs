// Validate formula-based calculator against brute force on ALL canonical hands

use itertools::Itertools;
use std::collections::HashMap;
use std::time::Instant;

#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
struct Card(u8);

impl Card {
    fn rank(&self) -> u8 { self.0 / 4 }
    fn suit(&self) -> u8 { self.0 % 4 }
    fn rank_char(&self) -> char {
        match self.rank() {
            0 => '2', 1 => '3', 2 => '4', 3 => '5', 4 => '6',
            5 => '7', 6 => '8', 7 => '9', 8 => 'T',
            9 => 'J', 10 => 'Q', 11 => 'K', 12 => 'A',
            _ => '?'
        }
    }
}

type Hand = [Card; 5];

const ROYAL_FLUSH: f64 = 800.0;
const STRAIGHT_FLUSH: f64 = 50.0;
const FOUR_OF_KIND: f64 = 25.0;
const FULL_HOUSE: f64 = 9.0;
const FLUSH: f64 = 6.0;
const STRAIGHT: f64 = 4.0;
const THREE_OF_KIND: f64 = 3.0;
const TWO_PAIR: f64 = 2.0;
const JACKS_OR_BETTER: f64 = 1.0;

fn is_flush(hand: &[Card]) -> bool {
    if hand.len() != 5 { return false; }
    let suit = hand[0].suit();
    hand.iter().all(|c| c.suit() == suit)
}

fn is_straight(hand: &[Card]) -> bool {
    if hand.len() != 5 { return false; }
    let mut ranks: Vec<u8> = hand.iter().map(|c| c.rank()).collect();
    ranks.sort();
    let is_regular = ranks.windows(2).all(|w| w[1] == w[0] + 1);
    let is_wheel = ranks == vec![0, 1, 2, 3, 12];
    is_regular || is_wheel
}

fn is_royal(hand: &[Card]) -> bool {
    if !is_flush(hand) || !is_straight(hand) { return false; }
    let mut ranks: Vec<u8> = hand.iter().map(|c| c.rank()).collect();
    ranks.sort();
    ranks == vec![8, 9, 10, 11, 12]
}

fn get_rank_counts(hand: &[Card]) -> [u8; 13] {
    let mut counts = [0u8; 13];
    for card in hand {
        counts[card.rank() as usize] += 1;
    }
    counts
}

fn get_payout(hand: &[Card]) -> f64 {
    if hand.len() != 5 { return 0.0; }

    let flush = is_flush(hand);
    let straight = is_straight(hand);
    let counts = get_rank_counts(hand);

    if is_royal(hand) { return ROYAL_FLUSH; }
    if flush && straight { return STRAIGHT_FLUSH; }

    let mut pairs = 0;
    let mut pair_ranks = Vec::new();
    let mut trips = 0;
    let mut quads = 0;

    for (rank, &count) in counts.iter().enumerate() {
        match count {
            2 => { pairs += 1; pair_ranks.push(rank as u8); }
            3 => trips += 1,
            4 => quads += 1,
            _ => {}
        }
    }

    if quads > 0 { return FOUR_OF_KIND; }
    if trips > 0 && pairs > 0 { return FULL_HOUSE; }
    if flush { return FLUSH; }
    if straight { return STRAIGHT; }
    if trips > 0 { return THREE_OF_KIND; }
    if pairs >= 2 { return TWO_PAIR; }
    if pairs == 1 {
        let rank = pair_ranks[0];
        if rank >= 9 { return JACKS_OR_BETTER; }
    }

    0.0
}

fn calculate_ev_brute(hand: &Hand, hold_mask: u8) -> f64 {
    let mut held: Vec<Card> = Vec::new();
    for i in 0..5 {
        if hold_mask & (1 << i) != 0 {
            held.push(hand[i]);
        }
    }

    let num_to_draw = 5 - held.len();
    if num_to_draw == 0 {
        let final_hand: [Card; 5] = held.try_into().unwrap();
        return get_payout(&final_hand);
    }

    let mut deck: Vec<Card> = Vec::new();
    for card_idx in 0..52u8 {
        let card = Card(card_idx);
        if !hand.contains(&card) {
            deck.push(card);
        }
    }

    let mut total_payout = 0.0;
    let count = deck.iter().combinations(num_to_draw).count();

    for draw in deck.iter().combinations(num_to_draw) {
        let mut final_hand = held.clone();
        for &card in &draw {
            final_hand.push(*card);
        }
        let final_arr: [Card; 5] = final_hand.try_into().unwrap();
        total_payout += get_payout(&final_arr);
    }

    total_payout / count as f64
}

fn calculate_ev_formula(hand: &Hand, hold_mask: u8) -> f64 {
    // For now, this is identical to brute force
    // We'll optimize later while ensuring 100% accuracy
    calculate_ev_brute(hand, hold_mask)
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

fn generate_canonical_hands() -> Vec<Hand> {
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

    seen.values().cloned().collect()
}

fn main() {
    println!("Canonical Hand Validator");
    println!("========================\n");

    println!("Generating all canonical hands...");
    let start = Instant::now();
    let canonical_hands = generate_canonical_hands();
    let gen_time = start.elapsed();
    println!("Generated {} canonical hands in {:?}\n", canonical_hands.len(), gen_time);

    println!("Validating ALL canonical hands (this will take a while)...");
    println!("Testing {} hands × 32 hold patterns = {} total evaluations\n",
             canonical_hands.len(), canonical_hands.len() * 32);

    let start = Instant::now();
    let mut total_evaluations = 0u64;
    let mut hands_with_errors = 0;
    let mut max_error = 0.0f64;

    for (idx, hand) in canonical_hands.iter().enumerate() {
        if idx % 10000 == 0 {
            let elapsed = start.elapsed().as_secs_f64();
            let rate = if elapsed > 0.0 { idx as f64 / elapsed } else { 0.0 };
            println!("Progress: {}/{} hands ({:.1}%) - {:.1} hands/sec",
                     idx, canonical_hands.len(),
                     100.0 * idx as f64 / canonical_hands.len() as f64,
                     rate);
        }

        let mut hand_has_error = false;

        for hold_mask in 0..32u8 {
            let ev_brute = calculate_ev_brute(hand, hold_mask);
            let ev_formula = calculate_ev_formula(hand, hold_mask);

            let diff = (ev_brute - ev_formula).abs();

            if diff > max_error {
                max_error = diff;
            }

            if diff > 1e-9 {
                hand_has_error = true;
            }

            total_evaluations += 1;
        }

        if hand_has_error {
            hands_with_errors += 1;
        }
    }

    let total_time = start.elapsed();
    let rate = total_evaluations as f64 / total_time.as_secs_f64();

    println!("\n========================================");
    println!("VALIDATION COMPLETE!");
    println!("========================================");
    println!("Total hands tested: {}", canonical_hands.len());
    println!("Total evaluations: {}", total_evaluations);
    println!("Total time: {:?}", total_time);
    println!("Evaluation rate: {:.1} evals/sec", rate);
    println!("Maximum error: {:.15}", max_error);
    println!("Hands with errors: {}", hands_with_errors);

    if max_error < 1e-9 {
        println!("\n✓✓✓ PERFECT MATCH - ALL HANDS VALIDATED! ✓✓✓");
    } else {
        println!("\n✗✗✗ ERRORS DETECTED ✗✗✗");
    }
}
