use itertools::Itertools;
use rayon::prelude::*;
use serde::Serialize;
use std::collections::HashMap;
use std::io::{self, Write};
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;
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
}

type Hand = [Card; 5];

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum GameType {
    JacksOrBetter,
    DoubleDoubleBonus,
    DeucesWildNSUD,      // Not So Ugly Deuces (25-15-9-4-4-3-2-1)
    DeucesWildFullPay,   // Full Pay Deuces (25-15-9-5-3-2-2-1)
    BonusPoker85,        // Bonus Poker 8/5
    DoubleBonus107,      // Double Bonus 10/7
    TripleDoubleBonus96, // Triple Double Bonus 9/6
    AllAmerican,         // All American 8-8-8-3-1-1
    BonusPokerDeluxe86,  // Bonus Poker Deluxe 8/6
    TensOrBetter65,      // Tens or Better 6/5
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

    // Wheel (A-2-3-4-5)
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

// Count deuces (rank 0 = '2') in hand
fn count_deuces(hand: &[Card]) -> u8 {
    hand.iter().filter(|c| c.rank() == 0).count() as u8
}

// Get non-deuce cards
fn get_non_deuces(hand: &[Card]) -> Vec<Card> {
    hand.iter().filter(|c| c.rank() != 0).cloned().collect()
}

// Check for flush with wild cards
fn is_flush_wild(non_deuces: &[Card]) -> bool {
    if non_deuces.is_empty() { return true; }
    let suit = non_deuces[0].suit();
    non_deuces.iter().all(|c| c.suit() == suit)
}

// Check for straight with wild cards
fn is_straight_wild(non_deuces: &[Card], num_wilds: u8) -> bool {
    if non_deuces.is_empty() { return true; }

    let mut ranks: Vec<u8> = non_deuces.iter().map(|c| c.rank()).collect();
    ranks.sort();
    ranks.dedup(); // Remove duplicates (can't make straight with duplicate non-wilds)

    if ranks.len() + (num_wilds as usize) < 5 { return false; }

    // Check if cards can form a straight with wilds filling gaps
    // Need to check all possible 5-card windows
    for start in 0..=8u8 { // 0-8 for straights starting at 2-T
        let mut needed = 0u8;
        for r in start..start+5 {
            if !ranks.contains(&r) {
                needed += 1;
            }
        }
        if needed <= num_wilds { return true; }
    }

    // Check wheel (A-2-3-4-5) - but 2s are wild, so check A-3-4-5 can be made
    // Ace = rank 12, 3=1, 4=2, 5=3
    let wheel_ranks = [1u8, 2, 3, 12]; // 3, 4, 5, A (2 is wild)
    let mut needed = 0u8;
    for &r in &wheel_ranks {
        if !ranks.contains(&r) {
            needed += 1;
        }
    }
    if needed <= num_wilds { return true; }

    // Check royal (T-J-Q-K-A)
    let royal_ranks = [8u8, 9, 10, 11, 12]; // T, J, Q, K, A
    let mut needed = 0u8;
    for &r in &royal_ranks {
        if !ranks.contains(&r) {
            needed += 1;
        }
    }
    if needed <= num_wilds { return true; }

    false
}

// Check for royal flush with wilds (T-J-Q-K-A of same suit)
fn is_royal_wild(non_deuces: &[Card], num_wilds: u8) -> bool {
    if !is_flush_wild(non_deuces) { return false; }

    let ranks: Vec<u8> = non_deuces.iter().map(|c| c.rank()).collect();
    let royal_ranks = [8u8, 9, 10, 11, 12]; // T, J, Q, K, A

    let mut needed = 0u8;
    for &r in &royal_ranks {
        if !ranks.contains(&r) {
            needed += 1;
        }
    }
    needed <= num_wilds
}

// Evaluate deuces wild hand
fn get_deuces_wild_payout(hand: &[Card], game_type: GameType) -> f64 {
    let num_deuces = count_deuces(hand);
    let non_deuces = get_non_deuces(hand);

    // Get rank counts for non-deuces only
    let mut counts = [0u8; 13];
    for card in &non_deuces {
        counts[card.rank() as usize] += 1;
    }

    let max_count = *counts.iter().max().unwrap_or(&0);
    let num_pairs = counts.iter().filter(|&&c| c == 2).count() as u8;

    let is_flush = is_flush_wild(&non_deuces);
    let is_straight = is_straight_wild(&non_deuces, num_deuces);

    // Natural Royal (no wilds)
    if num_deuces == 0 && is_flush && is_straight {
        let mut ranks: Vec<u8> = non_deuces.iter().map(|c| c.rank()).collect();
        ranks.sort();
        if ranks == vec![8, 9, 10, 11, 12] {
            return 800.0; // Natural Royal Flush
        }
    }

    // Four Deuces
    if num_deuces == 4 {
        return 200.0;
    }

    // Wild Royal Flush
    if is_royal_wild(&non_deuces, num_deuces) && num_deuces > 0 {
        return 25.0;
    }

    // Five of a Kind (4 of same rank + 1 wild, or 3 + 2 wilds, etc.)
    if max_count + num_deuces >= 5 {
        return 15.0;
    }

    // Straight Flush (not royal)
    if is_flush && is_straight && !is_royal_wild(&non_deuces, num_deuces) {
        return 9.0;
    }

    // Four of a Kind
    if max_count + num_deuces >= 4 {
        match game_type {
            GameType::DeucesWildNSUD => return 4.0,
            GameType::DeucesWildFullPay => return 5.0,
            _ => return 4.0,
        }
    }

    // Full House
    if (max_count + num_deuces >= 3) && (num_pairs >= 1 || max_count >= 2) {
        // Need 3 of one rank and 2 of another
        let mut sorted_counts: Vec<u8> = counts.iter().cloned().filter(|&c| c > 0).collect();
        sorted_counts.sort();
        sorted_counts.reverse();

        // Check if we can make full house
        let can_make_full_house = if sorted_counts.len() >= 2 {
            let need_for_trips = 3_u8.saturating_sub(sorted_counts[0]);
            let need_for_pair = 2_u8.saturating_sub(sorted_counts[1]);
            need_for_trips + need_for_pair <= num_deuces
        } else if sorted_counts.len() == 1 {
            // Only one rank, need wilds to make the pair
            sorted_counts[0] + num_deuces >= 5 && sorted_counts[0] >= 2
        } else {
            num_deuces >= 5
        };

        if can_make_full_house && max_count + num_deuces < 4 {
            match game_type {
                GameType::DeucesWildNSUD => return 4.0,
                GameType::DeucesWildFullPay => return 3.0,
                _ => return 3.0,
            }
        }
    }

    // Flush
    if is_flush && !is_straight {
        match game_type {
            GameType::DeucesWildNSUD => return 3.0,
            GameType::DeucesWildFullPay => return 2.0,
            _ => return 2.0,
        }
    }

    // Straight
    if is_straight && !is_flush {
        return 2.0;
    }

    // Three of a Kind
    if max_count + num_deuces >= 3 {
        return 1.0;
    }

    0.0
}

fn get_payout(hand: &[Card], game_type: GameType) -> f64 {
    if hand.len() != 5 { return 0.0; }

    // Route Deuces Wild games to special handler
    match game_type {
        GameType::DeucesWildNSUD | GameType::DeucesWildFullPay => {
            return get_deuces_wild_payout(hand, game_type);
        }
        _ => {}
    }

    let flush = is_flush(hand);
    let straight = is_straight(hand);
    let counts = get_rank_counts(hand);

    // Check for royal flush
    if flush && straight {
        let mut ranks: Vec<u8> = hand.iter().map(|c| c.rank()).collect();
        ranks.sort();
        if ranks == vec![8, 9, 10, 11, 12] {
            return 800.0; // Royal Flush
        }
        return 50.0; // Straight Flush
    }

    // Count pairs, trips, quads and find quad rank
    let mut pairs = 0;
    let mut trips = 0;
    let mut quad_rank: Option<u8> = None;
    let mut pair_ranks: Vec<usize> = Vec::new();

    for (rank, &count) in counts.iter().enumerate() {
        match count {
            2 => { pairs += 1; pair_ranks.push(rank); }
            3 => trips += 1,
            4 => quad_rank = Some(rank as u8),
            _ => {}
        }
    }

    // Four of a kind - handle differently based on game type
    if let Some(qr) = quad_rank {
        match game_type {
            GameType::JacksOrBetter | GameType::TensOrBetter65 => return 25.0,
            GameType::BonusPoker85 => {
                // Bonus Poker: 80 for aces, 40 for 2-4, 25 for 5-K
                if qr == 12 { return 80.0; }      // Four Aces
                if qr <= 2 { return 40.0; }       // Four 2s, 3s, or 4s
                return 25.0;                       // Four 5s-Kings
            }
            GameType::DoubleBonus107 => {
                // Double Bonus: 160 for aces, 80 for 2-4, 50 for 5-K
                if qr == 12 { return 160.0; }     // Four Aces
                if qr <= 2 { return 80.0; }       // Four 2s, 3s, or 4s
                return 50.0;                       // Four 5s-Kings
            }
            GameType::DoubleDoubleBonus => {
                // Find the kicker rank
                let kicker_rank = counts.iter().enumerate()
                    .find(|(r, &c)| c == 1 && *r as u8 != qr)
                    .map(|(r, _)| r as u8)
                    .unwrap_or(0);

                // Ranks: 0=2, 1=3, 2=4, 12=A
                let is_low_kicker = kicker_rank <= 2 || kicker_rank == 12; // 2,3,4 or A

                if qr == 12 { // Four Aces
                    if is_low_kicker { return 400.0; } // Aces with 2-4 kicker
                    return 160.0; // Aces without kicker bonus
                } else if qr <= 2 { // Four 2s, 3s, or 4s
                    if is_low_kicker { return 160.0; } // 2-4 with A-4 kicker
                    return 80.0; // 2-4 without kicker bonus
                } else { // Four 5s through Kings
                    return 50.0;
                }
            }
            GameType::TripleDoubleBonus96 => {
                // Find the kicker rank
                let kicker_rank = counts.iter().enumerate()
                    .find(|(r, &c)| c == 1 && *r as u8 != qr)
                    .map(|(r, _)| r as u8)
                    .unwrap_or(0);

                // Ranks: 0=2, 1=3, 2=4, 12=A
                let is_low_kicker = kicker_rank <= 2 || kicker_rank == 12; // 2,3,4 or A

                if qr == 12 { // Four Aces
                    if is_low_kicker { return 800.0; } // Aces with 2-4 kicker (4000 for max bet)
                    return 160.0; // Aces without kicker bonus
                } else if qr <= 2 { // Four 2s, 3s, or 4s
                    if is_low_kicker { return 160.0; } // 2-4 with A-4 kicker
                    return 80.0; // 2-4 without kicker bonus
                } else { // Four 5s through Kings
                    return 50.0;
                }
            }
            GameType::AllAmerican => return 40.0, // All quads pay 40
            GameType::BonusPokerDeluxe86 => return 80.0, // All quads pay 80
            _ => return 25.0,
        }
    }

    // Full House
    if trips > 0 && pairs > 0 {
        return match game_type {
            GameType::JacksOrBetter | GameType::TensOrBetter65 => 9.0,
            GameType::BonusPoker85 => 8.0,
            GameType::DoubleBonus107 => 10.0,
            GameType::DoubleDoubleBonus | GameType::TripleDoubleBonus96 => 9.0,
            GameType::AllAmerican => 8.0,
            GameType::BonusPokerDeluxe86 => 8.0,
            _ => 9.0,
        };
    }

    // Flush
    if flush {
        return match game_type {
            GameType::JacksOrBetter | GameType::TensOrBetter65 => 6.0,
            GameType::BonusPoker85 => 5.0,
            GameType::DoubleBonus107 => 7.0,
            GameType::DoubleDoubleBonus | GameType::TripleDoubleBonus96 => 6.0,
            GameType::AllAmerican => 8.0, // All American pays 8 for flush
            GameType::BonusPokerDeluxe86 => 6.0,
            _ => 6.0,
        };
    }

    // Straight
    if straight {
        return match game_type {
            GameType::JacksOrBetter | GameType::TensOrBetter65 => 4.0,
            GameType::BonusPoker85 => 4.0,
            GameType::DoubleBonus107 => 5.0,
            GameType::DoubleDoubleBonus | GameType::TripleDoubleBonus96 => 4.0,
            GameType::AllAmerican => 8.0, // All American pays 8 for straight
            GameType::BonusPokerDeluxe86 => 4.0,
            _ => 4.0,
        };
    }

    // Three of a Kind
    if trips > 0 {
        return match game_type {
            GameType::JacksOrBetter | GameType::TensOrBetter65 => 3.0,
            GameType::BonusPoker85 => 3.0,
            GameType::DoubleBonus107 => 3.0,
            GameType::DoubleDoubleBonus | GameType::TripleDoubleBonus96 => 3.0,
            GameType::AllAmerican => 3.0,
            GameType::BonusPokerDeluxe86 => 3.0,
            _ => 3.0,
        };
    }

    // Two Pair
    if pairs == 2 {
        return match game_type {
            GameType::JacksOrBetter | GameType::TensOrBetter65 => 2.0,
            GameType::BonusPoker85 => 2.0,
            GameType::DoubleBonus107 => 1.0,    // Double Bonus pays 1 for two pair
            GameType::DoubleDoubleBonus | GameType::TripleDoubleBonus96 => 1.0, // DDB/TDB pays 1 for two pair
            GameType::AllAmerican => 1.0,
            GameType::BonusPokerDeluxe86 => 1.0,
            _ => 2.0,
        };
    }

    // High pair (Jacks or Better for most games, Tens or Better for TOB)
    if pairs == 1 {
        let pair_rank = pair_ranks[0];
        match game_type {
            GameType::TensOrBetter65 => {
                // Tens or better: T=8, J=9, Q=10, K=11, A=12
                if pair_rank >= 8 {
                    return 1.0;
                }
            }
            _ => {
                // J=9, Q=10, K=11, A=12
                if pair_rank >= 9 {
                    return 1.0;
                }
            }
        }
    }

    0.0
}

fn calculate_hold_ev(hand: &Hand, hold_mask: u8, game_type: GameType) -> f64 {
    // Get held cards
    let mut held: Vec<Card> = Vec::with_capacity(5);
    for i in 0..5 {
        if hold_mask & (1 << i) != 0 {
            held.push(hand[i]);
        }
    }

    let num_to_draw = 5 - held.len();

    if num_to_draw == 0 {
        let final_hand: [Card; 5] = held.try_into().unwrap();
        return get_payout(&final_hand, game_type);
    }

    // Build remaining deck (47 cards)
    let mut deck: Vec<Card> = Vec::with_capacity(47);
    for card_idx in 0..52u8 {
        let card = Card(card_idx);
        if !hand.contains(&card) {
            deck.push(card);
        }
    }

    // Calculate EV by iterating through all draw combinations
    let mut total_payout = 0.0;
    let mut count = 0u64;

    for draw in deck.iter().combinations(num_to_draw) {
        let mut final_hand = held.clone();
        for &card in &draw {
            final_hand.push(*card);
        }
        let final_arr: [Card; 5] = final_hand.try_into().unwrap();
        total_payout += get_payout(&final_arr, game_type);
        count += 1;
    }

    total_payout / count as f64
}

fn analyze_hand(hand: &Hand, game_type: GameType) -> (u8, f64, HashMap<String, f64>) {
    let mut hold_evs: HashMap<String, f64> = HashMap::new();
    let mut best_hold = 0u8;
    let mut best_ev = f64::NEG_INFINITY;

    for hold_mask in 0..32u8 {
        let ev = calculate_hold_ev(hand, hold_mask, game_type);
        hold_evs.insert(hold_mask.to_string(), (ev * 1000000.0).round() / 1000000.0);
        if ev > best_ev {
            best_ev = ev;
            best_hold = hold_mask;
        }
    }

    (best_hold, (best_ev * 1000000.0).round() / 1000000.0, hold_evs)
}

fn hand_to_canonical_key(hand: &Hand) -> String {
    // Sort by rank
    let mut sorted: Vec<Card> = hand.to_vec();
    sorted.sort_by_key(|c| c.rank());

    // Map suits to a, b, c, d in order of first appearance
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

fn generate_canonical_hands() -> Vec<(String, Hand)> {
    println!("Generating canonical hands...");
    let mut seen: HashMap<String, Hand> = HashMap::new();
    let mut processed = 0u64;

    for c1 in 0..48u8 {
        for c2 in (c1 + 1)..49 {
            for c3 in (c2 + 1)..50 {
                for c4 in (c3 + 1)..51 {
                    for c5 in (c4 + 1)..52 {
                        let hand: Hand = [Card(c1), Card(c2), Card(c3), Card(c4), Card(c5)];
                        let key = hand_to_canonical_key(&hand);
                        seen.entry(key).or_insert(hand);

                        processed += 1;
                        if processed % 500000 == 0 {
                            println!("  {} processed, {} unique", processed, seen.len());
                        }
                    }
                }
            }
        }
    }

    println!("Found {} canonical hands", seen.len());
    seen.into_iter().collect()
}

#[derive(Serialize)]
struct StrategyRow {
    paytable_id: String,
    hand_key: String,
    best_hold: u8,
    best_ev: f64,
    hold_evs: HashMap<String, f64>,
}

fn upload_batch(client: &reqwest::blocking::Client, batch: &[StrategyRow], supabase_url: &str, service_key: &str) -> Result<(), String> {
    let url = format!("{}/rest/v1/strategy", supabase_url);

    let response = client
        .post(&url)
        .header("apikey", service_key)
        .header("Authorization", format!("Bearer {}", service_key))
        .header("Content-Type", "application/json")
        .header("Prefer", "resolution=merge-duplicates")
        .timeout(std::time::Duration::from_secs(60))
        .json(batch)
        .send()
        .map_err(|e| format!("Request error: {}", e))?;

    if !response.status().is_success() {
        let status = response.status();
        let body = response.text().unwrap_or_default();
        return Err(format!("Upload failed: {} - {}", status, body));
    }

    Ok(())
}

fn main() {
    dotenv::from_path("../../.env").ok();

    let supabase_url = std::env::var("SUPABASE_URL").expect("SUPABASE_URL not set");
    let service_key = std::env::var("SUPABASE_SERVICE_KEY").expect("SUPABASE_SERVICE_KEY not set");
    let paytable_id = std::env::args().nth(1).unwrap_or_else(|| "jacks-or-better-9-6".to_string());

    let game_type = match paytable_id.as_str() {
        "jacks-or-better-9-6" => GameType::JacksOrBetter,
        "double-double-bonus-9-6" => GameType::DoubleDoubleBonus,
        "deuces-wild-nsud" => GameType::DeucesWildNSUD,
        "deuces-wild-full-pay" => GameType::DeucesWildFullPay,
        "bonus-poker-8-5" => GameType::BonusPoker85,
        "double-bonus-10-7" => GameType::DoubleBonus107,
        "triple-double-bonus-9-6" => GameType::TripleDoubleBonus96,
        "all-american" => GameType::AllAmerican,
        "bonus-poker-deluxe-8-6" => GameType::BonusPokerDeluxe86,
        "tens-or-better-6-5" => GameType::TensOrBetter65,
        _ => {
            eprintln!("Unknown paytable: {}", paytable_id);
            eprintln!("Available paytables:");
            eprintln!("  jacks-or-better-9-6");
            eprintln!("  double-double-bonus-9-6");
            eprintln!("  deuces-wild-nsud");
            eprintln!("  deuces-wild-full-pay");
            eprintln!("  bonus-poker-8-5");
            eprintln!("  double-bonus-10-7");
            eprintln!("  triple-double-bonus-9-6");
            eprintln!("  all-american");
            eprintln!("  bonus-poker-deluxe-8-6");
            eprintln!("  tens-or-better-6-5");
            std::process::exit(1);
        }
    };

    println!("=== Rust Video Poker Strategy Calculator ===\n");
    println!("Paytable: {}", paytable_id);

    let start = Instant::now();

    // Generate canonical hands
    let hands = generate_canonical_hands();
    let total = hands.len();

    println!("\nCalculating EVs using {} threads...", rayon::current_num_threads());
    io::stdout().flush().unwrap();

    let processed = Arc::new(AtomicUsize::new(0));
    let uploaded = Arc::new(AtomicUsize::new(0));
    let errors = Arc::new(AtomicUsize::new(0));

    // Create HTTP client once - it's thread-safe
    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(60))
        .build()
        .expect("Failed to create HTTP client");

    // Process in chunks for batch uploading
    let chunk_size = 500;
    let print_every = 5000; // Print progress every N hands

    // Process chunks sequentially (upload) but analyze in parallel within each chunk
    let mut batch_num = 0;
    for chunk in hands.chunks(chunk_size) {
        batch_num += 1;
        // Parallel analysis within the chunk
        let batch: Vec<StrategyRow> = chunk
            .par_iter()
            .map(|(key, hand)| {
                let (best_hold, best_ev, hold_evs) = analyze_hand(hand, game_type);
                StrategyRow {
                    paytable_id: paytable_id.clone(),
                    hand_key: key.clone(),
                    best_hold,
                    best_ev,
                    hold_evs,
                }
            })
            .collect();

        let count = batch.len();
        processed.fetch_add(count, Ordering::Relaxed);

        // Upload batch
        if let Err(e) = upload_batch(&client, &batch, &supabase_url, &service_key) {
            eprintln!("\nUpload error: {}", e);
            errors.fetch_add(1, Ordering::Relaxed);
        } else {
            uploaded.fetch_add(count, Ordering::Relaxed);
        }

        let p = processed.load(Ordering::Relaxed);
        let u = uploaded.load(Ordering::Relaxed);

        // Print progress periodically
        if batch_num % 10 == 0 {
            let pct = (p as f64 / total as f64 * 100.0) as u32;
            println!("  Progress: {}/{} ({}%) | Uploaded: {}", p, total, pct, u);
            io::stdout().flush().unwrap();
        }
    }

    let elapsed = start.elapsed();
    let final_uploaded = uploaded.load(Ordering::Relaxed);
    let final_errors = errors.load(Ordering::Relaxed);

    println!("\n=== Completed ===");
    println!("Time: {:.1}s", elapsed.as_secs_f64());
    println!("Uploaded: {} hands", final_uploaded);
    if final_errors > 0 {
        println!("Errors: {} batches failed", final_errors);
    }
    io::stdout().flush().unwrap();
}
