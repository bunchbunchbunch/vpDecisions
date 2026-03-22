import Testing
@testable import VideoPokerAcademy
import Foundation

@MainActor
struct RatingPromptServiceTests {

    // MARK: - Helper

    /// Creates an isolated service backed by a fresh UserDefaults suite.
    private func makeService(
        firstLaunchDaysAgo: Double? = nil,
        alreadyShown: Bool = false
    ) -> RatingPromptService {
        let suiteName = "test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        if let days = firstLaunchDaysAgo {
            let date = Date().addingTimeInterval(-days * 86_400)
            defaults.set(date, forKey: "firstLaunchDate")
        }
        if alreadyShown {
            defaults.set(true, forKey: "ratingPromptShown")
        }
        return RatingPromptService(defaults: defaults)
    }

    // MARK: - markTriggerEvent

    @Test("No prompt when firstLaunchDate has never been set")
    func noFirstLaunchDate() {
        let service = makeService()
        service.markTriggerEvent()
        #expect(service.shouldShowPrompt == false)
    }

    @Test("No prompt when fewer than 3 days have passed")
    func tooSoon() {
        let service = makeService(firstLaunchDaysAgo: 1)
        service.markTriggerEvent()
        #expect(service.shouldShowPrompt == false)
    }

    @Test("Prompt shown when exactly 3 days have passed")
    func showsAtThreeDays() {
        let service = makeService(firstLaunchDaysAgo: 3)
        service.markTriggerEvent()
        #expect(service.shouldShowPrompt == true)
    }

    @Test("Prompt shown when more than 3 days have passed")
    func showsAfterThreeDays() {
        let service = makeService(firstLaunchDaysAgo: 10)
        service.markTriggerEvent()
        #expect(service.shouldShowPrompt == true)
    }

    @Test("No prompt when already shown before")
    func notShownAgain() {
        let service = makeService(firstLaunchDaysAgo: 10, alreadyShown: true)
        service.markTriggerEvent()
        #expect(service.shouldShowPrompt == false)
    }

    @Test("Second trigger after dismiss is ignored")
    func onlyFiresOnce() {
        let service = makeService(firstLaunchDaysAgo: 3)
        service.markTriggerEvent() // first call — shows prompt
        service.dismiss()
        service.markTriggerEvent() // second call — should be ignored (ratingPromptShown is now true)
        #expect(service.shouldShowPrompt == false)
    }

    // MARK: - dismiss

    @Test("dismiss() hides the prompt")
    func dismissHidesPrompt() {
        let service = makeService(firstLaunchDaysAgo: 3)
        service.markTriggerEvent()
        service.dismiss()
        #expect(service.shouldShowPrompt == false)
    }

    // MARK: - forceShow (DEBUG only)

    #if DEBUG
    @Test("forceShow() shows prompt regardless of time gate")
    func forceShowIgnoresTimeGate() {
        let service = makeService(firstLaunchDaysAgo: 0)
        service.forceShow()
        #expect(service.shouldShowPrompt == true)
    }

    @Test("forceShow() shows prompt even when already shown once")
    func forceShowResetsShownState() {
        let service = makeService(firstLaunchDaysAgo: 10, alreadyShown: true)
        service.forceShow()
        #expect(service.shouldShowPrompt == true)
    }

    @Test("forceShow() can be called repeatedly")
    func forceShowRepeatable() {
        let service = makeService(firstLaunchDaysAgo: 3)
        service.forceShow()
        service.dismiss()
        service.forceShow() // should work again
        #expect(service.shouldShowPrompt == true)
    }
    #endif
}
