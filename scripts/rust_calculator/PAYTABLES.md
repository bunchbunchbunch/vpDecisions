# Video Poker Paytables

This document lists all 145 paytable variants supported by the Rust calculator.

## Standard Games (52-card deck)

### Jacks or Better (9 variants)
Minimum winning hand: Pair of Jacks or Better

| ID | Name | RF | SF | 4K | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|-----|
| jacks-or-better-9-6 | Jacks or Better 9/6 (99.54%) | 800 | 50 | 25 | 9 | 6 | 4 | 3 | 2 | 1 |
| jacks-or-better-9-6-90 | Jacks or Better 9/6/90 (100%) | 800 | 90 | 25 | 9 | 6 | 4 | 3 | 2 | 1 |
| jacks-or-better-9-6-940 | Jacks or Better 940 (100.17%) | 940 | 50 | 25 | 9 | 6 | 4 | 3 | 2 | 1 |
| jacks-or-better-9-5 | Jacks or Better 9/5 | 800 | 50 | 25 | 9 | 5 | 4 | 3 | 2 | 1 |
| jacks-or-better-8-6 | Jacks or Better 8/6 | 800 | 50 | 25 | 8 | 6 | 4 | 3 | 2 | 1 |
| jacks-or-better-8-5 | Jacks or Better 8/5 | 800 | 50 | 25 | 8 | 5 | 4 | 3 | 2 | 1 |
| jacks-or-better-8-5-35 | Jacks or Better 8/5/35 (96.30%) | 800 | 35 | 25 | 8 | 5 | 4 | 3 | 2 | 1 |
| jacks-or-better-7-5 | Jacks or Better 7/5 | 800 | 50 | 25 | 7 | 5 | 4 | 3 | 2 | 1 |
| jacks-or-better-6-5 | Jacks or Better 6/5 | 800 | 50 | 25 | 6 | 5 | 4 | 3 | 2 | 1 |

### Tens or Better (1 variant)
Minimum winning hand: Pair of Tens or Better

| ID | Name | RF | SF | 4K | FH | FL | ST | 3K | 2P | ToB |
|----|------|----|----|----|----|----|----|----|----|-----|
| tens-or-better-6-5 | Tens or Better 6/5 | 800 | 50 | 25 | 6 | 5 | 4 | 3 | 2 | 1 |

### Bonus Poker (4 variants)
Minimum winning hand: Pair of Jacks or Better
Bonus: Four Aces (80), Four 2-4 (40), Four 5-K (25)

| ID | Name | RF | SF | 4A | 4(2-4) | 4K | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|----|----|-----|
| bonus-poker-8-5 | Bonus Poker 8/5 | 800 | 50 | 80 | 40 | 25 | 8 | 5 | 4 | 3 | 2 | 1 |
| bonus-poker-7-5 | Bonus Poker 7/5 | 800 | 50 | 80 | 40 | 25 | 7 | 5 | 4 | 3 | 2 | 1 |
| bonus-poker-7-5-1200 | Bonus Poker 7/5 (RF 1200) | 1200 | 50 | 80 | 40 | 25 | 7 | 5 | 4 | 3 | 2 | 1 |
| bonus-poker-6-5 | Bonus Poker 6/5 | 800 | 50 | 80 | 40 | 25 | 6 | 5 | 4 | 3 | 2 | 1 |

### Bonus Poker Deluxe (7 variants)
Minimum winning hand: Pair of Jacks or Better
All Four of a Kind pays 80

| ID | Name | RF | SF | 4K | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|-----|
| bonus-poker-deluxe-9-6 | Bonus Poker Deluxe 9/6 | 800 | 50 | 80 | 9 | 6 | 4 | 3 | 2 | 1 |
| bonus-poker-deluxe-9-5 | Bonus Poker Deluxe 9/5 | 800 | 50 | 80 | 9 | 5 | 4 | 3 | 2 | 1 |
| bonus-poker-deluxe-8-6 | Bonus Poker Deluxe 8/6 | 800 | 50 | 80 | 8 | 6 | 4 | 3 | 2 | 1 |
| bonus-poker-deluxe-8-6-100 | Bonus Poker Deluxe 8/6 SF100 | 800 | 100 | 80 | 8 | 6 | 4 | 3 | 2 | 1 |
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

