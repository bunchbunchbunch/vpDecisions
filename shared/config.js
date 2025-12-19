// Shared configuration for video poker apps
export const SUPABASE_URL = 'https://ctqefgdvqiaiumtmcjdz.supabase.co';
export const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0cWVmZ2R2cWlhaXVtdG1jamR6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwMTExMzksImV4cCI6MjA4MTU4NzEzOX0.SSrvFVyedTsjq2r9mWMj8SKV4bZfRtp0MESavfz3AiI';

export const PAYTABLES = {
    'jacks-or-better-9-6': { name: 'Jacks or Better 9/6', gameType: 'jacks-or-better' },
    'jacks-or-better-8-5': { name: 'Jacks or Better 8/5', gameType: 'jacks-or-better' },
    'jacks-or-better-7-5': { name: 'Jacks or Better 7/5', gameType: 'jacks-or-better' },
    'bonus-poker-8-5': { name: 'Bonus Poker 8/5', gameType: 'bonus-poker' },
    'bonus-poker-7-5': { name: 'Bonus Poker 7/5', gameType: 'bonus-poker' },
    'double-bonus-10-7': { name: 'Double Bonus 10/7', gameType: 'double-bonus' },
    'double-bonus-9-7': { name: 'Double Bonus 9/7', gameType: 'double-bonus' },
    'double-bonus-9-6': { name: 'Double Bonus 9/6', gameType: 'double-bonus' },
    'double-double-bonus-9-6': { name: 'Double Double Bonus 9/6', gameType: 'double-double-bonus' },
    'double-double-bonus-9-5': { name: 'Double Double Bonus 9/5', gameType: 'double-double-bonus' },
    'double-double-bonus-8-5': { name: 'Double Double Bonus 8/5', gameType: 'double-double-bonus' }
};

// Canonical key utilities
const rankValues = {
    '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9,
    '10': 10, 'J': 11, 'Q': 12, 'K': 13, 'A': 14
};

const rankDisplay = {
    '2': '2', '3': '3', '4': '4', '5': '5', '6': '6', '7': '7', '8': '8', '9': '9',
    '10': 'T', 'J': 'J', 'Q': 'Q', 'K': 'K', 'A': 'A'
};

export function handToCanonicalKey(cards) {
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
    return sorted.map(card => rankDisplay[card.rank] + suitMap[card.suit]).join('');
}

// Convert hold bitmask to array of indices
export function holdBitmaskToIndices(bitmask) {
    const indices = [];
    for (let i = 0; i < 5; i++) {
        if (bitmask & (1 << i)) {
            indices.push(i);
        }
    }
    return indices;
}
