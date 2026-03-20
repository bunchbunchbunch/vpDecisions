# PRD: Dealt Winner Celebration Feature

## Overview
Add authentic video poker machine behavior that celebrates when the player is dealt a winning hand (a "pat hand"). This enhances the training experience by providing immediate positive feedback and mimicking real casino play.

## Problem Statement
Currently, when users are dealt a winning hand (e.g., a pair of Jacks in Jacks or Better), there's no immediate indication that they already have a paying hand. Real video poker machines celebrate dealt winners with:
- Special sound effects
- Visual highlighting of the winning cards
- Display of the hand name

This missing feedback:
1. Reduces the authentic casino feel
2. Misses an opportunity for positive reinforcement
3. Doesn't teach users to recognize pat hands instantly

## Success Metrics
- User engagement: % of users who complete more quiz hands after implementation
- Retention: DAU/MAU improvement in first 2 weeks
- User feedback: Positive sentiment in app reviews mentioning "realistic" or "authentic"
- Educational: Reduction in time to identify pat hands (measured by response time)

## User Stories

### As a quiz mode user
- I want to hear a celebratory sound when dealt a winning hand
- I want to see which cards form the winning combination
- I want to know what hand I was dealt (e.g., "Pair of Jacks")
- So that I feel the excitement of real video poker and learn to recognize winners

### As a weak spots trainee
- I want the same celebration for dealt winners
- So that positive reinforcement helps me recognize these hands faster

## Functional Requirements

### FR1: Detect Dealt Winners
**Priority:** P0 (Must Have)

When a hand is dealt in quiz or weak spots mode:
1. Check if the initial 5-card deal is a paying hand for the current paytable
2. Minimum paying hands vary by game:
   - Jacks or Better 9/6: Pair of Jacks or better
   - Double Double Bonus 9/6: Pair of Jacks or better
   - Deuces Wild NSUD: Three of a Kind
   - Deuces Wild Full Pay: Three of a Kind
   - Bonus Poker 8/5: Pair of Jacks or better
   - Double Bonus 10/7: Pair of Jacks or better
   - Triple Double Bonus 9/6: Pair of Jacks or better
   - All American: Pair of Jacks or better
   - Bonus Poker Deluxe 8/6: Pair of Jacks or better
   - Tens or Better 6/5: Pair of Tens or better

### FR2: Audio Celebration
**Priority:** P0 (Must Have)

When a dealt winner is detected:
1. Play a distinct "dealt winner" sound effect
2. Sound should be:
   - Different from the standard card flip sound
   - Celebratory but not jarring (1-2 seconds max)
   - Similar to real VP machines (chime/ding pattern)
3. Sound plays immediately after cards are displayed
4. Respects existing audio settings (can be muted)

**Implementation Notes:**
- Add new sound file: `dealt-winner.mp3`
- Use existing AudioService infrastructure
- Play after card deal animation completes

### FR3: Visual Highlighting
**Priority:** P0 (Must Have)

When a dealt winner is detected:
1. Highlight the winning cards with a visual effect:
   - Gold/yellow glow or border around winning cards
   - Subtle pulsing animation (0.5s pulse, 2-3 cycles)
   - Cards slightly elevated/scaled (1.05x)
2. Show hand name banner:
   - Display hand type (e.g., "Pair of Queens", "Three of a Kind")
   - Position: Center above cards
   - Style: Gold/yellow background with white text
   - Font: Bold, 18pt
   - Duration: 2 seconds, then fade out
3. Animation sequence:
   - Cards deal normally (existing animation)
   - 0.3s pause
   - Sound plays + highlighting begins
   - Hand name appears
   - After 2s, highlighting fades but cards remain selected

### FR4: No Auto-Selection
**Priority:** P0 (Must Have)

When a dealt winner is detected:
1. Cards are NOT automatically selected
2. User must still make their selection
3. Visual state:
   - Winning glow is independent of selection state
   - User can select/deselect as normal

**Rationale:** This maintains the training aspect - users should practice identifying and selecting winning cards themselves, even when highlighted.

### FR5: Paytable-Specific Logic
**Priority:** P0 (Must Have)

Implement correct minimum paying hand detection for each paytable:

#### Jacks or Better Games
- Minimum: Pair of Jacks or better (J, Q, K, A)
- Check: Count cards by rank, find pairs of J/Q/K/A

#### Tens or Better
- Minimum: Pair of Tens or better (T, J, Q, K, A)
- Check: Count cards by rank, find pairs of T/J/Q/K/A

#### Deuces Wild Games
- Minimum: Three of a Kind
- Check: Count non-deuce cards, include deuces as wilds

