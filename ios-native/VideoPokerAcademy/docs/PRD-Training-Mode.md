# PRD: Training Mode for VP Academy

## Overview
Training Mode is a structured learning system that teaches users optimal video poker strategy through progressive lessons, targeted practice on common decision points, and personalized review of hands they've missed during gameplay.

---

## Problem Statement

Current learning path for video poker strategy:
1. **Play Mode** - Practice but no structured learning
2. **Quiz Mode** - Random hands, no progression
3. **Hand Analyzer** - Manual lookup, requires knowing what to search

**Gap:** No guided path from beginner to expert. Users don't know what they don't know.

---

## Core Training Components

### 1. Lesson-Based Curriculum

Structured lessons that teach strategy concepts progressively.

#### Jacks or Better Curriculum Example

| Lesson | Topic | Hands Covered |
|--------|-------|---------------|
| 1 | Made Hands | When to break up made hands (pairs, two pair, straights) |
| 2 | High Cards vs. Draws | Holding high cards vs. 4-card flush/straight draws |
| 3 | The Penalty Card System | How kickers affect straight draws |
| 4 | Three-Card Royals | When to chase the royal flush |
| 5 | Garbage Hands | Optimal play with no obvious holds |
| 6 | Close Decisions | Hands within 0.1 EV of each other |
| 7 | Deuces Wild Basics | (separate game curriculum) |
| 8 | Advanced: Full Pay vs. Short Pay | Strategy adjustments for different paytables |

#### Lesson Structure

```
┌─────────────────────────────────────────┐
│  LESSON 3: The Penalty Card System      │
├─────────────────────────────────────────┤
│  📖 Concept Introduction (1-2 screens)  │
│     - What are penalty cards?           │
│     - Why they matter for EV            │
│                                         │
│  🎯 Guided Examples (3-5 hands)         │
│     - Show hand, explain optimal play   │
│     - Highlight the penalty card        │
│                                         │
│  ✏️ Practice Quiz (10 hands)            │
│     - User plays, gets feedback         │
│     - Must get 8/10 to pass             │
│                                         │
│  🏆 Lesson Complete!                    │
│     - Unlock next lesson                │
│     - Add to "Review Queue"             │
└─────────────────────────────────────────┘
```

---

### 2. Common Decision Drills

Targeted practice on specific decision categories that appear frequently.

#### Decision Categories

| Category | Description | Example |
|----------|-------------|---------|
| **High Pair vs. 4-Flush** | Keep JJ or draw to 4-flush? | J♠ J♥ 5♠ 8♠ 2♠ |
| **Low Pair vs. 4-Straight** | Keep 44 or draw to open-ended straight? | 4♥ 4♦ 5♣ 6♠ 7♥ |
| **3-Royal vs. Made Hand** | Break up flush for 3-card royal? | K♠ Q♠ T♠ 5♠ 2♠ |
| **Suited High Cards** | When to hold 2 suited vs. 3 to a straight | K♠ Q♠ J♥ 9♦ 3♣ |
| **Garbage Hand Triage** | No pairs, no draws - what to hold? | K♥ 9♠ 6♦ 3♣ 2♠ |
| **Inside Straight Draws** | When inside straights are worth it | Q♠ J♥ 9♦ 8♣ 4♠ |
| **Three-Card Straights** | Almost never correct but when? | 9♠ 8♥ 7♦ 3♣ 2♠ |

#### Drill Mode Interface

```
┌──────────────────────────────────────┐
│  DRILL: High Pair vs. 4-Flush       │
│  ─────────────────────────────────  │
│  Progress: ████████░░ 8/10          │
│  Streak: 🔥 5                       │
│                                      │
│  [Card Display - J♠ J♥ 5♠ 8♠ 2♠]   │
│                                      │
│  Your choice: [Hold JJ] [Hold 4♠]   │
│                                      │
│  💡 Hint available (costs streak)   │
└──────────────────────────────────────┘
```

---

### 3. Mistake Review System

Automatically tracks hands where the user made suboptimal plays and queues them for review.

#### Mistake Tracking

```swift
struct TrackedMistake {
    let hand: Hand
    let userHold: Set<Int>
    let optimalHold: Set<Int>
    let evLoss: Double  // How much EV was lost
    let category: DecisionCategory
    let timestamp: Date
    let gameVariant: String
}
```

#### Review Queue Logic

1. **Capture:** During Play Mode and Quiz Mode, log every suboptimal decision
2. **Categorize:** Assign to decision category (High Pair vs. 4-Flush, etc.)
3. **Prioritize:** Sort by:
   - Frequency (same mistake made multiple times)
   - EV impact (bigger mistakes first)
   - Recency (recent mistakes more relevant)
4. **Present:** In Training Mode, drill on mistake categories

#### Smart Review Features

| Feature | Description |
|---------|-------------|
| **Spaced Repetition** | Show mastered concepts less frequently |
| **Mistake Clustering** | "You've missed 5 'High Pair vs. 4-Flush' hands this week" |
| **Weakness Report** | Weekly summary of problem areas |
| **Progress Tracking** | "Your 4-flush decisions improved from 60% to 85%" |

---

### 4. Close Hands Training

Special focus on hands where multiple options have similar EV.

#### What Makes a "Close" Hand?

- EV difference < 0.05 between top 2 options
- These are the hands that separate good players from great

#### Close Hands Interface

