use std::collections::{HashMap, HashSet, BTreeSet};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
enum Rank {
    Two = 2, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King, Ace,
}

impl Rank {
    fn all() -> Vec<Rank> {
        vec![
            Rank::Two, Rank::Three, Rank::Four, Rank::Five, Rank::Six,
            Rank::Seven, Rank::Eight, Rank::Nine, Rank::Ten, Rank::Jack,
            Rank::Queen, Rank::King, Rank::Ace,
        ]
    }

    fn is_high(&self) -> bool {
        matches!(self, Rank::Ten | Rank::Jack | Rank::Queen | Rank::King | Rank::Ace)
    }

    fn value(&self) -> u8 {
        *self as u8
    }

    fn to_char(&self) -> char {
        match self {
            Rank::Two => '2', Rank::Three => '3', Rank::Four => '4', Rank::Five => '5',
            Rank::Six => '6', Rank::Seven => '7', Rank::Eight => '8', Rank::Nine => '9',
            Rank::Ten => 'T', Rank::Jack => 'J', Rank::Queen => 'Q', Rank::King => 'K',
            Rank::Ace => 'A',
        }
    }
}

// Canonical suits: a, b, c, d (assigned in order of first appearance)
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
enum CanonicalSuit {
    A = 0, B, C, D,
}

