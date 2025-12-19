// Pre-calculation Worker for Video Poker Strategy Database
// Generates all 2,598,960 possible hands and calculates optimal plays

// Paytable definitions (same as ev-worker.js)
const PAYTABLES = {
    'jacks-or-better-9-6': {
        name: 'Jacks or Better 9/6', gameType: 'jacks-or-better',
        pays: { royalFlush: 800, straightFlush: 50, fourOfAKind: 25, fullHouse: 9, flush: 6, straight: 4, threeOfAKind: 3, twoPair: 2, jacksOrBetter: 1 }
    },
    'jacks-or-better-8-5': {
        name: 'Jacks or Better 8/5', gameType: 'jacks-or-better',
        pays: { royalFlush: 800, straightFlush: 50, fourOfAKind: 25, fullHouse: 8, flush: 5, straight: 4, threeOfAKind: 3, twoPair: 2, jacksOrBetter: 1 }
    },
    'jacks-or-better-7-5': {
        name: 'Jacks or Better 7/5', gameType: 'jacks-or-better',
        pays: { royalFlush: 800, straightFlush: 50, fourOfAKind: 25, fullHouse: 7, flush: 5, straight: 4, threeOfAKind: 3, twoPair: 2, jacksOrBetter: 1 }
    },
    'bonus-poker-8-5': {
        name: 'Bonus Poker 8/5', gameType: 'bonus-poker',
        pays: { royalFlush: 800, straightFlush: 50, fourAces: 80, fourTwosThruFours: 40, fourFivesThruKings: 25, fullHouse: 8, flush: 5, straight: 4, threeOfAKind: 3, twoPair: 2, jacksOrBetter: 1 }
    },
    'bonus-poker-7-5': {
        name: 'Bonus Poker 7/5', gameType: 'bonus-poker',
        pays: { royalFlush: 800, straightFlush: 50, fourAces: 80, fourTwosThruFours: 40, fourFivesThruKings: 25, fullHouse: 7, flush: 5, straight: 4, threeOfAKind: 3, twoPair: 2, jacksOrBetter: 1 }
    },
    'double-bonus-10-7': {
        name: 'Double Bonus 10/7', gameType: 'double-bonus',
        pays: { royalFlush: 800, straightFlush: 50, fourAces: 160, fourTwosThruFours: 80, fourFivesThruKings: 50, fullHouse: 10, flush: 7, straight: 5, threeOfAKind: 3, twoPair: 1, jacksOrBetter: 1 }
    },
    'double-bonus-9-7': {
        name: 'Double Bonus 9/7', gameType: 'double-bonus',
        pays: { royalFlush: 800, straightFlush: 50, fourAces: 160, fourTwosThruFours: 80, fourFivesThruKings: 50, fullHouse: 9, flush: 7, straight: 5, threeOfAKind: 3, twoPair: 1, jacksOrBetter: 1 }
    },
    'double-bonus-9-6': {
        name: 'Double Bonus 9/6', gameType: 'double-bonus',
        pays: { royalFlush: 800, straightFlush: 50, fourAces: 160, fourTwosThruFours: 80, fourFivesThruKings: 50, fullHouse: 9, flush: 6, straight: 5, threeOfAKind: 3, twoPair: 1, jacksOrBetter: 1 }
    },
    'double-double-bonus-9-6': {
        name: 'Double Double Bonus 9/6', gameType: 'double-double-bonus',
        pays: { royalFlush: 800, straightFlush: 50, fourAcesWithKicker: 400, fourAces: 160, fourTwosThruFoursWithKicker: 160, fourTwosThruFours: 80, fourFivesThruKings: 50, fullHouse: 9, flush: 6, straight: 4, threeOfAKind: 3, twoPair: 1, jacksOrBetter: 1 }
    },
    'double-double-bonus-9-5': {
        name: 'Double Double Bonus 9/5', gameType: 'double-double-bonus',
        pays: { royalFlush: 800, straightFlush: 50, fourAcesWithKicker: 400, fourAces: 160, fourTwosThruFoursWithKicker: 160, fourTwosThruFours: 80, fourFivesThruKings: 50, fullHouse: 9, flush: 5, straight: 4, threeOfAKind: 3, twoPair: 1, jacksOrBetter: 1 }
    },
    'double-double-bonus-8-5': {
        name: 'Double Double Bonus 8/5', gameType: 'double-double-bonus',
        pays: { royalFlush: 800, straightFlush: 50, fourAcesWithKicker: 400, fourAces: 160, fourTwosThruFoursWithKicker: 160, fourTwosThruFours: 80, fourFivesThruKings: 50, fullHouse: 8, flush: 5, straight: 4, threeOfAKind: 3, twoPair: 1, jacksOrBetter: 1 }
    }
};

