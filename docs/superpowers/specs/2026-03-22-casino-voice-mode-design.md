# Casino Voice Mode — Design Spec

**Date:** 2026-03-22
**Status:** Approved

---

## Overview

Casino Voice Mode is a hands-free companion feature for users playing video poker at a real casino. The user selects their game/paytable before sitting down, then sets their phone on the table. By pressing the volume-up button (or using the Action Button shortcut on iPhone 15 Pro+), they open a listening window, speak their 5-card hand, and hear the optimal hold decision spoken back through their headphones.

---

## Use Case

- User is seated at a casino video poker machine
- Phone is set on the table, Casino Mode active, screen dimmed
- User is dealt a hand, presses volume-up button
- Speaks: "ace of spades, king of hearts, queen of diamonds, jack of clubs, ten of spades"
- Hears in headphones: "Four to a royal. Hold the ace, king, queen, jack, and ten."
- Presses again for next hand

---

## Architecture

### New Components

| Component | Type | Responsibility |
|---|---|---|
| `VoiceService` | `@MainActor @Observable` class | Manages `AVAudioEngine` + `SFSpeechRecognizer` session lifecycle, detects volume button press via KVO on `AVAudioSession.outputVolume`, opens/closes listening windows |
| `CardParser` | Struct with static `parse(_:gameFamily:) throws -> [Card]` | Converts raw transcript string → exactly 5 `Card` values. Handles fuzzy normalization and wild-card game awareness. |
| `SpeechSynthesisService` | `@MainActor @Observable` singleton | Wraps `AVSpeechSynthesizer`, routes audio to headphones, exposes `isSpeaking: Bool` for UI, queues and cancels responses |
| `ResponseFormatter` | Struct with static `format(hand:result:gameFamily:) -> String` | Maps `Hand` + `StrategyResult` bitmask + `GameFamily` → natural language response string using spoken-word card names |
| `CasinoModeViewModel` | `@MainActor @Observable` class | Orchestrates full loop: trigger → recognize → parse → strategy lookup (async) → format → speak |

### Existing Components Used

- `StrategyService` — unchanged; called as `await strategyService.lookup(hand:paytableId:)` which is `async throws`; must handle the `.notDownloaded` error path explicitly
- `AudioService` — must be suspended on Casino Mode entry and restored on exit to avoid `AVAudioSession` category conflicts (see Session Conflict below)
- `Hand`, `Card`, `Rank`, `Suit` models — unchanged

### Data Flow

```
Volume button press (KVO on outputVolume, debounced)
  → VoiceService opens 10s listening window
  → SFSpeechRecognizer streams transcript (locale: en-US)
  → CardParser.parse(transcript, gameFamily:) → [Card] or ParseError
  → Hand(cards:)
  → await StrategyService.lookup(hand:, paytableId:)  // async throws
  → StrategyResult (bestHold bitmask + bestEv)
  → ResponseFormatter.format(hand:, result:, gameFamily:) → String
  → SpeechSynthesisService.speak(string)
```

### AVAudioSession Management

`AVAudioSession` is a shared singleton. `AudioService` sets category `.ambient` or `.playback`. `VoiceService` requires `.playAndRecord`. These conflict.

**On Casino Mode entry:**
1. Call `AudioService.shared.suspend()` — stops any active players, saves current category
2. `VoiceService` sets category to `.playAndRecord` with options `[.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker]`
3. `AVAudioSession.sharedInstance().setActive(true)`

**On Casino Mode exit:**
1. `VoiceService` deactivates audio session
2. Call `AudioService.shared.resume()` — restores previous category and state

`AudioService` must expose `suspend()` and `resume()` methods.

### Session Management

- `SFSpeechRecognizer` initialized with locale `Locale(identifier: "en-US")`
- Sessions expire at ~60 seconds; `VoiceService` auto-restarts at ~55s to avoid gaps
- Only one listening window open at a time; pressing volume button during an active window cancels and restarts it
- The listening window is closed automatically after 5 cards are successfully parsed, or after a 10-second timeout

---

## Volume Button Trigger

Volume button presses are detected via KVO on `AVAudioSession.sharedInstance().outputVolume`. This is a well-established technique with known edge cases that must be handled:

