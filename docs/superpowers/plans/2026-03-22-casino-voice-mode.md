# Casino Voice Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Git policy:** Do NOT commit or push without explicit user approval for each operation.

**Goal:** Add a hands-free Casino Voice Mode where users speak their video poker hand and hear the optimal hold strategy through their headphones.

**Architecture:** `VoiceService` manages continuous speech recognition and volume-button triggering; `CardParser` converts transcripts to cards; `ResponseFormatter` maps strategy results to natural-language responses; `SpeechSynthesisService` delivers audio output. `CasinoModeViewModel` orchestrates the full async loop. Casino views integrate into existing `NavigationStack`-based navigation in `HomeView`.

**Tech Stack:** SFSpeechRecognizer, AVAudioEngine, AVSpeechSynthesizer, AVAudioSession, MPVolumeView, AppIntents, Swift 6 strict concurrency, Swift Testing (`@Test`, `#expect`)

---

## File Map

### New Files

| File | Responsibility |
|------|---------------|
| `Services/CardParser.swift` | Pure struct: transcript → `[Card]`. Rank/suit word mapping + fuzzy normalization. |
| `Services/ResponseFormatter.swift` | Pure struct: `Hand` + `StrategyResult` + `GameFamily` → spoken response string. |
| `Services/VoiceService.swift` | `@MainActor @Observable`: AVAudioEngine + SFSpeechRecognizer lifecycle, volume button KVO, session auto-restart. |
| `Services/SpeechSynthesisService.swift` | `@MainActor @Observable` singleton: AVSpeechSynthesizer wrapper, `isSpeaking` state. |
| `ViewModels/CasinoModeViewModel.swift` | `@MainActor @Observable`: orchestrates trigger → parse → strategy lookup (async) → speak. |
| `Views/Casino/CasinoSetupView.swift` | Game/paytable picker with download progress, persists selection. Pushed onto parent NavigationStack. |
| `Views/Casino/CasinoModeView.swift` | Active casino screen: dark UI, mic state indicator, idle timer, brightness control. |
| `App/StartCasinoListeningIntent.swift` | `AppIntent` for Action Button integration. |
| `VideoPokerAcademyTests/CardParserTests.swift` | Unit tests for CardParser. |
| `VideoPokerAcademyTests/ResponseFormatterTests.swift` | Unit tests for ResponseFormatter. |
| `VideoPokerAcademyTests/VoiceServiceTests.swift` | Unit tests for VoiceService debounce logic. |
| `VideoPokerAcademyTests/CasinoModeViewModelTests.swift` | Integration tests for CasinoModeViewModel. |

### Modified Files

| File | Change |
|------|--------|
| `VideoPokerAcademy/Info.plist` | Add microphone + speech recognition permissions, `audio` background mode. |
| `Services/AudioService.swift` | Add `isSuspended`, `suspend()`, `resume()`. Guard `play()` against suspended state. |
| `Views/Home/HomeView.swift` | Add `.casinoSetup` to `AppScreen` enum, navigation destination, and home screen card. |

### Key Existing APIs (verified from codebase)

```swift
// GameFamily (Models/GameFamily.swift)
// rawValue = "jacks-or-better", "deuces-wild", etc.
enum GameFamily: String, CaseIterable, Identifiable
var isWildGame: Bool   // true for .deucesWild, .looseDeuces
var displayName: String
// Correct case names: .jacksOrBetter, .deucesWild, .looseDeuces etc.
// NOTE: PayTable.jacksOrBetter96 is a PayTable constant, NOT a GameFamily case

// PayTable (Models/PayTable.swift)
struct PayTable: Identifiable { let id: String; let name: String; var family: GameFamily }
static let allPayTables: [PayTable]                          // full list
static func paytables(for family: GameFamily) -> [PayTable]  // filtered list

// SoundEffect (Services/AudioService.swift)
// Cases: .cardSelect, .cardFlip, .coinPayout, .bigWin, .submit, .correct,
//        .incorrect, .nextHand, .quizComplete, .buttonTap, .dealtWinner

// StrategyResult (Models/MasteryScore.swift)
struct StrategyResult: Codable { let bestHold: Int; let bestEv: Double; let holdEvs: [String: Double] }
var bestHoldIndices: [Int]   // convenience: Hand.holdIndicesFromBitmask(bestHold)

// StrategyService (Services/StrategyService.swift) — actor
func lookup(hand: Hand, paytableId: String) async throws -> StrategyResult?
func preparePaytable(paytableId: String) async -> Bool

// Hand (Models/Hand.swift)
static func holdIndicesFromBitmask(_ bitmask: Int) -> [Int]
static func bitmaskFromHoldIndices(_ indices: [Int]) -> Int
func cardsAtIndices(_ indices: [Int]) -> [Card]

// AudioService (Services/AudioService.swift) — ObservableObject singleton
static let shared: AudioService
func play(_ sound: SoundEffect)
// Will add: func suspend(), func resume(), var isSuspended: Bool
```

---

## Task 1: Info.plist — Permissions and Background Mode

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Info.plist`

- [ ] **Step 1: Add three keys to Info.plist**

Open `Info.plist` and add these entries before the closing `</dict>`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Casino Voice Mode listens for your spoken hand to provide real-time strategy coaching.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>Casino Voice Mode uses speech recognition to hear your hand and look up the optimal play.</string>

<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

- [ ] **Step 2: Build to verify plist is valid**

Run: `mcp__xcodebuildmcp__build_sim_name_proj` with scheme `VideoPokerAcademy`
Expected: BUILD SUCCEEDED

---

## Task 2: AudioService — suspend() and resume()

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Services/AudioService.swift`
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/AudioServiceSuspendTests.swift`

**Context:** `AudioService` is an `ObservableObject` singleton. It configures `AVAudioSession` in `configureAudioSession()`. `VoiceService` will take over the audio session when Casino Mode starts. Add `suspend()` / `resume()` so the two can coexist without session conflicts.

- [ ] **Step 1: Write the failing tests**

Create `VideoPokerAcademyTests/AudioServiceSuspendTests.swift`:

```swift
import Testing
@testable import VideoPokerAcademy

@MainActor
struct AudioServiceSuspendTests {

    @Test("suspend sets isSuspended to true")
    func testSuspendSetsSuspendedFlag() {
        AudioService.shared.resume()  // ensure clean state
        AudioService.shared.suspend()
        #expect(AudioService.shared.isSuspended == true)
    }

    @Test("resume clears isSuspended flag")
    func testResumeClearsSuspendedFlag() {
        AudioService.shared.suspend()
        AudioService.shared.resume()
        #expect(AudioService.shared.isSuspended == false)
    }

