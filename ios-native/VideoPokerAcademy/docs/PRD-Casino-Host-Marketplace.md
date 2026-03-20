# PRD: Casino Host Marketplace for VP Academy

## Overview
A two-sided marketplace connecting VP Academy users with casino hosts seeking video poker players. Casino hosts gain access to a qualified, engaged audience of serious video poker enthusiasts. Players gain access to exclusive offers, comps, and personalized casino experiences they wouldn't otherwise receive.

---

## The Opportunity

### Why This Works

**For Casino Hosts:**
- VP Academy users are *qualified leads* - they're actively training to play video poker
- Traditional player acquisition is expensive and untargeted
- Video poker players are valuable: they play longer sessions, have predictable theoretical loss, and are loyal to casinos with good paytables
- Hosts need to fill their "books" with players who will actually visit and play

**For VP Academy Users:**
- Most players don't know how to connect with casino hosts
- Hosts can offer: free rooms, meals, show tickets, cashback, tournament invites
- Players with modest bankrolls ($500-2,000/trip) can still get offers if connected properly
- Access to information about which casinos have good video poker paytables

**For VP Academy:**
- Creates B2B revenue stream beyond consumer subscriptions
- Increases user engagement (real-world connection to their training)
- Differentiator from competitors
- Network effects: more users → more valuable to hosts → more hosts → better offers for users

---

## Market Context

### Casino Player Development

Casino hosts are responsible for:
- Acquiring new VIP and mid-tier players
- Retaining existing players with personalized offers
- Meeting revenue quotas from their "book" of players

Challenges they face:
- Finding qualified players (not just anyone, but people who will actually visit and play)
- Justifying acquisition costs (typical player acquisition: $200-500 per depositing customer)
- Competing with other casinos for the same players

### Video Poker Player Value

Video poker players are particularly valuable because:
- Lower variance than slots = more predictable theoretical loss
- Skill element means players who train are more engaged
- VP players often play for hours (more floor time)
- Many are "advantage players" who will travel for good paytables

---

## Core Features

### 1. Player Profile & Preferences

Users opt-in to the marketplace by creating a player profile:

```
┌─────────────────────────────────────────┐
│  CASINO CONNECT PROFILE                │
├─────────────────────────────────────────┤
│                                         │
│  Gaming Preferences                     │
│  ├─ Preferred games: JoB, Deuces Wild  │
│  ├─ Typical session: 2-4 hours         │
│  ├─ Bankroll range: $500-1,000/trip    │
│  └─ Denomination: $0.25 - $1.00        │
│                                         │
│  Travel Preferences                     │
│  ├─ Home region: Southwest US          │
│  ├─ Willing to travel: 500+ miles      │
│  ├─ Preferred destinations:            │
│  │   ☑ Las Vegas                       │
│  │   ☑ Reno/Tahoe                      │
│  │   ☐ Atlantic City                   │
│  │   ☑ Regional (AZ, NM, OK)           │
│  └─ Travel frequency: Monthly          │
│                                         │
│  Contact Preferences                    │
│  ├─ Email offers: Yes                  │
│  ├─ Phone calls: No                    │
│  └─ In-app messages: Yes               │
│                                         │
│  [Save Profile]                        │
└─────────────────────────────────────────┘
```

### 2. Casino/Host Directory

Browsable directory of participating casinos and hosts:

```
┌─────────────────────────────────────────┐
│  CASINO DIRECTORY                      │
├─────────────────────────────────────────┤
│                                         │
│  🏆 FEATURED PARTNER                   │
│  ┌─────────────────────────────────┐   │
│  │ Station Casinos - Las Vegas     │   │
│  │ ⭐⭐⭐⭐⭐ (4.8) 127 reviews      │   │
│  │ Games: JoB 9/6, Deuces NSU      │   │
│  │ Current Offer: $100 free play   │   │
│  │ [Connect with Host]             │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ALL CASINOS                           │
│  ├─ The Orleans (Las Vegas)            │
│  │   JoB 8/5, Bonus Poker 7/5          │
│  │   Host: Sarah M. | [Connect]        │
│  │                                      │
│  ├─ Atlantis (Reno)                    │
│  │   JoB 9/6, DW Full Pay              │
│  │   Host: Mike T. | [Connect]         │
│  │                                      │
│  └─ [View 45 more casinos...]          │
│                                         │
│  FILTER BY:                            │
│  [Region ▼] [Games ▼] [Has Offer ▼]   │
└─────────────────────────────────────────┘
```

