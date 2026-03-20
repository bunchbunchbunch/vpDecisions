import Foundation

// MARK: - All 16 Training Lessons for 9/6 Jacks or Better

extension TrainingLesson {
    static let allLessons: [TrainingLesson] = [
        lesson1, lesson2, lesson3, lesson4, lesson5, lesson6, lesson7, lesson8,
        lesson9, lesson10, lesson11, lesson12, lesson13, lesson14, lesson15, lesson16
    ]

    static func lesson(_ number: Int) -> TrainingLesson? {
        allLessons.first { $0.number == number }
    }

    // MARK: - Lesson 1: Dealt Hands That Pay

    static let lesson1 = TrainingLesson(
        number: 1,
        title: "Dealt Hands That Pay",
        keyConcept: "A \"pat\" hand is any dealt hand that already pays. Two Pair and above should almost always be kept intact.",
        whatToLearn: [
            "Recognize all paying hands (Jacks or Better through Royal Flush)",
            "How to keep the cards in the paying hand"
        ],
        commonMistakes: [
            "Not seeing the dealt hand"
        ],
        practiceHands: [
            TrainingPracticeHand(number: 1, cards: ["Jh", "Th", "9h", "8h", "7h"], holdCards: ["Jh", "Th", "9h", "8h", "7h"], explanation: "Straight flush — 5 in a row and suited"),
            TrainingPracticeHand(number: 2, cards: ["Ks", "Kd", "Kh", "7c", "7s"], holdCards: ["Ks", "Kd", "Kh", "7c", "7s"], explanation: "Full house — always keep"),
            TrainingPracticeHand(number: 3, cards: ["Th", "9h", "6h", "3h", "2h"], holdCards: ["Th", "9h", "6h", "3h", "2h"], explanation: "Flush — all the same suit"),
            TrainingPracticeHand(number: 4, cards: ["Ts", "9d", "8c", "7h", "6s"], holdCards: ["Ts", "9d", "8c", "7h", "6s"], explanation: "Straight — 5 in a row"),
            TrainingPracticeHand(number: 5, cards: ["Qh", "Qd", "8s", "8c", "3d"], holdCards: ["Qh", "Qd", "8s", "8c"], explanation: "Two pair — Keep the two pair, throw away the extra card"),
            TrainingPracticeHand(number: 6, cards: ["8s", "8h", "8c", "Ad", "Kd"], holdCards: ["8s", "8h", "8c"], explanation: "Three of a kind — drop the kickers, draw 2")
        ]
    )

    // MARK: - Lesson 2: Pairs

    static let lesson2 = TrainingLesson(
        number: 2,
        title: "Pairs — Your Bread and Butter",
        keyConcept: "Pairs drive the strategy in Jacks or Better. A high pair (JJ, QQ, KK, AA) already pays. A low pair (22–TT) doesn't pay, but it's still better than almost every drawing hand.",
        whatToLearn: [
            "High pair = paying hand. Hold it and draw 3.",
            "Low pair = not paying, but still a strong hold. Keep it over single high cards, inside straight draws, and 3-card flush draws."
        ],
        commonMistakes: [
            "Keeping a \"kicker\" (e.g., holding a King alongside a pair of 5s)",
            "Breaking a low pair to hold two unsuited high cards"
        ],
        practiceHands: [
            TrainingPracticeHand(number: 1, cards: ["Qh", "Qd", "7s", "4c", "2d"], holdCards: ["Qh", "Qd"], explanation: "High pair — it already pays, hold it"),
            TrainingPracticeHand(number: 2, cards: ["6h", "6d", "As", "Kc", "3s"], holdCards: ["6h", "6d"], explanation: "Low pair is better than unsuited AK — this surprises beginners"),
            TrainingPracticeHand(number: 3, cards: ["9s", "9d", "Jh", "Tc", "3c"], holdCards: ["9s", "9d"], explanation: "Low pair — don't be tempted by J or JT"),
            TrainingPracticeHand(number: 4, cards: ["Ks", "Kd", "7h", "3h", "2h"], holdCards: ["Ks", "Kd"], explanation: "High pair is better than 3 to a flush"),
            TrainingPracticeHand(number: 5, cards: ["4c", "4d", "Ah", "Qh", "9c"], holdCards: ["4c", "4d"], explanation: "Low pair is better than AQ unsuited")
        ]
    )

    // MARK: - Lesson 3: The Lone High Card

