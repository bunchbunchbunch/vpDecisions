# Video Poker Trainer - Comprehensive Feature Roadmap

## Executive Summary

This document outlines a comprehensive feature roadmap for building a world-class video poker training application. Based on extensive market research of existing solutions (WinPoker, Video Poker for Winners, Frugal Video Poker, VideoPoker.com Pro, Play Perfect apps, Video Poker Tutor) and analysis of gaps in the current market, this roadmap prioritizes features by impact and feasibility.

---

## Market Research Summary

### Existing Apps Analyzed

| App | Strengths | Weaknesses |
|-----|-----------|------------|
| **WinPoker** | 23+ game variants, 5 training modes, fast calculations, custom paytables | Outdated, removed from iOS App Store, no longer maintained |
| **VideoPoker.com Pro** | Real-time EV tables, session replay, statistics dashboard, expert Q&A | $14/month subscription, web-based |
| **Video Poker for Winners** | Casino-accurate screens, 20+ games, multi-hand support, Bob Dancer guidance | $50+ desktop software, Windows-focused |
| **Frugal Video Poker** | Strategy chart generator, printable cards, 54 games, free | Windows only, dated UI |
| **Play Perfect** | Ultimate X support, trip recorder, multiple card selection methods | Separate apps for different features |
| **Video Poker Tutor** | Free, 4.7 rating, Game Center integration, 4 training modes | Only 5 game variations |

### Common User Complaints (from App Store reviews)
1. Forced in-app purchases for coins/hints (no one-time fee option)
2. Missing bankroll/payout tracking display
3. No sound effects
4. Custom paytables break strategy calculations
5. No explanation of WHY certain holds are correct
6. Apps not updated for new iOS versions

### Market Gaps Identified
1. **No spaced repetition learning** - No app uses proven memory techniques
2. **No camera-based paytable scanning** - Manual entry required everywhere
3. **No social/competitive features** - Video poker training is solitary
4. **Limited explanation of strategy reasoning** - Apps say what's wrong but not why
5. **No trip planning/casino finder** - Must use separate resources
6. **No progressive jackpot strategy adjustments** - Static strategies only
7. **No offline-first mobile experience** - Most require constant connectivity

---

## Feature Priority Matrix

### Priority 1: Core Training Excellence
*These differentiate us and must be exceptional*

### Priority 2: Engagement & Retention
*These keep users coming back*

### Priority 3: Advanced Tools
*These serve serious players*

### Priority 4: Social & Community
*These drive organic growth*

### Priority 5: Premium/Monetization
*These enable sustainable business*

---

## Detailed Feature PRDs

---

# PRD-001: Enhanced Quiz Mode with Spaced Repetition

## Overview
Transform the existing quiz mode into an intelligent learning system that adapts to user weaknesses using spaced repetition algorithms.

## Problem Statement
Current video poker trainers show random hands or let users filter by difficulty, but don't intelligently focus on hands the user specifically struggles with. This results in inefficient learning where users practice hands they already know.

## Solution
Implement a spaced repetition system (similar to Anki/Duolingo) that:
- Tracks every hand the user gets wrong
- Schedules those specific hand patterns for review at optimal intervals
- Adapts difficulty based on mastery level
- Focuses practice time on actual weaknesses

## User Stories
1. As a learner, I want the app to remember which hands I struggle with so I can focus my practice time efficiently
2. As a learner, I want to see my mastery level for different hand categories so I know where I need work
3. As a learner, I want the app to automatically increase difficulty as I improve

## Feature Requirements

### Must Have (MVP)
- Track all user answers with timestamp
- Calculate per-hand-pattern accuracy (e.g., "4 to a flush vs low pair")
- Implement SM-2 or Leitner-style scheduling algorithm
- Show hands with lowest mastery scores more frequently
- Display mastery percentage for hand categories

### Should Have
- Visual mastery map (heat map of hand types)
- Daily streak tracking
- Estimated time to mastery
- "Weak spots" drill mode

### Could Have
- Comparative mastery between game types
- Mastery decay for inactive users
- Custom review scheduling

## Technical Requirements
- Local SQLite database for hand history
- Supabase sync for cross-device progress
- Algorithm calculates next review time on answer submit
- Mastery scores range 0-100%

## Hand Categories to Track
```
1. High pairs (JJ, QQ, KK, AA)
2. Low pairs (22-TT)
3. Two pair
4. Three of a kind
5. Four to a flush
6. Four to a straight (open-ended)
7. Four to a straight (inside)
8. Four to a royal flush
9. Four to a straight flush
10. Three to a royal flush
11. Three to a straight flush
12. High cards only
13. Garbage hands (complete discards)
14. Mixed decisions (pair vs flush draw, etc.)
```

## Success Metrics
- Users who complete 100+ hands have >85% accuracy on weak categories
- Average session length increases 25%
- 7-day retention increases 40%