### 3. Offer Feed

Personalized feed of offers based on player profile:

```
┌─────────────────────────────────────────┐
│  OFFERS FOR YOU                        │
├─────────────────────────────────────────┤
│                                         │
│  🔥 NEW - Expires in 3 days            │
│  ┌─────────────────────────────────┐   │
│  │ Red Rock Casino                  │   │
│  │ 2 Free Nights + $50 Free Play   │   │
│  │ Valid: Jan 15-31                 │   │
│  │ Requirements: 4 hours play       │   │
│  │ [Claim Offer] [Save for Later]   │   │
│  └─────────────────────────────────┘   │
│                                         │
│  📧 EXCLUSIVE                          │
│  ┌─────────────────────────────────┐   │
│  │ Atlantis Reno                    │   │
│  │ VP Tournament Entry ($299 value) │   │
│  │ For VP Academy users only        │   │
│  │ [Request Invite]                 │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

### 4. Host Messaging

In-app messaging between players and hosts:

```
┌─────────────────────────────────────────┐
│  💬 Sarah M. - Station Casinos         │
├─────────────────────────────────────────┤
│                                         │
│  Sarah: Hi! I noticed you've been      │
│  training on Jacks or Better. We have  │
│  9/6 machines at Red Rock. Would you   │
│  be interested in a stay-and-play      │
│  offer for next month?                 │
│                                         │
│  You: That sounds great! What does     │
│  the offer include?                    │
│                                         │
│  Sarah: 2 nights comped, $100 free     │
│  play, and I can set up a $25 denom    │
│  machine for you if you prefer high    │
│  limit. Let me know your dates!        │
│                                         │
│  [Type message...]            [Send]   │
└─────────────────────────────────────────┘
```

### 5. Paytable Database Integration

Connect training to real-world casinos:

```
┌─────────────────────────────────────────┐
│  WHERE TO PLAY: Jacks or Better 9/6   │
├─────────────────────────────────────────┤
│                                         │
│  LAS VEGAS                             │
│  ├─ Station Casinos (all locations)    │
│  │   $0.25 - $5 denominations          │
│  │   Host available: Sarah M.          │
│  │                                      │
│  ├─ The Orleans                        │
│  │   $0.25 - $1 denominations          │
│  │   Host available: John D.           │
│  │                                      │
│  └─ South Point                        │
│      $0.25 - $2 denominations          │
│      No host partnership yet           │
│                                         │
│  [Report Paytable Change]              │
└─────────────────────────────────────────┘
```

---

## Monetization Models

### Option A: Lead Generation Fee (CPA)

Charge casinos/hosts per qualified connection:

| Lead Type | Price |
|-----------|-------|
| Profile view | $0 (free to browse) |
| Connection request | $5-10 |
| Verified visit (player checked in) | $25-50 |
| First-time depositing player | $50-100 |

**Pros:** Simple, clear value exchange
**Cons:** Requires verification, one-time revenue

### Option B: Subscription for Hosts

Monthly subscription for hosts to access the platform:

| Tier | Price | Includes |
|------|-------|----------|
| Basic | $99/month | 10 connections/month, basic messaging |
| Pro | $299/month | 50 connections/month, featured placement, analytics |
| Enterprise | $999/month | Unlimited, API access, dedicated support |

**Pros:** Recurring revenue, predictable
**Cons:** Harder to sell initially without proven user base

### Option C: Revenue Share

Partner with online sportsbooks/casinos (where legal) for revenue share:

- Traditional affiliate model: 20-40% of net gaming revenue
- CPA hybrid: $100-250 per depositing player + 10% ongoing

**Pros:** Highest potential revenue
**Cons:** Legal complexity, not applicable to land-based

### Option D: Hybrid Model (Recommended)

Combine multiple revenue streams:

1. **Hosts pay for premium placement** - Featured listings, priority in search
2. **CPA for verified visits** - Small fee when a VP Academy user visits and plays
3. **Sponsored offers** - Casinos pay to push offers to relevant users
4. **Data insights subscription** - Anonymized data about player preferences

**Pricing Example:**
| Product | Price |
|---------|-------|
| Host account (basic) | Free |
| Featured placement | $199/month |
| Push offer to 1,000 users | $50 |
| Verified visit commission | $25 |
| Annual insights report | $500 |

---

## Key Decisions Required

### 1. Geographic Scope

**Option A: Las Vegas Only (MVP)**
- Highest concentration of VP players and casinos
- Easier to build initial relationships
- Can verify paytables personally

**Option B: Major Gaming Markets**
- Las Vegas, Reno, Atlantic City, regional casinos
- Broader appeal but harder to manage

**Option C: National/International**
- Include tribal casinos, cruise ships, international
- Scalable but complex

**Recommendation:** Start with Las Vegas, expand to Reno/regional after proving model

### 2. Player Opt-In Level

**Option A: Fully Anonymous**
- Players browse offers, never share identity
- Low commitment but limited value for hosts

**Option B: Profile with Alias**
- Create profile with preferences but no real name
- Hosts see "VPPlayer_42" with stats

**Option C: Verified Identity**
- Real name, email, optional players club numbers
- Highest value for hosts, highest friction for users

**Recommendation:** Option B initially, Option C opt-in for premium offers

### 3. Verification of Visits

How do we know if a VP Academy user actually visited a casino?

**Option A: Honor System**
- User marks "I visited" in app
- Low friction, low accuracy

**Option B: Location Check-In**
- GPS verification when user is at casino
- Better accuracy, privacy concerns

**Option C: Players Club Integration**
- Connect to casino loyalty programs via API
- Most accurate, requires casino partnership

**Option D: Host Confirmation**
- Host marks player as visited in their dashboard
- Moderate accuracy, requires host action

**Recommendation:** Option D initially (host confirms), explore Option C with partners

### 4. Quality Control

How do we ensure good experiences on both sides?

**For Players:**
- Review system for casinos and hosts
- Report bad experiences
- Blacklist hosts who spam or mislead

**For Hosts:**
- Player "quality score" based on: app activity, profile completeness, previous visits
- Don't show low-quality leads to premium hosts

### 5. Regulatory Considerations

**Questions to Research:**
- Is this considered gambling advertising? (Varies by state)
- Do we need gaming licenses?
- GDPR/CCPA compliance for player data
- Can we operate in states with strict gaming laws?

**Recommendation:** Legal review before launch, start in Nevada (most permissive)

---

## Data Model

```swift
// Player marketplace profile
struct MarketplaceProfile: Codable {
    let userId: UUID
    var alias: String
    var isPublic: Bool

