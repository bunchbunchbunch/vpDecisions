// Convert to CSV with standard video poker strategy descriptions
const fs = require('fs');
const csv = require('csv-parser');
const { createObjectCsvWriter } = require('csv-writer');

// Function to extract held cards based on bitmask
function getCardsHeld(handKey, holdMask) {
    const cards = [];
    for (let i = 0; i < handKey.length; i += 2) {
        cards.push(handKey.substring(i, i + 2));
    }

    const heldCards = [];
    for (let i = 0; i < 5; i++) {
        if (holdMask & (1 << i)) {
            heldCards.push(cards[i]);
        }
    }

    return heldCards.join('');
}

// Helper functions
function isHighCard(rank) {
    return ['J', 'Q', 'K', 'A'].includes(rank);
}

function countHighCards(ranks) {
    return ranks.filter(r => isHighCard(r)).length;
}

function countGaps(ranks) {
    const rankOrder = '23456789TJQKA';
    const positions = ranks.map(r => rankOrder.indexOf(r)).sort((a, b) => a - b);

    // Handle ace-low
    if (positions.includes(12) && positions.includes(0)) {
        const aceLowPositions = positions.map(p => p === 12 ? -1 : p).sort((a, b) => a - b);
        const aceLowGaps = (aceLowPositions[aceLowPositions.length - 1] - aceLowPositions[0]) - (aceLowPositions.length - 1);
        const aceHighGaps = (positions[positions.length - 1] - positions[0]) - (positions.length - 1);
        return Math.min(aceLowGaps, aceHighGaps);
    }

    return (positions[positions.length - 1] - positions[0]) - (positions.length - 1);
}

function isOutsideStraight(ranks) {
    const rankOrder = '23456789TJQKA';
    const positions = ranks.map(r => rankOrder.indexOf(r)).sort((a, b) => a - b);

    if (ranks.length === 4) {
        if (positions[3] - positions[0] === 3) {
            // Exclude J-Q-K-A (positions [9,10,11,12]) - can only complete with T
            if (positions[0] === 9 && positions[3] === 12) {
                return false;
            }
            return true;
        }
    }
    return false;
}

function isRoyalFlush(ranks, suits) {
    if (suits.length === 5 && suits.every(s => s === suits[0])) {
        const rankSet = new Set(ranks);
        return rankSet.has('T') && rankSet.has('J') && rankSet.has('Q') && rankSet.has('K') && rankSet.has('A');
    }
    return false;
}

function isStraightFlush(ranks, suits) {
    if (suits.length === 5 && suits.every(s => s === suits[0])) {
        const rankOrder = '23456789TJQKA';
        const positions = ranks.map(r => rankOrder.indexOf(r)).sort((a, b) => a - b);
        // Normal straight flush
        if (positions[4] - positions[0] === 4) return true;
        // Ace-low straight flush (A-2-3-4-5)
        if (positions[0] === 0 && positions[1] === 1 && positions[2] === 2 && positions[3] === 3 && positions[4] === 12) {
            return true;
        }
    }
    return false;
}

function isStraight(ranks) {
    const rankOrder = '23456789TJQKA';
    const positions = ranks.map(r => rankOrder.indexOf(r)).sort((a, b) => a - b);
    // Normal straight (e.g., 5-6-7-8-9)
    if (positions[4] - positions[0] === 4) return true;
    // Ace-low straight (A-2-3-4-5): positions are [0,1,2,3,12] when sorted
    if (positions[0] === 0 && positions[1] === 1 && positions[2] === 2 && positions[3] === 3 && positions[4] === 12) {
        return true;
    }
    return false;
}

function isRoyalDraw(ranks, suits, numCards) {
    if (suits.every(s => s === suits[0])) {
        const royalRanks = ['T', 'J', 'Q', 'K', 'A'];
        return ranks.every(r => royalRanks.includes(r));
    }
    return false;
}