    static let lesson3 = TrainingLesson(
        number: 3,
        title: "The Lone High Card — Better Than Nothing",
        keyConcept: "When your hand has no pair, no meaningful draw, and only one high card, that lone high card is your best play. Hold it and draw 4 new cards — you have a roughly 1-in-5 chance of pairing it for a Jacks or Better payout.",
        whatToLearn: [
            "A single J, Q, K, or A is always worth holding when nothing better exists",
            "Draw 4 new cards — a fresh draw gives you many chances to improve",
            "Don't keep low cards alongside the high card — they don't help",
            "A Ten is NOT a high card in Jacks or Better (pairing a Ten doesn't pay)"
        ],
        commonMistakes: [
            "Keeping a low card as a \"kicker\" next to the high card",
            "Chasing a 3-card flush draw instead of holding the lone high card",
            "Holding a Ten thinking it's a high card",
            "Discarding everything when you have a lone Jack"
        ],
        practiceHands: [
            TrainingPracticeHand(number: 1, cards: ["Ah", "9c", "7d", "4s", "2h"], holdCards: ["Ah"], explanation: "Lone Ace — keep it, draw 4 new cards"),
            TrainingPracticeHand(number: 2, cards: ["Ks", "8d", "6c", "3h", "2s"], holdCards: ["Ks"], explanation: "Lone King — your only high card, don't keep the garbage"),
            TrainingPracticeHand(number: 3, cards: ["Qd", "9h", "7c", "4s", "2d"], holdCards: ["Qd"], explanation: "Lone Queen — hold it and draw 4"),
            TrainingPracticeHand(number: 4, cards: ["Jh", "8c", "5d", "3s", "2h"], holdCards: ["Jh"], explanation: "Lone Jack — the minimum card that can make a paying pair"),
            TrainingPracticeHand(number: 5, cards: ["Kh", "9h", "7d", "4c", "2s"], holdCards: ["Kh"], explanation: "Lone King — don't be tempted by 2 hearts, that's not a draw"),
            TrainingPracticeHand(number: 6, cards: ["Th", "8d", "6c", "3s", "2h"], holdCards: [], explanation: "A Ten is NOT a high card — pairing it won't pay, discard everything"),
            TrainingPracticeHand(number: 7, cards: ["Ah", "9d", "6d", "3d", "2s"], holdCards: ["Ah"], explanation: "Keep the Ace — don't chase the 3-card flush in diamonds"),
            TrainingPracticeHand(number: 8, cards: ["Qh", "9c", "8d", "6s", "5h"], holdCards: ["Qh"], explanation: "Lone Queen beats the inside straight (9-8-_-6-5)"),
            TrainingPracticeHand(number: 9, cards: ["Js", "7h", "5c", "4d", "2s"], holdCards: ["Js"], explanation: "Lone Jack — it looks like nothing but the Jack gives you a shot"),
            TrainingPracticeHand(number: 10, cards: ["Kd", "8c", "6h", "4s", "2d"], holdCards: ["Kd"], explanation: "Lone King — pure garbage around it, hold the King and draw 4")
        ]
    )

    // MARK: - Lesson 4: Garbage Hands

    static let lesson4 = TrainingLesson(
        number: 4,
        title: "Garbage Hands & Full Strategy Review",
        keyConcept: "Sometimes you're dealt nothing — no pair, no draw, no high cards. Knowing when to throw away all 5 cards is a skill. This lesson also puts everything together.",
        whatToLearn: [
            "If you have nothing useful, discard all 5 and draw fresh",
            "A single high card (J, Q, K, A) is still better than keeping random low cards",
            "Don't keep 3 unsuited low cards hoping for a straight or flush",
            "Review the full holding hierarchy from Lesson 1 through Lesson 3"
        ],
        commonMistakes: [
            "Keeping random suited low cards (e.g., 7h 4h 2h) — 3 to a flush is almost never worth it",
            "Not recognizing true garbage (no pair, no draw, no high cards)",
            "Getting \"attached\" to an almost-hand"
        ],
        practiceHands: [
            TrainingPracticeHand(number: 1, cards: ["8c", "6d", "4h", "3s", "2c"], holdCards: [], explanation: "Pure garbage — discard all 5"),
            TrainingPracticeHand(number: 2, cards: ["9h", "7d", "5c", "3s", "2h"], holdCards: [], explanation: "No pair, no draw, no high card — toss it"),
            TrainingPracticeHand(number: 3, cards: ["Jh", "4d", "3c", "2s", "8h"], holdCards: ["Jh"], explanation: "Lone Jack — better than garbage"),
            TrainingPracticeHand(number: 4, cards: ["Qh", "9h", "7d", "4c", "2s"], holdCards: ["Qh"], explanation: "Lone Queen — only high card in the hand"),
            TrainingPracticeHand(number: 5, cards: ["9d", "7c", "5h", "3s", "2d"], holdCards: [], explanation: "Garbage — fresh 5 cards is the best play")
        ]
    )

    // MARK: - Lesson 5: Unsuited High Card Showdowns