    // Gaming preferences
    var preferredGames: [String]  // ["jacks_or_better_9_6", "deuces_wild_full_pay"]
    var typicalSessionHours: SessionLength
    var bankrollRange: BankrollRange
    var preferredDenominations: [String]

    // Travel preferences
    var homeRegion: String
    var willingToTravel: TravelDistance
    var preferredDestinations: [String]
    var travelFrequency: TravelFrequency

    // Contact preferences
    var allowEmail: Bool
    var allowPhone: Bool
    var allowInAppMessages: Bool

    // Computed quality score (for hosts)
    var qualityScore: Int  // Based on app activity, profile completeness, etc.
}

// Casino listing
struct CasinoListing: Codable {
    let id: UUID
    var name: String
    var location: Location
    var description: String
    var paytables: [PaytableInfo]  // What VP games they offer
    var amenities: [String]
    var rating: Double
    var reviewCount: Int
    var isFeatured: Bool
    var hosts: [HostProfile]
}

// Host profile
struct HostProfile: Codable {
    let id: UUID
    let casinoId: UUID
    var name: String
    var title: String
    var bio: String
    var photoUrl: String?
    var responseTime: String  // "Usually responds within 24 hours"
    var specialties: [String]  // ["Video Poker", "High Limit", "Tournaments"]
    var isVerified: Bool
}

// Offer
struct CasinoOffer: Codable {
    let id: UUID
    let casinoId: UUID
    let hostId: UUID?
    var title: String
    var description: String
    var value: String  // "$100 Free Play"
    var requirements: String?  // "4 hours of play"
    var validFrom: Date
    var validTo: Date
    var targetCriteria: OfferTargeting  // Which users see this
    var claimCount: Int
    var isExclusive: Bool  // VP Academy exclusive?
}