## Effort Estimate
- Design: 2 days
- Implementation: 5 days
- Testing: 2 days

---

# PRD-002: Strategy Explanation Engine

## Overview
Provide detailed explanations for WHY certain holds are optimal, not just WHAT the optimal hold is.

## Problem Statement
Current trainers tell users they made a mistake but don't explain the reasoning. Users memorize patterns without understanding underlying logic, making it hard to apply knowledge to novel situations.

## Solution
Build an explanation engine that breaks down:
- Expected value calculation for each option
- What winning hands each hold is drawing to
- Probability of hitting each outcome
- Comparison to alternative holds

## User Stories
1. As a learner, I want to understand why my hold was wrong so I can learn the underlying principle
2. As a learner, I want to see the math behind EV calculations so I trust the recommendations
3. As a learner, I want to know what winning hands I'm drawing to with each hold option

## Feature Requirements

### Must Have
- Show top 3-5 holds with EV for each
- For each hold, list possible outcomes (flush, straight, pair, etc.)
- Show probability of each outcome
- Highlight the EV difference between user's choice and optimal

### Should Have
- "Deep dive" expandable section with full probability breakdown
- Visual representation (pie chart or bar chart) of outcome probabilities
- Link to strategy category (e.g., "This is a 4-to-flush vs pair decision")

### Could Have
- Video explanations for common mistake types
- Link to relevant strategy articles
- "Similar hands" examples

## Technical Requirements
- Pre-calculate outcome probabilities per hold (can be done offline)
- Store explanation templates for hand categories
- Generate dynamic explanations based on specific cards

## Example Explanation
```
Your hold: J♠ J♦ (pair of jacks)
Optimal hold: 9♠ T♠ J♠ Q♠ (4 to a royal flush)

Why the 4-to-royal is better:

4 to Royal Flush (optimal):
- Royal Flush (1/47): 800.00 coins
- Straight Flush (3/47): 150.00 coins
- Flush (8/47): 30.00 coins
- Straight (3/47): 20.00 coins
- Nothing (32/47): 0 coins
= Expected Value: 18.66 coins

Pair of Jacks:
- Four of a Kind (1/1,081): 125.00 coins
- Full House (9/1,081): 9 coins
- Three of a Kind (63/1,081): 3 coins
- Two Pair (198/1,081): 2 coins
- Jacks or Better (810/1,081): 1 coin
= Expected Value: 7.68 coins

The 4-to-royal has 2.4x higher expected value!
```

## Success Metrics
- Users report better understanding in surveys
- Users make fewer mistakes on similar hand patterns
- App store reviews mention explanations as key feature

## Effort Estimate
- Design: 3 days
- Implementation: 7 days
- Testing: 3 days

---

# PRD-003: Bankroll Management & Session Tracking

## Overview
Provide realistic bankroll simulation and session tracking to teach proper money management alongside strategy.

## Problem Statement
Perfect strategy is only half the equation. Many players go broke due to poor bankroll management despite knowing correct holds. Existing apps don't teach this critical skill.

## Solution
Integrated bankroll simulator that:
- Simulates realistic variance over time
- Shows risk of ruin calculations
- Tracks virtual "sessions" with realistic payouts
- Teaches relationship between game selection, denomination, and bankroll requirements

## User Stories
1. As a player, I want to understand how much bankroll I need for a given game so I don't go broke
2. As a player, I want to track my virtual sessions to see how variance affects results
3. As a player, I want to learn which games are appropriate for my bankroll size

## Feature Requirements

### Must Have
- Bankroll input (virtual starting amount)
- Denomination selection ($0.25, $1, $5, etc.)
- Session tracking (wins, losses, hands played)
- Bankroll chart over time
- Risk of ruin calculator

### Should Have
- Multiple saved bankroll profiles
- Session goals (stop-loss, win goals)
- Variance visualization (possible outcomes distribution)
- Comparison of different games' volatility

### Could Have
- Import real session data
- Slot club value calculator
- Optimal denomination recommendations
- "What if" scenario simulator

## Risk of Ruin Calculator Inputs
- Starting bankroll
- Game (with known house edge and variance)
- Hands per hour
- Session length
- Slot club cashback percentage

## Risk of Ruin Output
- Probability of losing entire bankroll
- Expected value of session
- Standard deviation range (1σ, 2σ, 3σ)
- Recommended bankroll for 5% risk of ruin

## Technical Requirements
- Monte Carlo simulation for variance modeling (can run client-side)
- Persistent storage for session history
- Statistical calculations for risk of ruin

## Example Bankroll Requirements (for reference)
| Game | Variance | Bankroll for 5% RoR (2hr) |
|------|----------|---------------------------|
| 9/6 Jacks or Better | 19.51 | $165 |
| Double Double Bonus | 41.99 | $300 |
| Deuces Wild | 25.83 | $185 |

## Success Metrics
- Users understand bankroll requirements before playing
- Reduced "coin" complaints (realistic simulation removes need for fake coins)
- Users report feeling more prepared for real play

