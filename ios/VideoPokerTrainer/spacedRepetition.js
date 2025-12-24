// Spaced Repetition System for Video Poker Trainer
// Implements SM-2 algorithm with hand categorization

// Hand categories for tracking mastery
export const HAND_CATEGORIES = {
  HIGH_PAIR: 'high_pair',           // JJ, QQ, KK, AA
  LOW_PAIR: 'low_pair',             // 22-TT
  TWO_PAIR: 'two_pair',
  THREE_OF_KIND: 'three_of_kind',
  FOUR_TO_FLUSH: 'four_to_flush',
  FOUR_TO_STRAIGHT_OPEN: 'four_to_straight_open',
  FOUR_TO_STRAIGHT_INSIDE: 'four_to_straight_inside',
  FOUR_TO_ROYAL: 'four_to_royal',
  FOUR_TO_STRAIGHT_FLUSH: 'four_to_straight_flush',
  THREE_TO_ROYAL: 'three_to_royal',
  THREE_TO_STRAIGHT_FLUSH: 'three_to_straight_flush',
  HIGH_CARDS: 'high_cards',         // Just high cards (J, Q, K, A)
  GARBAGE: 'garbage',               // Discard all
  MADE_HAND: 'made_hand',           // Already have straight, flush, etc.
  MIXED_DECISION: 'mixed_decision', // Complex decisions (pair vs draw)
};

// Category display names
export const CATEGORY_NAMES = {
  [HAND_CATEGORIES.HIGH_PAIR]: 'High Pairs (J-A)',
  [HAND_CATEGORIES.LOW_PAIR]: 'Low Pairs (2-T)',
  [HAND_CATEGORIES.TWO_PAIR]: 'Two Pair',
  [HAND_CATEGORIES.THREE_OF_KIND]: 'Three of a Kind',
  [HAND_CATEGORIES.FOUR_TO_FLUSH]: 'Four to a Flush',
  [HAND_CATEGORIES.FOUR_TO_STRAIGHT_OPEN]: 'Open-Ended Straight Draw',
  [HAND_CATEGORIES.FOUR_TO_STRAIGHT_INSIDE]: 'Inside Straight Draw',
  [HAND_CATEGORIES.FOUR_TO_ROYAL]: 'Four to a Royal',
  [HAND_CATEGORIES.FOUR_TO_STRAIGHT_FLUSH]: 'Four to Straight Flush',
  [HAND_CATEGORIES.THREE_TO_ROYAL]: 'Three to a Royal',
  [HAND_CATEGORIES.THREE_TO_STRAIGHT_FLUSH]: 'Three to Straight Flush',
  [HAND_CATEGORIES.HIGH_CARDS]: 'High Cards Only',
  [HAND_CATEGORIES.GARBAGE]: 'Discard All',
  [HAND_CATEGORIES.MADE_HAND]: 'Made Hands',
  [HAND_CATEGORIES.MIXED_DECISION]: 'Mixed Decisions',
};

// Category colors for UI
export const CATEGORY_COLORS = {
  [HAND_CATEGORIES.HIGH_PAIR]: '#3498db',
  [HAND_CATEGORIES.LOW_PAIR]: '#9b59b6',
  [HAND_CATEGORIES.TWO_PAIR]: '#2ecc71',
  [HAND_CATEGORIES.THREE_OF_KIND]: '#27ae60',
  [HAND_CATEGORIES.FOUR_TO_FLUSH]: '#e74c3c',
  [HAND_CATEGORIES.FOUR_TO_STRAIGHT_OPEN]: '#f39c12',
  [HAND_CATEGORIES.FOUR_TO_STRAIGHT_INSIDE]: '#d35400',
  [HAND_CATEGORIES.FOUR_TO_ROYAL]: '#ffd700',
  [HAND_CATEGORIES.FOUR_TO_STRAIGHT_FLUSH]: '#e67e22',
  [HAND_CATEGORIES.THREE_TO_ROYAL]: '#f1c40f',
  [HAND_CATEGORIES.THREE_TO_STRAIGHT_FLUSH]: '#e59866',
  [HAND_CATEGORIES.HIGH_CARDS]: '#1abc9c',
  [HAND_CATEGORIES.GARBAGE]: '#95a5a6',
  [HAND_CATEGORIES.MADE_HAND]: '#2c3e50',
  [HAND_CATEGORIES.MIXED_DECISION]: '#8e44ad',
};

