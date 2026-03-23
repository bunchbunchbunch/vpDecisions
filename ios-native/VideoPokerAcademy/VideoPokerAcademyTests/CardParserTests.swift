import Testing
@testable import VideoPokerAcademy

struct CardParserTests {

    // MARK: - Basic Parsing

    @Test("parses a full five-card hand")
    func testParsesFiveCards() throws {
        let t = "ace of spades king of hearts queen of diamonds jack of clubs ten of spades"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards.count == 5)
        #expect(cards[0].rank == .ace   && cards[0].suit == .spades)
        #expect(cards[1].rank == .king  && cards[1].suit == .hearts)
        #expect(cards[2].rank == .queen && cards[2].suit == .diamonds)
        #expect(cards[3].rank == .jack  && cards[3].suit == .clubs)
        #expect(cards[4].rank == .ten   && cards[4].suit == .spades)
    }

    @Test("parses numeric ranks two through six")
    func testNumericRanks() throws {
        let t = "two of hearts three of diamonds four of clubs five of spades six of hearts"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards.map(\.rank) == [.two, .three, .four, .five, .six])
    }

    @Test("parses seven through nine")
    func testMidRanks() throws {
        let t = "seven of clubs eight of hearts nine of spades two of diamonds three of clubs"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards[0].rank == .seven)
        #expect(cards[1].rank == .eight)
        #expect(cards[2].rank == .nine)
    }

    @Test("throws insufficientCards when fewer than 5 recognized")
    func testThrowsOnPartialHand() {
        let t = "ace of spades king of hearts"
        #expect(throws: ParseError.self) {
            try CardParser.parse(t, gameFamily: .jacksOrBetter)
        }
    }

    @Test("error includes count of found cards")
    func testErrorCount() {
        let t = "ace of spades king of hearts queen of diamonds"
        do {
            _ = try CardParser.parse(t, gameFamily: .jacksOrBetter)
            Issue.record("Expected throw")
        } catch ParseError.insufficientCards(let found) {
            #expect(found == 3)
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    // MARK: - Fuzzy Normalization

    @Test("normalizes 'to' to two")
    func testNormalizesTo() throws {
        let t = "to of hearts king of spades queen of clubs jack of diamonds ten of hearts"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards[0].rank == .two)
    }

    @Test("normalizes 'too' to two")
    func testNormalizesToo() throws {
        let t = "too of clubs ace of spades king of hearts queen of diamonds jack of clubs"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards[0].rank == .two)
    }

    @Test("normalizes 'for' to four")
    func testNormalizesFor() throws {
        let t = "for of diamonds ace of spades king of hearts queen of clubs jack of spades"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards[0].rank == .four)
    }

    @Test("normalizes 'tin' to ten")
    func testNormalizesTin() throws {
        let t = "tin of spades ace of hearts king of clubs queen of diamonds jack of spades"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards[0].rank == .ten)
    }

    @Test("normalizes possessive jack's to jack")
    func testNormalizesPossessive() throws {
        let t = "jack's of clubs ace of spades king of hearts queen of diamonds ten of clubs"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards[0].rank == .jack)
    }

    @Test("normalizes singular suit names to plural")
    func testNormalizesSingularSuits() throws {
        let t = "ace of spade king of heart queen of diamond jack of club ten of spade"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards[0].suit == .spades)
        #expect(cards[1].suit == .hearts)
        #expect(cards[2].suit == .diamonds)
        #expect(cards[3].suit == .clubs)
    }

    // MARK: - Wild Card Games

    @Test("two of clubs parsed as normal Card in wild game — wild logic is StrategyService's job")
    func testWildCardParsedNormally() throws {
        let t = "two of clubs ace of spades king of hearts queen of diamonds jack of clubs"
        let cards = try CardParser.parse(t, gameFamily: .deucesWild)
        #expect(cards[0].rank == .two && cards[0].suit == .clubs)
    }

    // MARK: - Punctuation stripping (SFSpeechRecognizer adds commas/periods)

    @Test("strips trailing commas from suit words")
    func testStripsCommasFromSuits() throws {
        let t = "ace of spades, king of hearts, queen of diamonds, jack of clubs, ten of spades"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards.count == 5)
        #expect(cards[0].rank == .ace  && cards[0].suit == .spades)
        #expect(cards[1].rank == .king && cards[1].suit == .hearts)
    }

    @Test("strips trailing periods")
    func testStripsPeriods() throws {
        let t = "ace of spades. king of hearts. queen of diamonds. jack of clubs. ten of spades."
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards.count == 5)
    }

    // MARK: - Digit rank forms

    @Test("parses digit '2' as two")
    func testDigitTwo() throws {
        let t = "2 of hearts king of spades queen of clubs jack of diamonds ten of hearts"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards[0].rank == .two)
    }

    @Test("parses digits 3 through 9")
    func testDigits3Through9() throws {
        let t = "3 of hearts 4 of spades 5 of clubs 6 of diamonds 7 of hearts"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards.map(\.rank) == [.three, .four, .five, .six, .seven])
    }

    @Test("parses digit '10' as ten")
    func testDigitTen() throws {
        let t = "10 of spades ace of hearts king of clubs queen of diamonds jack of spades"
        let cards = try CardParser.parse(t, gameFamily: .jacksOrBetter)
        #expect(cards[0].rank == .ten)
    }
}