const suits = ['hearts', 'diamonds', 'clubs', 'spades'];
const ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];
const rankValues = { '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9, '10': 10, 'J': 11, 'Q': 12, 'K': 13, 'A': 14 };

// Convert card index (0-51) to card object
function indexToCard(index) {
    return { rank: ranks[index % 13], suit: suits[Math.floor(index / 13)] };
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

// Optimized combination generator
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
function calculateHoldEV(hand, holdIndices, remainingDeck, paytable) {
    const heldCards = holdIndices.map(i => hand[i]);
    const numToDraw = 5 - heldCards.length;

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

// Analyze a hand and return top 5 plays
function analyzeHand(handIndices, paytable) {
    const hand = handIndices.map(indexToCard);

    // Build remaining deck
    const handSet = new Set(handIndices);
    const remainingDeck = [];
    for (let i = 0; i < 52; i++) {
        if (!handSet.has(i)) {
            remainingDeck.push(indexToCard(i));
        }
    }

    const results = [];
    for (const pattern of HOLD_PATTERNS) {
        const ev = calculateHoldEV(hand, pattern, remainingDeck, paytable);
        results.push({ hold: pattern, ev: ev });
    }

    results.sort((a, b) => b.ev - a.ev);
    return results.slice(0, 5); // Return top 5 plays
}

// Generate all possible 5-card hands
function* generateAllHands() {
    for (let c1 = 0; c1 < 48; c1++) {
        for (let c2 = c1 + 1; c2 < 49; c2++) {
            for (let c3 = c2 + 1; c3 < 50; c3++) {
                for (let c4 = c3 + 1; c4 < 51; c4++) {
                    for (let c5 = c4 + 1; c5 < 52; c5++) {
                        yield [c1, c2, c3, c4, c5];
                    }
                }
            }
        }
    }
}

// Total number of hands: C(52,5) = 2,598,960
const TOTAL_HANDS = 2598960;

// Message handler
self.onmessage = function(e) {
    const { type, paytableId, startIndex = 0, batchSize = 1000 } = e.data;

    if (type === 'calculate') {
        const paytable = PAYTABLES[paytableId];
        if (!paytable) {
            self.postMessage({ type: 'error', error: 'Unknown paytable: ' + paytableId });
            return;
        }

        const results = [];
        let count = 0;
        let currentIndex = 0;

        for (const handIndices of generateAllHands()) {
            // Skip to start index
            if (currentIndex < startIndex) {
                currentIndex++;
                continue;
            }

            // Analyze hand
            const analysis = analyzeHand(handIndices, paytable);

            // Create compact key (sorted indices as string)
            const key = handIndices.join(',');

            // Store top 5 plays with EVs
            results.push({
                key: key,
                plays: analysis.map(p => ({ h: p.hold.reduce((acc, i) => acc | (1 << i), 0), e: p.ev }))
            });

            count++;
            currentIndex++;

            // Send batch when ready
            if (count >= batchSize) {
                self.postMessage({
                    type: 'batch',
                    results: results,
                    processed: currentIndex,
                    total: TOTAL_HANDS
                });
                return; // Main thread will request next batch
            }
        }

        // Send final batch
        self.postMessage({
            type: 'complete',
            results: results,
            processed: currentIndex,
            total: TOTAL_HANDS
        });
    }

    if (type === 'analyzeHand') {
        // Single hand analysis (for fallback when DB not available)
        const { hand, paytableId, requestId } = e.data;
        const paytable = PAYTABLES[paytableId];
        if (!paytable) {
            self.postMessage({ type: 'error', error: 'Unknown paytable', requestId });
            return;
        }

        // Convert hand objects to indices
        const handIndices = hand.map(card => {
            const suitIndex = suits.indexOf(card.suit);
            const rankIndex = ranks.indexOf(card.rank);
            return suitIndex * 13 + rankIndex;
        });

        const analysis = analyzeHand(handIndices, paytable);

        // Convert back to full format for compatibility
        const handCards = handIndices.map(indexToCard);
        const fullResults = analysis.map(p => ({
            holdIndices: HOLD_PATTERNS.find(pat => pat.reduce((acc, i) => acc | (1 << i), 0) === p.h) || [],
            heldCards: [],
            ev: p.ev,
            description: ''
        }));

        // Fill in held cards
        fullResults.forEach(r => {
            r.heldCards = r.holdIndices.map(i => handCards[i]);
        });

        self.postMessage({
            type: 'result',
            results: fullResults,
            requestId
        });
    }
};