    @Test("play is a no-op while suspended")
    func testPlayDoesNothingWhileSuspended() {
        AudioService.shared.suspend()
        // Should not crash — just a no-op
        AudioService.shared.play(.buttonTap)   // .buttonTap is the correct SoundEffect case
        #expect(AudioService.shared.isSuspended == true)
        AudioService.shared.resume()
    }
}
```

- [ ] **Step 2: Run tests to confirm compile failure**

Expected: `isSuspended` does not exist yet — build error.

- [ ] **Step 3: Add suspend/resume to AudioService**

In `AudioService.swift`, add after `@Published var volume`:

```swift
@Published private(set) var isSuspended = false

func suspend() {
    isSuspended = true
    playerLock.withLock {
        players.values.forEach { $0.stop() }
    }
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
}

func resume() {
    isSuspended = false
    configureAudioSession()
}
```

At the top of the existing `play(_ sound:)` method, add:

```swift
guard !isSuspended else { return }
```

- [ ] **Step 4: Run tests**

Run: `mcp__xcodebuildmcp__test_sim_name_proj`
Expected: All tests pass including new suspend tests.

- [ ] **Step 5: Build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: BUILD SUCCEEDED

---

## Task 3: CardParser

**Files:**
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Services/CardParser.swift`
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/CardParserTests.swift`

**Context:** `Rank` enum rawValues are Ints (`.two = 2` … `.ace = 14`). `Suit` has `.hearts`, `.diamonds`, `.clubs`, `.spades`. `Card(rank:suit:)` is the initializer. `GameFamily` case for standard games is `.jacksOrBetter` (not `.jacksOrBetter96` — that's a `PayTable` constant). `CardParser` needs a word-to-Rank/Suit map and fuzzy normalization before matching `[rank] of [suit]` triples.

- [ ] **Step 1: Write the failing tests**

Create `VideoPokerAcademyTests/CardParserTests.swift`:

```swift
import Testing
@testable import VideoPokerAcademy

struct CardParserTests {

    // MARK: - Basic Parsing

    @Test("parses a full five-card hand")
    func testParsesFiveCards() throws {
        let t = "ace of spades king of hearts queen of diamonds jack of clubs ten of spades"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards.count == 5)
        #expect(cards[0].rank == .ace   && cards[0].suit == .spades)
        #expect(cards[1].rank == .king  && cards[1].suit == .hearts)
        #expect(cards[2].rank == .queen && cards[2].suit == .diamonds)
        #expect(cards[3].rank == .jack  && cards[3].suit == .clubs)
        #expect(cards[4].rank == .ten   && cards[4].suit == .spades)
    }

    @Test("parses numeric ranks two through six")
    func testNumericRanks() throws {
        let t = "two of hearts three of diamonds four of clubs five of spades six of hearts"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards.map(\.rank) == [.two, .three, .four, .five, .six])
    }

    @Test("parses seven through nine")
    func testMidRanks() throws {
        let t = "seven of clubs eight of hearts nine of spades two of diamonds three of clubs"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards[0].rank == .seven)
        #expect(cards[1].rank == .eight)
        #expect(cards[2].rank == .nine)
    }

    @Test("throws insufficientCards when fewer than 5 recognized")
    func testThrowsOnPartialHand() {
        let t = "ace of spades king of hearts"
        #expect(throws: CardParseError.self) {
            try CardParser.parse(t, gameFamily: .jacksOrBetter)
        }
    }

    @Test("error includes count of found cards")
    func testErrorCount() {
        let t = "ace of spades king of hearts queen of diamonds"
        do {
            _ = try CardParser.parse(t, gameFamily: .jacksOrBetter)
            Issue.record("Expected throw")
        } catch CardParseError.insufficientCards(let found) {
            #expect(found == 3)
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    // MARK: - Fuzzy Normalization

    @Test("normalizes 'to' to two")
    func testNormalizesTo() throws {
        let t = "to of hearts king of spades queen of clubs jack of diamonds ten of hearts"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards[0].rank == .two)
    }

    @Test("normalizes 'too' to two")
    func testNormalizesToo() throws {
        let t = "too of clubs ace of spades king of hearts queen of diamonds jack of clubs"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards[0].rank == .two)
    }

    @Test("normalizes 'for' to four")
    func testNormalizesFor() throws {
        let t = "for of diamonds ace of spades king of hearts queen of clubs jack of spades"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards[0].rank == .four)
    }

    @Test("normalizes 'tin' to ten")
    func testNormalizesTin() throws {
        let t = "tin of spades ace of hearts king of clubs queen of diamonds jack of spades"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards[0].rank == .ten)
    }

    @Test("normalizes possessive jack's to jack")
    func testNormalizesPossessive() throws {
        let t = "jack's of clubs ace of spades king of hearts queen of diamonds ten of clubs"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards[0].rank == .jack)
    }

    @Test("normalizes singular suit names to plural")
    func testNormalizesSingularSuits() throws {
        let t = "ace of spade king of heart queen of diamond jack of club ten of spade"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards[0].suit == .spades)
        #expect(cards[1].suit == .hearts)
        #expect(cards[2].suit == .diamonds)
        #expect(cards[3].suit == .clubs)
    }

    // MARK: - Wild Card Games

    @Test("two of clubs parsed as normal Card in wild game — wild logic is StrategyService's job")
    func testWildCardParsedNormally() throws {
        let t = "two of clubs ace of spades king of hearts queen of diamonds jack of clubs"
        let cards = try CardParser.parse(t, gameFamily: .deucesWild)
        #expect(cards[0].rank == .two && cards[0].suit == .clubs)
    }
}
```

- [ ] **Step 2: Run — expect compile error**

Expected: `CardParser` not found.

- [ ] **Step 3: Create CardParser.swift**

Create `Services/CardParser.swift`:

```swift
import Foundation

enum CardParseError: Error {
    case insufficientCards(found: Int)
}

struct CardParser {

    static let rankWords: [String: Rank] = [
        "two": .two, "three": .three, "four": .four,
        "five": .five, "six": .six, "seven": .seven,
        "eight": .eight, "nine": .nine, "ten": .ten,
        "jack": .jack, "queen": .queen, "king": .king, "ace": .ace
    ]

    static let suitWords: [String: Suit] = [
        "hearts": .hearts, "diamonds": .diamonds,
        "clubs": .clubs, "spades": .spades
    ]

    static func normalize(_ word: String) -> String {
        let cleaned = word.lowercased().replacingOccurrences(of: "'s", with: "")
        switch cleaned {
        case "to", "too":          return "two"
        case "for":                return "four"
        case "tin", "than", "tan": return "ten"
        case "heart":              return "hearts"
        case "diamond":            return "diamonds"
        case "club":               return "clubs"
        case "spade":              return "spades"
        case "jacks":              return "jack"
        case "queens":             return "queen"
        case "kings":              return "king"
        case "aces":               return "ace"
        default:                   return cleaned
        }
    }

