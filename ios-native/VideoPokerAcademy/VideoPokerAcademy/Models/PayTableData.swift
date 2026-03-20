import Foundation

struct PayTableRow: Identifiable {
    let id = UUID()
    let handName: String
    let payouts: [Int] // Payouts for 1, 2, 3, 4, 5 coins
}

extension PayTable {
    var rows: [PayTableRow] {
        switch id {
        // ==========================================================================
        // MARK: - Jacks or Better (9 variants)
        // ==========================================================================
        case "jacks-or-better-9-6":
            // 99.54% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four of a Kind", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "jacks-or-better-9-5":
            // 98.45% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four of a Kind", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "jacks-or-better-8-6":
            // 98.39% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four of a Kind", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "jacks-or-better-8-5":
            // 97.30% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four of a Kind", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "jacks-or-better-8-5-35":
            // 99.66% return - 35 for 4K
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four of a Kind", payouts: [35, 70, 105, 140, 175]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "jacks-or-better-7-5":
            // 96.15% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four of a Kind", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "jacks-or-better-6-5":
            // 95.00% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four of a Kind", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "jacks-or-better-9-6-90":
            // 100.00% return - 90 for SF
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [90, 180, 270, 360, 450]),
                PayTableRow(handName: "Four of a Kind", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "jacks-or-better-9-6-940":
            // 99.90% return - 940 for RF (4700 at 5 coins)
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4700]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four of a Kind", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Tens or Better (1 variant)
        // ==========================================================================
        case "tens-or-better-6-5":
            // 99.14% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four of a Kind", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Tens or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Bonus Poker (4 variants)
        // ==========================================================================
        case "bonus-poker-8-5":
            // 99.17% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 2-4", payouts: [40, 80, 120, 160, 200]),
                PayTableRow(handName: "Four 5-K", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "bonus-poker-7-5":
            // 98.01% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 2-4", payouts: [40, 80, 120, 160, 200]),
                PayTableRow(handName: "Four 5-K", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "bonus-poker-7-5-1200":
            // 99.09% return - 1200 RF bonus (6000 at 5 coins)
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 6000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 2-4", payouts: [40, 80, 120, 160, 200]),
                PayTableRow(handName: "Four 5-K", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "bonus-poker-6-5":
            // 96.87% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 2-4", payouts: [40, 80, 120, 160, 200]),
                PayTableRow(handName: "Four 5-K", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Bonus Poker Deluxe (7 variants)
        // ==========================================================================
        case "bonus-poker-deluxe-9-6":
            // 99.64% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four of a Kind", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "bonus-poker-deluxe-9-5":
            // 98.55% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four of a Kind", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "bonus-poker-deluxe-8-6":
            // 98.49% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four of a Kind", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "bonus-poker-deluxe-8-6-100":
            // ~100% return with progressive
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four of a Kind", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "bonus-poker-deluxe-8-5":
            // 97.40% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four of a Kind", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "bonus-poker-deluxe-7-5":
            // 96.25% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four of a Kind", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Full House", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "bonus-poker-deluxe-6-5":
            // 95.36% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four of a Kind", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Full House", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Bonus Poker Plus (2 variants)
        // ==========================================================================
        case "bonus-poker-plus-10-7":
            // 99.61% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 2-4", payouts: [40, 80, 120, 160, 200]),
                PayTableRow(handName: "Four 5-K", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [10, 20, 30, 40, 50]),
                PayTableRow(handName: "Flush", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Straight", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "bonus-poker-plus-9-6":
            // 98.34% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 2-4", payouts: [40, 80, 120, 160, 200]),
                PayTableRow(handName: "Four 5-K", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Double Bonus (8 variants)
        // ==========================================================================
        case "double-bonus-10-7":
            // 100.17% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [10, 20, 30, 40, 50]),
                PayTableRow(handName: "Flush", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Straight", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "double-bonus-10-7-100":
            // ~100% return variant
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [10, 20, 30, 40, 50]),
                PayTableRow(handName: "Flush", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Straight", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "double-bonus-10-7-80":
            // 100.52% return - 80 SF
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [10, 20, 30, 40, 50]),
                PayTableRow(handName: "Flush", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Straight", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "double-bonus-10-7-4":
            // 100.77% return - 4K bonus
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [100, 200, 300, 400, 500]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [10, 20, 30, 40, 50]),
                PayTableRow(handName: "Flush", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Straight", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "double-bonus-10-6":
            // 98.88% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [10, 20, 30, 40, 50]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "double-bonus-9-7-5":
            // 99.11% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Straight", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "double-bonus-9-6-5":
            // 97.81% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "double-bonus-9-6-4":
            // 96.38% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Double Double Bonus (7 variants)
        // ==========================================================================
        case "double-double-bonus-10-6":
            // 100.07% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + 2-4", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four 2-4 + A-4", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [10, 20, 30, 40, 50]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "double-double-bonus-10-6-100":
            // ~100% return variant
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + 2-4", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four 2-4 + A-4", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [10, 20, 30, 40, 50]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "double-double-bonus-9-6":
            // 98.98% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + 2-4", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four 2-4 + A-4", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "double-double-bonus-9-5":
            // 97.87% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + 2-4", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four 2-4 + A-4", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "double-double-bonus-8-5":
            // 96.79% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + 2-4", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four 2-4 + A-4", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "double-double-bonus-7-5":
            // 95.71% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + 2-4", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four 2-4 + A-4", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "double-double-bonus-6-5":
            // 94.66% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + 2-4", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four 2-4 + A-4", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Super Double Bonus (4 variants)
        // ==========================================================================
        case "super-double-bonus-9-5":
            // 99.69% return (Full Pay)
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four J-K", payouts: [120, 240, 360, 480, 600]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-10", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "super-double-bonus-8-5":
            // 98.69% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four J-K", payouts: [120, 240, 360, 480, 600]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-10", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "super-double-bonus-7-5":
            // 97.77% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four J-K", payouts: [120, 240, 360, 480, 600]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-10", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "super-double-bonus-6-5":
            // 96.87% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four J-K", payouts: [120, 240, 360, 480, 600]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-10", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Triple Double Bonus (3 variants)
        // ==========================================================================
        case "triple-double-bonus-9-7":
            // 99.58% return (Full Pay)
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + 2-4", payouts: [800, 1600, 2400, 3200, 4000]),
                PayTableRow(handName: "Four 2-4 + A-4", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "triple-double-bonus-9-6":
            // 98.15% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + 2-4", payouts: [800, 1600, 2400, 3200, 4000]),
                PayTableRow(handName: "Four 2-4 + A-4", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "triple-double-bonus-8-5":
            // 95.97% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + 2-4", payouts: [800, 1600, 2400, 3200, 4000]),
                PayTableRow(handName: "Four 2-4 + A-4", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Deuces Wild (11 variants)
        // ==========================================================================
        case "deuces-wild-full-pay":
            // 100.76% return - 25-15-9-5-3-2-2-1
            return [
                PayTableRow(handName: "Natural Royal", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Four Deuces", payouts: [200, 400, 600, 800, 1000]),
                PayTableRow(handName: "Wild Royal", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Five of a Kind", payouts: [15, 30, 45, 60, 75]),
                PayTableRow(handName: "Straight Flush", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Four of a Kind", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Full House", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Flush", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Straight", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Three of a Kind", payouts: [1, 2, 3, 4, 5])
            ]

        case "deuces-wild-nsud":
            // 99.73% return - NSUD (Not So Ugly Ducks) 25-16-10-4-4-3-2-1
            return [
                PayTableRow(handName: "Natural Royal", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Four Deuces", payouts: [200, 400, 600, 800, 1000]),
                PayTableRow(handName: "Wild Royal", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Five of a Kind", payouts: [16, 32, 48, 64, 80]),
                PayTableRow(handName: "Straight Flush", payouts: [10, 20, 30, 40, 50]),
                PayTableRow(handName: "Four of a Kind", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Full House", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Flush", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Straight", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Three of a Kind", payouts: [1, 2, 3, 4, 5])
            ]

        case "deuces-wild-illinois":
            // Illinois Deuces
            return [
                PayTableRow(handName: "Natural Royal", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Four Deuces", payouts: [200, 400, 600, 800, 1000]),
                PayTableRow(handName: "Wild Royal", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Five of a Kind", payouts: [15, 30, 45, 60, 75]),
                PayTableRow(handName: "Straight Flush", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Four of a Kind", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Full House", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Flush", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Straight", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Three of a Kind", payouts: [1, 2, 3, 4, 5])
            ]

        case "deuces-wild-colorado":
            // Colorado Deuces
            return [
                PayTableRow(handName: "Natural Royal", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Four Deuces", payouts: [200, 400, 600, 800, 1000]),
                PayTableRow(handName: "Wild Royal", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Five of a Kind", payouts: [15, 30, 45, 60, 75]),
                PayTableRow(handName: "Straight Flush", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Four of a Kind", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Full House", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Flush", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Straight", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Three of a Kind", payouts: [1, 2, 3, 4, 5])
            ]

        case "deuces-wild-25-15-9":
            return [
                PayTableRow(handName: "Natural Royal", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Four Deuces", payouts: [200, 400, 600, 800, 1000]),
                PayTableRow(handName: "Wild Royal", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Five of a Kind", payouts: [15, 30, 45, 60, 75]),
                PayTableRow(handName: "Straight Flush", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Four of a Kind", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Full House", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Flush", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Straight", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Three of a Kind", payouts: [1, 2, 3, 4, 5])
            ]

        case "deuces-wild-25-12-9":
            return [
                PayTableRow(handName: "Natural Royal", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Four Deuces", payouts: [200, 400, 600, 800, 1000]),
                PayTableRow(handName: "Wild Royal", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Five of a Kind", payouts: [12, 24, 36, 48, 60]),
                PayTableRow(handName: "Straight Flush", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Four of a Kind", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Full House", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Flush", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Straight", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Three of a Kind", payouts: [1, 2, 3, 4, 5])
            ]

        case "deuces-wild-25-15-8":
            return [
                PayTableRow(handName: "Natural Royal", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Four Deuces", payouts: [200, 400, 600, 800, 1000]),
                PayTableRow(handName: "Wild Royal", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Five of a Kind", payouts: [15, 30, 45, 60, 75]),
                PayTableRow(handName: "Straight Flush", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Four of a Kind", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Full House", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Flush", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Straight", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Three of a Kind", payouts: [1, 2, 3, 4, 5])
            ]

        case "deuces-wild-20-15-9":
            return [
                PayTableRow(handName: "Natural Royal", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Four Deuces", payouts: [200, 400, 600, 800, 1000]),
                PayTableRow(handName: "Wild Royal", payouts: [20, 40, 60, 80, 100]),
                PayTableRow(handName: "Five of a Kind", payouts: [15, 30, 45, 60, 75]),
                PayTableRow(handName: "Straight Flush", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Four of a Kind", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Full House", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Flush", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Straight", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Three of a Kind", payouts: [1, 2, 3, 4, 5])
            ]

        case "deuces-wild-20-12-9":
            return [
                PayTableRow(handName: "Natural Royal", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Four Deuces", payouts: [200, 400, 600, 800, 1000]),
                PayTableRow(handName: "Wild Royal", payouts: [20, 40, 60, 80, 100]),
                PayTableRow(handName: "Five of a Kind", payouts: [12, 24, 36, 48, 60]),
                PayTableRow(handName: "Straight Flush", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Four of a Kind", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Full House", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Flush", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Straight", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Three of a Kind", payouts: [1, 2, 3, 4, 5])
            ]

        case "deuces-wild-44-nsud", "deuces-wild-44-illinois", "deuces-wild-44-apdw":
            // 44 variants - 4 Deuces pays 44
            return [
                PayTableRow(handName: "Natural Royal", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Four Deuces", payouts: [44, 88, 132, 176, 220]),
                PayTableRow(handName: "Wild Royal", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Five of a Kind", payouts: [16, 32, 48, 64, 80]),
                PayTableRow(handName: "Straight Flush", payouts: [10, 20, 30, 40, 50]),
                PayTableRow(handName: "Four of a Kind", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Full House", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Flush", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Straight", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Three of a Kind", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Loose Deuces (4 variants)
        // ==========================================================================
        case "loose-deuces-500-17":
            // 101.60% return
            return [
                PayTableRow(handName: "Natural Royal", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Four Deuces", payouts: [500, 1000, 1500, 2000, 2500]),
                PayTableRow(handName: "Wild Royal", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Five of a Kind", payouts: [17, 34, 51, 68, 85]),
                PayTableRow(handName: "Straight Flush", payouts: [10, 20, 30, 40, 50]),
                PayTableRow(handName: "Four of a Kind", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Full House", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Flush", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Straight", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Three of a Kind", payouts: [1, 2, 3, 4, 5])
            ]

        case "loose-deuces-500-15":
            // 100.97% return
            return [
                PayTableRow(handName: "Natural Royal", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Four Deuces", payouts: [500, 1000, 1500, 2000, 2500]),
                PayTableRow(handName: "Wild Royal", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Five of a Kind", payouts: [15, 30, 45, 60, 75]),
                PayTableRow(handName: "Straight Flush", payouts: [10, 20, 30, 40, 50]),
                PayTableRow(handName: "Four of a Kind", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Full House", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Flush", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Straight", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Three of a Kind", payouts: [1, 2, 3, 4, 5])
            ]

        case "loose-deuces-500-12":
            // 100.15% return
            return [
                PayTableRow(handName: "Natural Royal", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Four Deuces", payouts: [500, 1000, 1500, 2000, 2500]),
                PayTableRow(handName: "Wild Royal", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Five of a Kind", payouts: [15, 30, 45, 60, 75]),
                PayTableRow(handName: "Straight Flush", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Four of a Kind", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Full House", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Flush", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Straight", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Three of a Kind", payouts: [1, 2, 3, 4, 5])
            ]

        case "loose-deuces-400-12":
            // 99.20% return
            return [
                PayTableRow(handName: "Natural Royal", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Four Deuces", payouts: [500, 1000, 1500, 2000, 2500]),
                PayTableRow(handName: "Wild Royal", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Five of a Kind", payouts: [12, 24, 36, 48, 60]),
                PayTableRow(handName: "Straight Flush", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Four of a Kind", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Full House", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Flush", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Straight", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Three of a Kind", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - All American (4 variants)
        // ==========================================================================
        case "all-american-40-7":
            // 100.72% return (Full Pay)
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [200, 400, 600, 800, 1000]),
                PayTableRow(handName: "Four of a Kind", payouts: [40, 80, 120, 160, 200]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Straight", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "all-american-35-8":
            // 99.60% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [200, 400, 600, 800, 1000]),
                PayTableRow(handName: "Four of a Kind", payouts: [35, 70, 105, 140, 175]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Straight", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "all-american-30-8":
            // 98.49% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [200, 400, 600, 800, 1000]),
                PayTableRow(handName: "Four of a Kind", payouts: [30, 60, 90, 120, 150]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Straight", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "all-american-25-8":
            // 97.37% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [200, 400, 600, 800, 1000]),
                PayTableRow(handName: "Four of a Kind", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Straight", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Triple Bonus (3 variants) - Kings or Better
        // ==========================================================================
        case "triple-bonus-9-5":
            // 99.94% return (Full Pay)
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [240, 480, 720, 960, 1200]),
                PayTableRow(handName: "Four 2-4", payouts: [120, 240, 360, 480, 600]),
                PayTableRow(handName: "Four 5-K", payouts: [75, 150, 225, 300, 375]),
                PayTableRow(handName: "Full House", payouts: [10, 20, 30, 40, 50]),
                PayTableRow(handName: "Flush", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Straight", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Kings or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "triple-bonus-8-5":
            // 98.52% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [240, 480, 720, 960, 1200]),
                PayTableRow(handName: "Four 2-4", payouts: [120, 240, 360, 480, 600]),
                PayTableRow(handName: "Four 5-K", payouts: [75, 150, 225, 300, 375]),
                PayTableRow(handName: "Full House", payouts: [10, 20, 30, 40, 50]),
                PayTableRow(handName: "Flush", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Kings or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "triple-bonus-7-5":
            // 97.45% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [240, 480, 720, 960, 1200]),
                PayTableRow(handName: "Four 2-4", payouts: [120, 240, 360, 480, 600]),
                PayTableRow(handName: "Four 5-K", payouts: [75, 150, 225, 300, 375]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Kings or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Triple Bonus Plus (3 variants)
        // ==========================================================================
        case "triple-bonus-plus-9-5":
            // 99.80% return (Full Pay)
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [100, 200, 300, 400, 500]),
                PayTableRow(handName: "Four Aces", payouts: [240, 480, 720, 960, 1200]),
                PayTableRow(handName: "Four 2-4", payouts: [120, 240, 360, 480, 600]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "triple-bonus-plus-8-5":
            // 98.73% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [100, 200, 300, 400, 500]),
                PayTableRow(handName: "Four Aces", payouts: [240, 480, 720, 960, 1200]),
                PayTableRow(handName: "Four 2-4", payouts: [120, 240, 360, 480, 600]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "triple-bonus-plus-7-5":
            // 97.67% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [100, 200, 300, 400, 500]),
                PayTableRow(handName: "Four Aces", payouts: [240, 480, 720, 960, 1200]),
                PayTableRow(handName: "Four 2-4", payouts: [120, 240, 360, 480, 600]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Triple Triple Bonus (4 variants)
        // ==========================================================================
        case "triple-triple-bonus-9-6":
            // 99.75% return (Full Pay)
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + 2-4", payouts: [800, 1600, 2400, 3200, 4000]),
                PayTableRow(handName: "Four 2-4 + A-4", payouts: [800, 1600, 2400, 3200, 4000]),
                PayTableRow(handName: "Four 2-4 + 2-4", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Three of a Kind", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "triple-triple-bonus-9-5":
            // 98.61% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + 2-4", payouts: [800, 1600, 2400, 3200, 4000]),
                PayTableRow(handName: "Four 2-4 + A-4", payouts: [800, 1600, 2400, 3200, 4000]),
                PayTableRow(handName: "Four 2-4 + 2-4", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Three of a Kind", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "triple-triple-bonus-8-5":
            // 97.61% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [55, 110, 165, 220, 275]),
                PayTableRow(handName: "Four Aces + 2-4", payouts: [800, 1600, 2400, 3200, 4000]),
                PayTableRow(handName: "Four 2-4 + A-4", payouts: [800, 1600, 2400, 3200, 4000]),
                PayTableRow(handName: "Four 2-4 + 2-4", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Three of a Kind", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "triple-triple-bonus-7-5":
            // 96.55% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + 2-4", payouts: [800, 1600, 2400, 3200, 4000]),
                PayTableRow(handName: "Four 2-4 + A-4", payouts: [800, 1600, 2400, 3200, 4000]),
                PayTableRow(handName: "Four 2-4 + 2-4", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Three of a Kind", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - White Hot Aces (4 variants)
        // ==========================================================================
        case "white-hot-aces-9-5":
            // 99.80% return (Full Pay)
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [100, 200, 300, 400, 500]),
                PayTableRow(handName: "Four Aces", payouts: [240, 480, 720, 960, 1200]),
                PayTableRow(handName: "Four 2-4", payouts: [120, 240, 360, 480, 600]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "white-hot-aces-8-5":
            // 98.50% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four Aces", payouts: [240, 480, 720, 960, 1200]),
                PayTableRow(handName: "Four 2-4", payouts: [120, 240, 360, 480, 600]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "white-hot-aces-7-5":
            // 97.44% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four Aces", payouts: [240, 480, 720, 960, 1200]),
                PayTableRow(handName: "Four 2-4", payouts: [120, 240, 360, 480, 600]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "white-hot-aces-6-5":
            // 96.39% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [240, 480, 720, 960, 1200]),
                PayTableRow(handName: "Four 2-4", payouts: [120, 240, 360, 480, 600]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Super Aces (3 variants)
        // ==========================================================================
        case "super-aces-8-5":
            // 99.94% return (Full Pay)
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [60, 120, 180, 240, 300]),
                PayTableRow(handName: "Four Aces", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "super-aces-7-5":
            // 98.85% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [60, 120, 180, 240, 300]),
                PayTableRow(handName: "Four Aces", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "super-aces-6-5":
            // 97.78% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [60, 120, 180, 240, 300]),
                PayTableRow(handName: "Four Aces", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Aces & Eights (2 variants)
        // ==========================================================================
        case "aces-and-eights-8-5":
            // 99.78% return (Full Pay)
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces/Eights", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four Sevens", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four 2-6/9-K", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "aces-and-eights-7-5":
            // 98.63% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces/Eights", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four Sevens", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four 2-6/9-K", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Aces & Faces (4 variants)
        // ==========================================================================
        case "aces-and-faces-8-5":
            // 99.26% return (Full Pay)
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four J-K", payouts: [40, 80, 120, 160, 200]),
                PayTableRow(handName: "Four 2-10", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "aces-and-faces-7-6":
            // 98.85% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four J-K", payouts: [40, 80, 120, 160, 200]),
                PayTableRow(handName: "Four 2-10", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "aces-and-faces-7-5":
            // 98.12% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four J-K", payouts: [40, 80, 120, 160, 200]),
                PayTableRow(handName: "Four 2-10", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "aces-and-faces-6-5":
            // 96.97% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four J-K", payouts: [40, 80, 120, 160, 200]),
                PayTableRow(handName: "Four 2-10", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Aces Bonus (3 variants)
        // ==========================================================================
        case "aces-bonus-8-5":
            // 99.40% return (Full Pay)
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [800, 1600, 2400, 3200, 4000]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [40, 80, 120, 160, 200]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "aces-bonus-7-5":
            // 98.25% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [800, 1600, 2400, 3200, 4000]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [40, 80, 120, 160, 200]),
                PayTableRow(handName: "Full House", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "aces-bonus-6-5":
            // 97.11% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [800, 1600, 2400, 3200, 4000]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [40, 80, 120, 160, 200]),
                PayTableRow(handName: "Full House", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Bonus Aces & Faces (3 variants)
        // ==========================================================================
        case "bonus-aces-faces-8-5":
            // 99.26% return (Full Pay)
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four J-K", payouts: [40, 80, 120, 160, 200]),
                PayTableRow(handName: "Four 2-10", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "bonus-aces-faces-7-5":
            // 98.12% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four J-K", payouts: [40, 80, 120, 160, 200]),
                PayTableRow(handName: "Four 2-10", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "bonus-aces-faces-6-5":
            // 96.97% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four J-K", payouts: [40, 80, 120, 160, 200]),
                PayTableRow(handName: "Four 2-10", payouts: [25, 50, 75, 100, 125]),
                PayTableRow(handName: "Full House", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Double Jackpot (2 variants)
        // ==========================================================================
        case "double-jackpot-8-5":
            // 99.63% return (Full Pay)
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + Face", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four Aces", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four K/Q/J + Face", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four K/Q/J", payouts: [40, 80, 120, 160, 200]),
                PayTableRow(handName: "Four 2-10", payouts: [20, 40, 60, 80, 100]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "double-jackpot-7-5":
            // 98.49% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + Face", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four Aces", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four K/Q/J + Face", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four K/Q/J", payouts: [40, 80, 120, 160, 200]),
                PayTableRow(handName: "Four 2-10", payouts: [20, 40, 60, 80, 100]),
                PayTableRow(handName: "Full House", payouts: [7, 14, 21, 28, 35]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [2, 4, 6, 8, 10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Double Double Jackpot (2 variants)
        // ==========================================================================
        case "double-double-jackpot-10-6":
            // 100.35% return (Full Pay)
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + Face", payouts: [320, 640, 960, 1280, 1600]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four K/Q/J + Face", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four K/Q/J", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 2-10", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [10, 20, 30, 40, 50]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "double-double-jackpot-9-6":
            // 99.27% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + Face", payouts: [320, 640, 960, 1280, 1600]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four K/Q/J + Face", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four K/Q/J", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 2-10", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Royal Aces Bonus (4 variants)
        // ==========================================================================
        case "royal-aces-bonus-9-6":
            // 99.58% return (Full Pay)
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [100, 200, 300, 400, 500]),
                PayTableRow(handName: "Four Aces", payouts: [800, 1600, 2400, 3200, 4000]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Pair of Aces", payouts: [1, 2, 3, 4, 5])
            ]

        case "royal-aces-bonus-10-5":
            // 99.20% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [800, 1600, 2400, 3200, 4000]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [10, 20, 30, 40, 50]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Pair of Aces", payouts: [1, 2, 3, 4, 5])
            ]

        case "royal-aces-bonus-8-6":
            // 98.51% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [100, 200, 300, 400, 500]),
                PayTableRow(handName: "Four Aces", payouts: [800, 1600, 2400, 3200, 4000]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Pair of Aces", payouts: [1, 2, 3, 4, 5])
            ]

        case "royal-aces-bonus-9-5":
            // 97.55% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces", payouts: [800, 1600, 2400, 3200, 4000]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Pair of Aces", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - DDB Aces & Faces (2 variants)
        // ==========================================================================
        case "ddb-aces-faces-9-6":
            // 99.47% return (Full Pay)
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + Face", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four J-K + A-4", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four J-K", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 2-10", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "ddb-aces-faces-9-5":
            // 98.37% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + Face", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four J-K + A-4", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four J-K", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 2-10", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - DDB Plus (3 variants)
        // ==========================================================================
        case "ddb-plus-9-6":
            // 99.68% return (Full Pay)
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + 2-4", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four 2-4 + A-4", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [6, 12, 18, 24, 30]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "ddb-plus-9-5":
            // 98.57% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + 2-4", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four 2-4 + A-4", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [9, 18, 27, 36, 45]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        case "ddb-plus-8-5":
            // 97.49% return
            return [
                PayTableRow(handName: "Royal Flush", payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "Straight Flush", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Four Aces + 2-4", payouts: [400, 800, 1200, 1600, 2000]),
                PayTableRow(handName: "Four 2-4 + A-4", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four Aces", payouts: [160, 320, 480, 640, 800]),
                PayTableRow(handName: "Four 2-4", payouts: [80, 160, 240, 320, 400]),
                PayTableRow(handName: "Four 5-K", payouts: [50, 100, 150, 200, 250]),
                PayTableRow(handName: "Full House", payouts: [8, 16, 24, 32, 40]),
                PayTableRow(handName: "Flush", payouts: [5, 10, 15, 20, 25]),
                PayTableRow(handName: "Straight", payouts: [4, 8, 12, 16, 20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3, 6, 9, 12, 15]),
                PayTableRow(handName: "Two Pair", payouts: [1, 2, 3, 4, 5]),
                PayTableRow(handName: "Jacks or Better", payouts: [1, 2, 3, 4, 5])
            ]

        // ==========================================================================
        // MARK: - Default (empty for unknown paytables)
        // ==========================================================================
        default:
            return []
        }
    }
}