    static let lesson5 = TrainingLesson(
        number: 5,
        title: "Unsuited High Card Showdowns",
        keyConcept: "When you have multiple unsuited high cards and no better draw, which ones you keep matters. The hierarchy is QJ > KJ, KQ > AJ, AQ, AK. With 3 unsuited high cards, keep only the best 2 — and that usually means dropping the Ace or the King.",
        whatToLearn: [
            "QJ is the best unsuited 2-card combo because it participates in the most straights",
            "With AQJ unsuited: hold QJ, drop the A",
            "With AKQ unsuited: hold KQ, drop the A",
            "With AKJ unsuited: hold KJ, drop the A",
            "KQJ is the only 3 high card hand where you keep all 3"
        ],
        commonMistakes: [
            "Keeping AK because \"those are the two highest cards\"",
            "Holding all 3 unsuited high cards (AKQ, AQJ, AKJ) — trim to 2",
            "Thinking the Ace is the most valuable high card (it restricts straight possibilities)"
        ],
        practiceHands: [
            TrainingPracticeHand(number: 1, cards: ["Qs", "Jd", "8c", "5h", "3s"], holdCards: ["Qs", "Jd"], explanation: "QJ unsuited — the best 2-card unsuited combo"),
            TrainingPracticeHand(number: 2, cards: ["As", "Qd", "8c", "5h", "3s"], holdCards: ["As", "Qd"], explanation: "AQ unsuited — weaker than QJ, but still hold both"),
            TrainingPracticeHand(number: 3, cards: ["Ah", "Qd", "Jc", "6s", "3h"], holdCards: ["Qd", "Jc"], explanation: "AQJ unsuited — drop the A, keep QJ"),
            TrainingPracticeHand(number: 4, cards: ["Ac", "Kd", "Qs", "7c", "3h"], holdCards: ["Kd", "Qs"], explanation: "AKQ unsuited — drop the A, keep KQ"),
            TrainingPracticeHand(number: 5, cards: ["Ah", "Kd", "Jc", "6s", "2h"], holdCards: ["Kd", "Jc"], explanation: "AKJ unsuited — drop the A, keep KJ"),
            TrainingPracticeHand(number: 6, cards: ["Ks", "Jd", "8c", "5h", "2s"], holdCards: ["Ks", "Jd"], explanation: "KJ unsuited — solid 2-card hold"),
            TrainingPracticeHand(number: 7, cards: ["As", "Kd", "8c", "5h", "3s"], holdCards: ["As", "Kd"], explanation: "AK unsuited"),
            TrainingPracticeHand(number: 8, cards: ["Ks", "Qd", "9c", "6h", "2s"], holdCards: ["Ks", "Qd"], explanation: "KQ unsuited — weaker than QJ but stronger than AQ"),
            TrainingPracticeHand(number: 9, cards: ["Kh", "Qd", "Js", "7c", "2h"], holdCards: ["Kh", "Qd", "Js"], explanation: "Keep KQJ — This is the one time you keep 3 high cards")
        ]
    )

    // MARK: - Lesson 6: High Card Subtleties

    static let lesson6 = TrainingLesson(
        number: 6,
        title: "High Card Hands — The Subtleties",
        keyConcept: "When you have no pair and no strong draw, the specific high cards you hold matter more than you'd think. Suited is better than unsuited. And counterintuitively, QJ is better than AQ because QJ can participate in more straights.",
        whatToLearn: [
            "Suited high cards (Qh Jh) >> unsuited high cards (Qs Jd) because of flush potential",
            "The 2-card unsuited hierarchy: QJ > KJ, KQ > AJ, AQ, AK",
            "Why: QJ makes straights in 3 positions (AKQJT, KQJT9, QJT98), AK makes only 1 (AKQJT)",
            "Never hold 3 unsuited high cards except for KQJ"
        ],
        commonMistakes: [
            "Keeping AQ over QJ (the Ace restricts straight possibilities)",
            "Holding 3 unsuited high cards (AKQ) instead of the best 2 (KQ)",
            "Not valuing suited high cards enough"
        ],
        practiceHands: [
            TrainingPracticeHand(number: 1, cards: ["Qh", "Jh", "8c", "5d", "3s"], holdCards: ["Qh", "Jh"], explanation: "Suited QJ — best 2-card high card combo"),
            TrainingPracticeHand(number: 2, cards: ["Qs", "Jd", "8c", "5h", "3d"], holdCards: ["Qs", "Jd"], explanation: "Unsuited QJ — still the best unsuited 2-card combo"),
            TrainingPracticeHand(number: 3, cards: ["As", "Kd", "8c", "5h", "3s"], holdCards: ["As", "Kd"], explanation: "AK unsuited"),
            TrainingPracticeHand(number: 4, cards: ["Ah", "Qd", "Jc", "6s", "3h"], holdCards: ["Qd", "Jc"], explanation: "3 unsuited high cards — drop the A, keep QJ"),
            TrainingPracticeHand(number: 5, cards: ["Kh", "Jc", "Qc", "5d", "2s"], holdCards: ["Qc", "Jc"], explanation: "Suited QJ — the suit makes this much stronger"),
            TrainingPracticeHand(number: 6, cards: ["8s", "Jd", "Qc", "Ad", "3d"], holdCards: ["Ad", "Jd"], explanation: "Suited AJ — better than QJ offsuit"),
            TrainingPracticeHand(number: 7, cards: ["Kd", "Qh", "Jd", "6c", "2h"], holdCards: ["Kd", "Jd"], explanation: "Suited KJ — better than QJ offsuit"),
            TrainingPracticeHand(number: 8, cards: ["Kd", "Qh", "Jc", "6c", "2h"], holdCards: ["Kd", "Qh", "Jc"], explanation: "Unsuited KQJ — the only time you hold three high cards"),
            TrainingPracticeHand(number: 9, cards: ["Ah", "Kd", "Qs", "7c", "3d"], holdCards: ["Kd", "Qs"], explanation: "3 high cards — drop the Ace, keep KQ"),
            TrainingPracticeHand(number: 10, cards: ["8s", "Jc", "Kd", "Ad", "3d"], holdCards: ["Ad", "Kd"], explanation: "Suited AK — better than KJ offsuit")
        ]
    )

    // MARK: - Lesson 7: Suited Ten + High Card

