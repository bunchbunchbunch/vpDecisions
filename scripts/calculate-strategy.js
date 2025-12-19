// Video Poker Strategy Calculator
// Generates all canonical hands and calculates optimal plays for each paytable

import { createClient } from '@supabase/supabase-js';
import { config } from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { writeFileSync, existsSync, readFileSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load environment variables from parent directory
config({ path: join(__dirname, '..', '.env') });

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
    console.error('Missing Supabase credentials in .env file');
    process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// Paytable definitions
const PAYTABLES = {
    'jacks-or-better-9-6': {
        name: 'Jacks or Better 9/6',
        gameType: 'jacks-or-better',
        pays: { royalFlush: 800, straightFlush: 50, fourOfAKind: 25, fullHouse: 9, flush: 6, straight: 4, threeOfAKind: 3, twoPair: 2, jacksOrBetter: 1 }
    },
    'jacks-or-better-8-5': {
        name: 'Jacks or Better 8/5',
        gameType: 'jacks-or-better',
        pays: { royalFlush: 800, straightFlush: 50, fourOfAKind: 25, fullHouse: 8, flush: 5, straight: 4, threeOfAKind: 3, twoPair: 2, jacksOrBetter: 1 }
    },
    'jacks-or-better-7-5': {
        name: 'Jacks or Better 7/5',
        gameType: 'jacks-or-better',
        pays: { royalFlush: 800, straightFlush: 50, fourOfAKind: 25, fullHouse: 7, flush: 5, straight: 4, threeOfAKind: 3, twoPair: 2, jacksOrBetter: 1 }
    },
    'bonus-poker-8-5': {
        name: 'Bonus Poker 8/5',
        gameType: 'bonus-poker',
        pays: { royalFlush: 800, straightFlush: 50, fourAces: 80, fourTwosThruFours: 40, fourFivesThruKings: 25, fullHouse: 8, flush: 5, straight: 4, threeOfAKind: 3, twoPair: 2, jacksOrBetter: 1 }
    },
    'bonus-poker-7-5': {
        name: 'Bonus Poker 7/5',
        gameType: 'bonus-poker',
        pays: { royalFlush: 800, straightFlush: 50, fourAces: 80, fourTwosThruFours: 40, fourFivesThruKings: 25, fullHouse: 7, flush: 5, straight: 4, threeOfAKind: 3, twoPair: 2, jacksOrBetter: 1 }
    },
    'double-bonus-10-7': {
        name: 'Double Bonus 10/7',
        gameType: 'double-bonus',
        pays: { royalFlush: 800, straightFlush: 50, fourAces: 160, fourTwosThruFours: 80, fourFivesThruKings: 50, fullHouse: 10, flush: 7, straight: 5, threeOfAKind: 3, twoPair: 1, jacksOrBetter: 1 }
    },
    'double-bonus-9-7': {
        name: 'Double Bonus 9/7',
        gameType: 'double-bonus',
        pays: { royalFlush: 800, straightFlush: 50, fourAces: 160, fourTwosThruFours: 80, fourFivesThruKings: 50, fullHouse: 9, flush: 7, straight: 5, threeOfAKind: 3, twoPair: 1, jacksOrBetter: 1 }
    },
    'double-bonus-9-6': {
        name: 'Double Bonus 9/6',
        gameType: 'double-bonus',
        pays: { royalFlush: 800, straightFlush: 50, fourAces: 160, fourTwosThruFours: 80, fourFivesThruKings: 50, fullHouse: 9, flush: 6, straight: 5, threeOfAKind: 3, twoPair: 1, jacksOrBetter: 1 }
    },
    'double-double-bonus-9-6': {
        name: 'Double Double Bonus 9/6',
        gameType: 'double-double-bonus',
        pays: { royalFlush: 800, straightFlush: 50, fourAcesWithKicker: 400, fourAces: 160, fourTwosThruFoursWithKicker: 160, fourTwosThruFours: 80, fourFivesThruKings: 50, fullHouse: 9, flush: 6, straight: 4, threeOfAKind: 3, twoPair: 1, jacksOrBetter: 1 }
    },
    'double-double-bonus-9-5': {
        name: 'Double Double Bonus 9/5',
        gameType: 'double-double-bonus',
        pays: { royalFlush: 800, straightFlush: 50, fourAcesWithKicker: 400, fourAces: 160, fourTwosThruFoursWithKicker: 160, fourTwosThruFours: 80, fourFivesThruKings: 50, fullHouse: 9, flush: 5, straight: 4, threeOfAKind: 3, twoPair: 1, jacksOrBetter: 1 }
    },
    'double-double-bonus-8-5': {
        name: 'Double Double Bonus 8/5',
        gameType: 'double-double-bonus',
        pays: { royalFlush: 800, straightFlush: 50, fourAcesWithKicker: 400, fourAces: 160, fourTwosThruFoursWithKicker: 160, fourTwosThruFours: 80, fourFivesThruKings: 50, fullHouse: 8, flush: 5, straight: 4, threeOfAKind: 3, twoPair: 1, jacksOrBetter: 1 }
    }
};

// Card constants
const suits = ['hearts', 'diamonds', 'clubs', 'spades'];
const ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];
const rankValues = {
    '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9,
    '10': 10, 'J': 11, 'Q': 12, 'K': 13, 'A': 14
};