### Bonus Aces and Faces (3 variants)
Minimum winning hand: Pair of Jacks or Better
Bonus: Four Aces (80), Four J/Q/K (40)

| ID | Name | Return |
|----|------|--------|
| bonus-aces-faces-8-5 | Bonus Aces and Faces 8/5 | 99.26% |
| bonus-aces-faces-7-5 | Bonus Aces and Faces 7/5 | 98.10% |
| bonus-aces-faces-6-5 | Bonus Aces and Faces 6/5 | 96.96% |

### Aces and Eights (2 variants)
Minimum winning hand: Pair of Jacks or Better
Bonus: Four Aces (80), Four 8s (80), Four 7s (50)

| ID | Name | RF | SF | 4A | 4(8s) | 4(7s) | 4K | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|----|----|----|----|
| aces-and-eights-8-5 | Aces and Eights 8/5 | 800 | 50 | 80 | 80 | 50 | 25 | 8 | 5 | 4 | 3 | 2 | 1 |
| aces-and-eights-7-5 | Aces and Eights 7/5 | 800 | 50 | 80 | 80 | 50 | 25 | 7 | 5 | 4 | 3 | 2 | 1 |

### A-c-e-s Bonus (3 variants)
Minimum winning hand: Pair of Jacks or Better
Bonus: Four Aces (800)

| ID | Name | Return |
|----|------|--------|
| aces-bonus-8-5 | A-c-e-s Bonus 8/5 | 99.40% |
| aces-bonus-7-5 | A-c-e-s Bonus 7/5 | 98.25% |
| aces-bonus-6-5 | A-c-e-s Bonus 6/5 | 97.11% |

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

### Triple Triple Bonus (4 variants)
Minimum winning hand: Pair of Jacks or Better
Kicker bonus: 4A+2-4 pays 800, 4(2-4)+A pays 800, 4(2-4)+2-4 pays 400

| ID | Name | Return |
|----|------|--------|
| triple-triple-bonus-9-6 | Triple Triple Bonus 9/6 | 99.75% |
| triple-triple-bonus-9-5 | Triple Triple Bonus 9/5 | 98.61% |
| triple-triple-bonus-8-5 | Triple Triple Bonus 8/5 | 97.61% |
| triple-triple-bonus-7-5 | Triple Triple Bonus 7/5 | 96.55% |

### Super Aces (3 variants)
Minimum winning hand: Pair of Jacks or Better
Bonus: Four Aces (400)

| ID | Name | RF | SF | 4A | 4K | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|----|----|
| super-aces-8-5 | Super Aces 8/5 | 800 | 60 | 400 | 50 | 8 | 5 | 4 | 3 | 1 | 1 |
| super-aces-7-5 | Super Aces 7/5 | 800 | 60 | 400 | 50 | 7 | 5 | 4 | 3 | 1 | 1 |
| super-aces-6-5 | Super Aces 6/5 | 800 | 60 | 400 | 50 | 6 | 5 | 4 | 3 | 1 | 1 |

### Royal Aces Bonus (4 variants)
Minimum winning hand: Pair of Aces
Bonus: Four Aces (800)

| ID | Name | Return |
|----|------|--------|
| royal-aces-bonus-9-6 | Royal Aces Bonus 9/6 | 99.58% |
| royal-aces-bonus-10-5 | Royal Aces Bonus 10/5 | 99.20% |
| royal-aces-bonus-8-6 | Royal Aces Bonus 8/6 | 98.51% |
| royal-aces-bonus-9-5 | Royal Aces Bonus 9/5 | 98.13% |

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