1. **Debounce**: Ignore repeated volume changes within 300ms of the last one (slider drags produce rapid events)
2. **Max/min volume clamp**: If volume is already at maximum (1.0) or minimum (0.0), a press produces no change event. After each detected press, reset volume to 0.5 to ensure subsequent presses are always detectable. This is done silently (no UI volume indicator shown) by briefly setting a `MPVolumeView` offscreen.
3. **Observation loss**: Re-register KVO observation whenever `VoiceService` resumes from background
4. **Tap-to-speak fallback**: Always available in the UI as a reliable alternative

---

## CardParser

### Signature
```swift
static func parse(_ transcript: String, gameFamily: GameFamily) throws -> [Card]
```
Throws `ParseError.insufficientCards(found: Int)` when fewer than 5 cards are recognized.

### Spoken-Word Rank & Suit Mapping

`Rank` does not have spoken-word names. `CardParser` (and `ResponseFormatter`) use a local mapping:

| Rank | Spoken word |
|---|---|
| `.two` | "two" |
| `.three` | "three" |
| `.four` | "four" |
| `.five` | "five" |
| `.six` | "six" |
| `.seven` | "seven" |
| `.eight` | "eight" |
| `.nine` | "nine" |
| `.ten` | "ten" |
| `.jack` | "jack" |
| `.queen` | "queen" |
| `.king` | "king" |
| `.ace` | "ace" |

Numeric ranks are spoken as words ("two", not "2") in all responses.

### Fuzzy Normalization (applied before matching)

| Raw word | Normalized |
|---|---|
| "to", "too" | "two" |
| "for" | "four" |
| "jack's", "queens", "kings", "aces" | strip possessives/plurals → "jack", "queen", "king", "ace" |
| "club", "heart", "spade", "diamond" | → "clubs", "hearts", "spades", "diamonds" |
| "tin", "than", "tan" | → "ten" (common speech-to-text misrecognitions) |

### Matching Algorithm
1. Tokenize transcript into words
2. Apply fuzzy normalization
3. Walk tokens looking for `[rank_word] of [suit_word]` pattern
4. Each match produces one `Card`
5. Return `[Card]` when 5 found, or throw `ParseError.insufficientCards(found:)` if fewer

### Wild Card Handling
In wild card games (e.g., Deuces Wild, where `GameFamily.isWildGame == true`), a spoken "two" is still parsed as `Card(rank: .two, suit: <spoken suit>)`. The `Hand` model and `StrategyService` already handle wild card logic correctly for these game families — `CardParser` does not need to treat wilds specially. `ResponseFormatter` should label wild cards in the response when the game is a wild game (e.g., "Two pair plus a wild. Hold all five." rather than naming the deuce individually).

### Error Response
If < 5 cards parsed: `SpeechSynthesisService.speak("I only caught \(n) cards — try again.")`

---

## Response Format

`ResponseFormatter` maps `Hand` + `StrategyResult` bitmask + `GameFamily` → natural language string.

### Format: `"[Hand name]. [Hold instruction]."`

Hold instructions name specific cards by rank (spoken words), not positions.

| Hand situation | Example response |
|---|---|
| Royal flush | "Royal flush. Hold all five." |
| Straight flush | "Straight flush. Hold all five." |
| Four of a kind | "Four aces. Hold the four aces." |
| Full house | "Full house. Hold all five." |
| Flush | "Flush. Hold all five." |
| Straight | "Straight. Hold all five." |
| Three of a kind | "Three queens. Hold the three queens." |
| Two pair | "Two pair. Hold the jacks and fours." |
| High pair (JJ+) | "Pair of jacks. Hold the two jacks." |
| Low pair | "Low pair. Hold the two fours." |
| Four to a royal | "Four to a royal. Hold the ace, king, queen, and jack." |
| Three to a royal | "Three to a royal. Hold the ace, king, and queen." |
| Four to a straight flush | "Four to a straight flush. Hold the nine, eight, seven, and six." |
| Four to a flush | "Four to a flush. Hold the ace, ten, eight, and four of hearts." |
| Discard all | "No made hand. Discard everything." |

