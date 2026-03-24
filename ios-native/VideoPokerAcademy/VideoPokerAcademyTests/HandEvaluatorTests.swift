import Testing
@testable import VideoPokerAcademy

// MARK: - resolveQuadHandName Tests

@Suite("HandEvaluator.resolveQuadHandName")
struct ResolveQuadHandNameTests {

    // MARK: Standard single-tier (Jacks or Better, Bonus Poker Deluxe)

    @Test func jacksOrBetter_returnsGenericFourOfAKind() {
        let rows: Set<String> = ["Royal Flush", "Straight Flush", "Four of a Kind", "Full House",
                                 "Flush", "Straight", "Three of a Kind", "Two Pair", "Jacks or Better"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 7, paytableRowNames: rows) == "Four of a Kind")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 8, kickerRank: 5, paytableRowNames: rows) == "Four of a Kind")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 2, kickerRank: 9, paytableRowNames: rows) == "Four of a Kind")
    }

    // MARK: Bonus Poker / Double Bonus / Triple Bonus (Four Aces / Four 2-4 / Four 5-K)

    @Test func bonusPoker_acesReturnFourAces() {
        let rows: Set<String> = ["Four Aces", "Four 2-4", "Four 5-K", "Full House", "Flush",
                                 "Straight", "Three of a Kind", "Two Pair", "Jacks or Better"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 7, paytableRowNames: rows) == "Four Aces")
    }

    @Test func bonusPoker_lowRanksReturnFour2_4() {
        let rows: Set<String> = ["Four Aces", "Four 2-4", "Four 5-K", "Full House", "Flush",
                                 "Straight", "Three of a Kind", "Two Pair", "Jacks or Better"]
        for rank in [2, 3, 4] {
            #expect(HandEvaluator.resolveQuadHandName(quadRank: rank, kickerRank: 9, paytableRowNames: rows) == "Four 2-4",
                    "quadRank \(rank) should map to Four 2-4")
        }
    }

    @Test func bonusPoker_midHighRanksReturnFour5K() {
        let rows: Set<String> = ["Four Aces", "Four 2-4", "Four 5-K", "Full House", "Flush",
                                 "Straight", "Three of a Kind", "Two Pair", "Jacks or Better"]
        for rank in [5, 7, 8, 10, 11, 13] {
            #expect(HandEvaluator.resolveQuadHandName(quadRank: rank, kickerRank: 9, paytableRowNames: rows) == "Four 5-K",
                    "quadRank \(rank) should map to Four 5-K")
        }
    }

    // MARK: Double Double Bonus — kicker-sensitive

    @Test func ddb_acesWithLowKickerReturnFourAcesPlus2_4() {
        let rows: Set<String> = ["Four Aces + 2-4", "Four 2-4 + A-4", "Four Aces", "Four 2-4", "Four 5-K",
                                 "Full House", "Flush", "Straight", "Three of a Kind", "Two Pair", "Jacks or Better"]
        for kicker in [2, 3, 4] {
            #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: kicker, paytableRowNames: rows) == "Four Aces + 2-4",
                    "Aces with kicker \(kicker) should be Four Aces + 2-4")
        }
    }

    @Test func ddb_acesWithHighKickerReturnFourAces() {
        let rows: Set<String> = ["Four Aces + 2-4", "Four 2-4 + A-4", "Four Aces", "Four 2-4", "Four 5-K",
                                 "Full House", "Flush", "Straight", "Three of a Kind", "Two Pair", "Jacks or Better"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 9, paytableRowNames: rows) == "Four Aces")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 11, paytableRowNames: rows) == "Four Aces")
    }

    @Test func ddb_lowRankWithAceOrLowKickerReturnFour2_4PlusA4() {
        let rows: Set<String> = ["Four Aces + 2-4", "Four 2-4 + A-4", "Four Aces", "Four 2-4", "Four 5-K",
                                 "Full House", "Flush", "Straight", "Three of a Kind", "Two Pair", "Jacks or Better"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 3, kickerRank: 14, paytableRowNames: rows) == "Four 2-4 + A-4")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 3, kickerRank: 4, paytableRowNames: rows) == "Four 2-4 + A-4")
    }

    @Test func ddb_lowRankWithMidKickerReturnFour2_4() {
        let rows: Set<String> = ["Four Aces + 2-4", "Four 2-4 + A-4", "Four Aces", "Four 2-4", "Four 5-K",
                                 "Full House", "Flush", "Straight", "Three of a Kind", "Two Pair", "Jacks or Better"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 3, kickerRank: 9, paytableRowNames: rows) == "Four 2-4")
    }

    // MARK: DDB Plus (abbreviated ID — must use row names, not ID)

    @Test func ddbPlus_usesKickerRows() {
        let rows: Set<String> = ["Four Aces + 2-4", "Four 2-4 + A-4", "Four Aces", "Four 2-4", "Four 5-K",
                                 "Full House", "Flush", "Straight", "Three of a Kind", "Two Pair", "Jacks or Better"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 2, paytableRowNames: rows) == "Four Aces + 2-4")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 3, kickerRank: 14, paytableRowNames: rows) == "Four 2-4 + A-4")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 8, kickerRank: 5, paytableRowNames: rows) == "Four 5-K")
    }

    // MARK: Triple Double Bonus — has "Four 2-4 + 2-4" row

    @Test func tripleDoubleBonus_lowRankWithLowKicker() {
        let rows: Set<String> = ["Four Aces + 2-4", "Four 2-4 + A-4", "Four 2-4 + 2-4",
                                 "Four Aces", "Four 2-4", "Four 5-K", "Full House", "Jacks or Better"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 2, kickerRank: 3, paytableRowNames: rows) == "Four 2-4 + 2-4")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 2, kickerRank: 14, paytableRowNames: rows) == "Four 2-4 + A-4")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 2, kickerRank: 9, paytableRowNames: rows) == "Four 2-4")
    }

    // MARK: Super Aces / White Hot Aces (no kicker rows, same tier structure as Bonus Poker)

    @Test func superAces_eightQuadsReturnFour5K() {
        let rows: Set<String> = ["Four Aces", "Four 2-4", "Four 5-K", "Full House", "Flush",
                                 "Straight", "Three of a Kind", "Two Pair", "Jacks or Better"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 8, kickerRank: 5, paytableRowNames: rows) == "Four 5-K")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 9, paytableRowNames: rows) == "Four Aces")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 3, kickerRank: 9, paytableRowNames: rows) == "Four 2-4")
    }

    // MARK: Aces & Eights

    @Test func acesAndEights_acesReturnFourAcesEights() {
        let rows: Set<String> = ["Four Aces/Eights", "Four Sevens", "Four 2-6/9-K",
                                 "Full House", "Flush", "Straight", "Three of a Kind", "Two Pair", "Jacks or Better"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 5, paytableRowNames: rows) == "Four Aces/Eights")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 8, kickerRank: 5, paytableRowNames: rows) == "Four Aces/Eights")
    }

    @Test func acesAndEights_sevensReturnFourSevens() {
        let rows: Set<String> = ["Four Aces/Eights", "Four Sevens", "Four 2-6/9-K"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 7, kickerRank: 5, paytableRowNames: rows) == "Four Sevens")
    }

    @Test func acesAndEights_otherRanksReturnFour2_6_9_K() {
        let rows: Set<String> = ["Four Aces/Eights", "Four Sevens", "Four 2-6/9-K"]
        for rank in [2, 3, 5, 6, 9, 10, 11, 13] {
            #expect(HandEvaluator.resolveQuadHandName(quadRank: rank, kickerRank: 5, paytableRowNames: rows) == "Four 2-6/9-K",
                    "quadRank \(rank) should map to Four 2-6/9-K")
        }
    }

    // MARK: Aces & Faces / Bonus Aces & Faces

    @Test func acesAndFaces_allTiers() {
        let rows: Set<String> = ["Four Aces", "Four J-K", "Four 2-10"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 7, paytableRowNames: rows) == "Four Aces")
        for rank in [11, 12, 13] {
            #expect(HandEvaluator.resolveQuadHandName(quadRank: rank, kickerRank: 7, paytableRowNames: rows) == "Four J-K",
                    "quadRank \(rank) should map to Four J-K")
        }
        for rank in [2, 5, 8, 10] {
            #expect(HandEvaluator.resolveQuadHandName(quadRank: rank, kickerRank: 7, paytableRowNames: rows) == "Four 2-10",
                    "quadRank \(rank) should map to Four 2-10")
        }
    }

    // MARK: Super Double Bonus

    @Test func superDoubleBonus_acesWithFaceKicker() {
        let rows: Set<String> = ["Four Aces + Face", "Four Face + A-K", "Four Aces", "Four Face", "Four 2-10"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 12, paytableRowNames: rows) == "Four Aces + Face")
    }

    @Test func superDoubleBonus_acesWithLowKicker() {
        let rows: Set<String> = ["Four Aces + Face", "Four Face + A-K", "Four Aces", "Four Face", "Four 2-10"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 7, paytableRowNames: rows) == "Four Aces")
    }

    @Test func superDoubleBonus_faceWithHighKicker() {
        let rows: Set<String> = ["Four Aces + Face", "Four Face + A-K", "Four Aces", "Four Face", "Four 2-10"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 11, kickerRank: 14, paytableRowNames: rows) == "Four Face + A-K")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 11, kickerRank: 13, paytableRowNames: rows) == "Four Face + A-K")
    }

    @Test func superDoubleBonus_faceWithLowKicker() {
        let rows: Set<String> = ["Four Aces + Face", "Four Face + A-K", "Four Aces", "Four Face", "Four 2-10"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 11, kickerRank: 7, paytableRowNames: rows) == "Four Face")
    }

    @Test func superDoubleBonus_lowRanksReturnFour2_10() {
        let rows: Set<String> = ["Four Aces + Face", "Four Face + A-K", "Four Aces", "Four Face", "Four 2-10"]
        for rank in [2, 5, 8, 10] {
            #expect(HandEvaluator.resolveQuadHandName(quadRank: rank, kickerRank: 7, paytableRowNames: rows) == "Four 2-10",
                    "quadRank \(rank) should map to Four 2-10")
        }
    }

    // MARK: Double Jackpot

    @Test func doubleJackpot_acesWithFaceKicker() {
        let rows: Set<String> = ["Four Aces + Face", "Four Aces", "Four K/Q/J + Face", "Four K/Q/J", "Four 2-10"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 13, paytableRowNames: rows) == "Four Aces + Face")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 7, paytableRowNames: rows) == "Four Aces")
    }

    @Test func doubleJackpot_faceWithFaceOrAceKicker() {
        let rows: Set<String> = ["Four Aces + Face", "Four Aces", "Four K/Q/J + Face", "Four K/Q/J", "Four 2-10"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 13, kickerRank: 14, paytableRowNames: rows) == "Four K/Q/J + Face")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 13, kickerRank: 11, paytableRowNames: rows) == "Four K/Q/J + Face")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 13, kickerRank: 7, paytableRowNames: rows) == "Four K/Q/J")
    }

    // MARK: DDB Aces & Faces

    @Test func ddbAcesFaces_allTiers() {
        let rows: Set<String> = ["Four Aces + Face", "Four J-K + A-4", "Four Aces", "Four J-K", "Four 2-10"]
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 11, paytableRowNames: rows) == "Four Aces + Face")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 14, kickerRank: 7, paytableRowNames: rows) == "Four Aces")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 12, kickerRank: 14, paytableRowNames: rows) == "Four J-K + A-4")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 12, kickerRank: 3, paytableRowNames: rows) == "Four J-K + A-4")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 12, kickerRank: 7, paytableRowNames: rows) == "Four J-K")
        #expect(HandEvaluator.resolveQuadHandName(quadRank: 8, kickerRank: 7, paytableRowNames: rows) == "Four 2-10")
    }
}

