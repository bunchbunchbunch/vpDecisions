import SwiftUI

/// Displays contextual information about the current game, variant, and strategy methodology.
struct GameInfoSheet: View {
    let paytableId: String
    let variant: GameInfoVariant
    @Binding var isPresented: Bool

    private var family: GameFamily {
        PayTable.allPayTables.first { $0.id == paytableId }?.family ?? .jacksOrBetter
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    variantSection
                    gameFamilySection
                    strategySection
                    if variant == .ultimateX {
                        ultimateXStrategyMethodology
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Game Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Variant Section

    @ViewBuilder
    private var variantSection: some View {
        switch variant {
        case .standard:
            infoCard(title: "Standard Video Poker", icon: "suit.spade.fill") {
                Text("Draw poker played on a machine. You're dealt five cards, choose which to keep, then draw replacements. Winning hands pay according to the pay table displayed on screen.")
                Text("The game uses a standard 52-card deck (or 53 with a joker in wild card games). Each hand is dealt from a freshly shuffled deck.")
            }
        case .ultimateX:
            infoCard(title: "Multi-Hand Multiplier Poker", icon: "arrow.up.right.circle.fill") {
                Text("A multi-hand draw poker variant where winning hands earn multipliers that apply to the **next** hand on that line. The bet is doubled (10 coins per line instead of 5) to activate the multiplier feature.")
                Text("Multipliers range from 2\u{00d7} to 12\u{00d7} depending on the hand rank and game family. Higher-ranking wins earn larger multipliers. The multiplier carries forward one hand, then resets to 1\u{00d7} if the next hand doesn't win.")
                Text("The strategic challenge is that optimal play changes based on your current multiplier. With a high multiplier, you may favor safer holds that protect expected value, while with a 1\u{00d7} multiplier you may play more aggressively to chase multiplier-earning hands.")
            }
        case .wildWildWild:
            infoCard(title: "Wild Card Draw Poker", icon: "sparkles") {
                Text("A draw poker variant where 0 to 3 wild cards (jokers) are randomly added to the deck before each deal. The bet is doubled (10 coins per line) to activate the wild card feature.")
                Text("The number of wilds added follows a probability distribution that varies by game. Wild cards can substitute for any card to form the best possible hand, enabling hands like Five of a Kind that aren't possible in standard play.")
                Text("The pay table is adjusted with boosted payouts for many hands. Five of a Kind pays differently based on rank tier (Aces pay the most, low cards pay less). The strategy changes significantly based on how many wilds are in the deck.")
            }
        }
    }

    // MARK: - Game Family Section

    private var gameFamilySection: some View {
        infoCard(title: gameFamilyName, icon: "rectangle.stack.fill") {
            Text(gameFamilyDescription)
        }
    }

    private var gameFamilyName: String {
        switch family {
        case .jacksOrBetter: return "Jacks or Better"
        case .tensOrBetter: return "Tens or Better"
        case .bonusPoker: return "Bonus Poker"
        case .bonusPokerDeluxe: return "Bonus Poker Deluxe"
        case .bonusPokerPlus: return "Bonus Poker Plus"
        case .doubleBonus: return "Double Bonus"
        case .doubleDoubleBonus: return "Double Double Bonus"
        case .tripleDoubleBonus: return "Triple Double Bonus"
        case .tripleBonus: return "Triple Bonus"
        case .tripleBonusPlus: return "Triple Bonus Plus"
        case .tripleTripleBonus: return "Triple Triple Bonus"
        case .deucesWild: return "Deuces Wild"
        case .looseDeuces: return "Loose Deuces"
        case .superDoubleBonus: return "Super Double Bonus"
        case .superAces: return "Super Aces"
        case .allAmerican: return "All American"
        default: return family.displayName
        }
    }

    private var gameFamilyDescription: String {
        switch family {
        case .jacksOrBetter:
            return "The most common video poker game. A pair of Jacks or higher is the minimum paying hand. All four-of-a-kind hands pay the same regardless of rank. A straightforward game ideal for learning basic video poker strategy."
        case .tensOrBetter:
            return "Similar to Jacks or Better but with a lower minimum paying hand \u{2014} a pair of Tens or higher pays. The pay table is adjusted to compensate for the more frequent wins."
        case .bonusPoker:
            return "Based on Jacks or Better but with enhanced payouts for four-of-a-kind hands. Four Aces pay the most, followed by four 2s-4s, then four 5s-Kings. This rank-based bonus structure adds strategic depth to quad decisions."
        case .bonusPokerDeluxe:
            return "All four-of-a-kind hands pay the same enhanced amount regardless of rank. This simplifies quad strategy compared to standard Bonus Poker while still offering a higher four-of-a-kind payout than Jacks or Better."
        case .doubleBonus:
            return "Significantly boosted four-of-a-kind payouts with three rank tiers: Aces pay the most, 2s-4s pay a mid-range bonus, and 5s-Kings pay a smaller bonus. The enhanced quad payouts come at the cost of reduced two-pair and full house returns."
        case .doubleDoubleBonus:
            return "Extends Double Bonus with kicker-based payouts. Four Aces with a 2, 3, or 4 kicker pays a premium. Four 2s-4s with an Ace through 4 kicker also earns a bonus. The kicker adds another layer of strategic consideration when holding quads."
        case .tripleDoubleBonus:
            return "Further enhances the kicker-based payout structure. The premium for four Aces with a low kicker is even higher, and the rank-tier bonuses are amplified. A high-volatility game where quad hands with the right kicker can produce large payouts."
        case .deucesWild:
            return "All four 2s (deuces) are wild and can substitute for any card. This dramatically changes strategy and hand rankings. The minimum paying hand is three of a kind, and unique hands like Five of a Kind and Four Deuces have their own pay table entries."
        case .looseDeuces:
            return "A Deuces Wild variant with an increased payout for Four Deuces (the rarest deuces-specific hand). The higher Four Deuces payout is offset by lower payouts on other hands."
        case .allAmerican:
            return "Flushes, straights, and straight flushes all pay enhanced amounts compared to Jacks or Better. In exchange, full house and two-pair payouts are reduced. This shifts strategy toward chasing straight and flush draws."
        case .superDoubleBonus:
            return "An extension of Double Bonus with even more rank tiers for four-of-a-kind hands. Face cards (Jacks, Queens, Kings) get their own bonus tier in addition to Aces and low cards."
        default:
            return "A video poker variant with its own unique pay table structure and strategic considerations. Consult the pay table displayed during play for specific hand payouts."
        }
    }

    // MARK: - Strategy Section

    private var strategySection: some View {
        infoCard(title: "How Strategy Works", icon: "brain.head.profile") {
            Text("Optimal strategy is pre-computed by evaluating every possible draw outcome for every possible hold combination. For each of the 32 ways to hold/discard 5 cards, the expected value (EV) is calculated as the probability-weighted average payout across all possible replacement cards.")
            Text("The hold combination with the highest EV is the optimal play. The strategy files used by this app contain the optimal hold for every possible dealt hand, computed by exhaustive analysis.")
            if variant == .wildWildWild {
                Text("For the wild card variant, separate strategy files are computed for each possible wild count (1, 2, or 3 wilds in deck). When 0 wilds are added, the standard strategy applies since the deck is unchanged.")
            }
        }
    }

    // MARK: - Ultimate X Methodology

    private var ultimateXStrategyMethodology: some View {
        infoCard(title: "Multiplier Strategy Scoring", icon: "function") {
            Text("In the multiplier variant, each hold option is scored using a formula that accounts for both the immediate expected value and the future value of the multiplier earned:")
            Text("**Score = (Avg Multiplier \u{00d7} 2 \u{00d7} Base EV) + Next-Hand Multiplier Value \u{2212} 1**")
                .font(.system(.callout, design: .monospaced))
                .padding(.vertical, 4)
            Text("**EV** (Base EV \u{00d7} Avg Multiplier \u{00d7} 2) represents the expected return of this hold given your current multiplier and the doubled bet cost.")
            Text("**NH Mult** (Next-Hand Multiplier Value) represents the average future multiplier this hold will earn. Holds that tend to produce winning hands earn higher next-hand multiplier value, even if their immediate EV is lower.")
            Text("**Score** combines both components minus 1 (the cost of the double bet) to produce a single number where values above 0 are profitable. The hold with the highest score is optimal.")
            Text("This means optimal play sometimes differs from standard strategy. A hold with slightly lower immediate EV but a much higher expected multiplier can be the better play overall.")
        }
    }

    // MARK: - Card Helper

    private func infoCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .font(.system(size: 15))
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Variant Abstraction

/// Simplified variant enum for use across all modes (not all modes use PlayVariant)
enum GameInfoVariant {
    case standard
    case ultimateX
    case wildWildWild

    init(from playVariant: PlayVariant) {
        switch playVariant {
        case .standard: self = .standard
        case .ultimateX: self = .ultimateX
        case .wildWildWild: self = .wildWildWild
        }
    }

    init(isUltimateX: Bool) {
        self = isUltimateX ? .ultimateX : .standard
    }
}
