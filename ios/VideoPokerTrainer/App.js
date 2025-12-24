import React, { useState, useEffect, useCallback } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  ScrollView,
  Platform,
  Image,
  useWindowDimensions,
  SafeAreaView,
  ActivityIndicator,
  Switch,
  TextInput,
} from 'react-native';
import { Picker } from '@react-native-picker/picker';
import { createClient } from '@supabase/supabase-js';
import { StatusBar } from 'expo-status-bar';
import * as ScreenOrientation from 'expo-screen-orientation';
import * as WebBrowser from 'expo-web-browser';
import * as AuthSession from 'expo-auth-session';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Import spaced repetition system
import {
  HAND_CATEGORIES,
  CATEGORY_NAMES,
  CATEGORY_COLORS,
  categorizeOptimalHold,
  calculateSM2Update,
  getCategoriesByPriority,
  calculateOverallMastery,
  getMasteryLevel,
  saveHandAttempt,
  updateMasteryScore,
  getMasteryScores,
} from './spacedRepetition';

// Import feedback service for sound and haptics
import {
  SOUNDS,
  HAPTIC_TYPES,
  initializeAudio,
  playSound,
  triggerHaptic,
  updateFeedbackSettings,
  cleanupAudio,
} from './feedbackService';

// Required for web browser auth flow
WebBrowser.maybeCompleteAuthSession();

// Supabase configuration - use localStorage on web, AsyncStorage on mobile
const SUPABASE_URL = 'https://ctqefgdvqiaiumtmcjdz.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0cWVmZ2R2cWlhaXVtdG1jamR6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwMTExMzksImV4cCI6MjA4MTU4NzEzOX0.SSrvFVyedTsjq2r9mWMj8SKV4bZfRtp0MESavfz3AiI';

const supabaseClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    storage: Platform.OS === 'web' ? undefined : AsyncStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
});

