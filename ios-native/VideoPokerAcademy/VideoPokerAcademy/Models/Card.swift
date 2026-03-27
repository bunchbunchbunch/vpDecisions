import SwiftUI

enum Suit: String, CaseIterable, Codable {
    case hearts = "hearts"
    case diamonds = "diamonds"
    case clubs = "clubs"
    case spades = "spades"

    var symbol: String {
        switch self {
        case .hearts: return "♥"
        case .diamonds: return "♦"
        case .clubs: return "♣"
        case .spades: return "♠"
        }
    }

    var color: Color {
        switch self {
        case .hearts, .diamonds: return Color(hex: "e74c3c")
        case .clubs, .spades: return .white
        }
    }

    /// Adaptive color for text display - black suits always show as white
    func textColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .hearts, .diamonds: return Color(hex: "e74c3c")
        case .clubs, .spades: return .white
        }
    }

    var code: String {
        switch self {
        case .hearts: return "H"
        case .diamonds: return "D"
        case .clubs: return "C"
        case .spades: return "S"
        }
    }
}

enum Rank: Int, Codable, Comparable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack = 11, queen, king, ace
    case joker = 15

    // Manual CaseIterable conformance excluding joker
    static var allCases: [Rank] {
        [.two, .three, .four, .five, .six, .seven, .eight, .nine, .ten,
         .jack, .queen, .king, .ace]
    }

    var display: String {
        switch self {
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .ten: return "T"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        case .ace: return "A"
        case .joker: return "W"
        }
    }

    var fullName: String {
        switch self {
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .ten: return "10"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        case .ace: return "A"
        case .joker: return "Wild"
        }
    }

    static func < (lhs: Rank, rhs: Rank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct Card: Identifiable, Equatable, Hashable {
    let id = UUID()
    let rank: Rank
    let suit: Suit

    var imageName: String {
        if rank == .joker { return "1J" }
        return "\(rank.display)\(suit.code)"
    }

    var displayText: String {
        if rank == .joker { return "Wild" }
        return "\(rank.fullName)\(suit.symbol)"
    }

    static func createDeck() -> [Card] {
        var deck: [Card] = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.append(Card(rank: rank, suit: suit))
            }
        }
        return deck
    }

    static func shuffledDeck() -> [Card] {
        createDeck().shuffled()
    }

    static func shuffledDeck(jokerCount: Int) -> [Card] {
        var deck = createDeck()
        for _ in 0..<jokerCount {
            deck.append(Card(rank: .joker, suit: .hearts))
        }
        return deck.shuffled()
    }

    /// Parse a card string like "Ah", "Kc", "Td", "6h" into a Card.
    /// Format: rank character(s) + single lowercase suit character.
    static func from(string: String) -> Card? {
        guard string.count >= 2 else { return nil }
        let suitChar = String(string.suffix(1))
        let rankStr = String(string.dropLast())

        let suit: Suit
        switch suitChar {
        case "h": suit = .hearts
        case "d": suit = .diamonds
        case "c": suit = .clubs
        case "s": suit = .spades
        default: return nil
        }

        let rank: Rank
        switch rankStr.uppercased() {
        case "2": rank = .two
        case "3": rank = .three
        case "4": rank = .four
        case "5": rank = .five
        case "6": rank = .six
        case "7": rank = .seven
        case "8": rank = .eight
        case "9": rank = .nine
        case "T", "10": rank = .ten
        case "J": rank = .jack
        case "Q": rank = .queen
        case "K": rank = .king
        case "A": rank = .ace
        default: return nil
        }

        return Card(rank: rank, suit: suit)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
