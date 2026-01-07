# Video Poker Game Families

This document tracks all video poker game families, their paytables, and implementation status.

## Legend
- **Rust**: Has generator in Rust calculator
- **Strategy**: Has strategy file in Supabase Storage
- **Bundled**: Included in iOS app bundle

---

## Standard 52-Card Games (Jacks or Better Family)

### JoB - Jacks or Better
| Paytable | Return % | FH | FL | Rust | Strategy | Bundled |
|----------|----------|----|----|------|----------|---------|
| 9/6 (Full Pay) | 99.54% | 9 | 6 | Yes | Yes | Yes |
| 9/5 | 98.45% | 9 | 5 | Yes | No | No |
| 8/6 | 98.39% | 8 | 6 | Yes | No | No |
| 8/5 | 97.30% | 8 | 5 | Yes | No | No |
| 7/5 | 96.15% | 7 | 5 | Yes | No | No |
| 6/5 | 95.00% | 6 | 5 | Yes | No | No |

### BP - Bonus Poker
| Paytable | Return % | FH | FL | 4A | 4(2-4) | 4(5-K) | Rust | Strategy |
|----------|----------|----|----|-----|--------|--------|------|----------|
| 8/5 (Full Pay) | 99.17% | 8 | 5 | 80 | 40 | 25 | Yes | No |
| 7/5 | 98.01% | 7 | 5 | 80 | 40 | 25 | Yes | No |
| 6/5 | 96.87% | 6 | 5 | 80 | 40 | 25 | Yes | No |

### Bdlx - Bonus Poker Deluxe
| Paytable | Return % | FH | FL | 4K | Rust | Strategy |
|----------|----------|----|----|-----|------|----------|
| 9/6 (Full Pay) | 99.64% | 9 | 6 | 80 | Yes | No |
| 8/6 | 98.49% | 8 | 6 | 80 | Yes | No |
| 8/5 | 97.40% | 8 | 5 | 80 | Yes | No |
| 7/5 | 96.25% | 7 | 5 | 80 | Yes | No |
| 6/5 | 95.36% | 6 | 5 | 80 | Yes | No |

### DB - Double Bonus
| Paytable | Return % | FH | FL | ST | 4A | 4(2-4) | 4(5-K) | Rust | Strategy |
|----------|----------|----|----|-----|-----|--------|--------|------|----------|
| 10/7 (Full Pay) | 100.17% | 10 | 7 | 5 | 160 | 80 | 50 | Yes | No |
| 9/7/5 | 99.11% | 9 | 7 | 5 | 160 | 80 | 50 | Yes | No |
| 9/6/5 | 97.81% | 9 | 6 | 5 | 160 | 80 | 50 | Yes | No |
| 9/6/4 | 96.38% | 9 | 6 | 4 | 160 | 80 | 50 | Yes | No |
| 10/6/5 | 98.88% | 10 | 6 | 5 | 160 | 80 | 50 | No | No |
| 10/7/4 | 98.81% | 10 | 7 | 4 | 160 | 80 | 50 | No | No |
| 9/7/4 | 97.74% | 9 | 7 | 4 | 160 | 80 | 50 | No | No |
| 10/6/4 | 97.46% | 10 | 6 | 4 | 160 | 80 | 50 | No | No |
| 8/6/5 | 96.73% | 8 | 6 | 5 | 160 | 80 | 50 | No | No |
| 9/5/4 | 95.27% | 9 | 5 | 4 | 160 | 80 | 50 | No | No |
| 8/5/4 | 94.19% | 8 | 5 | 4 | 160 | 80 | 50 | No | No |
| 7/5/4 | 93.11% | 7 | 5 | 4 | 160 | 80 | 50 | No | No |

### SDB - Super Double Bonus
| Paytable | Return % | FH | FL | 4A | 4(J-K) | 4(2-4) | 4(5-10) | Rust | Strategy |
|----------|----------|----|----|-----|--------|--------|---------|------|----------|
| 9/5 | 99.69% | 9 | 5 | 160 | 120 | 80 | 50 | Yes | No |
| 8/5 | 98.69% | 8 | 5 | 160 | 120 | 80 | 50 | Yes | No |
| 7/5 | 97.77% | 7 | 5 | 160 | 120 | 80 | 50 | Yes | No |
| 6/5 | 96.87% | 6 | 5 | 160 | 120 | 80 | 50 | Yes | No |

### DDB - Double Double Bonus
*Kicker bonuses: 4A w/2-4=400, 4(2-4) w/A-4=160*
| Paytable | Return % | FH | FL | Rust | Strategy | Bundled |
|----------|----------|----|----|------|----------|---------|
| 10/6 | 100.07% | 10 | 6 | No | No | No |
| 9/6 | 98.98% | 9 | 6 | Yes | Yes | Yes |
| 9/5 | 97.87% | 9 | 5 | Yes | No | No |
| 8/5 | 96.79% | 8 | 5 | Yes | No | No |
| 8/6 | 97.89% | 8 | 6 | No | No | No |
| 6/5 | 94.66% | 6 | 5 | No | No | No |

