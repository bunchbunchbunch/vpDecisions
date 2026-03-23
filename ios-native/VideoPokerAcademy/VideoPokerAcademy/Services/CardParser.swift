import Foundation

enum ParseError: LocalizedError {
    case insufficientCards(found: Int)

    var errorDescription: String? {
        switch self {
        case .insufficientCards(let found):
            return "I only caught \(found) card\(found == 1 ? "" : "s") — try again."
        }
    }
}

struct CardParser {

    static let rankWords: [String: Rank] = [
        "two": .two, "three": .three, "four": .four,
        "five": .five, "six": .six, "seven": .seven,
        "eight": .eight, "nine": .nine, "ten": .ten,
        "jack": .jack, "queen": .queen, "king": .king, "ace": .ace
    ]

    static let suitWords: [String: Suit] = [
        "hearts": .hearts, "diamonds": .diamonds,
        "clubs": .clubs, "spades": .spades
    ]

    static func normalize(_ word: String) -> String {
        // Strip punctuation (SFSpeechRecognizer adds commas, periods between cards)
        let cleaned = word
            .replacingOccurrences(of: "'s", with: "")
            .trimmingCharacters(in: .punctuationCharacters)
        switch cleaned {
        case "to", "too":                    return "two"
        case "2":                            return "two"
        case "3":                            return "three"
        case "for", "4":                     return "four"
        case "5":                            return "five"
        case "6":                            return "six"
        case "7":                            return "seven"
        case "8":                            return "eight"
        case "9":                            return "nine"
        case "10", "tin", "than", "tan":     return "ten"
        case "heart":                        return "hearts"
        case "diamond":                      return "diamonds"
        case "club":                         return "clubs"
        case "spade":                        return "spades"
        case "jacks":                        return "jack"
        case "queens":                       return "queen"
        case "kings":                        return "king"
        case "aces":                         return "ace"
        default:                             return cleaned
        }
    }

    static func parse(_ transcript: String, gameFamily: GameFamily) throws -> [Card] {
        // gameFamily accepted for future extensions; wild card detection is StrategyService's responsibility
        let words = transcript
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        print("[CardParser] RAW TRANSCRIPT: \"\(transcript)\"")
        print("[CardParser] TOKENS (\(words.count)): \(words)")

        var cards: [Card] = []
        var i = 0

        while i < words.count {
            let raw = words[i]
            let word = normalize(raw)
            if let rank = rankWords[word] {
                // Found a rank — check "of" + suit
                if i + 2 < words.count {
                    let ofWord = normalize(words[i + 1])
                    let suitRaw = words[i + 2]
                    let suitWord = normalize(suitRaw)
                    if ofWord == "of" {
                        if let suit = suitWords[suitWord] {
                            print("[CardParser] ✅ Card: \(rank) of \(suit)  (tokens: \"\(raw)\" \"\(words[i+1])\" \"\(suitRaw)\")")
                            cards.append(Card(rank: rank, suit: suit))
                            i += 3
                        } else {
                            print("[CardParser] ❌ Rank '\(word)' found but suit '\(suitRaw)' → normalized '\(suitWord)' not recognized")
                            i += 1
                        }
                    } else {
                        print("[CardParser] ❌ Rank '\(word)' found but next token '\(words[i+1])' → normalized '\(ofWord)' is not 'of'")
                        i += 1
                    }
                } else {
                    print("[CardParser] ❌ Rank '\(word)' found at end of tokens, not enough remaining for 'of <suit>'")
                    i += 1
                }
            } else {
                print("[CardParser] ⬜ Token '\(raw)' → normalized '\(word)' — not a rank, skipping")
                i += 1
            }
        }

        print("[CardParser] RESULT: found \(cards.count) card(s)")
        guard cards.count >= 5 else {
            throw ParseError.insufficientCards(found: cards.count)
        }
        return Array(cards.prefix(5))
    }
}