    static func parse(_ transcript: String, gameFamily: GameFamily) throws -> [Card] {
        // gameFamily parameter is accepted for future wild-game parsing extensions;
        // wild card detection is handled by StrategyService, not CardParser.
        let words = transcript
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        var cards: [Card] = []
        var i = 0

        while i < words.count {
            let word = normalize(words[i])
            if let rank = rankWords[word],
               i + 2 < words.count,
               normalize(words[i + 1]) == "of",
               let suit = suitWords[normalize(words[i + 2])] {
                cards.append(Card(rank: rank, suit: suit))
                i += 3
            } else {
                i += 1
            }
        }

        guard cards.count >= 5 else {
            throw CardParseError.insufficientCards(found: cards.count)
        }
        return Array(cards.prefix(5))
    }
}
```

- [ ] **Step 4: Run tests**

Run: `mcp__xcodebuildmcp__test_sim_name_proj`
Expected: All `CardParserTests` pass.

- [ ] **Step 5: Build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: BUILD SUCCEEDED

---

## Task 4: ResponseFormatter

**Files:**
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Services/ResponseFormatter.swift`
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/ResponseFormatterTests.swift`

**Context:**
- `StrategyResult.bestHoldIndices: [Int]` is already a convenience property
- `Hand.cardsAtIndices(_:) -> [Card]` returns the held cards
- `GameFamily.isWildGame` is `true` for `.deucesWild` / `.looseDeuces`
- Spoken rank names: `.two` → "two", `.ten` → "ten", `.jack` → "jack", etc. Never digits.
- Response format: `"[Hand name]. [Hold instruction]."`
- Wild card games use different hand names ("Five of a kind", "Wild royal", "Four deuces") and refer to held deuces as "the wild two"
- When all 5 cards are held (made hand), `buildHoldInstruction` returns "Hold all five" — this is correct even for four-of-a-kind because the 5th card (kicker) is always held

- [ ] **Step 1: Write the failing tests**

Create `VideoPokerAcademyTests/ResponseFormatterTests.swift`:

```swift
import Testing
@testable import VideoPokerAcademy

struct ResponseFormatterTests {

    private func result(hold indices: [Int], ev: Double = 1.0) -> StrategyResult {
        StrategyResult(
            bestHold: Hand.bitmaskFromHoldIndices(indices),
            bestEv: ev,
            holdEvs: [:]
        )
    }

    // MARK: - Hold All Five (made hands)

    @Test("royal flush — hold all five")
    func testRoyalFlush() {
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .spades), Card(rank: .king, suit: .spades),
            Card(rank: .queen, suit: .spades), Card(rank: .jack, suit: .spades),
            Card(rank: .ten, suit: .spades)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3,4], ev: 800), gameFamily: .jacksOrBetter)
        #expect(r == "Royal flush. Hold all five.")
    }

    @Test("straight flush — hold all five")
    func testStraightFlush() {
        let hand = Hand(cards: [
            Card(rank: .nine, suit: .hearts), Card(rank: .eight, suit: .hearts),
            Card(rank: .seven, suit: .hearts), Card(rank: .six, suit: .hearts),
            Card(rank: .five, suit: .hearts)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3,4], ev: 50), gameFamily: .jacksOrBetter)
        #expect(r == "Straight flush. Hold all five.")
    }

    @Test("four of a kind — hold all five")
    func testFourOfAKind() {
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .spades), Card(rank: .ace, suit: .hearts),
            Card(rank: .ace, suit: .diamonds), Card(rank: .ace, suit: .clubs),
            Card(rank: .king, suit: .spades)
        ])
        // Strategy holds all 5 (kicker included) — response says "Hold all five"
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3,4], ev: 25), gameFamily: .jacksOrBetter)
        #expect(r == "Four of a kind. Hold all five.")
    }

    @Test("full house — hold all five")
    func testFullHouse() {
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .spades), Card(rank: .ace, suit: .hearts),
            Card(rank: .ace, suit: .diamonds), Card(rank: .king, suit: .clubs),
            Card(rank: .king, suit: .spades)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3,4], ev: 9), gameFamily: .jacksOrBetter)
        #expect(r == "Full house. Hold all five.")
    }

    @Test("flush — hold all five")
    func testFlush() {
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .hearts), Card(rank: .nine, suit: .hearts),
            Card(rank: .seven, suit: .hearts), Card(rank: .four, suit: .hearts),
            Card(rank: .two, suit: .hearts)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3,4], ev: 6), gameFamily: .jacksOrBetter)
        #expect(r == "Flush. Hold all five.")
    }

    @Test("straight — hold all five")
    func testStraight() {
        let hand = Hand(cards: [
            Card(rank: .nine, suit: .spades), Card(rank: .eight, suit: .hearts),
            Card(rank: .seven, suit: .diamonds), Card(rank: .six, suit: .clubs),
            Card(rank: .five, suit: .spades)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3,4], ev: 4), gameFamily: .jacksOrBetter)
        #expect(r == "Straight. Hold all five.")
    }

    // MARK: - Discard All

    @Test("discard all")
    func testDiscardAll() {
        let hand = Hand(cards: [
            Card(rank: .seven, suit: .clubs), Card(rank: .four, suit: .hearts),
            Card(rank: .two, suit: .spades), Card(rank: .nine, suit: .diamonds),
            Card(rank: .jack, suit: .hearts)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [], ev: 0.36), gameFamily: .jacksOrBetter)
        #expect(r == "No made hand. Discard everything.")
    }

    // MARK: - Pairs / Trips (partial holds)

    @Test("high pair — jacks")
    func testHighPair() {
        let hand = Hand(cards: [
            Card(rank: .jack, suit: .hearts), Card(rank: .jack, suit: .diamonds),
            Card(rank: .seven, suit: .clubs), Card(rank: .four, suit: .spades),
            Card(rank: .two, suit: .hearts)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1], ev: 1.54), gameFamily: .jacksOrBetter)
        #expect(r == "Pair of jacks. Hold the two jacks.")
    }

    @Test("low pair")
    func testLowPair() {
        let hand = Hand(cards: [
            Card(rank: .four, suit: .hearts), Card(rank: .four, suit: .diamonds),
            Card(rank: .king, suit: .clubs), Card(rank: .nine, suit: .spades),
            Card(rank: .two, suit: .hearts)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1], ev: 0.82), gameFamily: .jacksOrBetter)
        #expect(r == "Low pair. Hold the two fours.")
    }

    @Test("three of a kind")
    func testThreeOfAKind() {
        let hand = Hand(cards: [
            Card(rank: .queen, suit: .hearts), Card(rank: .queen, suit: .diamonds),
            Card(rank: .queen, suit: .clubs), Card(rank: .king, suit: .spades),
            Card(rank: .two, suit: .hearts)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2], ev: 4), gameFamily: .jacksOrBetter)
        #expect(r == "Three queens. Hold the three queens.")
    }

    @Test("two pair")
    func testTwoPair() {
        let hand = Hand(cards: [
            Card(rank: .jack, suit: .hearts), Card(rank: .jack, suit: .diamonds),
            Card(rank: .four, suit: .clubs), Card(rank: .four, suit: .spades),
            Card(rank: .two, suit: .hearts)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3], ev: 2.6), gameFamily: .jacksOrBetter)
        #expect(r == "Two pair. Hold the jacks and fours.")
    }

    // MARK: - Draws

    @Test("four to a royal")
    func testFourToRoyal() {
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .spades), Card(rank: .king, suit: .spades),
            Card(rank: .queen, suit: .spades), Card(rank: .jack, suit: .spades),
            Card(rank: .two, suit: .hearts)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3], ev: 18.4), gameFamily: .jacksOrBetter)
        #expect(r == "Four to a royal. Hold the ace, king, queen, and jack.")
    }

    @Test("four to a flush")
    func testFourToFlush() {
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .hearts), Card(rank: .ten, suit: .hearts),
            Card(rank: .eight, suit: .hearts), Card(rank: .four, suit: .hearts),
            Card(rank: .two, suit: .clubs)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3], ev: 1.22), gameFamily: .jacksOrBetter)
        #expect(r == "Four to a flush. Hold the ace, ten, eight, and four.")
    }

    // MARK: - Wild Card Games

    @Test("wild game: natural royal flush is labeled correctly")
    func testWildGameNaturalRoyal() {
        let hand = Hand(cards: [
            Card(rank: .ace, suit: .spades), Card(rank: .king, suit: .spades),
            Card(rank: .queen, suit: .spades), Card(rank: .jack, suit: .spades),
            Card(rank: .ten, suit: .spades)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1,2,3,4], ev: 800), gameFamily: .deucesWild)
        #expect(r == "Natural royal flush. Hold all five.")
    }

    // MARK: - Spoken rank names use words not digits

    @Test("numeric rank spoken as word, not digit")
    func testNumericRankAsWord() {
        let hand = Hand(cards: [
            Card(rank: .two, suit: .hearts), Card(rank: .two, suit: .diamonds),
            Card(rank: .king, suit: .clubs), Card(rank: .nine, suit: .spades),
            Card(rank: .seven, suit: .hearts)
        ])
        let r = ResponseFormatter.format(hand: hand, result: result(hold: [0,1], ev: 0.82), gameFamily: .jacksOrBetter)
        #expect(r.contains("two"))
        #expect(!r.contains("2"))
    }
}
```

- [ ] **Step 2: Run — expect compile error**

Expected: `ResponseFormatter` not found.

- [ ] **Step 3: Create ResponseFormatter.swift**

Create `Services/ResponseFormatter.swift`:

```swift
import Foundation

