use chrono::Utc;
use flate2::write::GzEncoder;
use flate2::Compression;
use itertools::Itertools;
use rayon::prelude::*;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::io::{self, Write};
use std::path::Path;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;
use std::time::Instant;

// Card representation: 0-51 (rank * 4 + suit)
// Ranks: 0=2, 1=3, 2=4, 3=5, 4=6, 5=7, 6=8, 7=9, 8=T, 9=J, 10=Q, 11=K, 12=A
// Suits: 0=hearts, 1=diamonds, 2=clubs, 3=spades
// For Joker Poker: Card 52 = Joker

#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
struct Card(u8);

impl Card {
    fn rank(&self) -> u8 {
        if self.0 == 52 { return 255; } // Joker has no rank
        self.0 / 4
    }

    fn suit(&self) -> u8 {
        if self.0 == 52 { return 255; } // Joker has no suit
        self.0 % 4
    }

    fn is_joker(&self) -> bool {
        self.0 == 52
    }

    fn rank_char(&self) -> char {
        match self.rank() {
            0 => '2', 1 => '3', 2 => '4', 3 => '5', 4 => '6',
            5 => '7', 6 => '8', 7 => '9', 8 => 'T',
            9 => 'J', 10 => 'Q', 11 => 'K', 12 => 'A',
            255 => 'W', // Joker/Wild
            _ => '?'
        }
    }
}

type Hand = [Card; 5];

// ============================================================================
// PAYTABLE CONFIGURATION
// ============================================================================

#[derive(Clone, Debug)]
struct Paytable {
    id: String,
    name: String,
    game_family: GameFamily,
    // Standard payouts (multiply by bet)
    royal_flush: f64,
    straight_flush: f64,
    four_of_a_kind: f64,      // Default 4K payout (used if no special bonuses)
    full_house: f64,
    flush: f64,
    straight: f64,
    three_of_a_kind: f64,
    two_pair: f64,
    high_pair: f64,           // Jacks+, Kings+, Tens+, etc.
    // Bonus quad payouts (for bonus poker variants)
    four_aces: Option<f64>,
    four_2_4: Option<f64>,    // Four 2s, 3s, or 4s
    four_5_k: Option<f64>,    // Four 5s through Kings
    four_jqk: Option<f64>,    // Four Jacks, Queens, or Kings (Aces and Faces, Super Double Bonus)
    four_8s: Option<f64>,     // Four 8s (Aces and Eights)
    four_7s: Option<f64>,     // Four 7s (Aces and Eights)
    // Kicker bonus payouts (for DDB, TDB)
    four_aces_with_kicker: Option<f64>,   // 4 Aces with 2-4 kicker
    four_2_4_with_kicker: Option<f64>,    // 4 2-4 with A-4 kicker
    // Face kicker bonus payouts (for Double Jackpot, Double Double Jackpot)
    four_aces_with_face: Option<f64>,     // 4 Aces with J/Q/K kicker
    four_jqk_with_face: Option<f64>,      // 4 J/Q/K with J/Q/K/A kicker
    // Deuces Wild specific
    four_deuces: Option<f64>,
    wild_royal: Option<f64>,
    five_of_a_kind: Option<f64>,
    // Joker Poker specific (uses wild_royal, five_of_a_kind from above)
    // Minimum winning hand
    min_pair_rank: u8,        // 9=Jacks, 8=Tens, 11=Kings, 0=Two Pair minimum
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum GameFamily {
    // Standard 52-card games
    JacksOrBetter,
    TensOrBetter,
    BonusPoker,
    BonusPokerDeluxe,
    Doublebonus,
    SuperDoubleBonus,
    DoubleDoubleBonus,
    TripleDoubleBonus,
    WhiteHotAces,
    AcesAndFaces,
    AcesAndEights,
    TripleBonus,
    SuperAces,
    BonusPokerPlus,
    DoubleJackpot,
    DoubleDoubleJackpot,
    SuperDoubleDoubleBonus,
    TripleBonusPlus,
    AllAmerican,
    // Wild card games (52-card with deuces wild)
    DeucesWild,
    LooseDeuces,
    DoubleDeuces,
    TripleDeuces,
    DeucesWildBonusPoker,
    DoubleBonusDeucesWild,
    SuperBonusDeucesWild,
    DeluxeDeucesWild,
    // Joker games (53-card deck)
    JokerPokerKings,
    JokerPokerTwoPair,
    DoubleJoker,
    // Additional game families from comprehensive paytables
    TripleTripleBonus,        // TTB
    RoyalAcesBonus,           // RAB
    AcesBonus,                // Ace$ (A-c-e-s Bonus)
    BonusAcesAndFaces,        // BPAF
    DDBonusAcesAndFaces,      // DDBAF
    DoubleDoubleBonusPlus,    // DDB+
    DeucesWild44,             // DW44 (different payouts)
    DeucesJokerWild,          // DJW (deuces + joker wild)
}

impl Paytable {
    fn is_deuces_wild(&self) -> bool {
        matches!(self.game_family,
            GameFamily::DeucesWild | GameFamily::LooseDeuces |
            GameFamily::DoubleDeuces | GameFamily::TripleDeuces |
            GameFamily::DeucesWildBonusPoker | GameFamily::DoubleBonusDeucesWild |
            GameFamily::SuperBonusDeucesWild | GameFamily::DeluxeDeucesWild |
            GameFamily::DeucesWild44 | GameFamily::DeucesJokerWild)
    }

    fn is_joker_poker(&self) -> bool {
        matches!(self.game_family,
            GameFamily::JokerPokerKings | GameFamily::JokerPokerTwoPair |
            GameFamily::DoubleJoker | GameFamily::DeucesJokerWild)
    }

    fn has_kicker_bonus(&self) -> bool {
        self.four_aces_with_kicker.is_some()
    }