## Effort Estimate
- Design: 2 days
- Implementation: 5 days
- Testing: 2 days

---

# PRD-004: Strategy Card Generator

## Overview
Generate printable strategy cards that users can take to the casino.

## Problem Statement
Memorizing perfect strategy takes significant time. Strategy cards are legal in casinos and help bridge the gap while learning. Existing generators are desktop-only or produce ugly output.

## Solution
In-app strategy card generator that:
- Creates beautiful, readable strategy cards
- Supports any paytable combination
- Optimizes for printing or phone reference
- Color-codes for easy reading

## User Stories
1. As a player, I want to generate a strategy card for the exact paytable I'll play
2. As a player, I want to print the card or save it for phone reference
3. As a player, I want the card to be easy to read quickly in a casino

## Feature Requirements

### Must Have
- Select game and paytable
- Generate ordered strategy list (best holds first)
- Export as PDF
- Share/print functionality

### Should Have
- Color-coded by hand type
- Compact (wallet-size) and full-page formats
- Custom paytable entry
- Multiple output formats (PDF, image)

### Could Have
- Laminated card ordering integration
- Simplified vs perfect strategy options
- Regional strategy adjustments

## Strategy Card Format
```
9/6 JACKS OR BETTER STRATEGY

1. Royal Flush
2. Straight Flush
3. Four of a Kind
4. 4 to a Royal Flush
5. Three of a Kind
6. Full House, Flush, Straight
7. 4 to a Straight Flush
8. Two Pair
9. High Pair (JJ-AA)
10. 3 to a Royal Flush
11. 4 to a Flush
12. Low Pair (22-TT)
13. 4 to an Outside Straight
14. 3 to a Straight Flush (Type 1)
15. AKQJ unsuited
16. 2 High Cards (JQ, JK, QK suited)
...
```

## Technical Requirements
- PDF generation library (react-native-pdf-lib or similar)
- Strategy generation algorithm from paytable
- Share sheet integration

## Success Metrics
- Users generate and use strategy cards
- Reduced in-app errors correlate with card usage

## Effort Estimate
- Design: 2 days
- Implementation: 4 days
- Testing: 1 day

---

# PRD-005: Progressive Jackpot Strategy Adjustments

## Overview
Adjust strategy recommendations based on progressive jackpot amounts.

## Problem Statement
When progressive jackpots grow large enough, optimal strategy changes (you should chase royals more aggressively). No mobile app handles this dynamically.

## Solution
Allow users to input current progressive amount and see:
- Adjusted strategy for that jackpot level
- Break-even jackpot amount
- Current effective return percentage
- Whether the game is "positive EV"

## User Stories
1. As an advantage player, I want to know when a progressive is worth playing
2. As a player, I want to know how strategy changes with higher progressives
3. As a player, I want to quickly calculate if a game is +EV

## Feature Requirements

### Must Have
- Progressive amount input
- Calculate adjusted return percentage
- Show break-even progressive amount
- Indicate if game is +EV (>100%)

### Should Have
- Strategy adjustments for different jackpot levels
- Side-by-side strategy comparison (base vs progressive)
- Quick "is this playable?" indicator

### Could Have
- Progressive tracking over time
- Alerts when local progressives hit target levels
- Historical progressive data

## Break-Even Calculation
For 9/6 Jacks or Better (99.54% base):
- Each additional $1,000 on royal (per coin wagered) adds ~0.02% return
- Break-even for $0.25 game: ~$2,165 progressive
- Break-even for $1.00 game: ~$8,660 progressive

## Technical Requirements
- Recalculate EV with modified royal flush payout
- Store strategy adjustments per jackpot tier
- Input validation for jackpot amounts

## Success Metrics
- Users find +EV games using the tool
- Feature differentiation in marketing

## Effort Estimate
- Design: 1 day
- Implementation: 3 days
- Testing: 1 day

---

# PRD-006: Multi-Hand Game Support

## Overview
Support training for multi-hand video poker variants (Triple Play, Five Play, Ten Play, Fifty Play, Hundred Play).

## Problem Statement
Multi-hand games are extremely popular in casinos but have higher variance. Users need to understand the different dynamics and practice with realistic multi-hand visuals.

## Solution
Add multi-hand training mode that:
- Shows realistic multi-hand layouts
- Calculates aggregate results
- Teaches variance differences
- Supports all hand counts (3, 5, 10, 50, 100)

## User Stories
1. As a player, I want to practice with multi-hand layouts to prepare for casino play
2. As a player, I want to understand how variance changes with more hands
3. As a player, I want to see realistic animations of multi-hand results

## Feature Requirements

### Must Have
- 3-hand, 5-hand, 10-hand modes
- Same deal, different draws for each hand
- Aggregate payout display
- Strategy remains consistent (same as single-hand)