// Constants
const DEBUG = true; // Set to false to disable debug logging
const QUIZ_SIZE = 25;
const CANDIDATE_POOL_SIZE = 200;
const suits = ['hearts', 'diamonds', 'clubs', 'spades'];
const ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];
const rankValues = { '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9, '10': 10, 'J': 11, 'Q': 12, 'K': 13, 'A': 14 };
const rankDisplay = { '2': '2', '3': '3', '4': '4', '5': '5', '6': '6', '7': '7', '8': '8', '9': '9', '10': 'T', 'J': 'J', 'Q': 'Q', 'K': 'K', 'A': 'A' };
const suitSymbols = { hearts: '♥', diamonds: '♦', clubs: '♣', spades: '♠' };
const suitColors = { hearts: '#e74c3c', diamonds: '#e74c3c', clubs: '#2c3e50', spades: '#2c3e50' };

// Local card images (PNG files work on all platforms)
const cardAssets = {
  '2C': require('./assets/cards/png/2C.png'),
  '2D': require('./assets/cards/png/2D.png'),
  '2H': require('./assets/cards/png/2H.png'),
  '2S': require('./assets/cards/png/2S.png'),
  '3C': require('./assets/cards/png/3C.png'),
  '3D': require('./assets/cards/png/3D.png'),
  '3H': require('./assets/cards/png/3H.png'),
  '3S': require('./assets/cards/png/3S.png'),
  '4C': require('./assets/cards/png/4C.png'),
  '4D': require('./assets/cards/png/4D.png'),
  '4H': require('./assets/cards/png/4H.png'),
  '4S': require('./assets/cards/png/4S.png'),
  '5C': require('./assets/cards/png/5C.png'),
  '5D': require('./assets/cards/png/5D.png'),
  '5H': require('./assets/cards/png/5H.png'),
  '5S': require('./assets/cards/png/5S.png'),
  '6C': require('./assets/cards/png/6C.png'),
  '6D': require('./assets/cards/png/6D.png'),
  '6H': require('./assets/cards/png/6H.png'),
  '6S': require('./assets/cards/png/6S.png'),
  '7C': require('./assets/cards/png/7C.png'),
  '7D': require('./assets/cards/png/7D.png'),
  '7H': require('./assets/cards/png/7H.png'),
  '7S': require('./assets/cards/png/7S.png'),
  '8C': require('./assets/cards/png/8C.png'),
  '8D': require('./assets/cards/png/8D.png'),
  '8H': require('./assets/cards/png/8H.png'),
  '8S': require('./assets/cards/png/8S.png'),
  '9C': require('./assets/cards/png/9C.png'),
  '9D': require('./assets/cards/png/9D.png'),
  '9H': require('./assets/cards/png/9H.png'),
  '9S': require('./assets/cards/png/9S.png'),
  'TC': require('./assets/cards/png/TC.png'),
  'TD': require('./assets/cards/png/TD.png'),
  'TH': require('./assets/cards/png/TH.png'),
  'TS': require('./assets/cards/png/TS.png'),
  'JC': require('./assets/cards/png/JC.png'),
  'JD': require('./assets/cards/png/JD.png'),
  'JH': require('./assets/cards/png/JH.png'),
  'JS': require('./assets/cards/png/JS.png'),
  'QC': require('./assets/cards/png/QC.png'),
  'QD': require('./assets/cards/png/QD.png'),
  'QH': require('./assets/cards/png/QH.png'),
  'QS': require('./assets/cards/png/QS.png'),
  'KC': require('./assets/cards/png/KC.png'),
  'KD': require('./assets/cards/png/KD.png'),
  'KH': require('./assets/cards/png/KH.png'),
  'KS': require('./assets/cards/png/KS.png'),
  'AC': require('./assets/cards/png/AC.png'),
  'AD': require('./assets/cards/png/AD.png'),
  'AH': require('./assets/cards/png/AH.png'),
  'AS': require('./assets/cards/png/AS.png'),
};

function getCardImageSource(card) {
  const rankMap = { '10': 'T', 'J': 'J', 'Q': 'Q', 'K': 'K', 'A': 'A' };
  const suitMap = { 'hearts': 'H', 'diamonds': 'D', 'clubs': 'C', 'spades': 'S' };
  const rankCode = rankMap[card.rank] || card.rank;
  const suitCode = suitMap[card.suit];
  const key = `${rankCode}${suitCode}`;
  return cardAssets[key];
}

// Helper component for colored card text
function ColoredCard({ card }) {
  return (
    <Text style={{ color: suitColors[card.suit], fontWeight: 'bold' }}>
      {card.rank}{suitSymbols[card.suit]}
    </Text>
  );
}

// Helper to render a list of cards with colors
function ColoredCardList({ cards, style }) {
  return (
    <Text style={style}>
      {cards.map((card, i) => (
        <React.Fragment key={i}>
          {i > 0 && ' '}
          <ColoredCard card={card} />
        </React.Fragment>
      ))}
    </Text>
  );
}

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

// Card component with landscape optimization
function Card({ card, selected, onPress, disabled, isLandscape, cardHeight, cardWidth }) {
  const imageSource = getCardImageSource(card);

  return (
    <View style={[styles.cardWrapper, isLandscape && styles.cardWrapperLandscape]}>
      <TouchableOpacity
        style={[
          styles.cardBox,
          selected && styles.cardSelected,
          isLandscape && cardWidth && cardHeight && {
            width: cardWidth,
            height: cardHeight,
            aspectRatio: undefined,
          }
        ]}
        onPress={onPress}
        disabled={disabled}
        activeOpacity={0.7}
      >
        <Image
          source={imageSource}
          style={styles.cardImage}
          resizeMode="contain"
        />
      </TouchableOpacity>
      {selected && <Text style={[styles.heldLabel, isLandscape && styles.heldLabelLandscape]}>HELD</Text>}
    </View>
  );
}

// Main App
export default function App() {
  const { width, height } = useWindowDimensions();
  const isLandscape = width > height;
  const isMobile = Platform.OS !== 'web';

  // Auth state
  const [session, setSession] = useState(null);
  const [user, setUser] = useState(null);
  const [authLoading, setAuthLoading] = useState(true);
  const [authError, setAuthError] = useState(null);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isSignUp, setIsSignUp] = useState(false);

  // Sound & Haptic settings state
  const [soundEnabled, setSoundEnabled] = useState(true);
  const [soundVolume, setSoundVolume] = useState(0.7);
  const [hapticsEnabled, setHapticsEnabled] = useState(true);

  // Get redirect URL for OAuth
  const redirectUrl = AuthSession.makeRedirectUri({
    scheme: 'vptrainer',
    path: 'auth/callback',
  });

  // Check for existing session on mount
  useEffect(() => {
    supabaseClient.auth.getSession()
      .then(({ data: { session } }) => {
        setSession(session);
        setUser(session?.user ?? null);
        setAuthLoading(false);
      })
      .catch((error) => {
        console.error('Error getting session:', error);
        setAuthLoading(false);
      });

    // Listen for auth state changes
    const { data: { subscription } } = supabaseClient.auth.onAuthStateChange(
      async (event, session) => {
        setSession(session);
        setUser(session?.user ?? null);

        // Create/update profile on sign in
        if (event === 'SIGNED_IN' && session?.user) {
          await upsertProfile(session.user);
        }
      }
    );

    return () => subscription.unsubscribe();
  }, []);

  // Load settings from AsyncStorage on mount
  useEffect(() => {
    const loadSettings = async () => {
      try {
        const stored = await AsyncStorage.getItem('@vp_trainer_settings');
        if (stored) {
          const parsed = JSON.parse(stored);
          if (parsed.soundEnabled !== undefined) setSoundEnabled(parsed.soundEnabled);
          if (parsed.soundVolume !== undefined) setSoundVolume(parsed.soundVolume);
          if (parsed.hapticsEnabled !== undefined) setHapticsEnabled(parsed.hapticsEnabled);
        }
      } catch (error) {
        console.warn('Failed to load settings:', error);
      }
    };
    loadSettings();
  }, []);

  // Sync settings to feedback service when they change
  useEffect(() => {
    updateFeedbackSettings({
      soundEnabled,
      soundVolume,
      hapticsEnabled,
    });
  }, [soundEnabled, soundVolume, hapticsEnabled]);

  // Save settings to AsyncStorage when they change
  useEffect(() => {
    const saveSettings = async () => {
      try {
        await AsyncStorage.setItem('@vp_trainer_settings', JSON.stringify({
          soundEnabled,
          soundVolume,
          hapticsEnabled,
        }));
      } catch (error) {
        console.warn('Failed to save settings:', error);
      }
    };
    saveSettings();
  }, [soundEnabled, soundVolume, hapticsEnabled]);

  // Initialize audio system on mount
  useEffect(() => {
    initializeAudio();
    return () => cleanupAudio();
  }, []);

  // Create or update user profile
  const upsertProfile = async (user) => {
    const { error } = await supabaseClient
      .from('profiles')
      .upsert({
        id: user.id,
        email: user.email,
        full_name: user.user_metadata?.full_name || user.user_metadata?.name || null,
        avatar_url: user.user_metadata?.avatar_url || user.user_metadata?.picture || null,
        updated_at: new Date().toISOString(),
      }, { onConflict: 'id' });

    if (error) {
      console.error('Error upserting profile:', error);
    }
  };

  // Sign in with Google
  const signInWithGoogle = async () => {
    setAuthError(null);
    try {
      const { data, error } = await supabaseClient.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: redirectUrl,
          skipBrowserRedirect: true,
        },
      });

      if (error) throw error;

      if (data?.url) {
        const result = await WebBrowser.openAuthSessionAsync(
          data.url,
          redirectUrl
        );

        if (result.type === 'success') {
          const url = result.url;
          // Extract tokens from URL
          const params = new URL(url).hash.substring(1);
          const urlParams = new URLSearchParams(params);
          const accessToken = urlParams.get('access_token');
          const refreshToken = urlParams.get('refresh_token');

          if (accessToken) {
            const { error: sessionError } = await supabaseClient.auth.setSession({
              access_token: accessToken,
              refresh_token: refreshToken,
            });
            if (sessionError) throw sessionError;
          }
        }
      }
    } catch (error) {
      console.error('Error signing in:', error);
      setAuthError(error.message);
    }
  };

  // Sign in with email/password
  const signInWithEmail = async () => {
    setAuthError(null);
    if (!email || !password) {
      setAuthError('Please enter email and password');
      return;
    }
    try {
      const { error } = await supabaseClient.auth.signInWithPassword({
        email,
        password,
      });
      if (error) throw error;
    } catch (error) {
      console.error('Error signing in with email:', error);
      setAuthError(error.message);
    }
  };

  // Sign up with email/password
  const signUpWithEmail = async () => {
    setAuthError(null);
    if (!email || !password) {
      setAuthError('Please enter email and password');
      return;
    }
    if (password.length < 6) {
      setAuthError('Password must be at least 6 characters');
      return;
    }
    try {
      const { error } = await supabaseClient.auth.signUp({
        email,
        password,
      });
      if (error) throw error;
      setAuthError('Check your email for verification link (or sign in if email confirmation is disabled)');
    } catch (error) {
      console.error('Error signing up:', error);
      setAuthError(error.message);
    }
  };

  // Sign out
  const signOut = async () => {
    const { error } = await supabaseClient.auth.signOut();
    if (error) {
      console.error('Error signing out:', error);
    }
  };

  // Lock to landscape on mobile
  useEffect(() => {
    if (isMobile) {
      ScreenOrientation.lockAsync(ScreenOrientation.OrientationLock.LANDSCAPE);
    }
    return () => {
      if (isMobile) {
        ScreenOrientation.unlockAsync();
      }
    };
  }, [isMobile]);

  const [screen, setScreen] = useState('home');
  const [paytableId, setPaytableId] = useState('jacks-or-better-9-6');

  // Hand Analyzer state
  const [analyzerHand, setAnalyzerHand] = useState([]);
  const [analyzerResults, setAnalyzerResults] = useState(null);
  const [analyzerLoading, setAnalyzerLoading] = useState(false);
  const [analyzerPaytable, setAnalyzerPaytable] = useState('jacks-or-better-9-6');
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
  const [expandedHandIndex, setExpandedHandIndex] = useState(null);

  // Spaced repetition state
  const [masteryScores, setMasteryScores] = useState([]);
  const [masteryLoading, setMasteryLoading] = useState(false);
  const [handStartTime, setHandStartTime] = useState(null);
  const [weakSpotsMode, setWeakSpotsMode] = useState(false);

  // Fetch mastery scores when user logs in or paytable changes
  useEffect(() => {
    if (user && paytableId) {
      fetchMasteryScores();
    }
  }, [user, paytableId]);

  const fetchMasteryScores = async () => {
    if (!user) return;
    setMasteryLoading(true);
    try {
      const scores = await getMasteryScores(supabaseClient, user.id, paytableId);
      setMasteryScores(scores);
    } catch (error) {
      console.error('Error fetching mastery scores:', error);
    }
    setMasteryLoading(false);
  };

  // Track when each hand starts (for response time)
  useEffect(() => {
    if (screen === 'quiz' && !showFeedback && quizHands.length > 0) {
      setHandStartTime(Date.now());
    }
  }, [currentHandIndex, screen, showFeedback, quizHands.length]);

  const toggleCard = useCallback((index) => {
    if (showFeedback) return;
    // Provide feedback on card selection
    playSound(SOUNDS.CARD_SELECT);
    triggerHaptic(HAPTIC_TYPES.LIGHT);
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

  const submitAnswer = useCallback(async () => {
    if (showFeedback || quizResults.length === 0) return;

    // Provide feedback on submission
    playSound(SOUNDS.SUBMIT);
    triggerHaptic(HAPTIC_TYPES.MEDIUM);

    const userHold = Array.from(selectedCards).sort();
    const correctHold = quizResults[currentHandIndex][0].holdIndices.slice().sort();

    const correct = userHold.length === correctHold.length &&
      userHold.every((v, i) => v === correctHold[i]);

    // Provide feedback based on correctness
    if (correct) {
      setCorrectCount(prev => prev + 1);
      // Delay success feedback slightly for better UX flow
      setTimeout(() => {
        playSound(SOUNDS.CORRECT);
        triggerHaptic(HAPTIC_TYPES.SUCCESS);
      }, 150);
    } else {
      // Delay error feedback slightly for better UX flow
      setTimeout(() => {
        playSound(SOUNDS.INCORRECT);
        triggerHaptic(HAPTIC_TYPES.ERROR);
      }, 150);
    }

    const hand = quizHands[currentHandIndex];
    const optimalHoldIndices = quizResults[currentHandIndex][0].holdIndices;

    // Categorize the hand based on optimal hold
    const category = categorizeOptimalHold(hand, optimalHoldIndices);

    // Calculate response time
    const responseTime = handStartTime ? Date.now() - handStartTime : null;

    // Calculate EV difference if wrong
    let evDifference = 0;
    if (!correct) {
      const userHoldEv = quizResults[currentHandIndex].find(h =>
        h.holdIndices.length === userHold.length &&
        h.holdIndices.slice().sort().every((v, i) => v === userHold[i])
      )?.ev || 0;
      evDifference = quizResults[currentHandIndex][0].ev - userHoldEv;
    }

    setQuizAnswers(prev => [...prev, {
      hand: hand,
      userHold: Array.from(selectedCards),
      correctHold: optimalHoldIndices,
      isCorrect: correct,
      ev: quizResults[currentHandIndex][0].ev,
      allHolds: quizResults[currentHandIndex],
      category: category,
    }]);

    setIsCorrect(correct);
    setShowFeedback(true);

    // Save attempt and update mastery (async, don't wait)
    if (user) {
      const handKey = handToCanonicalKey(hand);

      // Save hand attempt
      saveHandAttempt(supabaseClient, user.id, {
        handKey,
        category,
        paytableId,
        userHold: Array.from(selectedCards),
        optimalHold: optimalHoldIndices,
        isCorrect: correct,
        evDifference,
        responseTime,
      }).catch(err => console.error('Error saving attempt:', err));

      // Update mastery score
      updateMasteryScore(supabaseClient, user.id, paytableId, category, correct)
        .then(() => fetchMasteryScores())
        .catch(err => console.error('Error updating mastery:', err));
    }
  }, [showFeedback, quizResults, quizHands, currentHandIndex, selectedCards, user, paytableId, handStartTime]);

  const nextHand = useCallback(() => {
    if (currentHandIndex + 1 >= QUIZ_SIZE) {
      // Quiz complete - celebration feedback
      playSound(SOUNDS.QUIZ_COMPLETE);
      triggerHaptic(HAPTIC_TYPES.SUCCESS);
      setScreen('results');
    } else {
      // Next hand transition feedback
      playSound(SOUNDS.NEXT_HAND);
      triggerHaptic(HAPTIC_TYPES.LIGHT);
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
        const keyMap = { '1': 0, '2': 1, '3': 2, '4': 3, '5': 4, 'd': 0, 'f': 1, 'j': 2, 'k': 3, 'l': 4 };
        if (e.key in keyMap) {
          toggleCard(keyMap[e.key]);
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
    if (DEBUG) console.log('lookupHand called with key:', key, 'paytable:', paytableId);

    let data, error;
    try {
      // Use direct fetch to bypass supabase client (more reliable)
      const url = `${SUPABASE_URL}/rest/v1/strategy?paytable_id=eq.${paytableId}&hand_key=eq.${key}&select=best_hold,best_ev,hold_evs`;
      if (DEBUG) console.log('Fetching:', url);
      const response = await fetch(url, {
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        }
      });
      if (DEBUG) console.log('Fetch response status:', response.status);
      const jsonData = await response.json();
      if (DEBUG) console.log('Fetch got data:', jsonData.length > 0 ? 'yes' : 'no');

      data = jsonData[0] || null;
      error = jsonData.length === 0 ? { code: 'PGRST116' } : null;
    } catch (e) {
      console.error('lookupHand exception:', e);
      return null;
    }

    if (error) {
      // Only log non-PGRST116 errors (PGRST116 = row not found, expected for random hands)
      if (error.code !== 'PGRST116') {
        console.error('lookupHand error:', error.code, error.message, 'paytable:', paytableId, 'key:', key);
      }
      return null;
    }
    if (!data) return null;

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

    const results = sortedHolds.map(({ hold, ev }) => {
      const indices = bitmaskToOriginalIndices(hold);
      return {
        holdIndices: indices,
        heldCards: indices.map(idx => hand[idx]),
        ev: ev
      };
    });
    return results;
  };

  const prepareQuiz = async () => {
    if (DEBUG) console.log('prepareQuiz called, weakSpotsMode:', weakSpotsMode);
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
      if (weakSpotsMode) {
        // Weak spots mode: focus on categories with low mastery
        if (DEBUG) console.log('Entering weak spots mode');
        setLoadingText('Finding weak spots...');

        // Get weak categories (lowest mastery or never practiced)
        const weakCategories = new Set();
        const sortedScores = getCategoriesByPriority(masteryScores);

        // Take categories with mastery < 80% or due for review
        sortedScores.forEach(score => {
          if ((score.mastery_score || 0) < 80) {
            weakCategories.add(score.category);
          }
        });

        // Also add categories never practiced
        Object.values(HAND_CATEGORIES).forEach(cat => {
          if (!masteryScores.find(s => s.category === cat)) {
            weakCategories.add(cat);
          }
        });

        // If no weak categories, use all categories
        if (weakCategories.size === 0) {
          Object.values(HAND_CATEGORIES).forEach(cat => weakCategories.add(cat));
        }

        const candidates = [];
        let attempts = 0;
        // For weak spots, we only need ~50 candidates (2x quiz size) for variety
        const weakSpotPoolSize = QUIZ_SIZE * 2;
        const maxAttempts = 500;
        if (DEBUG) console.log('Starting weak spots loop, poolSize:', weakSpotPoolSize, 'maxAttempts:', maxAttempts);

        while (candidates.length < weakSpotPoolSize && attempts < maxAttempts) {
          const hand = dealHand();
          if (DEBUG && attempts === 0) console.log('First hand dealt, calling lookupHand...');
          const result = await lookupHand(hand);
          if (DEBUG && attempts === 0) console.log('First lookupHand returned:', result ? 'found' : 'null');
          attempts++;

          if (result && result.length > 0) {
            const category = categorizeOptimalHold(hand, result[0].holdIndices);
            const isWeakCategory = weakCategories.has(category);
            const masteryScore = masteryScores.find(s => s.category === category)?.mastery_score || 0;

            // Prioritize weak categories, but include some variety
            if (isWeakCategory || candidates.length < QUIZ_SIZE / 2) {
              candidates.push({
                hand,
                result,
                category,
                masteryScore,
                priority: isWeakCategory ? masteryScore : 100 + masteryScore, // Weak categories first
              });
            }
          }

          if (attempts % 20 === 0) {
            setLoadingText(`Found ${candidates.length} weak spot hands (${attempts} tried)`);
          }
        }

        if (candidates.length < QUIZ_SIZE) {
          alert(`Only found ${candidates.length} hands. Try again later.`);
          setScreen('start');
          return;
        }

        // Sort by priority (weakest first)
        candidates.sort((a, b) => a.priority - b.priority);
        const selected = candidates.slice(0, QUIZ_SIZE);

        // Shuffle to mix up the categories
        for (let i = selected.length - 1; i > 0; i--) {
          const j = Math.floor(Math.random() * (i + 1));
          [selected[i], selected[j]] = [selected[j], selected[i]];
        }

        hands.push(...selected.map(c => c.hand));
        results.push(...selected.map(c => c.result));
      } else if (closeDecisions) {
        setLoadingText('Finding close decisions...');
        const candidates = [];
        let attempts = 0;
        // For close decisions, we need a larger pool to find truly close ones
        const closeDecisionPoolSize = QUIZ_SIZE * 3;
        const maxAttempts = 500;

        while (candidates.length < closeDecisionPoolSize && attempts < maxAttempts) {
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
    setScreen('home');
    setQuizHands([]);
    setQuizResults([]);
    setQuizAnswers([]);
    setCurrentHandIndex(0);
    setCorrectCount(0);
    setSelectedCards(new Set());
    setShowFeedback(false);
    setExpandedHandIndex(null);
    setWeakSpotsMode(false);
  };

  // Hand Analyzer functions
  const toggleAnalyzerCard = (card) => {
    const cardIndex = analyzerHand.findIndex(c => c.rank === card.rank && c.suit === card.suit);
    if (cardIndex >= 0) {
      // Remove card
      setAnalyzerHand(prev => prev.filter((_, i) => i !== cardIndex));
      setAnalyzerResults(null);
    } else if (analyzerHand.length < 5) {
      // Add card
      setAnalyzerHand(prev => [...prev, card]);
      setAnalyzerResults(null);
    }
  };

  const isCardSelected = (card) => {
    return analyzerHand.some(c => c.rank === card.rank && c.suit === card.suit);
  };

  const analyzeHand = async () => {
    if (analyzerHand.length !== 5) return;
    setAnalyzerLoading(true);
    setAnalyzerResults(null);

    // Use analyzerPaytable for lookup
    const key = handToCanonicalKey(analyzerHand);
    const { data, error } = await supabaseClient
      .from('strategy')
      .select('best_hold, best_ev, hold_evs')
      .eq('paytable_id', analyzerPaytable)
      .eq('hand_key', key)
      .single();

    if (error || !data) {
      setAnalyzerResults([]);
      setAnalyzerLoading(false);
      return;
    }

    const sorted = [...analyzerHand].sort((a, b) => rankValues[a.rank] - rankValues[b.rank]);

    function bitmaskToOriginalIndices(bitmask) {
      const sortedIndices = [];
      for (let i = 0; i < 5; i++) {
        if (bitmask & (1 << i)) sortedIndices.push(i);
      }
      return sortedIndices.map(si => {
        const card = sorted[si];
        return analyzerHand.findIndex(c => c.rank === card.rank && c.suit === card.suit);
      });
    }

    const holdEvs = data.hold_evs || {};
    const sortedHolds = Object.entries(holdEvs)
      .map(([hold, ev]) => ({ hold: parseInt(hold), ev }))
      .sort((a, b) => b.ev - a.ev);

    const results = sortedHolds.map(({ hold, ev }) => {
      const indices = bitmaskToOriginalIndices(hold);
      return {
        holdIndices: indices,
        heldCards: indices.map(idx => analyzerHand[idx]),
        ev: ev
      };
    });

    setAnalyzerResults(results);
    setAnalyzerLoading(false);
  };

  const clearAnalyzer = () => {
    setAnalyzerHand([]);
    setAnalyzerResults(null);
  };

  const goToAnalyzer = () => {
    setScreen('analyzer');
    setAnalyzerHand([]);
    setAnalyzerResults(null);
  };

  const goHome = () => {
    setScreen('home');
    setAnalyzerHand([]);
    setAnalyzerResults(null);
    setWeakSpotsMode(false);
  };

  // Calculate optimal card size for landscape
  const getCardDimensions = () => {
    if (isLandscape && isMobile) {
      // Calculate max height based on vertical space
      // Account for: progress bar (~36), button (~50), padding (~32), held label (~20), feedback area (~60)
      const maxHeightBasedOnVertical = height - 198;

      // Calculate max height based on horizontal space (5 cards + gaps)
      // Available width minus padding (32) and gaps between cards (4 gaps * 12px = 48)
      const availableWidth = width - 80;
      const cardWidthIfFitHorizontally = availableWidth / 5;
      const maxHeightBasedOnHorizontal = cardWidthIfFitHorizontally * (3.5 / 2.5); // Convert width to height using aspect ratio

      // Use the smaller of the two to ensure cards fit both ways
      const cardHeight = Math.min(maxHeightBasedOnVertical, maxHeightBasedOnHorizontal);
      const cardWidth = cardHeight * (2.5 / 3.5);

      return { cardHeight, cardWidth };
    }
    return { cardHeight: undefined, cardWidth: undefined };
  };

  const { cardHeight, cardWidth } = getCardDimensions();

  // Auth loading screen
  if (authLoading) {
    return (
      <SafeAreaView style={[styles.container, styles.authContainer]}>
        <StatusBar style="light" />
        <ActivityIndicator size="large" color="white" />
        <Text style={styles.authLoadingText}>Loading...</Text>
      </SafeAreaView>
    );
  }

  // Auth screen (shown when not logged in)
  if (!session) {
    return (
      <SafeAreaView style={[styles.container, styles.authContainer]}>
        <StatusBar style="light" />
        <View style={styles.authContent}>
          <View style={styles.authHeader}>
            <Text style={styles.authTitle}>Video Poker Trainer</Text>
            <Text style={styles.authSubtitle}>Master perfect strategy</Text>
          </View>

          <View style={styles.authCard}>
            <Text style={styles.authCardTitle}>{isSignUp ? 'Create Account' : 'Sign In'}</Text>
            <Text style={styles.authCardDesc}>
              Track your progress and sync across devices
            </Text>

            <TextInput
              style={styles.authInput}
              placeholder="Email"
              placeholderTextColor="#999"
              value={email}
              onChangeText={setEmail}
              autoCapitalize="none"
              keyboardType="email-address"
            />
            <TextInput
              style={styles.authInput}
              placeholder="Password"
              placeholderTextColor="#999"
              value={password}
              onChangeText={setPassword}
              secureTextEntry
            />

            <TouchableOpacity
              style={styles.emailButton}
              onPress={isSignUp ? signUpWithEmail : signInWithEmail}
            >
              <Text style={styles.emailButtonText}>
                {isSignUp ? 'Sign Up' : 'Sign In'}
              </Text>
            </TouchableOpacity>

            <TouchableOpacity onPress={() => setIsSignUp(!isSignUp)}>
              <Text style={styles.switchAuthText}>
                {isSignUp ? 'Already have an account? Sign In' : "Don't have an account? Sign Up"}
              </Text>
            </TouchableOpacity>

            <View style={styles.authDivider}>
              <View style={styles.authDividerLine} />
              <Text style={styles.authDividerText}>or</Text>
              <View style={styles.authDividerLine} />
            </View>

            <TouchableOpacity
              style={styles.googleButton}
              onPress={signInWithGoogle}
            >
              <Text style={styles.googleButtonText}>Continue with Google</Text>
            </TouchableOpacity>

            {/* DEV ONLY - Remove in production */}
            <TouchableOpacity
              style={styles.devLoginButton}
              onPress={async () => {
                setAuthError(null);
                try {
                  const { error } = await supabaseClient.auth.signInWithPassword({
                    email: 'bhsapcsturnin@gmail.com',
                    password: 'test1234',
                  });
                  if (error) throw error;
                } catch (error) {
                  setAuthError(error.message);
                }
              }}
            >
              <Text style={styles.devLoginButtonText}>Quick Login (Dev)</Text>
            </TouchableOpacity>

            {authError && (
              <Text style={styles.authErrorText}>{authError}</Text>
            )}
          </View>
        </View>
      </SafeAreaView>
    );
  }

  // Home screen
  if (screen === 'home') {
    return (
      <SafeAreaView style={[styles.container, isLandscape && isMobile && styles.containerLandscape]}>
        <StatusBar style="light" hidden={isLandscape && isMobile} />

        {/* User info bar */}
        <View style={styles.userBar}>
          <View style={styles.userInfo}>
            {user?.user_metadata?.avatar_url && (
              <Image
                source={{ uri: user.user_metadata.avatar_url }}
                style={styles.userAvatar}
              />
            )}
            <Text style={styles.userName} numberOfLines={1}>
              {user?.user_metadata?.full_name || user?.email || 'User'}
            </Text>
          </View>
          <TouchableOpacity onPress={signOut} style={styles.signOutButton}>
            <Text style={styles.signOutText}>Sign Out</Text>
          </TouchableOpacity>
        </View>

        <View style={[styles.startContent, isLandscape && isMobile && styles.homeContentLandscape]}>
          <View style={[styles.header, isLandscape && isMobile && styles.headerLandscape]}>
            <Text style={[styles.title, isLandscape && isMobile && styles.titleLandscape]}>Video Poker Trainer</Text>
            <Text style={styles.subtitle}>EV-Based Strategy Training</Text>
          </View>

          {/* Mastery summary */}
          {masteryScores.length > 0 && (
            <TouchableOpacity
              style={styles.masterySummary}
              onPress={() => setScreen('mastery')}
            >
              <Text style={styles.masterySummaryLabel}>Overall Mastery</Text>
              <View style={styles.masteryBarContainer}>
                <View style={[styles.masteryBarFill, { width: `${calculateOverallMastery(masteryScores)}%` }]} />
              </View>
              <Text style={styles.masterySummaryPercent}>
                {calculateOverallMastery(masteryScores).toFixed(0)}%
              </Text>
            </TouchableOpacity>
          )}

          <View style={[styles.homeButtons, isLandscape && isMobile && styles.homeButtonsLandscape]}>
            <TouchableOpacity
              style={[styles.homeButton, styles.homeButtonQuiz]}
              onPress={() => {
                playSound(SOUNDS.BUTTON_TAP);
                triggerHaptic(HAPTIC_TYPES.LIGHT);
                setScreen('start');
              }}
            >
              <Text style={styles.homeButtonIcon}>🎯</Text>
              <Text style={styles.homeButtonTitle}>Quiz Mode</Text>
              <Text style={styles.homeButtonDesc}>Test your strategy knowledge</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.homeButton, styles.homeButtonWeakSpots]}
              onPress={() => {
                playSound(SOUNDS.BUTTON_TAP);
                triggerHaptic(HAPTIC_TYPES.LIGHT);
                setWeakSpotsMode(true);
                setScreen('start');
              }}
            >
              <Text style={styles.homeButtonIcon}>🔥</Text>
              <Text style={styles.homeButtonTitle}>Weak Spots</Text>
              <Text style={styles.homeButtonDesc}>Focus on problem areas</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.homeButton, styles.homeButtonMastery]}
              onPress={() => {
                playSound(SOUNDS.BUTTON_TAP);
                triggerHaptic(HAPTIC_TYPES.LIGHT);
                setScreen('mastery');
              }}
            >
              <Text style={styles.homeButtonIcon}>📊</Text>
              <Text style={styles.homeButtonTitle}>Progress</Text>
              <Text style={styles.homeButtonDesc}>View your mastery levels</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.homeButton, styles.homeButtonAnalyzer]}
              onPress={() => {
                playSound(SOUNDS.BUTTON_TAP);
                triggerHaptic(HAPTIC_TYPES.LIGHT);
                goToAnalyzer();
              }}
            >
              <Text style={styles.homeButtonIcon}>🔍</Text>
              <Text style={styles.homeButtonTitle}>Hand Analyzer</Text>
              <Text style={styles.homeButtonDesc}>See optimal plays for any hand</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.homeButton, styles.homeButtonSettings]}
              onPress={() => {
                playSound(SOUNDS.BUTTON_TAP);
                triggerHaptic(HAPTIC_TYPES.LIGHT);
                setScreen('settings');
              }}
            >
              <Text style={styles.homeButtonIcon}>⚙️</Text>
              <Text style={styles.homeButtonTitle}>Settings</Text>
              <Text style={styles.homeButtonDesc}>Sound & haptic preferences</Text>
            </TouchableOpacity>
          </View>
        </View>
      </SafeAreaView>
    );
  }

  // Start screen (Quiz setup)
  if (screen === 'start') {
    return (
      <SafeAreaView style={[styles.container, isLandscape && isMobile && styles.containerLandscape]}>
        <StatusBar style="light" hidden={isLandscape && isMobile} />
        <View style={[styles.startContent, isLandscape && isMobile && styles.startContentLandscape]}>
          <View style={[styles.header, isLandscape && isMobile && styles.headerLandscape]}>
            <Text style={[styles.title, isLandscape && isMobile && styles.titleLandscape]}>Video Poker Trainer</Text>
            <Text style={styles.subtitle}>EV-Based Strategy Training</Text>
          </View>

          <View style={[styles.whiteCard, isLandscape && isMobile && styles.whiteCardLandscape]}>
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
            {!isLandscape && <Text style={styles.hint}>Focuses on hands where top plays have similar EVs</Text>}

            <TouchableOpacity
              style={styles.button}
              onPress={prepareQuiz}
            >
              <Text style={styles.buttonText}>Start 25-Hand Quiz</Text>
            </TouchableOpacity>

            {Platform.OS === 'web' && (
              <Text style={styles.hint}>
                Keyboard: 1-5 or D F J K L to toggle cards, Enter/Space to submit
              </Text>
            )}

            <TouchableOpacity style={styles.backLink} onPress={goHome}>
              <Text style={styles.backLinkText}>← Back to Menu</Text>
            </TouchableOpacity>
          </View>
        </View>
      </SafeAreaView>
    );
  }

  // Loading screen
  if (screen === 'loading') {
    return (
      <SafeAreaView style={[styles.container, isLandscape && isMobile && styles.containerLandscape]}>
        <StatusBar style="light" hidden={isLandscape && isMobile} />
        <View style={styles.loadingContent}>
          <View style={styles.whiteCard}>
            <View style={styles.spinner} />
            <Text style={styles.loadingText}>{loadingText}</Text>
          </View>
        </View>
      </SafeAreaView>
    );
  }

  // Quiz screen - optimized for landscape
  if (screen === 'quiz') {
    const hand = quizHands[currentHandIndex];
    const results = quizResults[currentHandIndex];

    return (
      <SafeAreaView style={[styles.container, isLandscape && isMobile && styles.containerLandscape]}>
        <StatusBar style="light" hidden={isLandscape && isMobile} />

        {/* Compact progress bar */}
        <View style={[styles.progressBar, isLandscape && isMobile && styles.progressBarLandscape]}>
          <View style={styles.progressRow}>
            <Text style={styles.progressText}>
              {currentHandIndex + 1}/{QUIZ_SIZE}
            </Text>
            <View style={[styles.progressTrack, isLandscape && isMobile && styles.progressTrackLandscape]}>
              <View style={[styles.progressFill, { width: `${(currentHandIndex / QUIZ_SIZE) * 100}%` }]} />
            </View>
            <Text style={styles.progressText}>
              Score: {correctCount}
            </Text>
          </View>
        </View>

        {/* Game area */}
        <View style={[styles.gameArea, isLandscape && isMobile && styles.gameAreaLandscape]}>
          {/* Cards */}
          <View style={[styles.cardsContainer, isLandscape && isMobile && styles.cardsContainerLandscape]}>
            {hand.map((card, index) => (
              <Card
                key={index}
                card={card}
                selected={selectedCards.has(index)}
                onPress={() => toggleCard(index)}
                disabled={showFeedback}
                isLandscape={isLandscape && isMobile}
                cardHeight={cardHeight}
                cardWidth={cardWidth}
              />
            ))}
          </View>

          {/* Feedback overlay - compact for landscape */}
          {showFeedback && (
            <View style={[
              styles.feedback,
              isCorrect ? styles.feedbackCorrect : styles.feedbackIncorrect,
              isLandscape && isMobile && styles.feedbackLandscape
            ]}>
              <Text style={[styles.feedbackTitle, isCorrect ? styles.textGreen : styles.textRed]}>
                {isCorrect ? '✓ Correct!' : '✗ Incorrect'}
              </Text>
              <Text style={styles.feedbackText}>
                Best: {results[0].heldCards.length === 0 ? 'Discard all' :
                  results[0].heldCards.map(c => `${c.rank}${suitSymbols[c.suit]}`).join(' ')}
                {' '}(EV: {results[0].ev.toFixed(4)})
              </Text>
              {results.length > 1 && !isLandscape && (
                <Text style={styles.feedbackText}>
                  2nd best EV: {results[1].ev.toFixed(4)} (gap: {(results[0].ev - results[1].ev).toFixed(4)})
                </Text>
              )}
            </View>
          )}

          {/* Action button */}
          {!showFeedback ? (
            <TouchableOpacity
              style={[styles.button, isLandscape && isMobile && styles.buttonLandscape]}
              onPress={submitAnswer}
            >
              <Text style={styles.buttonText}>Submit</Text>
            </TouchableOpacity>
          ) : (
            <TouchableOpacity
              style={[styles.button, styles.buttonNext, isLandscape && isMobile && styles.buttonLandscape]}
              onPress={nextHand}
            >
              <Text style={styles.buttonText}>
                {currentHandIndex + 1 >= QUIZ_SIZE ? 'See Results' : 'Next'}
              </Text>
            </TouchableOpacity>
          )}
        </View>
      </SafeAreaView>
    );
  }

  // Results screen
  if (screen === 'results') {
    return (
      <SafeAreaView style={[styles.container, isLandscape && isMobile && styles.containerLandscape]}>
        <StatusBar style="light" hidden={isLandscape && isMobile} />
        <ScrollView
          style={styles.resultsScroll}
          contentContainerStyle={[styles.resultsContent, isLandscape && isMobile && styles.resultsContentLandscape]}
        >
          <View style={[styles.resultsHeader, isLandscape && isMobile && styles.resultsHeaderLandscape]}>
            <Text style={[styles.title, isLandscape && isMobile && styles.titleLandscape]}>Quiz Complete!</Text>
            <Text style={[styles.finalScore, isLandscape && isMobile && styles.finalScoreLandscape]}>{correctCount} / {QUIZ_SIZE}</Text>
            <Text style={styles.percentage}>{Math.round((correctCount / QUIZ_SIZE) * 100)}%</Text>
          </View>

          <View style={[styles.reviewSection, isLandscape && isMobile && styles.reviewSectionLandscape]}>
            {quizAnswers.map((answer, index) => (
              <TouchableOpacity
                key={index}
                style={[styles.reviewItem, answer.isCorrect ? styles.reviewCorrect : styles.reviewIncorrect]}
                onPress={() => setExpandedHandIndex(expandedHandIndex === index ? null : index)}
                activeOpacity={0.7}
              >
                <View style={styles.reviewHeader}>
                  <Text style={styles.reviewTitle}>Hand {index + 1}</Text>
                  <Text style={styles.expandIcon}>{expandedHandIndex === index ? '▼' : '▶'}</Text>
                </View>
                <ColoredCardList cards={answer.hand} style={styles.reviewCards} />
                <Text style={styles.reviewText}>
                  Your hold: {answer.userHold.length === 0 ? 'Discard all' : ''}
                </Text>
                {answer.userHold.length > 0 && (
                  <ColoredCardList
                    cards={answer.userHold.map(i => answer.hand[i])}
                    style={styles.reviewText}
                  />
                )}
                {!answer.isCorrect && (
                  <View>
                    <Text style={[styles.reviewText, styles.textRed]}>
                      Correct: {answer.correctHold.length === 0 ? 'Discard all' : ''}
                    </Text>
                    {answer.correctHold.length > 0 && (
                      <ColoredCardList
                        cards={answer.correctHold.map(i => answer.hand[i])}
                        style={[styles.reviewText, styles.textRed]}
                      />
                    )}
                  </View>
                )}

                {expandedHandIndex === index && answer.allHolds && (
                  <View style={styles.allHoldsSection}>
                    <Text style={styles.allHoldsTitle}>All Options (sorted by EV):</Text>
                    {answer.allHolds.slice(0, 10).map((hold, hi) => (
                      <View key={hi} style={styles.holdRow}>
                        <Text style={styles.holdEv}>{hold.ev.toFixed(4)}</Text>
                        <Text style={styles.holdCards}>
                          {hold.heldCards.length === 0 ? (
                            <Text style={styles.discardText}>Discard all</Text>
                          ) : (
                            hold.heldCards.map((c, ci) => (
                              <Text key={ci}>
                                {ci > 0 && ' '}
                                <Text style={{ color: suitColors[c.suit] }}>
                                  {c.rank}{suitSymbols[c.suit]}
                                </Text>
                              </Text>
                            ))
                          )}
                        </Text>
                      </View>
                    ))}
                    {answer.allHolds.length > 10 && (
                      <Text style={styles.moreText}>...and {answer.allHolds.length - 10} more options</Text>
                    )}
                  </View>
                )}
              </TouchableOpacity>
            ))}
          </View>

          <TouchableOpacity style={[styles.button, isLandscape && isMobile && styles.buttonLandscape]} onPress={resetQuiz}>
            <Text style={styles.buttonText}>Play Again</Text>
          </TouchableOpacity>
        </ScrollView>
      </SafeAreaView>
    );
  }

  // Mastery Dashboard screen
  if (screen === 'mastery') {
    const sortedCategories = getCategoriesByPriority(masteryScores);
    const overallMastery = calculateOverallMastery(masteryScores);
    const masteryLevel = getMasteryLevel(overallMastery);

    // Get all possible categories and merge with existing scores
    const allCategories = Object.keys(HAND_CATEGORIES).map(key => {
      const categoryId = HAND_CATEGORIES[key];
      const existing = masteryScores.find(s => s.category === categoryId);
      return {
        category: categoryId,
        name: CATEGORY_NAMES[categoryId],
        color: CATEGORY_COLORS[categoryId],
        mastery_score: existing?.mastery_score || 0,
        total_attempts: existing?.total_attempts || 0,
        correct_attempts: existing?.correct_attempts || 0,
        next_review_at: existing?.next_review_at,
      };
    });

    return (
      <SafeAreaView style={[styles.container, isLandscape && isMobile && styles.containerLandscape]}>
        <StatusBar style="light" hidden={isLandscape && isMobile} />
        <ScrollView style={styles.masteryScroll} contentContainerStyle={styles.masteryContent}>
          {/* Header */}
          <View style={styles.masteryHeader}>
            <TouchableOpacity onPress={goHome} style={styles.backButton}>
              <Text style={styles.backButtonText}>← Menu</Text>
            </TouchableOpacity>
            <Text style={styles.masteryTitle}>Progress Dashboard</Text>
            <View style={{ width: 70 }} />
          </View>

          {/* Overall mastery card */}
          <View style={styles.overallMasteryCard}>
            <Text style={styles.overallMasteryLabel}>Overall Mastery</Text>
            <Text style={[styles.overallMasteryPercent, { color: masteryLevel.color }]}>
              {overallMastery.toFixed(0)}%
            </Text>
            <Text style={[styles.overallMasteryLevel, { color: masteryLevel.color }]}>
              {masteryLevel.label}
            </Text>
            <View style={styles.overallMasteryBar}>
              <View style={[styles.overallMasteryBarFill, { width: `${overallMastery}%`, backgroundColor: masteryLevel.color }]} />
            </View>
            <Text style={styles.overallMasteryStats}>
              {masteryScores.reduce((sum, s) => sum + (s.total_attempts || 0), 0)} hands practiced
            </Text>
          </View>

          {/* Category breakdown */}
          <Text style={styles.categorySectionTitle}>Category Breakdown</Text>
          <View style={styles.categoryList}>
            {allCategories.map((cat, index) => {
              const level = getMasteryLevel(cat.mastery_score);
              const isDue = !cat.next_review_at || new Date(cat.next_review_at) <= new Date();

              return (
                <View key={cat.category} style={styles.categoryItem}>
                  <View style={styles.categoryHeader}>
                    <View style={[styles.categoryIndicator, { backgroundColor: cat.color }]} />
                    <Text style={styles.categoryName} numberOfLines={1}>{cat.name}</Text>
                    {isDue && cat.total_attempts > 0 && (
                      <View style={styles.dueTag}>
                        <Text style={styles.dueTagText}>Due</Text>
                      </View>
                    )}
                  </View>
                  <View style={styles.categoryStats}>
                    <View style={styles.categoryBarContainer}>
                      <View style={[styles.categoryBarFill, { width: `${cat.mastery_score}%`, backgroundColor: level.color }]} />
                    </View>
                    <Text style={styles.categoryPercent}>{cat.mastery_score.toFixed(0)}%</Text>
                  </View>
                  <Text style={styles.categoryAttempts}>
                    {cat.total_attempts > 0
                      ? `${cat.correct_attempts}/${cat.total_attempts} correct`
                      : 'Not practiced yet'}
                  </Text>
                </View>
              );
            })}
          </View>

          {/* Action buttons */}
          <TouchableOpacity
            style={[styles.button, styles.weakSpotsButton]}
            onPress={() => {
              setWeakSpotsMode(true);
              setScreen('start');
            }}
          >
            <Text style={styles.buttonText}>Practice Weak Spots</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.button, { marginTop: 12 }]}
            onPress={() => setScreen('start')}
          >
            <Text style={styles.buttonText}>Start Regular Quiz</Text>
          </TouchableOpacity>
        </ScrollView>
      </SafeAreaView>
    );
  }

  // Hand Analyzer screen
  if (screen === 'analyzer') {
    return (
      <SafeAreaView style={[styles.container, isLandscape && isMobile && styles.containerLandscape]}>
        <StatusBar style="light" hidden={isLandscape && isMobile} />

        {/* Header row */}
        <View style={styles.analyzerHeaderRow}>
          <TouchableOpacity onPress={goHome} style={styles.backButton}>
            <Text style={styles.backButtonText}>← Menu</Text>
          </TouchableOpacity>

          {/* Selected cards display */}
          <View style={styles.selectedHandRow}>
            {analyzerHand.map((card, i) => (
              <View key={i} style={styles.selectedCardMini}>
                <Text style={[styles.selectedCardText, { color: suitColors[card.suit] }]}>
                  {card.rank === '10' ? 'T' : card.rank}{suitSymbols[card.suit]}
                </Text>
              </View>
            ))}
            {Array(5 - analyzerHand.length).fill(null).map((_, i) => (
              <View key={`empty-${i}`} style={styles.selectedCardEmpty}>
                <Text style={styles.selectedCardEmptyText}>?</Text>
              </View>
            ))}
          </View>

          <View style={styles.analyzerHeaderRight}>
            {analyzerHand.length > 0 && (
              <TouchableOpacity onPress={clearAnalyzer}>
                <Text style={styles.clearText}>Clear</Text>
              </TouchableOpacity>
            )}
          </View>
        </View>

        {/* Full-screen Card grid - 4 rows (suits) x 13 columns (ranks) */}
        <View style={styles.cardGridFull}>
          {suits.map(suit => (
            <View key={suit} style={styles.cardGridRowFull}>
              {ranks.map(rank => {
                const card = { rank, suit };
                const selected = isCardSelected(card);
                const disabled = !selected && analyzerHand.length >= 5;
                return (
                  <TouchableOpacity
                    key={`${rank}-${suit}`}
                    style={[
                      styles.gridCardFull,
                      selected && styles.gridCardSelected,
                      disabled && styles.gridCardDisabled,
                    ]}
                    onPress={() => toggleAnalyzerCard(card)}
                    disabled={disabled}
                  >
                    <Text style={[
                      styles.gridCardTextFull,
                      { color: suitColors[suit] },
                      selected && styles.gridCardTextSelected,
                    ]}>
                      {rank === '10' ? 'T' : rank}{suitSymbols[suit]}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          ))}
        </View>

        {/* Bottom bar: Paytable + Analyze button */}
        <View style={styles.analyzerBottomBar}>
          <View style={styles.analyzerPaytableCompact}>
            <Picker
              selectedValue={analyzerPaytable}
              onValueChange={setAnalyzerPaytable}
              style={styles.pickerCompact}
            >
              {PAYTABLES.map(p => (
                <Picker.Item key={p.id} label={p.name} value={p.id} />
              ))}
            </Picker>
          </View>

          <TouchableOpacity
            style={[
              styles.analyzeButtonCompact,
              analyzerHand.length !== 5 && styles.analyzeButtonDisabled
            ]}
            onPress={analyzeHand}
            disabled={analyzerHand.length !== 5}
          >
            <Text style={styles.analyzeButtonText}>
              {analyzerLoading ? 'Analyzing...' : 'Analyze'}
            </Text>
          </TouchableOpacity>
        </View>

        {/* Results overlay */}
        {analyzerResults && analyzerResults.length > 0 && (
          <View style={styles.resultsOverlay}>
            <View style={styles.resultsOverlayContent}>
              <View style={styles.resultsOverlayHeader}>
                <Text style={styles.resultsOverlayTitle}>
                  Hold: {analyzerResults[0].heldCards.length === 0 ? 'Discard all' :
                    analyzerResults[0].heldCards.map(c => `${c.rank}${suitSymbols[c.suit]}`).join(' ')}
                </Text>
                <Text style={styles.resultsOverlayEv}>EV: {analyzerResults[0].ev.toFixed(4)}</Text>
                <TouchableOpacity onPress={() => setAnalyzerResults(null)} style={styles.closeButton}>
                  <Text style={styles.closeButtonText}>✕</Text>
                </TouchableOpacity>
              </View>
              <ScrollView style={styles.resultsOverlayScroll} horizontal>
                {analyzerResults.slice(0, 10).map((hold, i) => (
                  <View key={i} style={[styles.resultCard, i === 0 && styles.resultCardBest]}>
                    <Text style={styles.resultCardEv}>{hold.ev.toFixed(4)}</Text>
                    <Text style={styles.resultCardHold}>
                      {hold.heldCards.length === 0 ? 'Discard' :
                        hold.heldCards.map(c => `${c.rank}${suitSymbols[c.suit]}`).join(' ')}
                    </Text>
                  </View>
                ))}
              </ScrollView>
            </View>
          </View>
        )}
      </SafeAreaView>
    );
  }

  // Settings screen
  if (screen === 'settings') {
    return (
      <SafeAreaView style={[styles.container, isLandscape && isMobile && styles.containerLandscape]}>
        <StatusBar style="light" hidden={isLandscape && isMobile} />
        <ScrollView style={styles.settingsScroll} contentContainerStyle={styles.settingsContent}>
          <View style={styles.settingsHeader}>
            <TouchableOpacity
              onPress={() => {
                playSound(SOUNDS.BUTTON_TAP);
                triggerHaptic(HAPTIC_TYPES.LIGHT);
                goHome();
              }}
              style={styles.backButton}
            >
              <Text style={styles.backButtonText}>← Back</Text>
            </TouchableOpacity>
            <Text style={styles.settingsTitle}>Settings</Text>
            <View style={styles.backButton} />
          </View>

          <View style={styles.settingsCard}>
            <Text style={styles.settingsCardTitle}>Sound & Haptics</Text>

            <View style={styles.settingRow}>
              <View style={styles.settingInfo}>
                <Text style={styles.settingLabel}>Sound Effects</Text>
                <Text style={styles.settingDesc}>Play sounds for actions</Text>
              </View>
              <Switch
                value={soundEnabled}
                onValueChange={(value) => {
                  setSoundEnabled(value);
                  if (value) {
                    playSound(SOUNDS.BUTTON_TAP);
                  }
                  triggerHaptic(HAPTIC_TYPES.LIGHT);
                }}
                trackColor={{ false: '#ccc', true: '#667eea' }}
                thumbColor={soundEnabled ? '#fff' : '#f4f3f4'}
              />
            </View>

            {soundEnabled && (
              <View style={styles.settingRow}>
                <View style={styles.settingInfo}>
                  <Text style={styles.settingLabel}>Volume</Text>
                  <Text style={styles.settingDesc}>{Math.round(soundVolume * 100)}%</Text>
                </View>
                <View style={styles.volumeSlider}>
                  <TouchableOpacity
                    onPress={() => {
                      const newVol = Math.max(0, soundVolume - 0.1);
                      setSoundVolume(newVol);
                      triggerHaptic(HAPTIC_TYPES.LIGHT);
                    }}
                    style={styles.volumeButton}
                  >
                    <Text style={styles.volumeButtonText}>-</Text>
                  </TouchableOpacity>
                  <View style={styles.volumeBar}>
                    <View style={[styles.volumeFill, { width: `${soundVolume * 100}%` }]} />
                  </View>
                  <TouchableOpacity
                    onPress={() => {
                      const newVol = Math.min(1, soundVolume + 0.1);
                      setSoundVolume(newVol);
                      playSound(SOUNDS.BUTTON_TAP);
                      triggerHaptic(HAPTIC_TYPES.LIGHT);
                    }}
                    style={styles.volumeButton}
                  >
                    <Text style={styles.volumeButtonText}>+</Text>
                  </TouchableOpacity>
                </View>
              </View>
            )}

            {Platform.OS !== 'web' && (
              <View style={styles.settingRow}>
                <View style={styles.settingInfo}>
                  <Text style={styles.settingLabel}>Haptic Feedback</Text>
                  <Text style={styles.settingDesc}>Vibration on interactions</Text>
                </View>
                <Switch
                  value={hapticsEnabled}
                  onValueChange={(value) => {
                    setHapticsEnabled(value);
                    if (value) {
                      triggerHaptic(HAPTIC_TYPES.SUCCESS);
                    }
                  }}
                  trackColor={{ false: '#ccc', true: '#667eea' }}
                  thumbColor={hapticsEnabled ? '#fff' : '#f4f3f4'}
                />
              </View>
            )}

            <TouchableOpacity
              style={styles.resetButton}
              onPress={() => {
                playSound(SOUNDS.BUTTON_TAP);
                triggerHaptic(HAPTIC_TYPES.MEDIUM);
                setSoundEnabled(true);
                setSoundVolume(0.7);
                setHapticsEnabled(true);
              }}
            >
              <Text style={styles.resetButtonText}>Reset to Defaults</Text>
            </TouchableOpacity>
          </View>

          <View style={styles.settingsCard}>
            <Text style={styles.settingsCardTitle}>About</Text>
            <Text style={styles.aboutText}>Video Poker Trainer v1.0</Text>
            <Text style={styles.aboutText}>EV-Based Strategy Training</Text>
          </View>
        </ScrollView>
      </SafeAreaView>
    );
  }

  return null;
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#667eea',
    padding: 16,
    paddingTop: Platform.OS === 'ios' ? 50 : 16,
  },
  containerLandscape: {
    paddingTop: 8,
    paddingBottom: 8,
    paddingHorizontal: 16,
  },
  startContent: {
    flex: 1,
    justifyContent: 'center',
  },
  startContentLandscape: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 24,
  },
  homeContentLandscape: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 40,
  },
  homeButtons: {
    gap: 16,
  },
  homeButtonsLandscape: {
    flexDirection: 'row',
    gap: 20,
  },
  homeButton: {
    backgroundColor: 'white',
    borderRadius: 16,
    padding: 24,
    alignItems: 'center',
    boxShadow: '0px 2px 8px rgba(0, 0, 0, 0.1)',
    elevation: 4,
    minWidth: 200,
  },
  homeButtonQuiz: {
    borderBottomWidth: 4,
    borderBottomColor: '#667eea',
  },
  homeButtonAnalyzer: {
    borderBottomWidth: 4,
    borderBottomColor: '#27ae60',
  },
  homeButtonIcon: {
    fontSize: 40,
    marginBottom: 12,
  },
  homeButtonTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 4,
  },
  homeButtonDesc: {
    fontSize: 14,
    color: '#666',
    textAlign: 'center',
  },
  backLink: {
    marginTop: 16,
    alignItems: 'center',
  },
  backLinkText: {
    color: '#667eea',
    fontSize: 16,
  },
  header: {
    alignItems: 'center',
    marginBottom: 20,
  },
  headerLandscape: {
    marginBottom: 0,
    flex: 1,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: 'white',
    marginBottom: 8,
  },
  titleLandscape: {
    fontSize: 24,
  },
  subtitle: {
    fontSize: 16,
    color: 'rgba(255,255,255,0.8)',
  },
  whiteCard: {
    backgroundColor: 'white',
    borderRadius: 16,
    padding: 20,
    boxShadow: '0px 2px 8px rgba(0, 0, 0, 0.1)',
    elevation: 4,
  },
  whiteCardLandscape: {
    flex: 1.5,
    padding: 16,
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
    height: Platform.OS === 'ios' ? 120 : 50,
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
  buttonLandscape: {
    marginTop: 8,
    paddingVertical: 12,
  },
  buttonNext: {
    backgroundColor: '#3498db',
  },
  buttonText: {
    color: 'white',
    fontSize: 18,
    fontWeight: 'bold',
  },
  loadingContent: {
    flex: 1,
    justifyContent: 'center',
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
    marginBottom: 12,
  },
  progressBarLandscape: {
    padding: 6,
    marginBottom: 6,
    borderRadius: 8,
  },
  progressRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  progressText: {
    fontSize: 14,
    color: '#666',
    fontWeight: '600',
  },
  progressTrack: {
    flex: 1,
    height: 8,
    backgroundColor: '#e0e0e0',
    borderRadius: 4,
    marginHorizontal: 12,
    overflow: 'hidden',
  },
  progressTrackLandscape: {
    height: 6,
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
  gameAreaLandscape: {
    padding: 8,
    borderRadius: 12,
  },
  cardsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  cardsContainerLandscape: {
    justifyContent: 'center',
    marginBottom: 8,
    flex: 1,
  },
  cardWrapper: {
    flex: 1,
    marginHorizontal: 2,
    alignItems: 'center',
  },
  cardWrapperLandscape: {
    flex: 0,
    marginHorizontal: 6,
  },
  cardBox: {
    backgroundColor: 'white',
    borderRadius: 8,
    aspectRatio: 2.5 / 3.5,
    width: '100%',
    alignItems: 'center',
    justifyContent: 'center',
    boxShadow: '0px 2px 4px rgba(0, 0, 0, 0.3)',
    elevation: 4,
    overflow: 'hidden',
  },
  cardSelected: {
    transform: [{ translateY: -10 }],
    borderWidth: 3,
    borderColor: '#ffd700',
    boxShadow: '0px 0px 8px rgba(255, 215, 0, 0.6)',
  },
  cardImage: {
    width: '100%',
    height: '100%',
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
  heldLabelLandscape: {
    fontSize: 9,
    paddingHorizontal: 4,
    paddingVertical: 1,
    marginTop: 2,
  },
  feedback: {
    backgroundColor: 'rgba(255,255,255,0.95)',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
  },
  feedbackLandscape: {
    padding: 8,
    marginBottom: 8,
    borderRadius: 8,
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
    marginBottom: 4,
  },
  feedbackText: {
    fontSize: 14,
    color: '#666',
  },
  textGreen: {
    color: '#2ecc71',
  },
  textRed: {
    color: '#e74c3c',
  },
  resultsScroll: {
    flex: 1,
  },
  resultsContent: {
    paddingBottom: 40,
  },
  resultsContentLandscape: {
    paddingBottom: 20,
  },
  resultsHeader: {
    alignItems: 'center',
    marginBottom: 24,
  },
  resultsHeaderLandscape: {
    marginBottom: 12,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'baseline',
    gap: 16,
  },
  finalScore: {
    fontSize: 48,
    fontWeight: 'bold',
    color: 'white',
    marginTop: 16,
  },
  finalScoreLandscape: {
    fontSize: 32,
    marginTop: 0,
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
  reviewSectionLandscape: {
    padding: 12,
    marginBottom: 12,
    borderRadius: 12,
  },
  reviewItem: {
    padding: 12,
    borderRadius: 8,
    marginBottom: 8,
    backgroundColor: '#f5f5f5',
  },
  reviewHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  expandIcon: {
    fontSize: 12,
    color: '#666',
  },
  allHoldsSection: {
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#ddd',
  },
  allHoldsTitle: {
    fontWeight: 'bold',
    marginBottom: 8,
    color: '#333',
  },
  holdRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 4,
  },
  holdEv: {
    width: 70,
    fontSize: 13,
    color: '#666',
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
  },
  holdCards: {
    flex: 1,
    fontSize: 14,
  },
  discardText: {
    fontStyle: 'italic',
    color: '#888',
  },
  moreText: {
    fontStyle: 'italic',
    color: '#888',
    marginTop: 4,
    fontSize: 12,
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
  // Analyzer styles
  analyzerHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 6,
  },
  analyzerHeaderRight: {
    minWidth: 60,
    alignItems: 'flex-end',
  },
  clearText: {
    color: '#ff6b6b',
    fontSize: 16,
    fontWeight: 'bold',
  },
  selectedHandRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 6,
  },
  selectedCardMini: {
    backgroundColor: 'white',
    borderRadius: 6,
    paddingVertical: 4,
    paddingHorizontal: 8,
    minWidth: 36,
    alignItems: 'center',
  },
  selectedCardEmpty: {
    backgroundColor: 'rgba(255,255,255,0.3)',
    borderRadius: 6,
    paddingVertical: 4,
    paddingHorizontal: 8,
    minWidth: 36,
    alignItems: 'center',
  },
  selectedCardText: {
    fontSize: 14,
    fontWeight: 'bold',
  },
  selectedCardEmptyText: {
    fontSize: 14,
    fontWeight: 'bold',
    color: 'rgba(255,255,255,0.5)',
  },
  cardGridFull: {
    flex: 1,
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 8,
    justifyContent: 'space-around',
  },
  cardGridRowFull: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 4,
    marginVertical: 2,
  },
  gridCardFull: {
    flex: 1,
    backgroundColor: '#f0f0f0',
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: '#ddd',
  },
  gridCardSelected: {
    backgroundColor: '#ffd700',
    borderColor: '#d4a800',
    borderWidth: 3,
  },
  gridCardDisabled: {
    opacity: 0.35,
  },
  gridCardTextFull: {
    fontSize: 18,
    fontWeight: 'bold',
  },
  gridCardTextSelected: {
    color: '#333',
  },
  analyzerBottomBar: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 6,
    gap: 12,
  },
  analyzerPaytableCompact: {
    flex: 1,
    backgroundColor: 'white',
    borderRadius: 8,
    overflow: 'hidden',
  },
  pickerCompact: {
    height: Platform.OS === 'ios' ? 120 : 40,
  },
  analyzeButtonCompact: {
    backgroundColor: '#27ae60',
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 20,
  },
  analyzeButtonDisabled: {
    backgroundColor: '#95a5a6',
  },
  analyzeButtonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: 'bold',
  },
  resultsOverlay: {
    position: 'absolute',
    bottom: 80,
    left: 16,
    right: 16,
    backgroundColor: 'rgba(0,0,0,0.9)',
    borderRadius: 12,
    padding: 12,
  },
  resultsOverlayContent: {
  },
  resultsOverlayHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  resultsOverlayTitle: {
    color: '#2ecc71',
    fontSize: 18,
    fontWeight: 'bold',
    flex: 1,
  },
  resultsOverlayEv: {
    color: 'white',
    fontSize: 16,
    marginRight: 12,
  },
  closeButton: {
    padding: 4,
  },
  closeButtonText: {
    color: 'white',
    fontSize: 20,
  },
  resultsOverlayScroll: {
  },
  resultCard: {
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderRadius: 8,
    padding: 8,
    marginRight: 8,
    minWidth: 80,
    alignItems: 'center',
  },
  resultCardBest: {
    backgroundColor: 'rgba(46,204,113,0.3)',
    borderWidth: 1,
    borderColor: '#2ecc71',
  },
  resultCardEv: {
    color: 'white',
    fontSize: 12,
    fontWeight: 'bold',
  },
  resultCardHold: {
    color: 'rgba(255,255,255,0.8)',
    fontSize: 11,
    marginTop: 2,
  },
  backButton: {
    minWidth: 70,
  },
  backButtonText: {
    color: 'white',
    fontSize: 16,
  },
  holdEvBest: {
    color: '#27ae60',
    fontWeight: 'bold',
  },
  // Auth styles
  authContainer: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  authLoadingText: {
    color: 'white',
    fontSize: 16,
    marginTop: 16,
  },
  authContent: {
    width: '100%',
    maxWidth: 400,
    padding: 20,
  },
  authHeader: {
    alignItems: 'center',
    marginBottom: 32,
  },
  authTitle: {
    fontSize: 32,
    fontWeight: 'bold',
    color: 'white',
    marginBottom: 8,
    textAlign: 'center',
  },
  authSubtitle: {
    fontSize: 18,
    color: 'rgba(255,255,255,0.8)',
    textAlign: 'center',
  },
  authCard: {
    backgroundColor: 'white',
    borderRadius: 16,
    padding: 24,
    boxShadow: '0px 4px 12px rgba(0, 0, 0, 0.15)',
    elevation: 6,
  },
  authCardTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 8,
    textAlign: 'center',
  },
  authCardDesc: {
    fontSize: 14,
    color: '#666',
    textAlign: 'center',
    marginBottom: 24,
  },
  googleButton: {
    backgroundColor: '#4285F4',
    paddingVertical: 14,
    paddingHorizontal: 24,
    borderRadius: 8,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  googleButtonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '600',
  },
  authErrorText: {
    color: '#e74c3c',
    fontSize: 14,
    textAlign: 'center',
    marginTop: 16,
  },
  authInput: {
    backgroundColor: '#f5f5f5',
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    paddingVertical: 12,
    paddingHorizontal: 16,
    fontSize: 16,
    marginBottom: 12,
    color: '#333',
  },
  emailButton: {
    backgroundColor: '#667eea',
    paddingVertical: 14,
    paddingHorizontal: 24,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
  },
  emailButtonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '600',
  },
  switchAuthText: {
    color: '#667eea',
    fontSize: 14,
    textAlign: 'center',
    marginBottom: 16,
  },
  authDivider: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 16,
  },
  authDividerLine: {
    flex: 1,
    height: 1,
    backgroundColor: '#ddd',
  },
  authDividerText: {
    color: '#999',
    paddingHorizontal: 12,
    fontSize: 14,
  },
  devLoginButton: {
    backgroundColor: '#95a5a6',
    paddingVertical: 10,
    paddingHorizontal: 20,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 12,
  },
  devLoginButtonText: {
    color: 'white',
    fontSize: 14,
    fontWeight: '500',
  },
  // User bar styles
  userBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
    paddingHorizontal: 4,
    marginBottom: 8,
  },
  userInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  userAvatar: {
    width: 32,
    height: 32,
    borderRadius: 16,
    marginRight: 10,
    backgroundColor: 'rgba(255,255,255,0.2)',
  },
  userName: {
    color: 'white',
    fontSize: 14,
    fontWeight: '500',
    flex: 1,
  },
  signOutButton: {
    paddingVertical: 6,
    paddingHorizontal: 12,
  },
  signOutText: {
    color: 'rgba(255,255,255,0.8)',
    fontSize: 14,
  },
  // Mastery styles
  masterySummary: {
    backgroundColor: 'rgba(255,255,255,0.15)',
    borderRadius: 12,
    padding: 12,
    marginBottom: 16,
    flexDirection: 'row',
    alignItems: 'center',
  },
  masterySummaryLabel: {
    color: 'white',
    fontSize: 14,
    fontWeight: '600',
    marginRight: 12,
  },
  masteryBarContainer: {
    flex: 1,
    height: 8,
    backgroundColor: 'rgba(255,255,255,0.2)',
    borderRadius: 4,
    overflow: 'hidden',
  },
  masteryBarFill: {
    height: '100%',
    backgroundColor: '#2ecc71',
    borderRadius: 4,
  },
  masterySummaryPercent: {
    color: 'white',
    fontSize: 14,
    fontWeight: 'bold',
    marginLeft: 12,
    minWidth: 40,
    textAlign: 'right',
  },
  homeButtonWeakSpots: {
    borderBottomWidth: 4,
    borderBottomColor: '#e74c3c',
  },
  homeButtonMastery: {
    borderBottomWidth: 4,
    borderBottomColor: '#9b59b6',
  },
  // Mastery Dashboard styles
  masteryScroll: {
    flex: 1,
  },
  masteryContent: {
    padding: 16,
    paddingBottom: 40,
  },
  masteryHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 20,
  },
  masteryTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: 'white',
  },
  overallMasteryCard: {
    backgroundColor: 'white',
    borderRadius: 16,
    padding: 20,
    alignItems: 'center',
    marginBottom: 20,
  },
  overallMasteryLabel: {
    fontSize: 14,
    color: '#666',
    marginBottom: 8,
  },
  overallMasteryPercent: {
    fontSize: 48,
    fontWeight: 'bold',
  },
  overallMasteryLevel: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 12,
  },
  overallMasteryBar: {
    width: '100%',
    height: 8,
    backgroundColor: '#e0e0e0',
    borderRadius: 4,
    overflow: 'hidden',
    marginBottom: 12,
  },
  overallMasteryBarFill: {
    height: '100%',
    borderRadius: 4,
  },
  overallMasteryStats: {
    fontSize: 14,
    color: '#888',
  },
  categorySectionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: 'white',
    marginBottom: 12,
  },
  categoryList: {
    backgroundColor: 'white',
    borderRadius: 16,
    padding: 12,
    marginBottom: 20,
  },
  categoryItem: {
    padding: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  categoryHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  categoryIndicator: {
    width: 12,
    height: 12,
    borderRadius: 6,
    marginRight: 10,
  },
  categoryName: {
    flex: 1,
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
  },
  dueTag: {
    backgroundColor: '#e74c3c',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 10,
  },
  dueTagText: {
    color: 'white',
    fontSize: 10,
    fontWeight: 'bold',
  },
  categoryStats: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
  },
  categoryBarContainer: {
    flex: 1,
    height: 6,
    backgroundColor: '#e0e0e0',
    borderRadius: 3,
    overflow: 'hidden',
    marginRight: 10,
  },
  categoryBarFill: {
    height: '100%',
    borderRadius: 3,
  },
  categoryPercent: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#333',
    minWidth: 40,
    textAlign: 'right',
  },
  categoryAttempts: {
    fontSize: 12,
    color: '#888',
  },
  weakSpotsButton: {
    backgroundColor: '#e74c3c',
  },
  // Settings button style
  homeButtonSettings: {
    borderBottomWidth: 4,
    borderBottomColor: '#95a5a6',
  },
  // Settings screen styles
  settingsScroll: {
    flex: 1,
  },
  settingsContent: {
    padding: 16,
    paddingBottom: 40,
  },
  settingsHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 20,
  },
  settingsTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: 'white',
  },
  settingsCard: {
    backgroundColor: 'white',
    borderRadius: 16,
    padding: 20,
    marginBottom: 16,
  },
  settingsCardTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 16,
  },
  settingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  settingInfo: {
    flex: 1,
    marginRight: 16,
  },
  settingLabel: {
    fontSize: 16,
    color: '#333',
    fontWeight: '500',
  },
  settingDesc: {
    fontSize: 12,
    color: '#888',
    marginTop: 2,
  },
  volumeSlider: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  volumeButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#667eea',
    alignItems: 'center',
    justifyContent: 'center',
  },
  volumeButtonText: {
    color: 'white',
    fontSize: 18,
    fontWeight: 'bold',
  },
  volumeBar: {
    width: 80,
    height: 6,
    backgroundColor: '#e0e0e0',
    borderRadius: 3,
    overflow: 'hidden',
  },
  volumeFill: {
    height: '100%',
    backgroundColor: '#667eea',
    borderRadius: 3,
  },
  resetButton: {
    marginTop: 16,
    paddingVertical: 12,
    paddingHorizontal: 16,
    backgroundColor: '#f0f0f0',
    borderRadius: 8,
    alignItems: 'center',
  },
  resetButtonText: {
    color: '#666',
    fontSize: 14,
    fontWeight: '500',
  },
  aboutText: {
    fontSize: 14,
    color: '#666',
    marginBottom: 4,
  },
});
