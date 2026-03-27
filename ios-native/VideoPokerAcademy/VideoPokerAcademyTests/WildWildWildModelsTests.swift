import Testing
@testable import VideoPokerAcademy

struct WildWildWildModelsTests {
    @Test func distributionProbabilitiesSumToOne() {
        for family in GameFamily.allCases {
            let probs = WildWildWildDistribution.probabilities(for: family)
            #expect(probs.count == 4)
            let sum = probs.reduce(0, +)
            #expect(abs(sum - 1.0) < 0.01, "Probabilities for \(family) sum to \(sum)")
        }
    }

    @Test func sampleWildCountInRange() {
        for _ in 0..<100 {
            let count = WildWildWildDistribution.sampleWildCount(for: .jacksOrBetter)
            #expect(count >= 0 && count <= 3)
        }
    }

    @Test func strategyIdFormat() {
        #expect(WildWildWildDistribution.wwwStrategyId(baseId: "jacks-or-better-9-6", wildCount: 0) == "www-jacks-or-better-9-6-0w")
        #expect(WildWildWildDistribution.wwwStrategyId(baseId: "jacks-or-better-9-6", wildCount: 2) == "www-jacks-or-better-9-6-2w")
    }

    @Test func wwwVariantCoinsPerLine() {
        #expect(PlayVariant.wildWildWild.coinsPerLine == 10)
    }

    @Test func wwwVariantDisplayName() {
        #expect(PlayVariant.wildWildWild.displayName == "Wild³")
    }

    @Test func wwwSettingsEffectiveLineCount() {
        var settings = PlaySettings()
        settings.variant = .wildWildWild
        settings.lineCount = .five
        #expect(settings.effectiveLineCount == 5)
    }

    @Test func wwwSettingsTotalBetIs10xLines() {
        var settings = PlaySettings()
        settings.variant = .wildWildWild
        settings.lineCount = .three
        #expect(settings.totalBetCredits == 30)
    }

    @Test func wwwStatsKey() {
        var settings = PlaySettings()
        settings.variant = .wildWildWild
        settings.selectedPaytableId = "jacks-or-better-9-6"
        #expect(settings.statsPaytableKey == "jacks-or-better-9-6-www")
    }
}