// Rank display for canonical key (T for 10)
const rankDisplay = {
    '2': '2', '3': '3', '4': '4', '5': '5', '6': '6', '7': '7', '8': '8', '9': '9',
    '10': 'T', 'J': 'J', 'Q': 'Q', 'K': 'K', 'A': 'A'
};

// Convert card index (0-51) to card object
function indexToCard(index) {
    return { rank: ranks[index % 13], suit: suits[Math.floor(index / 13)] };
}

// Convert card to canonical form: rank + canonical suit letter
function cardToCanonical(card, suitMap) {
    const canonicalSuit = suitMap[card.suit];
    return rankDisplay[card.rank] + canonicalSuit;
}

// Convert a hand to canonical key
// Sort by rank, assign suits in order of first appearance
function handToCanonicalKey(cards) {
    // Sort cards by rank value
    const sorted = [...cards].sort((a, b) => rankValues[a.rank] - rankValues[b.rank]);

    // Assign canonical suits based on order of first appearance
    const suitMap = {};
    const suitLetters = ['a', 'b', 'c', 'd'];
    let nextSuitIndex = 0;

    for (const card of sorted) {
        if (!(card.suit in suitMap)) {
            suitMap[card.suit] = suitLetters[nextSuitIndex++];
        }
    }

    // Build canonical key
    return sorted.map(card => cardToCanonical(card, suitMap)).join('');
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
    if (quads.length > 0) {
        const quadRank = quads[0];
        const gameType = paytable.gameType;

        if (gameType === 'double-double-bonus') {
            const kicker = cards.find(c => c.rank !== quadRank);
            const kickerIsLow = ['A', '2', '3', '4'].includes(kicker.rank);
            if (quadRank === 'A' && kickerIsLow) return 'fourAcesWithKicker';
            if (['2', '3', '4'].includes(quadRank) && kickerIsLow) return 'fourTwosThruFoursWithKicker';
        }

        if (gameType === 'bonus-poker' || gameType === 'double-bonus' || gameType === 'double-double-bonus') {
            if (quadRank === 'A') return 'fourAces';
            if (['2', '3', '4'].includes(quadRank)) return 'fourTwosThruFours';
            return 'fourFivesThruKings';
        }
        return 'fourOfAKind';
    }

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

// Generate all k-combinations
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

// Calculate EV for a specific hold pattern
function calculateHoldEV(hand, holdIndices, paytable) {
    const heldCards = holdIndices.map(i => hand[i]);
    const numToDraw = 5 - heldCards.length;

    // Build remaining deck
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

// Analyze a hand - returns top 2 plays
function analyzeHand(hand, paytable) {
    const results = [];

    for (const pattern of HOLD_PATTERNS) {
        const ev = calculateHoldEV(hand, pattern, paytable);
        const holdBitmask = pattern.reduce((acc, i) => acc | (1 << i), 0);
        results.push({ hold: holdBitmask, ev: ev });
    }

    results.sort((a, b) => b.ev - a.ev);
    return results.slice(0, 2); // Return top 2
}

// Generate all canonical hands
function generateCanonicalHands() {
    console.log('Generating all canonical hands...');
    const canonicalHands = new Map(); // key -> representative hand

    let processed = 0;
    const total = 2598960;

    // Iterate through all C(52,5) combinations
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

                        // Only store if we haven't seen this canonical form
                        if (!canonicalHands.has(key)) {
                            canonicalHands.set(key, hand);
                        }

                        processed++;
                        if (processed % 100000 === 0) {
                            console.log(`  Processed ${processed.toLocaleString()} / ${total.toLocaleString()} hands, found ${canonicalHands.size.toLocaleString()} unique`);
                        }
                    }
                }
            }
        }
    }

    console.log(`Found ${canonicalHands.size.toLocaleString()} canonical hands`);
    return canonicalHands;
}