### Should Have
- 50-hand and 100-hand modes
- Variance comparison education
- Realistic animation speed options
- Bankroll implications calculator

### Could Have
- Spin Poker mode
- Multi-Strike Poker mode
- Super Times Pay mode

## Technical Requirements
- Efficient rendering for 100 hands
- Random draw generation for multiple hands
- Aggregate statistics calculation

## Variance Comparison Data
| Hands | Std Dev Multiplier |
|-------|-------------------|
| 1 | 1.0x |
| 3 | 1.73x |
| 5 | 2.24x |
| 10 | 3.16x |
| 50 | 7.07x |
| 100 | 10.0x |

## Success Metrics
- Users engage with multi-hand mode
- Users report better preparation for casino multi-hand games

## Effort Estimate
- Design: 3 days
- Implementation: 7 days
- Testing: 3 days

---

# PRD-007: Ultimate X Training Mode

## Overview
Dedicated training for Ultimate X video poker, which requires completely different strategy based on current multipliers.

## Problem Statement
Ultimate X is extremely popular but has complex strategy that changes based on multiplier state. Play Perfect offers this, but as a separate app. Integrated training would be valuable.

## Solution
Full Ultimate X trainer that:
- Tracks current multipliers across all lines
- Adjusts strategy recommendations based on multiplier state
- Teaches the multiplier system
- Simulates realistic Ultimate X gameplay

## User Stories
1. As an Ultimate X player, I want to learn how multipliers change optimal strategy
2. As a player, I want to practice the full Ultimate X experience
3. As an advantage player, I want to recognize +EV abandoned games

## Feature Requirements

### Must Have
- Multi-line display with multiplier tracking
- Strategy adjustment based on multiplier state
- Clear display of earned multipliers
- Support for 3-play, 5-play, 10-play

