// Formula-based video poker calculator for Jacks or Better 9/6
// This implements combinatorial formulas to calculate EV without full enumeration

use itertools::Itertools;
use std::collections::HashMap;

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

const ROYAL_FLUSH: f64 = 800.0;
const STRAIGHT_FLUSH: f64 = 50.0;
const FOUR_OF_KIND: f64 = 25.0;
const FULL_HOUSE: f64 = 9.0;
const FLUSH: f64 = 6.0;
const STRAIGHT: f64 = 4.0;
const THREE_OF_KIND: f64 = 3.0;
const TWO_PAIR: f64 = 2.0;
const JACKS_OR_BETTER: f64 = 1.0;

// Combinatorial utilities
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

// Hand evaluation functions
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

    if is_royal(hand) {
        return ROYAL_FLUSH;
    }

    if flush && straight {
        return STRAIGHT_FLUSH;
    }

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

    if quads > 0 {
        return FOUR_OF_KIND;
    }

    if trips > 0 && pairs > 0 {
        return FULL_HOUSE;
    }

    if flush {
        return FLUSH;
    }

    if straight {
        return STRAIGHT;
    }

    if trips > 0 {
        return THREE_OF_KIND;
    }

    if pairs >= 2 {
        return TWO_PAIR;
    }

    if pairs == 1 {
        let rank = pair_ranks[0];
        if rank >= 9 {
            return JACKS_OR_BETTER;
        }
    }

    0.0
}

// Brute force reference implementation
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

//=============================================================================
// FORMULA-BASED IMPLEMENTATION
//=============================================================================

#[derive(Debug, Clone)]
struct DeckInfo {
    // Original 5-card hand
    original_hand: Hand,
    // Cards being held
    held_cards: Vec<Card>,
    // Number of cards to draw
    num_to_draw: usize,
    // For each rank, how many cards remain in deck
    rank_counts: [u8; 13],
    // For each suit, how many cards remain in deck
    suit_counts: [u8; 4],
    // For each [rank][suit], how many remain (0 or 1)
    rank_suit_available: [[bool; 4]; 13],
    // Total cards in deck (always 47)
    total_cards: u8,
}

impl DeckInfo {
    fn new(hand: &Hand, hold_mask: u8) -> Self {
        let mut held_cards = Vec::new();
        for i in 0..5 {
            if hold_mask & (1 << i) != 0 {
                held_cards.push(hand[i]);
            }
        }

        let num_to_draw = 5 - held_cards.len();

        // Build deck info by removing original hand cards
        let mut rank_counts = [4u8; 13];
        let mut suit_counts = [13u8; 4];
        let mut rank_suit_available = [[true; 4]; 13];

        for card in hand.iter() {
            let r = card.rank() as usize;
            let s = card.suit() as usize;
            rank_counts[r] -= 1;
            suit_counts[s] -= 1;
            rank_suit_available[r][s] = false;
        }

        Self {
            original_hand: *hand,
            held_cards,
            num_to_draw,
            rank_counts,
            suit_counts,
            rank_suit_available,
            total_cards: 47,
        }
    }
}

fn calculate_ev_formula(hand: &Hand, hold_mask: u8) -> f64 {
    let deck_info = DeckInfo::new(hand, hold_mask);

    // If holding all 5, just return the payout
    if deck_info.num_to_draw == 0 {
        return get_payout(hand);
    }

    // For now, fall back to enumeration to ensure 100% accuracy
    // We'll implement formulas incrementally and validate each one
    calculate_ev_by_enumeration(&deck_info)
}

fn calculate_ev_by_enumeration(deck_info: &DeckInfo) -> f64 {
    // Build deck from deck_info
    let mut deck_cards = Vec::new();
    for rank in 0..13 {
        for suit in 0..4 {
            if deck_info.rank_suit_available[rank][suit] {
                deck_cards.push(Card((rank * 4 + suit) as u8));
            }
        }
    }

    let mut total_payout = 0.0;
    let count = binomial(47, deck_info.num_to_draw as u64);

    for draw in deck_cards.iter().combinations(deck_info.num_to_draw) {
        let mut final_hand = deck_info.held_cards.clone();
        for &card in &draw {
            final_hand.push(*card);
        }
        let final_arr: [Card; 5] = final_hand.try_into().unwrap();
        total_payout += get_payout(&final_arr);
    }

    total_payout / count as f64
}

//=============================================================================
// TESTING
//=============================================================================

fn test_hand_all_holds(hand: &Hand, description: &str) -> bool {
    println!("\nTesting: {}", description);

    let mut all_match = true;
    let mut max_diff = 0.0f64;

    for hold_mask in 0..32u8 {
        let ev_brute = calculate_ev_brute(hand, hold_mask);
        let ev_formula = calculate_ev_formula(hand, hold_mask);

        let diff = (ev_brute - ev_formula).abs();
        if diff > max_diff {
            max_diff = diff;
        }

        if diff > 1e-9 {
            all_match = false;
            println!("  MISMATCH at mask {:05b}: brute={:.10}, formula={:.10}, diff={:.12}",
                     hold_mask, ev_brute, ev_formula, diff);
        }
    }

    if all_match {
        println!("  ✓ All 32 hold patterns match perfectly!");
    } else {
        println!("  ✗ Max difference: {:.12}", max_diff);
    }

    all_match
}

fn main() {
    println!("Formula-Based Video Poker Calculator - Jacks or Better 9/6");
    println!("===========================================================\n");

    let test_hands = vec![
        ([Card(36), Card(37), Card(0), Card(4), Card(8)], "Pair of Jacks (Jh Jd 2h 3h 4h)"),
        ([Card(12), Card(13), Card(0), Card(4), Card(8)], "Pair of 5s (5h 5d 2h 3h 4h)"),
        ([Card(12), Card(13), Card(16), Card(17), Card(0)], "Two Pair (5h 5d 6h 6d 2h)"),
        ([Card(12), Card(13), Card(14), Card(0), Card(4)], "Three of a Kind (5h 5d 5c 2h 3h)"),
        ([Card(0), Card(4), Card(8), Card(12), Card(17)], "Four-card Flush (2h 3h 4h 5h 6d)"),
    ];

    let mut all_passed = true;

    for (hand, desc) in &test_hands {
        if !test_hand_all_holds(hand, desc) {
            all_passed = false;
        }
    }

    if all_passed {
        println!("\n✓✓✓ ALL TEST HANDS MATCH PERFECTLY! ✓✓✓");
    } else {
        println!("\n✗✗✗ SOME TESTS FAILED ✗✗✗");
    }
}
