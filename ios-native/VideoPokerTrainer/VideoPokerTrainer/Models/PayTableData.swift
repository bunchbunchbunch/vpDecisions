import Foundation

struct PayTableRow: Identifiable {
    let id = UUID()
    let handName: String
    let payouts: [Int] // Payouts for 1, 2, 3, 4, 5 coins
}

extension PayTable {
    var rows: [PayTableRow] {
        switch id {
        case "jacks-or-better-9-6":
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

        case "tens-or-better-6-5":
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

        case "double-double-bonus-9-6":
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

        case "deuces-wild-nsud":
            // NSUD (Not So Ugly Ducks): 800-200-25-16-10-4-4-3-2-1
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

        case "deuces-wild-full-pay":
            // Full Pay Deuces: 25-15-9-5-3-2-2-1
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

        case "bonus-poker-8-5":
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

        case "double-bonus-10-7":
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

        case "triple-double-bonus-9-6":
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

        case "all-american":
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

        case "bonus-poker-deluxe-8-6":
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

        default:
            return []
        }
    }
}
