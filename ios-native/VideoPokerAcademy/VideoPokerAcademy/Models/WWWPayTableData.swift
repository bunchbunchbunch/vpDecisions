import Foundation

/// Explicit WWW pay table data with boosted 5-coin payouts and rank-tiered Five of a Kind.
/// Source: docs/www-pay-tables.md (transcribed from in-game screenshots).
///
/// Add new pay tables here as WWW strategies are generated and uploaded to Supabase.
/// The hand names must exactly match what `evaluateWWWHand()` returns.
enum WWWPayTableData {

    /// Returns explicit WWW pay table rows for a given paytable ID, or nil if not defined.
    static func rows(for paytableId: String) -> [PayTableRow]? {
        switch paytableId {

        // ══════════════════════════════════════════════════════════════════
        // MARK: - Jacks or Better 9/6
        // ══════════════════════════════════════════════════════════════════
        case "jacks-or-better-9-6":
            return [
                PayTableRow(handName: "5 Aces",         payouts: [25,  50,  75,  100, 4000]),
                PayTableRow(handName: "Royal Flush",    payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "5 2s,3s,4s",     payouts: [25,  50,  75,  100, 1600]),
                PayTableRow(handName: "5 5s thru Ks",   payouts: [25,  50,  75,  100, 500]),
                PayTableRow(handName: "Straight Flush", payouts: [50,  100, 150, 200, 250]),
                PayTableRow(handName: "Four of a Kind", payouts: [25,  50,  75,  100, 150]),
                PayTableRow(handName: "Full House",     payouts: [9,   18,  27,  36,  55]),
                PayTableRow(handName: "Flush",          payouts: [6,   12,  18,  24,  30]),
                PayTableRow(handName: "Straight",       payouts: [4,   8,   12,  16,  25]),
                PayTableRow(handName: "Three of a Kind", payouts: [3,  6,   9,   12,  15]),
                PayTableRow(handName: "Two Pair",       payouts: [2,   4,   6,   8,   10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1,  2,   3,   4,   5]),
            ]

        // ══════════════════════════════════════════════════════════════════
        // MARK: - Bonus Poker 8/5
        // ══════════════════════════════════════════════════════════════════
        case "bonus-poker-8-5":
            return [
                PayTableRow(handName: "5 Aces",         payouts: [80,  160, 240, 320, 4000]),
                PayTableRow(handName: "Royal Flush",    payouts: [250, 500, 750, 1000, 4000]),
                PayTableRow(handName: "5 2s,3s,4s",     payouts: [40,  80,  120, 160, 1600]),
                PayTableRow(handName: "5 5s thru Ks",   payouts: [25,  50,  75,  100, 500]),
                PayTableRow(handName: "Four Aces",      payouts: [80,  160, 240, 320, 400]),
                PayTableRow(handName: "Straight Flush", payouts: [50,  100, 150, 200, 250]),
                PayTableRow(handName: "Four 2-4",       payouts: [40,  80,  120, 160, 200]),
                PayTableRow(handName: "Four 5-K",       payouts: [25,  50,  75,  100, 145]),
                PayTableRow(handName: "Full House",     payouts: [8,   16,  24,  32,  45]),
                PayTableRow(handName: "Flush",          payouts: [5,   10,  15,  20,  30]),
                PayTableRow(handName: "Straight",       payouts: [4,   8,   12,  16,  20]),
                PayTableRow(handName: "Three of a Kind", payouts: [3,  6,   9,   12,  15]),
                PayTableRow(handName: "Two Pair",       payouts: [2,   4,   6,   8,   10]),
                PayTableRow(handName: "Jacks or Better", payouts: [1,  2,   3,   4,   5]),
            ]

        default:
            return nil
        }
    }

    // MARK: - Five of a Kind Rank Resolution

    /// Maps a five-of-a-kind rank to the correct pay table hand name.
    /// Different games have different rank tier structures.
    static func fiveOfAKindHandName(for rank: Int, paytableId: String) -> String {
        switch paytableId {

        // Jacks or Better / Bonus Poker: Aces / 2s-4s / 5s-Ks
        case _ where paytableId.hasPrefix("jacks-or-better"),
             _ where paytableId.hasPrefix("bonus-poker-"):
            if rank == 14 { return "5 Aces" }
            if rank >= 2 && rank <= 4 { return "5 2s,3s,4s" }
            return "5 5s thru Ks"

        default:
            return "Five of a Kind"
        }
    }

    /// Whether a wild royal flush is a distinct hand in this pay table.
    /// If false, wild royals pay as "Royal Flush".
    static func hasWildRoyalRow(for paytableId: String) -> Bool {
        guard let tableRows = rows(for: paytableId) else { return false }
        return tableRows.contains { $0.handName == "Wild Royal" }
    }
}