    static let lesson7 = TrainingLesson(
        number: 7,
        title: "Suited Ten + High Card — 2 to a Royal with a Ten",
        keyConcept: "When a Ten is suited with a Jack, Queen, or King, the combo becomes a \"2 to a Royal Flush\" draw with flush and straight potential on top. TJ suited is the strongest, TK suited is the weakest. AT suited is NOT a real hold — the Ace alone is always better.",
        whatToLearn: [
            "TJ suited, TQ suited, and TK suited are real holds worth keeping over garbage and lone high cards",
            "The ranking is TJ suited (best) > TQ suited > TK suited",
            "AT suited is NOT a valid hold — just keep the Ace",
            "TJ suited beats KJ unsuited — the suit's power overcomes the extra high card",
            "A low pair always beats any suited T+HC",
            "QJ unsuited beats even TJ suited"
        ],
        commonMistakes: [
            "Holding AT suited instead of just the Ace alone",
            "Breaking TJ suited to hold just the Jack",
            "Keeping KJ unsuited over TJ suited"
        ],
        practiceHands: [
            TrainingPracticeHand(number: 1, cards: ["Th", "Jh", "8c", "5d", "2s"], holdCards: ["Th", "Jh"], explanation: "TJ suited — best of the T+HC group"),
            TrainingPracticeHand(number: 2, cards: ["Th", "Qh", "9c", "6d", "3s"], holdCards: ["Th", "Qh"], explanation: "TQ suited — keep both for Royal, flush, and straight potential"),
            TrainingPracticeHand(number: 3, cards: ["Th", "Kh", "9c", "7d", "4s"], holdCards: ["Th", "Kh"], explanation: "TK suited — weakest of the three but still better than a lone King"),
            TrainingPracticeHand(number: 4, cards: ["Th", "Ah", "9c", "7d", "3s"], holdCards: ["Ah"], explanation: "AT suited is NOT a hold — just keep the Ace"),
            TrainingPracticeHand(number: 5, cards: ["Th", "Jh", "Kd", "6c", "3s"], holdCards: ["Th", "Jh"], explanation: "TJ suited beats KJ unsuited — the suit overcomes the extra high card"),
            TrainingPracticeHand(number: 6, cards: ["Th", "Qh", "Ac", "6d", "5s"], holdCards: ["Th", "Qh"], explanation: "TQ suited beats AQ unsuited — the suit makes TQ stronger"),
            TrainingPracticeHand(number: 7, cards: ["Th", "Jh", "Qc", "6d", "3s"], holdCards: ["Qc", "Jh"], explanation: "QJ unsuited beats TJ suited — QJ is the best unsuited 2-card combo"),
            TrainingPracticeHand(number: 8, cards: ["Th", "Jh", "5d", "5c", "3s"], holdCards: ["5d", "5c"], explanation: "Low pair of 5s beats TJ suited — a pair always wins here"),
            TrainingPracticeHand(number: 9, cards: ["Th", "Kh", "Ad", "3c", "2s"], holdCards: ["Ad", "Kh"], explanation: "AK unsuited beats TK suited — two high cards outweigh the suit"),
            TrainingPracticeHand(number: 10, cards: ["Th", "Qh", "Ks", "3d", "2c"], holdCards: ["Ks", "Qh"], explanation: "KQ unsuited beats TQ suited — K adds more value than the suited Ten")
        ]
    )

    // MARK: - Lesson 8: Straight Draws Level 1

    static let lesson8 = TrainingLesson(
        number: 8,
        title: "Straight Draws — Level 1",
        keyConcept: "Not all straight draws are equal. An open-ended straight draw can be completed on either end (8 outs), while an inside straight draw needs one specific rank (4 outs). Open-ended draws are roughly twice as likely to hit.",
        whatToLearn: [
            "Open-ended straight draw (e.g., 7-8-9-T): Keep it over a high card",
            "Inside straight draw (e.g., 5-6-_-8-9): only 4 cards fill the gap, much weaker. Never keep it with all low cards.",
            "Any pair is better than an open-ended straight draw."
        ],
        commonMistakes: [
            "Treating inside straight draws as valuable (they're usually not)",
            "Breaking a low pair for an inside straight draw",
            "Not recognizing that A-2-3-4 is an inside draw, not open-ended"
        ],
        practiceHands: [
            TrainingPracticeHand(number: 1, cards: ["Jh", "Ts", "9d", "8c", "3h"], holdCards: ["Jh", "Ts", "9d", "8c"], explanation: "Open-ended with a high card — good draw"),
            TrainingPracticeHand(number: 2, cards: ["9h", "8d", "7c", "6s", "Ks"], holdCards: ["9h", "8d", "7c", "6s"], explanation: "Open-ended — the K isn't helping"),
            TrainingPracticeHand(number: 3, cards: ["5h", "5d", "8s", "6c", "7d"], holdCards: ["5h", "5d"], explanation: "Low pair is better than open-ended with no high cards"),
            TrainingPracticeHand(number: 4, cards: ["Jh", "Td", "Js", "8c", "9h"], holdCards: ["Jh", "Js"], explanation: "Keep the high pair"),
            TrainingPracticeHand(number: 5, cards: ["8h", "7d", "5c", "4s", "Kd"], holdCards: ["Kd"], explanation: "Inside draw (8-7-_-5-4) loses to a single high card"),
            TrainingPracticeHand(number: 6, cards: ["6s", "6d", "Jh", "Tc", "9d"], holdCards: ["6s", "6d"], explanation: "Low pair is better than an inside straight draw"),
            TrainingPracticeHand(number: 7, cards: ["Th", "9d", "8c", "6s", "2d"], holdCards: [], explanation: "Never keep an inside straight draw with no high cards"),
            TrainingPracticeHand(number: 8, cards: ["Ah", "2d", "3c", "4s", "9h"], holdCards: ["Ah"], explanation: "A-2-3-4 is an inside draw — just keep the Ace")
        ]
    )