// Get standard description
function getStandardDescription(cardsHeld) {
    if (!cardsHeld || cardsHeld.length === 0) {
        return 'Garbage, discard everything';
    }

    const cards = [];
    for (let i = 0; i < cardsHeld.length; i += 2) {
        cards.push(cardsHeld.substring(i, i + 2));
    }

    const ranks = cards.map(c => c[0]);
    const suits = cards.map(c => c[1]);
    const allSameSuit = suits.every(s => s === suits[0]);
    const highCardCount = countHighCards(ranks);
    const gaps = countGaps(ranks);

    // Count rank occurrences
    const rankCounts = {};
    ranks.forEach(r => rankCounts[r] = (rankCounts[r] || 0) + 1);
    const rankCountEntries = Object.entries(rankCounts).sort((a, b) => b[1] - a[1]);

    // Check for made hands in proper order
    // 4 of a kind (highest priority, can be 4 or 5 cards)
    if (rankCountEntries[0][1] === 4) {
        return 'Dealt four of a kind';
    }

    // 5-card special hands (must check before pairs/trips since flush/straight beat those)
    if (cards.length === 5) {
        if (isRoyalFlush(ranks, suits)) return 'Dealt royal flush';
        if (isStraightFlush(ranks, suits)) return 'Dealt straight flush';

        // Full house (must have exactly 2 different ranks with counts 3 and 2)
        if (rankCountEntries.length === 2 && rankCountEntries[0][1] === 3 && rankCountEntries[1][1] === 2) {
            return 'Dealt full house';
        }

        if (allSameSuit) return 'Dealt flush';
        if (isStraight(ranks)) return 'Dealt straight';
    }

    // 3 of a kind
    if (rankCountEntries[0][1] === 3) {
        return '3 of a kind';
    }

    // Two pair (must have at least 2 different ranks, both with count 2)
    if (rankCountEntries.length >= 2 && rankCountEntries[0][1] === 2 && rankCountEntries[1][1] === 2) {
        return 'Two pair';
    }

    // Pair (high or low)
    if (rankCountEntries[0][1] === 2) {
        const pairRank = rankCountEntries[0][0];
        if (['J', 'Q', 'K', 'A'].includes(pairRank)) return 'High pair';
        return 'Low pair';
    }

    // 4 cards
    if (cards.length === 4) {
        // 4 to a royal flush
        if (isRoyalDraw(ranks, suits, 4)) {
            return '4 to a royal flush';
        }

        // 4 to a straight flush
        if (allSameSuit && gaps <= 1) {
            return '4 to a straight flush';
        }

        // 4 to a flush
        if (allSameSuit) {
            return '4 to a flush';
        }

        // Check specific unsuited 4-card straight patterns
        const rankSet = new Set(ranks);

        // Unsuited TJQK (check for specific ranks)
        if (!allSameSuit && rankSet.has('T') && rankSet.has('J') && rankSet.has('Q') && rankSet.has('K')) {
            return 'Unsuited TJQK';
        }

        // J-Q-K-A unsuited (inside straight needing T, 4 high cards)
        if (!allSameSuit && rankSet.has('J') && rankSet.has('Q') && rankSet.has('K') && rankSet.has('A') && rankSet.size === 4) {
            return '4 to an inside straight, 4 high cards';
        }

        // 4 to outside straight (must have 0 gaps and 0-2 high cards)
        if (gaps === 0 && isOutsideStraight(ranks) && highCardCount <= 2) {
            return '4 to an outside straight with 0-2 high cards';
        }

        // 4 to inside straight with high cards (must have exactly 1 gap)
        if (gaps === 1) {
            if (highCardCount === 4) return '4 to an inside straight, 4 high cards';
            if (highCardCount === 3) return '4 to an inside straight, 3 high cards';
        }
    }

    // 3 cards
    if (cards.length === 3) {
        // 3 to a royal flush
        if (isRoyalDraw(ranks, suits, 3)) {
            return '3 to a royal flush';
        }

        // 3 to a straight flush (types 1, 2, 3)
        if (allSameSuit) {
            // Check for ace-low patterns (A with any of 2,3,4,5)
            const hasAce = ranks.includes('A');
            const hasAceLowCard = ranks.some(r => ['2', '3', '4', '5'].includes(r));
            const isAceLow = hasAce && hasAceLowCard;

            // Type 1: high cards >= gaps
            if (highCardCount >= gaps) {
                return '3 to a straight flush (type 1)';
            }
            // Type 2: (1 gap, 0 high) OR (2 gaps, 1 high) OR ace low OR 2-3-4
            if ((gaps === 1 && highCardCount === 0) ||
                (gaps === 2 && highCardCount === 1) ||
                isAceLow ||
                (ranks.includes('2') && ranks.includes('3') && ranks.includes('4'))) {
                return '3 to a straight flush (type 2)';
            }
            // Type 3: 2 gaps, 0 high
            if (gaps === 2 && highCardCount === 0) {
                return '3 to a straight flush (type 3)';
            }
        }

        // Unsuited JQK
        if (!allSameSuit && highCardCount === 3) {
            const rankSet = new Set(ranks);
            if (rankSet.has('J') && rankSet.has('Q') && rankSet.has('K')) {
                return 'Unsuited JQK';
            }
        }
    }

    // 2 cards
    if (cards.length === 2) {
        const rankSet = new Set(ranks);

        // Suited pairs
        if (allSameSuit) {
            if (rankSet.has('Q') && rankSet.has('J')) return 'Suited QJ';
            if ((rankSet.has('K') && rankSet.has('Q')) || (rankSet.has('K') && rankSet.has('J'))) {
                return 'Suited KQ or KJ';
            }
            if ((rankSet.has('A') && rankSet.has('K')) ||
                (rankSet.has('A') && rankSet.has('Q')) ||
                (rankSet.has('A') && rankSet.has('J'))) {
                return 'Suited AK, AQ, or AJ';
            }
            if (rankSet.has('T') && rankSet.has('J')) return 'Suited TJ';
            if (rankSet.has('T') && rankSet.has('Q')) return 'Suited TQ';
            if (rankSet.has('T') && rankSet.has('K')) return 'Suited TK';
        }

        // Unsuited pairs
        if (!allSameSuit && highCardCount === 2) {
            if (rankSet.has('J') && rankSet.has('Q')) return 'Unsuited JQ';

            // 2 unsuited high cards, king highest
            if (rankSet.has('K') && !rankSet.has('A')) {
                return '2 unsuited high cards king highest';
            }

            // 2 unsuited high cards, ace highest
            if (rankSet.has('A')) {
                return '2 unsuited high cards ace highest';
            }
        }
    }

    // 1 card
    if (cards.length === 1) {
        if (ranks[0] === 'J') return 'J only';
        if (ranks[0] === 'Q') return 'Q only';
        if (ranks[0] === 'K') return 'K only';
        if (ranks[0] === 'A') return 'A only';
    }

    // If we can't categorize, return with details for clarification
    return `UNKNOWN: ${cards.length} cards, ${highCardCount} high, ${gaps} gaps, suited=${allSameSuit}`;
}