```
┌──────────────────────────────────────────┐
│  CLOSE CALL                             │
│  ─────────────────────────────────────  │
│  Hand: K♠ Q♠ J♥ T♦ 3♣                  │
│                                          │
│  Option A: Hold K♠ Q♠         EV: 0.596 │
│  Option B: Hold K♠ Q♠ J♥ T♦   EV: 0.593 │
│                                          │
│  Difference: 0.003 (~$0.015 per hand)   │
│                                          │
│  Both plays are reasonable!             │
│  The suited high cards have a           │
│  slight edge due to royal potential.    │
│                                          │
│  [Mark as Reviewed] [Add to Favorites]  │
└──────────────────────────────────────────┘
```

---

## Key Decisions Required

### 1. Curriculum Scope

**Option A: Comprehensive (All Games)**
- Full curriculum for each game family (JoB, Deuces, Bonus, etc.)
- 50+ total lessons
- Higher development cost, broader appeal

**Option B: Core Games Only**
- Full curriculum for JoB + Deuces Wild only
- "Strategy tips" for other variants
- Faster to market, can expand later

**Recommendation:** Option B initially, expand post-launch

### 2. Mistake Data Storage

**Option A: Local Only**
- Store mistake history on device
- No cloud sync
- Privacy-friendly, simpler

**Option B: Cloud Sync**
- Sync mistakes to Supabase
- Access history across devices
- Enables aggregate analytics ("most common mistakes")

**Recommendation:** Option B - cloud sync enables powerful features and cross-device continuity

### 3. Spaced Repetition Algorithm

**Option A: Simple (Fixed Intervals)**
- Review after 1 day, 3 days, 7 days, 14 days
- Easy to implement

**Option B: SM-2 Algorithm**
- Adjust intervals based on performance
- More effective but complex

**Option C: Custom Poker-Specific**
- Weight by EV impact and category
- Review high-EV mistakes more often

**Recommendation:** Option C - poker-specific logic more valuable than generic SRS

### 4. Lesson Gating

**Option A: Linear Progression**
- Must complete Lesson 1 before Lesson 2
- Ensures foundation

**Option B: Category Unlocks**
- Complete any 3 lessons to unlock next tier
- More flexibility

**Option C: Assessment-Based**
- Take diagnostic quiz, unlock appropriate lessons
- Best for experienced players

**Recommendation:** Option A for beginners, with Option C "test out" for returning users

---

## Data Model

```swift
// Lesson progress tracking
struct LessonProgress {
    let lessonId: String
    let gameVariant: String
    var status: LessonStatus  // .locked, .available, .inProgress, .completed
    var quizScore: Int?
    var completedAt: Date?
    var reviewDueAt: Date?
}

enum LessonStatus {
    case locked
    case available
    case inProgress
    case completed
    case needsReview
}

// Drill session tracking
struct DrillSession {
    let category: DecisionCategory
    let handsPresented: Int
    let correctAnswers: Int
    let averageResponseTime: TimeInterval
    let completedAt: Date
}

// Mistake for review
struct MistakeRecord: Codable {
    let id: UUID
    let handId: String  // Canonical hand representation
    let userHoldMask: Int
    let optimalHoldMask: Int
    let evLoss: Double
    let category: String
    let gameVariant: String
    let source: MistakeSource  // .playMode, .quizMode, .drill
    let createdAt: Date
    var reviewCount: Int
    var lastReviewedAt: Date?
    var nextReviewAt: Date?
    var masteryLevel: Int  // 0-5, increases with correct reviews
}
```

---

## UI/UX Considerations

### Training Mode Home Screen

```
┌─────────────────────────────────────────┐
│  TRAINING MODE                         │
├─────────────────────────────────────────┤
│                                         │
│  📚 LESSONS                            │
│  ├─ Jacks or Better    ████░░ 4/6     │
│  ├─ Deuces Wild        ░░░░░░ 0/5     │
│  └─ Bonus Poker        🔒 Locked       │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  🎯 DRILLS                             │
│  ├─ High Pair vs. 4-Flush   [Start]   │
│  ├─ 3-Card Royals           [Start]   │
│  └─ Garbage Hands           [Start]   │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  🔄 REVIEW QUEUE              12 hands │
│  ├─ 5 from Play Mode mistakes          │
│  ├─ 4 from lesson reviews              │
│  └─ 3 close hands to study             │
│                                         │
│  [Start Review Session]                │
│                                         │
└─────────────────────────────────────────┘
```

### Progress Visualization

- Skill radar chart showing competency in each category
- Streak tracking for motivation
- "Hands to Mastery" countdown for each topic

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Lesson completion rate | >70% start → finish |
| Drill session length | 5+ minutes average |
| Review queue engagement | 60% of users with queue items review weekly |
| Play Mode accuracy improvement | 10% improvement after Training completion |
| User retention (Training users vs. non) | 2x Day 30 retention |

---

## Implementation Phases

### Phase 1: Foundation (MVP)
- Lesson framework with 3 JoB lessons
- Basic mistake tracking in Play Mode
- Simple review queue

### Phase 2: Full Curriculum
- Complete JoB + Deuces curriculum
- Drill mode for all decision categories
- Spaced repetition for reviews

### Phase 3: Intelligence
- Personalized lesson recommendations
- Weakness detection and targeted drills
- Aggregate insights ("You're in the top 10% for 3-card royal decisions")

---

## Open Questions

1. Should lessons include video/animation explanations or text only?
2. How do we handle hands that are close calls - mark both as "correct"?
3. Should we show EV numbers during training or keep it abstract?
4. What's the minimum lesson set for launch?
5. Should Training Mode be premium-only or have a free tier?