### Double Bonus (8 variants)
Minimum winning hand: Pair of Jacks or Better
Bonus: Four Aces (160), Four 2-4 (80), Four 5-K (50)

| ID | Name | RF | SF | 4A | 4(2-4) | 4(5-K) | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|----|----|-----|
| double-bonus-10-7 | Double Bonus 10/7 (100.17%) | 800 | 50 | 160 | 80 | 50 | 10 | 7 | 5 | 3 | 1 | 1 |
| double-bonus-10-7-100 | Double Bonus 10/7 SF100 (100.52%) | 800 | 100 | 160 | 80 | 50 | 10 | 7 | 5 | 3 | 1 | 1 |
| double-bonus-10-7-80 | Double Bonus 10/7 SF80 (100.52%) | 800 | 80 | 160 | 80 | 50 | 10 | 7 | 5 | 3 | 1 | 1 |
| double-bonus-10-6 | Double Bonus 10/6 (98.88%) | 800 | 50 | 160 | 80 | 50 | 10 | 6 | 5 | 3 | 1 | 1 |
| double-bonus-10-7-4 | Double Bonus 10/7/4 (98.81%) | 800 | 50 | 160 | 80 | 50 | 10 | 7 | 4 | 3 | 1 | 1 |
| double-bonus-9-7-5 | Double Bonus 9/7/5 | 800 | 50 | 160 | 80 | 50 | 9 | 7 | 5 | 3 | 1 | 1 |
| double-bonus-9-6-5 | Double Bonus 9/6/5 | 800 | 50 | 160 | 80 | 50 | 9 | 6 | 5 | 3 | 1 | 1 |
| double-bonus-9-6-4 | Double Bonus 9/6/4 | 800 | 50 | 160 | 80 | 50 | 9 | 6 | 4 | 3 | 1 | 1 |

### Super Double Bonus (4 variants)
Minimum winning hand: Pair of Jacks or Better
Bonus: Four Aces (160), Four JQK (120), Four 2-4 (80), Four 5-10 (50)

| ID | Name | RF | SF | 4A | 4JQK | 4(2-4) | 4(5-10) | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|----|----|----|----|
| super-double-bonus-9-5 | Super Double Bonus 9/5 | 800 | 80 | 160 | 120 | 80 | 50 | 9 | 5 | 4 | 3 | 1 | 1 |
| super-double-bonus-8-5 | Super Double Bonus 8/5 | 800 | 80 | 160 | 120 | 80 | 50 | 8 | 5 | 4 | 3 | 1 | 1 |
| super-double-bonus-7-5 | Super Double Bonus 7/5 | 800 | 80 | 160 | 120 | 80 | 50 | 7 | 5 | 4 | 3 | 1 | 1 |
| super-double-bonus-6-5 | Super Double Bonus 6/5 | 800 | 80 | 160 | 120 | 80 | 50 | 6 | 5 | 4 | 3 | 1 | 1 |

### Double Double Bonus (7 variants)
Minimum winning hand: Pair of Jacks or Better
Kicker bonus: Four Aces + 2-4 (400), Four Aces (160), Four 2-4 + A-4 (160), Four 2-4 (80), Four 5-K (50)

