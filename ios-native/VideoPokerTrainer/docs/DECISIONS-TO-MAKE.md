# Decisions to Make: VP Academy Features

Use this document to make decisions on the airplane. Circle or highlight your choices, add notes, and I'll implement accordingly.

---

## 1. FREEMIUM MODEL

### 1.1 Pricing Model
Which pricing structure do you prefer?

- [ ] **A: Subscription Only**
  - Monthly: $3.99
  - Annual: $29.99

- [ ] **B: Subscription + Lifetime**
  - Monthly: $3.99
  - Annual: $29.99
  - Lifetime: $49.99 *(Recommended)*

- [ ] **C: One-Time Purchase**
  - Full unlock: $9.99 (matches Wizard of Odds)

- [ ] **D: Tiered Unlocks**
  - Per-game family: $2.99 each
  - All games bundle: $9.99

**Your choice:** A

**Notes:** _____________________________________________

---

### 1.2 Free Tier - Games Available
How many games should be free?

- [ ] **A: JoB 9/6 only** (most restrictive, creates clear upgrade path)
- [ ] **B: JoB 9/6 + Deuces Wild Full Pay** (two popular games)
- [ ] **C: One game per family** (JoB, Deuces, Bonus, etc.)
- [ ] **D: All games free, premium = features only**

**Your choice:** I think all games, but there should be daily limits

---

### 1.3 Free Tier - Daily Limits
What daily limits for free users?

| Feature | Option A | Option B | Option C |
|---------|----------|----------|----------|
| Quiz hands/day | 10 | 25 | 50 |
| Hand analyses/day | 5 | 10 | 20 |
| Simulation hands | 1,000 max | 5,000 max | 10,000 max |

**Your choice:** Perhaps it should just be 50 hands per day regardless of mode (quiz, Play, or Hand analysis.) And 2 simulations per day.

---

### 1.4 Trial Strategy
Should we offer a free trial of premium?

- [ ] **A: 7-day free trial** (industry standard for games)
- [ ] **B: 3-day free trial** (gaming apps prefer shorter)
- [ ] **C: No trial** (rely on generous free tier)
- [ ] **D: Trial for specific features only** (e.g., Training Mode trial)

**Your choice:** A

---

### 1.5 Grandfather Existing Users?
What happens to current users when freemium launches?

- [ ] **A: 1-year free premium** (generous, builds goodwill)
- [ ] **B: 6-month free premium**
- [ ] **C: Lifetime free premium** (they were early adopters)
- [ ] **D: No grandfathering** (everyone starts fresh)

**Your choice:** D.  We don't really have existing users.  I would like to be able to give away free usage somehow.  Not sure the best way to do this with the iPhone App Store subscription setup model.

---

### 1.6 Open Questions

**Q1:** Should we offer family sharing? (Increases value but reduces per-seat revenue)
- [ ] Yes  [X] No  [ ] Decide later

**Q2:** Should Simulation Mode be free with ads instead of limited?
- [ ] Yes  [X] No  [ ] No ads anywhere

**Q3:** Should we offer a cheaper "Games Only" tier without Training Mode?
- [ ] Yes, at $____ /month  [X] No, keep it simple

---

## 2. TRAINING MODE

### 2.1 Curriculum Scope (MVP)
How much content for initial launch?

- [ ] **A: JoB only** (6 lessons, fastest to market)
- [ ] **B: JoB + Deuces Wild** (12 lessons)
- [ ] **C: JoB + Deuces + Bonus Poker** (18 lessons)
- [ ] **D: All game families** (30+ lessons, significant effort)

**Your choice:** I'd like to be able to automatically be able to generate lessons based on the payables and what we know to be interesting decisions.  Note: Close (from an EV perspective) decisions aren't necessarily interesting.  Long term, I'm thinking interesting decisions are just ones where people have a high propensity of missing a certain class of hand.  For example, picking a low pair instead of 4 to the flush.  We are keeping track of user responses.  I'd like to write a process that data mines these responses to look for patterns to figure out which hands we should train users on.  I think at the start we can just start with the "Popular Games" but I'd like to branch out to get trainings for all games/paytables we have on the app.

