# Video Poker Paytables

This document lists all 80 paytable variants supported by the Rust calculator.

## Standard Games (52-card deck)

### Jacks or Better (6 variants)
Minimum winning hand: Pair of Jacks or Better

| ID | Name | RF | SF | 4K | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|-----|
| jacks-or-better-9-6 | Jacks or Better 9/6 | 800 | 50 | 25 | 9 | 6 | 4 | 3 | 2 | 1 |
| jacks-or-better-9-5 | Jacks or Better 9/5 | 800 | 50 | 25 | 9 | 5 | 4 | 3 | 2 | 1 |
| jacks-or-better-8-6 | Jacks or Better 8/6 | 800 | 50 | 25 | 8 | 6 | 4 | 3 | 2 | 1 |
| jacks-or-better-8-5 | Jacks or Better 8/5 | 800 | 50 | 25 | 8 | 5 | 4 | 3 | 2 | 1 |
| jacks-or-better-7-5 | Jacks or Better 7/5 | 800 | 50 | 25 | 7 | 5 | 4 | 3 | 2 | 1 |
| jacks-or-better-6-5 | Jacks or Better 6/5 | 800 | 50 | 25 | 6 | 5 | 4 | 3 | 2 | 1 |

### Tens or Better (1 variant)
Minimum winning hand: Pair of Tens or Better

| ID | Name | RF | SF | 4K | FH | FL | ST | 3K | 2P | ToB |
|----|------|----|----|----|----|----|----|----|----|-----|
| tens-or-better-6-5 | Tens or Better 6/5 | 800 | 50 | 25 | 6 | 5 | 4 | 3 | 2 | 1 |

### Bonus Poker (3 variants)
Minimum winning hand: Pair of Jacks or Better
Bonus: Four Aces (80), Four 2-4 (40), Four 5-K (25)

| ID | Name | RF | SF | 4A | 4(2-4) | 4K | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|----|----|-----|
| bonus-poker-8-5 | Bonus Poker 8/5 | 800 | 50 | 80 | 40 | 25 | 8 | 5 | 4 | 3 | 2 | 1 |
| bonus-poker-7-5 | Bonus Poker 7/5 | 800 | 50 | 80 | 40 | 25 | 7 | 5 | 4 | 3 | 2 | 1 |
| bonus-poker-6-5 | Bonus Poker 6/5 | 800 | 50 | 80 | 40 | 25 | 6 | 5 | 4 | 3 | 2 | 1 |

### Bonus Poker Deluxe (5 variants)
Minimum winning hand: Pair of Jacks or Better
All Four of a Kind pays 80

| ID | Name | RF | SF | 4K | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|-----|
| bonus-poker-deluxe-9-6 | Bonus Poker Deluxe 9/6 | 800 | 50 | 80 | 9 | 6 | 4 | 3 | 2 | 1 |
| bonus-poker-deluxe-8-6 | Bonus Poker Deluxe 8/6 | 800 | 50 | 80 | 8 | 6 | 4 | 3 | 2 | 1 |
| bonus-poker-deluxe-8-5 | Bonus Poker Deluxe 8/5 | 800 | 50 | 80 | 8 | 5 | 4 | 3 | 2 | 1 |
| bonus-poker-deluxe-7-5 | Bonus Poker Deluxe 7/5 | 800 | 50 | 80 | 7 | 5 | 4 | 3 | 2 | 1 |
| bonus-poker-deluxe-6-5 | Bonus Poker Deluxe 6/5 | 800 | 50 | 80 | 6 | 5 | 4 | 3 | 2 | 1 |

### Bonus Poker Plus (2 variants)
Minimum winning hand: Pair of Jacks or Better
All Four of a Kind pays 100

| ID | Name | RF | SF | 4K | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|-----|
| bonus-poker-plus-10-7 | Bonus Poker Plus 10/7 | 800 | 50 | 100 | 10 | 7 | 4 | 2 | 1 | 1 |
| bonus-poker-plus-9-6 | Bonus Poker Plus 9/6 | 800 | 50 | 100 | 9 | 6 | 4 | 2 | 1 | 1 |

### Aces and Faces (4 variants)
Minimum winning hand: Pair of Jacks or Better
Bonus: Four Aces (80), Four J/Q/K (40)