#### Bonus/Double Bonus Games
- Minimum: Pair of Jacks or better
- Note: Higher quads pay more but detection is same as Jacks or Better

### FR6: Integration with Quiz Flow
**Priority:** P0 (Must Have)

1. Celebration occurs immediately when cards are dealt
2. After celebration animation (2s), user can interact with cards normally
3. User must still select which cards to hold (no auto-selection)
4. Celebration does not count against response time metrics
5. Works in both:
   - Standard quiz mode
   - Weak spots mode
   - Close decisions mode (if dealt hand happens to be a winner)

### FR7: Always Enabled
**Priority:** P0 (Must Have)

Dealt winner celebration is always enabled:
- No settings toggle required
- Consistent experience for all users
- Simpler implementation and maintenance

**Rationale:** The feature enhances learning and authenticity without being intrusive (2-second duration). Making it always-on simplifies the user experience.

## Non-Functional Requirements

### NFR1: Performance
- Detection must complete in < 50ms
- Animation must be smooth (60fps)
- No impact on hand loading time

### NFR2: Audio Quality
- Sound file < 100KB
- High quality audio (44.1kHz, AAC)
- No audio clipping or distortion

### NFR3: Accessibility
- Celebration must work with VoiceOver
- Announce hand name audibly
- Visual effects must meet WCAG contrast requirements
- Haptic feedback for deaf users (optional P2)

## Technical Implementation

### Architecture
```
QuizPlayView
  ├─ QuizViewModel
  │   ├─ loadQuiz() - deal hands
  │   └─ checkDealtWinner() - NEW
  │
  ├─ AudioService
  │   └─ play(.dealtWinner) - NEW
  │
  └─ DealtWinnerView - NEW
      ├─ Hand name banner
      └─ Card highlighting overlay
```

### Key Functions

#### 1. Hand Evaluation
```swift
// In QuizViewModel or new HandEvaluator service
func isDealtWinner(hand: Hand, paytableId: String) -> (isWinner: Bool, handName: String?, winningIndices: [Int]) {
    // Get minimum paying hand for paytable
    let minPayout = getMinimumPayingHand(paytableId)

    // Evaluate hand
    let handType = evaluateHand(hand)

    if handType.payout >= minPayout {
        return (true, handType.name, handType.cardIndices)
    }

    return (false, nil, [])
}
```

#### 2. Animation Controller
```swift
// In QuizPlayView
@State private var showDealtWinner = false
@State private var dealtWinnerName: String? = nil
@State private var winningIndices: [Int] = []

func onHandDealt() {
    let result = viewModel.isDealtWinner()

    if result.isWinner {
        withAnimation(.easeInOut(duration: 0.3).delay(0.3)) {
            showDealtWinner = true
            dealtWinnerName = result.handName
            winningIndices = result.winningIndices
        }

        // Play sound
        AudioService.shared.play(.dealtWinner)
        HapticService.shared.trigger(.success)

        // Hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showDealtWinner = false
            }
        }
    }
}
```

### New Files Required
1. **Services/HandEvaluator.swift** - Hand evaluation logic
2. **Views/Components/DealtWinnerBanner.swift** - Hand name banner component
3. **Views/Components/CardGlowEffect.swift** - Winning card glow modifier
4. **Assets/Sounds/dealt-winner.mp3** - Celebration sound

### Modified Files
1. **ViewModels/QuizViewModel.swift** - Add dealt winner detection
2. **Views/Quiz/QuizPlayView.swift** - Add celebration UI
3. **Services/AudioService.swift** - Add .dealtWinner case
4. **Models/HandCategory.swift** - Add hand evaluation methods

## UI/UX Specifications

### Visual Design

#### Winning Card Glow
```
- Glow color: #FFD700 (gold)
- Glow radius: 8px
- Shadow: 0px 0px 20px rgba(255, 215, 0, 0.6)
- Pulsing: opacity 0.4 → 1.0 → 0.4 (1s cycle, 2 cycles)
- Card scale: 1.0 → 1.05 → 1.0
```

#### Hand Name Banner
```
- Background: Linear gradient #FFD700 to #FFA500
- Border: 2px solid #FFFFFF
- Border radius: 12px
- Padding: 16px 24px
- Font: SF Pro Bold, 18pt
- Text color: #FFFFFF
- Shadow: 0px 4px 12px rgba(0, 0, 0, 0.3)
- Position: Center, 20px above cards
```

### Animation Timeline
```
0.0s:  Cards deal normally
0.3s:  Pause (cards visible)
0.3s:  Sound plays
0.3s:  Glow begins
0.3s:  Banner fades in (0.2s)
0.5s:  Pulsing animation (2 cycles over 2s)
2.5s:  Banner fades out (0.3s)
2.8s:  Glow fades out (0.3s)
3.1s:  Animation complete, user can interact
```