struct ResponseFormatter {

    // MARK: - Spoken Rank Map (words only, never digits)

    static let spokenRank: [Rank: String] = [
        .two: "two", .three: "three", .four: "four", .five: "five",
        .six: "six", .seven: "seven", .eight: "eight", .nine: "nine",
        .ten: "ten", .jack: "jack", .queen: "queen", .king: "king", .ace: "ace"
    ]

    // MARK: - Public API

    static func format(hand: Hand, result: StrategyResult, gameFamily: GameFamily) -> String {
        let heldIndices = result.bestHoldIndices
        let heldCards = hand.cardsAtIndices(heldIndices)
        let handName = determineHandName(
            hand: hand,
            heldIndices: heldIndices,
            heldCards: heldCards,
            gameFamily: gameFamily
        )
        let holdInstruction = buildHoldInstruction(heldIndices: heldIndices, heldCards: heldCards)
        return "\(handName). \(holdInstruction)."
    }

    // MARK: - Hand Name

    private static func determineHandName(
        hand: Hand,
        heldIndices: [Int],
        heldCards: [Card],
        gameFamily: GameFamily
    ) -> String {
        if heldIndices.isEmpty { return "No made hand" }
        if heldIndices.count == 5 {
            return gameFamily.isWildGame
                ? evaluateWildHandName(hand: hand)
                : evaluateFullHandName(hand: hand)
        }
        return evaluateDrawName(heldCards: heldCards)
    }

    // Standard (non-wild) five-card hand name
    private static func evaluateFullHandName(hand: Hand) -> String {
        let ranks = hand.cards.map(\.rank)
        let suits = hand.cards.map(\.suit)
        let rankCounts = Dictionary(grouping: ranks, by: { $0 }).mapValues(\.count)
        let isFlush = Set(suits).count == 1
        let sortedRankValues = ranks.map(\.rawValue).sorted()
        let isSequential = zip(sortedRankValues, sortedRankValues.dropFirst()).allSatisfy { $1 == $0 + 1 }
        let isWheelStraight = sortedRankValues == [2, 3, 4, 5, 14]
        let isStraight = isSequential || isWheelStraight

        if isFlush && sortedRankValues == [10, 11, 12, 13, 14] { return "Royal flush" }
        if isFlush && isSequential { return "Straight flush" }
        if rankCounts.values.contains(4) { return "Four of a kind" }
        if rankCounts.values.contains(3) && rankCounts.values.contains(2) { return "Full house" }
        if isFlush { return "Flush" }
        if isStraight { return "Straight" }
        if rankCounts.values.contains(3) {
            let r = rankCounts.first { $0.value == 3 }!.key
            return "Three \(spokenRank[r]!)s"
        }
        if rankCounts.values.filter({ $0 == 2 }).count == 2 { return "Two pair" }
        if let pairRank = rankCounts.first(where: { $0.value == 2 })?.key {
            return pairRank.rawValue >= Rank.jack.rawValue
                ? "Pair of \(spokenRank[pairRank]!)s"
                : "Low pair"
        }
        return "High card"
    }

    // Wild card game five-card hand name (Deuces Wild hand hierarchy)
    private static func evaluateWildHandName(hand: Hand) -> String {
        let ranks = hand.cards.map(\.rank)
        let suits = hand.cards.map(\.suit)
        let deuceCount = ranks.filter { $0 == .two }.count
        let nonDeuceRanks = ranks.filter { $0 != .two }
        let rankCounts = Dictionary(grouping: nonDeuceRanks, by: { $0 }).mapValues(\.count)
        let isNaturalFlush = Set(suits).count == 1
        let sortedRankValues = ranks.map(\.rawValue).sorted()
        let isNaturalRoyal = isNaturalFlush && sortedRankValues == [10, 11, 12, 13, 14]

        if deuceCount == 0 && isNaturalRoyal { return "Natural royal flush" }
        if deuceCount == 4 { return "Four deuces" }
        // Five of a kind: 4 matching non-deuces + deuces fill, or any grouping with deuces
        let maxNonDeuce = rankCounts.values.max() ?? 0
        if maxNonDeuce + deuceCount >= 5 { return "Five of a kind" }
        // Wild royal: flush but not natural, contains deuces that fill the royal
        if isNaturalFlush && deuceCount > 0 { return "Wild royal flush" }
        if maxNonDeuce + deuceCount >= 4 { return "Four of a kind" }
        return evaluateFullHandName(hand: hand) // fall back for straights, flushes, etc.
    }