    // MARK: - Lesson 9: Inside Straights with Broadway Cards

    static let lesson9 = TrainingLesson(
        number: 9,
        title: "Straight Draws — Level 2: 4 to Broadway",
        keyConcept: "Normally, inside straight draws are weak. But when all 4 cards are Broadway cards (Ten through Ace), the draw gets extra value: every card can pair up for a paying hand (Jacks or Better), and you're drawing to a straight.",
        whatToLearn: [
            "AKQT, AKJT, AQJT are inside straights with 3+ high cards — keep all 4 unless you have two suited high cards",
            "If you have two suited high cards (not involving the Ten), keep the suited pair instead",
            "AKQJ: Keep all four unless you have suited QJ",
            "These 4-card Broadway holds rank above holding just 2 unsuited high cards"
        ],
        commonMistakes: [
            "Holding only QJ offsuit from AKQJ (the 4-card inside straight is better than 2 high cards)",
            "Treating all inside straights the same — Broadway inside straights are special"
        ],
        practiceHands: [
            TrainingPracticeHand(number: 1, cards: ["As", "Kd", "Qh", "Tc", "6s"], holdCards: ["As", "Kd", "Qh", "Tc"], explanation: "AKQT inside straight — hold all 4 (needs J)"),
            TrainingPracticeHand(number: 2, cards: ["As", "Kd", "Jh", "Tc", "5s"], holdCards: ["As", "Kd", "Jh", "Tc"], explanation: "AKJT inside straight — hold all 4 (needs Q)"),
            TrainingPracticeHand(number: 3, cards: ["Ah", "Qd", "Jc", "Ts", "6h"], holdCards: ["Ah", "Qd", "Jc", "Ts"], explanation: "AQJT inside straight — hold all 4 (needs K)"),
            TrainingPracticeHand(number: 4, cards: ["As", "Kd", "Qs", "Tc", "6s"], holdCards: ["As", "Qs"], explanation: "AQ suited is better than AKQT"),
            TrainingPracticeHand(number: 5, cards: ["As", "Kh", "Jh", "Tc", "5s"], holdCards: ["Kh", "Jh"], explanation: "KJ suited is better than AKJT"),
            TrainingPracticeHand(number: 6, cards: ["Ah", "Qd", "Jc", "Th", "6c"], holdCards: ["Ah", "Qd", "Jc", "Th"], explanation: "AQJT is better than JT suited"),
            TrainingPracticeHand(number: 7, cards: ["As", "Kd", "Qd", "Jc", "2c"], holdCards: ["As", "Kd", "Qd", "Jc"], explanation: "AKQJ is better than KQ suited"),
            TrainingPracticeHand(number: 8, cards: ["As", "Kd", "Qc", "Jc", "5s"], holdCards: ["Qc", "Jc"], explanation: "QJ suited is better than AKQJ")
        ]
    )

    // MARK: - Lesson 10: Other Inside Straights with High Cards

    static let lesson10 = TrainingLesson(
        number: 10,
        title: "Straight Draws — Level 3: Other Inside Straights",
        keyConcept: "Normally, if you have two high cards and an inside straight draw you keep the high cards and don't go for the inside straight, but there is an exception.",
        whatToLearn: [
            "In hands with two high cards and an inside straight like KQT9 or QJT8, just keep the two high cards",
            "If you have 3 high cards and an inside straight draw, keep the inside straight draw (KQJ9)",
        ],
        commonMistakes: [
            "Just keeping KQJ if you have KQJ9",
            "Going for the inside straight draw with hands like QJT8"
        ],
        practiceHands: [
            TrainingPracticeHand(number: 1, cards: ["Kd", "Qh", "Tc", "9h", "6s"], holdCards: ["Kd", "Qh"], explanation: "KQ is better than the inside straight draw"),
            TrainingPracticeHand(number: 2, cards: ["8s", "Jd", "Qh", "Tc", "5s"], holdCards: ["Jd", "Qh"], explanation: "QJ is better than the inside straight draw"),
            TrainingPracticeHand(number: 3, cards: ["9h", "Qd", "Jc", "Ks", "6h"], holdCards: ["9h", "Qd", "Jc", "Ks"], explanation: "KQJ9 is better than KQJ")
        ]
    )

    // MARK: - Lesson 11: The KQJT Exception