---

### 2.2 Mistake Data Storage
Where should we store user mistake history?

- [ ] **A: Local only** (simpler, more private)
- [ ] **B: Cloud sync to Supabase** (enables cross-device, aggregate insights)

**Your choice:** I thought we were already syncing to supabase.  Is this correct?

---

### 2.3 Lesson Progression
How should lessons unlock?

- [ ] **A: Linear** (must complete Lesson 1 before 2)
- [ ] **B: Flexible** (complete any 3 to unlock next tier)
- [ ] **C: Assessment-based** (test out if you already know it)
- [ ] **D: Linear + test out option** *(Recommended)*

**Your choice:** I think people should be able to take any lesson at any time, but by default we would walk them through lessons from start to finish from most basic to most rare/complex.

---

### 2.4 Spaced Repetition Algorithm
How sophisticated should the review system be?

- [ ] **A: Simple fixed intervals** (1 day, 3 days, 7 days, 14 days)
- [ ] **B: SM-2 algorithm** (adjusts based on performance)
- [ ] **C: Poker-specific** (weight by EV impact and category)

**Your choice:** B

---

### 2.5 Open Questions

**Q1:** Should lessons include video/animation or text only?
- [X] Text only (faster to create)
- [ ] Simple animations
- [ ] Full video explanations

**Q2:** For "close call" hands (EV within 0.05), should both answers count as correct?
- [ ] Yes, both correct  [X] No, only optimal  [ ] Show as "acceptable" but not optimal

**Q3:** Should we show EV numbers during training or keep it abstract ("better"/"worse")?
- [X] Show exact EV  [ ] Abstract only  [ ] User preference toggle

Extra note: Ev is to challenging for some users to grasp, so perhaps we should say you are betting $5 per hand ($1 denomination single line) and let them know how much they would have lost

**Q4:** Should Training Mode be premium-only or have a free tier?
- [ ] Premium only  [ ] First lesson free  [X] First 3 lessons free

---

## 3. GAMIFICATION

### 3.1 XP Earning Rate
How fast should players level up?

| Pace | Level 5 at | Level 10 at |
|------|------------|-------------|
| **Fast** | 1 week | 1 month |
| **Medium** | 2 weeks | 3 months |
| **Slow** | 1 month | 6 months |

**Your choice:** It should be based on how much they play, how many mistakes they make (the lower the better), how many different games they know, etc.

---

### 3.2 Competitive vs. Personal
What's the primary focus?

- [ ] **A: Heavy competition** (prominent leaderboards, tournaments, head-to-head)
- [ ] **B: Personal progress** (leaderboards hidden/optional, focus on self-improvement)
- [ ] **C: Hybrid** (personal progress primary, opt-in to competitive) *(Recommended)*

**Your choice:** B

---

### 3.3 Social Features
How social should the app be?

- [ ] **A: No social** (single-player only)
- [ ] **B: Anonymous social** (leaderboards with usernames, no direct interaction)
- [ ] **C: Friends system** (add friends, compare progress, no messaging)
- [ ] **D: Full social** (friends, messaging, challenges)

**Your choice:** A

---

### 3.4 Reward Type
Should unlockable rewards be cosmetic only or have functional value?

- [ ] **A: Cosmetic only** (card backs, badges, themes)
- [ ] **B: Functional** (extra Quiz hands, priority downloads)
- [ ] **C: Mix** (mostly cosmetic, minor functional perks)

**Your choice:** A

---

### 3.5 Premium Gamification
What gamification features are premium-only?

| Feature | Free | Premium Only |
|---------|------|--------------|
| XP earning | [ ] | [ ] |
| Achievements | [ ] | [ ] |
| Leaderboards | [ ] View only / [ ] Full | |
| Daily challenges | [ ] 1/day / [ ] 3/day | |
| Streak freeze | [ ] | [ ] |
| Custom card backs | [ ] 2 basic / [ ] All | |

