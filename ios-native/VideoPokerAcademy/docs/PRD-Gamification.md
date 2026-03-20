# PRD: Gamification & Leveling System for VP Academy

## Overview
A progression system that motivates continued engagement through levels, achievements, streaks, and social features. The goal is to make learning optimal video poker strategy feel like a game itself.

---

## Core Gamification Elements

### 1. Player Level System

#### Experience Points (XP) Sources

| Activity | XP Earned | Notes |
|----------|-----------|-------|
| Play Mode hand | 1 XP | Base, any hand played |
| Optimal play in Play Mode | +2 XP | Bonus for correct decision |
| Quiz Mode correct answer | 5 XP | Higher value for active learning |
| Quiz Mode streak bonus | +1 XP per streak | Compounds: 5 streak = +5 XP per hand |
| Lesson completed | 50 XP | One-time per lesson |
| Drill completed (8/10+) | 25 XP | Must pass threshold |
| Review queue cleared | 10 XP | Daily bonus |
| Daily login | 5 XP | Retention hook |
| First play of the day | 10 XP | Encourages daily engagement |

#### Level Progression

```
Level 1:     0 XP      "Novice"
Level 2:   100 XP      "Beginner"
Level 3:   300 XP      "Student"
Level 4:   600 XP      "Apprentice"
Level 5: 1,000 XP      "Player"
Level 6: 1,500 XP      "Skilled Player"
Level 7: 2,200 XP      "Expert"
Level 8: 3,000 XP      "Master"
Level 9: 4,000 XP      "Grand Master"
Level 10: 5,500 XP     "Wizard"
Level 11+: +2,000 XP each  "Wizard II, III, etc."
```

#### Level Rewards

| Level | Unlock |
|-------|--------|
| 2 | Custom card back #1 |
| 3 | Profile badge: "Rising Star" |
| 4 | Unlock Drills feature |
| 5 | Custom card back #2 |
| 6 | Profile badge: "Dedicated" |
| 7 | Access to leaderboards |
| 8 | Custom card back #3 (animated) |
| 9 | Profile badge: "Master Strategist" |
| 10 | Exclusive "Wizard" card back |

---

### 2. Achievement System

#### Achievement Categories

**Learning Achievements**
| Achievement | Requirement | XP Bonus |
|-------------|-------------|----------|
| First Steps | Complete first lesson | 25 |
| Scholar | Complete all JoB lessons | 100 |
| Polyglot | Complete lessons in 3 game variants | 150 |
| Professor | Complete ALL lessons | 500 |

**Practice Achievements**
| Achievement | Requirement | XP Bonus |
|-------------|-------------|----------|
| Getting Started | Play 100 hands | 25 |
| Dedicated | Play 1,000 hands | 100 |
| Grinder | Play 10,000 hands | 250 |
| Marathon | Play 100,000 hands | 1,000 |

**Accuracy Achievements**
| Achievement | Requirement | XP Bonus |
|-------------|-------------|----------|
| Sharp Eye | 90% accuracy in 50-hand session | 50 |
| Perfectionist | 100% accuracy in 25-hand session | 75 |
| Consistency | 95%+ accuracy for 7 days straight | 200 |
| Flawless | 100% accuracy in 100-hand Quiz session | 500 |

**Streak Achievements**
| Achievement | Requirement | XP Bonus |
|-------------|-------------|----------|
| On Fire | 10 correct in a row | 25 |
| Hot Streak | 25 correct in a row | 75 |
| Unstoppable | 50 correct in a row | 150 |
| Legendary | 100 correct in a row | 500 |

**Special Achievements**
| Achievement | Requirement | XP Bonus |
|-------------|-------------|----------|
| Night Owl | Play between midnight and 5am | 10 |
| Early Bird | Play before 6am | 10 |
| Weekend Warrior | Play 100+ hands on Saturday AND Sunday | 50 |
| Analyst | Use Hand Analyzer 50 times | 50 |
| Simulator | Run 10 simulations | 75 |
| Comeback Kid | Improve accuracy by 20% in one week | 100 |

**Hidden Achievements** (discovered by doing)
| Achievement | Requirement | XP Bonus |
|-------------|-------------|----------|
| Royal Treatment | Get dealt a royal flush in Play Mode | 100 |
| Against the Odds | Correctly play a hand where the right answer isn't obvious | 50 |
| The Hard Way | Complete a drill with 10/10 | 50 |