| ID | Name | RF | SF | 4A | 4JQK | 4K | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|----|----|-----|
| aces-and-faces-8-5 | Aces and Faces 8/5 | 800 | 50 | 80 | 40 | 25 | 8 | 5 | 4 | 3 | 2 | 1 |
| aces-and-faces-7-6 | Aces and Faces 7/6 | 800 | 50 | 80 | 40 | 25 | 7 | 6 | 4 | 3 | 2 | 1 |
| aces-and-faces-7-5 | Aces and Faces 7/5 | 800 | 50 | 80 | 40 | 25 | 7 | 5 | 4 | 3 | 2 | 1 |
| aces-and-faces-6-5 | Aces and Faces 6/5 | 800 | 50 | 80 | 40 | 25 | 6 | 5 | 4 | 3 | 2 | 1 |

### Aces and Eights (2 variants)
Minimum winning hand: Pair of Jacks or Better
Bonus: Four Aces (80), Four 8s (80), Four 7s (50)

| ID | Name | RF | SF | 4A | 4(8s) | 4(7s) | 4K | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|----|----|----|----|
| aces-and-eights-8-5 | Aces and Eights 8/5 | 800 | 50 | 80 | 80 | 50 | 25 | 8 | 5 | 4 | 3 | 2 | 1 |
| aces-and-eights-7-5 | Aces and Eights 7/5 | 800 | 50 | 80 | 80 | 50 | 25 | 7 | 5 | 4 | 3 | 2 | 1 |

### Triple Bonus (3 variants)
Minimum winning hand: Pair of Kings or Better
Bonus: Four Aces (240), Four 2-4 (120), Four 5-K (75)

| ID | Name | RF | SF | 4A | 4(2-4) | 4(5-K) | FH | FL | ST | 3K | 2P | KoB |
|----|------|----|----|----|----|----|----|----|----|----|----|-----|
| triple-bonus-9-5 | Triple Bonus 9/5 | 800 | 100 | 240 | 120 | 75 | 9 | 5 | 4 | 3 | 1 | 1 |
| triple-bonus-8-5 | Triple Bonus 8/5 | 800 | 100 | 240 | 120 | 75 | 8 | 5 | 4 | 3 | 1 | 1 |
| triple-bonus-7-5 | Triple Bonus 7/5 | 800 | 100 | 240 | 120 | 75 | 7 | 5 | 4 | 3 | 1 | 1 |

### Triple Bonus Plus (3 variants)
Minimum winning hand: Pair of Jacks or Better
Bonus: Four Aces (240), Four 2-4 (120), Four 5-K (50)

| ID | Name | RF | SF | 4A | 4(2-4) | 4(5-K) | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|----|----|-----|
| triple-bonus-plus-9-5 | Triple Bonus Plus 9/5 | 800 | 100 | 240 | 120 | 50 | 9 | 5 | 4 | 3 | 1 | 1 |
| triple-bonus-plus-8-5 | Triple Bonus Plus 8/5 | 800 | 100 | 240 | 120 | 50 | 8 | 5 | 4 | 3 | 1 | 1 |
| triple-bonus-plus-7-5 | Triple Bonus Plus 7/5 | 800 | 100 | 240 | 120 | 50 | 7 | 5 | 4 | 3 | 1 | 1 |

### Super Aces (3 variants)
Minimum winning hand: Pair of Jacks or Better
Bonus: Four Aces (400)

| ID | Name | RF | SF | 4A | 4K | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|----|----|
| super-aces-8-5 | Super Aces 8/5 | 800 | 60 | 400 | 50 | 8 | 5 | 4 | 3 | 1 | 1 |
| super-aces-7-5 | Super Aces 7/5 | 800 | 60 | 400 | 50 | 7 | 5 | 4 | 3 | 1 | 1 |
| super-aces-6-5 | Super Aces 6/5 | 800 | 60 | 400 | 50 | 6 | 5 | 4 | 3 | 1 | 1 |

### Double Jackpot (2 variants)
Minimum winning hand: Pair of Jacks or Better
Face kicker bonus: Four Aces + J/Q/K (160), Four Aces (80), Four JQK + Face (80), Four JQK (40)

| ID | Name | RF | SF | 4A+F | 4A | 4JQK+F | 4JQK | 4K | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|----|----|----|----|-----|
| double-jackpot-8-5 | Double Jackpot 8/5 | 800 | 50 | 160 | 80 | 80 | 40 | 20 | 8 | 5 | 4 | 3 | 2 | 1 |
| double-jackpot-7-5 | Double Jackpot 7/5 | 800 | 50 | 160 | 80 | 80 | 40 | 20 | 7 | 5 | 4 | 3 | 2 | 1 |

### Double Double Jackpot (2 variants)
Minimum winning hand: Pair of Jacks or Better
Face kicker bonus: Four Aces + Face (320), Four Aces (160), Four JQK + Face (160), Four JQK (80)

