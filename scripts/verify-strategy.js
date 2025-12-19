// Verify Supabase strategy data against local EV calculations
// This script compares a sample of hands to ensure correctness

import { createClient } from '@supabase/supabase-js';
import { config } from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

config({ path: join(__dirname, '..', '.env') });

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Paytable (using Jacks or Better 9/6 for testing)
const PAYTABLE = {
    gameType: 'jacks-or-better',
    pays: {
        royalFlush: 800, straightFlush: 50, fourOfAKind: 25,
        fullHouse: 9, flush: 6, straight: 4, threeOfAKind: 3,
        twoPair: 2, jacksOrBetter: 1
    }
};

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

// Canonical key generation
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
    return sorted.map(card => rankDisplay[card.rank] + suitMap[card.suit]).join('');
}

// Hand evaluation functions
function isFlush(cards) {
    if (cards.length !== 5) return false;
    return cards.every(c => c.suit === cards[0].suit);
}

function isStraight(cards) {
    if (cards.length !== 5) return false;
    const values = cards.map(c => rankValues[c.rank]).sort((a, b) => a - b);
    let isRegularStraight = true;
    for (let i = 1; i < values.length; i++) {
        if (values[i] !== values[i-1] + 1) { isRegularStraight = false; break; }
    }
    const isWheelStraight = values[0] === 2 && values[1] === 3 && values[2] === 4 && values[3] === 5 && values[4] === 14;
    return isRegularStraight || isWheelStraight;
}

function isRoyalFlush(cards) {
    if (!isFlush(cards) || cards.length !== 5) return false;
    const cardRanks = cards.map(c => c.rank).sort();
    return cardRanks.join(',') === '10,A,J,K,Q';
}

function isStraightFlush(cards) {
    return isFlush(cards) && isStraight(cards) && !isRoyalFlush(cards);
}

function getRankCounts(cards) {
    const counts = {};
    cards.forEach(card => { counts[card.rank] = (counts[card.rank] || 0) + 1; });
    return counts;
}

function getPairs(cards) {
    const counts = getRankCounts(cards);
    return Object.entries(counts).filter(([rank, count]) => count === 2).map(([rank]) => rank);
}

function getTrips(cards) {
    const counts = getRankCounts(cards);
    return Object.entries(counts).filter(([rank, count]) => count === 3).map(([rank]) => rank);
}

function getQuads(cards) {
    const counts = getRankCounts(cards);
    return Object.entries(counts).filter(([rank, count]) => count === 4).map(([rank]) => rank);
}

function classifyFinalHand(cards, paytable) {
    if (cards.length !== 5) return 'nothing';
    if (isRoyalFlush(cards)) return 'royalFlush';
    if (isStraightFlush(cards)) return 'straightFlush';
    const quads = getQuads(cards);
    if (quads.length > 0) return 'fourOfAKind';
    const trips = getTrips(cards);
    const pairs = getPairs(cards);
    if (trips.length > 0 && pairs.length > 0) return 'fullHouse';
    if (isFlush(cards)) return 'flush';
    if (isStraight(cards)) return 'straight';
    if (trips.length > 0) return 'threeOfAKind';
    if (pairs.length === 2) return 'twoPair';
    if (pairs.length === 1 && ['J', 'Q', 'K', 'A'].includes(pairs[0])) return 'jacksOrBetter';
    return 'nothing';
}

function getPayout(handType, paytable) {
    return paytable.pays[handType] || 0;
}

// Generate combinations
function getCombinations(arr, k) {
    if (k === 0) return [[]];
    if (arr.length < k) return [];
    if (arr.length === k) return [arr.slice()];
    const results = [];
    const indices = Array.from({length: k}, (_, i) => i);
    while (true) {
        results.push(indices.map(i => arr[i]));
        let i = k - 1;
        while (i >= 0 && indices[i] === arr.length - k + i) i--;
        if (i < 0) break;
        indices[i]++;
        for (let j = i + 1; j < k; j++) { indices[j] = indices[j-1] + 1; }
    }
    return results;
}