---

### 3. Streak System

#### Daily Streak
- Consecutive days with at least 1 Quiz Mode session
- Visual "flame" icon with day count
- Streak freeze available (1 per week for premium users)

#### Streak Rewards
| Days | Reward |
|------|--------|
| 3 | 10 bonus XP |
| 7 | 25 bonus XP + "Week Warrior" badge |
| 14 | 50 bonus XP |
| 30 | 100 bonus XP + "Monthly Master" badge |
| 60 | 200 bonus XP |
| 100 | 500 bonus XP + "Century" badge + exclusive card back |
| 365 | 2,000 bonus XP + "Year of Dedication" badge |

#### Streak Recovery
- Miss a day? Option to "repair" streak:
  - Watch ad (free users)
  - Use streak freeze (premium)
  - Complete 50 Quiz hands to restore (anyone)

---

### 4. Leaderboards

#### Leaderboard Types

**Weekly Leaderboards**
- Most XP earned this week
- Highest Quiz accuracy this week
- Longest streak this week
- Most hands played this week

**All-Time Leaderboards**
- Total XP
- Total hands played
- Best ever streak
- Most achievements

**Friends Leaderboard**
- Compare with friends who also use the app
- Requires optional social connection

#### Leaderboard Rewards
| Position | Weekly Reward |
|----------|---------------|
| 1st | 500 XP + "Champion" badge (temporary) |
| 2nd-3rd | 250 XP |
| 4th-10th | 100 XP |
| Top 10% | 50 XP |
| Participation | 10 XP (played 50+ hands) |

---

### 5. Challenges & Events

#### Daily Challenges
Rotating challenges that refresh every 24 hours:

| Challenge Type | Example | Reward |
|----------------|---------|--------|
| Accuracy | Get 85%+ accuracy in 25 hands | 30 XP |
| Volume | Play 50 hands in Play Mode | 20 XP |
| Streak | Get a 10-hand streak | 25 XP |
| Learning | Complete a drill with 8/10+ | 25 XP |
| Variety | Play 3 different game variants | 20 XP |

#### Weekly Challenges
Larger challenges that span the week:

- "Marathon": Play 500 hands
- "Scholar": Complete 2 lessons
- "Perfectionist": Achieve 95% weekly accuracy
- "Explorer": Try all game variants

#### Special Events
Time-limited events (holidays, app anniversaries):

- "Royal Rush Week": 2x XP for royal flush hands
- "New Year, New Strategy": Bonus XP for lesson completion
- "Summer Grind": Leaderboard with exclusive rewards

---

## Key Decisions Required

### 1. XP Economy Balance

**Concern:** Too easy to level = no sense of progression. Too hard = frustration.

**Proposed Testing:**
- Target: Level 5 at ~2 weeks of moderate use (20 hands/day)
- Target: Level 10 at ~3 months of moderate use
- Soft cap at Level 10 with prestige system beyond

**Decision Needed:** Final XP values for each activity

### 2. Competitive vs. Personal

**Option A: Heavy Competition**
- Prominent leaderboards
- Weekly tournaments
- Head-to-head challenges

**Option B: Personal Progress Focus**
- Leaderboards optional/hidden
- Focus on self-improvement metrics
- "Compete with yesterday's you"

**Option C: Hybrid**
- Personal progress primary
- Opt-in to competitive features
- Friends-only leaderboard by default

**Recommendation:** Option C - appeals to both casual and competitive users

### 3. Premium Gamification Features

What gamification elements should be premium-only?

| Feature | Free | Premium |
|---------|------|---------|
| XP earning | Yes | Yes |
| Basic achievements | Yes | Yes |
| Rare achievements | Some | All |
| Leaderboards | View only | Full participation |
| Daily challenges | 1/day | 3/day |
| Streak freeze | No | 1/week |
| Custom card backs | 2 basic | All unlockable |
| Profile badges | Basic | All |

### 4. Social Features

**Option A: No Social**
- Fully single-player experience
- Simpler implementation
- Privacy-friendly

**Option B: Anonymous Social**
- Leaderboards with usernames
- No direct messaging
- No friend connections

**Option C: Full Social**
- Friend system
- Challenge friends to duels
- Share achievements
- In-app messaging

**Recommendation:** Option B initially, expand to C based on demand

### 5. Reward Tangibility

Should rewards have functional value or just cosmetic?

