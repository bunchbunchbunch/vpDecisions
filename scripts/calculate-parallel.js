// Parallel Video Poker Strategy Calculator
// Uses worker threads for parallel processing

import { Worker, isMainThread, parentPort, workerData } from 'worker_threads';
import { createClient } from '@supabase/supabase-js';
import { config } from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import os from 'os';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load environment variables
config({ path: join(__dirname, '..', '.env') });

// ============= WORKER CODE =============
if (!isMainThread) {
    // This code runs in worker threads
    const { hands, paytable, startIdx } = workerData;

    const suits = ['hearts', 'diamonds', 'clubs', 'spades'];
    const ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];
    const rankValues = { '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9, '10': 10, 'J': 11, 'Q': 12, 'K': 13, 'A': 14 };

    function isFlush(cards) {
        if (cards.length !== 5) return false;
        return cards.every(c => c.suit === cards[0].suit);
    }

    function isStraight(cards) {
        if (cards.length !== 5) return false;
        const values = cards.map(c => rankValues[c.rank]).sort((a, b) => a - b);
        let isRegular = true;
        for (let i = 1; i < values.length; i++) {
            if (values[i] !== values[i-1] + 1) { isRegular = false; break; }
        }
        const isWheel = values[0] === 2 && values[1] === 3 && values[2] === 4 && values[3] === 5 && values[4] === 14;
        return isRegular || isWheel;
    }

    function isRoyalFlush(cards) {
        if (!isFlush(cards) || cards.length !== 5) return false;
        const cardRanks = cards.map(c => c.rank).sort();
        return cardRanks.join(',') === '10,A,J,K,Q';
    }

    function getRankCounts(cards) {
        const counts = {};
        cards.forEach(c => { counts[c.rank] = (counts[c.rank] || 0) + 1; });
        return counts;
    }

    function classifyFinalHand(cards, gameType) {
        if (cards.length !== 5) return 'nothing';
        if (isRoyalFlush(cards)) return 'royalFlush';
        if (isFlush(cards) && isStraight(cards)) return 'straightFlush';

        const counts = getRankCounts(cards);
        const values = Object.values(counts).sort((a, b) => b - a);

        if (values[0] === 4) {
            const quadRank = Object.keys(counts).find(r => counts[r] === 4);
            if (gameType === 'double-double-bonus') {
                const kicker = Object.keys(counts).find(r => counts[r] === 1);
                const kickerIsLow = ['A', '2', '3', '4'].includes(kicker);
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

        if (values[0] === 3 && values[1] === 2) return 'fullHouse';
        if (isFlush(cards)) return 'flush';
        if (isStraight(cards)) return 'straight';
        if (values[0] === 3) return 'threeOfAKind';
        if (values[0] === 2 && values[1] === 2) return 'twoPair';
        if (values[0] === 2) {
            const pairRank = Object.keys(counts).find(r => counts[r] === 2);
            if (['J', 'Q', 'K', 'A'].includes(pairRank)) return 'jacksOrBetter';
        }
        return 'nothing';
    }

    function getPayout(handType, pays) {
        return pays[handType] || 0;
    }

    // Optimized: iterate combinations without storing all in memory
    function calculateHoldEV(hand, holdMask, gameType, pays) {
        const heldCards = [];
        for (let i = 0; i < 5; i++) {
            if (holdMask & (1 << i)) heldCards.push(hand[i]);
        }

        const numToDraw = 5 - heldCards.length;

        // Build remaining deck
        const deck = [];
        for (const suit of suits) {
            for (const rank of ranks) {
                if (!hand.some(c => c.rank === rank && c.suit === suit)) {
                    deck.push({ rank, suit });
                }
            }
        }

        if (numToDraw === 0) {
            return getPayout(classifyFinalHand(heldCards, gameType), pays);
        }

        // For small draws, iterate inline
        let totalPayout = 0;
        let count = 0;

        if (numToDraw === 1) {
            for (let i = 0; i < deck.length; i++) {
                const final = [...heldCards, deck[i]];
                totalPayout += getPayout(classifyFinalHand(final, gameType), pays);
                count++;
            }
        } else if (numToDraw === 2) {
            for (let i = 0; i < deck.length - 1; i++) {
                for (let j = i + 1; j < deck.length; j++) {
                    const final = [...heldCards, deck[i], deck[j]];
                    totalPayout += getPayout(classifyFinalHand(final, gameType), pays);
                    count++;
                }
            }
        } else if (numToDraw === 3) {
            for (let i = 0; i < deck.length - 2; i++) {
                for (let j = i + 1; j < deck.length - 1; j++) {
                    for (let k = j + 1; k < deck.length; k++) {
                        const final = [...heldCards, deck[i], deck[j], deck[k]];
                        totalPayout += getPayout(classifyFinalHand(final, gameType), pays);
                        count++;
                    }
                }
            }
        } else if (numToDraw === 4) {
            for (let i = 0; i < deck.length - 3; i++) {
                for (let j = i + 1; j < deck.length - 2; j++) {
                    for (let k = j + 1; k < deck.length - 1; k++) {
                        for (let l = k + 1; l < deck.length; l++) {
                            const final = [...heldCards, deck[i], deck[j], deck[k], deck[l]];
                            totalPayout += getPayout(classifyFinalHand(final, gameType), pays);
                            count++;
                        }
                    }
                }
            }
        } else { // numToDraw === 5
            for (let i = 0; i < deck.length - 4; i++) {
                for (let j = i + 1; j < deck.length - 3; j++) {
                    for (let k = j + 1; k < deck.length - 2; k++) {
                        for (let l = k + 1; l < deck.length - 1; l++) {
                            for (let m = l + 1; m < deck.length; m++) {
                                const final = [deck[i], deck[j], deck[k], deck[l], deck[m]];
                                totalPayout += getPayout(classifyFinalHand(final, gameType), pays);
                                count++;
                            }
                        }
                    }
                }
            }
        }

        return totalPayout / count;
    }

    function analyzeHand(hand, gameType, pays) {
        const holdEvs = {};
        let bestHold = 0;
        let bestEv = -Infinity;

        for (let holdMask = 0; holdMask < 32; holdMask++) {
            const ev = calculateHoldEV(hand, holdMask, gameType, pays);
            holdEvs[holdMask] = parseFloat(ev.toFixed(6));
            if (ev > bestEv) {
                bestEv = ev;
                bestHold = holdMask;
            }
        }

        return { holdEvs, bestHold, bestEv: parseFloat(bestEv.toFixed(6)) };
    }

    // Process assigned hands in batches for incremental upload
    const BATCH_SIZE = 100;
    let batch = [];

    for (let i = 0; i < hands.length; i++) {
        const { key, hand } = hands[i];
        const analysis = analyzeHand(hand, paytable.gameType, paytable.pays);

        batch.push({
            paytable_id: paytable.id,
            hand_key: key,
            best_hold: analysis.bestHold,
            best_ev: analysis.bestEv,
            hold_evs: analysis.holdEvs
        });

        // Send batch every BATCH_SIZE hands
        if (batch.length >= BATCH_SIZE) {
            parentPort.postMessage({ type: 'batch', results: batch, progress: i + 1, total: hands.length });
            batch = [];
        }
    }

    // Send any remaining results
    if (batch.length > 0) {
        parentPort.postMessage({ type: 'batch', results: batch, progress: hands.length, total: hands.length });
    }

    parentPort.postMessage({ type: 'done' });
}

// ============= MAIN THREAD CODE =============
if (isMainThread) {
    const SUPABASE_URL = process.env.SUPABASE_URL;
    const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    const PAYTABLES = {
        'jacks-or-better-9-6': {
            id: 'jacks-or-better-9-6',
            name: 'Jacks or Better 9/6',
            gameType: 'jacks-or-better',
            pays: { royalFlush: 800, straightFlush: 50, fourOfAKind: 25, fullHouse: 9, flush: 6, straight: 4, threeOfAKind: 3, twoPair: 2, jacksOrBetter: 1 }
        }
    };

    const suits = ['hearts', 'diamonds', 'clubs', 'spades'];
    const ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];
    const rankValues = { '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9, '10': 10, 'J': 11, 'Q': 12, 'K': 13, 'A': 14 };
    const rankDisplay = { '2': '2', '3': '3', '4': '4', '5': '5', '6': '6', '7': '7', '8': '8', '9': '9', '10': 'T', 'J': 'J', 'Q': 'Q', 'K': 'K', 'A': 'A' };

    function indexToCard(index) {
        return { rank: ranks[index % 13], suit: suits[Math.floor(index / 13)] };
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
        return sorted.map(card => rankDisplay[card.rank] + suitMap[card.suit]).join('');
    }

    function generateCanonicalHands() {
        console.log('Generating canonical hands...');
        const hands = new Map();
        let processed = 0;

        for (let c1 = 0; c1 < 48; c1++) {
            for (let c2 = c1 + 1; c2 < 49; c2++) {
                for (let c3 = c2 + 1; c3 < 50; c3++) {
                    for (let c4 = c3 + 1; c4 < 51; c4++) {
                        for (let c5 = c4 + 1; c5 < 52; c5++) {
                            const hand = [indexToCard(c1), indexToCard(c2), indexToCard(c3), indexToCard(c4), indexToCard(c5)];
                            const key = handToCanonicalKey(hand);
                            if (!hands.has(key)) {
                                hands.set(key, hand);
                            }
                            processed++;
                            if (processed % 500000 === 0) {
                                console.log(`  ${processed.toLocaleString()} processed, ${hands.size.toLocaleString()} unique`);
                            }
                        }
                    }
                }
            }
        }

        console.log(`Found ${hands.size.toLocaleString()} canonical hands`);
        return hands;
    }

    async function uploadToSupabase(results) {
        console.log(`Uploading ${results.length.toLocaleString()} hands to Supabase...`);

        const batchSize = 500;
        let uploaded = 0;

        for (let i = 0; i < results.length; i += batchSize) {
            const batch = results.slice(i, i + batchSize);
            const { error } = await supabase
                .from('strategy')
                .upsert(batch, { onConflict: 'paytable_id,hand_key' });

            if (error) {
                console.error('Upload error:', error.message);
                throw error;
            }

            uploaded += batch.length;
            if (uploaded % 5000 === 0 || uploaded === results.length) {
                console.log(`  Uploaded ${uploaded.toLocaleString()} / ${results.length.toLocaleString()}`);
            }
        }
    }

    async function main() {
        const paytableId = process.argv[2] || 'jacks-or-better-9-6';
        const paytable = PAYTABLES[paytableId];

        if (!paytable) {
            console.error('Unknown paytable:', paytableId);
            process.exit(1);
        }

        console.log('=== Parallel Strategy Calculator ===\n');
        console.log(`Paytable: ${paytable.name}`);

        // Generate canonical hands
        const canonicalHands = generateCanonicalHands();

        // Convert to array for splitting
        const handsArray = Array.from(canonicalHands.entries()).map(([key, hand]) => ({ key, hand }));

        // Determine number of workers
        const numCPUs = os.cpus().length;
        const numWorkers = Math.min(numCPUs, 8);
        console.log(`\nUsing ${numWorkers} worker threads`);

        // Split hands among workers
        const chunkSize = Math.ceil(handsArray.length / numWorkers);
        const workerPromises = [];
        const progressTracker = new Array(numWorkers).fill(0);

        const startTime = Date.now();

        // Track uploads with proper async handling
        let totalUploaded = 0;
        let totalCalculated = 0;
        const pendingUploads = [];

        async function uploadBatch(batch) {
            const { error } = await supabase
                .from('strategy')
                .upsert(batch, { onConflict: 'paytable_id,hand_key' });

            if (error) {
                console.error('\nUpload error:', error.message);
                return 0;
            }
            return batch.length;
        }

        for (let i = 0; i < numWorkers; i++) {
            const start = i * chunkSize;
            const end = Math.min(start + chunkSize, handsArray.length);
            const chunk = handsArray.slice(start, end);

            const workerPromise = new Promise((resolve, reject) => {
                const worker = new Worker(__filename, {
                    workerData: { hands: chunk, paytable, startIdx: start }
                });

                worker.on('message', async (msg) => {
                    if (msg.type === 'batch') {
                        // Update progress
                        progressTracker[i] = msg.progress;
                        totalCalculated = progressTracker.reduce((a, b) => a + b, 0);

                        // Start upload (don't await - let it run in parallel)
                        const uploadPromise = uploadBatch(msg.results).then(count => {
                            totalUploaded += count;
                            console.log(`  Calc: ${totalCalculated.toLocaleString()}/${handsArray.length.toLocaleString()} | DB: ${totalUploaded.toLocaleString()}`);
                        });
                        pendingUploads.push(uploadPromise);
                    } else if (msg.type === 'done') {
                        resolve();
                    }
                });

                worker.on('error', reject);
                worker.on('exit', (code) => {
                    if (code !== 0) reject(new Error(`Worker stopped with exit code ${code}`));
                });
            });

            workerPromises.push(workerPromise);
        }

        // Wait for all workers to finish calculating
        await Promise.all(workerPromises);
        console.log('\nCalculations complete, waiting for uploads...');

        // Wait for all uploads to complete
        await Promise.all(pendingUploads);

        const calcTime = ((Date.now() - startTime) / 1000).toFixed(1);
        console.log(`\nCompleted in ${calcTime}s - ${totalUploaded.toLocaleString()} hands uploaded`);

        console.log('\n=== Done! ===');
    }

    main().catch(err => {
        console.error('Error:', err);
        process.exit(1);
    });
}
