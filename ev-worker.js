// Video Poker EV Calculation Web Worker
// Calculates expected values for all 32 hold patterns in background

// Paytable definitions
const PAYTABLES = {
    'jacks-or-better-9-6': {
        name: 'Jacks or Better 9/6',
        payback: 0.9954,
        gameType: 'jacks-or-better',
        pays: {
            royalFlush: 800,
            straightFlush: 50,
            fourOfAKind: 25,
            fullHouse: 9,
            flush: 6,
            straight: 4,
            threeOfAKind: 3,
            twoPair: 2,
            jacksOrBetter: 1
        }
    },
    'jacks-or-better-8-5': {
        name: 'Jacks or Better 8/5',
        payback: 0.9737,
        gameType: 'jacks-or-better',
        pays: {
            royalFlush: 800,
            straightFlush: 50,
            fourOfAKind: 25,
            fullHouse: 8,
            flush: 5,
            straight: 4,
            threeOfAKind: 3,
            twoPair: 2,
            jacksOrBetter: 1
        }
    },
    'jacks-or-better-7-5': {
        name: 'Jacks or Better 7/5',
        payback: 0.9615,
        gameType: 'jacks-or-better',
        pays: {
            royalFlush: 800,
            straightFlush: 50,
            fourOfAKind: 25,
            fullHouse: 7,
            flush: 5,
            straight: 4,
            threeOfAKind: 3,
            twoPair: 2,
            jacksOrBetter: 1
        }
    },
    'bonus-poker-8-5': {
        name: 'Bonus Poker 8/5',
        payback: 0.9917,
        gameType: 'bonus-poker',
        pays: {
            royalFlush: 800,
            straightFlush: 50,
            fourAces: 80,
            fourTwosThruFours: 40,
            fourFivesThruKings: 25,
            fullHouse: 8,
            flush: 5,
            straight: 4,
            threeOfAKind: 3,
            twoPair: 2,
            jacksOrBetter: 1
        }
    },
    'bonus-poker-7-5': {
        name: 'Bonus Poker 7/5',
        payback: 0.9801,
        gameType: 'bonus-poker',
        pays: {
            royalFlush: 800,
            straightFlush: 50,
            fourAces: 80,
            fourTwosThruFours: 40,
            fourFivesThruKings: 25,
            fullHouse: 7,
            flush: 5,
            straight: 4,
            threeOfAKind: 3,
            twoPair: 2,
            jacksOrBetter: 1
        }
    },
    'double-bonus-10-7': {
        name: 'Double Bonus 10/7',
        payback: 1.0017,
        gameType: 'double-bonus',
        pays: {
            royalFlush: 800,
            straightFlush: 50,
            fourAces: 160,
            fourTwosThruFours: 80,
            fourFivesThruKings: 50,
            fullHouse: 10,
            flush: 7,
            straight: 5,
            threeOfAKind: 3,
            twoPair: 1,
            jacksOrBetter: 1
        }
    },
    'double-bonus-9-7': {
        name: 'Double Bonus 9/7',
        payback: 0.9911,
        gameType: 'double-bonus',
        pays: {
            royalFlush: 800,
            straightFlush: 50,
            fourAces: 160,
            fourTwosThruFours: 80,
            fourFivesThruKings: 50,
            fullHouse: 9,
            flush: 7,
            straight: 5,
            threeOfAKind: 3,
            twoPair: 1,
            jacksOrBetter: 1
        }
    },
    'double-bonus-9-6': {
        name: 'Double Bonus 9/6',
        payback: 0.9781,
        gameType: 'double-bonus',
        pays: {
            royalFlush: 800,
            straightFlush: 50,
            fourAces: 160,
            fourTwosThruFours: 80,
            fourFivesThruKings: 50,
            fullHouse: 9,
            flush: 6,
            straight: 5,
            threeOfAKind: 3,
            twoPair: 1,
            jacksOrBetter: 1
        }
    },
    'double-double-bonus-9-6': {
        name: 'Double Double Bonus 9/6',
        payback: 0.9898,
        gameType: 'double-double-bonus',
        pays: {
            royalFlush: 800,
            straightFlush: 50,
            fourAcesWithKicker: 400,
            fourAces: 160,
            fourTwosThruFoursWithKicker: 160,
            fourTwosThruFours: 80,
            fourFivesThruKings: 50,
            fullHouse: 9,
            flush: 6,
            straight: 4,
            threeOfAKind: 3,
            twoPair: 1,
            jacksOrBetter: 1
        }
    },
    'double-double-bonus-9-5': {
        name: 'Double Double Bonus 9/5',
        payback: 0.9787,
        gameType: 'double-double-bonus',
        pays: {
            royalFlush: 800,
            straightFlush: 50,
            fourAcesWithKicker: 400,
            fourAces: 160,
            fourTwosThruFoursWithKicker: 160,
            fourTwosThruFours: 80,
            fourFivesThruKings: 50,
            fullHouse: 9,
            flush: 5,
            straight: 4,
            threeOfAKind: 3,
            twoPair: 1,
            jacksOrBetter: 1
        }
    },
    'double-double-bonus-8-5': {
        name: 'Double Double Bonus 8/5',
        payback: 0.9679,
        gameType: 'double-double-bonus',
        pays: {
            royalFlush: 800,
            straightFlush: 50,
            fourAcesWithKicker: 400,
            fourAces: 160,
            fourTwosThruFoursWithKicker: 160,
            fourTwosThruFours: 80,
            fourFivesThruKings: 50,
            fullHouse: 8,
            flush: 5,
            straight: 4,
            threeOfAKind: 3,
            twoPair: 1,
            jacksOrBetter: 1
        }
    }
};