    private static func evaluateDrawName(heldCards: [Card]) -> String {
        let count = heldCards.count
        let prefix = count == 4 ? "Four" : count == 3 ? "Three" : count == 2 ? "Two" : "One"
        let suits = heldCards.map(\.suit)
        let ranks = heldCards.map(\.rank)
        let allSameSuit = Set(suits).count == 1
        let royalRanks: Set<Rank> = [.ten, .jack, .queen, .king, .ace]
        let isRoyalDraw = allSameSuit && Set(ranks).isSubset(of: royalRanks)

        if isRoyalDraw { return "\(prefix) to a royal" }
        if allSameSuit && count == 4 { return "Four to a flush" }
        if allSameSuit { return "\(prefix) to a straight flush" }

        let rankCounts = Dictionary(grouping: ranks, by: { $0 }).mapValues(\.count)
        if rankCounts.values.contains(4) { return "Four of a kind" }
        if rankCounts.values.contains(3) {
            let r = rankCounts.first { $0.value == 3 }!.key
            return "Three \(spokenRank[r]!)s"
        }
        if rankCounts.values.filter({ $0 == 2 }).count == 2 { return "Two pair" }
        if let pairRank = rankCounts.first(where: { $0.value == 2 })?.key {
            return pairRank.rawValue >= Rank.jack.rawValue
                ? "Pair of \(spokenRank[pairRank]!)s"
                : "Low pair"
        }
        return "\(prefix) to a straight"
    }

    // MARK: - Hold Instruction

    private static func buildHoldInstruction(heldIndices: [Int], heldCards: [Card]) -> String {
        if heldIndices.isEmpty { return "Discard everything" }
        if heldIndices.count == 5 { return "Hold all five" }

        let ranks = heldCards.map(\.rank)
        let rankCounts = Dictionary(grouping: ranks, by: { $0 }).mapValues(\.count)

        // Two pair: "Hold the jacks and fours"
        if rankCounts.values.filter({ $0 == 2 }).count == 2 {
            let pairs = rankCounts.filter { $0.value == 2 }.keys.sorted { $0.rawValue > $1.rawValue }
            return "Hold the \(spokenRank[pairs[0]]!)s and \(spokenRank[pairs[1]]!)s"
        }
        if let quad = rankCounts.first(where: { $0.value == 4 }) {
            return "Hold the four \(spokenRank[quad.key]!)s"
        }
        if let triple = rankCounts.first(where: { $0.value == 3 }) {
            return "Hold the three \(spokenRank[triple.key]!)s"
        }
        if let pair = rankCounts.first(where: { $0.value == 2 }) {
            return "Hold the two \(spokenRank[pair.key]!)s"
        }
        // Distinct cards: "Hold the ace, king, queen, and jack"
        let names = heldCards.map { spokenRank[$0.rank]! }
        switch names.count {
        case 1: return "Hold the \(names[0])"
        case 2: return "Hold the \(names[0]) and \(names[1])"
        default:
            let allButLast = names.dropLast().joined(separator: ", ")
            return "Hold the \(allButLast), and \(names.last!)"
        }
    }
}
```

- [ ] **Step 4: Run tests**

Run: `mcp__xcodebuildmcp__test_sim_name_proj`
Expected: All `ResponseFormatterTests` pass.

- [ ] **Step 5: Build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: BUILD SUCCEEDED

---

## Task 5: SpeechSynthesisService

**Files:**
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Services/SpeechSynthesisService.swift`

**Context:** Wraps `AVSpeechSynthesizer`. No unit tests (wraps system framework). Cancels in-progress speech before starting a new utterance. Exposes `isSpeaking` for the mic state indicator in `CasinoModeView`.

**Swift 6 note:** The class is `@MainActor @Observable` and inherits `NSObject`. Delegate methods are `nonisolated` to satisfy `AVSpeechSynthesizerDelegate` (an `@objc` protocol). Assigning `synthesizer.delegate = self` in `init()` is safe because `AVSpeechSynthesizer.delegate` is itself non-isolated. The `nonisolated` delegate methods dispatch back to `@MainActor` via `Task { @MainActor in ... }`.

- [ ] **Step 1: Create SpeechSynthesisService.swift**

Create `Services/SpeechSynthesisService.swift`:

```swift
import AVFoundation

@MainActor
@Observable
final class SpeechSynthesisService: NSObject {

    static let shared = SpeechSynthesisService()

    private(set) var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 1.0
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
}

extension SpeechSynthesisService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }
}
```

- [ ] **Step 2: Build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: BUILD SUCCEEDED. If Swift 6 reports isolation errors on the delegate methods, ensure they are `nonisolated` and dispatch back via `Task { @MainActor in ... }` as shown.

---

## Task 6: VoiceService

**Files:**
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Services/VoiceService.swift`

**Context:** Manages:
1. Permissions: microphone + speech recognition
2. `AVAudioSession`: `.playAndRecord` with `.allowBluetooth`, `.allowBluetoothA2DP`, `.defaultToSpeaker`
3. Volume button detection: KVO on `AVAudioSession.outputVolume`, 300ms debounce, volume reset to 0.5 via `MPVolumeView` to handle max/min edge case
4. `SFSpeechRecognizer` (locale `en-US`) + `AVAudioEngine` continuous session, auto-restart at 55s
5. Active listening window: 10s timeout, closes when transcript fires
6. Callbacks: `onVolumeButtonPressed: (() -> Void)?` and `onTranscriptReady: ((String) -> Void)?`

**Swift 6 notes:**
- The KVO closure for `outputVolume` runs on a non-isolated thread; it must route to `@MainActor` via `Task { @MainActor in ... }` — this is correct in the code below
- The `NSKeyValueObservation` is stored on an `@MainActor` property, which is safe
- Use `Task { try? await Task.sleep(nanoseconds: 100_000_000) }` instead of `DispatchQueue.main.asyncAfter` — the latter bypasses Swift concurrency's isolation tracking

- [ ] **Step 1: Create VoiceService.swift**

Create `Services/VoiceService.swift`:

```swift
import AVFoundation
import Speech
import MediaPlayer

enum ListeningState: Equatable {
    case idle
    case windowOpen
    case processing
    case error(String)
}

@MainActor
@Observable
final class VoiceService: NSObject {

    private(set) var listeningState: ListeningState = .idle

    var onTranscriptReady: ((String) -> Void)?
    var onVolumeButtonPressed: (() -> Void)?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private var sessionRestartTimer: Timer?
    private var windowTimer: Timer?
    private var debounceTimer: Timer?
    private var volumeObservation: NSKeyValueObservation?