| ID | Name | RF | SF | 4A+k | 4A | 4(2-4)+k | 4(2-4) | 4(5-K) | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|----|----|----|----|-----|
| double-double-bonus-10-6-100 | DDB 10/6 SF100 (100.64%) | 800 | 100 | 400 | 160 | 160 | 80 | 50 | 10 | 6 | 4 | 3 | 1 | 1 |
| double-double-bonus-10-6 | DDB 10/6 (100.07%) | 800 | 50 | 400 | 160 | 160 | 80 | 50 | 10 | 6 | 4 | 3 | 1 | 1 |
| double-double-bonus-9-6 | DDB 9/6 (98.98%) | 800 | 50 | 400 | 160 | 160 | 80 | 50 | 9 | 6 | 4 | 3 | 1 | 1 |
| double-double-bonus-9-5 | DDB 9/5 (97.87%) | 800 | 50 | 400 | 160 | 160 | 80 | 50 | 9 | 5 | 4 | 3 | 1 | 1 |
| double-double-bonus-8-5 | DDB 8/5 (96.79%) | 800 | 50 | 400 | 160 | 160 | 80 | 50 | 8 | 5 | 4 | 3 | 1 | 1 |
| double-double-bonus-7-5 | DDB 7/5 (95.71%) | 800 | 50 | 400 | 160 | 160 | 80 | 50 | 7 | 5 | 4 | 3 | 1 | 1 |
| double-double-bonus-6-5 | DDB 6/5 (94.66%) | 800 | 50 | 400 | 160 | 160 | 80 | 50 | 6 | 5 | 4 | 3 | 1 | 1 |

### DDB Aces and Faces (2 variants)
Minimum winning hand: Pair of Jacks or Better
Additional bonus: Four JQK + Face (160)

| ID | Name | Return |
|----|------|--------|
| ddb-aces-faces-9-6 | DDB Aces and Faces 9/6 | 99.46% |
| ddb-aces-faces-9-5 | DDB Aces and Faces 9/5 | 98.37% |

### DDB Plus (3 variants)
Minimum winning hand: Pair of Jacks or Better
Additional kicker: Four 5-K + A pays 80

| ID | Name | Return |
|----|------|--------|
| ddb-plus-9-6 | DDB Plus 9/6 | 99.44% |
| ddb-plus-9-5 | DDB Plus 9/5 | 98.33% |
| ddb-plus-8-5 | DDB Plus 8/5 | 97.25% |

### White Hot Aces (4 variants)
Minimum winning hand: Pair of Jacks or Better
Bonus: Four Aces (240), Four 2-4 (120)

| ID | Name | RF | SF | 4A | 4(2-4) | 4(5-K) | FH | FL | ST | 3K | 2P | JoB |
|----|------|----|----|----|----|----|----|----|----|----|----|-----|
| white-hot-aces-9-5 | White Hot Aces 9/5 | 800 | 80 | 240 | 120 | 50 | 9 | 5 | 4 | 3 | 1 | 1 |
| white-hot-aces-8-5 | White Hot Aces 8/5 | 800 | 80 | 240 | 120 | 50 | 8 | 5 | 4 | 3 | 1 | 1 |
| white-hot-aces-7-5 | White Hot Aces 7/5 | 800 | 80 | 240 | 120 | 50 | 7 | 5 | 4 | 3 | 1 | 1 |
| white-hot-aces-6-5 | White Hot Aces 6/5 | 800 | 80 | 240 | 120 | 50 | 6 | 5 | 4 | 3 | 1 | 1 |

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
| all-american-40-7 | All American 40-7 | 800 | 200 | 40 | 7 | 7 | 7 | 3 | 1 | 1 |

---

## Deuces Wild Games (52-card deck, 2s are wild)

### Deuces Wild (8 variants)
Minimum winning hand: Three of a Kind

| ID | Name | RF | 4D | WR | 5K | SF | 4K | FH | FL | ST | 3K |
|----|------|----|----|----|----|----|----|----|----|----|----|
| deuces-wild-full-pay | Deuces Wild Full Pay (100.76%) | 800 | 200 | 25 | 15 | 9 | 5 | 3 | 2 | 2 | 1 |
| deuces-wild-25-15-8 | Deuces Wild 25/15/8 (100.36%) | 800 | 200 | 25 | 15 | 8 | 5 | 3 | 2 | 2 | 1 |
| deuces-wild-nsud | Deuces Wild NSUD (99.73%) | 800 | 200 | 25 | 16 | 10 | 4 | 4 | 3 | 2 | 1 |
| deuces-wild-20-15-9 | Deuces Wild 20/15/9 (99.89%) | 800 | 200 | 20 | 15 | 9 | 5 | 3 | 2 | 2 | 1 |
| deuces-wild-25-12-9 | Deuces Wild 25/12/9 (99.81%) | 800 | 200 | 25 | 12 | 9 | 5 | 3 | 2 | 2 | 1 |
| deuces-wild-illinois | Deuces Wild Illinois (98.91%) | 800 | 200 | 25 | 15 | 9 | 4 | 4 | 3 | 2 | 1 |
| deuces-wild-20-12-9 | Deuces Wild 20-12-9 | 800 | 200 | 20 | 12 | 9 | 5 | 3 | 2 | 2 | 1 |
| deuces-wild-colorado | Colorado Deuces (96.77%) | 800 | 200 | 25 | 16 | 13 | 4 | 3 | 2 | 2 | 1 |