async function convertCsv(inputFile, outputFile) {
    console.log(`Reading ${inputFile}...`);

    const hands = [];
    const unknownTypes = new Set();

    return new Promise((resolve, reject) => {
        fs.createReadStream(inputFile)
            .pipe(csv())
            .on('data', (row) => {
                const handKey = row.hand_key;
                const bestHold = parseInt(row.best_hold);
                const bestEv = parseFloat(row.best_ev);

                const cardsHeld = getCardsHeld(handKey, bestHold);
                const description = getStandardDescription(cardsHeld);

                if (description.startsWith('UNKNOWN')) {
                    unknownTypes.add(`${description} (e.g., hand=${handKey}, held=${cardsHeld})`);
                }

                hands.push({
                    hand_key: handKey,
                    best_hold: bestHold,
                    cards_held: cardsHeld,
                    description: description,
                    best_ev: bestEv
                });
            })
            .on('end', () => {
                console.log(`Processing ${hands.length} hands...`);

                if (unknownTypes.size > 0) {
                    console.log(`\nFound ${unknownTypes.size} unknown hand types:`);
                    Array.from(unknownTypes).forEach(type => console.log(`  ${type}`));
                    console.log('\nPlease provide clarification for these hand types.');
                }

                // Sort by EV descending, then by cards_held alphabetically
                hands.sort((a, b) => {
                    if (b.best_ev !== a.best_ev) {
                        return b.best_ev - a.best_ev;
                    }
                    return a.cards_held.localeCompare(b.cards_held);
                });

                console.log('Sorted hands by EV');

                // Write CSV
                const csvWriter = createObjectCsvWriter({
                    path: outputFile,
                    header: [
                        { id: 'hand_key', title: 'hand_key' },
                        { id: 'best_hold', title: 'best_hold' },
                        { id: 'cards_held', title: 'cards_held' },
                        { id: 'description', title: 'description' },
                        { id: 'best_ev', title: 'best_ev' }
                    ]
                });

                csvWriter.writeRecords(hands)
                    .then(() => {
                        console.log(`\nExported to ${outputFile}`);
                        console.log(`Total rows: ${hands.length}`);
                        console.log(`Highest EV: ${hands[0].hand_key} = ${hands[0].best_ev}`);
                        console.log(`Lowest EV: ${hands[hands.length - 1].hand_key} = ${hands[hands.length - 1].best_ev}`);
                        resolve();
                    })
                    .catch(reject);
            })
            .on('error', reject);
    });
}

const inputFile = process.argv[2] || 'jacks_or_better_9_6_ranked_complete.csv';
const outputFile = process.argv[3] || 'jacks_or_better_9_6_standard_descriptions.csv';

convertCsv(inputFile, outputFile).catch(console.error);
