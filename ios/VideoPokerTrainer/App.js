import React, { useState, useEffect, useCallback } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  ScrollView,
  Platform,
} from 'react-native';
import { Picker } from '@react-native-picker/picker';
import { createClient } from '@supabase/supabase-js';
import { StatusBar } from 'expo-status-bar';

// Supabase configuration
const SUPABASE_URL = 'https://ctqefgdvqiaiumtmcjdz.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0cWVmZ2R2cWlhaXVtdG1jamR6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwMTExMzksImV4cCI6MjA4MTU4NzEzOX0.SSrvFVyedTsjq2r9mWMj8SKV4bZfRtp0MESavfz3AiI';
const supabaseClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Constants
const QUIZ_SIZE = 25;
const CANDIDATE_POOL_SIZE = 200;
const suits = ['hearts', 'diamonds', 'clubs', 'spades'];
const ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];
const rankValues = { '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9, '10': 10, 'J': 11, 'Q': 12, 'K': 13, 'A': 14 };
const rankDisplay = { '2': '2', '3': '3', '4': '4', '5': '5', '6': '6', '7': '7', '8': '8', '9': '9', '10': 'T', 'J': 'J', 'Q': 'Q', 'K': 'K', 'A': 'A' };
const suitSymbols = { hearts: '♥', diamonds: '♦', clubs: '♣', spades: '♠' };

const PAYTABLES = [
  { id: 'jacks-or-better-9-6', name: 'Jacks or Better 9/6' },
  { id: 'double-double-bonus-9-6', name: 'Double Double Bonus 9/6' },
];

// Utility functions
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

// Card component
function Card({ card, selected, onPress, disabled }) {
  const isRed = card.suit === 'hearts' || card.suit === 'diamonds';

  return (
    <View style={styles.cardWrapper}>
      <TouchableOpacity
        style={[styles.cardBox, selected && styles.cardSelected]}
        onPress={onPress}
        disabled={disabled}
        activeOpacity={0.7}
      >
        <Text style={[styles.cardText, isRed ? styles.cardRed : styles.cardBlack]}>
          {card.rank}{suitSymbols[card.suit]}
        </Text>
      </TouchableOpacity>
      {selected && <Text style={styles.heldLabel}>HELD</Text>}
    </View>
  );
}

// Main App
export default function App() {
  const [screen, setScreen] = useState('start');
  const [paytableId, setPaytableId] = useState('jacks-or-better-9-6');
  const [closeDecisions, setCloseDecisions] = useState(false);
  const [loadingText, setLoadingText] = useState('');

  const [quizHands, setQuizHands] = useState([]);
  const [quizResults, setQuizResults] = useState([]);
  const [quizAnswers, setQuizAnswers] = useState([]);
  const [currentHandIndex, setCurrentHandIndex] = useState(0);
  const [selectedCards, setSelectedCards] = useState(new Set());
  const [correctCount, setCorrectCount] = useState(0);
  const [showFeedback, setShowFeedback] = useState(false);
  const [isCorrect, setIsCorrect] = useState(false);

  const toggleCard = useCallback((index) => {
    if (showFeedback) return;
    setSelectedCards(prev => {
      const newSet = new Set(prev);
      if (newSet.has(index)) {
        newSet.delete(index);
      } else {
        newSet.add(index);
      }
      return newSet;
    });
  }, [showFeedback]);

  const submitAnswer = useCallback(() => {
    if (showFeedback || quizResults.length === 0) return;

    const userHold = Array.from(selectedCards).sort();
    const correctHold = quizResults[currentHandIndex][0].holdIndices.slice().sort();

    const correct = userHold.length === correctHold.length &&
      userHold.every((v, i) => v === correctHold[i]);

    if (correct) setCorrectCount(prev => prev + 1);

    setQuizAnswers(prev => [...prev, {
      hand: quizHands[currentHandIndex],
      userHold: Array.from(selectedCards),
      correctHold: quizResults[currentHandIndex][0].holdIndices,
      isCorrect: correct,
      ev: quizResults[currentHandIndex][0].ev
    }]);

    setIsCorrect(correct);
    setShowFeedback(true);
  }, [showFeedback, quizResults, quizHands, currentHandIndex, selectedCards]);

  const nextHand = useCallback(() => {
    if (currentHandIndex + 1 >= QUIZ_SIZE) {
      setScreen('results');
    } else {
      setCurrentHandIndex(prev => prev + 1);
      setSelectedCards(new Set());
      setShowFeedback(false);
    }
  }, [currentHandIndex]);

  // Keyboard handling for web
  useEffect(() => {
    if (Platform.OS !== 'web') return;

    const handleKeyDown = (e) => {
      if (screen === 'quiz' && !showFeedback) {
        if (e.key >= '1' && e.key <= '5') {
          const index = parseInt(e.key) - 1;
          toggleCard(index);
        } else if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          submitAnswer();
        }
      } else if (screen === 'quiz' && showFeedback) {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          nextHand();
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [screen, showFeedback, toggleCard, submitAnswer, nextHand]);

  const lookupHand = async (hand) => {
    const key = handToCanonicalKey(hand);

    const { data, error } = await supabaseClient
      .from('strategy')
      .select('best_hold, best_ev, hold_evs')
      .eq('paytable_id', paytableId)
      .eq('hand_key', key)
      .single();

    if (error || !data) return null;

    const sorted = [...hand].sort((a, b) => rankValues[a.rank] - rankValues[b.rank]);

    function bitmaskToOriginalIndices(bitmask) {
      const sortedIndices = [];
      for (let i = 0; i < 5; i++) {
        if (bitmask & (1 << i)) sortedIndices.push(i);
      }
      return sortedIndices.map(si => {
        const card = sorted[si];
        return hand.findIndex(c => c.rank === card.rank && c.suit === card.suit);
      });
    }

    const holdEvs = data.hold_evs || {};
    const sortedHolds = Object.entries(holdEvs)
      .map(([hold, ev]) => ({ hold: parseInt(hold), ev }))
      .sort((a, b) => b.ev - a.ev);

    const results = [];
    for (let i = 0; i < Math.min(2, sortedHolds.length); i++) {
      const { hold, ev } = sortedHolds[i];
      const indices = bitmaskToOriginalIndices(hold);
      results.push({
        holdIndices: indices,
        heldCards: indices.map(idx => hand[idx]),
        ev: ev
      });
    }
    return results;
  };

  const prepareQuiz = async () => {
    setScreen('loading');
    setQuizHands([]);
    setQuizResults([]);
    setQuizAnswers([]);
    setCurrentHandIndex(0);
    setCorrectCount(0);
    setSelectedCards(new Set());
    setShowFeedback(false);

    const hands = [];
    const results = [];

    try {
      if (closeDecisions) {
        setLoadingText('Finding close decisions...');
        const candidates = [];
        let attempts = 0;
        const maxAttempts = 1000;

        while (candidates.length < CANDIDATE_POOL_SIZE && attempts < maxAttempts) {
          const hand = dealHand();
          const result = await lookupHand(hand);
          attempts++;
          if (result && result.length >= 2) {
            const evGap = result[0].ev - result[1].ev;
            candidates.push({ hand, result, evGap });
          }
          if (attempts % 20 === 0) {
            setLoadingText(`Found ${candidates.length} candidates (${attempts} tried)`);
          }
        }

        if (candidates.length < QUIZ_SIZE) {
          alert(`Only found ${candidates.length} close decision hands. Try again later.`);
          setScreen('start');
          return;
        }

        candidates.sort((a, b) => a.evGap - b.evGap);
        const closest = candidates.slice(0, QUIZ_SIZE);
        hands.push(...closest.map(c => c.hand));
        results.push(...closest.map(c => c.result));
      } else {
        setLoadingText('Loading hands...');
        let attempts = 0;
        const maxAttempts = 500;

        while (hands.length < QUIZ_SIZE && attempts < maxAttempts) {
          const hand = dealHand();
          const result = await lookupHand(hand);
          attempts++;
          if (result && result.length > 0) {
            hands.push(hand);
            results.push(result);
            setLoadingText(`Found ${hands.length} of ${QUIZ_SIZE} hands (${attempts} tried)`);
          }
        }

        if (hands.length < QUIZ_SIZE) {
          alert(`Only found ${hands.length} hands in database. Try again later.`);
          setScreen('start');
          return;
        }
      }

      setQuizHands(hands);
      setQuizResults(results);
      setScreen('quiz');
    } catch (err) {
      alert('Error loading quiz: ' + err.message);
      setScreen('start');
    }
  };

  const resetQuiz = () => {
    setScreen('start');
    setQuizHands([]);
    setQuizResults([]);
    setQuizAnswers([]);
    setCurrentHandIndex(0);
    setCorrectCount(0);
    setSelectedCards(new Set());
    setShowFeedback(false);
  };

  // Start screen
  if (screen === 'start') {
    return (
      <View style={styles.container}>
        <StatusBar style="light" />
        <View style={styles.header}>
          <Text style={styles.title}>Video Poker Trainer</Text>
          <Text style={styles.subtitle}>EV-Based Strategy Training</Text>
        </View>

        <View style={styles.whiteCard}>
          <Text style={styles.label}>Select Game:</Text>
          <View style={styles.pickerContainer}>
            <Picker
              selectedValue={paytableId}
              onValueChange={setPaytableId}
              style={styles.picker}
            >
              {PAYTABLES.map(p => (
                <Picker.Item key={p.id} label={p.name} value={p.id} />
              ))}
            </Picker>
          </View>

          <TouchableOpacity
            style={styles.checkboxRow}
            onPress={() => setCloseDecisions(!closeDecisions)}
          >
            <View style={[styles.checkbox, closeDecisions && styles.checkboxChecked]}>
              {closeDecisions && <Text style={styles.checkmark}>✓</Text>}
            </View>
            <Text style={styles.checkboxLabel}>Close Decisions Only</Text>
          </TouchableOpacity>
          <Text style={styles.hint}>Focuses on hands where top plays have similar EVs</Text>

          <TouchableOpacity style={styles.button} onPress={prepareQuiz}>
            <Text style={styles.buttonText}>Start 25-Hand Quiz</Text>
          </TouchableOpacity>

          {Platform.OS === 'web' && (
            <Text style={styles.hint}>
              Keyboard: 1-5 to toggle cards, Enter/Space to submit
            </Text>
          )}
        </View>
      </View>
    );
  }

  // Loading screen
  if (screen === 'loading') {
    return (
      <View style={styles.container}>
        <StatusBar style="light" />
        <View style={styles.whiteCard}>
          <View style={styles.spinner} />
          <Text style={styles.loadingText}>{loadingText}</Text>
        </View>
      </View>
    );
  }

  // Quiz screen
  if (screen === 'quiz') {
    const hand = quizHands[currentHandIndex];
    const results = quizResults[currentHandIndex];

    return (
      <View style={styles.container}>
        <StatusBar style="light" />

        <View style={styles.progressBar}>
          <Text style={styles.progressText}>
            Hand {currentHandIndex + 1} of {QUIZ_SIZE} | Score: {correctCount}
          </Text>
          <View style={styles.progressTrack}>
            <View style={[styles.progressFill, { width: `${(currentHandIndex / QUIZ_SIZE) * 100}%` }]} />
          </View>
        </View>

        <View style={styles.gameArea}>
          <View style={styles.cardsContainer}>
            {hand.map((card, index) => (
              <Card
                key={index}
                card={card}
                selected={selectedCards.has(index)}
                onPress={() => toggleCard(index)}
                disabled={showFeedback}
              />
            ))}
          </View>

          {showFeedback && (
            <View style={[styles.feedback, isCorrect ? styles.feedbackCorrect : styles.feedbackIncorrect]}>
              <Text style={[styles.feedbackTitle, isCorrect ? styles.textGreen : styles.textRed]}>
                {isCorrect ? '✓ Correct!' : '✗ Incorrect'}
              </Text>
              <Text style={styles.feedbackText}>
                Best play: {results[0].heldCards.length === 0 ? 'Discard all' :
                  results[0].heldCards.map(c => `${c.rank}${suitSymbols[c.suit]}`).join(' ')}
              </Text>
              <Text style={styles.feedbackText}>EV: {results[0].ev.toFixed(4)}</Text>
              {results.length > 1 && (
                <Text style={styles.feedbackText}>
                  2nd best EV: {results[1].ev.toFixed(4)} (gap: {(results[0].ev - results[1].ev).toFixed(4)})
                </Text>
              )}
            </View>
          )}

          {!showFeedback ? (
            <TouchableOpacity style={styles.button} onPress={submitAnswer}>
              <Text style={styles.buttonText}>Submit</Text>
            </TouchableOpacity>
          ) : (
            <TouchableOpacity style={[styles.button, styles.buttonNext]} onPress={nextHand}>
              <Text style={styles.buttonText}>
                {currentHandIndex + 1 >= QUIZ_SIZE ? 'See Results' : 'Next Hand'}
              </Text>
            </TouchableOpacity>
          )}
        </View>
      </View>
    );
  }

  // Results screen
  if (screen === 'results') {
    return (
      <ScrollView style={styles.container} contentContainerStyle={styles.resultsContent}>
        <StatusBar style="light" />

        <View style={styles.resultsHeader}>
          <Text style={styles.title}>Quiz Complete!</Text>
          <Text style={styles.finalScore}>{correctCount} / {QUIZ_SIZE}</Text>
          <Text style={styles.percentage}>{Math.round((correctCount / QUIZ_SIZE) * 100)}%</Text>
        </View>

        <View style={styles.reviewSection}>
          {quizAnswers.map((answer, index) => (
            <View key={index} style={[styles.reviewItem, answer.isCorrect ? styles.reviewCorrect : styles.reviewIncorrect]}>
              <Text style={styles.reviewTitle}>Hand {index + 1}</Text>
              <Text style={styles.reviewCards}>
                {answer.hand.map(c => `${c.rank}${suitSymbols[c.suit]}`).join(' ')}
              </Text>
              <Text style={styles.reviewText}>
                Your hold: {answer.userHold.length === 0 ? 'Discard all' :
                  answer.userHold.map(i => `${answer.hand[i].rank}${suitSymbols[answer.hand[i].suit]}`).join(' ')}
              </Text>
              {!answer.isCorrect && (
                <Text style={[styles.reviewText, styles.textRed]}>
                  Correct: {answer.correctHold.length === 0 ? 'Discard all' :
                    answer.correctHold.map(i => `${answer.hand[i].rank}${suitSymbols[answer.hand[i].suit]}`).join(' ')}
                </Text>
              )}
            </View>
          ))}
        </View>

        <TouchableOpacity style={styles.button} onPress={resetQuiz}>
          <Text style={styles.buttonText}>Play Again</Text>
        </TouchableOpacity>
      </ScrollView>
    );
  }

  return null;
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#667eea',
    padding: 16,
    paddingTop: 50,
  },
  header: {
    alignItems: 'center',
    marginBottom: 20,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: 'white',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: 'rgba(255,255,255,0.8)',
  },
  whiteCard: {
    backgroundColor: 'white',
    borderRadius: 16,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 4,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 8,
    color: '#333',
  },
  pickerContainer: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    marginBottom: 16,
    overflow: 'hidden',
  },
  picker: {
    height: 50,
  },
  checkboxRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 12,
  },
  checkbox: {
    width: 24,
    height: 24,
    borderWidth: 2,
    borderColor: '#667eea',
    borderRadius: 4,
    marginRight: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  checkboxChecked: {
    backgroundColor: '#667eea',
  },
  checkmark: {
    color: 'white',
    fontWeight: 'bold',
  },
  checkboxLabel: {
    fontSize: 16,
    color: '#333',
  },
  hint: {
    fontSize: 12,
    color: '#888',
    marginTop: 8,
    textAlign: 'center',
  },
  button: {
    backgroundColor: '#667eea',
    padding: 16,
    borderRadius: 30,
    alignItems: 'center',
    marginTop: 20,
  },
  buttonNext: {
    backgroundColor: '#3498db',
  },
  buttonText: {
    color: 'white',
    fontSize: 18,
    fontWeight: 'bold',
  },
  spinner: {
    width: 40,
    height: 40,
    borderWidth: 4,
    borderColor: '#ddd',
    borderTopColor: '#667eea',
    borderRadius: 20,
    marginBottom: 20,
    alignSelf: 'center',
  },
  loadingText: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
  },
  progressBar: {
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 12,
    marginBottom: 16,
  },
  progressText: {
    fontSize: 14,
    color: '#666',
    marginBottom: 8,
  },
  progressTrack: {
    height: 8,
    backgroundColor: '#e0e0e0',
    borderRadius: 4,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: '#667eea',
    borderRadius: 4,
  },
  gameArea: {
    backgroundColor: '#0a5f38',
    borderRadius: 16,
    padding: 16,
    flex: 1,
  },
  cardsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  cardWrapper: {
    flex: 1,
    marginHorizontal: 2,
    alignItems: 'center',
  },
  cardBox: {
    backgroundColor: 'white',
    borderRadius: 8,
    aspectRatio: 0.7,
    width: '100%',
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 4,
    elevation: 4,
  },
  cardSelected: {
    transform: [{ translateY: -10 }],
    borderWidth: 3,
    borderColor: '#ffd700',
    shadowColor: '#ffd700',
    shadowOpacity: 0.6,
  },
  cardText: {
    fontSize: 18,
    fontWeight: 'bold',
  },
  cardRed: {
    color: '#e74c3c',
  },
  cardBlack: {
    color: '#2c3e50',
  },
  heldLabel: {
    backgroundColor: '#ffd700',
    color: '#333',
    fontSize: 10,
    fontWeight: 'bold',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    marginTop: 4,
    overflow: 'hidden',
  },
  feedback: {
    backgroundColor: 'rgba(255,255,255,0.95)',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
  },
  feedbackCorrect: {
    borderLeftWidth: 4,
    borderLeftColor: '#2ecc71',
  },
  feedbackIncorrect: {
    borderLeftWidth: 4,
    borderLeftColor: '#e74c3c',
  },
  feedbackTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  feedbackText: {
    fontSize: 14,
    color: '#666',
    marginTop: 4,
  },
  textGreen: {
    color: '#2ecc71',
  },
  textRed: {
    color: '#e74c3c',
  },
  resultsContent: {
    paddingBottom: 40,
  },
  resultsHeader: {
    alignItems: 'center',
    marginBottom: 24,
  },
  finalScore: {
    fontSize: 48,
    fontWeight: 'bold',
    color: 'white',
    marginTop: 16,
  },
  percentage: {
    fontSize: 24,
    color: 'rgba(255,255,255,0.8)',
  },
  reviewSection: {
    backgroundColor: 'white',
    borderRadius: 16,
    padding: 16,
    marginBottom: 16,
  },
  reviewItem: {
    padding: 12,
    borderRadius: 8,
    marginBottom: 8,
    backgroundColor: '#f5f5f5',
  },
  reviewCorrect: {
    borderLeftWidth: 3,
    borderLeftColor: '#2ecc71',
  },
  reviewIncorrect: {
    borderLeftWidth: 3,
    borderLeftColor: '#e74c3c',
  },
  reviewTitle: {
    fontWeight: 'bold',
    marginBottom: 4,
  },
  reviewCards: {
    fontSize: 16,
    marginBottom: 4,
  },
  reviewText: {
    fontSize: 14,
    color: '#666',
  },
});