### Should Have
- "Vulturing" mode (practice recognizing abandoned games)
- Multiplier strategy explanation
- Return percentage calculator based on current state
- Last-hand strategy (don't activate feature)

### Could Have
- Ultimate X Bonus Streak variant
- Ultimate X Gold variant
- Historical multiplier tracking

## Key Strategy Differences
- With high multipliers (14x+), use conventional strategy
- With mid multipliers (3x-13x), adjusted strategy applies
- Last hand before quitting: bet only 5 coins (don't activate feature)
- Finding abandoned multipliers provides significant edge

## Technical Requirements
- Multiplier state machine
- Dynamic strategy lookup based on state
- Multi-line rendering with multiplier overlays

## Success Metrics
- Users improve Ultimate X play accuracy
- Feature drives app differentiation

## Effort Estimate
- Design: 3 days
- Implementation: 10 days
- Testing: 4 days

---

# PRD-008: Casino Paytable Database & Finder

## Overview
Crowdsourced database of casino paytables to help users find the best games.

## Problem Statement
Finding good paytables requires research across multiple sources (vpFree2, forums, etc.). An integrated, up-to-date database would save time and drive engagement.

## Solution
Build or integrate with existing paytable databases to:
- Show best paytables by location
- Filter by game type, denomination, return percentage
- Allow user submissions/updates
- Provide trip planning features

## User Stories
1. As a player, I want to find the best paytables in my destination city
2. As a player, I want to know which casinos have the games I've trained for
3. As a player, I want to contribute paytable updates I discover

## Feature Requirements

### Must Have
- Casino database with paytable information
- Search by location (city, state)
- Filter by game type
- Show return percentage

### Should Have
- User submissions with moderation
- Last updated timestamps
- Directions integration (maps)
- Favorite casinos

### Could Have
- Push notifications for paytable changes
- Progressive jackpot tracking
- Slot club value comparison
- Casino reviews/ratings

## Data Sources
- Partner with vpFree2.com for data
- User submissions
- Casino websites

## Technical Requirements
- Supabase tables for casino and paytable data
- Location services integration
- Moderation queue for submissions
- API for data retrieval

## Success Metrics
- Users use casino finder before trips
- User-submitted data accuracy
- Return usage correlation with trip planning

## Effort Estimate
- Design: 3 days
- Implementation: 10 days
- Partnerships: Ongoing
- Testing: 3 days

---

# PRD-009: Achievements & Gamification System

## Overview
Add achievements, streaks, and leaderboards to increase engagement and retention.

## Problem Statement
Learning perfect strategy is a long process. Without engagement hooks, users abandon training before achieving mastery. Gamification proven to increase retention in learning apps.

## Solution
Comprehensive gamification system including:
- Achievements for milestones
- Daily streaks
- Leaderboards
- Progress visualization
- Unlockable content

## User Stories
1. As a learner, I want to earn achievements to feel progress
2. As a competitive player, I want to compare my stats with others
3. As a regular user, I want streak incentives to practice daily

## Feature Requirements

### Must Have
- Achievement system with 20+ achievements
- Daily streak counter
- Progress statistics
- Achievement notifications

### Should Have
- Global and friend leaderboards
- Weekly challenges
- Level/XP system
- Shareable achievement cards

### Could Have
- Seasonal challenges
- Team competitions
- Cosmetic unlocks
- Achievement rarity tiers

## Achievement Examples
```
Beginner:
- First Hand: Complete your first hand
- Perfect 10: Get 10 hands correct in a row
- Quick Study: Complete 100 training hands

Intermediate:
- Streak Master: Maintain a 7-day streak
- Game Expert: Achieve 95% accuracy on one game
- Multi-Game: Train on 3 different games

Advanced:
- Strategy Savant: 99% accuracy over 1000 hands
- Royal Treatment: See 10 royal flushes
- Full Spectrum: Master all game types

Expert:
- Perfect Month: 30-day streak
- Close Call Expert: 95% on close decisions
- Speed Demon: 500 hands at <2 sec average
```

## Technical Requirements
- Achievement tracking in database
- Real-time leaderboard updates
- Push notifications for achievements
- Social sharing integration

## Success Metrics
- 30-day retention increases 50%
- Daily active users increase
- Social shares per user

## Effort Estimate
- Design: 3 days
- Implementation: 6 days
- Testing: 2 days

---

# PRD-010: Offline Mode & Data Sync

## Overview
Full offline functionality with cloud sync when connected.

## Problem Statement
Many training apps require connectivity. Users want to practice on planes, in areas with poor signal, or without data usage.

## Solution
Offline-first architecture:
- All training available offline
- Local storage of progress
- Sync when connected
- Conflict resolution for multi-device

## User Stories
1. As a traveler, I want to practice on planes without wifi
2. As a mobile user, I want to save data by not requiring constant connection
3. As a multi-device user, I want my progress synced across devices

## Feature Requirements

### Must Have
- All strategy data stored locally
- Training mode works fully offline
- Progress saved locally when offline
- Sync on reconnection

### Should Have
- Sync indicator showing status
- Conflict resolution for same-hand-different-device
- Background sync
- Selective sync (wifi only option)

### Could Have
- Offline casino database (cached)
- Peer-to-peer sync
- Export/import data

## Technical Requirements
- SQLite for local storage
- Supabase realtime for sync
- Conflict resolution logic
- Network status monitoring

## Data to Store Locally
- All paytable data (~500KB)
- Strategy tables (~2MB)
- User progress (~100KB)
- Session history (~1MB typical)

## Success Metrics
- Offline sessions > 10% of total sessions
- Zero data loss from offline use
- Sync conflicts < 0.1%

## Effort Estimate
- Design: 2 days
- Implementation: 5 days
- Testing: 3 days

---

# PRD-011: Sound & Haptic Feedback

## Overview
Add audio and haptic feedback to enhance the training experience.

## Problem Statement
Users complain about silent apps feeling unnatural. Sound and haptic feedback reinforce learning and make the experience more engaging.

## Solution
Comprehensive audio/haptic system:
- Card sounds (deal, flip, hold)
- Win celebration sounds
- Error/correction sounds
- Haptic feedback on mobile

## User Stories
1. As a user, I want realistic casino sounds for immersion
2. As a learner, I want audio cues for correct/incorrect answers
3. As a mobile user, I want haptic feedback for interactions

## Feature Requirements

### Must Have
- Sound on/off toggle
- Basic card sounds (deal, draw)
- Win sounds (scaled by hand rank)
- Error sound for mistakes

### Should Have
- Volume control
- Sound pack selection
- Haptic feedback (mobile)
- Distinct sounds per hand type

### Could Have
- Custom sound uploads
- Ambient casino background
- Voice announcements

## Sound Design
- Card deal: Crisp "snap"
- Hold selection: Subtle "click"
- Draw: "Whoosh"
- Win (small): "Ding"
- Win (big): "Fanfare"
- Royal flush: "Jackpot celebration"
- Error: "Gentle buzz"

## Technical Requirements
- Audio sprite for efficiency
- Expo-av for audio playback
- Expo-haptics for vibration
- Persist sound preferences

## Success Metrics
- User preference surveys favor sound
- Session length increases with sound enabled
- App store reviews mention good audio

## Effort Estimate
- Design: 2 days
- Asset creation: 3 days
- Implementation: 3 days
- Testing: 1 day

---

# PRD-012: Hand History & Session Replay

## Overview
Save and replay training sessions for review and learning.

## Problem Statement
Users can't review their mistakes after a session ends. Replay functionality enables post-session analysis and sharing for coaching.

## Solution
Session recording and replay:
- Save all hands from each session
- Filter by errors only
- Step through hands one by one
- Share sessions for review

## User Stories
1. As a learner, I want to review my mistakes after a session
2. As a serious student, I want to share my errors with a coach
3. As a data-driven learner, I want to see patterns in my mistakes

## Feature Requirements

### Must Have
- Auto-save all session hands
- Session list with basic stats
- Replay mode with step-through
- Filter to show only errors

### Should Have
- Session statistics (accuracy, time, errors by type)
- Error pattern analysis
- Export session as shareable link
- Compare sessions over time

### Could Have
- Video export of session replay
- Coaching mode (annotate hands)
- Session comparison (A/B)

## Session Data Structure
```json
{
  "sessionId": "uuid",
  "startTime": "2024-01-15T10:30:00Z",
  "endTime": "2024-01-15T10:45:00Z",
  "game": "jacks-or-better-9-6",
  "handsPlayed": 25,
  "correct": 23,
  "hands": [
    {
      "handId": 1,
      "dealt": ["AS", "KS", "QS", "JS", "2H"],
      "userHold": [0, 1, 2, 3],
      "optimalHold": [0, 1, 2, 3],
      "isCorrect": true,
      "evUser": 18.66,
      "evOptimal": 18.66,
      "timeToAnswer": 3.2
    }
  ]
}
```

## Technical Requirements
- Local session storage
- Cloud backup of sessions
- Efficient replay UI
- Share link generation

## Success Metrics
- Users review >30% of sessions with errors
- Coaches adopt platform for student review
- Error patterns identified drive improvement

## Effort Estimate
- Design: 2 days
- Implementation: 5 days
- Testing: 2 days

---

# PRD-013: Paytable Camera Scanner

## Overview
Use device camera to scan and recognize video poker paytables.

## Problem Statement
Manually entering paytables is tedious and error-prone. Camera scanning would let users instantly analyze any game they encounter.

## Solution
Camera-based paytable recognition:
- Point camera at video poker screen
- OCR extracts paytable values
- Auto-calculate return percentage
- Import into app for training

## User Stories
1. As a casino player, I want to quickly scan a game to know if it's worth playing
2. As a researcher, I want to catalog paytables I encounter
3. As a learner, I want to train on the exact paytable I'll play

## Feature Requirements

### Must Have
- Camera access with preview
- OCR for paytable numbers
- Game type recognition
- Return percentage calculation

### Should Have
- Manual correction for OCR errors
- Save scanned paytable
- Share paytable with community
- Comparison with known paytables

### Could Have
- Real-time AR overlay with return %
- Batch scanning mode
- Historical paytable tracking

## Technical Challenges
- Varying screen sizes/orientations
- Reflections and lighting
- Different display formats
- OCR accuracy on numbers

## Technical Requirements
- Camera access (expo-camera)
- OCR library (ML Kit or Tesseract)
- Paytable parsing logic
- Return calculation engine

## Success Metrics
- OCR accuracy > 95%
- Users scan paytables in casinos
- Community paytable database grows

## Effort Estimate
- Research: 3 days
- Design: 2 days
- Implementation: 10 days
- Testing: 5 days

---

# PRD-014: Social Features & Multiplayer

## Overview
Add social features for competition and community.

## Problem Statement
Video poker training is solitary. Social features drive engagement, retention, and organic growth through sharing.

## Solution
Social layer including:
- Friend system
- Challenges between friends
- Shared leaderboards
- Community forums/chat

## User Stories
1. As a competitive player, I want to challenge friends to accuracy contests
2. As a social player, I want to see how my progress compares to friends
3. As a community member, I want to discuss strategy with other players

## Feature Requirements

### Must Have
- User accounts with profiles
- Friend adding/management
- Friend leaderboard
- Challenge friends to quizzes

### Should Have
- Direct messaging
- Challenge notifications
- Shareable achievement cards
- Community leaderboard

### Could Have
- Live "race" mode (simultaneous quiz)
- Clubs/groups
- Forum/discussion
- Coaching marketplace

## Challenge System
1. User A creates challenge (game, hand count, difficulty)
2. User A completes challenge
3. User B receives notification
4. User B completes same hands
5. Winner determined by accuracy (ties: by speed)

## Technical Requirements
- User authentication (Supabase Auth)
- Friend relationship tables
- Push notification system
- Real-time challenge sync

## Success Metrics
- K-factor (viral coefficient) > 0.5
- 30% of users have 1+ friend
- Challenge completion rate > 60%

## Effort Estimate
- Design: 4 days
- Implementation: 12 days
- Testing: 4 days

---

## Unified UX/Navigation Plan

### Information Architecture

```
Home
├── Quick Play (jumps directly into quiz)
├── Quiz Mode
│   ├── Game Selection
│   ├── Settings (difficulty, mode)
│   ├── Active Quiz
│   └── Results & Review
├── Hand Analyzer
│   ├── Card Selector (current full-screen grid)
│   ├── Results Overlay
│   └── Explanation Deep Dive
├── Training Center
│   ├── Weak Spots Drill
│   ├── Spaced Repetition Queue
│   ├── Mastery Dashboard
│   └── Hand Categories Practice
├── Strategy Tools
│   ├── Strategy Card Generator
│   ├── Paytable Analyzer
│   ├── Bankroll Calculator
│   ├── Progressive Calculator
│   └── Paytable Scanner
├── Casino Finder
│   ├── Location Search
│   ├── Favorites
│   └── Contribute Paytable
├── History
│   ├── Sessions List
│   ├── Session Replay
│   ├── Statistics
│   └── Error Patterns
├── Social
│   ├── Friends
│   ├── Challenges
│   ├── Leaderboards
│   └── Profile
└── Settings
    ├── Account
    ├── Sound & Haptics
    ├── Default Games
    └── Notifications
```

### Navigation Components

#### Primary Navigation (Tab Bar)
For mobile, use bottom tab bar with 4-5 primary destinations:
1. **Home** - Quick access, recent activity
2. **Train** - Quiz and drill modes
3. **Analyze** - Hand analyzer and tools
4. **Progress** - Stats, history, mastery
5. **Social** - Friends, challenges (or merge with Profile)

#### Secondary Navigation
- Use cards/tiles on home screen for feature discovery
- Stack navigation within each tab
- Modal sheets for overlays (settings, quick actions)
- Swipe gestures for navigation where natural

#### Landscape Mode
- Primary tabs move to left sidebar (more vertical space)
- Content area maximized for cards
- Tool panels as slide-out sheets

### Screen Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        HOME SCREEN                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ Quick    │ │ Training │ │ Hand     │ │ Progress │       │
│  │ Play     │ │ Center   │ │ Analyzer │ │          │       │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘       │
└───────│────────────│────────────│────────────│──────────────┘
        │            │            │            │
        ▼            ▼            ▼            ▼
   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
   │ Quiz    │  │ Mode    │  │ Card    │  │ Stats   │
   │ Setup   │  │ Select  │  │ Grid    │  │ View    │
   └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘
        │            │            │            │
        ▼            │            ▼            ▼
   ┌─────────┐       │       ┌─────────┐  ┌─────────┐
   │ Active  │◀──────┘       │ Results │  │ Session │
   │ Quiz    │               │ Overlay │  │ Detail  │
   └────┬────┘               └────┬────┘  └─────────┘
        │                         │
        ▼                         ▼
   ┌─────────┐               ┌─────────┐
   │ Results │               │ Strategy│
   │ Review  │               │ Explain │
   └─────────┘               └─────────┘
```

### Design System

#### Colors
```
Primary: #667eea (current purple-blue)
Secondary: #27ae60 (green for success)
Error: #e74c3c (red for mistakes)
Warning: #f39c12 (orange for close decisions)
Background: #f5f7fa (light mode)
Card: #ffffff
Text Primary: #2c3e50
Text Secondary: #7f8c8d
```

#### Typography
```
Headers: System Bold, 24-32pt
Body: System Regular, 16pt
Caption: System Regular, 12pt
Monospace: Menlo/Courier for EV values
```

#### Card Styling
- 12px border radius
- Subtle shadow (2px blur, 10% opacity)
- White background
- 16px padding

#### Button Styling
- Primary: Solid fill, white text
- Secondary: Outline, colored text
- 30px border radius (pill shape)
- 16px vertical padding

---

## Implementation Phases

### Phase 1: Core Excellence (Current State + Refinements)
*Target: 4 weeks*

1. ~~Basic Quiz Mode~~ (Done)
2. ~~Hand Analyzer~~ (Done)
3. ~~Landscape optimization~~ (Done)
4. Sound & Haptic Feedback (PRD-011)
5. Strategy Explanation Engine - Basic (PRD-002 MVP)
6. Session History - Basic (PRD-012 MVP)

### Phase 2: Smart Learning
*Target: 6 weeks*

1. Spaced Repetition System (PRD-001)
2. Mastery Dashboard
3. Weak Spots Drill Mode
4. Hand Category Breakdown
5. Offline Mode (PRD-010)

### Phase 3: Advanced Tools
*Target: 6 weeks*

1. Strategy Card Generator (PRD-004)
2. Bankroll Calculator (PRD-003)
3. Progressive Jackpot Calculator (PRD-005)
4. Multi-Hand Training (PRD-006)

### Phase 4: Engagement & Social
*Target: 8 weeks*

1. Achievements System (PRD-009)
2. User Accounts
3. Friend System & Challenges (PRD-014)
4. Leaderboards

### Phase 5: Premium Features
*Target: 8 weeks*

1. Ultimate X Training (PRD-007)
2. Casino Finder Integration (PRD-008)
3. Paytable Scanner (PRD-013)
4. Full Explanation Engine

---

## Monetization Strategy

### Freemium Model

**Free Tier:**
- Jacks or Better training
- Basic quiz mode
- Hand analyzer (limited uses/day)
- Basic achievements

**Premium Tier ($4.99/month or $39.99/year):**
- All game types
- Unlimited hand analyzer
- Spaced repetition system
- Strategy card generator
- Bankroll calculator
- All achievements
- Ad-free experience
- Session history (30+ days)
- Social features (challenges)

**Lifetime Purchase ($79.99):**
- All premium features forever
- Early access to new features
- Priority support

### Why This Works
- Jacks or Better free = users learn value of app
- Limit hand analyzer = creates desire for full access
- Competitive pricing vs alternatives:
  - VideoPoker.com Pro: $14/month
  - Video Poker for Winners: $50 one-time
  - Our Premium: $40/year or $80 lifetime

---

## Technical Architecture Notes

### Current Stack
- React Native / Expo
- Supabase for strategy lookups
- Local storage for preferences

### Recommended Additions
- SQLite for local session/progress storage
- Supabase Auth for user accounts
- Supabase Realtime for sync
- Expo Notifications for push
- Expo AV for audio
- Expo Haptics for vibration
- Expo Camera for scanner feature

### Data Models Needed
```
Users
- id, email, created_at
- subscription_tier, subscription_expires

Progress
- user_id, game_id, hand_pattern
- attempts, correct, last_seen
- mastery_score, next_review

Sessions
- id, user_id, game_id
- started_at, ended_at
- hands_played, correct_count

SessionHands
- session_id, hand_number
- dealt_cards, user_hold, optimal_hold
- is_correct, ev_user, ev_optimal
- time_to_answer

Achievements
- id, user_id, achievement_type
- earned_at, progress

Friends
- user_id, friend_id
- status (pending, accepted)

Challenges
- id, challenger_id, challenged_id
- game_id, hand_count
- challenger_score, challenged_score
- created_at, completed_at
```

---

## Success Metrics Summary

| Metric | Target | Measurement |
|--------|--------|-------------|
| App Store Rating | 4.8+ | Aggregate reviews |
| 7-Day Retention | 40% | Analytics |
| 30-Day Retention | 25% | Analytics |
| Free to Paid Conversion | 5% | Subscription analytics |
| Daily Active Users | 10k (6mo goal) | Analytics |
| Session Length | 8+ minutes avg | Analytics |
| Viral Coefficient | 0.5+ | Referral tracking |
| User Accuracy Improvement | 20% in first month | In-app measurement |

---

## Competitive Differentiation Summary

What makes this app unique:
1. **Spaced Repetition Learning** - Only video poker app using proven memory science
2. **Strategy Explanations** - Not just "wrong" but "here's why"
3. **Beautiful Mobile-First Design** - Most competitors are web or outdated
4. **Offline-First** - Train anywhere, sync later
5. **Social Competition** - Challenge friends, compare progress
6. **Unified Experience** - Tools that work together, not separate apps
7. **Modern Tech Stack** - Fast, reliable, cross-platform

---

## Sources Referenced

### App Store / Reviews
- [Video Poker Trainer - App Store](https://apps.apple.com/us/app/video-poker-trainer/id324646348)
- [Video Poker Tutor - App Store](https://apps.apple.com/us/app/video-poker-tutor/id500158304)
- [WinPoker - App Store](https://apps.apple.com/us/app/winpoker/id298071996)

### Training Software Reviews
- [Video Poker Training Software - ReadyBetGo](https://www.readybetgo.com/video-poker/software/)
- [WinPoker Review - ReadyBetGo](https://www.readybetgo.com/software-reviews/winpoker-review-651.html)
- [WinPoker 6 Review - VideoPokerBaller](https://videopokerballer.com/tools/winpoker-6/)
- [Video Poker for Winners Review - VideoPokerBaller](https://www.videopokerballer.com/tools/video-poker-for-winners/)

### Professional Tools
- [VideoPoker.com Pro Features](https://www.videopoker.com/pro/features/)
- [Play Perfect LLC](https://www.playperfectllc.com/)
- [Frugal Video Poker - ReadyBetGo](https://www.readybetgo.com/software-reviews/frugal-video-poker-1325.html)

### Strategy & Math
- [Wizard of Odds - Video Poker](https://wizardofodds.com/games/video-poker/)
- [Video Poker Strategy Charts - American Casino Guide](https://www.americancasinoguidebook.com/video-poker/free-video-poker-strategy-charts.html)
- [VPFree2 - Paytable Database](https://www.vpfree2.com/video-poker/pay-tables)

### Learning Science
- [Spaced Repetition - Wikipedia](https://en.wikipedia.org/wiki/Spaced_repetition)
- [Leitner System - Wikipedia](https://en.wikipedia.org/wiki/Leitner_system)
- [FSRS Algorithm - GitHub](https://github.com/open-spaced-repetition/fsrs4anki/wiki)

### Gamification
- [Leaderboards in Mobile Apps - Plotline](https://www.plotline.so/blog/leaderboard-for-gamification-in-mobile-apps)
- [Gamification in iGaming - GR8 Tech](https://gr8.tech/blog/achievement-unlocked-gamification-tools-and-trends-in-igaming/)

---

*Document generated: December 2024*
*Last updated: December 2024*