| ID | Name | RF | SF | 4A+F | 4A | 4JQK+F | 4JQK | 4K | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|----|----|----|----|-----|
| double-double-jackpot-10-6 | Double Double Jackpot 10/6 | 800 | 50 | 320 | 160 | 160 | 80 | 50 | 10 | 6 | 5 | 3 | 1 | 1 |
| double-double-jackpot-9-6 | Double Double Jackpot 9/6 | 800 | 50 | 320 | 160 | 160 | 80 | 50 | 9 | 6 | 5 | 3 | 1 | 1 |

### Double Bonus (4 variants)
Minimum winning hand: Pair of Jacks or Better
Bonus: Four Aces (160), Four 2-4 (80), Four 5-K (50)

| ID | Name | RF | SF | 4A | 4(2-4) | 4(5-K) | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|----|----|-----|
| double-bonus-10-7 | Double Bonus 10/7 | 800 | 50 | 160 | 80 | 50 | 10 | 7 | 5 | 3 | 1 | 1 |
| double-bonus-9-7-5 | Double Bonus 9/7/5 | 800 | 50 | 160 | 80 | 50 | 9 | 7 | 5 | 3 | 1 | 1 |
| double-bonus-9-6-5 | Double Bonus 9/6/5 | 800 | 50 | 160 | 80 | 50 | 9 | 6 | 5 | 3 | 1 | 1 |
| double-bonus-9-6-4 | Double Bonus 9/6/4 | 800 | 50 | 160 | 80 | 50 | 9 | 6 | 4 | 3 | 1 | 1 |

### Super Double Bonus (4 variants)
Minimum winning hand: Pair of Jacks or Better
Bonus: Four Aces (160), Four JQK (120), Four 2-4 (80), Four 5-10 (50)

| ID | Name | RF | SF | 4A | 4JQK | 4(2-4) | 4(5-10) | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|----|----|----|----|
| super-double-bonus-9-5 | Super Double Bonus 9/5 | 800 | 50 | 160 | 120 | 80 | 50 | 9 | 5 | 4 | 3 | 1 | 1 |
| super-double-bonus-8-5 | Super Double Bonus 8/5 | 800 | 50 | 160 | 120 | 80 | 50 | 8 | 5 | 4 | 3 | 1 | 1 |
| super-double-bonus-7-5 | Super Double Bonus 7/5 | 800 | 50 | 160 | 120 | 80 | 50 | 7 | 5 | 4 | 3 | 1 | 1 |
| super-double-bonus-6-5 | Super Double Bonus 6/5 | 800 | 50 | 160 | 120 | 80 | 50 | 6 | 5 | 4 | 3 | 1 | 1 |

### Double Double Bonus (4 variants)
Minimum winning hand: Pair of Jacks or Better
Kicker bonus: Four Aces + 2-4 (400), Four Aces (160), Four 2-4 + A-4 (160), Four 2-4 (80), Four 5-K (50)

| ID | Name | RF | SF | 4A+k | 4A | 4(2-4)+k | 4(2-4) | 4(5-K) | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|----|----|----|----|-----|
| double-double-bonus-10-6 | Double Double Bonus 10/6 | 800 | 50 | 400 | 160 | 160 | 80 | 50 | 10 | 6 | 4 | 3 | 1 | 1 |
| double-double-bonus-9-6 | Double Double Bonus 9/6 | 800 | 50 | 400 | 160 | 160 | 80 | 50 | 9 | 6 | 4 | 3 | 1 | 1 |
| double-double-bonus-9-5 | Double Double Bonus 9/5 | 800 | 50 | 400 | 160 | 160 | 80 | 50 | 9 | 5 | 4 | 3 | 1 | 1 |
| double-double-bonus-8-5 | Double Double Bonus 8/5 | 800 | 50 | 400 | 160 | 160 | 80 | 50 | 8 | 5 | 4 | 3 | 1 | 1 |

### White Hot Aces (4 variants)
Minimum winning hand: Pair of Jacks or Better
Kicker bonus: Four Aces + 2-4 (400), Four Aces (160), Four 2-4 + A-4 (80), Four 2-4 (40), Four 5-K (25)

| ID | Name | RF | SF | 4A+k | 4A | 4(2-4)+k | 4(2-4) | 4(5-K) | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|----|----|----|----|-----|
| white-hot-aces-9-5 | White Hot Aces 9/5 | 800 | 50 | 400 | 160 | 80 | 40 | 25 | 9 | 5 | 4 | 3 | 2 | 1 |
| white-hot-aces-8-5 | White Hot Aces 8/5 | 800 | 50 | 400 | 160 | 80 | 40 | 25 | 8 | 5 | 4 | 3 | 2 | 1 |
| white-hot-aces-7-5 | White Hot Aces 7/5 | 800 | 50 | 400 | 160 | 80 | 40 | 25 | 7 | 5 | 4 | 3 | 2 | 1 |
| white-hot-aces-6-5 | White Hot Aces 6/5 | 800 | 50 | 400 | 160 | 80 | 40 | 25 | 6 | 5 | 4 | 3 | 2 | 1 |

