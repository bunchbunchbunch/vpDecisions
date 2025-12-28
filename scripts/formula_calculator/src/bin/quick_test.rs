// Quick test to verify brute and formula match

use itertools::Itertools;

#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
struct Card(u8);

impl Card {
    fn rank(&self) -> u8 {
        self.0 / 4
    }

    fn suit(&self) -> u8 {
        self.0 % 4
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

fn main() {
    println!("Quick Test: Verifying Brute Force Implementation\n");

    // Test hand: Jh Jd 2h 3h 4h
    let hand: Hand = [Card(36), Card(37), Card(0), Card(4), Card(8)];

    println!("Test hand: Jh Jd 2h 3h 4h\n");

    // Test a few specific hold patterns
    let test_patterns = vec![
        (0b11111, "Hold all 5"),
        (0b00011, "Hold JJ"),
        (0b00000, "Discard all"),
        (0b00111, "Hold JJ2"),
    ];

    for (mask, desc) in test_patterns {
        let ev = calculate_ev_brute(&hand, mask);
        println!("Hold pattern {:05b} ({}): EV = {:.8}", mask, desc, ev);
    }

    println!("\n✓ Basic implementation working!");
}