    fn has_face_kicker_bonus(&self) -> bool {
        self.four_aces_with_face.is_some()
    }
}

// ============================================================================
// PAYTABLE DEFINITIONS
// ============================================================================

fn get_paytable(id: &str) -> Option<Paytable> {
    match id {
        // ====== JACKS OR BETTER ======
        "jacks-or-better-9-6" => Some(Paytable {
            id: id.to_string(),
            name: "Jacks or Better 9/6".to_string(),
            game_family: GameFamily::JacksOrBetter,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 9.0, flush: 6.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "jacks-or-better-9-5" => Some(Paytable {
            id: id.to_string(),
            name: "Jacks or Better 9/5".to_string(),
            game_family: GameFamily::JacksOrBetter,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 9.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "jacks-or-better-8-6" => Some(Paytable {
            id: id.to_string(),
            name: "Jacks or Better 8/6".to_string(),
            game_family: GameFamily::JacksOrBetter,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 8.0, flush: 6.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "jacks-or-better-8-5" => Some(Paytable {
            id: id.to_string(),
            name: "Jacks or Better 8/5".to_string(),
            game_family: GameFamily::JacksOrBetter,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 8.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "jacks-or-better-7-5" => Some(Paytable {
            id: id.to_string(),
            name: "Jacks or Better 7/5".to_string(),
            game_family: GameFamily::JacksOrBetter,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 7.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "jacks-or-better-6-5" => Some(Paytable {
            id: id.to_string(),
            name: "Jacks or Better 6/5".to_string(),
            game_family: GameFamily::JacksOrBetter,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 6.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // Additional JoB variants from comprehensive paytable list
        "jacks-or-better-9-6-90" => Some(Paytable {
            id: id.to_string(),
            name: "Jacks or Better 9/6/90 (100%)".to_string(),
            game_family: GameFamily::JacksOrBetter,
            royal_flush: 800.0, straight_flush: 90.0, four_of_a_kind: 25.0,
            full_house: 9.0, flush: 6.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "jacks-or-better-9-6-940" => Some(Paytable {
            id: id.to_string(),
            name: "Jacks or Better 9/6 RF940 (99.90%)".to_string(),
            game_family: GameFamily::JacksOrBetter,
            royal_flush: 940.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 9.0, flush: 6.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "jacks-or-better-8-5-35" => Some(Paytable {
            id: id.to_string(),
            name: "Jacks or Better 8/5 4K35 (99.66%)".to_string(),
            game_family: GameFamily::JacksOrBetter,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 35.0,
            full_house: 8.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // ====== TENS OR BETTER ======
        "tens-or-better-6-5" => Some(Paytable {
            id: id.to_string(),
            name: "Tens or Better 6/5".to_string(),
            game_family: GameFamily::TensOrBetter,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 6.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 8,
        }),

        // ====== BONUS POKER ======
        "bonus-poker-8-5" => Some(Paytable {
            id: id.to_string(),
            name: "Bonus Poker 8/5".to_string(),
            game_family: GameFamily::BonusPoker,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 8.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: Some(80.0), four_2_4: Some(40.0), four_5_k: Some(25.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "bonus-poker-7-5" => Some(Paytable {
            id: id.to_string(),
            name: "Bonus Poker 7/5".to_string(),
            game_family: GameFamily::BonusPoker,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 7.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: Some(80.0), four_2_4: Some(40.0), four_5_k: Some(25.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "bonus-poker-6-5" => Some(Paytable {
            id: id.to_string(),
            name: "Bonus Poker 6/5".to_string(),
            game_family: GameFamily::BonusPoker,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 6.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: Some(80.0), four_2_4: Some(40.0), four_5_k: Some(25.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // Additional Bonus Poker variants
        "bonus-poker-7-5-1200" => Some(Paytable {
            id: id.to_string(),
            name: "Bonus Poker 7/5 RF1200 (99.09%)".to_string(),
            game_family: GameFamily::BonusPoker,
            royal_flush: 1200.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 7.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: Some(80.0), four_2_4: Some(40.0), four_5_k: Some(25.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // ====== BONUS POKER DELUXE ======
        "bonus-poker-deluxe-9-6" => Some(Paytable {
            id: id.to_string(),
            name: "Bonus Poker Deluxe 9/6".to_string(),
            game_family: GameFamily::BonusPokerDeluxe,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 80.0,
            full_house: 9.0, flush: 6.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "bonus-poker-deluxe-8-6" => Some(Paytable {
            id: id.to_string(),
            name: "Bonus Poker Deluxe 8/6".to_string(),
            game_family: GameFamily::BonusPokerDeluxe,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 80.0,
            full_house: 8.0, flush: 6.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "bonus-poker-deluxe-8-5" => Some(Paytable {
            id: id.to_string(),
            name: "Bonus Poker Deluxe 8/5".to_string(),
            game_family: GameFamily::BonusPokerDeluxe,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 80.0,
            full_house: 8.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "bonus-poker-deluxe-7-5" => Some(Paytable {
            id: id.to_string(),
            name: "Bonus Poker Deluxe 7/5".to_string(),
            game_family: GameFamily::BonusPokerDeluxe,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 80.0,
            full_house: 7.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "bonus-poker-deluxe-6-5" => Some(Paytable {
            id: id.to_string(),
            name: "Bonus Poker Deluxe 6/5".to_string(),
            game_family: GameFamily::BonusPokerDeluxe,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 80.0,
            full_house: 6.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // ====== ACES AND FACES ======
        "aces-and-faces-8-5" => Some(Paytable {
            id: id.to_string(),
            name: "Aces and Faces 8/5".to_string(),
            game_family: GameFamily::AcesAndFaces,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 8.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: Some(80.0), four_2_4: None, four_5_k: None, four_jqk: Some(40.0),
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "aces-and-faces-7-6" => Some(Paytable {
            id: id.to_string(),
            name: "Aces and Faces 7/6".to_string(),
            game_family: GameFamily::AcesAndFaces,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 7.0, flush: 6.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: Some(80.0), four_2_4: None, four_5_k: None, four_jqk: Some(40.0),
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "aces-and-faces-7-5" => Some(Paytable {
            id: id.to_string(),
            name: "Aces and Faces 7/5".to_string(),
            game_family: GameFamily::AcesAndFaces,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 7.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: Some(80.0), four_2_4: None, four_5_k: None, four_jqk: Some(40.0),
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "aces-and-faces-6-5" => Some(Paytable {
            id: id.to_string(),
            name: "Aces and Faces 6/5".to_string(),
            game_family: GameFamily::AcesAndFaces,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 6.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: Some(80.0), four_2_4: None, four_5_k: None, four_jqk: Some(40.0),
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // ====== ACES AND EIGHTS ======
        "aces-and-eights-8-5" => Some(Paytable {
            id: id.to_string(),
            name: "Aces and Eights 8/5".to_string(),
            game_family: GameFamily::AcesAndEights,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 8.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: Some(80.0), four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: Some(80.0), four_7s: Some(50.0),
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "aces-and-eights-7-5" => Some(Paytable {
            id: id.to_string(),
            name: "Aces and Eights 7/5".to_string(),
            game_family: GameFamily::AcesAndEights,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 7.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: Some(80.0), four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: Some(80.0), four_7s: Some(50.0),
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // ====== TRIPLE BONUS ======
        "triple-bonus-9-5" => Some(Paytable {
            id: id.to_string(),
            name: "Triple Bonus 9/5".to_string(),
            game_family: GameFamily::TripleBonus,
            royal_flush: 800.0, straight_flush: 100.0, four_of_a_kind: 75.0,
            full_house: 9.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(240.0), four_2_4: Some(120.0), four_5_k: Some(75.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 11, // Kings or Better
        }),
        "triple-bonus-8-5" => Some(Paytable {
            id: id.to_string(),
            name: "Triple Bonus 8/5".to_string(),
            game_family: GameFamily::TripleBonus,
            royal_flush: 800.0, straight_flush: 100.0, four_of_a_kind: 75.0,
            full_house: 8.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(240.0), four_2_4: Some(120.0), four_5_k: Some(75.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 11, // Kings or Better
        }),
        "triple-bonus-7-5" => Some(Paytable {
            id: id.to_string(),
            name: "Triple Bonus 7/5".to_string(),
            game_family: GameFamily::TripleBonus,
            royal_flush: 800.0, straight_flush: 100.0, four_of_a_kind: 75.0,
            full_house: 7.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(240.0), four_2_4: Some(120.0), four_5_k: Some(75.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 11, // Kings or Better
        }),

        // ====== TRIPLE BONUS PLUS ======
        // Same as Triple Bonus but Four 5-K pays 50, and Jacks or Better minimum
        "triple-bonus-plus-9-5" => Some(Paytable {
            id: id.to_string(),
            name: "Triple Bonus Plus 9/5".to_string(),
            game_family: GameFamily::TripleBonusPlus,
            royal_flush: 800.0, straight_flush: 100.0, four_of_a_kind: 50.0,
            full_house: 9.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(240.0), four_2_4: Some(120.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9, // Jacks or Better
        }),
        "triple-bonus-plus-8-5" => Some(Paytable {
            id: id.to_string(),
            name: "Triple Bonus Plus 8/5".to_string(),
            game_family: GameFamily::TripleBonusPlus,
            royal_flush: 800.0, straight_flush: 100.0, four_of_a_kind: 50.0,
            full_house: 8.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(240.0), four_2_4: Some(120.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9, // Jacks or Better
        }),
        "triple-bonus-plus-7-5" => Some(Paytable {
            id: id.to_string(),
            name: "Triple Bonus Plus 7/5".to_string(),
            game_family: GameFamily::TripleBonusPlus,
            royal_flush: 800.0, straight_flush: 100.0, four_of_a_kind: 50.0,
            full_house: 7.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(240.0), four_2_4: Some(120.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9, // Jacks or Better
        }),

        // ====== SUPER ACES ======
        "super-aces-8-5" => Some(Paytable {
            id: id.to_string(),
            name: "Super Aces 8/5".to_string(),
            game_family: GameFamily::SuperAces,
            royal_flush: 800.0, straight_flush: 60.0, four_of_a_kind: 50.0,
            full_house: 8.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(400.0), four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "super-aces-7-5" => Some(Paytable {
            id: id.to_string(),
            name: "Super Aces 7/5".to_string(),
            game_family: GameFamily::SuperAces,
            royal_flush: 800.0, straight_flush: 60.0, four_of_a_kind: 50.0,
            full_house: 7.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(400.0), four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "super-aces-6-5" => Some(Paytable {
            id: id.to_string(),
            name: "Super Aces 6/5".to_string(),
            game_family: GameFamily::SuperAces,
            royal_flush: 800.0, straight_flush: 60.0, four_of_a_kind: 50.0,
            full_house: 6.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(400.0), four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // ====== BONUS POKER PLUS ======
        "bonus-poker-plus-10-7" => Some(Paytable {
            id: id.to_string(),
            name: "Bonus Poker Plus 10/7".to_string(),
            game_family: GameFamily::BonusPokerPlus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 100.0,
            full_house: 10.0, flush: 7.0, straight: 4.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "bonus-poker-plus-9-6" => Some(Paytable {
            id: id.to_string(),
            name: "Bonus Poker Plus 9/6".to_string(),
            game_family: GameFamily::BonusPokerPlus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 100.0,
            full_house: 9.0, flush: 6.0, straight: 4.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // ====== DOUBLE JACKPOT ======
        // Face kicker = J, Q, K for Four Aces; J, Q, K, A for Four JQK
        "double-jackpot-8-5" => Some(Paytable {
            id: id.to_string(),
            name: "Double Jackpot 8/5".to_string(),
            game_family: GameFamily::DoubleJackpot,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 20.0,
            full_house: 8.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: Some(80.0), four_2_4: None, four_5_k: None, four_jqk: Some(40.0),
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: Some(160.0), four_jqk_with_face: Some(80.0),
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "double-jackpot-7-5" => Some(Paytable {
            id: id.to_string(),
            name: "Double Jackpot 7/5".to_string(),
            game_family: GameFamily::DoubleJackpot,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 20.0,
            full_house: 7.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: Some(80.0), four_2_4: None, four_5_k: None, four_jqk: Some(40.0),
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: Some(160.0), four_jqk_with_face: Some(80.0),
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // ====== DOUBLE DOUBLE JACKPOT ======
        "double-double-jackpot-10-6" => Some(Paytable {
            id: id.to_string(),
            name: "Double Double Jackpot 10/6".to_string(),
            game_family: GameFamily::DoubleDoubleJackpot,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 10.0, flush: 6.0, straight: 5.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: None, four_5_k: None, four_jqk: Some(80.0),
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: Some(320.0), four_jqk_with_face: Some(160.0),
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "double-double-jackpot-9-6" => Some(Paytable {
            id: id.to_string(),
            name: "Double Double Jackpot 9/6".to_string(),
            game_family: GameFamily::DoubleDoubleJackpot,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 9.0, flush: 6.0, straight: 5.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: None, four_5_k: None, four_jqk: Some(80.0),
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: Some(320.0), four_jqk_with_face: Some(160.0),
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // Additional Bonus Deluxe variants
        "bonus-poker-deluxe-9-5" => Some(Paytable {
            id: id.to_string(),
            name: "Bonus Poker Deluxe 9/5 (98.55%)".to_string(),
            game_family: GameFamily::BonusPokerDeluxe,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 80.0,
            full_house: 9.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "bonus-poker-deluxe-8-6-100" => Some(Paytable {
            id: id.to_string(),
            name: "Bonus Poker Deluxe 8/6 SF100 (99.07%)".to_string(),
            game_family: GameFamily::BonusPokerDeluxe,
            royal_flush: 800.0, straight_flush: 100.0, four_of_a_kind: 80.0,
            full_house: 8.0, flush: 6.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // ====== DOUBLE BONUS ======
        "double-bonus-10-7" => Some(Paytable {
            id: id.to_string(),
            name: "Double Bonus 10/7 (100.17%)".to_string(),
            game_family: GameFamily::Doublebonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 10.0, flush: 7.0, straight: 5.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "double-bonus-10-7-100" => Some(Paytable {
            id: id.to_string(),
            name: "Double Bonus 10/7 SF100 (100.77%)".to_string(),
            game_family: GameFamily::Doublebonus,
            royal_flush: 800.0, straight_flush: 100.0, four_of_a_kind: 50.0,
            full_house: 10.0, flush: 7.0, straight: 5.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "double-bonus-10-7-80" => Some(Paytable {
            id: id.to_string(),
            name: "Double Bonus 10/7 SF80 (100.52%)".to_string(),
            game_family: GameFamily::Doublebonus,
            royal_flush: 800.0, straight_flush: 80.0, four_of_a_kind: 50.0,
            full_house: 10.0, flush: 7.0, straight: 5.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "double-bonus-10-6" => Some(Paytable {
            id: id.to_string(),
            name: "Double Bonus 10/6 (98.88%)".to_string(),
            game_family: GameFamily::Doublebonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 10.0, flush: 6.0, straight: 5.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "double-bonus-10-7-4" => Some(Paytable {
            id: id.to_string(),
            name: "Double Bonus 10/7/4 (98.81%)".to_string(),
            game_family: GameFamily::Doublebonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 10.0, flush: 7.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "double-bonus-9-7-5" => Some(Paytable {
            id: id.to_string(),
            name: "Double Bonus 9/7/5".to_string(),
            game_family: GameFamily::Doublebonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 9.0, flush: 7.0, straight: 5.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "double-bonus-9-6-5" => Some(Paytable {
            id: id.to_string(),
            name: "Double Bonus 9/6/5".to_string(),
            game_family: GameFamily::Doublebonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 9.0, flush: 6.0, straight: 5.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "double-bonus-9-6-4" => Some(Paytable {
            id: id.to_string(),
            name: "Double Bonus 9/6/4".to_string(),
            game_family: GameFamily::Doublebonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 9.0, flush: 6.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // ====== SUPER DOUBLE BONUS ======
        "super-double-bonus-9-5" => Some(Paytable {
            id: id.to_string(),
            name: "Super Double Bonus 9/5".to_string(),
            game_family: GameFamily::SuperDoubleBonus,
            royal_flush: 800.0, straight_flush: 80.0, four_of_a_kind: 50.0,
            full_house: 9.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: None, four_5_k: Some(50.0), four_jqk: Some(120.0),
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "super-double-bonus-8-5" => Some(Paytable {
            id: id.to_string(),
            name: "Super Double Bonus 8/5".to_string(),
            game_family: GameFamily::SuperDoubleBonus,
            royal_flush: 800.0, straight_flush: 80.0, four_of_a_kind: 50.0,
            full_house: 8.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: None, four_5_k: Some(50.0), four_jqk: Some(120.0),
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "super-double-bonus-7-5" => Some(Paytable {
            id: id.to_string(),
            name: "Super Double Bonus 7/5".to_string(),
            game_family: GameFamily::SuperDoubleBonus,
            royal_flush: 800.0, straight_flush: 80.0, four_of_a_kind: 50.0,
            full_house: 7.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: None, four_5_k: Some(50.0), four_jqk: Some(120.0),
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "super-double-bonus-6-5" => Some(Paytable {
            id: id.to_string(),
            name: "Super Double Bonus 6/5".to_string(),
            game_family: GameFamily::SuperDoubleBonus,
            royal_flush: 800.0, straight_flush: 80.0, four_of_a_kind: 50.0,
            full_house: 6.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: None, four_5_k: Some(50.0), four_jqk: Some(120.0),
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // ====== DOUBLE DOUBLE BONUS ======
        "double-double-bonus-10-6-100" => Some(Paytable {
            id: id.to_string(),
            name: "Double Double Bonus 10/6 SF100 (100.64%)".to_string(),
            game_family: GameFamily::DoubleDoubleBonus,
            royal_flush: 800.0, straight_flush: 100.0, four_of_a_kind: 50.0,
            full_house: 10.0, flush: 6.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: Some(400.0), four_2_4_with_kicker: Some(160.0),
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "double-double-bonus-10-6" => Some(Paytable {
            id: id.to_string(),
            name: "Double Double Bonus 10/6 (100.07%)".to_string(),
            game_family: GameFamily::DoubleDoubleBonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 10.0, flush: 6.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: Some(400.0), four_2_4_with_kicker: Some(160.0),
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "double-double-bonus-7-5" => Some(Paytable {
            id: id.to_string(),
            name: "Double Double Bonus 7/5 (95.71%)".to_string(),
            game_family: GameFamily::DoubleDoubleBonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 7.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: Some(400.0), four_2_4_with_kicker: Some(160.0),
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "double-double-bonus-6-5" => Some(Paytable {
            id: id.to_string(),
            name: "Double Double Bonus 6/5 (94.66%)".to_string(),
            game_family: GameFamily::DoubleDoubleBonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 6.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: Some(400.0), four_2_4_with_kicker: Some(160.0),
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "double-double-bonus-9-6" => Some(Paytable {
            id: id.to_string(),
            name: "Double Double Bonus 9/6".to_string(),
            game_family: GameFamily::DoubleDoubleBonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 9.0, flush: 6.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: Some(400.0), four_2_4_with_kicker: Some(160.0),
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "double-double-bonus-9-5" => Some(Paytable {
            id: id.to_string(),
            name: "Double Double Bonus 9/5".to_string(),
            game_family: GameFamily::DoubleDoubleBonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 9.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: Some(400.0), four_2_4_with_kicker: Some(160.0),
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "double-double-bonus-8-5" => Some(Paytable {
            id: id.to_string(),
            name: "Double Double Bonus 8/5".to_string(),
            game_family: GameFamily::DoubleDoubleBonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 8.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: Some(400.0), four_2_4_with_kicker: Some(160.0),
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // ====== WHITE HOT ACES ======
        "white-hot-aces-9-5" => Some(Paytable {
            id: id.to_string(),
            name: "White Hot Aces 9/5".to_string(),
            game_family: GameFamily::WhiteHotAces,
            royal_flush: 800.0, straight_flush: 80.0, four_of_a_kind: 50.0,
            full_house: 9.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(240.0), four_2_4: Some(120.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "white-hot-aces-8-5" => Some(Paytable {
            id: id.to_string(),
            name: "White Hot Aces 8/5".to_string(),
            game_family: GameFamily::WhiteHotAces,
            royal_flush: 800.0, straight_flush: 80.0, four_of_a_kind: 50.0,
            full_house: 8.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(240.0), four_2_4: Some(120.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "white-hot-aces-7-5" => Some(Paytable {
            id: id.to_string(),
            name: "White Hot Aces 7/5".to_string(),
            game_family: GameFamily::WhiteHotAces,
            royal_flush: 800.0, straight_flush: 80.0, four_of_a_kind: 50.0,
            full_house: 7.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(240.0), four_2_4: Some(120.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "white-hot-aces-6-5" => Some(Paytable {
            id: id.to_string(),
            name: "White Hot Aces 6/5".to_string(),
            game_family: GameFamily::WhiteHotAces,
            royal_flush: 800.0, straight_flush: 80.0, four_of_a_kind: 50.0,
            full_house: 6.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(240.0), four_2_4: Some(120.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // ====== TRIPLE DOUBLE BONUS ======
        "triple-double-bonus-9-7" => Some(Paytable {
            id: id.to_string(),
            name: "Triple Double Bonus 9/7".to_string(),
            game_family: GameFamily::TripleDoubleBonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 9.0, flush: 7.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: Some(800.0), four_2_4_with_kicker: Some(400.0),
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "triple-double-bonus-9-6" => Some(Paytable {
            id: id.to_string(),
            name: "Triple Double Bonus 9/6".to_string(),
            game_family: GameFamily::TripleDoubleBonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 9.0, flush: 6.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: Some(800.0), four_2_4_with_kicker: Some(400.0),
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "triple-double-bonus-8-5" => Some(Paytable {
            id: id.to_string(),
            name: "Triple Double Bonus 8/5".to_string(),
            game_family: GameFamily::TripleDoubleBonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 8.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: Some(800.0), four_2_4_with_kicker: Some(400.0),
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // ====== ALL AMERICAN ======
        "all-american-35-8" => Some(Paytable {
            id: id.to_string(),
            name: "All American 35-8".to_string(),
            game_family: GameFamily::AllAmerican,
            royal_flush: 800.0, straight_flush: 200.0, four_of_a_kind: 35.0,
            full_house: 8.0, flush: 8.0, straight: 8.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "all-american-30-8" => Some(Paytable {
            id: id.to_string(),
            name: "All American 30-8".to_string(),
            game_family: GameFamily::AllAmerican,
            royal_flush: 800.0, straight_flush: 200.0, four_of_a_kind: 30.0,
            full_house: 8.0, flush: 8.0, straight: 8.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "all-american-25-8" => Some(Paytable {
            id: id.to_string(),
            name: "All American 25-8".to_string(),
            game_family: GameFamily::AllAmerican,
            royal_flush: 800.0, straight_flush: 200.0, four_of_a_kind: 25.0,
            full_house: 8.0, flush: 8.0, straight: 8.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "all-american-40-7" => Some(Paytable {
            id: id.to_string(),
            name: "All American 40-7".to_string(),
            game_family: GameFamily::AllAmerican,
            royal_flush: 800.0, straight_flush: 200.0, four_of_a_kind: 40.0,
            full_house: 7.0, flush: 7.0, straight: 7.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // ====== DEUCES WILD ======
        "deuces-wild-full-pay" => Some(Paytable {
            id: id.to_string(),
            name: "Deuces Wild Full Pay".to_string(),
            game_family: GameFamily::DeucesWild,
            royal_flush: 800.0, straight_flush: 9.0, four_of_a_kind: 5.0,
            full_house: 3.0, flush: 2.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(200.0), wild_royal: Some(25.0), five_of_a_kind: Some(15.0),
            min_pair_rank: 0, // Three of a kind minimum
        }),
        "deuces-wild-nsud" => Some(Paytable {
            id: id.to_string(),
            name: "Deuces Wild NSUD".to_string(),
            game_family: GameFamily::DeucesWild,
            royal_flush: 800.0, straight_flush: 10.0, four_of_a_kind: 4.0,
            full_house: 4.0, flush: 3.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(200.0), wild_royal: Some(25.0), five_of_a_kind: Some(16.0),
            min_pair_rank: 0,
        }),
        "deuces-wild-illinois" => Some(Paytable {
            id: id.to_string(),
            name: "Deuces Wild Illinois".to_string(),
            game_family: GameFamily::DeucesWild,
            royal_flush: 800.0, straight_flush: 9.0, four_of_a_kind: 4.0,
            full_house: 4.0, flush: 3.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(200.0), wild_royal: Some(25.0), five_of_a_kind: Some(15.0),
            min_pair_rank: 0,
        }),
        "deuces-wild-20-12-9" => Some(Paytable {
            id: id.to_string(),
            name: "Deuces Wild 20-12-9".to_string(),
            game_family: GameFamily::DeucesWild,
            royal_flush: 800.0, straight_flush: 9.0, four_of_a_kind: 5.0,
            full_house: 3.0, flush: 2.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(200.0), wild_royal: Some(20.0), five_of_a_kind: Some(12.0),
            min_pair_rank: 0,
        }),

        // Additional Deuces Wild variants
        "deuces-wild-25-15-8" => Some(Paytable {
            id: id.to_string(),
            name: "Deuces Wild 25/15/8 (100.36%)".to_string(),
            game_family: GameFamily::DeucesWild,
            royal_flush: 800.0, straight_flush: 8.0, four_of_a_kind: 5.0,
            full_house: 3.0, flush: 2.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(200.0), wild_royal: Some(25.0), five_of_a_kind: Some(15.0),
            min_pair_rank: 0,
        }),
        "deuces-wild-20-15-9" => Some(Paytable {
            id: id.to_string(),
            name: "Deuces Wild 20/15/9 (99.89%)".to_string(),
            game_family: GameFamily::DeucesWild,
            royal_flush: 800.0, straight_flush: 9.0, four_of_a_kind: 5.0,
            full_house: 3.0, flush: 2.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(200.0), wild_royal: Some(20.0), five_of_a_kind: Some(15.0),
            min_pair_rank: 0,
        }),
        "deuces-wild-25-12-9" => Some(Paytable {
            id: id.to_string(),
            name: "Deuces Wild 25/12/9 (99.81%)".to_string(),
            game_family: GameFamily::DeucesWild,
            royal_flush: 800.0, straight_flush: 9.0, four_of_a_kind: 5.0,
            full_house: 3.0, flush: 2.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(200.0), wild_royal: Some(25.0), five_of_a_kind: Some(12.0),
            min_pair_rank: 0,
        }),
        "deuces-wild-colorado" => Some(Paytable {
            id: id.to_string(),
            name: "Colorado Deuces (96.77%)".to_string(),
            game_family: GameFamily::DeucesWild,
            royal_flush: 800.0, straight_flush: 13.0, four_of_a_kind: 4.0,
            full_house: 3.0, flush: 2.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(200.0), wild_royal: Some(25.0), five_of_a_kind: Some(16.0),
            min_pair_rank: 0,
        }),

        // ====== LOOSE DEUCES ======
        "loose-deuces-500-17" => Some(Paytable {
            id: id.to_string(),
            name: "Loose Deuces 500-17".to_string(),
            game_family: GameFamily::LooseDeuces,
            royal_flush: 800.0, straight_flush: 10.0, four_of_a_kind: 4.0,
            full_house: 3.0, flush: 2.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(500.0), wild_royal: Some(25.0), five_of_a_kind: Some(17.0),
            min_pair_rank: 0,
        }),
        "loose-deuces-500-15" => Some(Paytable {
            id: id.to_string(),
            name: "Loose Deuces 500-15".to_string(),
            game_family: GameFamily::LooseDeuces,
            royal_flush: 800.0, straight_flush: 10.0, four_of_a_kind: 4.0,
            full_house: 3.0, flush: 2.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(500.0), wild_royal: Some(25.0), five_of_a_kind: Some(15.0),
            min_pair_rank: 0,
        }),
        "loose-deuces-500-12" => Some(Paytable {
            id: id.to_string(),
            name: "Loose Deuces 500-12".to_string(),
            game_family: GameFamily::LooseDeuces,
            royal_flush: 800.0, straight_flush: 10.0, four_of_a_kind: 4.0,
            full_house: 3.0, flush: 2.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(500.0), wild_royal: Some(25.0), five_of_a_kind: Some(12.0),
            min_pair_rank: 0,
        }),
        "loose-deuces-400-12" => Some(Paytable {
            id: id.to_string(),
            name: "Loose Deuces 400-12".to_string(),
            game_family: GameFamily::LooseDeuces,
            royal_flush: 800.0, straight_flush: 10.0, four_of_a_kind: 4.0,
            full_house: 3.0, flush: 2.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(400.0), wild_royal: Some(25.0), five_of_a_kind: Some(12.0),
            min_pair_rank: 0,
        }),

        // ====== DOUBLE DEUCES WILD ======
        "double-deuces-wild-10-10" => Some(Paytable {
            id: id.to_string(),
            name: "Double Deuces Wild 10/10".to_string(),
            game_family: GameFamily::DoubleDeuces,
            royal_flush: 800.0, straight_flush: 10.0, four_of_a_kind: 4.0,
            full_house: 4.0, flush: 3.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(400.0), wild_royal: Some(20.0), five_of_a_kind: Some(10.0),
            min_pair_rank: 0,
        }),
        "double-deuces-wild-16-13" => Some(Paytable {
            id: id.to_string(),
            name: "Double Deuces Wild 16/13".to_string(),
            game_family: GameFamily::DoubleDeuces,
            royal_flush: 800.0, straight_flush: 13.0, four_of_a_kind: 4.0,
            full_house: 3.0, flush: 2.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(400.0), wild_royal: Some(25.0), five_of_a_kind: Some(16.0),
            min_pair_rank: 0,
        }),

        // Additional Double Deuces Wild variants
        "double-deuces-wild-samstown" => Some(Paytable {
            id: id.to_string(),
            name: "Sam's Town Deuces (100.95%)".to_string(),
            game_family: GameFamily::DoubleDeuces,
            royal_flush: 800.0, straight_flush: 10.0, four_of_a_kind: 4.0,
            full_house: 4.0, flush: 3.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(400.0), wild_royal: Some(20.0), five_of_a_kind: Some(10.0),
            min_pair_rank: 0,
        }),
        "double-deuces-wild-downtown" => Some(Paytable {
            id: id.to_string(),
            name: "Downtown Deuces (100.92%)".to_string(),
            game_family: GameFamily::DoubleDeuces,
            royal_flush: 940.0, straight_flush: 13.0, four_of_a_kind: 4.0,
            full_house: 3.0, flush: 2.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(400.0), wild_royal: Some(25.0), five_of_a_kind: Some(16.0),
            min_pair_rank: 0,
        }),
        "double-deuces-wild-16-11" => Some(Paytable {
            id: id.to_string(),
            name: "Double Deuces Wild 16/11 (99.62%)".to_string(),
            game_family: GameFamily::DoubleDeuces,
            royal_flush: 800.0, straight_flush: 11.0, four_of_a_kind: 4.0,
            full_house: 3.0, flush: 2.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(400.0), wild_royal: Some(25.0), five_of_a_kind: Some(16.0),
            min_pair_rank: 0,
        }),
        "double-deuces-wild-16-10" => Some(Paytable {
            id: id.to_string(),
            name: "Double Deuces Wild 16/10 (99.17%)".to_string(),
            game_family: GameFamily::DoubleDeuces,
            royal_flush: 800.0, straight_flush: 10.0, four_of_a_kind: 4.0,
            full_house: 3.0, flush: 2.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(400.0), wild_royal: Some(25.0), five_of_a_kind: Some(16.0),
            min_pair_rank: 0,
        }),

        // ====== TRIPLE DEUCES WILD ======
        // Additional TDW variant
        "triple-deuces-wild-9-6" => Some(Paytable {
            id: id.to_string(),
            name: "Triple Deuces Wild 9/6 (98.86%)".to_string(),
            game_family: GameFamily::TripleDeuces,
            royal_flush: 800.0, straight_flush: 6.0, four_of_a_kind: 4.0,
            full_house: 3.0, flush: 2.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(600.0), wild_royal: Some(20.0), five_of_a_kind: Some(9.0),
            min_pair_rank: 0,
        }),
        "triple-deuces-wild-11-8" => Some(Paytable {
            id: id.to_string(),
            name: "Triple Deuces Wild 11/8".to_string(),
            game_family: GameFamily::TripleDeuces,
            royal_flush: 800.0, straight_flush: 8.0, four_of_a_kind: 4.0,
            full_house: 3.0, flush: 2.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(600.0), wild_royal: Some(20.0), five_of_a_kind: Some(11.0),
            min_pair_rank: 0,
        }),
        "triple-deuces-wild-10-8" => Some(Paytable {
            id: id.to_string(),
            name: "Triple Deuces Wild 10/8".to_string(),
            game_family: GameFamily::TripleDeuces,
            royal_flush: 800.0, straight_flush: 8.0, four_of_a_kind: 4.0,
            full_house: 3.0, flush: 2.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(600.0), wild_royal: Some(20.0), five_of_a_kind: Some(10.0),
            min_pair_rank: 0,
        }),

        // ====== DELUXE DEUCES WILD ======
        // Higher payouts for lower hands: SF=15, 4K=10, FH=9, Flush=4, Straight=4, 3K=3
        "deluxe-deuces-wild-940" => Some(Paytable {
            id: id.to_string(),
            name: "Deluxe Deuces Wild 940 (100.65%)".to_string(),
            game_family: GameFamily::DeluxeDeucesWild,
            royal_flush: 940.0, straight_flush: 15.0, four_of_a_kind: 10.0,
            full_house: 9.0, flush: 4.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(200.0), wild_royal: Some(50.0), five_of_a_kind: Some(25.0),
            min_pair_rank: 0,
        }),
        "deluxe-deuces-wild-800" => Some(Paytable {
            id: id.to_string(),
            name: "Deluxe Deuces Wild 800 (100.32%)".to_string(),
            game_family: GameFamily::DeluxeDeucesWild,
            royal_flush: 800.0, straight_flush: 15.0, four_of_a_kind: 10.0,
            full_house: 9.0, flush: 4.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(200.0), wild_royal: Some(50.0), five_of_a_kind: Some(25.0),
            min_pair_rank: 0,
        }),

        // ====== JOKER POKER (KINGS OR BETTER) ======
        "joker-poker-kings-100-64" => Some(Paytable {
            id: id.to_string(),
            name: "Joker Poker Kings 100.64%".to_string(),
            game_family: GameFamily::JokerPokerKings,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 17.0,
            full_house: 7.0, flush: 5.0, straight: 3.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: Some(100.0), five_of_a_kind: Some(200.0),
            min_pair_rank: 11, // Kings or better
        }),
        "joker-poker-kings-98-60" => Some(Paytable {
            id: id.to_string(),
            name: "Joker Poker Kings 98.60%".to_string(),
            game_family: GameFamily::JokerPokerKings,
            royal_flush: 1000.0, straight_flush: 50.0, four_of_a_kind: 17.0,
            full_house: 7.0, flush: 5.0, straight: 3.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: Some(50.0), five_of_a_kind: Some(100.0),
            min_pair_rank: 11,
        }),
        "joker-poker-kings-97-58" => Some(Paytable {
            id: id.to_string(),
            name: "Joker Poker Kings 97.58%".to_string(),
            game_family: GameFamily::JokerPokerKings,
            royal_flush: 1000.0, straight_flush: 50.0, four_of_a_kind: 17.0,
            full_house: 6.0, flush: 5.0, straight: 3.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: Some(50.0), five_of_a_kind: Some(100.0),
            min_pair_rank: 11,
        }),

        // ====== JOKER POKER (TWO PAIR OR BETTER) ======
        "joker-poker-two-pair-99-92" => Some(Paytable {
            id: id.to_string(),
            name: "Joker Poker Two Pair 99.92%".to_string(),
            game_family: GameFamily::JokerPokerTwoPair,
            royal_flush: 1000.0, straight_flush: 50.0, four_of_a_kind: 20.0,
            full_house: 10.0, flush: 6.0, straight: 5.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: Some(50.0), five_of_a_kind: Some(100.0),
            min_pair_rank: 0, // Two pair minimum
        }),
        "joker-poker-two-pair-98-59" => Some(Paytable {
            id: id.to_string(),
            name: "Joker Poker Two Pair 98.59%".to_string(),
            game_family: GameFamily::JokerPokerTwoPair,
            royal_flush: 800.0, straight_flush: 100.0, four_of_a_kind: 16.0,
            full_house: 8.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: Some(100.0), five_of_a_kind: Some(800.0),
            min_pair_rank: 0,
        }),

        // ====== DOUBLE JOKER ======
        // Two jokers in deck (54 cards), minimum hand is Kings or Better
        "double-joker-9-6" => Some(Paytable {
            id: id.to_string(),
            name: "Double Joker 9/6".to_string(),
            game_family: GameFamily::DoubleJoker,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 9.0, flush: 6.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: Some(25.0), five_of_a_kind: Some(100.0),
            min_pair_rank: 11, // Kings or Better
        }),
        "double-joker-5-4" => Some(Paytable {
            id: id.to_string(),
            name: "Double Joker 5/4".to_string(),
            game_family: GameFamily::DoubleJoker,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 5.0, flush: 4.0, straight: 3.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: Some(25.0), five_of_a_kind: Some(100.0),
            min_pair_rank: 11, // Kings or Better
        }),

        // ====== TRIPLE TRIPLE BONUS (TTB) ======
        // Kicker bonuses: 4A+234 pays 800, 4(234)+A pays 800, 4(234)+234 pays 400
        "triple-triple-bonus-9-6" => Some(Paytable {
            id: id.to_string(),
            name: "Triple Triple Bonus 9/6 (99.75%)".to_string(),
            game_family: GameFamily::TripleTripleBonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 9.0, flush: 6.0, straight: 3.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: Some(800.0), four_2_4_with_kicker: Some(400.0),
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "triple-triple-bonus-9-5" => Some(Paytable {
            id: id.to_string(),
            name: "Triple Triple Bonus 9/5 (98.61%)".to_string(),
            game_family: GameFamily::TripleTripleBonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 9.0, flush: 5.0, straight: 3.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: Some(800.0), four_2_4_with_kicker: Some(400.0),
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "triple-triple-bonus-8-5" => Some(Paytable {
            id: id.to_string(),
            name: "Triple Triple Bonus 8/5 (97.61%)".to_string(),
            game_family: GameFamily::TripleTripleBonus,
            royal_flush: 800.0, straight_flush: 55.0, four_of_a_kind: 50.0,
            full_house: 8.0, flush: 5.0, straight: 3.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: Some(800.0), four_2_4_with_kicker: Some(400.0),
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "triple-triple-bonus-7-5" => Some(Paytable {
            id: id.to_string(),
            name: "Triple Triple Bonus 7/5 (96.55%)".to_string(),
            game_family: GameFamily::TripleTripleBonus,
            royal_flush: 800.0, straight_flush: 55.0, four_of_a_kind: 50.0,
            full_house: 7.0, flush: 5.0, straight: 3.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: Some(800.0), four_2_4_with_kicker: Some(400.0),
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // ====== ROYAL ACES BONUS (RAB) ======
        // Four Aces pays 800 (royal treatment for aces)
        "royal-aces-bonus-9-6" => Some(Paytable {
            id: id.to_string(),
            name: "Royal Aces Bonus 9/6 (99.58%)".to_string(),
            game_family: GameFamily::RoyalAcesBonus,
            royal_flush: 800.0, straight_flush: 100.0, four_of_a_kind: 50.0,
            full_house: 9.0, flush: 6.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(800.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 12, // Aces or better
        }),
        "royal-aces-bonus-10-5" => Some(Paytable {
            id: id.to_string(),
            name: "Royal Aces Bonus 10/5 (99.20%)".to_string(),
            game_family: GameFamily::RoyalAcesBonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 10.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(800.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 12,
        }),
        "royal-aces-bonus-8-6" => Some(Paytable {
            id: id.to_string(),
            name: "Royal Aces Bonus 8/6 (98.51%)".to_string(),
            game_family: GameFamily::RoyalAcesBonus,
            royal_flush: 800.0, straight_flush: 100.0, four_of_a_kind: 50.0,
            full_house: 8.0, flush: 6.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(800.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 12,
        }),
        "royal-aces-bonus-9-5" => Some(Paytable {
            id: id.to_string(),
            name: "Royal Aces Bonus 9/5 (98.13%)".to_string(),
            game_family: GameFamily::RoyalAcesBonus,
            royal_flush: 800.0, straight_flush: 100.0, four_of_a_kind: 50.0,
            full_house: 9.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(800.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 12,
        }),

        // ====== A-C-E-S BONUS (Ace$) ======
        // Four Aces (all same suit = A-C-E-$) pays 800
        "aces-bonus-8-5" => Some(Paytable {
            id: id.to_string(),
            name: "A-c-e-s Bonus 8/5 (99.40%)".to_string(),
            game_family: GameFamily::AcesBonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 8.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: Some(800.0), four_2_4: Some(40.0), four_5_k: Some(25.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "aces-bonus-7-5" => Some(Paytable {
            id: id.to_string(),
            name: "A-c-e-s Bonus 7/5 (98.25%)".to_string(),
            game_family: GameFamily::AcesBonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 7.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: Some(800.0), four_2_4: Some(40.0), four_5_k: Some(25.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "aces-bonus-6-5" => Some(Paytable {
            id: id.to_string(),
            name: "A-c-e-s Bonus 6/5 (97.11%)".to_string(),
            game_family: GameFamily::AcesBonus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 6.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: Some(800.0), four_2_4: Some(40.0), four_5_k: Some(25.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // ====== BONUS ACES AND FACES (BPAF) ======
        "bonus-aces-faces-8-5" => Some(Paytable {
            id: id.to_string(),
            name: "Bonus Aces and Faces 8/5 (99.26%)".to_string(),
            game_family: GameFamily::BonusAcesAndFaces,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 8.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: Some(80.0), four_2_4: None, four_5_k: None, four_jqk: Some(40.0),
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "bonus-aces-faces-7-5" => Some(Paytable {
            id: id.to_string(),
            name: "Bonus Aces and Faces 7/5 (98.10%)".to_string(),
            game_family: GameFamily::BonusAcesAndFaces,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 7.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: Some(80.0), four_2_4: None, four_5_k: None, four_jqk: Some(40.0),
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "bonus-aces-faces-6-5" => Some(Paytable {
            id: id.to_string(),
            name: "Bonus Aces and Faces 6/5 (96.96%)".to_string(),
            game_family: GameFamily::BonusAcesAndFaces,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 25.0,
            full_house: 6.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 2.0, high_pair: 1.0,
            four_aces: Some(80.0), four_2_4: None, four_5_k: None, four_jqk: Some(40.0),
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // ====== DOUBLE DOUBLE BONUS ACES AND FACES (DDBAF) ======
        "ddb-aces-faces-9-6" => Some(Paytable {
            id: id.to_string(),
            name: "DDB Aces and Faces 9/6 (99.46%)".to_string(),
            game_family: GameFamily::DDBonusAcesAndFaces,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 9.0, flush: 6.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: Some(80.0),
            four_8s: None, four_7s: None,
            four_aces_with_kicker: Some(400.0), four_2_4_with_kicker: Some(160.0),
            four_aces_with_face: None, four_jqk_with_face: Some(160.0),
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "ddb-aces-faces-9-5" => Some(Paytable {
            id: id.to_string(),
            name: "DDB Aces and Faces 9/5 (98.37%)".to_string(),
            game_family: GameFamily::DDBonusAcesAndFaces,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 9.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(50.0), four_jqk: Some(80.0),
            four_8s: None, four_7s: None,
            four_aces_with_kicker: Some(400.0), four_2_4_with_kicker: Some(160.0),
            four_aces_with_face: None, four_jqk_with_face: Some(160.0),
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // ====== DOUBLE DOUBLE BONUS PLUS (DDB+) ======
        // Additional kicker: 4K+A pays 80
        "ddb-plus-9-6" => Some(Paytable {
            id: id.to_string(),
            name: "DDB Plus 9/6 (99.44%)".to_string(),
            game_family: GameFamily::DoubleDoubleBonusPlus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 9.0, flush: 6.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(80.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: Some(400.0), four_2_4_with_kicker: Some(160.0),
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "ddb-plus-9-5" => Some(Paytable {
            id: id.to_string(),
            name: "DDB Plus 9/5 (98.33%)".to_string(),
            game_family: GameFamily::DoubleDoubleBonusPlus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 9.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(80.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: Some(400.0), four_2_4_with_kicker: Some(160.0),
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),
        "ddb-plus-8-5" => Some(Paytable {
            id: id.to_string(),
            name: "DDB Plus 8/5 (97.25%)".to_string(),
            game_family: GameFamily::DoubleDoubleBonusPlus,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 50.0,
            full_house: 8.0, flush: 5.0, straight: 4.0,
            three_of_a_kind: 3.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: Some(160.0), four_2_4: Some(80.0), four_5_k: Some(80.0), four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: Some(400.0), four_2_4_with_kicker: Some(160.0),
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: None, five_of_a_kind: None,
            min_pair_rank: 9,
        }),

        // ====== DEUCES WILD 44 (DW44) ======
        // 4K pays 4 instead of 5, different 5K/SF payouts
        "deuces-wild-44-apdw" => Some(Paytable {
            id: id.to_string(),
            name: "APDW Deuces Wild 44 (99.96%)".to_string(),
            game_family: GameFamily::DeucesWild44,
            royal_flush: 800.0, straight_flush: 11.0, four_of_a_kind: 4.0,
            full_house: 4.0, flush: 3.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(200.0), wild_royal: Some(25.0), five_of_a_kind: Some(15.0),
            min_pair_rank: 0,
        }),
        "deuces-wild-44-nsud" => Some(Paytable {
            id: id.to_string(),
            name: "NSUD Deuces Wild 44 (99.73%)".to_string(),
            game_family: GameFamily::DeucesWild44,
            royal_flush: 800.0, straight_flush: 10.0, four_of_a_kind: 4.0,
            full_house: 4.0, flush: 3.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(200.0), wild_royal: Some(25.0), five_of_a_kind: Some(16.0),
            min_pair_rank: 0,
        }),
        "deuces-wild-44-illinois" => Some(Paytable {
            id: id.to_string(),
            name: "Illinois Deuces Wild 44 (98.91%)".to_string(),
            game_family: GameFamily::DeucesWild44,
            royal_flush: 800.0, straight_flush: 9.0, four_of_a_kind: 4.0,
            full_house: 4.0, flush: 3.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(200.0), wild_royal: Some(25.0), five_of_a_kind: Some(15.0),
            min_pair_rank: 0,
        }),

        // ====== DEUCES JOKER WILD (DJW) ======
        // Deuces AND Joker are wild (53-card deck)
        "deuces-joker-wild-12-9" => Some(Paytable {
            id: id.to_string(),
            name: "Deuces Joker Wild 12/9 (99.07%)".to_string(),
            game_family: GameFamily::DeucesJokerWild,
            royal_flush: 800.0, straight_flush: 6.0, four_of_a_kind: 3.0,
            full_house: 3.0, flush: 3.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(25.0), wild_royal: Some(12.0), five_of_a_kind: Some(9.0),
            min_pair_rank: 0,
        }),
        "deuces-joker-wild-10-8" => Some(Paytable {
            id: id.to_string(),
            name: "Deuces Joker Wild 10/8 (97.25%)".to_string(),
            game_family: GameFamily::DeucesJokerWild,
            royal_flush: 800.0, straight_flush: 5.0, four_of_a_kind: 3.0,
            full_house: 3.0, flush: 3.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(25.0), wild_royal: Some(10.0), five_of_a_kind: Some(8.0),
            min_pair_rank: 0,
        }),

        // ====== DOUBLE BONUS DEUCES WILD (DBDW) ======
        "double-bonus-deuces-12" => Some(Paytable {
            id: id.to_string(),
            name: "Double Bonus Deuces 12 (99.81%)".to_string(),
            game_family: GameFamily::DoubleBonusDeucesWild,
            royal_flush: 800.0, straight_flush: 12.0, four_of_a_kind: 4.0,
            full_house: 3.0, flush: 2.0, straight: 1.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(400.0), wild_royal: Some(25.0), five_of_a_kind: Some(160.0),
            min_pair_rank: 0,
        }),
        "double-bonus-deuces-9" => Some(Paytable {
            id: id.to_string(),
            name: "Double Bonus Deuces 9 (98.61%)".to_string(),
            game_family: GameFamily::DoubleBonusDeucesWild,
            royal_flush: 800.0, straight_flush: 9.0, four_of_a_kind: 4.0,
            full_house: 3.0, flush: 2.0, straight: 1.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(400.0), wild_royal: Some(25.0), five_of_a_kind: Some(160.0),
            min_pair_rank: 0,
        }),

        // ====== SUPER BONUS DEUCES WILD (SBDW) ======
        "super-bonus-deuces-10" => Some(Paytable {
            id: id.to_string(),
            name: "Super Bonus Deuces 10 (100.13%)".to_string(),
            game_family: GameFamily::SuperBonusDeucesWild,
            royal_flush: 800.0, straight_flush: 10.0, four_of_a_kind: 4.0,
            full_house: 3.0, flush: 2.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(400.0), wild_royal: Some(25.0), five_of_a_kind: Some(160.0),
            min_pair_rank: 0,
        }),
        "super-bonus-deuces-9" => Some(Paytable {
            id: id.to_string(),
            name: "Super Bonus Deuces 9 (99.67%)".to_string(),
            game_family: GameFamily::SuperBonusDeucesWild,
            royal_flush: 800.0, straight_flush: 9.0, four_of_a_kind: 4.0,
            full_house: 3.0, flush: 2.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(400.0), wild_royal: Some(25.0), five_of_a_kind: Some(160.0),
            min_pair_rank: 0,
        }),
        "super-bonus-deuces-8" => Some(Paytable {
            id: id.to_string(),
            name: "Super Bonus Deuces 8 (97.87%)".to_string(),
            game_family: GameFamily::SuperBonusDeucesWild,
            royal_flush: 800.0, straight_flush: 8.0, four_of_a_kind: 4.0,
            full_house: 3.0, flush: 2.0, straight: 2.0,
            three_of_a_kind: 1.0, two_pair: 0.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: Some(400.0), wild_royal: Some(25.0), five_of_a_kind: Some(160.0),
            min_pair_rank: 0,
        }),

        // ====== ADDITIONAL JOKER POKER KINGS VARIANTS ======
        "joker-poker-kings-20-7" => Some(Paytable {
            id: id.to_string(),
            name: "Joker Poker Kings 20/7 (100.65%)".to_string(),
            game_family: GameFamily::JokerPokerKings,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 20.0,
            full_house: 7.0, flush: 5.0, straight: 3.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: Some(100.0), five_of_a_kind: Some(200.0),
            min_pair_rank: 11,
        }),
        "joker-poker-kings-940-20" => Some(Paytable {
            id: id.to_string(),
            name: "Joker Poker Kings 940/20 (101.00%)".to_string(),
            game_family: GameFamily::JokerPokerKings,
            royal_flush: 940.0, straight_flush: 50.0, four_of_a_kind: 20.0,
            full_house: 7.0, flush: 5.0, straight: 3.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: Some(100.0), five_of_a_kind: Some(200.0),
            min_pair_rank: 11,
        }),
        "joker-poker-kings-20-6" => Some(Paytable {
            id: id.to_string(),
            name: "Joker Poker Kings 20/6 (99.08%)".to_string(),
            game_family: GameFamily::JokerPokerKings,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 20.0,
            full_house: 6.0, flush: 5.0, straight: 3.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: Some(100.0), five_of_a_kind: Some(200.0),
            min_pair_rank: 11,
        }),
        "joker-poker-kings-18-7" => Some(Paytable {
            id: id.to_string(),
            name: "Joker Poker Kings 18/7 (98.94%)".to_string(),
            game_family: GameFamily::JokerPokerKings,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 18.0,
            full_house: 7.0, flush: 5.0, straight: 3.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: Some(100.0), five_of_a_kind: Some(200.0),
            min_pair_rank: 11,
        }),
        "joker-poker-kings-17-7" => Some(Paytable {
            id: id.to_string(),
            name: "Joker Poker Kings 17/7 (98.09%)".to_string(),
            game_family: GameFamily::JokerPokerKings,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 17.0,
            full_house: 7.0, flush: 5.0, straight: 3.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: Some(100.0), five_of_a_kind: Some(200.0),
            min_pair_rank: 11,
        }),
        "joker-poker-kings-15-7" => Some(Paytable {
            id: id.to_string(),
            name: "Joker Poker Kings 15/7 (96.38%)".to_string(),
            game_family: GameFamily::JokerPokerKings,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 15.0,
            full_house: 7.0, flush: 5.0, straight: 3.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 1.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: Some(100.0), five_of_a_kind: Some(200.0),
            min_pair_rank: 11,
        }),

        // ====== ADDITIONAL JOKER POKER TWO PAIR VARIANTS ======
        "joker-poker-two-pair-20-10" => Some(Paytable {
            id: id.to_string(),
            name: "Joker Poker Two Pair 20/10 (99.49%)".to_string(),
            game_family: GameFamily::JokerPokerTwoPair,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 20.0,
            full_house: 10.0, flush: 6.0, straight: 5.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: Some(50.0), five_of_a_kind: Some(100.0),
            min_pair_rank: 0,
        }),
        "joker-poker-two-pair-20-8" => Some(Paytable {
            id: id.to_string(),
            name: "Joker Poker Two Pair 20/8 (99.08%)".to_string(),
            game_family: GameFamily::JokerPokerTwoPair,
            royal_flush: 1000.0, straight_flush: 50.0, four_of_a_kind: 20.0,
            full_house: 8.0, flush: 7.0, straight: 5.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: Some(50.0), five_of_a_kind: Some(100.0),
            min_pair_rank: 0,
        }),
        "joker-poker-two-pair-20-9" => Some(Paytable {
            id: id.to_string(),
            name: "Joker Poker Two Pair 20/9 (97.99%)".to_string(),
            game_family: GameFamily::JokerPokerTwoPair,
            royal_flush: 800.0, straight_flush: 50.0, four_of_a_kind: 20.0,
            full_house: 9.0, flush: 6.0, straight: 5.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: Some(50.0), five_of_a_kind: Some(100.0),
            min_pair_rank: 0,
        }),

        // ====== ADDITIONAL DOUBLE JOKER VARIANTS ======
        "double-joker-9-6-940" => Some(Paytable {
            id: id.to_string(),
            name: "Double Joker 9/6 940 (100.65%)".to_string(),
            game_family: GameFamily::DoubleJoker,
            royal_flush: 940.0, straight_flush: 25.0, four_of_a_kind: 10.0,
            full_house: 9.0, flush: 6.0, straight: 4.0,
            three_of_a_kind: 1.0, two_pair: 1.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: Some(100.0), five_of_a_kind: Some(50.0),
            min_pair_rank: 0,
        }),
        "double-joker-9-6-800" => Some(Paytable {
            id: id.to_string(),
            name: "Double Joker 9/6 800 (100.37%)".to_string(),
            game_family: GameFamily::DoubleJoker,
            royal_flush: 800.0, straight_flush: 25.0, four_of_a_kind: 10.0,
            full_house: 9.0, flush: 6.0, straight: 4.0,
            three_of_a_kind: 1.0, two_pair: 1.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: Some(100.0), five_of_a_kind: Some(50.0),
            min_pair_rank: 0,
        }),
        "double-joker-9-5-4" => Some(Paytable {
            id: id.to_string(),
            name: "Double Joker 9/5/4 (99.97%)".to_string(),
            game_family: GameFamily::DoubleJoker,
            royal_flush: 800.0, straight_flush: 25.0, four_of_a_kind: 9.0,
            full_house: 5.0, flush: 4.0, straight: 3.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: Some(100.0), five_of_a_kind: Some(50.0),
            min_pair_rank: 0,
        }),
        "double-joker-8-6-4" => Some(Paytable {
            id: id.to_string(),
            name: "Double Joker 8/6/4 (99.94%)".to_string(),
            game_family: GameFamily::DoubleJoker,
            royal_flush: 800.0, straight_flush: 25.0, four_of_a_kind: 8.0,
            full_house: 6.0, flush: 4.0, straight: 3.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: Some(100.0), five_of_a_kind: Some(50.0),
            min_pair_rank: 0,
        }),
        "double-joker-8-5-4" => Some(Paytable {
            id: id.to_string(),
            name: "Double Joker 8/5/4 (98.10%)".to_string(),
            game_family: GameFamily::DoubleJoker,
            royal_flush: 800.0, straight_flush: 25.0, four_of_a_kind: 8.0,
            full_house: 5.0, flush: 4.0, straight: 3.0,
            three_of_a_kind: 2.0, two_pair: 1.0, high_pair: 0.0,
            four_aces: None, four_2_4: None, four_5_k: None, four_jqk: None,
            four_8s: None, four_7s: None,
            four_aces_with_kicker: None, four_2_4_with_kicker: None,
            four_aces_with_face: None, four_jqk_with_face: None,
            four_deuces: None, wild_royal: Some(100.0), five_of_a_kind: Some(50.0),
            min_pair_rank: 0,
        }),

        _ => None,
    }
}

fn get_all_paytable_ids() -> Vec<&'static str> {
    vec![
        // Jacks or Better
        "jacks-or-better-9-6", "jacks-or-better-9-5", "jacks-or-better-8-6",
        "jacks-or-better-8-5", "jacks-or-better-7-5", "jacks-or-better-6-5",
        "jacks-or-better-9-6-90", "jacks-or-better-9-6-940", "jacks-or-better-8-5-35",
        // Tens or Better
        "tens-or-better-6-5",
        // Bonus Poker
        "bonus-poker-8-5", "bonus-poker-7-5", "bonus-poker-6-5", "bonus-poker-7-5-1200",
        // Bonus Poker Deluxe
        "bonus-poker-deluxe-9-6", "bonus-poker-deluxe-8-6", "bonus-poker-deluxe-8-5",
        "bonus-poker-deluxe-7-5", "bonus-poker-deluxe-6-5", "bonus-poker-deluxe-9-5", "bonus-poker-deluxe-8-6-100",
        // Aces and Faces
        "aces-and-faces-8-5", "aces-and-faces-7-6", "aces-and-faces-7-5", "aces-and-faces-6-5",
        // Aces and Eights
        "aces-and-eights-8-5", "aces-and-eights-7-5",
        // Triple Bonus
        "triple-bonus-9-5", "triple-bonus-8-5", "triple-bonus-7-5",
        // Triple Bonus Plus
        "triple-bonus-plus-9-5", "triple-bonus-plus-8-5", "triple-bonus-plus-7-5",
        // Super Aces
        "super-aces-8-5", "super-aces-7-5", "super-aces-6-5",
        // Double Jackpot
        "double-jackpot-8-5", "double-jackpot-7-5",
        // Double Double Jackpot
        "double-double-jackpot-10-6", "double-double-jackpot-9-6",
        // Double Bonus
        "double-bonus-10-7", "double-bonus-10-7-100", "double-bonus-10-7-80", "double-bonus-10-6",
        "double-bonus-10-7-4", "double-bonus-9-7-5", "double-bonus-9-6-5", "double-bonus-9-6-4",
        // Super Double Bonus
        "super-double-bonus-9-5", "super-double-bonus-8-5", "super-double-bonus-7-5", "super-double-bonus-6-5",
        // Double Double Bonus
        "double-double-bonus-10-6-100", "double-double-bonus-10-6", "double-double-bonus-9-6",
        "double-double-bonus-9-5", "double-double-bonus-8-5", "double-double-bonus-7-5", "double-double-bonus-6-5",
        // White Hot Aces
        "white-hot-aces-9-5", "white-hot-aces-8-5", "white-hot-aces-7-5", "white-hot-aces-6-5",
        // Triple Double Bonus
        "triple-double-bonus-9-7", "triple-double-bonus-9-6", "triple-double-bonus-8-5",
        // Triple Triple Bonus
        "triple-triple-bonus-9-6", "triple-triple-bonus-9-5", "triple-triple-bonus-8-5", "triple-triple-bonus-7-5",
        // Royal Aces Bonus
        "royal-aces-bonus-9-6", "royal-aces-bonus-10-5", "royal-aces-bonus-8-6", "royal-aces-bonus-9-5",
        // A-c-e-s Bonus
        "aces-bonus-8-5", "aces-bonus-7-5", "aces-bonus-6-5",
        // Bonus Aces and Faces
        "bonus-aces-faces-8-5", "bonus-aces-faces-7-5", "bonus-aces-faces-6-5",
        // DDB Aces and Faces
        "ddb-aces-faces-9-6", "ddb-aces-faces-9-5",
        // DDB Plus
        "ddb-plus-9-6", "ddb-plus-9-5", "ddb-plus-8-5",
        // All American
        "all-american-35-8", "all-american-30-8", "all-american-25-8", "all-american-40-7",
        // Deuces Wild
        "deuces-wild-full-pay", "deuces-wild-nsud", "deuces-wild-illinois", "deuces-wild-20-12-9",
        "deuces-wild-25-15-8", "deuces-wild-20-15-9", "deuces-wild-25-12-9", "deuces-wild-colorado",
        // Deuces Wild 44
        "deuces-wild-44-apdw", "deuces-wild-44-nsud", "deuces-wild-44-illinois",
        // Loose Deuces
        "loose-deuces-500-17", "loose-deuces-500-15", "loose-deuces-500-12", "loose-deuces-400-12",
        // Bonus Poker Plus
        "bonus-poker-plus-10-7", "bonus-poker-plus-9-6",
        // Double Deuces Wild
        "double-deuces-wild-10-10", "double-deuces-wild-16-13", "double-deuces-wild-samstown",
        "double-deuces-wild-downtown", "double-deuces-wild-16-11", "double-deuces-wild-16-10",
        // Triple Deuces Wild
        "triple-deuces-wild-9-6", "triple-deuces-wild-11-8", "triple-deuces-wild-10-8",
        // Deluxe Deuces Wild
        "deluxe-deuces-wild-940", "deluxe-deuces-wild-800",
        // Double Bonus Deuces Wild
        "double-bonus-deuces-12", "double-bonus-deuces-9",
        // Super Bonus Deuces Wild
        "super-bonus-deuces-10", "super-bonus-deuces-9", "super-bonus-deuces-8",
        // Deuces Joker Wild
        "deuces-joker-wild-12-9", "deuces-joker-wild-10-8",
        // Joker Poker Kings
        "joker-poker-kings-100-64", "joker-poker-kings-98-60", "joker-poker-kings-97-58",
        "joker-poker-kings-20-7", "joker-poker-kings-940-20", "joker-poker-kings-20-6",
        "joker-poker-kings-18-7", "joker-poker-kings-17-7", "joker-poker-kings-15-7",
        // Joker Poker Two Pair
        "joker-poker-two-pair-99-92", "joker-poker-two-pair-98-59",
        "joker-poker-two-pair-20-10", "joker-poker-two-pair-20-8", "joker-poker-two-pair-20-9",
        // Double Joker
        "double-joker-9-6", "double-joker-5-4", "double-joker-9-6-940", "double-joker-9-6-800",
        "double-joker-9-5-4", "double-joker-8-6-4", "double-joker-8-5-4",
    ]
}

// ============================================================================
// HAND EVALUATION HELPERS
// ============================================================================

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
        if card.rank() < 13 {
            counts[card.rank() as usize] += 1;
        }
    }
    counts
}

// Count deuces (rank 0 = '2') in hand
fn count_deuces(hand: &[Card]) -> u8 {
    hand.iter().filter(|c| c.rank() == 0).count() as u8
}

// Count jokers in hand
fn count_jokers(hand: &[Card]) -> u8 {
    hand.iter().filter(|c| c.is_joker()).count() as u8
}

// Get non-wild cards (for deuces wild)
fn get_non_deuces(hand: &[Card]) -> Vec<Card> {
    hand.iter().filter(|c| c.rank() != 0).cloned().collect()
}

// Get non-joker cards (for joker poker)
fn get_non_jokers(hand: &[Card]) -> Vec<Card> {
    hand.iter().filter(|c| !c.is_joker()).cloned().collect()
}

// Check for flush with wild cards
fn is_flush_wild(non_wilds: &[Card]) -> bool {
    if non_wilds.is_empty() { return true; }
    let suit = non_wilds[0].suit();
    non_wilds.iter().all(|c| c.suit() == suit)
}

// Check for straight with wild cards
fn is_straight_wild(non_wilds: &[Card], num_wilds: u8) -> bool {
    if non_wilds.is_empty() { return true; }

    let mut ranks: Vec<u8> = non_wilds.iter().map(|c| c.rank()).collect();
    ranks.sort();

    // Check for duplicate ranks - can't make straight with pairs
    for i in 1..ranks.len() {
        if ranks[i] == ranks[i - 1] {
            return false;
        }
    }

    // Regular straights: ALL cards must fit within a 5-rank window
    for start in 0..=8u8 {
        let end = start + 4;
        if ranks.iter().all(|&r| r >= start && r <= end) {
            let gaps = (start..=end).filter(|r| !ranks.contains(r)).count() as u8;
            if gaps == num_wilds {
                return true;
            }
        }
    }

    // Wheel (A-2-3-4-5)
    let wheel_ranks = [0u8, 1, 2, 3, 12]; // 2, 3, 4, 5, A (but 2s are wild in deuces)
    // For deuces wild, wheel positions are 3,4,5,A (ranks 1,2,3,12)
    let deuces_wheel_ranks = [1u8, 2, 3, 12];

    if ranks.iter().all(|&r| wheel_ranks.contains(&r) || deuces_wheel_ranks.contains(&r)) {
        let target_ranks: Vec<u8> = if num_wilds > 0 && ranks.iter().any(|&r| r == 0) {
            // If we have deuces as wilds, use normal wheel
            wheel_ranks.to_vec()
        } else {
            deuces_wheel_ranks.to_vec()
        };
        let gaps = target_ranks.iter().filter(|&&r| !ranks.contains(&r)).count() as u8;
        if gaps <= num_wilds {
            return true;
        }
    }

    false
}

// Check for royal flush with wilds
fn is_royal_wild(non_wilds: &[Card], num_wilds: u8) -> bool {
    if !is_flush_wild(non_wilds) { return false; }

    let ranks: Vec<u8> = non_wilds.iter().map(|c| c.rank()).collect();
    let royal_ranks = [8u8, 9, 10, 11, 12]; // T, J, Q, K, A

    let needed: u8 = royal_ranks.iter().filter(|&&r| !ranks.contains(&r)).count() as u8;
    needed <= num_wilds
}

// ============================================================================
// PAYOUT CALCULATION
// ============================================================================

fn get_standard_payout(hand: &[Card], paytable: &Paytable) -> f64 {
    if hand.len() != 5 { return 0.0; }

    let flush = is_flush(hand);
    let straight = is_straight(hand);
    let counts = get_rank_counts(hand);

    // Royal Flush
    if flush && straight {
        let mut ranks: Vec<u8> = hand.iter().map(|c| c.rank()).collect();
        ranks.sort();
        if ranks == vec![8, 9, 10, 11, 12] {
            return paytable.royal_flush;
        }
        return paytable.straight_flush;
    }

    // Count pairs, trips, quads
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

    // Four of a Kind
    if let Some(qr) = quad_rank {
        // Check for kicker bonuses first (DDB, TDB)
        if paytable.has_kicker_bonus() {
            let kicker_rank = counts.iter().enumerate()
                .find(|(r, &c)| c == 1 && *r as u8 != qr)
                .map(|(r, _)| r as u8)
                .unwrap_or(0);

            let is_low_kicker = kicker_rank <= 2 || kicker_rank == 12; // 2,3,4 or A

            if qr == 12 { // Four Aces
                if is_low_kicker {
                    if let Some(payout) = paytable.four_aces_with_kicker {
                        return payout;
                    }
                }
                if let Some(payout) = paytable.four_aces {
                    return payout;
                }
            } else if qr <= 2 { // Four 2s, 3s, or 4s
                if is_low_kicker {
                    if let Some(payout) = paytable.four_2_4_with_kicker {
                        return payout;
                    }
                }
                if let Some(payout) = paytable.four_2_4 {
                    return payout;
                }
            } else { // Four 5s through Kings
                if let Some(payout) = paytable.four_5_k {
                    return payout;
                }
            }
        }

        // Check for face kicker bonuses (Double Jackpot, Double Double Jackpot)
        if paytable.has_face_kicker_bonus() {
            let kicker_rank = counts.iter().enumerate()
                .find(|(r, &c)| c == 1 && *r as u8 != qr)
                .map(|(r, _)| r as u8)
                .unwrap_or(0);

            // Face kicker = J (9), Q (10), K (11), A (12)
            let is_face_kicker = kicker_rank >= 9;

            if qr == 12 { // Four Aces
                if is_face_kicker {
                    if let Some(payout) = paytable.four_aces_with_face {
                        return payout;
                    }
                }
                if let Some(payout) = paytable.four_aces {
                    return payout;
                }
            } else if qr >= 9 && qr <= 11 { // Four J, Q, K
                if is_face_kicker {
                    if let Some(payout) = paytable.four_jqk_with_face {
                        return payout;
                    }
                }
                if let Some(payout) = paytable.four_jqk {
                    return payout;
                }
            } else { // Four others (5-10)
                return paytable.four_of_a_kind;
            }
        }

        // Standard bonus payouts (without kicker)
        if qr == 12 { // Four Aces
            if let Some(payout) = paytable.four_aces {
                return payout;
            }
        }
        if qr <= 2 { // Four 2s, 3s, or 4s
            if let Some(payout) = paytable.four_2_4 {
                return payout;
            }
        }
        // Four J, Q, K (Aces and Faces, Super Double Bonus)
        if qr >= 9 && qr <= 11 {
            if let Some(payout) = paytable.four_jqk {
                return payout;
            }
        }
        // Four 8s (Aces and Eights) - rank 6
        if qr == 6 {
            if let Some(payout) = paytable.four_8s {
                return payout;
            }
        }
        // Four 7s (Aces and Eights) - rank 5
        if qr == 5 {
            if let Some(payout) = paytable.four_7s {
                return payout;
            }
        }
        // Four 5-K (or default)
        if let Some(payout) = paytable.four_5_k {
            return payout;
        }
        return paytable.four_of_a_kind;
    }

    // Full House
    if trips > 0 && pairs > 0 {
        return paytable.full_house;
    }

    // Flush
    if flush {
        return paytable.flush;
    }

    // Straight
    if straight {
        return paytable.straight;
    }

    // Three of a Kind
    if trips > 0 {
        return paytable.three_of_a_kind;
    }

    // Two Pair
    if pairs == 2 {
        return paytable.two_pair;
    }

    // High Pair
    if pairs == 1 {
        let pair_rank = pair_ranks[0] as u8;
        if pair_rank >= paytable.min_pair_rank {
            return paytable.high_pair;
        }
    }

    0.0
}

fn get_deuces_wild_payout(hand: &[Card], paytable: &Paytable) -> f64 {
    let num_deuces = count_deuces(hand);
    let non_deuces = get_non_deuces(hand);

    // Get rank counts for non-deuces only
    let mut counts = [0u8; 13];
    for card in &non_deuces {
        counts[card.rank() as usize] += 1;
    }

    let max_count = *counts.iter().max().unwrap_or(&0);

    let is_flush = is_flush_wild(&non_deuces);
    let is_straight = is_straight_wild(&non_deuces, num_deuces);

    // Natural Royal (no wilds)
    if num_deuces == 0 && is_flush && is_straight {
        let mut ranks: Vec<u8> = non_deuces.iter().map(|c| c.rank()).collect();
        ranks.sort();
        if ranks == vec![8, 9, 10, 11, 12] {
            return paytable.royal_flush;
        }
    }

    // Four Deuces
    if num_deuces == 4 {
        return paytable.four_deuces.unwrap_or(200.0);
    }

    // Wild Royal Flush
    if is_royal_wild(&non_deuces, num_deuces) && num_deuces > 0 {
        return paytable.wild_royal.unwrap_or(25.0);
    }

    // Five of a Kind
    if max_count + num_deuces >= 5 {
        return paytable.five_of_a_kind.unwrap_or(15.0);
    }

    // Straight Flush (not royal)
    if is_flush && is_straight && !is_royal_wild(&non_deuces, num_deuces) {
        return paytable.straight_flush;
    }

    // Four of a Kind
    if max_count + num_deuces >= 4 {
        return paytable.four_of_a_kind;
    }

    // Full House
    if max_count + num_deuces >= 3 {
        let mut sorted_counts: Vec<u8> = counts.iter().cloned().filter(|&c| c > 0).collect();
        sorted_counts.sort();
        sorted_counts.reverse();

        let can_make_full_house = if sorted_counts.len() >= 2 {
            let need_for_trips = 3_u8.saturating_sub(sorted_counts[0]);
            let need_for_pair = 2_u8.saturating_sub(sorted_counts[1]);
            need_for_trips + need_for_pair <= num_deuces
        } else if sorted_counts.len() == 1 {
            sorted_counts[0] + num_deuces >= 5 && sorted_counts[0] >= 2
        } else {
            num_deuces >= 5
        };

        if can_make_full_house && max_count + num_deuces < 4 {
            return paytable.full_house;
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
    if max_count + num_deuces >= 3 {
        return paytable.three_of_a_kind;
    }

    0.0
}

fn get_joker_payout(hand: &[Card], paytable: &Paytable) -> f64 {
    let num_jokers = count_jokers(hand);
    let non_jokers = get_non_jokers(hand);

    // Get rank counts for non-jokers
    let mut counts = [0u8; 13];
    for card in &non_jokers {
        if card.rank() < 13 {
            counts[card.rank() as usize] += 1;
        }
    }

    let max_count = *counts.iter().max().unwrap_or(&0);
    let num_pairs = counts.iter().filter(|&&c| c == 2).count() as u8;

    let is_flush = is_flush_wild(&non_jokers);
    let is_straight = is_straight_wild(&non_jokers, num_jokers);

    // Natural Royal (no jokers)
    if num_jokers == 0 && is_flush && is_straight {
        let mut ranks: Vec<u8> = non_jokers.iter().map(|c| c.rank()).collect();
        ranks.sort();
        if ranks == vec![8, 9, 10, 11, 12] {
            return paytable.royal_flush;
        }
    }

    // Five of a Kind (with joker)
    if max_count + num_jokers >= 5 {
        return paytable.five_of_a_kind.unwrap_or(100.0);
    }

    // Wild Royal Flush
    if is_royal_wild(&non_jokers, num_jokers) && num_jokers > 0 {
        return paytable.wild_royal.unwrap_or(50.0);
    }

    // Straight Flush
    if is_flush && is_straight {
        return paytable.straight_flush;
    }

    // Four of a Kind
    if max_count + num_jokers >= 4 {
        return paytable.four_of_a_kind;
    }

    // Full House
    if (max_count + num_jokers >= 3) && (num_pairs >= 1 || max_count >= 2) {
        let mut sorted_counts: Vec<u8> = counts.iter().cloned().filter(|&c| c > 0).collect();
        sorted_counts.sort();
        sorted_counts.reverse();

        let can_make_full_house = if sorted_counts.len() >= 2 {
            let need_for_trips = 3_u8.saturating_sub(sorted_counts[0]);
            let need_for_pair = 2_u8.saturating_sub(sorted_counts[1]);
            need_for_trips + need_for_pair <= num_jokers
        } else {
            false
        };

        if can_make_full_house && max_count + num_jokers < 4 {
            return paytable.full_house;
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
    if max_count + num_jokers >= 3 {
        return paytable.three_of_a_kind;
    }

    // Two Pair
    if num_pairs == 2 || (num_pairs == 1 && num_jokers >= 1 && max_count < 3) {
        if paytable.two_pair > 0.0 {
            return paytable.two_pair;
        }
    }

    // High Pair (Kings or better for most joker games)
    if num_pairs == 1 || (num_jokers >= 1 && max_count >= 1) {
        let mut pair_ranks: Vec<usize> = counts.iter().enumerate()
            .filter(|(_, &c)| c >= 2 || (c == 1 && num_jokers >= 1))
            .map(|(r, _)| r)
            .collect();
        pair_ranks.sort();
        pair_ranks.reverse();

        if !pair_ranks.is_empty() && pair_ranks[0] as u8 >= paytable.min_pair_rank {
            return paytable.high_pair;
        }
        // With a joker, we can make a pair of any rank
        if num_jokers >= 1 && paytable.high_pair > 0.0 {
            // Find highest card rank
            if let Some(highest) = counts.iter().enumerate().rev().find(|(_, &c)| c >= 1).map(|(r, _)| r) {
                if highest as u8 >= paytable.min_pair_rank {
                    return paytable.high_pair;
                }
            }
        }
    }

    0.0
}

fn get_payout(hand: &[Card], paytable: &Paytable) -> f64 {
    if hand.len() != 5 { return 0.0; }

    if paytable.is_deuces_wild() {
        get_deuces_wild_payout(hand, paytable)
    } else if paytable.is_joker_poker() {
        get_joker_payout(hand, paytable)
    } else {
        get_standard_payout(hand, paytable)
    }
}

// ============================================================================
// EV CALCULATION
// ============================================================================

fn calculate_hold_ev(hand: &Hand, hold_mask: u8, paytable: &Paytable, deck_size: u8) -> f64 {
    let mut held: Vec<Card> = Vec::with_capacity(5);
    for i in 0..5 {
        if hold_mask & (1 << i) != 0 {
            held.push(hand[i]);
        }
    }

    let num_to_draw = 5 - held.len();

    if num_to_draw == 0 {
        let final_hand: [Card; 5] = held.try_into().unwrap();
        return get_payout(&final_hand, paytable);
    }

    // Build remaining deck
    let mut deck: Vec<Card> = Vec::with_capacity((deck_size - 5) as usize);
    for card_idx in 0..deck_size {
        let card = Card(card_idx);
        if !hand.contains(&card) {
            deck.push(card);
        }
    }

    let mut total_payout = 0.0;
    let mut count = 0u64;

    for draw in deck.iter().combinations(num_to_draw) {
        let mut final_hand = held.clone();
        for &card in &draw {
            final_hand.push(*card);
        }
        let final_arr: [Card; 5] = final_hand.try_into().unwrap();
        total_payout += get_payout(&final_arr, paytable);
        count += 1;
    }

    total_payout / count as f64
}

fn analyze_hand(hand: &Hand, paytable: &Paytable) -> (u8, f64, HashMap<String, f64>) {
    let deck_size = if paytable.is_joker_poker() { 53 } else { 52 };

    let mut hold_evs: HashMap<String, f64> = HashMap::new();
    let mut best_hold = 0u8;
    let mut best_ev = f64::NEG_INFINITY;

    for hold_mask in 0..32u8 {
        let ev = calculate_hold_ev(hand, hold_mask, paytable, deck_size);
        hold_evs.insert(hold_mask.to_string(), (ev * 1000000.0).round() / 1000000.0);
        if ev > best_ev {
            best_ev = ev;
            best_hold = hold_mask;
        }
    }

    (best_hold, (best_ev * 1000000.0).round() / 1000000.0, hold_evs)
}

// ============================================================================
// CANONICAL HAND GENERATION
// ============================================================================

fn hand_to_canonical_key(hand: &Hand) -> String {
    let mut sorted: Vec<Card> = hand.to_vec();
    sorted.sort_by_key(|c| c.rank());

    let mut suit_map: HashMap<u8, char> = HashMap::new();
    let suit_letters = ['a', 'b', 'c', 'd'];
    let mut next_suit = 0;

    let mut key = String::with_capacity(10);
    for card in &sorted {
        if card.is_joker() {
            key.push('W');
            key.push('w');
        } else {
            key.push(card.rank_char());
            let suit_char = *suit_map.entry(card.suit()).or_insert_with(|| {
                let c = suit_letters[next_suit];
                next_suit += 1;
                c
            });
            key.push(suit_char);
        }
    }

    key
}

fn generate_canonical_hands(include_joker: bool) -> Vec<(String, Hand)> {
    println!("Generating canonical hands{}...", if include_joker { " (with joker)" } else { "" });
    let mut seen: HashMap<String, Hand> = HashMap::new();
    let max_card = if include_joker { 53u8 } else { 52u8 };

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

// ============================================================================
// JSON OUTPUT STRUCTURES
// ============================================================================

#[derive(Serialize, Deserialize)]
struct StrategyEntry {
    hold: u8,
    ev: f64,
    hold_evs: HashMap<String, f64>,
}

#[derive(Serialize, Deserialize)]
struct StrategyFile {
    game: String,
    paytable_id: String,
    version: u32,
    generated: String,
    hand_count: usize,
    strategies: HashMap<String, StrategyEntry>,
}

#[derive(Serialize, Deserialize, Clone)]
struct ManifestEntry {
    version: u32,
    updated_at: String,
    file: String,
    size: u64,
    hand_count: usize,
}

#[derive(Serialize, Deserialize, Default)]
struct Manifest {
    strategies: HashMap<String, ManifestEntry>,
}

// ============================================================================
// BINARY FORMAT (.vpstrat) - Memory-mapped strategy files
// ============================================================================
//
// File format:
//   Header (64 bytes):
//     - Magic: "VPST" (4 bytes)
//     - Version: u16 LE (2 bytes) - format version, currently 1
//     - Flags: u16 LE (2 bytes) - bit 0: has_joker
//     - Entry count: u32 LE (4 bytes)
//     - Key length: u8 (1 byte) - 10 for standard, 12 for joker
//     - Reserved: 51 bytes (zero-filled)
//   Index section (entry_count * key_length bytes):
//     - Canonical keys in sorted order (ASCII, e.g., "2a3b4c5d6a")
//   Data section (entry_count * 5 bytes):
//     - hold_mask: u8 (1 byte) - bitmask of cards to hold
//     - ev: f32 LE (4 bytes) - expected value
//
// Lookup: binary search on index section, then direct access to data section

const VPSTRAT_MAGIC: &[u8; 4] = b"VPST";
const VPSTRAT_VERSION: u16 = 1;
const VPSTRAT_HEADER_SIZE: usize = 64;
const VPSTRAT_DATA_ENTRY_SIZE: usize = 5;

fn generate_binary_strategy(
    strategies: &HashMap<String, StrategyEntry>,
    has_joker: bool,
) -> Vec<u8> {
    let key_length: u8 = if has_joker { 12 } else { 10 };
    let entry_count = strategies.len() as u32;

    // Sort canonical keys
    let mut sorted_keys: Vec<&String> = strategies.keys().collect();
    sorted_keys.sort();

    // Calculate sizes
    let index_size = entry_count as usize * key_length as usize;
    let data_size = entry_count as usize * VPSTRAT_DATA_ENTRY_SIZE;
    let total_size = VPSTRAT_HEADER_SIZE + index_size + data_size;

    let mut buffer = vec![0u8; total_size];

    // Write header
    buffer[0..4].copy_from_slice(VPSTRAT_MAGIC);
    buffer[4..6].copy_from_slice(&VPSTRAT_VERSION.to_le_bytes());
    let flags: u16 = if has_joker { 1 } else { 0 };
    buffer[6..8].copy_from_slice(&flags.to_le_bytes());
    buffer[8..12].copy_from_slice(&entry_count.to_le_bytes());
    buffer[12] = key_length;
    // bytes 13-63 are reserved (already zero)

    // Write index section (sorted canonical keys)
    let mut index_offset = VPSTRAT_HEADER_SIZE;
    for key in &sorted_keys {
        let key_bytes = key.as_bytes();
        let len = std::cmp::min(key_bytes.len(), key_length as usize);
        buffer[index_offset..index_offset + len].copy_from_slice(&key_bytes[..len]);
        // Pad with zeros if key is shorter than key_length
        index_offset += key_length as usize;
    }

    // Write data section
    let data_start = VPSTRAT_HEADER_SIZE + index_size;
    for (i, key) in sorted_keys.iter().enumerate() {
        let entry = &strategies[*key];
        let data_offset = data_start + i * VPSTRAT_DATA_ENTRY_SIZE;

        buffer[data_offset] = entry.hold;
        buffer[data_offset + 1..data_offset + 5].copy_from_slice(&(entry.ev as f32).to_le_bytes());
    }

    buffer
}

fn save_binary_strategy(binary: &[u8], paytable_id: &str, output_dir: &str) -> Result<String, String> {
    let filename = format!("strategy_{}.vpstrat", paytable_id.replace("-", "_"));
    let path = Path::new(output_dir).join(&filename);

    // Ensure directory exists
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).map_err(|e| format!("Failed to create directory: {}", e))?;
    }

    fs::write(&path, binary).map_err(|e| format!("Failed to write binary file: {}", e))?;

    Ok(path.to_string_lossy().to_string())
}

// ============================================================================
// BINARY FORMAT V2 (.vpstrat2) - Full holdEvs with variable scale
// ============================================================================
//
// File format:
//   Header (64 bytes):
//     - Magic: "VPS2" (4 bytes)
//     - Version: u16 LE (2 bytes) - format version, currently 2
//     - Flags: u16 LE (2 bytes) - bit 0: has_joker
//     - Entry count: u32 LE (4 bytes)
//     - Key length: u8 (1 byte) - 10 for standard, 12 for joker
//     - Reserved: 51 bytes (zero-filled)
//   Index section (entry_count * key_length bytes):
//     - Canonical keys in sorted order (ASCII, e.g., "2a3b4c5d6a")
//   Data section (entry_count * 66 bytes):
//     - best_hold: u8 (1 byte) - bitmask of optimal cards to hold (0-31)
//     - scale: u8 (1 byte) - EV scale factor:
//         0 = multiply by 0.0001 (range 0.0000 - 6.5535)
//         1 = multiply by 0.001  (range 0.000 - 65.535)
//         2 = multiply by 0.01   (range 0.00 - 655.35)
//         3 = multiply by 0.1    (range 0.0 - 6553.5)
//     - evs[32]: u16[32] LE (64 bytes) - EVs for hold masks 0-31
//
// Lookup: binary search on index section, then direct access to data section
// EV retrieval: evs[hold_mask] * scale_factor

const VPS2_MAGIC: &[u8; 4] = b"VPS2";
const VPS2_VERSION: u16 = 2;
const VPS2_HEADER_SIZE: usize = 64;
const VPS2_DATA_ENTRY_SIZE: usize = 66; // 1 (bestHold) + 1 (scale) + 64 (32 * u16)

/// Scale factors for EV encoding
const VPS2_SCALES: [f64; 4] = [0.0001, 0.001, 0.01, 0.1];

/// Determine the optimal scale for a set of EVs
fn determine_scale(evs: &[f64; 32]) -> u8 {
    let max_ev = evs.iter().cloned().fold(0.0f64, f64::max);

    // Find the smallest scale that can represent max_ev
    // Scale 0: max 6.5535, Scale 1: max 65.535, Scale 2: max 655.35, Scale 3: max 6553.5
    if max_ev <= 6.5535 {
        0
    } else if max_ev <= 65.535 {
        1
    } else if max_ev <= 655.35 {
        2
    } else {
        3
    }
}

/// Encode an EV value with the given scale
fn encode_ev(ev: f64, scale: u8) -> u16 {
    let scale_factor = VPS2_SCALES[scale as usize];
    let scaled = (ev / scale_factor).round() as u32;
    scaled.min(65535) as u16
}

/// Generate VPS2 binary format with full holdEvs
fn generate_binary_strategy_v2(
    strategies: &HashMap<String, StrategyEntry>,
    has_joker: bool,
) -> Vec<u8> {
    let key_length: u8 = if has_joker { 12 } else { 10 };
    let entry_count = strategies.len() as u32;

    // Sort canonical keys
    let mut sorted_keys: Vec<&String> = strategies.keys().collect();
    sorted_keys.sort();

    // Calculate sizes
    let index_size = entry_count as usize * key_length as usize;
    let data_size = entry_count as usize * VPS2_DATA_ENTRY_SIZE;
    let total_size = VPS2_HEADER_SIZE + index_size + data_size;

    let mut buffer = vec![0u8; total_size];

    // Write header
    buffer[0..4].copy_from_slice(VPS2_MAGIC);
    buffer[4..6].copy_from_slice(&VPS2_VERSION.to_le_bytes());
    let flags: u16 = if has_joker { 1 } else { 0 };
    buffer[6..8].copy_from_slice(&flags.to_le_bytes());
    buffer[8..12].copy_from_slice(&entry_count.to_le_bytes());
    buffer[12] = key_length;
    // bytes 13-63 are reserved (already zero)

    // Write index section (sorted canonical keys)
    let mut index_offset = VPS2_HEADER_SIZE;
    for key in &sorted_keys {
        let key_bytes = key.as_bytes();
        let len = std::cmp::min(key_bytes.len(), key_length as usize);
        buffer[index_offset..index_offset + len].copy_from_slice(&key_bytes[..len]);
        index_offset += key_length as usize;
    }

    // Write data section
    let data_start = VPS2_HEADER_SIZE + index_size;
    for (i, key) in sorted_keys.iter().enumerate() {
        let entry = &strategies[*key];
        let data_offset = data_start + i * VPS2_DATA_ENTRY_SIZE;

        // Build EV array from hold_evs HashMap
        let mut evs: [f64; 32] = [0.0; 32];
        for (mask_str, ev) in &entry.hold_evs {
            if let Ok(mask) = mask_str.parse::<usize>() {
                if mask < 32 {
                    evs[mask] = *ev;
                }
            }
        }

        // Determine scale for this hand
        let scale = determine_scale(&evs);

        // Write bestHold
        buffer[data_offset] = entry.hold;

        // Write scale
        buffer[data_offset + 1] = scale;

        // Write 32 EVs as u16
        for (j, &ev) in evs.iter().enumerate() {
            let encoded = encode_ev(ev, scale);
            let ev_offset = data_offset + 2 + j * 2;
            buffer[ev_offset..ev_offset + 2].copy_from_slice(&encoded.to_le_bytes());
        }
    }

    buffer
}

fn save_binary_strategy_v2(binary: &[u8], paytable_id: &str, output_dir: &str) -> Result<String, String> {
    let filename = format!("strategy_{}.vpstrat2", paytable_id.replace("-", "_"));
    let path = Path::new(output_dir).join(&filename);

    // Ensure directory exists
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).map_err(|e| format!("Failed to create directory: {}", e))?;
    }

    fs::write(&path, binary).map_err(|e| format!("Failed to write binary file: {}", e))?;

    Ok(path.to_string_lossy().to_string())
}

// ============================================================================
// FILE GENERATION & UPLOAD
// ============================================================================

/// Returns (json_gz_bytes, binary_v1_bytes, binary_v2_bytes, hand_count, version)
fn generate_strategy_file(paytable: &Paytable) -> (Vec<u8>, Vec<u8>, Vec<u8>, usize, u32) {
    let include_joker = paytable.is_joker_poker();
    let all_hands = generate_canonical_hands(include_joker);
    let total = all_hands.len();

    println!("\nCalculating {} hands using {} threads...", total, rayon::current_num_threads());
    io::stdout().flush().unwrap();

    let processed = Arc::new(AtomicUsize::new(0));
    let total_for_progress = total;
    let calc_start = Instant::now();
    let last_print = Arc::new(AtomicUsize::new(0));

    // Calculate all strategies in parallel
    let strategies: HashMap<String, StrategyEntry> = all_hands
        .par_iter()
        .map(|(key, hand)| {
            let (best_hold, best_ev, hold_evs) = analyze_hand(hand, paytable);

            let count = processed.fetch_add(1, Ordering::Relaxed) + 1;
            // Print every 5% progress
            let pct = (count * 100) / total_for_progress;
            let last_pct = last_print.load(Ordering::Relaxed);
            if pct >= last_pct + 5 && last_print.compare_exchange(last_pct, pct, Ordering::SeqCst, Ordering::Relaxed).is_ok() {
                let elapsed = calc_start.elapsed().as_secs_f64();
                let rate = count as f64 / elapsed;
                let remaining_hands = total_for_progress - count;
                let eta_secs = remaining_hands as f64 / rate;
                let eta_mins = (eta_secs / 60.0).ceil() as u32;
                println!("  Progress: {:>3}% ({}/{}) | {:.0} hands/sec | ETA: {}m",
                    pct, count, total_for_progress, rate, eta_mins);
                io::stdout().flush().unwrap();
            }

            (key.clone(), StrategyEntry {
                hold: best_hold,
                ev: best_ev,
                hold_evs,
            })
        })
        .collect();

    let calc_elapsed = calc_start.elapsed().as_secs_f64();
    println!("  Completed {} hands in {:.1}s ({:.0} hands/sec)",
        strategies.len(), calc_elapsed, strategies.len() as f64 / calc_elapsed);

    // Determine version (start at 1 for new files)
    let version = 1u32;

    // Generate binary format v1 (bestHold + bestEv only)
    print!("  Generating binary v1... ");
    io::stdout().flush().unwrap();
    let binary_v1 = generate_binary_strategy(&strategies, include_joker);
    println!("Done! ({:.2} MB)", binary_v1.len() as f64 / 1024.0 / 1024.0);

    // Generate binary format v2 (full holdEvs)
    print!("  Generating binary v2... ");
    io::stdout().flush().unwrap();
    let binary_v2 = generate_binary_strategy_v2(&strategies, include_joker);
    println!("Done! ({:.2} MB)", binary_v2.len() as f64 / 1024.0 / 1024.0);

    // Build the JSON output structure
    let output = StrategyFile {
        game: paytable.name.clone(),
        paytable_id: paytable.id.clone(),
        version,
        generated: Utc::now().to_rfc3339(),
        hand_count: strategies.len(),
        strategies,
    };

    // Serialize to JSON
    print!("  Serializing... ");
    io::stdout().flush().unwrap();
    let json_string = serde_json::to_string(&output).expect("Failed to serialize");
    let json_size = json_string.len();

    // Compress with gzip
    print!("Compressing... ");
    io::stdout().flush().unwrap();
    let mut encoder = GzEncoder::new(Vec::new(), Compression::best());
    encoder.write_all(json_string.as_bytes()).expect("Failed to compress");
    let compressed = encoder.finish().expect("Failed to finish compression");

    let compressed_size = compressed.len();
    let ratio = (1.0 - compressed_size as f64 / json_size as f64) * 100.0;
    println!("Done! ({:.2} MB -> {:.2} MB, {:.0}% reduction)",
        json_size as f64 / 1024.0 / 1024.0,
        compressed_size as f64 / 1024.0 / 1024.0,
        ratio);

    (compressed, binary_v1, binary_v2, total, version)
}

fn get_storage_filename(paytable_id: &str) -> String {
    format!("strategy_{}.json.gz", paytable_id.replace("-", "_"))
}

fn save_locally(compressed: &[u8], paytable_id: &str, output_dir: &str) -> Result<String, String> {
    let filename = get_storage_filename(paytable_id);
    let path = Path::new(output_dir).join(&filename);

    // Ensure directory exists
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).map_err(|e| format!("Failed to create directory: {}", e))?;
    }

    fs::write(&path, compressed).map_err(|e| format!("Failed to write file: {}", e))?;

    Ok(path.to_string_lossy().to_string())
}

fn upload_to_storage(
    client: &reqwest::blocking::Client,
    compressed: &[u8],
    paytable_id: &str,
    supabase_url: &str,
    service_key: &str,
) -> Result<(), String> {
    let filename = get_storage_filename(paytable_id);
    let url = format!("{}/storage/v1/object/strategies/{}", supabase_url, filename);

    println!("Uploading to Supabase Storage...");
    println!("  URL: {}", url);

    let response = client
        .post(&url)
        .header("Authorization", format!("Bearer {}", service_key))
        .header("Content-Type", "application/gzip")
        .header("x-upsert", "true")
        .body(compressed.to_vec())
        .timeout(std::time::Duration::from_secs(120))
        .send()
        .map_err(|e| format!("Upload request failed: {}", e))?;

    if !response.status().is_success() {
        let status = response.status();
        let body = response.text().unwrap_or_default();
        return Err(format!("Upload failed: {} - {}", status, body));
    }

    println!("  ✓ Upload successful");
    Ok(())
}

fn fetch_manifest(
    client: &reqwest::blocking::Client,
    supabase_url: &str,
    service_key: &str,
) -> Manifest {
    let url = format!("{}/storage/v1/object/strategies/manifest.json", supabase_url);

    let response = match client
        .get(&url)
        .header("Authorization", format!("Bearer {}", service_key))
        .timeout(std::time::Duration::from_secs(30))
        .send()
    {
        Ok(r) => r,
        Err(_) => return Manifest::default(),
    };

    if !response.status().is_success() {
        return Manifest::default();
    }

    response.json().unwrap_or_default()
}

fn update_manifest(
    client: &reqwest::blocking::Client,
    supabase_url: &str,
    service_key: &str,
    paytable_id: &str,
    _version: u32,  // Not used - we increment from existing manifest version
    file_size: u64,
    hand_count: usize,
) -> Result<(), String> {
    // Fetch existing manifest
    let mut manifest = fetch_manifest(client, supabase_url, service_key);

    // Get existing version or default to 0
    let existing_version = manifest
        .strategies
        .get(paytable_id)
        .map(|e| e.version)
        .unwrap_or(0);

    let new_version = existing_version + 1;

    // Update entry
    manifest.strategies.insert(
        paytable_id.to_string(),
        ManifestEntry {
            version: new_version,
            updated_at: Utc::now().to_rfc3339(),
            file: get_storage_filename(paytable_id),
            size: file_size,
            hand_count,
        },
    );

    // Upload updated manifest
    let manifest_json = serde_json::to_string_pretty(&manifest)
        .map_err(|e| format!("Failed to serialize manifest: {}", e))?;

    let url = format!("{}/storage/v1/object/strategies/manifest.json", supabase_url);

    println!("Updating manifest.json (version {} -> {})...", existing_version, new_version);

    let response = client
        .post(&url)
        .header("Authorization", format!("Bearer {}", service_key))
        .header("Content-Type", "application/json")
        .header("x-upsert", "true")
        .body(manifest_json)
        .timeout(std::time::Duration::from_secs(30))
        .send()
        .map_err(|e| format!("Manifest upload failed: {}", e))?;

    if !response.status().is_success() {
        let status = response.status();
        let body = response.text().unwrap_or_default();
        return Err(format!("Manifest upload failed: {} - {}", status, body));
    }

    println!("  ✓ Manifest updated");
    Ok(())
}

// ============================================================================
// TEST MODE
// ============================================================================

fn make_hand(cards: [(u8, u8); 5]) -> Hand {
    // cards: [(rank, suit); 5] where rank: 0=2..12=A, suit: 0-3
    // Special: rank 255 = joker
    [
        Card(if cards[0].0 == 255 { 52 } else { cards[0].0 * 4 + cards[0].1 }),
        Card(if cards[1].0 == 255 { 52 } else { cards[1].0 * 4 + cards[1].1 }),
        Card(if cards[2].0 == 255 { 52 } else { cards[2].0 * 4 + cards[2].1 }),
        Card(if cards[3].0 == 255 { 52 } else { cards[3].0 * 4 + cards[3].1 }),
        Card(if cards[4].0 == 255 { 52 } else { cards[4].0 * 4 + cards[4].1 }),
    ]
}

fn hand_to_string(hand: &Hand) -> String {
    hand.iter().map(|c| {
        if c.is_joker() {
            "JK".to_string()
        } else {
            format!("{}{}", c.rank_char(), match c.suit() { 0 => 'h', 1 => 'd', 2 => 'c', _ => 's' })
        }
    }).collect::<Vec<_>>().join(" ")
}

fn run_tests(filter: Option<&str>) {
    println!("=== Video Poker Payout Tests ===\n");

    let mut passed = 0;
    let mut failed = 0;

    // Test hands - each is (description, hand, expected_payouts by game family)
    struct TestCase {
        name: &'static str,
        hand: Hand,
        tests: Vec<(&'static str, f64)>, // (paytable_id, expected_payout)
    }

    let test_cases = vec![
        // ============= STANDARD GAMES =============
        TestCase {
            name: "Royal Flush (As Ks Qs Js Ts)",
            hand: make_hand([(12, 3), (11, 3), (10, 3), (9, 3), (8, 3)]),
            tests: vec![
                ("jacks-or-better-9-6", 800.0),
                ("bonus-poker-8-5", 800.0),
                ("double-double-bonus-9-6", 800.0),
            ],
        },
        TestCase {
            name: "Straight Flush (9h 8h 7h 6h 5h)",
            hand: make_hand([(7, 0), (6, 0), (5, 0), (4, 0), (3, 0)]),
            tests: vec![
                ("jacks-or-better-9-6", 50.0),
                ("all-american-35-8", 200.0),
            ],
        },
        TestCase {
            name: "Four Aces (Ah Ad Ac As 5h)",
            hand: make_hand([(12, 0), (12, 1), (12, 2), (12, 3), (3, 0)]),
            tests: vec![
                ("jacks-or-better-9-6", 25.0),  // No bonus
                ("bonus-poker-8-5", 80.0),       // 80 for 4 Aces
                ("double-bonus-10-7", 160.0),    // 160 for 4 Aces
                ("double-double-bonus-9-6", 160.0), // 160 (no kicker)
            ],
        },
        TestCase {
            name: "Four Aces with 2 kicker (Ah Ad Ac As 2h)",
            hand: make_hand([(12, 0), (12, 1), (12, 2), (12, 3), (0, 0)]),
            tests: vec![
                ("jacks-or-better-9-6", 25.0),     // No bonus
                ("double-double-bonus-9-6", 400.0), // 400 with 2-4 kicker
                ("triple-double-bonus-9-6", 800.0), // 800 with A-4 kicker
            ],
        },
        TestCase {
            name: "Four 3s with Ace kicker (3h 3d 3c 3s Ah)",
            hand: make_hand([(1, 0), (1, 1), (1, 2), (1, 3), (12, 0)]),
            tests: vec![
                ("jacks-or-better-9-6", 25.0),     // No bonus
                ("bonus-poker-8-5", 40.0),          // 40 for 4 2-4
                ("double-double-bonus-9-6", 160.0), // 160 with A-4 kicker
                ("triple-double-bonus-9-6", 400.0), // 400 with A-4 kicker
            ],
        },
        TestCase {
            name: "Four Kings (Kh Kd Kc Ks 5h)",
            hand: make_hand([(11, 0), (11, 1), (11, 2), (11, 3), (3, 0)]),
            tests: vec![
                ("jacks-or-better-9-6", 25.0),   // Standard
                ("aces-and-faces-8-5", 40.0),    // Face card bonus (80 for Aces, 40 for J/Q/K)
                ("super-double-bonus-9-5", 120.0), // JQK bonus
            ],
        },
        // ============= ACES AND EIGHTS =============
        TestCase {
            name: "Four Aces - Aces & Eights (Ah Ad Ac As 5h)",
            hand: make_hand([(12, 0), (12, 1), (12, 2), (12, 3), (3, 0)]),
            tests: vec![
                ("aces-and-eights-8-5", 80.0),   // 4 Aces = 80
            ],
        },
        TestCase {
            name: "Four Eights (8h 8d 8c 8s 5h)",
            hand: make_hand([(6, 0), (6, 1), (6, 2), (6, 3), (3, 0)]),
            tests: vec![
                ("jacks-or-better-9-6", 25.0),   // Standard
                ("aces-and-eights-8-5", 80.0),   // 4 8s = 80 (same as Aces)
            ],
        },
        TestCase {
            name: "Four Sevens (7h 7d 7c 7s 5h)",
            hand: make_hand([(5, 0), (5, 1), (5, 2), (5, 3), (3, 0)]),
            tests: vec![
                ("jacks-or-better-9-6", 25.0),   // Standard
                ("aces-and-eights-8-5", 50.0),   // 4 7s = 50
            ],
        },
        TestCase {
            name: "Four Sixes - Aces & Eights (6h 6d 6c 6s 5h)",
            hand: make_hand([(4, 0), (4, 1), (4, 2), (4, 3), (3, 0)]),
            tests: vec![
                ("aces-and-eights-8-5", 25.0),   // 4 others = 25
            ],
        },
        // ============= TRIPLE BONUS =============
        TestCase {
            name: "Four Aces - Triple Bonus (Ah Ad Ac As 5h)",
            hand: make_hand([(12, 0), (12, 1), (12, 2), (12, 3), (3, 0)]),
            tests: vec![
                ("triple-bonus-9-5", 240.0),     // 4 Aces = 240
            ],
        },
        TestCase {
            name: "Four 3s - Triple Bonus (3h 3d 3c 3s 5h)",
            hand: make_hand([(1, 0), (1, 1), (1, 2), (1, 3), (3, 0)]),
            tests: vec![
                ("triple-bonus-9-5", 120.0),     // 4 2-4 = 120
            ],
        },
        TestCase {
            name: "Four Kings - Triple Bonus (Kh Kd Kc Ks 5h)",
            hand: make_hand([(11, 0), (11, 1), (11, 2), (11, 3), (3, 0)]),
            tests: vec![
                ("triple-bonus-9-5", 75.0),      // 4 5-K = 75
            ],
        },
        TestCase {
            name: "Straight Flush - Triple Bonus (9h 8h 7h 6h 5h)",
            hand: make_hand([(7, 0), (6, 0), (5, 0), (4, 0), (3, 0)]),
            tests: vec![
                ("triple-bonus-9-5", 100.0),     // SF = 100
            ],
        },
        TestCase {
            name: "Pair of Kings - Triple Bonus (Kh Kd 5c 3s 2h)",
            hand: make_hand([(11, 0), (11, 1), (3, 2), (1, 3), (0, 0)]),
            tests: vec![
                ("triple-bonus-9-5", 1.0),       // Kings or Better
            ],
        },
        TestCase {
            name: "Pair of Jacks - Triple Bonus (Jh Jd 5c 3s 2h)",
            hand: make_hand([(9, 0), (9, 1), (3, 2), (1, 3), (0, 0)]),
            tests: vec![
                ("triple-bonus-9-5", 0.0),       // Jacks don't count (Kings or Better)
            ],
        },
        // ============= SUPER ACES =============
        TestCase {
            name: "Four Aces - Super Aces (Ah Ad Ac As 5h)",
            hand: make_hand([(12, 0), (12, 1), (12, 2), (12, 3), (3, 0)]),
            tests: vec![
                ("super-aces-8-5", 400.0),       // 4 Aces = 400!
            ],
        },
        TestCase {
            name: "Four Kings - Super Aces (Kh Kd Kc Ks 5h)",
            hand: make_hand([(11, 0), (11, 1), (11, 2), (11, 3), (3, 0)]),
            tests: vec![
                ("super-aces-8-5", 50.0),        // 4 others = 50
            ],
        },
        TestCase {
            name: "Straight Flush - Super Aces (9h 8h 7h 6h 5h)",
            hand: make_hand([(7, 0), (6, 0), (5, 0), (4, 0), (3, 0)]),
            tests: vec![
                ("super-aces-8-5", 60.0),        // SF = 60
            ],
        },
        // ============= DOUBLE JACKPOT =============
        TestCase {
            name: "Four Aces + King kicker - Double Jackpot (Ah Ad Ac As Kh)",
            hand: make_hand([(12, 0), (12, 1), (12, 2), (12, 3), (11, 0)]),
            tests: vec![
                ("double-jackpot-8-5", 160.0),   // 4 Aces + Face = 160
            ],
        },
        TestCase {
            name: "Four Aces + 5 kicker - Double Jackpot (Ah Ad Ac As 5h)",
            hand: make_hand([(12, 0), (12, 1), (12, 2), (12, 3), (3, 0)]),
            tests: vec![
                ("double-jackpot-8-5", 80.0),    // 4 Aces (no face kicker) = 80
            ],
        },
        TestCase {
            name: "Four Kings + Ace kicker - Double Jackpot (Kh Kd Kc Ks Ah)",
            hand: make_hand([(11, 0), (11, 1), (11, 2), (11, 3), (12, 0)]),
            tests: vec![
                ("double-jackpot-8-5", 80.0),    // 4 JQK + Face (A) = 80
            ],
        },
        TestCase {
            name: "Four Kings + 5 kicker - Double Jackpot (Kh Kd Kc Ks 5h)",
            hand: make_hand([(11, 0), (11, 1), (11, 2), (11, 3), (3, 0)]),
            tests: vec![
                ("double-jackpot-8-5", 40.0),    // 4 JQK (no face kicker) = 40
            ],
        },
        TestCase {
            name: "Four 5s - Double Jackpot (5h 5d 5c 5s Ah)",
            hand: make_hand([(3, 0), (3, 1), (3, 2), (3, 3), (12, 0)]),
            tests: vec![
                ("double-jackpot-8-5", 20.0),    // 4 others = 20
            ],
        },
        // ============= DOUBLE DOUBLE JACKPOT =============
        TestCase {
            name: "Four Aces + Face - Double Double Jackpot (Ah Ad Ac As Jh)",
            hand: make_hand([(12, 0), (12, 1), (12, 2), (12, 3), (9, 0)]),
            tests: vec![
                ("double-double-jackpot-9-6", 320.0),   // 4 Aces + Face = 320
            ],
        },
        TestCase {
            name: "Four Kings + Queen - DDJ (Kh Kd Kc Ks Qh)",
            hand: make_hand([(11, 0), (11, 1), (11, 2), (11, 3), (10, 0)]),
            tests: vec![
                ("double-double-jackpot-9-6", 160.0),   // 4 JQK + Face = 160
            ],
        },
        TestCase {
            name: "Full House (Ah Ad Ac Kh Kd)",
            hand: make_hand([(12, 0), (12, 1), (12, 2), (11, 0), (11, 1)]),
            tests: vec![
                ("jacks-or-better-9-6", 9.0),
                ("jacks-or-better-8-5", 8.0),
                ("all-american-35-8", 8.0),
            ],
        },
        TestCase {
            name: "Flush (Ah Kh 9h 7h 5h)",
            hand: make_hand([(12, 0), (11, 0), (7, 0), (5, 0), (3, 0)]),
            tests: vec![
                ("jacks-or-better-9-6", 6.0),
                ("jacks-or-better-8-5", 5.0),
                ("all-american-35-8", 8.0),
            ],
        },
        TestCase {
            name: "Straight (Ah Kd Qc Js Th)",
            hand: make_hand([(12, 0), (11, 1), (10, 2), (9, 3), (8, 0)]),
            tests: vec![
                ("jacks-or-better-9-6", 4.0),
                ("all-american-35-8", 8.0),
            ],
        },
        TestCase {
            name: "Three of a Kind (Ah Ad Ac 5h 3d)",
            hand: make_hand([(12, 0), (12, 1), (12, 2), (3, 0), (1, 1)]),
            tests: vec![
                ("jacks-or-better-9-6", 3.0),
            ],
        },
        TestCase {
            name: "Two Pair (Ah Ad Kh Kd 5c)",
            hand: make_hand([(12, 0), (12, 1), (11, 0), (11, 1), (3, 2)]),
            tests: vec![
                ("jacks-or-better-9-6", 2.0),
            ],
        },
        TestCase {
            name: "Pair of Jacks (Jh Jd 5c 3s 2h)",
            hand: make_hand([(9, 0), (9, 1), (3, 2), (1, 3), (0, 0)]),
            tests: vec![
                ("jacks-or-better-9-6", 1.0),
                ("tens-or-better-6-5", 1.0),
            ],
        },
        TestCase {
            name: "Pair of Tens (Th Td 5c 3s 2h)",
            hand: make_hand([(8, 0), (8, 1), (3, 2), (1, 3), (0, 0)]),
            tests: vec![
                ("jacks-or-better-9-6", 0.0),  // Not high enough
                ("tens-or-better-6-5", 1.0),   // Tens count!
            ],
        },
        TestCase {
            name: "Low Pair - 7s (7h 7d Kc 3s 2h)",
            hand: make_hand([(5, 0), (5, 1), (11, 2), (1, 3), (0, 0)]),
            tests: vec![
                ("jacks-or-better-9-6", 0.0),
            ],
        },

        // ============= DEUCES WILD =============
        TestCase {
            name: "Natural Royal (As Ks Qs Js Ts) - Deuces",
            hand: make_hand([(12, 3), (11, 3), (10, 3), (9, 3), (8, 3)]),
            tests: vec![
                ("deuces-wild-full-pay", 800.0),
                ("deuces-wild-nsud", 800.0),
            ],
        },
        TestCase {
            name: "Four Deuces (2h 2d 2c 2s Ah)",
            hand: make_hand([(0, 0), (0, 1), (0, 2), (0, 3), (12, 0)]),
            tests: vec![
                ("deuces-wild-full-pay", 200.0),
                ("deuces-wild-nsud", 200.0),
                ("loose-deuces-500-17", 500.0),
            ],
        },
        TestCase {
            name: "Wild Royal (As Ks 2s Js Ts)",
            hand: make_hand([(12, 3), (11, 3), (0, 3), (9, 3), (8, 3)]),
            tests: vec![
                ("deuces-wild-full-pay", 25.0),
                ("deuces-wild-nsud", 25.0),
            ],
        },
        TestCase {
            name: "Five Aces (Ah Ad Ac As 2h)",
            hand: make_hand([(12, 0), (12, 1), (12, 2), (12, 3), (0, 0)]),
            tests: vec![
                ("deuces-wild-full-pay", 15.0),
                ("loose-deuces-500-17", 17.0),
            ],
        },
        TestCase {
            name: "Straight Flush with Deuce (9h 8h 7h 6h 2h)",
            hand: make_hand([(7, 0), (6, 0), (5, 0), (4, 0), (0, 0)]),
            tests: vec![
                ("deuces-wild-full-pay", 9.0),
            ],
        },
        TestCase {
            name: "Four of a Kind with Deuce (Kh Kd Kc 2s 5h)",
            hand: make_hand([(11, 0), (11, 1), (11, 2), (0, 3), (3, 0)]),
            tests: vec![
                ("deuces-wild-full-pay", 5.0),
            ],
        },
        TestCase {
            name: "Three of a Kind with Two Deuces (Kh 2d 2c 5h 3s)",
            hand: make_hand([(11, 0), (0, 1), (0, 2), (3, 0), (1, 3)]),
            tests: vec![
                ("deuces-wild-full-pay", 1.0), // Just 3oaK
            ],
        },

        // ============= JOKER POKER =============
        TestCase {
            name: "Five Aces with Joker (Ah Ad Ac As JK)",
            hand: make_hand([(12, 0), (12, 1), (12, 2), (12, 3), (255, 0)]),
            tests: vec![
                ("joker-poker-kings-100-64", 200.0),
                ("joker-poker-two-pair-99-92", 100.0),
            ],
        },
        TestCase {
            name: "Natural Royal (As Ks Qs Js Ts) - Joker",
            hand: make_hand([(12, 3), (11, 3), (10, 3), (9, 3), (8, 3)]),
            tests: vec![
                ("joker-poker-kings-100-64", 800.0),
            ],
        },
        TestCase {
            name: "Wild Royal with Joker (As Ks JK Js Ts)",
            hand: make_hand([(12, 3), (11, 3), (255, 0), (9, 3), (8, 3)]),
            tests: vec![
                ("joker-poker-kings-100-64", 100.0),
            ],
        },
        TestCase {
            name: "Four of a Kind with Joker (Kh Kd Kc JK 5h)",
            hand: make_hand([(11, 0), (11, 1), (11, 2), (255, 0), (3, 0)]),
            tests: vec![
                ("joker-poker-kings-100-64", 17.0),
            ],
        },
        TestCase {
            name: "Pair of Kings (Kh Kd 9c 5s 3h) - Joker Poker",
            hand: make_hand([(11, 0), (11, 1), (7, 2), (3, 3), (1, 0)]),
            tests: vec![
                ("joker-poker-kings-100-64", 1.0),
                ("joker-poker-two-pair-99-92", 0.0), // Need two pair minimum
            ],
        },
        TestCase {
            name: "Two Pair (Kh Kd 9c 9s 3h) - Joker Poker",
            hand: make_hand([(11, 0), (11, 1), (7, 2), (7, 3), (1, 0)]),
            tests: vec![
                ("joker-poker-kings-100-64", 1.0),  // Still just pays as high pair
                ("joker-poker-two-pair-99-92", 1.0), // Minimum winning hand
            ],
        },
    ];

    for tc in test_cases.iter() {
        for (paytable_id, expected) in &tc.tests {
            // Check if we should skip based on filter
            if let Some(f) = filter {
                if !paytable_id.contains(f) {
                    continue;
                }
            }

            if let Some(paytable) = get_paytable(paytable_id) {
                let actual = get_payout(&tc.hand, &paytable);
                let pass = (actual - expected).abs() < 0.001;

                if pass {
                    passed += 1;
                    println!("✓ {} [{}]: {} = {}", tc.name, paytable_id, hand_to_string(&tc.hand), actual);
                } else {
                    failed += 1;
                    println!("✗ {} [{}]: {} = {} (expected {})",
                        tc.name, paytable_id, hand_to_string(&tc.hand), actual, expected);
                }
            } else {
                println!("? Paytable not found: {}", paytable_id);
            }
        }
    }

    println!("\n=== Results: {} passed, {} failed ===", passed, failed);

    if failed > 0 {
        std::process::exit(1);
    }
}

fn format_duration(secs: u64) -> String {
    if secs < 60 {
        format!("{}s", secs)
    } else if secs < 3600 {
        format!("{}m {}s", secs / 60, secs % 60)
    } else {
        format!("{}h {}m {}s", secs / 3600, (secs % 3600) / 60, secs % 60)
    }
}

fn generate_all_strategies(output_dir: &str) {
    let all_ids = get_all_paytable_ids();
    let total_paytables = all_ids.len();

    // Ensure output directory exists
    if let Err(e) = fs::create_dir_all(output_dir) {
        eprintln!("Failed to create output directory: {}", e);
        std::process::exit(1);
    }

    // Check which paytables already have output files (for resume)
    let mut already_done: Vec<&str> = Vec::new();
    let mut to_process: Vec<&str> = Vec::new();

    for id in &all_ids {
        let filename = get_storage_filename(id);
        let path = Path::new(output_dir).join(&filename);
        if path.exists() {
            already_done.push(id);
        } else {
            to_process.push(id);
        }
    }

    let previously_completed = already_done.len();
    let remaining = to_process.len();

    println!("╔══════════════════════════════════════════════════════════════════╗");
    println!("║          VIDEO POKER STRATEGY GENERATOR - BATCH MODE            ║");
    println!("╠══════════════════════════════════════════════════════════════════╣");
    println!("║  Total paytables: {:<47} ║", total_paytables);
    println!("║  Already completed: {:<45} ║", previously_completed);
    println!("║  To process this run: {:<43} ║", remaining);
    println!("║  Output directory: {:<46} ║", output_dir);
    println!("║  Threads: {:<55} ║", rayon::current_num_threads());
    println!("╚══════════════════════════════════════════════════════════════════╝");
    println!();

    if remaining == 0 {
        println!("All paytables already generated! Nothing to do.");
        return;
    }

    let overall_start = Instant::now();
    let mut completed_this_run = 0;
    let mut total_hands = 0usize;
    let mut total_bytes = 0u64;
    let mut failed_paytables: Vec<String> = Vec::new();

    // Track timing for ETA calculation
    let mut paytable_times: Vec<f64> = Vec::new();

    for (idx, paytable_id) in to_process.iter().enumerate() {
        let paytable = match get_paytable(paytable_id) {
            Some(pt) => pt,
            None => {
                println!("  ⚠ Paytable not found: {}", paytable_id);
                failed_paytables.push(paytable_id.to_string());
                continue;
            }
        };

        let overall_done = previously_completed + completed_this_run;

        // Calculate ETA based on average time per paytable
        let eta_str = if !paytable_times.is_empty() {
            let avg_time = paytable_times.iter().sum::<f64>() / paytable_times.len() as f64;
            let remaining_count = remaining - idx;
            let remaining_secs = remaining_count as f64 * avg_time;
            format!("ETA: {}", format_duration(remaining_secs as u64))
        } else {
            "ETA: calculating...".to_string()
        };

        println!("┌──────────────────────────────────────────────────────────────────┐");
        println!("│ Overall: {}/{}  |  This run: {}/{}                               │",
            overall_done + 1, total_paytables, idx + 1, remaining);
        println!("│ {:<65} │", paytable.name);
        println!("│ ID: {:<61} │", paytable_id);
        println!("│ {:<65} │", eta_str);
        println!("└──────────────────────────────────────────────────────────────────┘");

        let paytable_start = Instant::now();

        // Generate strategy with progress (JSON.gz and binary formats)
        let (compressed, binary_v1, binary_v2, hand_count, _version) = generate_strategy_file_with_progress(
            &paytable,
            overall_done + 1,
            total_paytables
        );
        let file_size = compressed.len() as u64;
        let binary_v1_size = binary_v1.len() as u64;
        let binary_v2_size = binary_v2.len() as u64;

        // Save locally (all formats)
        let json_result = save_locally(&compressed, paytable_id, output_dir);
        let binary_v1_result = save_binary_strategy(&binary_v1, paytable_id, output_dir);
        let binary_v2_result = save_binary_strategy_v2(&binary_v2, paytable_id, output_dir);

        match (&json_result, &binary_v1_result, &binary_v2_result) {
            (Ok(json_path), Ok(binary_v1_path), Ok(binary_v2_path)) => {
                let elapsed = paytable_start.elapsed().as_secs_f64();
                paytable_times.push(elapsed);
                completed_this_run += 1;
                total_hands += hand_count;
                total_bytes += file_size + binary_v1_size + binary_v2_size;
                println!("  ✓ Saved: {} ({:.2} MB) in {:.1}s",
                    json_path.split('/').last().unwrap_or(json_path),
                    file_size as f64 / 1024.0 / 1024.0,
                    elapsed
                );
                println!("  ✓ Binary v1: {} ({:.2} MB)",
                    binary_v1_path.split('/').last().unwrap_or(binary_v1_path),
                    binary_v1_size as f64 / 1024.0 / 1024.0
                );
                println!("  ✓ Binary v2: {} ({:.2} MB)",
                    binary_v2_path.split('/').last().unwrap_or(binary_v2_path),
                    binary_v2_size as f64 / 1024.0 / 1024.0
                );
            }
            _ => {
                if let Err(e) = json_result { println!("  ✗ Failed to save JSON: {}", e); }
                if let Err(e) = binary_v1_result { println!("  ✗ Failed to save binary v1: {}", e); }
                if let Err(e) = binary_v2_result { println!("  ✗ Failed to save binary v2: {}", e); }
                failed_paytables.push(paytable_id.to_string());
            }
        }
        println!();
    }

    // Final summary
    let total_elapsed = overall_start.elapsed();
    let final_total = previously_completed + completed_this_run;
    println!("╔══════════════════════════════════════════════════════════════════╗");
    println!("║                        GENERATION COMPLETE                       ║");
    println!("╠══════════════════════════════════════════════════════════════════╣");
    println!("║  Overall progress: {:<46} ║", format!("{}/{}", final_total, total_paytables));
    println!("║  Completed this run: {:<44} ║", completed_this_run);
    println!("║  Previously completed: {:<42} ║", previously_completed);
    println!("║  Hands calculated (this run): {:<35} ║", format!("{}", total_hands));
    println!("║  Output size (this run): {:<40} ║", format!("{:.2} MB", total_bytes as f64 / 1024.0 / 1024.0));
    println!("║  Time (this run): {:<47} ║", format_duration(total_elapsed.as_secs()));
    if !failed_paytables.is_empty() {
        println!("╠══════════════════════════════════════════════════════════════════╣");
        println!("║  Failed paytables:                                               ║");
        for failed in &failed_paytables {
            println!("║    - {:<59} ║", failed);
        }
    }
    println!("╚══════════════════════════════════════════════════════════════════╝");

    if !failed_paytables.is_empty() {
        std::process::exit(1);
    }
}

fn upload_existing_strategies(input_dir: &str) {
    println!("╔══════════════════════════════════════════════════════════════════╗");
    println!("║          UPLOAD EXISTING STRATEGY FILES TO SUPABASE             ║");
    println!("╚══════════════════════════════════════════════════════════════════╝");
    println!();

    // Load environment
    dotenv::from_path("../../.env").ok();

    let supabase_url = match std::env::var("SUPABASE_URL") {
        Ok(url) => url,
        Err(_) => {
            eprintln!("SUPABASE_URL not set in .env");
            std::process::exit(1);
        }
    };

    let service_key = match std::env::var("SUPABASE_SERVICE_KEY") {
        Ok(key) => key,
        Err(_) => {
            eprintln!("SUPABASE_SERVICE_KEY not set in .env");
            std::process::exit(1);
        }
    };

    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(120))
        .build()
        .expect("Failed to create HTTP client");

    // Find all .json.gz files in the input directory
    let entries = match fs::read_dir(input_dir) {
        Ok(e) => e,
        Err(e) => {
            eprintln!("Failed to read directory {}: {}", input_dir, e);
            std::process::exit(1);
        }
    };

    let mut files: Vec<_> = entries
        .filter_map(|e| e.ok())
        .filter(|e| e.path().extension().map(|ext| ext == "gz").unwrap_or(false))
        .collect();

    files.sort_by_key(|e| e.path());

    println!("Found {} strategy files in {}\n", files.len(), input_dir);

    let mut uploaded = 0;
    let mut failed = 0;

    for (idx, entry) in files.iter().enumerate() {
        let path = entry.path();
        let filename = path.file_name().unwrap().to_string_lossy();

        // Extract paytable_id from filename: strategy_xxx_yyy.json.gz -> xxx-yyy
        let paytable_id = filename
            .trim_start_matches("strategy_")
            .trim_end_matches(".json.gz")
            .replace('_', "-");

        println!("[{}/{}] Uploading: {}", idx + 1, files.len(), filename);
        println!("  Paytable ID: {}", paytable_id);

        // Read file
        let compressed = match fs::read(&path) {
            Ok(data) => data,
            Err(e) => {
                println!("  ✗ Failed to read file: {}", e);
                failed += 1;
                continue;
            }
        };

        let file_size = compressed.len() as u64;
        println!("  Size: {:.2} MB", file_size as f64 / 1024.0 / 1024.0);

        // Upload to storage
        if let Err(e) = upload_to_storage(&client, &compressed, &paytable_id, &supabase_url, &service_key) {
            println!("  ✗ Upload failed: {}", e);
            failed += 1;
            continue;
        }

        // Parse the file to get hand count for manifest
        let hand_count = match flate2::read::GzDecoder::new(&compressed[..]) {
            decoder => {
                let mut json_str = String::new();
                if std::io::Read::read_to_string(&mut std::io::BufReader::new(decoder), &mut json_str).is_ok() {
                    if let Ok(strategy_file) = serde_json::from_str::<StrategyFile>(&json_str) {
                        strategy_file.hand_count
                    } else {
                        0
                    }
                } else {
                    0
                }
            }
        };

        // Update manifest
        if let Err(e) = update_manifest(&client, &supabase_url, &service_key, &paytable_id, 1, file_size, hand_count) {
            println!("  ⚠ Manifest update failed: {}", e);
        }

        uploaded += 1;
        println!();
    }

    println!("╔══════════════════════════════════════════════════════════════════╗");
    println!("║                         UPLOAD COMPLETE                          ║");
    println!("╠══════════════════════════════════════════════════════════════════╣");
    println!("║  Uploaded: {:<54} ║", uploaded);
    println!("║  Failed: {:<56} ║", failed);
    println!("╚══════════════════════════════════════════════════════════════════╝");

    if failed > 0 {
        std::process::exit(1);
    }
}

fn convert_json_to_binary(input_dir: &str) {
    use flate2::read::GzDecoder;
    use std::io::Read;

    println!("╔══════════════════════════════════════════════════════════════════╗");
    println!("║      CONVERT JSON.GZ TO BINARY FORMATS (.vpstrat, .vpstrat2)    ║");
    println!("╚══════════════════════════════════════════════════════════════════╝");
    println!();
    println!("Input directory: {}", input_dir);
    println!();

    // Find all .json.gz files
    let paths: Vec<_> = match fs::read_dir(input_dir) {
        Ok(entries) => entries
            .filter_map(|e| e.ok())
            .map(|e| e.path())
            .filter(|p| p.extension().map(|e| e == "gz").unwrap_or(false))
            .filter(|p| p.to_string_lossy().contains(".json.gz"))
            .collect(),
        Err(e) => {
            eprintln!("Failed to read directory: {}", e);
            std::process::exit(1);
        }
    };

    if paths.is_empty() {
        println!("No .json.gz files found in {}", input_dir);
        return;
    }

    println!("Found {} strategy files to convert\n", paths.len());

    let mut converted = 0;
    let mut failed = 0;

    for path in &paths {
        let filename = path.file_name().unwrap_or_default().to_string_lossy();
        print!("Converting {}... ", filename);
        io::stdout().flush().unwrap();

        // Read and decompress
        let gz_data = match fs::read(&path) {
            Ok(data) => data,
            Err(e) => {
                println!("✗ Failed to read: {}", e);
                failed += 1;
                continue;
            }
        };

        let mut decoder = GzDecoder::new(&gz_data[..]);
        let mut json_string = String::new();
        if let Err(e) = decoder.read_to_string(&mut json_string) {
            println!("✗ Failed to decompress: {}", e);
            failed += 1;
            continue;
        }

        // Parse JSON
        let strategy_file: StrategyFile = match serde_json::from_str(&json_string) {
            Ok(sf) => sf,
            Err(e) => {
                println!("✗ Failed to parse JSON: {}", e);
                failed += 1;
                continue;
            }
        };

        // Detect if joker poker based on paytable ID or hand count
        let has_joker = strategy_file.paytable_id.contains("joker")
            || strategy_file.hand_count > 210000;

        // Generate binary v1
        let binary_v1 = generate_binary_strategy(&strategy_file.strategies, has_joker);

        // Generate binary v2 (with full holdEvs)
        let binary_v2 = generate_binary_strategy_v2(&strategy_file.strategies, has_joker);

        // Save binary v1 file
        let binary_v1_filename = filename.replace(".json.gz", ".vpstrat");
        let binary_v1_path = Path::new(input_dir).join(&binary_v1_filename);
        if let Err(e) = fs::write(&binary_v1_path, &binary_v1) {
            println!("✗ Failed to save v1: {}", e);
            failed += 1;
            continue;
        }

        // Save binary v2 file
        let binary_v2_filename = filename.replace(".json.gz", ".vpstrat2");
        let binary_v2_path = Path::new(input_dir).join(&binary_v2_filename);
        if let Err(e) = fs::write(&binary_v2_path, &binary_v2) {
            println!("✗ Failed to save v2: {}", e);
            failed += 1;
            continue;
        }

        println!("✓ v1: {:.2} MB, v2: {:.2} MB",
            binary_v1.len() as f64 / 1024.0 / 1024.0,
            binary_v2.len() as f64 / 1024.0 / 1024.0
        );
        converted += 1;
    }

    println!();
    println!("╔══════════════════════════════════════════════════════════════════╗");
    println!("║                      CONVERSION COMPLETE                         ║");
    println!("╠══════════════════════════════════════════════════════════════════╣");
    println!("║  Converted: {:<53} ║", converted);
    println!("║  Failed: {:<56} ║", failed);
    println!("╚══════════════════════════════════════════════════════════════════╝");

    if failed > 0 {
        std::process::exit(1);
    }
}

fn verify_binary_files(input_dir: &str) {
    use flate2::read::GzDecoder;
    use std::io::Read;

    println!("╔══════════════════════════════════════════════════════════════════╗");
    println!("║          VERIFY BINARY FORMAT AGAINST JSON.GZ                   ║");
    println!("╚══════════════════════════════════════════════════════════════════╝");
    println!();
    println!("Input directory: {}", input_dir);
    println!();

    // Find all .vpstrat files
    let binary_paths: Vec<_> = match fs::read_dir(input_dir) {
        Ok(entries) => entries
            .filter_map(|e| e.ok())
            .map(|e| e.path())
            .filter(|p| p.extension().map(|e| e == "vpstrat").unwrap_or(false))
            .collect(),
        Err(e) => {
            eprintln!("Failed to read directory: {}", e);
            std::process::exit(1);
        }
    };

    if binary_paths.is_empty() {
        println!("No .vpstrat files found in {}", input_dir);
        return;
    }

    println!("Found {} binary files to verify\n", binary_paths.len());

    let mut passed = 0;
    let mut failed = 0;

    for binary_path in &binary_paths {
        let filename = binary_path.file_name().unwrap_or_default().to_string_lossy();
        let json_filename = filename.replace(".vpstrat", ".json.gz");
        let json_path = Path::new(input_dir).join(&json_filename);

        print!("Verifying {}... ", filename);
        io::stdout().flush().unwrap();

        // Check if JSON exists
        if !json_path.exists() {
            println!("⚠ No matching JSON.gz file");
            continue;
        }

        // Load binary file
        let binary_data = match fs::read(&binary_path) {
            Ok(data) => data,
            Err(e) => {
                println!("✗ Failed to read binary: {}", e);
                failed += 1;
                continue;
            }
        };

        // Verify binary header
        if binary_data.len() < VPSTRAT_HEADER_SIZE {
            println!("✗ Binary file too small");
            failed += 1;
            continue;
        }

        if &binary_data[0..4] != VPSTRAT_MAGIC {
            println!("✗ Invalid magic number");
            failed += 1;
            continue;
        }

        let entry_count = u32::from_le_bytes([binary_data[8], binary_data[9], binary_data[10], binary_data[11]]) as usize;
        let key_length = binary_data[12] as usize;

        // Load and parse JSON
        let gz_data = match fs::read(&json_path) {
            Ok(data) => data,
            Err(e) => {
                println!("✗ Failed to read JSON: {}", e);
                failed += 1;
                continue;
            }
        };

        let mut decoder = GzDecoder::new(&gz_data[..]);
        let mut json_string = String::new();
        if let Err(e) = decoder.read_to_string(&mut json_string) {
            println!("✗ Failed to decompress: {}", e);
            failed += 1;
            continue;
        }

        let strategy_file: StrategyFile = match serde_json::from_str(&json_string) {
            Ok(sf) => sf,
            Err(e) => {
                println!("✗ Failed to parse JSON: {}", e);
                failed += 1;
                continue;
            }
        };

        // Verify entry count
        if entry_count != strategy_file.hand_count {
            println!("✗ Entry count mismatch: binary={} json={}", entry_count, strategy_file.hand_count);
            failed += 1;
            continue;
        }

        // Verify all entries
        let index_size = entry_count * key_length;
        let data_start = VPSTRAT_HEADER_SIZE + index_size;

        let mut mismatches = 0;
        let mut ev_tolerance_failures = 0;
        let ev_tolerance: f32 = 0.0001;

        for i in 0..entry_count {
            // Read key from binary index
            let key_offset = VPSTRAT_HEADER_SIZE + i * key_length;
            let key_bytes = &binary_data[key_offset..key_offset + key_length];
            let key = String::from_utf8_lossy(key_bytes).trim_end_matches('\0').to_string();

            // Read data from binary
            let data_offset = data_start + i * VPSTRAT_DATA_ENTRY_SIZE;
            let binary_hold = binary_data[data_offset];
            let binary_ev = f32::from_le_bytes([
                binary_data[data_offset + 1],
                binary_data[data_offset + 2],
                binary_data[data_offset + 3],
                binary_data[data_offset + 4],
            ]);

            // Look up in JSON
            if let Some(json_entry) = strategy_file.strategies.get(&key) {
                if binary_hold != json_entry.hold {
                    if mismatches < 5 {
                        eprintln!("\n  Hold mismatch for {}: binary={} json={}", key, binary_hold, json_entry.hold);
                    }
                    mismatches += 1;
                } else if (binary_ev as f64 - json_entry.ev).abs() > ev_tolerance as f64 {
                    if ev_tolerance_failures < 5 {
                        eprintln!("\n  EV mismatch for {}: binary={:.6} json={:.6}", key, binary_ev, json_entry.ev);
                    }
                    ev_tolerance_failures += 1;
                }
            } else {
                if mismatches < 5 {
                    eprintln!("\n  Key not found in JSON: {}", key);
                }
                mismatches += 1;
            }
        }

        if mismatches == 0 && ev_tolerance_failures == 0 {
            println!("✓ {} entries verified", entry_count);
            passed += 1;
        } else {
            println!("✗ {} hold mismatches, {} EV tolerance failures", mismatches, ev_tolerance_failures);
            failed += 1;
        }
    }

    println!();
    println!("╔══════════════════════════════════════════════════════════════════╗");
    println!("║                     VERIFICATION COMPLETE                        ║");
    println!("╠══════════════════════════════════════════════════════════════════╣");
    println!("║  Passed: {:<56} ║", passed);
    println!("║  Failed: {:<56} ║", failed);
    println!("╚══════════════════════════════════════════════════════════════════╝");

    if failed > 0 {
        std::process::exit(1);
    }
}

/// Returns (json_gz_bytes, binary_v1_bytes, binary_v2_bytes, hand_count, version)
fn generate_strategy_file_with_progress(paytable: &Paytable, current_paytable: usize, total_paytables: usize) -> (Vec<u8>, Vec<u8>, Vec<u8>, usize, u32) {
    let include_joker = paytable.is_joker_poker();
    let all_hands = generate_canonical_hands(include_joker);
    let total = all_hands.len();

    println!("  Calculating {} hands...", total);
    io::stdout().flush().unwrap();

    let processed = Arc::new(AtomicUsize::new(0));
    let total_for_progress = total;
    let start = Instant::now();

    // Calculate all strategies in parallel
    let strategies: HashMap<String, StrategyEntry> = all_hands
        .par_iter()
        .map(|(key, hand)| {
            let (best_hold, best_ev, hold_evs) = analyze_hand(hand, paytable);

            let count = processed.fetch_add(1, Ordering::Relaxed) + 1;
            if count % 5000 == 0 || count == total_for_progress {
                let pct = (count as f64 / total_for_progress as f64 * 100.0) as u32;
                let elapsed = start.elapsed().as_secs_f64();
                let rate = count as f64 / elapsed;
                let remaining = (total_for_progress - count) as f64 / rate;
                print!("  [{}/{}] Progress: {:>6}/{} ({:>3}%) | {:.0} hands/s | ~{}s remaining\r",
                    current_paytable, total_paytables,
                    count, total_for_progress, pct,
                    rate,
                    remaining as u64
                );
                io::stdout().flush().unwrap();
            }

            (key.clone(), StrategyEntry {
                hold: best_hold,
                ev: best_ev,
                hold_evs,
            })
        })
        .collect();

    println!("  Calculated {} hands                                                      ", strategies.len());

    // Determine version
    let version = 1u32;

    // Generate binary format v1 (bestHold + bestEv only)
    print!("  Generating binary v1... ");
    io::stdout().flush().unwrap();
    let binary_v1 = generate_binary_strategy(&strategies, include_joker);
    println!("({:.2} MB)", binary_v1.len() as f64 / 1024.0 / 1024.0);

    // Generate binary format v2 (full holdEvs)
    print!("  Generating binary v2... ");
    io::stdout().flush().unwrap();
    let binary_v2 = generate_binary_strategy_v2(&strategies, include_joker);
    println!("({:.2} MB)", binary_v2.len() as f64 / 1024.0 / 1024.0);

    // Build the JSON output structure
    let output = StrategyFile {
        game: paytable.name.clone(),
        paytable_id: paytable.id.clone(),
        version,
        generated: Utc::now().to_rfc3339(),
        hand_count: strategies.len(),
        strategies,
    };

    // Serialize to JSON
    print!("  Serializing...");
    io::stdout().flush().unwrap();
    let json_string = serde_json::to_string(&output).expect("Failed to serialize");
    let json_size = json_string.len();

    // Compress with gzip
    print!(" Compressing...");
    io::stdout().flush().unwrap();
    let mut encoder = GzEncoder::new(Vec::new(), Compression::best());
    encoder.write_all(json_string.as_bytes()).expect("Failed to compress");
    let compressed = encoder.finish().expect("Failed to finish compression");

    let compressed_size = compressed.len();
    let ratio = (1.0 - compressed_size as f64 / json_size as f64) * 100.0;
    println!(" Done! ({:.2} MB → {:.2} MB, {:.0}% reduction)",
        json_size as f64 / 1024.0 / 1024.0,
        compressed_size as f64 / 1024.0 / 1024.0,
        ratio
    );

    (compressed, binary_v1, binary_v2, total, version)
}

fn main() {
    let args: Vec<String> = std::env::args().collect();

    // Check for help
    if args.get(1).map(|s| s.as_str()) == Some("--help") || args.get(1).map(|s| s.as_str()) == Some("-h") {
        println!("Video Poker Strategy Calculator\n");
        println!("Usage:");
        println!("  vp_calculator <paytable-id>              Generate strategy, save locally, and upload");
        println!("  vp_calculator <paytable-id> --no-upload  Generate strategy and save locally only");
        println!("  vp_calculator generate-all [--output DIR] Generate all strategies (no upload)");
        println!("  vp_calculator upload-existing [DIR]      Upload existing .json.gz files to Supabase");
        println!("  vp_calculator list                       List all available paytables");
        println!("  vp_calculator test [filter]              Run payout tests");
        println!("  vp_calculator manifest                   Show current manifest from Supabase");
        println!("\nOptions:");
        println!("  --no-upload    Skip uploading to Supabase Storage");
        println!("  --output DIR   Specify output directory (default: ../../supabase-uploads)");
        return;
    }

    // Check for list mode
    if args.get(1).map(|s| s.as_str()) == Some("list") {
        println!("Available paytables:\n");
        for id in get_all_paytable_ids() {
            if let Some(pt) = get_paytable(id) {
                println!("  {} - {}", id, pt.name);
            }
        }
        return;
    }

    // Check for generate-all mode
    if args.get(1).map(|s| s.as_str()) == Some("generate-all") {
        let mut output_dir = "./strategies".to_string();
        let mut i = 2;
        while i < args.len() {
            if args[i] == "--output" && i + 1 < args.len() {
                output_dir = args[i + 1].clone();
                i += 2;
            } else {
                i += 1;
            }
        }
        generate_all_strategies(&output_dir);
        return;
    }

    // Check for upload-existing mode
    if args.get(1).map(|s| s.as_str()) == Some("upload-existing") {
        let input_dir = args.get(2).map(|s| s.as_str()).unwrap_or("../../supabase-uploads");
        upload_existing_strategies(input_dir);
        return;
    }

    // Check for test mode
    if args.get(1).map(|s| s.as_str()) == Some("test") {
        let paytable_id = args.get(2).map(|s| s.as_str());
        run_tests(paytable_id);
        return;
    }

    // Check for convert-to-binary mode
    if args.get(1).map(|s| s.as_str()) == Some("convert-to-binary") {
        let input_dir = args.get(2).map(|s| s.as_str()).unwrap_or("./strategies");
        convert_json_to_binary(input_dir);
        return;
    }

    // Check for verify-binary mode
    if args.get(1).map(|s| s.as_str()) == Some("verify-binary") {
        let input_dir = args.get(2).map(|s| s.as_str()).unwrap_or("./strategies");
        verify_binary_files(input_dir);
        return;
    }

    // Check for manifest mode
    if args.get(1).map(|s| s.as_str()) == Some("manifest") {
        dotenv::from_path("../../.env").ok();
        let supabase_url = std::env::var("SUPABASE_URL").expect("SUPABASE_URL not set");
        let service_key = std::env::var("SUPABASE_SERVICE_KEY").expect("SUPABASE_SERVICE_KEY not set");

        let client = reqwest::blocking::Client::builder()
            .timeout(std::time::Duration::from_secs(30))
            .build()
            .expect("Failed to create HTTP client");

        let manifest = fetch_manifest(&client, &supabase_url, &service_key);

        if manifest.strategies.is_empty() {
            println!("No strategies in manifest (or manifest doesn't exist yet)");
        } else {
            println!("=== Strategy Manifest ===\n");
            let mut entries: Vec<_> = manifest.strategies.iter().collect();
            entries.sort_by_key(|(id, _)| *id);

            for (id, entry) in entries {
                println!("  {} (v{})", id, entry.version);
                println!("    File: {}", entry.file);
                println!("    Size: {:.2} MB", entry.size as f64 / 1024.0 / 1024.0);
                println!("    Hands: {}", entry.hand_count);
                println!("    Updated: {}", entry.updated_at);
                println!();
            }
        }
        return;
    }

    // Parse arguments
    let mut paytable_id = String::new();
    let mut no_upload = false;
    let mut output_dir = "../../supabase-uploads".to_string();

    let mut i = 1;
    while i < args.len() {
        let arg = &args[i];
        if arg == "--no-upload" {
            no_upload = true;
        } else if arg == "--output" {
            i += 1;
            if i < args.len() {
                output_dir = args[i].clone();
            }
        } else if !arg.starts_with("--") {
            paytable_id = arg.clone();
        }
        i += 1;
    }

    if paytable_id.is_empty() {
        eprintln!("Usage: vp_calculator <paytable-id> [--no-upload] [--output DIR]");
        eprintln!("Run 'vp_calculator list' to see available paytables");
        std::process::exit(1);
    }

    let paytable = match get_paytable(&paytable_id) {
        Some(pt) => pt,
        None => {
            eprintln!("Unknown paytable: {}", paytable_id);
            eprintln!("\nRun with 'list' to see available paytables");
            std::process::exit(1);
        }
    };

    println!("=== Video Poker Strategy Calculator ===\n");
    println!("Paytable: {} ({})", paytable.name, paytable.id);
    println!("Game Family: {:?}", paytable.game_family);
    println!("Upload: {}", if no_upload { "disabled" } else { "enabled" });

    let start = Instant::now();

    // Generate the compressed strategy file (JSON.gz) and binary formats
    let (compressed, binary_v1, binary_v2, hand_count, version) = generate_strategy_file(&paytable);
    let file_size = compressed.len() as u64;

    // Save locally
    println!("\nSaving locally...");
    match save_locally(&compressed, &paytable_id, &output_dir) {
        Ok(path) => println!("  ✓ JSON.gz: {}", path),
        Err(e) => {
            eprintln!("  ✗ Failed to save JSON.gz: {}", e);
            std::process::exit(1);
        }
    }
    match save_binary_strategy(&binary_v1, &paytable_id, &output_dir) {
        Ok(path) => println!("  ✓ Binary v1: {} ({:.2} MB)", path, binary_v1.len() as f64 / 1024.0 / 1024.0),
        Err(e) => {
            eprintln!("  ✗ Failed to save binary v1: {}", e);
            std::process::exit(1);
        }
    }
    match save_binary_strategy_v2(&binary_v2, &paytable_id, &output_dir) {
        Ok(path) => println!("  ✓ Binary v2: {} ({:.2} MB)", path, binary_v2.len() as f64 / 1024.0 / 1024.0),
        Err(e) => {
            eprintln!("  ✗ Failed to save binary v2: {}", e);
            std::process::exit(1);
        }
    }

    // Upload to Supabase Storage (unless --no-upload)
    if !no_upload {
        dotenv::from_path("../../.env").ok();

        let supabase_url = match std::env::var("SUPABASE_URL") {
            Ok(url) => url,
            Err(_) => {
                eprintln!("\nSUPABASE_URL not set. Skipping upload.");
                eprintln!("Set SUPABASE_URL and SUPABASE_SERVICE_KEY in .env to enable upload.");
                let elapsed = start.elapsed();
                println!("\n=== Completed (local only) ===");
                println!("Time: {:.1}s", elapsed.as_secs_f64());
                println!("Hands: {}", hand_count);
                return;
            }
        };

        let service_key = match std::env::var("SUPABASE_SERVICE_KEY") {
            Ok(key) => key,
            Err(_) => {
                eprintln!("\nSUPABASE_SERVICE_KEY not set. Skipping upload.");
                let elapsed = start.elapsed();
                println!("\n=== Completed (local only) ===");
                println!("Time: {:.1}s", elapsed.as_secs_f64());
                println!("Hands: {}", hand_count);
                return;
            }
        };

        let client = reqwest::blocking::Client::builder()
            .timeout(std::time::Duration::from_secs(120))
            .build()
            .expect("Failed to create HTTP client");

        // Upload strategy file
        println!();
        if let Err(e) = upload_to_storage(&client, &compressed, &paytable_id, &supabase_url, &service_key) {
            eprintln!("  ✗ Upload failed: {}", e);
            std::process::exit(1);
        }

        // Update manifest
        if let Err(e) = update_manifest(&client, &supabase_url, &service_key, &paytable_id, version, file_size, hand_count) {
            eprintln!("  ✗ Manifest update failed: {}", e);
            // Don't exit - the file was uploaded successfully
        }
    }

    let elapsed = start.elapsed();
    println!("\n=== Completed ===");
    println!("Time: {:.1}s", elapsed.as_secs_f64());
    println!("Hands: {}", hand_count);
    println!("Size: {:.2} MB (compressed)", file_size as f64 / 1024.0 / 1024.0);
    io::stdout().flush().unwrap();
}
