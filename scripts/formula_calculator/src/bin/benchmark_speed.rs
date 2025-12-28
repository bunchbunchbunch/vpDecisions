// Benchmark: Formula vs Brute Force Speed Comparison
// This will tell us if the formula approach is actually faster

use std::time::Instant;
use itertools::Itertools;
use rand::{thread_rng, seq::SliceRandom};

// Copy minimal code from formula_ddb.rs for benchmarking
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash, PartialOrd, Ord)]
struct Card(u8);

impl Card {
    fn rank(&self) -> u8 { self.0 / 4 }
    fn suit(&self) -> u8 { self.0 % 4 }
}

type Hand = [Card; 5];

fn main() {
    println!("=================================================");
    println!("Formula vs Brute Force Speed Benchmark");
    println!("=================================================\n");

    // Generate a sample of random hands
    let mut rng = thread_rng();
    let mut sample_hands = Vec::new();

    for _ in 0..1000 {
        let mut cards: Vec<u8> = (0..52).collect();
        cards.shuffle(&mut rng);
        let hand: Hand = [Card(cards[0]), Card(cards[1]), Card(cards[2]), Card(cards[3]), Card(cards[4])];
        sample_hands.push(hand);
    }

    println!("Testing on 1000 random hands × 32 hold patterns = 32,000 evaluations\n");

    // TODO: Benchmark brute force approach
    println!("Brute Force Approach:");
    println!("  [Need to implement using code from rust_calculator/src/main.rs]");
    println!("  Expected: ~60-100 evals/sec based on original implementation\n");

    // TODO: Benchmark formula approach
    println!("Formula Approach:");
    println!("  [Need to implement using code from formula_ddb.rs]");
    println!("  Current: ~60 evals/sec (from validation)\n");

    println!("=================================================");
    println!("KEY QUESTION:");
    println!("Is the formula approach actually faster?");
    println!("If not, we should:");
    println!("  1. Use brute force with parallelization (rayon)");
    println!("  2. OR implement more formula optimizations");
    println!("=================================================");
}