    static let lesson11 = TrainingLesson(
        number: 11,
        title: "The KQJT Exception — When an Outside Straight Beats a Pair",
        keyConcept: "Lesson 8 taught that a pair beats an outside straight draw. KQJT is the one exception. With 3 high cards (K, Q, J) that each pay when paired plus 8 straight outs, KQJT beats a pair of Tens. This only matters when the 5th card gives you a pair of Tens.",
        whatToLearn: [
            "KQJT is the only 4-to-outside-straight that beats a low pair",
            "If your hand is KQJTT (pair of tens + KQJT straight), break the pair and hold KQJT",
            "If your hand has a high pair (JJ, QQ, or KK), keep the high pair",
            "If 3 of the KQJT cards are suited, check for 3-to-a-Royal first"
        ],
        commonMistakes: [
            "Keeping a pair of Tens over KQJT",
            "Breaking a high pair of Jacks/Queens/Kings for the KQJT straight",
            "Missing a 3-to-Royal hiding inside the hand"
        ],
        practiceHands: [
            TrainingPracticeHand(number: 1, cards: ["Th", "Td", "Jc", "Qd", "Ks"], holdCards: ["Td", "Jc", "Qd", "Ks"], explanation: "KQJT beats pair of Tens — the one exception to \"pairs beat straights\""),
            TrainingPracticeHand(number: 2, cards: ["Ts", "Tc", "Jd", "Qh", "Kc"], holdCards: ["Tc", "Jd", "Qh", "Kc"], explanation: "Same concept — break the Tens for the KQJT draw"),
            TrainingPracticeHand(number: 3, cards: ["Jh", "Jd", "Kc", "Qs", "Ts"], holdCards: ["Jh", "Jd"], explanation: "High pair of Jacks beats KQJT — high pairs always win"),
            TrainingPracticeHand(number: 4, cards: ["Qh", "Qd", "Kc", "Js", "Ts"], holdCards: ["Qh", "Qd"], explanation: "High pair of Queens beats KQJT"),
            TrainingPracticeHand(number: 5, cards: ["Kh", "Kd", "Qc", "Jd", "Ts"], holdCards: ["Kh", "Kd"], explanation: "High pair of Kings beats KQJT")
        ]
    )

    // MARK: - Lesson 12: The 4-Card Flush

    static let lesson12 = TrainingLesson(
        number: 12,
        title: "The 4-Card Flush — A Powerful Draw",
        keyConcept: "Four cards to a flush is one of the strongest drawing hands in the game. You have roughly a 1-in-5 chance of completing it (9 remaining suited cards out of 47). A 4-flush is better than a low pair but not a high pair.",
        whatToLearn: [
            "4 to a flush is better than low pair: keep flush draw",
            "A high pair is better than 4 to a flush: keep high pair (JJ+)"
        ],
        commonMistakes: [
            "Keeping a low pair instead of drawing to the 4-flush",
            "Keeping two off-suit high cards instead of the 4-flush",
            "Breaking a high pair for a 4-flush (the high pair is better)"
        ],
        practiceHands: [
            TrainingPracticeHand(number: 1, cards: ["Ah", "9h", "6h", "3h", "Kc"], holdCards: ["Ah", "9h", "6h", "3h"], explanation: "4 to a flush — discard the off-suit King"),
            TrainingPracticeHand(number: 2, cards: ["8h", "5h", "3h", "2h", "8d"], holdCards: ["8h", "5h", "3h", "2h"], explanation: "4 to a flush is better than the pair of 8s"),
            TrainingPracticeHand(number: 3, cards: ["Qh", "9h", "7h", "4h", "Ks"], holdCards: ["Qh", "9h", "7h", "4h"], explanation: "4 to a flush is better than the off-suit KQ"),
            TrainingPracticeHand(number: 4, cards: ["Kh", "Th", "6h", "2h", "Qs"], holdCards: ["Kh", "Th", "6h", "2h"], explanation: "4 flush is better than a single high card (Q)"),
            TrainingPracticeHand(number: 5, cards: ["Jh", "8h", "4h", "2h", "5c"], holdCards: ["Jh", "8h", "4h", "2h"], explanation: "4 to a flush — even though J is high, the flush draw is much better"),
            TrainingPracticeHand(number: 6, cards: ["Qh", "Qd", "8h", "5h", "3h"], holdCards: ["Qh", "Qd"], explanation: "High pair Queens is better than 4 to a flush"),
            TrainingPracticeHand(number: 7, cards: ["Ts", "6s", "4s", "2s", "6d"], holdCards: ["Ts", "6s", "4s", "2s"], explanation: "4 to a flush is better than a low pair of 6s"),
            TrainingPracticeHand(number: 8, cards: ["Jd", "Jh", "9h", "7h", "4h"], holdCards: ["Jd", "Jh"], explanation: "High pair of Jacks is better than 4 to a flush")
        ]
    )

    // MARK: - Lesson 13: Three to a Royal