For wild card games, hand names differ from standard games. `ResponseFormatter` requires a separate wild-game hand name mapping covering Deuces Wild-specific categories: "Five of a Kind", "Wild Royal Flush", "Four Deuces", "Natural Royal Flush", etc. When a wild card is in the held cards, the hold instruction names the deuce as "the wild two" (e.g., "Three of a kind. Hold the two queens and the wild two.").

---

## Casino Mode UI

### Setup Screen
- Shown on first launch of Casino Mode (and accessible via "Change Game" tap during a session)
- Game family picker
- Paytable picker filtered to selected game
- **Download state**: On paytable selection, immediately call `StrategyService.preparePaytable(paytableId:)` and show a progress indicator. The "Start Casino Mode" button is disabled until the strategy data is confirmed ready. If download fails, show an error with a retry button.
- Selection persisted via `UserDefaults` so returning users skip setup
- **AppIntent fallback**: If `StartCasinoListeningIntent` fires but no paytable has been selected, redirect to the setup screen rather than starting listening

### Active Screen
- **Dark background** — visually low-profile, reduced battery draw
- Screen brightness auto-set to ~20% on entry, restored on exit
- `UIApplication.shared.isIdleTimerDisabled = true` on entry, `false` on exit
- **Top bar**: current game + paytable label (e.g., "Jacks or Better 9/6") — tap to change
- **Center**: large mic icon
  - Idle: gray, static
  - Listening window open: pulsing blue
  - Processing: activity spinner
  - Error: red with brief message
- **Lower half**: last recognized hand (card names) + recommended hold as text — visual backup for users not wearing headphones or for verification
- **"Tap to Speak" button**: fallback trigger, always visible
- **"Exit Casino Mode" button**: small, bottom of screen — restores brightness, idle timer, and `AudioService`

### Entry Point
A "Casino Mode" card on the existing Home screen, visually distinct from other modes.

---

## Permissions & Entitlements

### Info.plist additions
```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>Casino Voice Mode uses speech recognition to hear your hand and look up the optimal play.</string>

<key>NSMicrophoneUsageDescription</key>
<string>Casino Voice Mode listens for your spoken hand to provide real-time strategy coaching.</string>

<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

The `audio` background mode keeps `AVAudioSession` alive for speech synthesis while Casino Mode is active. **Casino Mode is designed to be used with the app in the foreground** (screen on, dimmed). The listening window is always triggered by user action (volume button or tap), so background microphone access is not required. If the app is backgrounded mid-session, the listening window is cancelled and the user is notified on return.

### Runtime Permissions
Both microphone and speech recognition permissions are requested together on first entry to the Casino Mode setup screen (before any listening begins). If either is denied, the setup screen shows an explanatory error with a deep link to Settings.

---

## Action Button Support (iPhone 15 Pro+)

- Ship a `StartCasinoListeningIntent: AppIntent` that opens the app directly to Casino Mode with listening already armed
- User assigns it to the Action Button via Settings → Action Button → Shortcut
- From a locked state: screen wakes, app jumps to foreground, listening begins (~1 second)
- If no paytable has been configured: redirect to setup screen, do not start listening
- Document as a power-user tip in Casino Mode onboarding

---

## Out of Scope (v1)

- Always-on wake word ("Hey Poker") — volume button is the primary trigger
- Voice game switching during a session — user changes game via UI
- EV spoken aloud — response is hand name + hold instruction only
- Android / cross-platform

---

## Testing Strategy

- **Unit tests for `CardParser`**: valid 5-card inputs, fuzzy corrections ("to of hearts" → two), partial parses (3 of 5 cards), all 13 ranks × 4 suits, wild card games, possessive/plural normalization
- **Unit tests for `ResponseFormatter`**: all 15 hand categories (including two-pair), discard-all, hold-all, wild card game responses, spoken rank names for numeric cards ("two" not "2")
- **Unit tests for `VoiceService` volume button debounce**: rapid events within 300ms treated as one press, min/max clamp reset behavior
- **Integration test for `CasinoModeViewModel`**: mock `VoiceService` + `StrategyService`, verify full async loop including `throws` path (strategy not downloaded → error spoken)
- **Manual QA**: wired headphones, AirPods (BT), no headphones; volume button at min/max volume; test `AudioService` suspend/resume (verify SFX stop and resume correctly)