**Functional Rewards (controversial):**
- Extra Quiz hands per day
- Priority offline downloads
- Advanced statistics

**Cosmetic Only:**
- Card backs
- Profile badges
- UI themes

**Recommendation:** Cosmetic only - functional rewards feel pay-to-win

---

## Data Model

```swift
// Player profile
struct PlayerProfile: Codable {
    let id: UUID
    var displayName: String
    var level: Int
    var totalXP: Int
    var currentStreak: Int
    var longestStreak: Int
    var totalHandsPlayed: Int
    var selectedCardBack: String
    var selectedBadge: String?
    var achievements: [AchievementRecord]
    var createdAt: Date
    var lastActiveAt: Date
}

// Achievement tracking
struct AchievementRecord: Codable {
    let achievementId: String
    let unlockedAt: Date
    let progress: Int?  // For progressive achievements
}

// XP transaction log
struct XPTransaction: Codable {
    let id: UUID
    let amount: Int
    let source: XPSource
    let timestamp: Date
    let metadata: [String: String]?  // e.g., "streak_length": "15"
}

enum XPSource: String, Codable {
    case playModeHand
    case playModeOptimal
    case quizModeCorrect
    case quizModeStreak
    case lessonComplete
    case drillComplete
    case reviewComplete
    case dailyLogin
    case achievementBonus
    case leaderboardReward
    case challengeComplete
}

// Leaderboard entry
struct LeaderboardEntry: Codable {
    let rank: Int
    let playerId: UUID
    let displayName: String
    let score: Int
    let badge: String?
}
```

---

## UI Components

### XP Bar (Always Visible)
```
┌────────────────────────────────────┐
│  Level 7 ████████████░░░░ 2,450 XP │
│  Expert      550 to Level 8        │
└────────────────────────────────────┘
```

### Achievement Toast
```
┌────────────────────────────────────┐
│  🏆 ACHIEVEMENT UNLOCKED!          │
│                                     │
│  "Hot Streak"                       │
│  Get 25 correct answers in a row   │
│                                     │
│  +75 XP                            │
└────────────────────────────────────┘
```

### Profile Screen
```
┌─────────────────────────────────────┐
│         [Avatar/Badge]              │
│         PokerWizard42               │
│         Level 8 - Master            │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  📊 STATS                          │
│  ├─ Total Hands: 12,456            │
│  ├─ Accuracy: 94.2%                │
│  ├─ Current Streak: 🔥 14 days     │
│  └─ Longest Streak: 45 days        │
│                                     │
│  🏆 ACHIEVEMENTS                   │
│  [🎯] [📚] [🔥] [⭐] [🎰] +12 more │
│                                     │
│  🎨 CARD BACKS                     │
│  [Default] [🔓] [🔓] [🔒] [🔒]    │
│                                     │
│  📈 LEADERBOARD RANK               │
│  Weekly: #47 | All-Time: #234      │
└─────────────────────────────────────┘
```

---

## Implementation Phases

### Phase 1: Core Progression
- XP system with basic earning
- Level progression (1-10)
- 10 starter achievements
- Daily streak tracking
- Basic profile page

### Phase 2: Engagement
- Full achievement system (30+ achievements)
- Daily/weekly challenges
- Streak recovery mechanics
- Card back unlocks

### Phase 3: Social
- Anonymous leaderboards
- Weekly competitions
- Special events framework
- Friends system (if demand exists)

---

## Success Metrics

| Metric | Target |
|--------|--------|
| DAU/MAU ratio | >30% (up from baseline) |
| Day 7 retention | >40% |
| Day 30 retention | >20% |
| Average session length | +25% |
| Sessions per week | +50% |
| Achievement unlock rate | 60% unlock at least 5 |

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| XP inflation over time | Periodic rebalancing, prestige system |
| Leaderboard cheating | Server-side validation, anomaly detection |
| Feature bloat | Keep core loop simple, gamification as enhancement |
| Player burnout | Don't punish missed days heavily, allow casual play |
| Distraction from learning | XP tied to correct plays, not just volume |

---

## Open Questions

1. Should there be a "prestige" system where you reset to Level 1 with a badge?
2. How do we handle players who already have history when we launch this?
3. Should achievements be retroactive (awarded for past play)?
4. What's the right balance between skill-based and volume-based achievements?
5. Should we have "negative" tracking (e.g., "hands since last mistake")?
6. How prominent should the XP bar be in the UI during normal play?