All gamification should be both Free and Premium.  To start, let's just do XP earning and Achievements
---

### 3.6 Open Questions

**Q1:** Should there be a "prestige" system (reset to Level 1 with badge)?
- [ ] Yes  [X] No

**Q2:** Should achievements be retroactive for existing play history?
- [ ] Yes (award for past play)  [X] No (start fresh)

**Q3:** How prominent should the XP bar be during normal play?
- [ ] Always visible  [ ] Collapsed/minimal  [X] Hidden during play, visible after

If there is some achievement that happens this could be a toast popup.

**Q4:** Should we track "negative" stats (e.g., "hands since last mistake")?
- [ ] Yes  [X] No

---

## 4. CASINO HOST MARKETPLACE

### 4.1 Geographic Scope (MVP)
Where should we launch first?

- [ ] **A: Las Vegas only** (highest concentration, easiest to verify)
- [ ] **B: Las Vegas + Reno**
- [ ] **C: Major gaming markets** (LV, Reno, AC, tribal)
- [ ] **D: National** (anywhere with casinos)

**Your choice:** A

---

### 4.2 Player Identity Level
How much info do players share with hosts?

- [ ] **A: Fully anonymous** (browse offers, never share identity)
- [ ] **B: Alias + preferences** (hosts see "VPPlayer_42" with stats)
- [ ] **C: Verified identity** (real name, email required)
- [ ] **D: Tiered** (anonymous browse, identity for premium offers) *(Recommended)*

**Your choice:** C

---

### 4.3 Visit Verification
How do we verify a player actually visited a casino?

- [ ] **A: Honor system** (user marks "I visited")
- [ ] **B: GPS check-in** (location verification)
- [ ] **C: Host confirmation** (host marks in dashboard)
- [ ] **D: Players club integration** (connect to loyalty programs)

**Your choice:** C

---

### 4.4 Monetization Model
How should we make money from this feature?

- [ ] **A: CPA only** ($25-50 per verified visit)
- [ ] **B: Host subscription** ($99-999/month tiers)
- [ ] **C: Sponsored offers** (casinos pay to push offers)
- [ ] **D: Hybrid** (subscription + CPA + sponsored) *(Recommended)*

**Your choice:** Ideally a cut of the Theoretical loss for the player, but at the start we could do a flat amount per verified visit.

---

### 4.5 Player Cost
Should players pay anything for marketplace access?

- [ ] **A: Completely free** (hosts pay, players get value)
- [ ] **B: Premium only** (part of subscription)
- [ ] **C: Separate premium tier** (marketplace access = add-on)

**Your choice:** A

---

### 4.6 Open Questions

**Q1:** Should we include online casinos/sportsbooks where legal?
- [ ] Yes  [X] No, land-based only

**Q2:** Should we allow independent hosts (player development consultants)?
- [X] Yes  [ ] No, casino employees only

**Q3:** Should VP Academy take a position on "good" vs "bad" casinos for players?
- [ ] Yes (rate/recommend)  [X] No (neutral platform)  [ ] User reviews only

**Q4:** Should we build a paytable database first (before host connections)?
- [ ] Yes, foundation first  [ ] No, launch together

No, let's just worry about host connections for now.

**Q5:** What's the minimum player activity level to be visible to hosts?
- [ ] Any registered user
- [ ] 100+ hands played
- [ ] Premium subscriber only
- [ ] Verified profile completion

Answer: We will help players when they want to be connected to a host.


## How to Use This Document

1. Read through each section
2. Mark your choices (circle, highlight, or check boxes)
3. Add notes where helpful
4. For "Open Questions" - even a quick Yes/No helps
5. If unsure, write "Discuss" and we'll talk through it
6. Priority ranking (#5) helps me know what to build first

When you're back, share this document (photo, scan, or typed notes) and I'll implement according to your decisions.