### TDB - Triple Double Bonus
*Kicker bonuses: 4A w/2-4=800, 4(2-4) w/A-4=400*
| Paytable | Return % | FH | FL | Rust | Strategy | Bundled |
|----------|----------|----|----|------|----------|---------|
| 9/7 | 99.58% | 9 | 7 | Yes | No | No |
| 9/6 | 98.15% | 9 | 6 | Yes | Yes | Yes |
| 10/6 | 99.22% | 10 | 6 | No | No | No |
| 8/5 | 95.97% | 8 | 5 | Yes | No | No |
| 7/5 | 94.92% | 7 | 5 | No | No | No |
| 6/5 | 93.87% | 6 | 5 | No | No | No |

### WHA - White Hot Aces
| Paytable | Return % | FH | FL | 4A | 4(2-4) | 4(5-K) | Rust | Strategy |
|----------|----------|----|----|-----|--------|--------|------|----------|
| 9/5 | 99.57% | 9 | 5 | 240 | 120 | 50 | Yes | No |
| 8/5 | 98.50% | 8 | 5 | 240 | 120 | 50 | Yes | No |
| 7/5 | 97.43% | 7 | 5 | 240 | 120 | 50 | Yes | No |
| 6/5 | 96.37% | 6 | 5 | 240 | 120 | 50 | Yes | No |

### AA - All American
*Enhanced straights and flushes*
| Paytable | Return % | SF | FH | FL | ST | Rust | Strategy |
|----------|----------|-----|----|----|-----|------|----------|
| 40/8/8/8 | 100.72% | 200 | 8 | 8 | 8 | No | No |
| 35/8/8/8 | 99.60% | 200 | 8 | 8 | 8 | Yes | No |
| 30/8/8/8 | 98.49% | 200 | 8 | 8 | 8 | Yes | No |
| 25/8/8/8 | 97.38% | 200 | 8 | 8 | 8 | Yes | No |
| 40/7/7/7 | 96.57% | 200 | 7 | 7 | 7 | Yes | No |

### A+8 - Aces and Eights
*Bonus for 4 Aces, 4 Eights, 4 Sevens*
| Paytable | Return % | FH | FL | 4A/8 | 4x7 | 4K | Rust | Strategy |
|----------|----------|----|----|------|-----|-----|------|----------|
| 8/5 | 99.78% | 8 | 5 | 80 | 50 | 25 | No | No |
| 7/5 | 97.72% | 7 | 5 | 80 | 50 | 20 | No | No |
| 8/5 (70SF) | 98.72% | 8 | 5 | 70 | 50 | 25 | No | No |
| 7/5 v2 | 98.63% | 7 | 5 | 80 | 50 | 25 | No | No |
| 6/5 | 97.49% | 6 | 5 | 80 | 50 | 25 | No | No |

### AF - Aces and Faces
*Bonus for 4 Aces and 4 Face Cards (J/Q/K)*
| Paytable | Return % | FH | FL | 4A | 4(J-K) | Rust | Strategy |
|----------|----------|----|----|-----|--------|------|----------|
| 8/5 | 99.26% | 8 | 5 | 80 | 40 | Yes | No |
| 7/6 | 98.35% | 7 | 6 | 80 | 40 | Yes | No |
| 7/5 | 97.10% | 7 | 5 | 80 | 40 | Yes | No |
| 6/5 | 95.94% | 6 | 5 | 80 | 40 | Yes | No |

---

## Games To Add (Standard 52-Card)

### BP+ - Bonus Poker Plus
| Status | Notes |
|--------|-------|
| Not Implemented | Need paytable data |

### SA - Super Aces
| Status | Notes |
|--------|-------|
| Not Implemented | 4 Aces pays 400 |

### SDDB - Super Double Double Bonus
| Status | Notes |
|--------|-------|
| Not Implemented | Need paytable data |

### TTB - Triple Triple Bonus
| Status | Notes |
|--------|-------|
| Not Implemented | Need paytable data |

### TB - Triple Bonus (Kings)
| Status | Notes |
|--------|-------|
| Not Implemented | Min pair: Kings or better |

### DJ - Double Jackpot
| Status | Notes |
|--------|-------|
| Not Implemented | Need paytable data |

### DDJ - Double Double Jackpot
| Status | Notes |
|--------|-------|
| Not Implemented | Need paytable data |

### RAB - Royal Aces Bonus
| Status | Notes |
|--------|-------|
| Not Implemented | Need paytable data |

### RBDDB - Red Black Double Double Bonus
| Status | Notes |
|--------|-------|
| Not Implemented | Special red/black kicker rules |

### BJB - Black Jack Bonus
| Status | Notes |
|--------|-------|
| Not Implemented | Need paytable data |

### Ace$ - A-c-e-s Bonus
| Status | Notes |
|--------|-------|
| Not Implemented | Need paytable data |

### A2BP - Ace and Deuce Bonus Poker
| Status | Notes |
|--------|-------|
| Not Implemented | Need paytable data |

### 5ADDB - Five Aces Double Double Bonus
| Status | Notes |
|--------|-------|
| Not Implemented | Need paytable data |

