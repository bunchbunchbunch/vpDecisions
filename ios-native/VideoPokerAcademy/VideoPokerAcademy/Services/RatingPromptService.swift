import Foundation
import StoreKit

// MARK: - Feedback Row (Supabase insert)

struct AppFeedbackRow: Codable, Sendable {
    let userId: UUID?
    let feedback: String
    let appVersion: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case feedback
        case appVersion = "app_version"
    }
}

// MARK: - RatingPromptService

@MainActor
final class RatingPromptService: ObservableObject {
    static let shared = RatingPromptService()

    // MARK: - Constants

    private static let minimumTimeInterval: TimeInterval = 3 * 86_400 // 3 days
    private static let firstLaunchKey = "firstLaunchDate"
    private static let shownKey = "ratingPromptShown"

    // MARK: - Published State

    @Published var shouldShowPrompt = false

    // MARK: - Private

    private let defaults: UserDefaults

    /// Designated initializer. Production code uses `RatingPromptService.shared` (default UserDefaults).
    /// Tests pass a fresh `UserDefaults(suiteName:)` instance for isolation.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private var firstLaunchDate: Date? {
        defaults.object(forKey: Self.firstLaunchKey) as? Date
    }

    private var ratingPromptShown: Bool {
        get { defaults.bool(forKey: Self.shownKey) }
        set { defaults.set(newValue, forKey: Self.shownKey) }
    }

    // MARK: - Public API

    /// Call at each trigger point (end of Play hand, Drill session, Training lesson quiz).
    /// Shows prompt if 3+ days have passed since install and prompt has not been shown before.
    func markTriggerEvent() {
        guard !ratingPromptShown else { return }
        guard let firstLaunch = firstLaunchDate,
              Date().timeIntervalSince(firstLaunch) >= Self.minimumTimeInterval else { return }
        ratingPromptShown = true
        shouldShowPrompt = true
    }

    /// Dismiss the prompt sheet without submitting feedback.
    func dismiss() {
        shouldShowPrompt = false
    }

    /// Submit feedback text to Supabase, then dismiss. Failures are logged and silently swallowed.
    func submitFeedback(_ text: String) async {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let userId = SupabaseService.shared.currentUser?.id
        let row = AppFeedbackRow(userId: userId, feedback: text, appVersion: appVersion)

        do {
            try await SupabaseService.shared.client
                .from("app_feedback")
                .insert(row)
                .execute()
        } catch {
            print("[RatingPromptService] Failed to submit feedback: \(error)")
        }

        dismiss()
    }

    // MARK: - Debug

    #if DEBUG
    /// Bypasses all conditions and shows the prompt immediately. Resets `ratingPromptShown` so
    /// repeated test invocations work. Compiled out of release builds.
    func forceShow() {
        ratingPromptShown = false  // uses self.defaults via the computed property setter
        shouldShowPrompt = true
    }
    #endif
}