// Connection/conversation
struct HostConnection: Codable {
    let id: UUID
    let playerId: UUID
    let hostId: UUID
    var status: ConnectionStatus  // .requested, .accepted, .declined
    var messages: [Message]
    var visitVerified: Bool
    var createdAt: Date
}
```

---

## User Flows

### Player Flow: Discovering Offers

```
1. User completes premium subscription
2. Prompt: "Want to get casino offers based on your play?"
3. User creates marketplace profile (2-3 screens)
4. Profile saved, "Casino Connect" tab unlocked
5. User browses offers personalized to their profile
6. User claims offer → connected with host
7. Host sends welcome message with details
8. User visits casino, host marks as verified
9. User leaves review
```

### Host Flow: Finding Players

```
1. Host signs up for VP Academy host account
2. Completes casino profile and verification
3. Host browses player profiles matching their criteria
4. Host sends connection request or posts offer
5. Player accepts, conversation begins
6. Player visits, host marks verified
7. Host pays CPA fee (or included in subscription)
8. Host sees ROI dashboard
```

---

## Success Metrics

### Player Metrics
| Metric | Target |
|--------|--------|
| Marketplace opt-in rate | 30% of premium users |
| Offers claimed | 2 per user per quarter |
| Verified visits | 1 per user per quarter |
| Player satisfaction (NPS) | 50+ |

### Host/Casino Metrics
| Metric | Target |
|--------|--------|
| Host accounts created | 50 in Year 1 |
| Paying host accounts | 20 in Year 1 |
| Verified visits per host | 10/month average |
| Host retention | 80% annual |

### Business Metrics
| Metric | Target |
|--------|--------|
| Marketplace revenue | $50K Year 1 |
| Revenue per premium user | $10/year from marketplace |
| Cost per verified visit | < $10 (to VP Academy) |

---

## Implementation Phases

### Phase 1: Paytable Database (Foundation)
- Crowdsourced paytable database for major casinos
- "Where to Play" feature showing best games by location
- No host involvement yet, just information

### Phase 2: Host Directory (MVP)
- Allow hosts to create profiles
- Players can browse and request connections
- Basic messaging
- Manual verification

### Phase 3: Offers & Monetization
- Offer posting system
- Featured placements (paid)
- CPA for verified visits
- Analytics dashboard for hosts

### Phase 4: Scale & Optimize
- API integrations with casino systems
- Automated verification
- Expand to new markets
- Premium data products

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Hosts spam users | Rate limits, user blocking, review system |
| Users game the system for offers | Verification requirements, host confirmation |
| Low host adoption | Start with personal relationships, prove ROI |
| Regulatory issues | Legal review, start in Nevada, clear disclosures |
| Privacy concerns | Clear opt-in, data controls, anonymization options |
| Competition from casinos directly | Focus on multi-property discovery (hosts can't do this alone) |

---

## Open Questions

1. Should we charge players anything, or keep player side completely free?
2. How do we verify that a host is actually a casino employee?
3. Should we allow independent hosts (player development consultants)?
4. What's the right balance between player privacy and host access?
5. Should we include online casinos/sportsbooks where legal, or stay land-based only?
6. How do we handle it when a casino has bad paytables but wants to participate?
7. Should VP Academy take a position on which casinos are "good" vs. "bad" for players?

---

## Competitive Landscape

| Competitor | Model | Gap We Fill |
|------------|-------|-------------|
| Casino direct marketing | Email blasts, direct mail | Untargeted, players overwhelmed |
| URComped | Connects players to hosts | Not VP-specific, no training tie-in |
| Vegas Message Board | Community recommendations | No direct host connection |
| Casino affiliate sites | Online casino referrals | Not land-based focused |

**Our Differentiation:**
- VP-specific audience (most valuable to casinos seeking VP players)
- Training → Real-world connection (unique value prop)
- Quality over quantity (trained, serious players, not casual tourists)

---

## References

- [Casino Player Development - Marketing Results](https://www.marketingresults.net/services/casino-player-development/)
- [Casino Marketing Advice from a VIP Player - CDC Gaming](https://cdcgaming.com/commentary/casino-marketing-advice-from-a-vip-player/)
- [Three Steps to World-Class Player Development - GGB Magazine](https://ggbmagazine.com/article/three-steps-to-world-class-player-development/)
- [Top Casino Affiliate Programs 2025 - Olavivo](https://olavivo.com/casino-affiliate-programs/)
- [Casino Affiliate Programs - Business of Apps](https://www.businessofapps.com/affiliate/casino/)
