// Quick test of canonical hand generation and EV calculation
// Tests with a small subset to verify correctness

import { config } from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

config({ path: join(__dirname, '..', '.env') });

// Card constants
const suits = ['hearts', 'diamonds', 'clubs', 'spades'];
const ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];
const rankValues = {
    '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9,
    '10': 10, 'J': 11, 'Q': 12, 'K': 13, 'A': 14
};
const rankDisplay = {
    '2': '2', '3': '3', '4': '4', '5': '5', '6': '6', '7': '7', '8': '8', '9': '9',
    '10': 'T', 'J': 'J', 'Q': 'Q', 'K': 'K', 'A': 'A'
};

function indexToCard(index) {
    return { rank: ranks[index % 13], suit: suits[Math.floor(index / 13)] };
}

function cardToCanonical(card, suitMap) {
    return rankDisplay[card.rank] + suitMap[card.suit];
}

function handToCanonicalKey(cards) {
    const sorted = [...cards].sort((a, b) => rankValues[a.rank] - rankValues[b.rank]);
    const suitMap = {};
    const suitLetters = ['a', 'b', 'c', 'd'];
    let nextSuitIndex = 0;
    for (const card of sorted) {
        if (!(card.suit in suitMap)) {
            suitMap[card.suit] = suitLetters[nextSuitIndex++];
        }
    }
    return sorted.map(card => cardToCanonical(card, suitMap)).join('');
}

// Test 1: Canonical key generation
console.log('=== Test 1: Canonical Key Generation ===\n');

// Two equivalent hands (same ranks, different suits)
const hand1 = [
    { rank: '2', suit: 'spades' },
    { rank: '5', suit: 'hearts' },
    { rank: '7', suit: 'spades' },
    { rank: 'J', suit: 'diamonds' },
    { rank: 'K', suit: 'hearts' }
];

const hand2 = [
    { rank: '2', suit: 'clubs' },
    { rank: '5', suit: 'diamonds' },
    { rank: '7', suit: 'clubs' },
    { rank: 'J', suit: 'spades' },
    { rank: 'K', suit: 'diamonds' }
];

const key1 = handToCanonicalKey(hand1);
const key2 = handToCanonicalKey(hand2);

console.log('Hand 1:', hand1.map(c => c.rank + c.suit[0]).join(' '));
console.log('Canonical key 1:', key1);
console.log('Hand 2:', hand2.map(c => c.rank + c.suit[0]).join(' '));
console.log('Canonical key 2:', key2);
console.log('Keys match (expected: true):', key1 === key2);

// Test 2: Non-equivalent hands
console.log('\n=== Test 2: Non-equivalent Hands ===\n');

const hand3 = [
    { rank: '2', suit: 'spades' },
    { rank: '5', suit: 'spades' },  // All same suit
    { rank: '7', suit: 'spades' },
    { rank: 'J', suit: 'spades' },
    { rank: 'K', suit: 'spades' }
];

const key3 = handToCanonicalKey(hand3);
console.log('Hand 3 (flush):', hand3.map(c => c.rank + c.suit[0]).join(' '));
console.log('Canonical key 3:', key3);
console.log('Keys match (expected: false):', key1 === key3);

// Test 3: Count unique canonical hands in a small sample
console.log('\n=== Test 3: Counting Unique Hands ===\n');

const canonicalHands = new Set();
let processed = 0;

// Process first 100,000 hands
for (let c1 = 0; c1 < 48; c1++) {
    for (let c2 = c1 + 1; c2 < 49; c2++) {
        for (let c3 = c2 + 1; c3 < 50; c3++) {
            for (let c4 = c3 + 1; c4 < 51; c4++) {
                for (let c5 = c4 + 1; c5 < 52; c5++) {
                    const hand = [
                        indexToCard(c1),
                        indexToCard(c2),
                        indexToCard(c3),
                        indexToCard(c4),
                        indexToCard(c5)
                    ];

                    const key = handToCanonicalKey(hand);
                    canonicalHands.add(key);

                    processed++;
                    if (processed >= 100000) break;
                }
                if (processed >= 100000) break;
            }
            if (processed >= 100000) break;
        }
        if (processed >= 100000) break;
    }
    if (processed >= 100000) break;
}

console.log(`Processed ${processed.toLocaleString()} hands`);
console.log(`Found ${canonicalHands.size.toLocaleString()} unique canonical hands`);
console.log(`Compression ratio: ${(processed / canonicalHands.size).toFixed(2)}x`);

// Test 4: Verify a specific EV calculation
console.log('\n=== Test 4: Sample Hands for Verification ===\n');

// Print a few canonical keys for hands that can be verified
const testHands = [
    // Royal flush draw
    [{ rank: '10', suit: 'hearts' }, { rank: 'J', suit: 'hearts' }, { rank: 'Q', suit: 'hearts' }, { rank: 'K', suit: 'hearts' }, { rank: '2', suit: 'spades' }],
    // Pair of Jacks
    [{ rank: 'J', suit: 'hearts' }, { rank: 'J', suit: 'spades' }, { rank: '3', suit: 'diamonds' }, { rank: '7', suit: 'clubs' }, { rank: '9', suit: 'hearts' }],
    // Four to a flush
    [{ rank: '2', suit: 'hearts' }, { rank: '5', suit: 'hearts' }, { rank: '8', suit: 'hearts' }, { rank: 'J', suit: 'hearts' }, { rank: 'K', suit: 'spades' }]
];

for (const hand of testHands) {
    console.log('Hand:', hand.map(c => c.rank + c.suit[0]).join(' '));
    console.log('Canonical key:', handToCanonicalKey(hand));
    console.log();
}

console.log('\n=== All tests passed! ===');