// Calculate EV for a hold pattern
function calculateHoldEV(hand, holdIndices, paytable) {
    const heldCards = holdIndices.map(i => hand[i]);
    const numToDraw = 5 - heldCards.length;

    const remainingDeck = [];
    for (const suit of suits) {
        for (const rank of ranks) {
            const inHand = hand.some(c => c.rank === rank && c.suit === suit);
            if (!inHand) {
                remainingDeck.push({ rank, suit });
            }
        }
    }

    if (numToDraw === 0) {
        const handType = classifyFinalHand(heldCards, paytable);
        return getPayout(handType, paytable);
    }

    const draws = getCombinations(remainingDeck, numToDraw);
    let totalPayout = 0;
    for (const draw of draws) {
        const finalHand = [...heldCards, ...draw];
        const handType = classifyFinalHand(finalHand, paytable);
        totalPayout += getPayout(handType, paytable);
    }
    return totalPayout / draws.length;
}

// Generate all 32 hold patterns
const HOLD_PATTERNS = [];
for (let i = 0; i < 32; i++) {
    const pattern = [];
    for (let j = 0; j < 5; j++) {
        if (i & (1 << j)) pattern.push(j);
    }
    HOLD_PATTERNS.push(pattern);
}

// Analyze hand locally
function analyzeHandLocally(hand) {
    const results = [];
    for (const pattern of HOLD_PATTERNS) {
        const ev = calculateHoldEV(hand, pattern, PAYTABLE);
        const holdBitmask = pattern.reduce((acc, i) => acc | (1 << i), 0);
        results.push({ hold: holdBitmask, ev: ev });
    }
    results.sort((a, b) => b.ev - a.ev);
    return results.slice(0, 2);
}

// Create deck and deal
function createDeck() {
    const deck = [];
    for (const suit of suits) {
        for (const rank of ranks) {
            deck.push({ rank, suit });
        }
    }
    return deck;
}

function shuffle(array) {
    const shuffled = [...array];
    for (let i = shuffled.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    return shuffled;
}

function dealHand() {
    return shuffle(createDeck()).slice(0, 5);
}

// Main verification
async function main() {
    console.log('=== Strategy Verification ===\n');

    const numTests = 50; // Number of hands to verify
    let passed = 0;
    let failed = 0;
    let notFound = 0;

    console.log(`Testing ${numTests} random hands against Supabase data...\n`);

    for (let i = 0; i < numTests; i++) {
        const hand = dealHand();
        const key = handToCanonicalKey(hand);
        const handStr = hand.map(c => `${c.rank}${c.suit[0]}`).join(' ');

        // Lookup in Supabase
        const { data, error } = await supabase
            .from('strategy')
            .select('best_hold, best_ev, second_hold, second_ev')
            .eq('paytable_id', 'jacks-or-better-9-6')
            .eq('hand_key', key)
            .single();

        if (error || !data) {
            console.log(`[${i + 1}] NOT FOUND: ${handStr} (key: ${key})`);
            notFound++;
            continue;
        }

        // Calculate locally
        const localResults = analyzeHandLocally(hand);
        const localBestHold = localResults[0].hold;
        const localBestEV = localResults[0].ev;

        // Compare
        const evDiff = Math.abs(localBestEV - data.best_ev);
        const holdMatch = localBestHold === data.best_hold;
        const evMatch = evDiff < 0.0001; // Allow small floating point difference

        if (holdMatch && evMatch) {
            passed++;
            if (i % 10 === 0) {
                console.log(`[${i + 1}] PASS: ${handStr} - EV: ${localBestEV.toFixed(4)}`);
            }
        } else {
            failed++;
            console.log(`[${i + 1}] FAIL: ${handStr}`);
            console.log(`  Local:  hold=${localBestHold}, ev=${localBestEV.toFixed(6)}`);
            console.log(`  Supabase: hold=${data.best_hold}, ev=${data.best_ev}`);
            console.log(`  Key: ${key}`);
        }
    }

    console.log('\n=== Results ===');
    console.log(`Passed: ${passed}`);
    console.log(`Failed: ${failed}`);
    console.log(`Not Found: ${notFound}`);
    console.log(`Total: ${numTests}`);

    if (failed === 0 && notFound === 0) {
        console.log('\n✓ All tests passed!');
    } else if (notFound > 0 && failed === 0) {
        console.log('\n⚠ Some hands not found in database (database may still be building)');
    } else {
        console.log('\n✗ Some tests failed - investigation needed');
    }
}

main().catch(err => {
    console.error('Error:', err);
    process.exit(1);
});