const rankValues = { '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9, '10': 10, 'J': 11, 'Q': 12, 'K': 13, 'A': 14 };

// Categorize a hand based on what the optimal hold is
export function categorizeOptimalHold(hand, optimalHoldIndices) {
  const heldCards = optimalHoldIndices.map(i => hand[i]);
  const numHeld = heldCards.length;

  // Discard all
  if (numHeld === 0) {
    return HAND_CATEGORIES.GARBAGE;
  }

  // Keep all 5 - made hand
  if (numHeld === 5) {
    return HAND_CATEGORIES.MADE_HAND;
  }

  // Analyze held cards
  const ranks = heldCards.map(c => rankValues[c.rank]);
  const suits = heldCards.map(c => c.suit);
  const uniqueRanks = [...new Set(ranks)];
  const uniqueSuits = [...new Set(suits)];
  const isAllSameSuit = uniqueSuits.length === 1;

  // Count rank occurrences
  const rankCounts = {};
  ranks.forEach(r => { rankCounts[r] = (rankCounts[r] || 0) + 1; });
  const counts = Object.values(rankCounts).sort((a, b) => b - a);

  // Check for pairs, trips, etc.
  if (numHeld === 2 && counts[0] === 2) {
    // Pair
    const pairRank = ranks[0];
    if (pairRank >= 11) { // J, Q, K, A
      return HAND_CATEGORIES.HIGH_PAIR;
    }
    return HAND_CATEGORIES.LOW_PAIR;
  }

  if (numHeld === 4 && counts[0] === 2 && counts[1] === 2) {
    return HAND_CATEGORIES.TWO_PAIR;
  }

  if (counts[0] === 3) {
    return HAND_CATEGORIES.THREE_OF_KIND;
  }

  // Check for flush draws (4 cards same suit)
  if (numHeld === 4 && isAllSameSuit) {
    // Check if it's a royal draw
    const sortedRanks = [...ranks].sort((a, b) => a - b);
    const hasAce = sortedRanks.includes(14);
    const hasTen = sortedRanks.includes(10);
    const hasJack = sortedRanks.includes(11);
    const hasQueen = sortedRanks.includes(12);
    const hasKing = sortedRanks.includes(13);

    // Four to a royal: 4 of T, J, Q, K, A suited
    const royalCards = [10, 11, 12, 13, 14];
    const royalCount = sortedRanks.filter(r => royalCards.includes(r)).length;
    if (royalCount === 4) {
      return HAND_CATEGORIES.FOUR_TO_ROYAL;
    }

    // Check for straight flush draw
    const minRank = Math.min(...sortedRanks);
    const maxRank = Math.max(...sortedRanks);
    const spread = maxRank - minRank;

    // Handle ace-low straight flush (A-2-3-4)
    if (hasAce && sortedRanks.includes(2)) {
      const lowStraightRanks = sortedRanks.filter(r => r <= 5 || r === 14);
      if (lowStraightRanks.length === 4) {
        return HAND_CATEGORIES.FOUR_TO_STRAIGHT_FLUSH;
      }
    }

    if (spread <= 4) {
      return HAND_CATEGORIES.FOUR_TO_STRAIGHT_FLUSH;
    }

    return HAND_CATEGORIES.FOUR_TO_FLUSH;
  }

  // Check for straight draws (4 cards)
  if (numHeld === 4 && uniqueRanks.length === 4) {
    const sortedRanks = [...ranks].sort((a, b) => a - b);
    const minRank = Math.min(...sortedRanks);
    const maxRank = Math.max(...sortedRanks);
    const spread = maxRank - minRank;

    // Handle ace-low straight (A-2-3-4 or similar)
    const hasAce = sortedRanks.includes(14);
    if (hasAce) {
      const lowRanks = sortedRanks.filter(r => r <= 5);
      if (lowRanks.length === 3) {
        // A-2-3-4 type
        return HAND_CATEGORIES.FOUR_TO_STRAIGHT_OPEN;
      }
    }

    if (spread === 3) {
      // Open-ended: e.g., 5-6-7-8
      return HAND_CATEGORIES.FOUR_TO_STRAIGHT_OPEN;
    } else if (spread === 4) {
      // Inside draw: e.g., 5-6-8-9 (missing 7)
      return HAND_CATEGORIES.FOUR_TO_STRAIGHT_INSIDE;
    }
  }

  // Check for 3 to a royal (3 cards, all T-A, same suit)
  if (numHeld === 3 && isAllSameSuit) {
    const royalCards = [10, 11, 12, 13, 14];
    const royalCount = ranks.filter(r => royalCards.includes(r)).length;
    if (royalCount === 3) {
      return HAND_CATEGORIES.THREE_TO_ROYAL;
    }

    // 3 to a straight flush
    const sortedRanks = [...ranks].sort((a, b) => a - b);
    const spread = sortedRanks[2] - sortedRanks[0];
    if (spread <= 4) {
      return HAND_CATEGORIES.THREE_TO_STRAIGHT_FLUSH;
    }
  }

  // High cards only (holding 1-2 high cards)
  if (numHeld <= 2 && ranks.every(r => r >= 11)) {
    return HAND_CATEGORIES.HIGH_CARDS;
  }

  // Default: mixed decision
  return HAND_CATEGORIES.MIXED_DECISION;
}

// SM-2 Algorithm Implementation
// Returns updated mastery data after a review
export function calculateSM2Update(currentData, isCorrect) {
  // SM-2 parameters
  const minEaseFactor = 1.3;

  // Get current values or defaults
  let easeFactor = currentData?.ease_factor || 2.5;
  let interval = currentData?.interval_days || 1;
  let totalAttempts = currentData?.total_attempts || 0;
  let correctAttempts = currentData?.correct_attempts || 0;

  // Update attempts
  totalAttempts += 1;
  if (isCorrect) {
    correctAttempts += 1;
  }

  // Calculate mastery score (percentage correct)
  const masteryScore = totalAttempts > 0 ? (correctAttempts / totalAttempts) * 100 : 0;

  // SM-2 quality rating: 0-5 scale
  // We map correct/incorrect to quality
  const quality = isCorrect ? 4 : 1; // 4 = correct with some hesitation, 1 = wrong

  // Update ease factor
  easeFactor = easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
  if (easeFactor < minEaseFactor) {
    easeFactor = minEaseFactor;
  }

  // Update interval
  if (!isCorrect) {
    // Reset interval on wrong answer
    interval = 1;
  } else {
    if (interval === 1) {
      interval = 1;
    } else if (interval === 2) {
      interval = 6;
    } else {
      interval = Math.round(interval * easeFactor);
    }
  }

  // Calculate next review date
  const now = new Date();
  const nextReview = new Date(now.getTime() + interval * 24 * 60 * 60 * 1000);

  return {
    ease_factor: easeFactor,
    interval_days: interval,
    total_attempts: totalAttempts,
    correct_attempts: correctAttempts,
    mastery_score: masteryScore,
    last_reviewed_at: now.toISOString(),
    next_review_at: nextReview.toISOString(),
  };
}

// Get categories that are due for review
export function getCategoriesDueForReview(masteryScores) {
  const now = new Date();
  return masteryScores.filter(score => {
    if (!score.next_review_at) return true; // Never reviewed
    return new Date(score.next_review_at) <= now;
  });
}

// Get categories sorted by priority (weakest first)
export function getCategoriesByPriority(masteryScores) {
  return [...masteryScores].sort((a, b) => {
    // First priority: due for review
    const aDue = !a.next_review_at || new Date(a.next_review_at) <= new Date();
    const bDue = !b.next_review_at || new Date(b.next_review_at) <= new Date();
    if (aDue && !bDue) return -1;
    if (!aDue && bDue) return 1;

    // Second priority: lowest mastery score
    return (a.mastery_score || 0) - (b.mastery_score || 0);
  });
}

// Calculate overall mastery percentage
export function calculateOverallMastery(masteryScores) {
  if (!masteryScores || masteryScores.length === 0) return 0;

  const totalScore = masteryScores.reduce((sum, s) => sum + (s.mastery_score || 0), 0);
  return totalScore / masteryScores.length;
}

// Get mastery level label
export function getMasteryLevel(score) {
  if (score >= 95) return { label: 'Master', color: '#27ae60' };
  if (score >= 85) return { label: 'Expert', color: '#2ecc71' };
  if (score >= 70) return { label: 'Proficient', color: '#3498db' };
  if (score >= 50) return { label: 'Learning', color: '#f39c12' };
  if (score >= 25) return { label: 'Beginner', color: '#e67e22' };
  return { label: 'Novice', color: '#e74c3c' };
}

// Generate a hand that matches a specific category (for drilling)
export function dealHandForCategory(category, attempts = 100) {
  const suits = ['hearts', 'diamonds', 'clubs', 'spades'];
  const ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];

  const createDeck = () => {
    const deck = [];
    for (const suit of suits) {
      for (const rank of ranks) {
        deck.push({ rank, suit });
      }
    }
    return deck;
  };

  const shuffle = (array) => {
    const shuffled = [...array];
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    return shuffled;
  };

  // For now, just deal random hands
  // In a full implementation, we'd generate hands that match the category
  for (let i = 0; i < attempts; i++) {
    const deck = shuffle(createDeck());
    const hand = deck.slice(0, 5);
    // We'd need to check if this hand matches the category
    // For now, return any hand
    return hand;
  }

  return shuffle(createDeck()).slice(0, 5);
}