impl CanonicalSuit {
    fn to_char(&self) -> char {
        match self {
            CanonicalSuit::A => 'a',
            CanonicalSuit::B => 'b',
            CanonicalSuit::C => 'c',
            CanonicalSuit::D => 'd',
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
struct Card {
    rank: Rank,
    suit: CanonicalSuit,
}

impl Card {
    fn new(rank: Rank, suit: CanonicalSuit) -> Self {
        Card { rank, suit }
    }

    fn to_string(&self) -> String {
        format!("{}{}", self.rank.to_char(), self.suit.to_char())
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
struct Hand {
    cards: Vec<Card>,
}

impl Hand {
    fn new(mut cards: Vec<Card>) -> Self {
        // Sort cards for consistent representation
        cards.sort_by(|a, b| a.rank.cmp(&b.rank).then(a.suit.cmp(&b.suit)));
        Hand { cards }
    }

    fn to_string(&self) -> String {
        self.cards.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(" ")
    }

    fn ranks(&self) -> Vec<Rank> {
        self.cards.iter().map(|c| c.rank).collect()
    }

    fn rank_counts(&self) -> HashMap<Rank, usize> {
        let mut counts = HashMap::new();
        for card in &self.cards {
            *counts.entry(card.rank).or_insert(0) += 1;
        }
        counts
    }

    fn suit_counts(&self) -> HashMap<CanonicalSuit, usize> {
        let mut counts = HashMap::new();
        for card in &self.cards {
            *counts.entry(card.suit).or_insert(0) += 1;
        }
        counts
    }

    fn cards_of_suit(&self, suit: CanonicalSuit) -> Vec<&Card> {
        self.cards.iter().filter(|c| c.suit == suit).collect()
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
enum HandClass {
    FourOfAKind,           // 3
    FourToRoyalFlush,      // 4
    FullHouse,             // 5
    Flush,                 // 6
    ThreeOfAKind,          // 7
    Straight,              // 8
    FourToStraightFlush,   // 9
    TwoPair,               // 10
    HighPair,              // 11
    ThreeToRoyalFlush,     // 12
    FourToFlush,           // 13
    UnsuitedTJQK,          // 14
    LowPair,               // 15
    FourToOutsideStraight, // 16
    ThreeToSFType1,        // 17
    SuitedQJ,              // 18
    FourToInsideStraight4High, // 19
    SuitedKQOrKJ,          // 20
    SuitedAKAQAJ,          // 21
    FourToInsideStraight3High, // 22
    ThreeToSFType2,        // 23
    UnsuitedJQK,           // 24
    UnsuitedJQ,            // 25
    SuitedTJ,              // 26
    TwoUnsuitedHighKing,   // 27
    SuitedTQ,              // 28
    TwoUnsuitedHighAce,    // 29
    JOnly,                 // 30
    SuitedTK,              // 31
    QOnly,                 // 32
    KOnly,                 // 33
    AOnly,                 // 34
    ThreeToSFType3,        // 35
    Garbage,               // 36
}

impl HandClass {
    fn rank(&self) -> u8 {
        match self {
            HandClass::FourOfAKind => 3,
            HandClass::FourToRoyalFlush => 4,
            HandClass::FullHouse => 5,
            HandClass::Flush => 6,
            HandClass::ThreeOfAKind => 7,
            HandClass::Straight => 8,
            HandClass::FourToStraightFlush => 9,
            HandClass::TwoPair => 10,
            HandClass::HighPair => 11,
            HandClass::ThreeToRoyalFlush => 12,
            HandClass::FourToFlush => 13,
            HandClass::UnsuitedTJQK => 14,
            HandClass::LowPair => 15,
            HandClass::FourToOutsideStraight => 16,
            HandClass::ThreeToSFType1 => 17,
            HandClass::SuitedQJ => 18,
            HandClass::FourToInsideStraight4High => 19,
            HandClass::SuitedKQOrKJ => 20,
            HandClass::SuitedAKAQAJ => 21,
            HandClass::FourToInsideStraight3High => 22,
            HandClass::ThreeToSFType2 => 23,
            HandClass::UnsuitedJQK => 24,
            HandClass::UnsuitedJQ => 25,
            HandClass::SuitedTJ => 26,
            HandClass::TwoUnsuitedHighKing => 27,
            HandClass::SuitedTQ => 28,
            HandClass::TwoUnsuitedHighAce => 29,
            HandClass::JOnly => 30,
            HandClass::SuitedTK => 31,
            HandClass::QOnly => 32,
            HandClass::KOnly => 33,
            HandClass::AOnly => 34,
            HandClass::ThreeToSFType3 => 35,
            HandClass::Garbage => 36,
        }
    }

    fn name(&self) -> &'static str {
        match self {
            HandClass::FourOfAKind => "Four of a kind",
            HandClass::FourToRoyalFlush => "4 to a royal flush",
            HandClass::FullHouse => "Full house",
            HandClass::Flush => "Flush",
            HandClass::ThreeOfAKind => "Three of a kind",
            HandClass::Straight => "Straight",
            HandClass::FourToStraightFlush => "4 to a straight flush",
            HandClass::TwoPair => "Two pair",
            HandClass::HighPair => "High pair",
            HandClass::ThreeToRoyalFlush => "3 to a royal flush",
            HandClass::FourToFlush => "4 to a flush",
            HandClass::UnsuitedTJQK => "Unsuited TJQK",
            HandClass::LowPair => "Low pair",
            HandClass::FourToOutsideStraight => "4 to outside straight (0-2 high)",
            HandClass::ThreeToSFType1 => "3 to SF type 1",
            HandClass::SuitedQJ => "Suited QJ",
            HandClass::FourToInsideStraight4High => "4 to inside straight (4 high)",
            HandClass::SuitedKQOrKJ => "Suited KQ or KJ",
            HandClass::SuitedAKAQAJ => "Suited AK, AQ, or AJ",
            HandClass::FourToInsideStraight3High => "4 to inside straight (3 high)",
            HandClass::ThreeToSFType2 => "3 to SF type 2",
            HandClass::UnsuitedJQK => "Unsuited JQK",
            HandClass::UnsuitedJQ => "Unsuited JQ",
            HandClass::SuitedTJ => "Suited TJ",
            HandClass::TwoUnsuitedHighKing => "2 unsuited high (K highest)",
            HandClass::SuitedTQ => "Suited TQ",
            HandClass::TwoUnsuitedHighAce => "2 unsuited high (A highest)",
            HandClass::JOnly => "J only",
            HandClass::SuitedTK => "Suited TK",
            HandClass::QOnly => "Q only",
            HandClass::KOnly => "K only",
            HandClass::AOnly => "A only",
            HandClass::ThreeToSFType3 => "3 to SF type 3",
            HandClass::Garbage => "Garbage",
        }
    }
}

fn is_straight_ranks(ranks: &[Rank]) -> bool {
    if ranks.len() != 5 {
        return false;
    }
    let mut values: Vec<u8> = ranks.iter().map(|r| r.value()).collect();
    values.sort();

    if values == vec![2, 3, 4, 5, 14] {
        return true;
    }

    for i in 1..values.len() {
        if values[i] != values[i - 1] + 1 {
            return false;
        }
    }
    true
}

fn is_outside_straight_draw(ranks: &[Rank]) -> Option<usize> {
    if ranks.len() != 4 {
        return None;
    }
    let mut values: Vec<u8> = ranks.iter().map(|r| r.value()).collect();
    values.sort();
    values.dedup();

    if values.len() != 4 {
        return None;
    }

    let is_consecutive = values[3] - values[0] == 3;
    if !is_consecutive {
        return None;
    }

    let has_ace = values.contains(&14);
    if has_ace {
        return None;
    }

    let high_count = ranks.iter().filter(|r| r.is_high()).count();
    Some(high_count)
}

fn is_inside_straight_draw(ranks: &[Rank]) -> Option<usize> {
    if ranks.len() != 4 {
        return None;
    }
    let mut values: Vec<u8> = ranks.iter().map(|r| r.value()).collect();
    values.sort();
    values.dedup();

    if values.len() != 4 {
        return None;
    }

    if values == vec![2, 3, 4, 14] {
        let high_count = ranks.iter().filter(|r| r.is_high()).count();
        return Some(high_count);
    }

    let span = values[3] - values[0];

    if span == 4 {
        let high_count = ranks.iter().filter(|r| r.is_high()).count();
        return Some(high_count);
    }

    if values[3] == 14 && values[0] >= 10 {
        let high_count = ranks.iter().filter(|r| r.is_high()).count();
        return Some(high_count);
    }

    None
}

fn sf_draw_gaps_and_highs(ranks: &[Rank]) -> Option<(usize, usize)> {
    if ranks.len() != 3 {
        return None;
    }

    let mut values: Vec<u8> = ranks.iter().map(|r| r.value()).collect();
    values.sort();

    let has_ace = values.contains(&14);
    let has_low = values.iter().any(|&v| v <= 5);

    if has_ace && has_low {
        let low_values: Vec<u8> = values.iter().map(|&v| if v == 14 { 1 } else { v }).collect();
        let mut low_sorted = low_values.clone();
        low_sorted.sort();

        if low_sorted[2] <= 5 {
            let gaps = (low_sorted[2] - low_sorted[0]) as usize - 2;
            let high_count = ranks.iter().filter(|r| r.is_high()).count();
            return Some((gaps, high_count));
        }
    }

    let span = values[2] - values[0];
    if span > 4 {
        return None;
    }

    let gaps = span as usize - 2;
    let high_count = ranks.iter().filter(|r| r.is_high()).count();

    Some((gaps, high_count))
}

fn sf_draw_type(gaps: usize, high_cards: usize, ranks: &[Rank]) -> Option<u8> {
    let mut values: Vec<u8> = ranks.iter().map(|r| r.value()).collect();
    values.sort();

    let has_ace = values.contains(&14);
    let has_low = values.iter().any(|&v| v <= 4);
    let is_ace_low = has_ace && has_low && values.iter().filter(|&&v| v <= 5 || v == 14).count() == 3;

    let is_234 = values == vec![2, 3, 4];

    if high_cards >= gaps {
        return Some(1);
    }

    if (gaps == 1 && high_cards == 0) ||
       (gaps == 2 && high_cards == 1) ||
       is_ace_low ||
       is_234 {
        return Some(2);
    }

    if gaps == 2 && high_cards == 0 {
        return Some(3);
    }

    None
}

fn get_hand_classes(hand: &Hand) -> Vec<HandClass> {
    let mut classes = Vec::new();
    let rank_counts = hand.rank_counts();
    let suit_counts = hand.suit_counts();
    let ranks = hand.ranks();

    let mut pairs = 0;
    let mut trips = 0;
    let mut quads = 0;
    let mut pair_ranks = Vec::new();

    for (&rank, &count) in &rank_counts {
        match count {
            2 => { pairs += 1; pair_ranks.push(rank); }
            3 => { trips += 1; }
            4 => { quads += 1; }
            _ => {}
        }
    }

    let is_flush = suit_counts.values().any(|&c| c == 5);
    let unique_ranks: Vec<Rank> = rank_counts.keys().cloned().collect();
    let is_straight = unique_ranks.len() == 5 && is_straight_ranks(&unique_ranks);

    if quads == 1 {
        classes.push(HandClass::FourOfAKind);
    }

    if trips == 1 && pairs == 1 {
        classes.push(HandClass::FullHouse);
    }

    if is_flush && !is_straight {
        classes.push(HandClass::Flush);
    }

    if is_straight && !is_flush {
        classes.push(HandClass::Straight);
    }

    if trips == 1 && pairs == 0 {
        classes.push(HandClass::ThreeOfAKind);
    }

    if pairs == 2 {
        classes.push(HandClass::TwoPair);
    }

    if pairs == 1 && trips == 0 {
        let pair_rank = pair_ranks[0];
        if pair_rank.is_high() && pair_rank != Rank::Ten {
            classes.push(HandClass::HighPair);
        } else {
            classes.push(HandClass::LowPair);
        }
    }

    let all_suits = vec![CanonicalSuit::A, CanonicalSuit::B, CanonicalSuit::C, CanonicalSuit::D];

    for suit in &all_suits {
        let suited_cards: Vec<&Card> = hand.cards_of_suit(*suit);
        let suited_ranks: Vec<Rank> = suited_cards.iter().map(|c| c.rank).collect();

        if suited_cards.len() == 4 {
            let mut is_sf_draw = false;
            let mut sorted_values: Vec<u8> = suited_ranks.iter().map(|r| r.value()).collect();
            sorted_values.sort();

            let span = sorted_values[3] - sorted_values[0];
            let is_ace_low_sf = sorted_values == vec![2, 3, 4, 14];

            if span <= 4 || is_ace_low_sf {
                let royal_ranks = vec![10, 11, 12, 13, 14];
                let is_royal_draw = sorted_values.iter().all(|v| royal_ranks.contains(v));

                if is_royal_draw {
                    classes.push(HandClass::FourToRoyalFlush);
                } else {
                    classes.push(HandClass::FourToStraightFlush);
                }
                is_sf_draw = true;
            }

            if !is_sf_draw {
                classes.push(HandClass::FourToFlush);
            }
        }

        if suited_cards.len() >= 3 {
            let royal_cards: Vec<&Card> = suited_cards.iter()
                .filter(|c| matches!(c.rank, Rank::Ten | Rank::Jack | Rank::Queen | Rank::King | Rank::Ace))
                .cloned()
                .collect();

            if royal_cards.len() >= 3 {
                classes.push(HandClass::ThreeToRoyalFlush);
            }
        }

        if suited_cards.len() >= 3 {
            for i in 0..suited_cards.len() {
                for j in (i+1)..suited_cards.len() {
                    for k in (j+1)..suited_cards.len() {
                        let three_ranks = vec![suited_cards[i].rank, suited_cards[j].rank, suited_cards[k].rank];

                        let all_royal = three_ranks.iter().all(|r|
                            matches!(r, Rank::Ten | Rank::Jack | Rank::Queen | Rank::King | Rank::Ace));
                        if all_royal {
                            continue;
                        }

                        if let Some((gaps, highs)) = sf_draw_gaps_and_highs(&three_ranks) {
                            if let Some(sf_type) = sf_draw_type(gaps, highs, &three_ranks) {
                                match sf_type {
                                    1 => { if !classes.contains(&HandClass::ThreeToSFType1) { classes.push(HandClass::ThreeToSFType1); } }
                                    2 => { if !classes.contains(&HandClass::ThreeToSFType2) { classes.push(HandClass::ThreeToSFType2); } }
                                    3 => { if !classes.contains(&HandClass::ThreeToSFType3) { classes.push(HandClass::ThreeToSFType3); } }
                                    _ => {}
                                }
                            }
                        }
                    }
                }
            }
        }

        if suited_cards.len() >= 2 {
            let has_t = suited_ranks.contains(&Rank::Ten);
            let has_j = suited_ranks.contains(&Rank::Jack);
            let has_q = suited_ranks.contains(&Rank::Queen);
            let has_k = suited_ranks.contains(&Rank::King);
            let has_a = suited_ranks.contains(&Rank::Ace);

            if has_q && has_j { classes.push(HandClass::SuitedQJ); }
            if has_k && has_q { classes.push(HandClass::SuitedKQOrKJ); }
            if has_k && has_j && !classes.contains(&HandClass::SuitedKQOrKJ) { classes.push(HandClass::SuitedKQOrKJ); }
            if has_a && has_k { classes.push(HandClass::SuitedAKAQAJ); }
            if has_a && has_q && !classes.contains(&HandClass::SuitedAKAQAJ) { classes.push(HandClass::SuitedAKAQAJ); }
            if has_a && has_j && !classes.contains(&HandClass::SuitedAKAQAJ) { classes.push(HandClass::SuitedAKAQAJ); }
            if has_t && has_j { classes.push(HandClass::SuitedTJ); }
            if has_t && has_q { classes.push(HandClass::SuitedTQ); }
            if has_t && has_k { classes.push(HandClass::SuitedTK); }
        }
    }

    let indices: Vec<Vec<usize>> = vec![
        vec![0,1,2,3], vec![0,1,2,4], vec![0,1,3,4], vec![0,2,3,4], vec![1,2,3,4]
    ];

    for idx in &indices {
        let four_cards: Vec<Rank> = idx.iter().map(|&i| hand.cards[i].rank).collect();

        if let Some(high_count) = is_outside_straight_draw(&four_cards) {
            if high_count <= 2 {
                if !classes.contains(&HandClass::FourToOutsideStraight) {
                    classes.push(HandClass::FourToOutsideStraight);
                }
            }
        }

        if let Some(high_count) = is_inside_straight_draw(&four_cards) {
            if high_count == 4 {
                if !classes.contains(&HandClass::FourToInsideStraight4High) {
                    classes.push(HandClass::FourToInsideStraight4High);
                }
            } else if high_count == 3 {
                if !classes.contains(&HandClass::FourToInsideStraight3High) {
                    classes.push(HandClass::FourToInsideStraight3High);
                }
            }
        }
    }

    let high_cards: Vec<Rank> = ranks.iter().filter(|r| r.is_high() && **r != Rank::Ten).cloned().collect();
    let has_j = high_cards.contains(&Rank::Jack);
    let has_q = high_cards.contains(&Rank::Queen);
    let has_k = high_cards.contains(&Rank::King);
    let has_a = high_cards.contains(&Rank::Ace);

    let j_suits: HashSet<CanonicalSuit> = hand.cards.iter().filter(|c| c.rank == Rank::Jack).map(|c| c.suit).collect();
    let q_suits: HashSet<CanonicalSuit> = hand.cards.iter().filter(|c| c.rank == Rank::Queen).map(|c| c.suit).collect();
    let k_suits: HashSet<CanonicalSuit> = hand.cards.iter().filter(|c| c.rank == Rank::King).map(|c| c.suit).collect();
    let a_suits: HashSet<CanonicalSuit> = hand.cards.iter().filter(|c| c.rank == Rank::Ace).map(|c| c.suit).collect();
    let t_suits: HashSet<CanonicalSuit> = hand.cards.iter().filter(|c| c.rank == Rank::Ten).map(|c| c.suit).collect();

    if hand.ranks().contains(&Rank::Ten) && has_j && has_q && has_k {
        let all_suits: HashSet<CanonicalSuit> = t_suits.iter().chain(j_suits.iter()).chain(q_suits.iter()).chain(k_suits.iter()).cloned().collect();
        if all_suits.len() > 1 {
            classes.push(HandClass::UnsuitedTJQK);
        }
    }

    if has_j && has_q && has_k {
        let all_suits: HashSet<CanonicalSuit> = j_suits.iter().chain(q_suits.iter()).chain(k_suits.iter()).cloned().collect();
        if all_suits.len() > 1 {
            classes.push(HandClass::UnsuitedJQK);
        }
    }

    if has_j && has_q {
        let all_suits: HashSet<CanonicalSuit> = j_suits.iter().chain(q_suits.iter()).cloned().collect();
        if all_suits.len() > 1 {
            classes.push(HandClass::UnsuitedJQ);
        }
    }

    if has_k && (has_j || has_q) && !has_a {
        let relevant_suits: HashSet<CanonicalSuit> = j_suits.iter().chain(q_suits.iter()).chain(k_suits.iter()).cloned().collect();
        if relevant_suits.len() > 1 {
            classes.push(HandClass::TwoUnsuitedHighKing);
        }
    }

    if has_a && (has_j || has_q || has_k) {
        let relevant_suits: HashSet<CanonicalSuit> = j_suits.iter().chain(q_suits.iter()).chain(k_suits.iter()).chain(a_suits.iter()).cloned().collect();
        if relevant_suits.len() > 1 {
            classes.push(HandClass::TwoUnsuitedHighAce);
        }
    }

    if has_j { classes.push(HandClass::JOnly); }
    if has_q { classes.push(HandClass::QOnly); }
    if has_k { classes.push(HandClass::KOnly); }
    if has_a { classes.push(HandClass::AOnly); }

    classes.push(HandClass::Garbage);

    classes
}

// Generate all canonical 5-card hands
// Canonical means we assign suits in order of first appearance: a, b, c, d
fn generate_canonical_hands() -> Vec<Hand> {
    let mut canonical_set: HashSet<Vec<(u8, u8)>> = HashSet::new();
    let mut hands = Vec::new();

    let ranks = Rank::all();
    let n_ranks = ranks.len();

    // Generate all combinations of 5 ranks (with repetition for pairs, etc.)
    // Actually we need all 5-card combinations from a 52-card deck, then canonicalize

    // Simpler approach: generate all suit patterns for each rank combination
    // Suit patterns: for 5 cards, suits can be assigned as first-seen = a, second-seen = b, etc.

    // Generate all rank combinations (with replacement allowed up to 4 of same rank)
    for r1 in 0..n_ranks {
        for r2 in r1..n_ranks {
            for r3 in r2..n_ranks {
                for r4 in r3..n_ranks {
                    for r5 in r4..n_ranks {
                        let rank_combo = vec![ranks[r1], ranks[r2], ranks[r3], ranks[r4], ranks[r5]];

                        // Check if this is a valid combination (no more than 4 of any rank)
                        let mut rank_counts = HashMap::new();
                        for &r in &rank_combo {
                            *rank_counts.entry(r).or_insert(0) += 1;
                        }
                        if rank_counts.values().any(|&c| c > 4) {
                            continue;
                        }

                        // Generate all valid suit patterns
                        let suit_patterns = generate_suit_patterns(&rank_combo);

                        for suits in suit_patterns {
                            let cards: Vec<Card> = rank_combo.iter().zip(suits.iter())
                                .map(|(&r, &s)| Card::new(r, s))
                                .collect();

                            // Create canonical representation
                            let canonical = canonicalize(&cards);

                            if !canonical_set.contains(&canonical) {
                                canonical_set.insert(canonical);
                                hands.push(Hand::new(cards));
                            }
                        }
                    }
                }
            }
        }
    }

    hands
}

// Generate all valid suit patterns for a given rank combination
fn generate_suit_patterns(ranks: &[Rank]) -> Vec<Vec<CanonicalSuit>> {
    let all_suits = vec![CanonicalSuit::A, CanonicalSuit::B, CanonicalSuit::C, CanonicalSuit::D];
    let mut patterns = Vec::new();

    // Count how many of each rank we have
    let mut rank_counts: HashMap<Rank, usize> = HashMap::new();
    for &r in ranks {
        *rank_counts.entry(r).or_insert(0) += 1;
    }

    // Generate all possible suit assignments
    generate_suits_recursive(ranks, 0, &mut Vec::new(), &all_suits, &mut patterns, &mut HashMap::new());

    patterns
}

fn generate_suits_recursive(
    ranks: &[Rank],
    idx: usize,
    current: &mut Vec<CanonicalSuit>,
    all_suits: &[CanonicalSuit],
    patterns: &mut Vec<Vec<CanonicalSuit>>,
    used_suits_for_rank: &mut HashMap<Rank, HashSet<CanonicalSuit>>,
) {
    if idx == ranks.len() {
        patterns.push(current.clone());
        return;
    }

    let rank = ranks[idx];

    for &suit in all_suits {
        let already_used = used_suits_for_rank
            .get(&rank)
            .map(|s| s.contains(&suit))
            .unwrap_or(false);

        if !already_used {
            current.push(suit);
            used_suits_for_rank.entry(rank).or_insert_with(HashSet::new).insert(suit);
            generate_suits_recursive(ranks, idx + 1, current, all_suits, patterns, used_suits_for_rank);
            used_suits_for_rank.get_mut(&rank).unwrap().remove(&suit);
            current.pop();
        }
    }
}

// Convert hand to canonical form (suits assigned in order of first appearance)
fn canonicalize(cards: &[Card]) -> Vec<(u8, u8)> {
    let mut suit_map: HashMap<CanonicalSuit, u8> = HashMap::new();
    let mut next_suit: u8 = 0;

    // Sort by rank first, then by original suit for consistency
    let mut sorted_cards = cards.to_vec();
    sorted_cards.sort_by(|a, b| a.rank.cmp(&b.rank).then(a.suit.cmp(&b.suit)));

    let mut result: Vec<(u8, u8)> = Vec::new();

    for card in &sorted_cards {
        let canonical_suit = *suit_map.entry(card.suit).or_insert_with(|| {
            let s = next_suit;
            next_suit += 1;
            s
        });
        result.push((card.rank.value(), canonical_suit));
    }

    result.sort();
    result
}

#[derive(Debug)]
struct ConflictResult {
    hand: String,
    rank_diff: u8,
    class1: HandClass,
    class2: HandClass,
}

fn main() {
    println!("Generating all canonical 5-card hands...");
    let hands = generate_canonical_hands();
    println!("Total canonical hands: {}", hands.len());

    println!("\nAnalyzing hands for close-ranked conflicts (within 5 ranks)...\n");

    let mut conflicts: Vec<ConflictResult> = Vec::new();

    for hand in &hands {
        let classes = get_hand_classes(hand);

        // Find the best two classes that are within 5 ranks
        let mut dominated_classes: BTreeSet<HandClass> = BTreeSet::new();

        for i in 0..classes.len() {
            for j in (i+1)..classes.len() {
                let r1 = classes[i].rank();
                let r2 = classes[j].rank();
                let diff = if r1 > r2 { r1 - r2 } else { r2 - r1 };

                if diff <= 5 && diff > 0 {
                    let (c1, c2) = if r1 < r2 { (classes[i], classes[j]) } else { (classes[j], classes[i]) };

                    // Skip if c2 is dominated by c1 (i.e., c1 is strictly better and includes c2's cards)
                    // We want to show hands where there's a genuine decision

                    // Don't show conflicts where one dominates the other trivially
                    // e.g., JQK vs JQ - if you have JQK, you'd never hold just JQ
                    let dominated = is_dominated(&c1, &c2);

                    if !dominated && !dominated_classes.contains(&c2) {
                        conflicts.push(ConflictResult {
                            hand: hand.to_string(),
                            rank_diff: diff,
                            class1: c1,
                            class2: c2,
                        });
                        dominated_classes.insert(c2);
                    }
                }
            }
        }
    }

    // Sort by class1 rank, then class2 rank, then hand
    conflicts.sort_by(|a, b| {
        a.class1.rank().cmp(&b.class1.rank())
            .then(a.class2.rank().cmp(&b.class2.rank()))
            .then(a.hand.cmp(&b.hand))
    });

    println!("Found {} canonical hands with conflicts:\n", conflicts.len());
    println!("{:<20} {:<6} {:<35} {:<35}", "Hand", "Diff", "Class 1 (better)", "Class 2");
    println!("{}", "-".repeat(100));

    for conflict in &conflicts {
        println!("{:<20} {:<6} {:<35} {:<35}",
            conflict.hand,
            conflict.rank_diff,
            format!("({}) {}", conflict.class1.rank(), conflict.class1.name()),
            format!("({}) {}", conflict.class2.rank(), conflict.class2.name()),
        );
    }

    // Summary by conflict type
    println!("\n\n=== SUMMARY BY CONFLICT TYPE ===\n");

    let mut summary: HashMap<(u8, u8), usize> = HashMap::new();
    for conflict in &conflicts {
        let key = (conflict.class1.rank(), conflict.class2.rank());
        *summary.entry(key).or_insert(0) += 1;
    }

    let mut summary_vec: Vec<_> = summary.into_iter().collect();
    summary_vec.sort_by_key(|&((r1, r2), _)| (r1, r2));

    for ((r1, r2), count) in summary_vec {
        let c1_name = conflicts.iter().find(|c| c.class1.rank() == r1).map(|c| c.class1.name()).unwrap_or("?");
        let c2_name = conflicts.iter().find(|c| c.class2.rank() == r2).map(|c| c.class2.name()).unwrap_or("?");
        println!("({}) {} vs ({}) {}: {} hands", r1, c1_name, r2, c2_name, count);
    }
}

// Check if class2 is dominated by class1 (trivially worse)
fn is_dominated(c1: &HandClass, c2: &HandClass) -> bool {
    use HandClass::*;

    match (c1, c2) {
        // JQK dominates JQ
        (UnsuitedJQK, UnsuitedJQ) => true,
        // JQK dominates single high cards
        (UnsuitedJQK, JOnly) | (UnsuitedJQK, QOnly) | (UnsuitedJQK, KOnly) => true,
        // JQ dominates single J or Q
        (UnsuitedJQ, JOnly) | (UnsuitedJQ, QOnly) => true,
        // 2 unsuited high (K) dominates single cards
        (TwoUnsuitedHighKing, JOnly) | (TwoUnsuitedHighKing, QOnly) | (TwoUnsuitedHighKing, KOnly) => true,
        // 2 unsuited high (A) dominates singles
        (TwoUnsuitedHighAce, JOnly) | (TwoUnsuitedHighAce, QOnly) | (TwoUnsuitedHighAce, KOnly) | (TwoUnsuitedHighAce, AOnly) => true,
        // Suited pairs dominate their component singles when clearly better
        (SuitedQJ, JOnly) | (SuitedQJ, QOnly) => true,
        (SuitedKQOrKJ, JOnly) | (SuitedKQOrKJ, QOnly) | (SuitedKQOrKJ, KOnly) => true,
        (SuitedAKAQAJ, JOnly) | (SuitedAKAQAJ, QOnly) | (SuitedAKAQAJ, KOnly) | (SuitedAKAQAJ, AOnly) => true,
        (SuitedTJ, JOnly) => true,
        (SuitedTQ, QOnly) => true,
        (SuitedTK, KOnly) => true,
        // 4 to flush dominates 3 to SF when same suit
        // Skip garbage comparisons for most things
        (_, Garbage) => true,
        _ => false,
    }
}