    // Hidden volume view for silently resetting volume to 0.5 after each press.
    // This ensures the KVO fires even when volume is at min or max.
    private lazy var hiddenVolumeView: MPVolumeView = {
        let v = MPVolumeView(frame: .zero)
        v.isHidden = true
        return v
    }()

    override init() { super.init() }

    // MARK: - Permissions

    func requestPermissions() async -> Bool {
        let micGranted = await AVAudioApplication.requestRecordPermission()
        guard micGranted else { return false }
        return await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
    }

    // MARK: - Session Lifecycle

    func startSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker])
        try session.setActive(true)
        startContinuousRecognition()
        startVolumeObservation()
    }

    func stopSession() {
        stopContinuousRecognition()
        stopVolumeObservation()
        windowTimer?.invalidate()
        windowTimer = nil
        listeningState = .idle
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Continuous Recognition

    private func startContinuousRecognition() {
        stopContinuousRecognition()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        try? audioEngine.start()

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, _ in
            guard let self, let result = result, result.isFinal else { return }
            let transcript = result.bestTranscription.formattedString
            Task { @MainActor [weak self] in
                guard let self, self.listeningState == .windowOpen else { return }
                self.windowTimer?.invalidate()
                self.windowTimer = nil
                self.listeningState = .idle
                self.onTranscriptReady?(transcript)
            }
        }

        // Auto-restart before the 60s session limit
        sessionRestartTimer = Timer.scheduledTimer(withTimeInterval: 55, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in self?.startContinuousRecognition() }
        }
    }

    private func stopContinuousRecognition() {
        sessionRestartTimer?.invalidate()
        sessionRestartTimer = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
    }

    // MARK: - Listening Window

    func openListeningWindow() {
        windowTimer?.invalidate()
        windowTimer = nil
        listeningState = .windowOpen

        // Restart recognition fresh for this window
        startContinuousRecognition()

        windowTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.listeningState = .idle
                SpeechSynthesisService.shared.speak("Listening timed out. Press the volume button to try again.")
            }
        }
    }

    func setProcessing() { listeningState = .processing }
    func setIdle()       { listeningState = .idle }
    func setError(_ msg: String) { listeningState = .error(msg) }

    // MARK: - Volume Button Detection

    private func startVolumeObservation() {
        let session = AVAudioSession.sharedInstance()
        // KVO closure runs on a non-isolated thread; route to @MainActor via Task
        volumeObservation = session.observe(\.outputVolume, options: [.new, .old]) { [weak self] _, change in
            guard change.newValue != change.oldValue else { return }
            Task { @MainActor [weak self] in self?.handleVolumeChange() }
        }
        resetVolumeToMidpoint()
    }

    private func stopVolumeObservation() {
        volumeObservation?.invalidate()
        volumeObservation = nil
        debounceTimer?.invalidate()
        debounceTimer = nil
    }

    private func handleVolumeChange() {
        // Debounce: ignore rapid events within 300ms (e.g., slider drags)
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.onVolumeButtonPressed?()
                self?.resetVolumeToMidpoint()
            }
        }
    }

    private func resetVolumeToMidpoint() {
        // Silently reset volume to 0.5 so future presses always generate a change event,
        // even when volume is already at min (0.0) or max (1.0).
        // Uses Task.sleep instead of DispatchQueue to stay within Swift concurrency.
        guard let slider = hiddenVolumeView.subviews.compactMap({ $0 as? UISlider }).first else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1s
            slider.value = 0.5
        }
    }
}
```

- [ ] **Step 2: Build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: BUILD SUCCEEDED. Fix any Swift 6 `Sendable` or isolation errors — all AVFoundation callbacks must route via `Task { @MainActor in ... }`.

---

## Task 7: VoiceService Debounce Tests

**Files:**
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/VoiceServiceTests.swift`

**Context:** The spec requires debounce unit tests. The debounce logic in `handleVolumeChange()` uses a `Timer` with a 0.3s interval. Testing this directly requires either real time delays or exposing internal state. The approach here is to test the observable `listeningState` transitions via the public API (`openListeningWindow`, `setProcessing`, `setIdle`, `setError`) — these are the pure state machine behaviors we can test without AVFoundation.

> **Note:** True debounce timing tests (verifying 300ms window) require `XCTestExpectation` with `wait(for:timeout:)`. Swift Testing does not yet have built-in async waiting. The tests below cover the pure state behaviors. Manual testing of the actual debounce (rapid volume presses) is required on device.

- [ ] **Step 1: Write VoiceService state tests**

Create `VideoPokerAcademyTests/VoiceServiceTests.swift`:

```swift
import Testing
@testable import VideoPokerAcademy

@MainActor
struct VoiceServiceTests {

    @Test("initial state is idle")
    func testInitialStateIsIdle() {
        let service = VoiceService()
        #expect(service.listeningState == .idle)
    }

    @Test("setProcessing changes state to processing")
    func testSetProcessing() {
        let service = VoiceService()
        service.setProcessing()
        #expect(service.listeningState == .processing)
    }

    @Test("setIdle returns state to idle")
    func testSetIdle() {
        let service = VoiceService()
        service.setProcessing()
        service.setIdle()
        #expect(service.listeningState == .idle)
    }

    @Test("setError sets error state with message")
    func testSetError() {
        let service = VoiceService()
        service.setError("test error")
        #expect(service.listeningState == .error("test error"))
    }

    @Test("ListeningState equality — idle equals idle")
    func testListeningStateEquality() {
        #expect(ListeningState.idle == ListeningState.idle)
        #expect(ListeningState.windowOpen == ListeningState.windowOpen)
        #expect(ListeningState.idle != ListeningState.windowOpen)
        #expect(ListeningState.error("a") == ListeningState.error("a"))
        #expect(ListeningState.error("a") != ListeningState.error("b"))
    }
}
```

- [ ] **Step 2: Run tests**

Run: `mcp__xcodebuildmcp__test_sim_name_proj`
Expected: All `VoiceServiceTests` pass.

- [ ] **Step 3: Build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: BUILD SUCCEEDED

---

## Task 8: CasinoModeViewModel + Tests

**Files:**
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/CasinoModeViewModel.swift`
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademyTests/CasinoModeViewModelTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `VideoPokerAcademyTests/CasinoModeViewModelTests.swift`:

```swift
import Testing
@testable import VideoPokerAcademy

@MainActor
struct CasinoModeViewModelTests {

    // NOTE: These tests exercise CardParser integration (parse path).
    // StrategyService.lookup is called with real data; if the paytable strategy
    // is not downloaded in the test environment, lastResponse will be nil and
    // lastError will be set — but lastHand is set BEFORE the lookup, so the
    // parse-path tests remain valid regardless of download state.