## Sound Design

### Dealt Winner Sound
- Style: Celebratory chime (similar to "ding-ding-ding" pattern)
- Duration: 1.2 - 1.5 seconds
- Notes: Consider ascending C-E-G major chord
- Inspiration: Real IGT/Aristocrat VP machine sounds
- Volume: Slightly louder than card flip (1.2x)

### Alternative Sound Sources
1. Record from real VP machine (if legal)
2. Commission from sound designer
3. Royalty-free casino sound libraries
4. Synthesize using GarageBand/Logic Pro

## Testing Requirements

### Unit Tests
- `testIsDealtWinner_JacksOrBetter_PairOfJacks()` - Returns true
- `testIsDealtWinner_JacksOrBetter_PairOfTens()` - Returns false
- `testIsDealtWinner_TensOrBetter_PairOfTens()` - Returns true
- `testIsDealtWinner_DeucesWild_ThreeOfKind()` - Returns true
- `testIsDealtWinner_DeucesWild_Pair()` - Returns false
- All 10 paytables covered

### Integration Tests
- Celebration triggers when dealt winner appears
- Celebration doesn't trigger for non-winners
- Sound plays correctly
- Animation completes
- Cards auto-select correctly
- User can override auto-selection

### Manual QA Checklist
- [ ] Test on all 10 paytables
- [ ] Test in quiz mode
- [ ] Test in weak spots mode
- [ ] Test with sound on/off
- [ ] Test with VoiceOver enabled
- [ ] Test on iPhone (various sizes)
- [ ] Test on iPad (if supported)
- [ ] Test performance with rapid hand dealing
- [ ] Verify no memory leaks
- [ ] Verify cards are NOT auto-selected

## Edge Cases

1. **Multiple valid hands**: If dealt hand has multiple interpretations (e.g., Flush + Pair), show highest-value hand
2. **Close decisions mode**: May rarely occur, celebrate anyway
3. **Weak spots for low hands**: If training on pair detection, still celebrate dealt pair
4. **User interaction during celebration**: Cards should not be selectable until celebration completes
5. **Rapid skip**: If user somehow skips (navigation), cancel animation gracefully
6. **Background/foreground**: Pause animation if app backgrounds

## Rollout Plan

### Phase 1: MVP (Week 1-2)
- Core detection logic for Jacks or Better only
- Basic audio + visual highlighting
- Integration with quiz mode

### Phase 2: Full Paytable Support (Week 3)
- All 10 paytables
- Weak spots mode integration

### Phase 3: Polish (Week 4)
- Refined animations
- VoiceOver support
- Performance optimization

### Phase 4: Launch (Week 5)
- Beta testing with 10 users
- Bug fixes
- Production release

## Success Criteria

### Must Have Before Launch
- ✅ All 10 paytables correctly detect dealt winners
- ✅ Sound plays without lag
- ✅ Animation is smooth (60fps)
- ✅ No crashes or memory leaks
- ✅ Works in both quiz and weak spots modes

### Nice to Have
- Haptic feedback
- Multiple sound variations (randomized)
- Celebration intensity based on hand value (bigger celebration for dealt Royal)
- Statistics tracking (% of dealt winners)

## Future Enhancements (Out of Scope)

1. **Dealt Royal Flush**: Special "jackpot" celebration with confetti
2. **Dealt Straight Flush**: Enhanced celebration
3. **Progressive intensity**: Bigger hands = bigger celebrations
4. **Achievement tracking**: "Lucky streak - 3 dealt winners in a row"
5. **Sound themes**: Multiple sound packs (classic, modern, retro)
6. **Custom celebrations**: User-selectable effects

## Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Incorrect hand detection | High | Low | Comprehensive unit tests, QA |
| Annoying sound | Medium | Medium | User testing, settings toggle |
| Performance issues | Medium | Low | Profile early, optimize |
| Delays quiz flow | Low | Medium | Short animation, skippable |

## Dependencies

- Existing AudioService must support new sound
- Existing HapticService for vibration
- Hand evaluation logic (may need new HandEvaluator service)

## Open Questions

1. Should celebration be skippable? (Recommendation: Yes, tap to skip)
2. Should we track dealt winner statistics? (Recommendation: Yes, Phase 3)
3. Different celebration intensities for different hand values? (Recommendation: Phase 4)
4. Show payout amount in banner? (Recommendation: No, focus on hand name)

---

**Document Version:** 1.0
**Last Updated:** 2024-12-24
**Author:** Product Team
**Stakeholders:** Engineering, Design, QA, Users