### Deuces Wild 44 (3 variants)
Minimum winning hand: Three of a Kind
Four of a Kind pays 4 instead of 5

| ID | Name | Return |
|----|------|--------|
| deuces-wild-44-apdw | APDW Deuces Wild 44 | 99.96% |
| deuces-wild-44-nsud | NSUD Deuces Wild 44 | 99.73% |
| deuces-wild-44-illinois | Illinois Deuces Wild 44 | 98.91% |

### Loose Deuces (4 variants)
Minimum winning hand: Three of a Kind
Higher payout for Four Deuces (400-500)

| ID | Name | RF | 4D | WR | 5K | SF | 4K | FH | FL | ST | 3K |
|----|------|----|----|----|----|----|----|----|----|----|----|
| loose-deuces-500-17 | Loose Deuces 500-17 | 800 | 500 | 25 | 17 | 10 | 4 | 3 | 2 | 2 | 1 |
| loose-deuces-500-15 | Loose Deuces 500-15 | 800 | 500 | 25 | 15 | 10 | 4 | 3 | 2 | 2 | 1 |
| loose-deuces-500-12 | Loose Deuces 500-12 | 800 | 500 | 25 | 12 | 10 | 4 | 3 | 2 | 2 | 1 |
| loose-deuces-400-12 | Loose Deuces 400-12 | 800 | 400 | 25 | 12 | 10 | 4 | 3 | 2 | 2 | 1 |

### Double Deuces Wild (6 variants)
Minimum winning hand: Three of a Kind
Four Deuces pays 400

| ID | Name | Return |
|----|------|--------|
| double-deuces-wild-samstown | Sam's Town Deuces | 100.95% |
| double-deuces-wild-downtown | Downtown Deuces | 100.92% |
| double-deuces-wild-10-10 | Double Deuces Wild 10/10 | ~99% |
| double-deuces-wild-16-13 | Double Deuces Wild 16/13 | ~99% |
| double-deuces-wild-16-11 | Double Deuces Wild 16/11 | 99.62% |
| double-deuces-wild-16-10 | Double Deuces Wild 16/10 | 99.17% |

### Triple Deuces Wild (3 variants)
Minimum winning hand: Three of a Kind
Four Deuces pays 600

| ID | Name | Return |
|----|------|--------|
| triple-deuces-wild-11-8 | Triple Deuces Wild 11/8 | ~99% |
| triple-deuces-wild-10-8 | Triple Deuces Wild 10/8 | ~98% |
| triple-deuces-wild-9-6 | Triple Deuces Wild 9/6 | 98.86% |

### Deluxe Deuces Wild (2 variants)
Minimum winning hand: Three of a Kind
Higher payouts for lower hands (SF=15, 4K=10, FH=9, FL=4, ST=4, 3K=3)

| ID | Name | RF | 4D | WR | 5K | SF | 4K | FH | FL | ST | 3K |
|----|------|----|----|----|----|----|----|----|----|----|----|
| deluxe-deuces-wild-940 | Deluxe Deuces Wild 940 (100.65%) | 940 | 200 | 50 | 25 | 15 | 10 | 9 | 4 | 4 | 3 |
| deluxe-deuces-wild-800 | Deluxe Deuces Wild 800 (100.32%) | 800 | 200 | 50 | 25 | 15 | 10 | 9 | 4 | 4 | 3 |