// Card constants
const suits = ['hearts', 'diamonds', 'clubs', 'spades'];
const ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];
const rankValues = {
    '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9,
    '10': 10, 'J': 11, 'Q': 12, 'K': 13, 'A': 14
};

// Helper functions for hand evaluation
function isFlush(cards) {
    if (cards.length !== 5) return false;
    return cards.every(c => c.suit === cards[0].suit);
}

function isStraight(cards) {
    if (cards.length !== 5) return false;
    const values = cards.map(c => rankValues[c.rank]).sort((a, b) => a - b);

    let isRegularStraight = true;
    for (let i = 1; i < values.length; i++) {
        if (values[i] !== values[i-1] + 1) {
            isRegularStraight = false;
            break;
        }
    }

    const isWheelStraight =
        values[0] === 2 && values[1] === 3 &&
        values[2] === 4 && values[3] === 5 && values[4] === 14;

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
    cards.forEach(card => {
        counts[card.rank] = (counts[card.rank] || 0) + 1;
    });
    return counts;
}

function getPairs(cards) {
    const counts = getRankCounts(cards);
    return Object.entries(counts)
        .filter(([rank, count]) => count === 2)
        .map(([rank]) => rank);
}

function getTrips(cards) {
    const counts = getRankCounts(cards);
    return Object.entries(counts)
        .filter(([rank, count]) => count === 3)
        .map(([rank]) => rank);
}

function getQuads(cards) {
    const counts = getRankCounts(cards);
    return Object.entries(counts)
        .filter(([rank, count]) => count === 4)
        .map(([rank]) => rank);
}

// Classify a final 5-card hand for payout lookup
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

            if (quadRank === 'A' && kickerIsLow) {
                return 'fourAcesWithKicker';
            }
            if (['2', '3', '4'].includes(quadRank) && kickerIsLow) {
                return 'fourTwosThruFoursWithKicker';
            }
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
    if (pairs.length === 1 && ['J', 'Q', 'K', 'A'].includes(pairs[0])) {
        return 'jacksOrBetter';
    }

    return 'nothing';
}

