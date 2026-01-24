# PRD: Freemium Model for VP Academy

## Overview
This document outlines the strategy for converting VP Academy to a freemium model, including what features to offer free vs. paid, pricing strategy, and technical implementation using StoreKit 2.

---

## Market Research Summary

### Competitor Pricing
| App | Price Model | Cost |
|-----|-------------|------|
| Wizard of Odds Video Poker | One-time purchase | $9.99 |
| VideoPoker.com | Subscription | ~$4.99/month |
| WinPoker (Windows) | One-time purchase | ~$29.95 |
| PlayPerfect | One-time purchase | $4.99-9.99 |

### Industry Benchmarks
- Freemium conversion rate: 2-5% (games typically 1-3%)
- Free trial conversion: 8-12% average, 15-25% for top apps
- Higher price points ($9.99+) see better Day 35 conversion (2.7% vs 1.5%)
- 96% of gaming app trials are 4 days or less

---

## Key Decisions Required

### 1. Pricing Model Choice

**Option A: Subscription Model**
- Monthly: $3.99/month
- Annual: $29.99/year (37% savings)
- Lifetime: $49.99 one-time

**Option B: One-Time Purchase**
- Full unlock: $9.99

**Option C: Tiered Unlocks**
- Per-game family unlock: $2.99 each
- All games bundle: $9.99

**Recommendation:** Option A (Subscription) with Lifetime option
- Aligns with App Store preferences (Apple promotes subscriptions)
- Provides recurring revenue for ongoing development
- Lifetime option captures users who prefer one-time payment
- Lower initial barrier ($3.99 vs $9.99)

### 2. Free Tier Features

**What to Include Free:**
| Feature | Free | Premium |
|---------|------|---------|
| **Games Available** | Jacks or Better 9/6 only | All 15+ game variants |
| **Play Mode** | Unlimited | Unlimited |
| **Quiz Mode** | 10 hands/day | Unlimited |
| **Hand Analyzer** | 5 analyses/day | Unlimited |
| **Optimal Play Feedback** | Basic (correct/incorrect) | Detailed EV breakdown |
| **Simulation Mode** | 1,000 hands max | Unlimited hands |
| **Training Mode** | First lesson only | Full curriculum |
| **Statistics/History** | Last 7 days | Full history |
| **Offline Mode** | JoB 9/6 only | All downloaded games |

**Rationale:**
- Jacks or Better 9/6 is the most popular game - hooks users
- Daily limits create "want more" moments without frustration
- Basic feedback shows value; detailed EV creates upgrade desire
- 7-day stats let users see progress but want more history

### 3. Paywall Placement Strategy

**Soft Paywalls (show upgrade prompt, allow dismiss):**
- After completing daily Quiz limit
- When selecting locked game variant
- After 5th hand analysis

**Hard Paywalls (must subscribe to continue):**
- Accessing Training Mode lessons 2+
- Running simulations >1,000 hands
- Viewing statistics older than 7 days
- Downloading additional offline games

**Timing Considerations:**
- Don't paywall during first session (let users experience value)
- Show upgrade after "aha moments" (correct difficult hand, improve streak)
- Offer upgrade after mistakes ("Want to train on this hand type?")

### 4. Trial Strategy

**Recommendation:** 7-day free trial of Premium
- Slightly longer than gaming average (shows confidence in product)
- Enough time to experience Training Mode value
- Includes full access to all features
- Automatic conversion to subscription after trial

**Alternative:** No trial, but generous free tier
- Lower conversion but larger user base
- Relies on daily limits creating conversion pressure

---

## Technical Implementation

### StoreKit 2 Architecture

```swift
// Product identifiers
enum ProductID: String {
    case monthlySubscription = "com.vptrainer.premium.monthly"
    case annualSubscription = "com.vptrainer.premium.annual"
    case lifetimePurchase = "com.vptrainer.premium.lifetime"
}

// Entitlement checking
@Observable
class SubscriptionManager {
    var isPremium: Bool = false
    var subscriptionStatus: Product.SubscriptionInfo.Status?

    func checkEntitlements() async {
        // Check for active subscription or lifetime purchase
        for await result in Transaction.currentEntitlements {
            // Verify and update isPremium
        }
    }
}
```

### Key Implementation Steps

1. **App Store Connect Setup**
   - Create subscription group "VP Academy Premium"
   - Configure monthly, annual, lifetime products
   - Set up promotional offers for re-engagement

2. **StoreKit Configuration**
   - Use StoreKit 2 async/await APIs
   - Implement `Transaction.updates` listener for real-time status
   - Use `SubscriptionStoreView` for native paywall UI

3. **Entitlement Caching**
   - Cache premium status locally (UserDefaults + Keychain)
   - Verify with App Store on app launch
   - Handle offline gracefully (trust cache for 7 days)

4. **Analytics Events**
   - Track: paywall_viewed, paywall_dismissed, purchase_started, purchase_completed, trial_started, trial_converted, trial_expired

### SwiftUI Paywall Implementation

```swift
// Using StoreKit's built-in subscription view
SubscriptionStoreView(groupID: "premium") {
    // Custom marketing content
    VStack {
        Text("Unlock Your Full Potential")
        FeatureComparisonView()
    }
}
.subscriptionStoreButtonLabel(.multiline)
.storeButton(.visible, for: .restorePurchases)
```

---

## Pricing Justification

### Why $3.99/month or $29.99/year?

1. **Lower than competitors' one-time price** - Wizard of Odds is $9.99 one-time; our annual is $30 but includes ongoing updates and Training Mode

2. **Value proposition** - Training Mode alone would justify price for serious players

3. **Casino context** - Users lose $20+ per casino session easily; $30/year to improve is trivial

4. **Psychological pricing** - $3.99 feels like "a coffee" impulse purchase

### Why Lifetime at $49.99?

- ~17 months of annual subscription
- Captures one-time purchase preference users
- Still provides revenue for customer acquisition cost recovery
- Doesn't cannibalize subscription (most prefer lower upfront)

---

## Rollout Strategy

### Phase 1: Soft Launch
- Implement infrastructure with feature flags
- All users remain "premium" by default
- A/B test paywall messaging with small %

### Phase 2: Grandfather Existing Users
- All users who installed before cutoff date get 1-year free premium
- Builds goodwill and reviews
- They become premium advocates

### Phase 3: Full Launch
- New users get free tier by default
- 7-day trial offered at strategic moments
- Monitor conversion rates and adjust limits

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Trial start rate | 20% of active users |
| Trial-to-paid conversion | 15% |
| Monthly churn | <5% |
| Annual/Lifetime ratio | 60% annual, 30% monthly, 10% lifetime |
| ARPPU | $40/year |

---

## Open Questions

1. Should we offer family sharing? (increases value but reduces per-seat revenue)
2. Should Simulation Mode be free with ads instead of limited?
3. What's the right daily Quiz limit? (10 feels low, 25 might be too generous)
4. Should we offer a cheaper "Games Only" tier without Training Mode?

---

## References

- [StoreKit 2 - Apple Developer](https://developer.apple.com/storekit/)
- [iOS In-App Subscription Tutorial with StoreKit 2](https://www.revenuecat.com/blog/engineering/ios-in-app-subscription-tutorial-with-storekit-2-and-swift/)
- [State of Subscription Apps 2025 - RevenueCat](https://www.revenuecat.com/state-of-subscription-apps-2025/)
- [Wizard of Odds Video Poker App](https://apps.apple.com/us/app/video-poker-wizard-of-odds/id1360271423)