### Double Bonus Deuces Wild (2 variants)
Minimum winning hand: Three of a Kind
Five of a Kind pays 160

| ID | Name | Return |
|----|------|--------|
| double-bonus-deuces-12 | Double Bonus Deuces 12 | 99.81% |
| double-bonus-deuces-9 | Double Bonus Deuces 9 | 98.61% |

### Super Bonus Deuces Wild (3 variants)
Minimum winning hand: Three of a Kind
Five of a Kind pays 160

| ID | Name | Return |
|----|------|--------|
| super-bonus-deuces-10 | Super Bonus Deuces 10 | 100.13% |
| super-bonus-deuces-9 | Super Bonus Deuces 9 | 99.67% |
| super-bonus-deuces-8 | Super Bonus Deuces 8 | 97.87% |

---

## Joker Poker Games (53-card deck, 1 Joker)

### Joker Poker - Kings or Better (9 variants)
Minimum winning hand: Pair of Kings or Better

| ID | Name | Return |
|----|------|--------|
| joker-poker-kings-940-20 | Joker Poker Kings 940/20 | 101.00% |
| joker-poker-kings-20-7 | Joker Poker Kings 20/7 | 100.65% |
| joker-poker-kings-100-64 | Joker Poker Kings 100.64% | 100.64% |
| joker-poker-kings-20-6 | Joker Poker Kings 20/6 | 99.08% |
| joker-poker-kings-18-7 | Joker Poker Kings 18/7 | 98.94% |
| joker-poker-kings-98-60 | Joker Poker Kings 98.60% | 98.60% |
| joker-poker-kings-17-7 | Joker Poker Kings 17/7 | 98.09% |
| joker-poker-kings-97-58 | Joker Poker Kings 97.58% | 97.58% |
| joker-poker-kings-15-7 | Joker Poker Kings 15/7 | 96.38% |

### Joker Poker - Two Pair or Better (5 variants)
Minimum winning hand: Two Pair

| ID | Name | Return |
|----|------|--------|
| joker-poker-two-pair-99-92 | Joker Poker Two Pair 99.92% | 99.92% |
| joker-poker-two-pair-20-10 | Joker Poker Two Pair 20/10 | 99.49% |
| joker-poker-two-pair-20-8 | Joker Poker Two Pair 20/8 | 99.08% |
| joker-poker-two-pair-98-59 | Joker Poker Two Pair 98.59% | 98.59% |
| joker-poker-two-pair-20-9 | Joker Poker Two Pair 20/9 | 97.99% |

### Deuces Joker Wild (2 variants)
53-card deck - Deuces AND Joker are wild
Minimum winning hand: Three of a Kind

| ID | Name | Return |
|----|------|--------|
| deuces-joker-wild-12-9 | Deuces Joker Wild 12/9 | 99.07% |
| deuces-joker-wild-10-8 | Deuces Joker Wild 10/8 | 97.25% |

---

## Double Joker Games (54-card deck, 2 Jokers)

### Double Joker (7 variants)
Minimum winning hand: Pair of Kings or Better (some variants Two Pair)

| ID | Name | Return |
|----|------|--------|
| double-joker-9-6-940 | Double Joker 9/6 940 | 100.65% |
| double-joker-9-6-800 | Double Joker 9/6 800 | 100.37% |
| double-joker-9-5-4 | Double Joker 9/5/4 | 99.97% |
| double-joker-8-6-4 | Double Joker 8/6/4 | 99.94% |
| double-joker-9-6 | Double Joker 9/6 | ~99% |
| double-joker-8-5-4 | Double Joker 8/5/4 | 98.10% |
| double-joker-5-4 | Double Joker 5/4 | ~97% |

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
- **Return** = Theoretical return percentage with optimal play