### BPAF - Bonus Aces and Faces
| Status | Notes |
|--------|-------|
| Not Implemented | Hybrid of BP and AF |

### DBAF - Double Bonus Aces and Faces
| Status | Notes |
|--------|-------|
| Not Implemented | Hybrid |

### DDBAF - Double Double Bonus Aces and Faces
| Status | Notes |
|--------|-------|
| Not Implemented | Hybrid |

### SFdlx - Straight Flush Deluxe
| Status | Notes |
|--------|-------|
| Not Implemented | Enhanced SF payouts |

---

## Deuces Wild Games (52-Card, 2s Wild)

### DW - Deuces Wild
| Paytable | Return % | 4D | WRF | 5K | SF | 4K | Rust | Strategy | Bundled |
|----------|----------|-----|-----|----|----|-----|------|----------|---------|
| Full Pay | 100.76% | 200 | 25 | 15 | 9 | 5 | Yes | No | No |
| NSUD | 99.73% | 200 | 25 | 16 | 10 | 4 | Yes | Yes | Yes |
| Illinois | 98.91% | 200 | 20 | 12 | 9 | 4 | Yes | No | No |
| 20/12/9 | 97.58% | 200 | 20 | 12 | 9 | 4 | Yes | No | No |

### LDW - Loose Deuces Wild
| Paytable | Return % | 4D | 5K | Rust | Strategy |
|----------|----------|-----|-----|------|----------|
| 500/17 | 100.15% | 500 | 17 | Yes | No |
| 500/15 | 99.35% | 500 | 15 | Yes | No |
| 500/12 | 97.95% | 500 | 12 | Yes | No |
| 400/12 | 96.78% | 400 | 12 | Yes | No |

### Games To Add (Deuces Wild Family)

| Game | Description | Status |
|------|-------------|--------|
| DDW - Double Deuces Wild | Enhanced deuces payouts | Not Implemented |
| TDW - Triple Deuces Wild | Triple deuces bonus | Not Implemented |
| DW44 - Deuces Wild 44 | Variant | Not Implemented |
| DWdlx - Deluxe Deuces Wild | Deluxe version | Not Implemented |
| BDW - Deuces Wild Bonus Poker | Hybrid | Not Implemented |
| DBDW - Double Bonus Deuces Wild | Hybrid | Not Implemented |
| SBDW - Super Bonus Deuces Wild | Hybrid | Not Implemented |
| 7W - Sevens Wild | 7s are wild instead of 2s | Not Implemented |
| OEJ - One Eyed Jacks | One-eyed jacks wild | Not Implemented |

---

## Joker Poker Games (53-Card Deck)

### JW - Joker Wild (Kings or Better)
| Paytable | Return % | 5K | WRF | 4K | Rust | Strategy |
|----------|----------|-----|-----|-----|------|----------|
| 100.64% | 100.64% | 200 | 100 | 17 | Yes | No |
| 98.60% | 98.60% | 200 | 100 | 20 | Yes | No |
| 97.58% | 97.58% | 200 | 100 | 17 | Yes | No |

### JW2 - Joker Wild (Two Pair or Better)
| Paytable | Return % | Rust | Strategy |
|----------|----------|------|----------|
| 99.92% | 99.92% | Yes | No |
| 98.59% | 98.59% | Yes | No |

### Games To Add (Joker Family)

| Game | Description | Status |
|------|-------------|--------|
| JWA - Joker Wild Aces or Better | Aces or better minimum | Not Implemented |
| JWD - Double Joker Wild | 2 jokers (54 cards) | Not Implemented |
| JW5 - Five Joker Wild | 5 jokers | Not Implemented |
| DJW - Deuces Joker Wild | Deuces + Joker wild | Not Implemented |

---

## Specialty Games (Different Mechanics - Not Implementing)

| Game | Description | Reason |
|------|-------------|--------|
| PKM - Pickem Poker | Different card selection mechanic | Different game logic |
| PKMDDB - Pickem DDB | Pickem variant | Different game logic |
| S3P variants | Super Triple Play (3 hands) | Multi-hand mechanic |
| BSP variants | Big Split Poker | Different game logic |
| SW - Shockwave | Progressive multiplier | Different game logic |
| TP - Triple Poker | Multi-hand | Different game logic |

---

## Summary

| Category | Total Games | Implemented | With Strategy |
|----------|-------------|-------------|---------------|
| Standard 52-Card | ~40+ | 15 | 4 |
| Deuces Wild | ~12+ | 4 | 1 |
| Joker Poker | ~6+ | 5 | 0 |
| **Total** | **~60+** | **24** | **5** |

---

## Notes

- Return percentages are for max coin (5 coins) with optimal strategy
- FH = Full House, FL = Flush, ST = Straight, SF = Straight Flush
- 4K = Four of a Kind, 4A = Four Aces, 4D = Four Deuces
- WRF = Wild Royal Flush, 5K = Five of a Kind
- Bundled strategies: JoB 9/6, DDB 9/6, TDB 9/6, DW NSUD