### Triple Double Bonus (3 variants)
Minimum winning hand: Pair of Jacks or Better
Kicker bonus: Four Aces + 2-4 (800), Four Aces (160), Four 2-4 + A-4 (400), Four 2-4 (80), Four 5-K (50)

| ID | Name | RF | SF | 4A+k | 4A | 4(2-4)+k | 4(2-4) | 4(5-K) | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|----|----|----|----|-----|
| triple-double-bonus-9-7 | Triple Double Bonus 9/7 | 800 | 50 | 800 | 160 | 400 | 80 | 50 | 9 | 7 | 4 | 2 | 1 | 1 |
| triple-double-bonus-9-6 | Triple Double Bonus 9/6 | 800 | 50 | 800 | 160 | 400 | 80 | 50 | 9 | 6 | 4 | 2 | 1 | 1 |
| triple-double-bonus-8-5 | Triple Double Bonus 8/5 | 800 | 50 | 800 | 160 | 400 | 80 | 50 | 8 | 5 | 4 | 2 | 1 | 1 |

### All American (4 variants)
Minimum winning hand: Pair of Jacks or Better
Higher payouts for Flush, Straight, Straight Flush

| ID | Name | RF | SF | 4K | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|-----|
| all-american-35-8 | All American 35-8 | 800 | 200 | 35 | 8 | 8 | 8 | 3 | 1 | 1 |
| all-american-30-8 | All American 30-8 | 800 | 200 | 30 | 8 | 8 | 8 | 3 | 1 | 1 |
| all-american-25-8 | All American 25-8 | 800 | 200 | 25 | 8 | 8 | 8 | 3 | 1 | 1 |
| all-american-40-7 | All American 40-7 | 800 | 200 | 40 | 7 | 8 | 8 | 3 | 1 | 1 |

---

## Deuces Wild Games (52-card deck, 2s are wild)

### Deuces Wild (4 variants)
Minimum winning hand: Three of a Kind

| ID | Name | RF | 4D | WR | 5K | SF | 4K | FH | FL | ST | 3K |
|----|------|----|----|----|----|----|----|----|----|----|----|
| deuces-wild-full-pay | Deuces Wild Full Pay | 800 | 200 | 25 | 15 | 9 | 5 | 3 | 2 | 2 | 1 |
| deuces-wild-nsud | Deuces Wild NSUD | 800 | 200 | 25 | 16 | 10 | 4 | 4 | 3 | 2 | 1 |
| deuces-wild-illinois | Deuces Wild Illinois | 800 | 200 | 25 | 15 | 9 | 4 | 4 | 3 | 2 | 1 |
| deuces-wild-20-12-9 | Deuces Wild 20-12-9 | 800 | 200 | 20 | 12 | 9 | 5 | 3 | 2 | 2 | 1 |

### Loose Deuces (4 variants)
Minimum winning hand: Three of a Kind
Higher payout for Four Deuces (400-500)

| ID | Name | RF | 4D | WR | 5K | SF | 4K | FH | FL | ST | 3K |
|----|------|----|----|----|----|----|----|----|----|----|----|
| loose-deuces-500-17 | Loose Deuces 500-17 | 800 | 500 | 25 | 17 | 10 | 4 | 3 | 2 | 2 | 1 |
| loose-deuces-500-15 | Loose Deuces 500-15 | 800 | 500 | 25 | 15 | 10 | 4 | 3 | 2 | 2 | 1 |
| loose-deuces-500-12 | Loose Deuces 500-12 | 800 | 500 | 25 | 12 | 10 | 4 | 3 | 2 | 2 | 1 |
| loose-deuces-400-12 | Loose Deuces 400-12 | 800 | 400 | 25 | 12 | 10 | 4 | 3 | 2 | 2 | 1 |

### Double Deuces Wild (2 variants)
Minimum winning hand: Three of a Kind
Four Deuces pays 400

| ID | Name | RF | 4D | WR | 5K | SF | 4K | FH | FL | ST | 3K |
|----|------|----|----|----|----|----|----|----|----|----|----|
| double-deuces-wild-10-10 | Double Deuces Wild 10/10 | 800 | 400 | 20 | 10 | 10 | 4 | 4 | 3 | 2 | 1 |
| double-deuces-wild-16-13 | Double Deuces Wild 16/13 | 800 | 400 | 25 | 16 | 13 | 4 | 3 | 2 | 2 | 1 |