// MARK: - resolveHighPairInfo Tests

@Suite("HandEvaluator.resolveHighPairInfo")
struct ResolveHighPairInfoTests {

    @Test func jacksOrBetter_returnsCorrectInfo() {
        let rows: Set<String> = ["Four of a Kind", "Full House", "Flush", "Straight",
                                 "Three of a Kind", "Two Pair", "Jacks or Better"]
        let info = HandEvaluator.resolveHighPairInfo(paytableRowNames: rows)
        #expect(info?.name == "Jacks or Better")
        #expect(info?.minRank == 11)
    }

    @Test func tensOrBetter_returnsCorrectInfo() {
        let rows: Set<String> = ["Four of a Kind", "Full House", "Flush", "Straight",
                                 "Three of a Kind", "Two Pair", "Tens or Better"]
        let info = HandEvaluator.resolveHighPairInfo(paytableRowNames: rows)
        #expect(info?.name == "Tens or Better")
        #expect(info?.minRank == 10)
    }

    @Test func tripleBonus_returnsKingsOrBetter() {
        let rows: Set<String> = ["Four Aces", "Four 2-4", "Four 5-K", "Full House", "Flush",
                                 "Straight", "Three of a Kind", "Two Pair", "Kings or Better"]
        let info = HandEvaluator.resolveHighPairInfo(paytableRowNames: rows)
        #expect(info?.name == "Kings or Better")
        #expect(info?.minRank == 13)
    }

    @Test func royalAcesBonus_returnsPairOfAces() {
        let rows: Set<String> = ["Four Aces", "Four 2-4", "Four 5-K", "Full House", "Flush",
                                 "Straight", "Three of a Kind", "Two Pair", "Pair of Aces"]
        let info = HandEvaluator.resolveHighPairInfo(paytableRowNames: rows)
        #expect(info?.name == "Pair of Aces")
        #expect(info?.minRank == 14)
    }

    @Test func deucesWild_returnsNil() {
        let rows: Set<String> = ["Natural Royal", "Four Deuces", "Wild Royal", "Five of a Kind",
                                 "Straight Flush", "Four of a Kind", "Full House", "Flush",
                                 "Straight", "Three of a Kind"]
        #expect(HandEvaluator.resolveHighPairInfo(paytableRowNames: rows) == nil)
    }
}