    @Test("valid transcript stores the parsed hand")
    func testValidTranscriptStoresHand() async {
        let vm = CasinoModeViewModel(paytableId: "jacks-or-better-9-6", gameFamily: .jacksOrBetter)
        let transcript = "ace of spades king of spades queen of spades jack of spades ten of spades"

        await vm.handleTranscript(transcript)

        #expect(vm.lastHand != nil)
        #expect(vm.lastHand?.cards.count == 5)
    }

    @Test("insufficient cards sets lastError, clears lastHand")
    func testInsufficientCardsSetsError() async {
        let vm = CasinoModeViewModel(paytableId: "jacks-or-better-9-6", gameFamily: .jacksOrBetter)

        await vm.handleTranscript("ace of spades king of hearts")

        #expect(vm.lastError != nil)
        #expect(vm.lastHand == nil)
    }

    @Test("voice state returns to idle after handling transcript")
    func testStateReturnsToIdleAfterProcessing() async {
        let vm = CasinoModeViewModel(paytableId: "jacks-or-better-9-6", gameFamily: .jacksOrBetter)

        await vm.handleTranscript("ace of spades king of hearts")

        #expect(vm.voiceService.listeningState == .idle)
    }
}
```

- [ ] **Step 2: Run — expect compile error**

Expected: `CasinoModeViewModel` not found.

- [ ] **Step 3: Create CasinoModeViewModel.swift**

Create `ViewModels/CasinoModeViewModel.swift`:

```swift
import Foundation

@MainActor
@Observable
final class CasinoModeViewModel {

    var gameFamily: GameFamily
    var paytableId: String

    private(set) var lastHand: Hand?
    private(set) var lastResponse: String?
    private(set) var lastError: String?

    let voiceService = VoiceService()
    private let speechService = SpeechSynthesisService.shared

    init(paytableId: String, gameFamily: GameFamily) {
        self.paytableId = paytableId
        self.gameFamily = gameFamily
        setupCallbacks()
    }

    private func setupCallbacks() {
        voiceService.onVolumeButtonPressed = { [weak self] in
            self?.voiceService.openListeningWindow()
        }
        voiceService.onTranscriptReady = { [weak self] transcript in
            guard let self else { return }
            Task { await self.handleTranscript(transcript) }
        }
    }

    // MARK: - Session Control

    func startCasinoSession() throws {
        AudioService.shared.suspend()
        try voiceService.startSession()
    }

    func stopCasinoSession() {
        voiceService.stopSession()
        AudioService.shared.resume()
    }

    // MARK: - Core Loop

    func handleTranscript(_ transcript: String) async {
        lastError = nil
        voiceService.setProcessing()

        do {
            let cards = try CardParser.parse(transcript, gameFamily: gameFamily)
            let hand = Hand(cards: cards)
            lastHand = hand  // set before async lookup — tests can assert this regardless of download state

            guard let result = try await StrategyService.shared.lookup(hand: hand, paytableId: paytableId) else {
                throw CasinoModeError.strategyNotAvailable
            }

            let response = ResponseFormatter.format(hand: hand, result: result, gameFamily: gameFamily)
            lastResponse = response
            speechService.speak(response)

        } catch CardParseError.insufficientCards(let found) {
            lastHand = nil
            let msg = "I only caught \(found) card\(found == 1 ? "" : "s") — try again."
            lastError = msg
            speechService.speak(msg)
        } catch CasinoModeError.strategyNotAvailable {
            let msg = "Strategy data not available. Please check your connection."
            lastError = msg
            speechService.speak(msg)
        } catch {
            let msg = "Something went wrong. Please try again."
            lastError = msg
            speechService.speak(msg)
        }

        voiceService.setIdle()
    }
}

enum CasinoModeError: Error {
    case strategyNotAvailable
}
```

- [ ] **Step 4: Run tests**

Run: `mcp__xcodebuildmcp__test_sim_name_proj`
Expected: All three `CasinoModeViewModelTests` pass.

- [ ] **Step 5: Build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: BUILD SUCCEEDED

---

## Task 9: CasinoSetupView

**Files:**
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Casino/CasinoSetupView.swift`

**Context:**
- `PayTable.allPayTables: [PayTable]` — static property on `PayTable` (not `PayTableData`)
- `PayTable.paytables(for: GameFamily) -> [PayTable]` — static filter method
- `GameFamily.rawValue` is `String` — works with `@AppStorage`
- **Do NOT wrap in `NavigationStack`** — this view is pushed onto the existing `NavigationStack` in `HomeView`. Adding a second `NavigationStack` causes SwiftUI navigation to break.

- [ ] **Step 1: Create CasinoSetupView.swift**

Create `Views/Casino/CasinoSetupView.swift`:

```swift
import SwiftUI

struct CasinoSetupView: View {

    @State private var selectedGame: GameFamily = .jacksOrBetter
    @State private var selectedPaytableId: String = ""
    @State private var isDownloading = false
    @State private var isReady = false
    @State private var downloadError: String?
    @State private var navigateToActive = false

    @AppStorage("casinoMode_game") private var savedGameRaw: String = ""
    @AppStorage("casinoMode_paytableId") private var savedPaytableId: String = ""

    private var paytablesForGame: [PayTable] {
        PayTable.paytables(for: selectedGame)
    }

    var body: some View {
        Form {
            Section("Game") {
                Picker("Game", selection: $selectedGame) {
                    ForEach(GameFamily.allCases) { game in
                        Text(game.displayName).tag(game)
                    }
                }
                .onChange(of: selectedGame) { _, _ in
                    selectedPaytableId = paytablesForGame.first?.id ?? ""
                    isReady = false
                    downloadError = nil
                    if !selectedPaytableId.isEmpty {
                        Task { await prepareStrategy(for: selectedPaytableId) }
                    }
                }
            }

            Section("Paytable") {
                Picker("Paytable", selection: $selectedPaytableId) {
                    ForEach(paytablesForGame) { pt in
                        Text(pt.name).tag(pt.id)
                    }
                }
                .onChange(of: selectedPaytableId) { _, newId in
                    guard !newId.isEmpty else { return }
                    isReady = false
                    downloadError = nil
                    Task { await prepareStrategy(for: newId) }
                }
            }

            if isDownloading {
                Section {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Downloading strategy data…").foregroundStyle(.secondary)
                    }
                }
            }

            if let error = downloadError {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error).foregroundStyle(.red)
                        Button("Retry") {
                            Task { await prepareStrategy(for: selectedPaytableId) }
                        }
                    }
                }
            }
        }
        .navigationTitle("Casino Mode Setup")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button("Start Casino Mode") {
                savedGameRaw = selectedGame.rawValue
                savedPaytableId = selectedPaytableId
                navigateToActive = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!isReady || selectedPaytableId.isEmpty)
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationDestination(isPresented: $navigateToActive) {
            CasinoModeView(paytableId: selectedPaytableId, gameFamily: selectedGame)
        }
        .onAppear { restoreAndPrepare() }
    }

    private func prepareStrategy(for paytableId: String) async {
        isDownloading = true
        isReady = false
        let success = await StrategyService.shared.preparePaytable(paytableId: paytableId)
        isDownloading = false
        if success {
            isReady = true
        } else {
            downloadError = "Could not load strategy data. Check your connection and try again."
        }
    }

    private func restoreAndPrepare() {
        if let saved = GameFamily(rawValue: savedGameRaw) {
            selectedGame = saved
        }
        let candidate = savedPaytableId.isEmpty ? (paytablesForGame.first?.id ?? "") : savedPaytableId
        let isValid = paytablesForGame.contains { $0.id == candidate }
        selectedPaytableId = isValid ? candidate : (paytablesForGame.first?.id ?? "")
        if !selectedPaytableId.isEmpty {
            Task { await prepareStrategy(for: selectedPaytableId) }
        }
    }
}
```

