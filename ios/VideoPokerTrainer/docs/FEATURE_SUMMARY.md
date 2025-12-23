# Video Poker Trainer - Feature Summary

## Quick Overview

This document provides a condensed view of the full feature roadmap. See `FEATURE_ROADMAP.md` for complete PRDs.

---

## Prioritized Feature List

### Priority 1: Core Training Excellence (Immediate)
| Feature | Description | Effort |
|---------|-------------|--------|
| Sound & Haptics | Audio feedback for actions, haptic on mobile | 9 days |
| Strategy Explanations | Show WHY holds are optimal, not just WHAT | 13 days |
| Session History | Save and replay training sessions | 9 days |

### Priority 2: Smart Learning (Next)
| Feature | Description | Effort |
|---------|-------------|--------|
| Spaced Repetition | Intelligent review scheduling based on mistakes | 9 days |
| Mastery Dashboard | Visual progress tracking by hand type | 5 days |
| Weak Spots Drill | Focused practice on problem areas | 4 days |
| Offline Mode | Full functionality without internet | 10 days |

### Priority 3: Advanced Tools
| Feature | Description | Effort |
|---------|-------------|--------|
| Strategy Card Generator | Printable strategy cards for casino use | 7 days |
| Bankroll Calculator | Risk of ruin and session variance tools | 9 days |
| Progressive Calculator | Adjust strategy for progressive jackpots | 5 days |
| Multi-Hand Training | 3/5/10/50/100-play training modes | 13 days |

### Priority 4: Engagement & Social
| Feature | Description | Effort |
|---------|-------------|--------|
| Achievements | 20+ achievement badges with notifications | 11 days |
| Friend System | Add friends, compare progress | 8 days |
| Challenges | Head-to-head accuracy contests | 12 days |
| Leaderboards | Global and friend rankings | 6 days |

### Priority 5: Premium Features
| Feature | Description | Effort |
|---------|-------------|--------|
| Ultimate X Training | Full Ultimate X with multiplier strategy | 17 days |
| Casino Finder | Find best paytables by location | 16 days |
| Paytable Scanner | Camera-based OCR for paytables | 20 days |

---

## Market Gaps We Address

| Gap | Our Solution |
|-----|--------------|
| No spaced repetition in any VP trainer | PRD-001: Full SM-2 style algorithm |
| Apps say "wrong" but not "why" | PRD-002: Detailed EV explanations |
| No mobile-first modern experience | Beautiful React Native app |
| Fragmented tools (separate apps) | Unified experience |
| No social/competitive features | Friend challenges, leaderboards |
| Require constant connectivity | Offline-first with sync |

---

## Competitive Comparison

| Feature | Us | WinPoker | VP.com Pro | Play Perfect |
|---------|-----|----------|------------|--------------|
| Mobile-first | Yes | No | Partial | Yes |
| Spaced repetition | Yes | No | No | No |
| Strategy explanations | Yes | Partial | Partial | No |
| Offline mode | Yes | Yes | No | Yes |
| Social features | Yes | No | No | No |
| Modern UI | Yes | No | Partial | Partial |
| Free tier | Yes | Trial | No | Lite version |

---

## Monetization

**Free Tier:**
- Jacks or Better training
- Basic quiz mode
- Limited hand analyzer

**Premium ($4.99/mo or $39.99/yr):**
- All games
- Unlimited analyzer
- Spaced repetition
- Strategy cards
- All tools
- Ad-free

**Lifetime ($79.99):**
- Everything forever

---

## Implementation Phases

```
Phase 1 (4 weeks): Core Excellence
├── Sound & Haptics
├── Basic Explanations
└── Basic Session History

Phase 2 (6 weeks): Smart Learning
├── Spaced Repetition
├── Mastery Dashboard
├── Weak Spots Drill
└── Offline Mode

Phase 3 (6 weeks): Advanced Tools
├── Strategy Cards
├── Bankroll Calculator
├── Progressive Calculator
└── Multi-Hand

Phase 4 (8 weeks): Social
├── Achievements
├── User Accounts
├── Friends
└── Challenges

Phase 5 (8 weeks): Premium
├── Ultimate X
├── Casino Finder
└── Paytable Scanner
```

---

## Key Differentiators

1. **Only VP app with spaced repetition** - Proven learning science
2. **Explains the "why"** - Not just error detection
3. **Beautiful modern mobile UI** - Most competitors are dated
4. **Offline-first architecture** - Train anywhere
5. **Social competition** - Makes learning fun
6. **Unified tool suite** - Not fragmented apps

---

## Success Targets

| Metric | 6-Month Target |
|--------|----------------|
| App Store Rating | 4.8+ |
| DAU | 10,000 |
| 30-Day Retention | 25% |
| Free-to-Paid Conversion | 5% |

---

## Navigation Structure

```
[Home] [Train] [Analyze] [Progress] [Social]
   │       │        │         │         │
   └─Quick └─Quiz   └─Hand    └─Stats   └─Friends
     Play    Setup    Analyzer   History   Challenges
             Drills   Tools      Mastery   Leaderboard
```

---

*See FEATURE_ROADMAP.md for complete PRDs and technical details.*