    static let lesson13 = TrainingLesson(
        number: 13,
        title: "Three to a Royal — When to Break Good Hands",
        keyConcept: "Three to a Royal Flush (3 cards T-or-higher of the same suit) is so powerful that it's correct to break a low pair and 4 to a straight. However, a high pair is better than 3 to the royal.",
        whatToLearn: [
            "3 to a Royal = 3 cards Ten-or-higher, all the same suit (e.g., Kh Qh Th)",
            "3 to a Royal is better than: 4 to a flush, 4 to a straight",
            "3 to a Royal is not as good as: two pair, trips, 4 to a straight flush",
            "You're not just chasing the Royal — on the redraw you can also hit a flush, straight, or pair"
        ],
        commonMistakes: [
            "Keeping a low pair instead of 3 to a Royal",
            "Confusing 3 to a Royal (very strong) with 3 to a straight flush (much weaker)"
        ],
        practiceHands: [
            TrainingPracticeHand(number: 1, cards: ["Ah", "Kh", "Qh", "7d", "3c"], holdCards: ["Ah", "Kh", "Qh"], explanation: "3 to a Royal — much better than 2 high cards"),
            TrainingPracticeHand(number: 2, cards: ["Kh", "Kd", "Kc", "Qh", "Jh"], holdCards: ["Kh", "Kd", "Kc"], explanation: "Trips are better than 3 to a Royal — keep the three Kings"),
            TrainingPracticeHand(number: 3, cards: ["Ah", "Kh", "Th", "9d", "4c"], holdCards: ["Ah", "Kh", "Th"], explanation: "3 to a Royal — discard the garbage"),
            TrainingPracticeHand(number: 4, cards: ["Qh", "Jh", "Th", "8c", "5d"], holdCards: ["Qh", "Jh", "Th"], explanation: "3 to a Royal — straightforward"),
            TrainingPracticeHand(number: 5, cards: ["Ks", "Qh", "Js", "Ts", "4h"], holdCards: ["Ks", "Js", "Ts"], explanation: "3 to a Royal in spades — don't keep the open-ended straight draw"),
            TrainingPracticeHand(number: 6, cards: ["Ah", "Kh", "Th", "9h", "3c"], holdCards: ["Ah", "Kh", "Th"], explanation: "3 to a Royal is better than 4 to a flush — yes, drop the 9h"),
            TrainingPracticeHand(number: 7, cards: ["Jh", "Tc", "Qh", "Th", "6d"], holdCards: ["Qh", "Jh", "Th"], explanation: "Break the pair of Tens for 3 to a Royal"),
            TrainingPracticeHand(number: 8, cards: ["Kh", "Qh", "Th", "8s", "8d"], holdCards: ["Kh", "Qh", "Th"], explanation: "3 to a Royal is better than a low pair of 8s"),
            TrainingPracticeHand(number: 9, cards: ["Kh", "Qh", "Th", "9h", "8d"], holdCards: ["Kh", "Qh", "Th", "9h"], explanation: "4 to a Straight Flush is better than 3 to a Royal")
        ]
    )

    // MARK: - Lesson 14: SF Type 3 (Weakest)

    static let lesson14 = TrainingLesson(
        number: 14,
        title: "Three to a Straight Flush — The Barely-There Draw (Type 3)",
        keyConcept: "A high card is J, Q, K, or A — the cards that pay when paired. A gap is a missing rank between your held cards (e.g., 8-9-J has 1 gap; 7-9-J has 2 gaps). Type 3 is the weakest straight flush draw: 3 suited cards with 2 gaps and 0 high cards (e.g., 3-5-7s, 4-6-8s). It barely beats throwing everything away.",
        whatToLearn: [
            "Type 3 = 3 suited cards with 2 gaps and no high cards (e.g., 3h 5h 7h, 4s 6s 8s)",
            "Type 3 beats: garbage only — it's the last thing you'd hold before discarding all 5",
            "Type 3 loses to: every single high card (J, Q, K, A)"
        ],
        commonMistakes: [
            "Holding a type 3 draw over a lone Jack, Queen, King, or Ace",
            "Thinking \"3 suited cards\" must be good — type 3 is barely better than nothing"
        ],
        practiceHands: [
            TrainingPracticeHand(number: 1, cards: ["3h", "5h", "7h", "9d", "2s"], holdCards: ["3h", "5h", "7h"], explanation: "Type 3 with pure garbage — barely better than discarding all 5"),
            TrainingPracticeHand(number: 2, cards: ["4h", "6h", "8h", "9d", "2s"], holdCards: ["4h", "6h", "8h"], explanation: "Type 3 — hold the SF draw over nothing"),
            TrainingPracticeHand(number: 3, cards: ["3h", "5h", "7h", "8d", "Jd"], holdCards: ["Jd"], explanation: "Lone Jack beats type 3 — any high card is better"),
            TrainingPracticeHand(number: 4, cards: ["4h", "6h", "8h", "Ad", "3s"], holdCards: ["Ad"], explanation: "Lone Ace beats type 3")
        ]
    )

    // MARK: - Lesson 15: SF Type 2 (Middle)