### Triple Deuces Wild (2 variants)
Minimum winning hand: Three of a Kind
Four Deuces pays 600

| ID | Name | RF | 4D | WR | 5K | SF | 4K | FH | FL | ST | 3K |
|----|------|----|----|----|----|----|----|----|----|----|----|
| triple-deuces-wild-11-8 | Triple Deuces Wild 11/8 | 800 | 600 | 20 | 11 | 8 | 4 | 3 | 2 | 2 | 1 |
| triple-deuces-wild-10-8 | Triple Deuces Wild 10/8 | 800 | 600 | 20 | 10 | 8 | 4 | 3 | 2 | 2 | 1 |

### Deluxe Deuces Wild (2 variants)
Minimum winning hand: Three of a Kind
Higher payouts for lower hands (SF=15, 4K=10, FH=9, FL=4, ST=4, 3K=3)

| ID | Name | RF | 4D | WR | 5K | SF | 4K | FH | FL | ST | 3K |
|----|------|----|----|----|----|----|----|----|----|----|----|
| deluxe-deuces-wild-940 | Deluxe Deuces Wild 940 | 940 | 200 | 50 | 25 | 15 | 10 | 9 | 4 | 4 | 3 |
| deluxe-deuces-wild-800 | Deluxe Deuces Wild 800 | 800 | 200 | 50 | 25 | 15 | 10 | 9 | 4 | 4 | 3 |

---

## Joker Poker Games (53-card deck, 1 Joker)

### Joker Poker - Kings or Better (3 variants)
Minimum winning hand: Pair of Kings or Better

| ID | Name | RF | 5K | WR | SF | 4K | FH | FL | ST | 3K | 2P | KoB |
|----|------|----|----|----|----|----|----|----|----|----|----|-----|
| joker-poker-kings-100-64 | Joker Poker Kings 100.64% | 800 | 200 | 100 | 50 | 17 | 7 | 5 | 3 | 2 | 1 | 1 |
| joker-poker-kings-98-60 | Joker Poker Kings 98.60% | 800 | 100 | 50 | 50 | 17 | 7 | 5 | 3 | 2 | 1 | 1 |
| joker-poker-kings-97-58 | Joker Poker Kings 97.58% | 800 | 100 | 50 | 50 | 16 | 7 | 5 | 3 | 2 | 1 | 1 |

### Joker Poker - Two Pair or Better (2 variants)
Minimum winning hand: Two Pair

| ID | Name | RF | 5K | WR | SF | 4K | FH | FL | ST | 3K | 2P |
|----|------|----|----|----|----|----|----|----|----|----|----|
| joker-poker-two-pair-99-92 | Joker Poker Two Pair 99.92% | 800 | 100 | 50 | 100 | 16 | 8 | 5 | 4 | 2 | 1 |
| joker-poker-two-pair-98-59 | Joker Poker Two Pair 98.59% | 800 | 800 | 100 | 100 | 16 | 8 | 5 | 4 | 2 | 1 |

---

## Double Joker Games (54-card deck, 2 Jokers)

### Double Joker (2 variants)
Minimum winning hand: Pair of Kings or Better

| ID | Name | RF | 5K | WR | SF | 4K | FH | FL | ST | 3K | 2P | KoB |
|----|------|----|----|----|----|----|----|----|----|----|----|-----|
| double-joker-9-6 | Double Joker 9/6 | 800 | 100 | 25 | 50 | 25 | 9 | 6 | 4 | 3 | 2 | 1 |
| double-joker-5-4 | Double Joker 5/4 | 800 | 100 | 25 | 50 | 25 | 5 | 4 | 3 | 2 | 1 | 1 |

---

## Legend

- **RF** = Royal Flush
- **SF** = Straight Flush
- **4K** = Four of a Kind
- **4A** = Four Aces
- **4D** = Four Deuces
- **5K** = Five of a Kind
- **WR** = Wild Royal
- **FH** = Full House
- **FL** = Flush
- **ST** = Straight
- **3K** = Three of a Kind
- **2P** = Two Pair
- **JoB** = Jacks or Better (pair)
- **ToB** = Tens or Better (pair)
- **KoB** = Kings or Better (pair)
- **+k** = with kicker (2-4 for Aces, A-4 for 2-4)
- **+F** = with Face kicker (J, Q, K for Aces; J, Q, K, A for JQK)