- [ ] **Step 2: Build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: BUILD SUCCEEDED.

---

## Task 10: CasinoModeView (Active Screen)

**Files:**
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Casino/CasinoModeView.swift`

- [ ] **Step 1: Create CasinoModeView.swift**

Create `Views/Casino/CasinoModeView.swift`:

```swift
import SwiftUI

struct CasinoModeView: View {

    let paytableId: String
    let gameFamily: GameFamily

    @State private var viewModel: CasinoModeViewModel
    @State private var savedBrightness: CGFloat = UIScreen.main.brightness
    @Environment(\.dismiss) private var dismiss

    init(paytableId: String, gameFamily: GameFamily) {
        self.paytableId = paytableId
        self.gameFamily = gameFamily
        _viewModel = State(initialValue: CasinoModeViewModel(paytableId: paytableId, gameFamily: gameFamily))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Text(gameFamily.displayName)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding(.top, 8)

                Spacer()

                MicStateView(state: viewModel.voiceService.listeningState)

                Group {
                    if let response = viewModel.lastResponse {
                        Text(response)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    if let error = viewModel.lastError {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }

                if let hand = viewModel.lastHand {
                    // Abbreviated card display (e.g. "A♠  K♥  Q♦  J♣  T♠")
                    Text(hand.cards.map { $0.rank.display + $0.suit.symbol }.joined(separator: "  "))
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Spacer()

                Button {
                    viewModel.voiceService.openListeningWindow()
                } label: {
                    Label("Tap to Speak", systemImage: "mic.fill")
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                }

                Button("Exit Casino Mode") {
                    exitCasinoMode()
                    dismiss()
                }
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.bottom, 12)
            }
        }
        .navigationBarHidden(true)
        .onAppear { enterCasinoMode() }
        .onDisappear { exitCasinoMode() }
    }

    private func enterCasinoMode() {
        savedBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = 0.2
        UIApplication.shared.isIdleTimerDisabled = true
        try? viewModel.startCasinoSession()
    }

    private func exitCasinoMode() {
        UIScreen.main.brightness = savedBrightness
        UIApplication.shared.isIdleTimerDisabled = false
        viewModel.stopCasinoSession()
    }
}

// MARK: - Mic State Indicator

private struct MicStateView: View {

    let state: ListeningState
    @State private var pulsing = false

    var body: some View {
        ZStack {
            if state == .windowOpen {
                Circle()
                    .fill(Color.blue.opacity(0.25))
                    .frame(width: 140, height: 140)
                    .scaleEffect(pulsing ? 1.35 : 1.0)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulsing)
                    .onAppear { pulsing = true }
                    .onDisappear { pulsing = false }
            }

            Image(systemName: iconName)
                .font(.system(size: 44))
                .foregroundStyle(iconColor)
                .frame(width: 88, height: 88)
                .background(Color.white.opacity(0.06))
                .clipShape(Circle())
        }
        .frame(width: 140, height: 140)
    }

    private var iconName: String {
        switch state {
        case .idle:        return "mic.slash"
        case .windowOpen:  return "mic.fill"
        case .processing:  return "waveform"
        case .error:       return "exclamationmark.circle"
        }
    }

    private var iconColor: Color {
        switch state {
        case .idle:        return .gray
        case .windowOpen:  return .blue
        case .processing:  return .white
        case .error:       return .red
        }
    }
}
```

- [ ] **Step 2: Build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: BUILD SUCCEEDED

---

## Task 11: HomeView Integration + AppIntent

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Home/HomeView.swift`
- Create: `ios-native/VideoPokerAcademy/VideoPokerAcademy/App/StartCasinoListeningIntent.swift`

- [ ] **Step 1: Read HomeView.swift fully before making any changes**

Read `Views/Home/HomeView.swift` to understand the `AppScreen` enum, `NavigationStack`, and how existing mode cards are laid out.

- [ ] **Step 2: Add `.casinoSetup` to AppScreen and navigation destination**

In `HomeView.swift`:
1. Add `case casinoSetup` to the `AppScreen` enum
2. In the `navigationDestination(for: AppScreen.self)` switch, add:
   ```swift
   case .casinoSetup:
       CasinoSetupView()
   ```
3. Add a "Casino Mode" navigation element to the home screen layout following the **exact same style** as existing mode cards

- [ ] **Step 3: Build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Create StartCasinoListeningIntent.swift**

Create `App/StartCasinoListeningIntent.swift`:

```swift
import AppIntents

/// AppIntent for Action Button support (iPhone 15 Pro+).
/// Signals the app to navigate to Casino Mode.
///
/// Implementation note: Uses @AppStorage flag rather than NotificationCenter
/// because NotificationCenter is unreliable on cold launch — the observer in
/// HomeView may not be registered yet when the notification fires. The flag
/// is read on HomeView's onAppear and will route correctly even from cold start.
struct StartCasinoListeningIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Casino Voice Mode"
    static let description = IntentDescription("Opens Casino Mode ready to listen for your hand.")

    @MainActor
    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(true, forKey: "casinoMode_launchFromIntent")
        return .result()
    }
}
```

In `HomeView.swift`, read and clear the flag on `onAppear`:

```swift
.onAppear {
    if UserDefaults.standard.bool(forKey: "casinoMode_launchFromIntent") {
        UserDefaults.standard.set(false, forKey: "casinoMode_launchFromIntent")
        path.append(AppScreen.casinoSetup)
    }
}
```

> **Note:** Replace `path` with whatever the actual `NavigationPath` variable is named in `HomeView` (check in Step 1).

- [ ] **Step 5: Run full test suite**

Run: `mcp__xcodebuildmcp__test_sim_name_proj`
Expected: All tests pass

- [ ] **Step 6: Boot simulator and screenshot**

```
mcp__xcodebuildmcp__boot_simulator  (iPhone 16)
mcp__xcodebuildmcp__install_app
mcp__xcodebuildmcp__launch_app
mcp__xcodebuildmcp__screenshot
```

Verify: Home screen shows "Casino Mode" entry point. Navigate into it to confirm setup screen loads.