function getPayout(handType, paytable) {
    return paytable.pays[handType] || 0;
}

// Generate all k-combinations (iterative for performance)
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
        for (let j = i + 1; j < k; j++) {
            indices[j] = indices[j-1] + 1;
        }
    }

    return results;
}

// Calculate EV for a specific hold pattern
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
function generateHoldPatterns() {
    const patterns = [];
    for (let i = 0; i < 32; i++) {
        const pattern = [];
        for (let j = 0; j < 5; j++) {
            if (i & (1 << j)) {
                pattern.push(j);
            }
        }
        patterns.push(pattern);
    }
    return patterns;
}

// Describe what's being held
function describeHold(holdIndices, hand) {
    if (holdIndices.length === 0) return 'Discard all';
    if (holdIndices.length === 5) return 'Hold all 5';

    const heldCards = holdIndices.map(i => hand[i]);
    const counts = getRankCounts(heldCards);
    const pairs = getPairs(heldCards);
    const trips = getTrips(heldCards);
    const allSameSuit = heldCards.length > 1 && heldCards.every(c => c.suit === heldCards[0].suit);

    if (trips.length > 0) {
        return `Three ${trips[0]}s`;
    }

    if (pairs.length === 2) {
        return `Two Pair: ${pairs[0]}s and ${pairs[1]}s`;
    }

    if (pairs.length === 1) {
        return `Pair of ${pairs[0]}s`;
    }

    if (allSameSuit && heldCards.length >= 3) {
        const sortedRanks = heldCards.map(c => c.rank).sort((a, b) => rankValues[a] - rankValues[b]);
        const royalRanks = ['10', 'J', 'Q', 'K', 'A'];
        const isRoyalDraw = sortedRanks.every(r => royalRanks.includes(r));

        if (isRoyalDraw) {
            return `${heldCards.length} to a Royal Flush`;
        }

        const values = heldCards.map(c => rankValues[c.rank]).sort((a, b) => a - b);
        const range = values[values.length - 1] - values[0];
        if (range <= 4) {
            return `${heldCards.length} to a Straight Flush`;
        }

        return `${heldCards.length} to a Flush`;
    }

    if (heldCards.length === 4 && !allSameSuit) {
        const values = heldCards.map(c => rankValues[c.rank]).sort((a, b) => a - b);
        const range = values[3] - values[0];
        if (range <= 4) {
            return '4 to a Straight';
        }
    }

    const highCards = heldCards.filter(c => ['J', 'Q', 'K', 'A'].includes(c.rank));
    if (highCards.length === heldCards.length && heldCards.length <= 2) {
        if (heldCards.length === 1) {
            return `High card: ${heldCards[0].rank}`;
        }
        return `High cards: ${heldCards.map(c => c.rank).join(', ')}`;
    }

    return `Hold ${heldCards.length} card${heldCards.length > 1 ? 's' : ''}`;
}

// Analyze the hand and return all plays sorted by EV
function analyzeHand(hand, paytable) {
    const patterns = generateHoldPatterns();
    const results = [];

    for (const pattern of patterns) {
        const ev = calculateHoldEV(hand, pattern, paytable);
        const description = describeHold(pattern, hand);

        results.push({
            holdIndices: pattern,
            heldCards: pattern.map(i => hand[i]),
            ev: ev,
            description: description
        });
    }

    results.sort((a, b) => b.ev - a.ev);
    return results;
}

// Handle messages from main thread
self.onmessage = function(e) {
    const { type, hand, paytableId, requestId } = e.data;

    if (type === 'analyze') {
        const paytable = PAYTABLES[paytableId];
        if (!paytable) {
            self.postMessage({
                type: 'error',
                error: 'Unknown paytable: ' + paytableId,
                requestId
            });
            return;
        }

        const results = analyzeHand(hand, paytable);

        self.postMessage({
            type: 'result',
            results: results,
            bestPlay: results[0],
            requestId
        });
    }
};
