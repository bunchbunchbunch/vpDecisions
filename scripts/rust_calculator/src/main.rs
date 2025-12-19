use itertools::Itertools;
use rayon::prelude::*;
use serde::Serialize;
use std::collections::HashMap;
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

fn get_payout(hand: &[Card], game_type: GameType) -> f64 {
    if hand.len() != 5 { return 0.0; }

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
    let mut pair_rank = 0;

    for (rank, &count) in counts.iter().enumerate() {
        match count {
            2 => { pairs += 1; pair_rank = rank; }
            3 => trips += 1,
            4 => quad_rank = Some(rank as u8),
            _ => {}
        }
    }

    // Four of a kind - handle differently based on game type
    if let Some(qr) = quad_rank {
        match game_type {
            GameType::JacksOrBetter => return 25.0,
            GameType::DoubleDoubleBonus => {
                // Find the kicker rank
                let kicker_rank = counts.iter().enumerate()
                    .find(|(r, &c)| c == 1 && *r as u8 != qr)
                    .map(|(r, _)| r as u8)
                    .unwrap_or(0);

                // Ranks: 0=2, 1=3, 2=4, 12=A
                let is_ace_kicker = kicker_rank == 12;
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
        }
    }

    if trips > 0 && pairs > 0 {
        return match game_type {
            GameType::JacksOrBetter => 9.0,
            GameType::DoubleDoubleBonus => 9.0,
        };
    }

    if flush {
        return match game_type {
            GameType::JacksOrBetter => 6.0,
            GameType::DoubleDoubleBonus => 6.0,
        };
    }

    if straight {
        return match game_type {
            GameType::JacksOrBetter => 4.0,
            GameType::DoubleDoubleBonus => 4.0,
        };
    }

    if trips > 0 {
        return match game_type {
            GameType::JacksOrBetter => 3.0,
            GameType::DoubleDoubleBonus => 3.0,
        };
    }

    if pairs == 2 {
        return match game_type {
            GameType::JacksOrBetter => 2.0,
            GameType::DoubleDoubleBonus => 1.0, // DDB pays 1 for two pair
        };
    }

    if pairs == 1 {
        // Jacks or better: J=9, Q=10, K=11, A=12
        if pair_rank >= 9 {
            return 1.0;
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

fn upload_batch(batch: &[StrategyRow], supabase_url: &str, service_key: &str) -> Result<(), String> {
    let client = reqwest::blocking::Client::new();
    let url = format!("{}/rest/v1/strategy", supabase_url);

    let response = client
        .post(&url)
        .header("apikey", service_key)
        .header("Authorization", format!("Bearer {}", service_key))
        .header("Content-Type", "application/json")
        .header("Prefer", "resolution=merge-duplicates")
        .json(batch)
        .send()
        .map_err(|e| e.to_string())?;

    if !response.status().is_success() {
        return Err(format!("Upload failed: {}", response.status()));
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
        _ => {
            eprintln!("Unknown paytable: {}. Use 'jacks-or-better-9-6' or 'double-double-bonus-9-6'", paytable_id);
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

    let processed = Arc::new(AtomicUsize::new(0));
    let uploaded = Arc::new(AtomicUsize::new(0));

    // Process in chunks for batch uploading
    let chunk_size = 500;

    hands.par_chunks(chunk_size).for_each(|chunk| {
        let batch: Vec<StrategyRow> = chunk
            .iter()
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
        if let Err(e) = upload_batch(&batch, &supabase_url, &service_key) {
            eprintln!("Upload error: {}", e);
        } else {
            uploaded.fetch_add(count, Ordering::Relaxed);
        }

        let p = processed.load(Ordering::Relaxed);
        let u = uploaded.load(Ordering::Relaxed);
        println!("  Calculated: {}/{} | Uploaded: {}", p, total, u);
    });

    let elapsed = start.elapsed();
    println!("\nCompleted in {:.1}s", elapsed.as_secs_f64());
    println!("Uploaded {} hands", uploaded.load(Ordering::Relaxed));
}