// Calculate strategy for all hands and one paytable
async function calculateStrategyForPaytable(canonicalHands, paytableId, paytable) {
    console.log(`\nCalculating strategy for ${paytable.name}...`);

    const results = [];
    let processed = 0;
    const total = canonicalHands.size;

    for (const [key, hand] of canonicalHands) {
        const analysis = analyzeHand(hand, paytable);

        results.push({
            paytable_id: paytableId,
            hand_key: key,
            best_hold: analysis[0].hold,
            best_ev: parseFloat(analysis[0].ev.toFixed(6)),
            second_hold: analysis[1] ? analysis[1].hold : null,
            second_ev: analysis[1] ? parseFloat(analysis[1].ev.toFixed(6)) : null
        });

        processed++;
        if (processed % 10000 === 0) {
            console.log(`  ${processed.toLocaleString()} / ${total.toLocaleString()} hands calculated`);
        }
    }

    return results;
}

// Upload to Supabase in batches
async function uploadToSupabase(results, paytableId) {
    console.log(`Uploading ${results.length.toLocaleString()} hands to Supabase...`);

    const batchSize = 1000;
    let uploaded = 0;

    for (let i = 0; i < results.length; i += batchSize) {
        const batch = results.slice(i, i + batchSize);

        const { error } = await supabase
            .from('strategy')
            .upsert(batch, { onConflict: 'paytable_id,hand_key' });

        if (error) {
            console.error(`Error uploading batch: ${error.message}`);
            throw error;
        }

        uploaded += batch.length;
        if (uploaded % 10000 === 0 || uploaded === results.length) {
            console.log(`  Uploaded ${uploaded.toLocaleString()} / ${results.length.toLocaleString()}`);
        }
    }

    console.log(`Successfully uploaded ${results.length.toLocaleString()} hands for ${paytableId}`);
}

// Save to JSON file (backup)
function saveToJson(results, paytableId) {
    const filename = join(__dirname, `strategy-${paytableId}.json`);
    writeFileSync(filename, JSON.stringify(results, null, 2));
    console.log(`Saved to ${filename}`);
}

// Main execution
async function main() {
    const args = process.argv.slice(2);
    const specificPaytable = args[0]; // Optional: only calculate for one paytable
    const skipUpload = args.includes('--skip-upload');
    const saveJson = args.includes('--save-json');

    console.log('=== Video Poker Strategy Calculator ===\n');

    // Step 1: Generate canonical hands
    const canonicalHands = generateCanonicalHands();

    // Step 2: Calculate for each paytable
    const paytablesToProcess = specificPaytable
        ? { [specificPaytable]: PAYTABLES[specificPaytable] }
        : PAYTABLES;

    for (const [paytableId, paytable] of Object.entries(paytablesToProcess)) {
        if (!paytable) {
            console.error(`Unknown paytable: ${specificPaytable}`);
            continue;
        }

        const startTime = Date.now();
        const results = await calculateStrategyForPaytable(canonicalHands, paytableId, paytable);
        const calcTime = ((Date.now() - startTime) / 1000).toFixed(1);
        console.log(`Calculation completed in ${calcTime}s`);

        // Save to JSON if requested
        if (saveJson) {
            saveToJson(results, paytableId);
        }

        // Upload to Supabase
        if (!skipUpload) {
            const uploadStart = Date.now();
            await uploadToSupabase(results, paytableId);
            const uploadTime = ((Date.now() - uploadStart) / 1000).toFixed(1);
            console.log(`Upload completed in ${uploadTime}s`);
        }
    }

    console.log('\n=== All calculations complete! ===');
}

main().catch(err => {
    console.error('Fatal error:', err);
    process.exit(1);
});