// Database operations
export async function saveHandAttempt(supabase, userId, attemptData) {
  const { error } = await supabase
    .from('hand_attempts')
    .insert({
      user_id: userId,
      hand_key: attemptData.handKey,
      hand_category: attemptData.category,
      paytable_id: attemptData.paytableId,
      user_hold: attemptData.userHold,
      optimal_hold: attemptData.optimalHold,
      is_correct: attemptData.isCorrect,
      ev_difference: attemptData.evDifference,
      response_time_ms: attemptData.responseTime,
    });

  if (error) {
    console.error('Error saving hand attempt:', error);
    throw error;
  }
}

export async function updateMasteryScore(supabase, userId, paytableId, category, isCorrect) {
  // First, get current mastery data
  const { data: currentData, error: fetchError } = await supabase
    .from('mastery_scores')
    .select('*')
    .eq('user_id', userId)
    .eq('paytable_id', paytableId)
    .eq('category', category)
    .single();

  // Calculate updated values
  const updates = calculateSM2Update(currentData, isCorrect);

  if (fetchError && fetchError.code !== 'PGRST116') {
    // Error other than "not found"
    console.error('Error fetching mastery score:', fetchError);
    throw fetchError;
  }

  if (!currentData) {
    // Insert new record
    const { error: insertError } = await supabase
      .from('mastery_scores')
      .insert({
        user_id: userId,
        paytable_id: paytableId,
        category: category,
        ...updates,
      });

    if (insertError) {
      console.error('Error inserting mastery score:', insertError);
      throw insertError;
    }
  } else {
    // Update existing record
    const { error: updateError } = await supabase
      .from('mastery_scores')
      .update({
        ...updates,
        updated_at: new Date().toISOString(),
      })
      .eq('id', currentData.id);

    if (updateError) {
      console.error('Error updating mastery score:', updateError);
      throw updateError;
    }
  }

  return updates;
}

export async function getMasteryScores(supabase, userId, paytableId) {
  const { data, error } = await supabase
    .from('mastery_scores')
    .select('*')
    .eq('user_id', userId)
    .eq('paytable_id', paytableId);

  if (error) {
    console.error('Error fetching mastery scores:', error);
    return [];
  }

  return data || [];
}

export async function getRecentAttempts(supabase, userId, limit = 50) {
  const { data, error } = await supabase
    .from('hand_attempts')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(limit);

  if (error) {
    console.error('Error fetching recent attempts:', error);
    return [];
  }

  return data || [];
}
