import Testing
import Foundation
@testable import VideoPokerAcademy

@Suite("UltimateX Play Mode Tests")
struct UltimateXPlayModeTests {

    // MARK: - PlayVariant

    @Test("PlayVariant.standard has coinsPerLine = 5")
    func testStandardCoinsPerLine() {
        let variant = PlayVariant.standard
        #expect(variant.coinsPerLine == 5)
    }

    @Test("PlayVariant.ultimateX has coinsPerLine = 10")
    func testUltimateXCoinsPerLine() {
        let variant = PlayVariant.ultimateX
        #expect(variant.coinsPerLine == 10)
    }

    // MARK: - PlaySettings

    @Test("PlaySettings effectiveLineCount uses lineCount for standard")
    func testEffectiveLineCountStandard() {
        var settings = PlaySettings()
        settings.variant = .standard
        settings.lineCount = .three
        #expect(settings.effectiveLineCount == 3)
    }

    @Test("PlaySettings effectiveLineCount: UX same as lineCount")
    func testEffectiveLineCountUX() {
        var settings = PlaySettings()
        settings.variant = .ultimateX
        settings.lineCount = .ten
        #expect(settings.effectiveLineCount == 10)
    }

    @Test("PlaySettings totalBetCredits: standard 3-line = 15")
    func testTotalBetCreditsStandard() {
        var settings = PlaySettings()
        settings.variant = .standard
        settings.lineCount = .three
        #expect(settings.totalBetCredits == 15)  // 3 lines × 5 coins
    }

    @Test("PlaySettings totalBetCredits: UX 3-line = 30")
    func testTotalBetCreditsUX3Play() {
        var settings = PlaySettings()
        settings.variant = .ultimateX
        settings.lineCount = .three
        #expect(settings.totalBetCredits == 30)  // 3 lines × 10 coins
    }

    @Test("PlaySettings statsPaytableKey includes variant suffix")
    func testStatsPaytableKey() {
        var settings = PlaySettings()
        settings.selectedPaytableId = "jacks-or-better-9-6"
        settings.variant = .ultimateX
        settings.lineCount = .three
        #expect(settings.statsPaytableKey == "jacks-or-better-9-6-ux-3play")
    }

    @Test("PlaySettings statsPaytableKey for standard has no suffix")
    func testStatsPaytableKeyStandard() {
        var settings = PlaySettings()
        settings.selectedPaytableId = "jacks-or-better-9-6"
        settings.variant = .standard
        #expect(settings.statsPaytableKey == "jacks-or-better-9-6")
    }

    // MARK: - Codable

    @Test("PlaySettings with UX variant round-trips through Codable")
    func testPlaySettingsCodable() throws {
        var settings = PlaySettings()
        settings.variant = .ultimateX
        settings.selectedPaytableId = "jacks-or-better-9-6"

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(PlaySettings.self, from: data)
        #expect(decoded.variant == .ultimateX)
        #expect(decoded.selectedPaytableId == "jacks-or-better-9-6")
    }

    @Test("PlaySettings decodes from JSON without variant key (backward compat)")
    func testPlaySettingsBackwardCompat() throws {
        // Simulate existing saved settings that have no 'variant' key
        let json = """
        {
            "denomination": 1.0,
            "lineCount": 1,
            "showOptimalFeedback": true,
            "selectedPaytableId": "jacks-or-better-9-6"
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(PlaySettings.self, from: json)
        #expect(decoded.variant == .standard)
    }

    // MARK: - Multiplier Table

    @Test("Multiplier table returns 12 for full house in JoB 3-play")
    func testMultiplierFullHouseJoB3Play() {
        let m = UltimateXMultiplierTable.multiplier(
            for: "full house",
            playCount: .three,
            family: .jacksOrBetter
        )
        #expect(m == 12)
    }

    @Test("Multiplier table returns 1 for no-win")
    func testMultiplierNoWin() {
        let m = UltimateXMultiplierTable.multiplier(
            for: "no win",
            playCount: .three,
            family: .jacksOrBetter
        )
        #expect(m == 1)
    }

    @Test("Multiplier table returns 1 for unknown hand name")
    func testMultiplierUnknownHand() {
        let m = UltimateXMultiplierTable.multiplier(
            for: "",
            playCount: .three,
            family: .jacksOrBetter
        )
        #expect(m == 1)
    }

    // MARK: - effectiveUXPlayCount

    @Test("effectiveUXPlayCount: 1-line maps to .three")
    func testUXPlayCountOne() {
        var s = PlaySettings(); s.variant = .ultimateX; s.lineCount = .one
        #expect(s.effectiveUXPlayCount == .three)
    }

    @Test("effectiveUXPlayCount: 100-line maps to .ten")
    func testUXPlayCountHundred() {
        var s = PlaySettings(); s.variant = .ultimateX; s.lineCount = .oneHundred
        #expect(s.effectiveUXPlayCount == .ten)
    }

    // MARK: - PlayHandResult

    @Test("PlayHandResult defaults multipliers to 1")
    func testHandResultDefaults() {
        let r = PlayHandResult(lineNumber: 1, finalHand: [], handName: nil, payout: 0, winningIndices: [])
        #expect(r.appliedMultiplier == 1)
        #expect(r.earnedMultiplier == 1)
    }

    @Test("PlaySettings.statsPaytableKey: UX 5-line")
    func testStatsKeyUX5Line() {
        var s = PlaySettings(); s.variant = .ultimateX; s.selectedPaytableId = "job-9-6"; s.lineCount = .five
        #expect(s.statsPaytableKey == "job-9-6-ux-5play")
    }
}
