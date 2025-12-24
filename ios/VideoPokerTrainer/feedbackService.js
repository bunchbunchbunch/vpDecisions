// feedbackService.js - Sound and Haptic Feedback Module
// Provides audio and haptic feedback for user interactions

import { Audio } from 'expo-av';
import * as Haptics from 'expo-haptics';
import { Platform } from 'react-native';

// Sound key constants
export const SOUNDS = {
  CARD_SELECT: 'card_select',
  SUBMIT: 'submit',
  CORRECT: 'correct',
  INCORRECT: 'incorrect',
  NEXT_HAND: 'next_hand',
  QUIZ_COMPLETE: 'quiz_complete',
  BUTTON_TAP: 'button_tap',
};

// Haptic feedback types
export const HAPTIC_TYPES = {
  LIGHT: 'light',
  MEDIUM: 'medium',
  HEAVY: 'heavy',
  SUCCESS: 'success',
  ERROR: 'error',
  WARNING: 'warning',
};

// Sound asset mappings
const soundAssets = {
  [SOUNDS.CARD_SELECT]: require('./assets/sounds/card-select.mp3'),
  [SOUNDS.SUBMIT]: require('./assets/sounds/submit.mp3'),
  [SOUNDS.CORRECT]: require('./assets/sounds/correct.mp3'),
  [SOUNDS.INCORRECT]: require('./assets/sounds/incorrect.mp3'),
  [SOUNDS.NEXT_HAND]: require('./assets/sounds/next-hand.mp3'),
  [SOUNDS.QUIZ_COMPLETE]: require('./assets/sounds/quiz-complete.mp3'),
  [SOUNDS.BUTTON_TAP]: require('./assets/sounds/button-tap.mp3'),
};

// Loaded sound objects cache
let loadedSounds = {};
let audioInitialized = false;

// Current settings reference (updated by updateFeedbackSettings)
let currentSettings = {
  soundEnabled: true,
  soundVolume: 0.7,
  hapticsEnabled: true,
};

/**
 * Update the feedback settings reference
 * Called by the settings context when settings change
 */
export function updateFeedbackSettings(settings) {
  currentSettings = { ...currentSettings, ...settings };
}

/**
 * Initialize the audio system and preload all sounds
 * Should be called once on app startup
 */
export async function initializeAudio() {
  if (audioInitialized) return;

  try {
    // Configure audio mode
    await Audio.setAudioModeAsync({
      allowsRecordingIOS: false,
      playsInSilentModeIOS: true,
      staysActiveInBackground: false,
      shouldDuckAndroid: true,
    });

    // Preload all sounds for instant playback
    for (const [key, asset] of Object.entries(soundAssets)) {
      try {
        const { sound } = await Audio.Sound.createAsync(asset);
        loadedSounds[key] = sound;
      } catch (err) {
        console.warn(`Failed to load sound ${key}:`, err);
      }
    }

    audioInitialized = true;
    console.log('Audio system initialized successfully');
  } catch (error) {
    console.warn('Audio initialization failed:', error);
  }
}

/**
 * Play a sound effect
 * @param {string} soundKey - One of SOUNDS constants
 */
export async function playSound(soundKey) {
  // Check if sound is enabled
  if (!currentSettings.soundEnabled) return;

  // Check if sound is loaded
  if (!loadedSounds[soundKey]) {
    console.warn(`Sound not loaded: ${soundKey}`);
    return;
  }

  try {
    const sound = loadedSounds[soundKey];

    // Set volume
    await sound.setVolumeAsync(currentSettings.soundVolume);

    // Reset to beginning (in case it was played before)
    await sound.setPositionAsync(0);

    // Play the sound
    await sound.playAsync();
  } catch (error) {
    console.warn(`Sound playback failed for ${soundKey}:`, error);
  }
}

/**
 * Trigger haptic feedback
 * Only works on native platforms (iOS/Android)
 * @param {string} hapticType - One of HAPTIC_TYPES constants
 */
export async function triggerHaptic(hapticType) {
  // Haptics don't work on web
  if (Platform.OS === 'web') return;

  // Check if haptics are enabled
  if (!currentSettings.hapticsEnabled) return;

  try {
    switch (hapticType) {
      case HAPTIC_TYPES.LIGHT:
        await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
        break;
      case HAPTIC_TYPES.MEDIUM:
        await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
        break;
      case HAPTIC_TYPES.HEAVY:
        await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
        break;
      case HAPTIC_TYPES.SUCCESS:
        await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
        break;
      case HAPTIC_TYPES.ERROR:
        await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
        break;
      case HAPTIC_TYPES.WARNING:
        await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
        break;
      default:
        await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    }
  } catch (error) {
    console.warn(`Haptic feedback failed for ${hapticType}:`, error);
  }
}

/**
 * Cleanup audio resources
 * Should be called when app is unmounting
 */
export async function cleanupAudio() {
  for (const sound of Object.values(loadedSounds)) {
    try {
      await sound.unloadAsync();
    } catch (e) {
      // Ignore cleanup errors
    }
  }
  loadedSounds = {};
  audioInitialized = false;
}

/**
 * Check if audio system is initialized
 */
export function isAudioInitialized() {
  return audioInitialized;
}