    static let lesson15 = TrainingLesson(
        number: 15,
        title: "Three to a Straight Flush — The Middle Draw (Type 2)",
        keyConcept: "Type 2 is the middle-strength straight flush draw. It covers: 1 gap with 0 high cards (e.g., 6-7-9s), 2 gaps with 1 high card (e.g., 7-9-Js), or ace-low (e.g., A-3-5s). These beat lone high cards and unsuited combos, but lose to suited high card pairs.",
        whatToLearn: [
            "Type 2 = 1 gap/0 high, 2 gaps/1 high, or ace-low suited",
            "Type 2 beats: unsuited JQK, unsuited JQ, suited TJ, suited TQ, lone J/Q/K/A",
            "Type 2 loses to: Any two suited high cards"
        ],
        commonMistakes: [
            "Confusing Type 2 with Type 1 — the gap/high-card balance matters",
            "Holding suited TJ over a Type 2 draw — Type 2 is surprisingly stronger",
            "Breaking a Type 2 draw for a single unsuited high card — the SF draw wins"
        ],
        practiceHands: [
            TrainingPracticeHand(number: 1, cards: ["6h", "7h", "9h", "4d", "2s"], holdCards: ["6h", "7h", "9h"], explanation: "Type 2: 1 gap, 0 high cards — basic hold"),
            TrainingPracticeHand(number: 2, cards: ["7h", "9h", "Jh", "5d", "2s"], holdCards: ["7h", "9h", "Jh"], explanation: "Type 2: 2 gaps, 1 high card"),
            TrainingPracticeHand(number: 3, cards: ["6h", "7h", "9h", "Jd", "Qc"], holdCards: ["6h", "7h", "9h"], explanation: "Type 2 beats unsuited JQ — the SF draw wins"),
            TrainingPracticeHand(number: 4, cards: ["6h", "7h", "9h", "Ts", "Js"], holdCards: ["6h", "7h", "9h"], explanation: "Type 2 beats suited TJ"),
            TrainingPracticeHand(number: 5, cards: ["5s", "6s", "8s", "Ah", "Kh"], holdCards: ["Ah", "Kh"], explanation: "Suited AK beats type 2 — the high cards outweigh the SF draw"),
            TrainingPracticeHand(number: 6, cards: ["7h", "9h", "Jh", "Ks", "Qd"], holdCards: ["7h", "9h", "Jh"], explanation: "Type 2 beats KQ unsuited and KQJ9 straight draw")
        ]
    )

    // MARK: - Lesson 16: SF Type 1 (Strongest)

    static let lesson16 = TrainingLesson(
        number: 16,
        title: "Three to a Straight Flush — The Strong Draw (Type 1)",
        keyConcept: "Type 1 is the strongest 3-to-a-straight-flush draw. The rule: high cards >= gaps. Consecutive suited cards (0 gaps) always qualify. One-gap hands need at least 1 high card (e.g., 8-9-Js). These are surprisingly powerful draws that beat most 2-card suited holdings, including suited AK.",
        whatToLearn: [
            "Type 1 = 3 suited cards where high card count >= gap count",
            "Consecutive suited cards (e.g., 7-8-9) are always type 1",
            "1-gap hands need at least 1 high card (e.g., 8-9-J suited)",
            "Beats: suited QJ, suited KQ/KJ, suited AK/AQ/AJ",
            "Loses to: 4-to-outside straight, low pair, 4-to-flush, and everything above"
        ],
        commonMistakes: [
            "Holding suited QJ instead of the 3-to-SF type 1",
            "Not recognizing that low consecutive suited cards (5-6-7) are still strong type 1 draws",
            "Breaking the 3-to-SF to hold a lone high card"
        ],
        practiceHands: [
            TrainingPracticeHand(number: 1, cards: ["7h", "8h", "9h", "4d", "2s"], holdCards: ["7h", "8h", "9h"], explanation: "Consecutive suited — basic 3-to-SF type 1"),
            TrainingPracticeHand(number: 2, cards: ["9h", "Jh", "Qh", "5d", "2s"], holdCards: ["9h", "Jh", "Qh"], explanation: "Strongest type 1 — 1 gap, 2 high cards"),
            TrainingPracticeHand(number: 3, cards: ["8h", "9h", "Jh", "4d", "2s"], holdCards: ["8h", "9h", "Jh"], explanation: "1 gap, 1 high — still type 1"),
            TrainingPracticeHand(number: 4, cards: ["5h", "6h", "7h", "4d", "2s"], holdCards: ["5h", "6h", "7h", "4d"], explanation: "Open-ended Straight Draw is better than Type 1 Straight Flush Draw"),
            TrainingPracticeHand(number: 5, cards: ["8h", "Jh", "Qh", "5d", "2s"], holdCards: ["8h", "Jh", "Qh"], explanation: "3-to-SF type 1 beats just holding QJ suited"),
            TrainingPracticeHand(number: 6, cards: ["7h", "8h", "9h", "Qs", "Ks"], holdCards: ["7h", "8h", "9h"], explanation: "Type 1 beats suited KQ — surprising but verified"),
            TrainingPracticeHand(number: 7, cards: ["7h", "8h", "9h", "Qs", "Js"], holdCards: ["7h", "8h", "9h"], explanation: "Type 1 beats suited QJ — the SF draw is much stronger"),
            TrainingPracticeHand(number: 8, cards: ["5h", "5d", "7s", "8s", "9s"], holdCards: ["5h", "5d"], explanation: "Low pair still beats type 1 — pairs are bread and butter"),
            TrainingPracticeHand(number: 9, cards: ["9h", "Th", "Jh", "Qd", "3s"], holdCards: ["9h", "Th", "Jh", "Qd"], explanation: "4-to-outside straight beats the 3-to-SF — add the off-suit Q"),
            TrainingPracticeHand(number: 10, cards: ["7h", "8h", "9h", "3h", "Kd"], holdCards: ["7h", "8h", "9h", "3h"], explanation: "4-to-flush beats 3-to-SF — take the extra flush card")
        ]
    )
}
