# Rating Prompt Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show a custom "Enjoying the app?" prompt once per install after 3 days, routing satisfied users to the App Store and unsatisfied users to a single-field in-app feedback form.

**Architecture:** A singleton `RatingPromptService` (matching existing service patterns) holds all logic and persisted state; ViewModels call `markTriggerEvent()` at natural completion points; `HomeView` owns the sheet driven by a `@Published var shouldShowPrompt`.

**Tech Stack:** Swift 6, SwiftUI, ObservableObject, UserDefaults, StoreKit (SKStoreReviewController), Supabase Swift SDK

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `supabase/migrations/20260322000000_add_app_feedback.sql` | Create | `app_feedback` table + RLS |
| `VideoPokerAcademy/Services/RatingPromptService.swift` | Create | All prompt logic + feedback submission |
| `VideoPokerAcademy/Views/Components/RatingPromptView.swift` | Create | Two-screen sheet UI |
| `VideoPokerAcademy/VideoPokerAcademyTests/RatingPromptServiceTests.swift` | Create | Unit tests for service logic |
| `VideoPokerAcademy/App/VideoPokerAcademyApp.swift` | Modify | Record `firstLaunchDate` on first run |
| `VideoPokerAcademy/Views/Home/HomeView.swift` | Modify | Observe service + attach `.sheet()` |
| `VideoPokerAcademy/ViewModels/PlayViewModel.swift` | Modify | Call `markTriggerEvent()` after `draw()` |
| `VideoPokerAcademy/ViewModels/DrillViewModel.swift` | Modify | Call `markTriggerEvent()` after drill completes |
| `VideoPokerAcademy/ViewModels/TrainingLessonQuizViewModel.swift` | Modify | Call `markTriggerEvent()` when quiz completes |
| `VideoPokerAcademy/Views/Settings/SettingsView.swift` | Modify | Add `#if DEBUG` "Preview Rating Prompt" button |

All paths are relative to `/Users/johnbunch/bbb/vpDecisions/ios-native/VideoPokerAcademy/`.

---

## Task 1: Supabase Migration — `app_feedback` table

**Files:**
- Create: `supabase/migrations/20260322000000_add_app_feedback.sql`

- [ ] **Step 1: Create migration file**

```sql
-- app_feedback table for user-submitted feedback from the rating prompt
create table app_feedback (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references auth.users(id) on delete set null,
    feedback text not null,
    app_version text not null,
    created_at timestamptz not null default now()
);

alter table app_feedback enable row level security;

-- Allow anonymous and authenticated users to INSERT (feedback is best-effort, no auth required)
create policy "Allow public inserts" on app_feedback
    for insert
    to anon, authenticated
    with check (true);

-- Only service role can read (no SELECT policy for anon/authenticated)
```

- [ ] **Step 2: Apply the migration**

Run from the repo root (`/Users/johnbunch/bbb/vpDecisions`):

```bash
npx supabase db push
```

If Supabase CLI is not installed locally, paste the SQL above directly into the Supabase dashboard SQL editor at https://supabase.com/dashboard → SQL Editor.

- [ ] **Step 3: Verify the table exists**

In the Supabase dashboard, navigate to Table Editor and confirm `app_feedback` appears with the correct columns.

---

## Task 2: Create `RatingPromptService`

**Files:**
- Create: `VideoPokerAcademy/Services/RatingPromptService.swift`

- [ ] **Step 1: Create the service file**

```swift
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
```

- [ ] **Step 2: Build to confirm it compiles**

Use the XcodeBuildMCP tool:
```
mcp__xcodebuildmcp__build_sim_name_proj
  simulatorName: "iPhone 16"
  projectPath: "/Users/johnbunch/bbb/vpDecisions/ios-native/VideoPokerAcademy/VideoPokerAcademy.xcodeproj"
  scheme: "VideoPokerAcademy"
```

Expected: BUILD SUCCEEDED. Fix any errors before continuing.

---

## Task 3: Unit Tests for `RatingPromptService`

**Files:**
- Modify: `VideoPokerAcademy/project.yml` (add test target)
- Create: `VideoPokerAcademy/VideoPokerAcademyTests/RatingPromptServiceTests.swift`

The project uses XcodeGen (`project.yml`) — add the test target there and regenerate, rather than using the Xcode GUI.

- [ ] **Step 1: Add test target to `project.yml`**

In `/Users/johnbunch/bbb/vpDecisions/ios-native/VideoPokerAcademy/project.yml`, add a new target after the existing `VideoPokerAcademy` target:

```yaml
  VideoPokerAcademyTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - VideoPokerAcademyTests
    dependencies:
      - target: VideoPokerAcademy
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.vptrainer.native.tests
        SWIFT_VERSION: "5.0"
```

- [ ] **Step 2: Create the test source directory and regenerate the project**

```bash
mkdir -p /Users/johnbunch/bbb/vpDecisions/ios-native/VideoPokerAcademy/VideoPokerAcademyTests
cd /Users/johnbunch/bbb/vpDecisions/ios-native/VideoPokerAcademy
xcodegen generate
```

Expected: `VideoPokerAcademy.xcodeproj` is regenerated with a `VideoPokerAcademyTests` target.

- [ ] **Step 3: Create the test file**

```swift
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
```

- [ ] **Step 4: Run tests and confirm all pass**

```
mcp__xcodebuildmcp__test_sim_name_proj
  simulatorName: "iPhone 16"
  projectPath: "/Users/johnbunch/bbb/vpDecisions/ios-native/VideoPokerAcademy/VideoPokerAcademy.xcodeproj"
  scheme: "VideoPokerAcademy"
```

Expected: All `RatingPromptServiceTests` tests pass. Fix any failures before continuing.

---

## Task 4: Create `RatingPromptView`

**Files:**
- Create: `VideoPokerAcademy/Views/Components/RatingPromptView.swift`

- [ ] **Step 1: Create the view file**

```swift
import StoreKit
import SwiftUI

struct RatingPromptView: View {
    @ObservedObject private var service = RatingPromptService.shared
    @State private var screen: Screen = .prompt
    @State private var feedbackText = ""
    @State private var isSubmitting = false

    private enum Screen { case prompt, feedback }

    var body: some View {
        ZStack {
            AppTheme.Gradients.background
                .ignoresSafeArea()

            switch screen {
            case .prompt:
                promptScreen
            case .feedback:
                feedbackScreen
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Screen 1: Prompt

    private var promptScreen: some View {
        VStack(spacing: 28) {
            Image(systemName: "star.fill")
                .font(.system(size: 52))
                .foregroundColor(.yellow)

            VStack(spacing: 12) {
                Text("Enjoying Video Poker Academy?")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Your rating helps other players find the app.")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button {
                    requestReview()
                    service.dismiss()
                } label: {
                    Text("Yes, love it! ★")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppTheme.Colors.mintGreen)
                        .cornerRadius(26)
                }

                Button {
                    screen = .feedback
                } label: {
                    Text("Not really")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding(32)
    }

    // MARK: - Screen 2: Feedback Form

    private var feedbackScreen: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What could we do better?")
                .font(.title2.bold())
                .foregroundColor(.white)

            TextEditor(text: $feedbackText)
                .frame(minHeight: 120)
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
                .overlay(alignment: .topLeading) {
                    if feedbackText.isEmpty {
                        Text("Share your thoughts...")
                            .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.6))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }

            HStack {
                Button("Skip") {
                    service.dismiss()
                }
                .foregroundColor(AppTheme.Colors.textSecondary)

                Spacer()

                Button("Send Feedback") {
                    isSubmitting = true
                    Task {
                        await service.submitFeedback(feedbackText)
                        isSubmitting = false
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isSendEnabled ? AppTheme.Colors.mintGreen : Color.gray.opacity(0.5))
                .cornerRadius(22)
                .disabled(!isSendEnabled)
            }
        }
        .padding(32)
    }

    // MARK: - Helpers

    private var isSendEnabled: Bool {
        !feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSubmitting
    }

    private func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}

#Preview {
    RatingPromptView()
}
```

- [ ] **Step 2: Build to confirm it compiles**

```
mcp__xcodebuildmcp__build_sim_name_proj
```

Expected: BUILD SUCCEEDED. Fix any errors before continuing.

---

## Task 5: Record `firstLaunchDate` in App Entry Point

**Files:**
- Modify: `VideoPokerAcademy/App/VideoPokerAcademyApp.swift`

The `init()` method currently only starts Sentry (lines 12–17). Add the `firstLaunchDate` recording at the end of `init()`.

> **Note on injection pattern:** The spec mentions injecting `RatingPromptService.shared` as `.environmentObject()` at the app level. The plan instead uses `@ObservedObject private var ratingPromptService = RatingPromptService.shared` directly in `HomeView` (Task 6) and `@ObservedObject private var service = RatingPromptService.shared` in `RatingPromptView` (Task 4). Both produce the same result — the singleton is observed wherever needed. No `.environmentObject()` call is required in `VideoPokerAcademyApp.swift`.

- [ ] **Step 1: Add firstLaunchDate recording to `init()`**

In `VideoPokerAcademyApp.init()`, after the Sentry setup block (after the closing `}` of `SentrySDK.start { ... }`), add:

```swift
// Record first launch date for rating prompt (written once; never overwritten)
if UserDefaults.standard.object(forKey: "firstLaunchDate") == nil {
    UserDefaults.standard.set(Date(), forKey: "firstLaunchDate")
}
```

The resulting `init()` should look like:

```swift
init() {
    SentrySDK.start { options in
        options.dsn = "https://c6a1309302958c324ec7580b62d0ccbc@o4510830379728896.ingest.us.sentry.io/4510830381367296"
        options.tracesSampleRate = 0
    }
    // Record first launch date for rating prompt (written once; never overwritten)
    if UserDefaults.standard.object(forKey: "firstLaunchDate") == nil {
        UserDefaults.standard.set(Date(), forKey: "firstLaunchDate")
    }
}
```

- [ ] **Step 2: Build to confirm it compiles**

```
mcp__xcodebuildmcp__build_sim_name_proj
```

---

## Task 6: Wire `HomeView` to Show the Prompt Sheet

**Files:**
- Modify: `VideoPokerAcademy/Views/Home/HomeView.swift`

`HomeView` needs to observe `RatingPromptService` and present the sheet.

- [ ] **Step 1: Add `@ObservedObject` property to `HomeView`**

After the existing state properties (around line 32, after `@State private var weakSpotsMode = false`), add:

```swift
@ObservedObject private var ratingPromptService = RatingPromptService.shared
```

- [ ] **Step 2: Attach the sheet to the `NavigationStack`**

The `NavigationStack` in `HomeView.body` closes at line 74 (`}`). Add the sheet modifier before that closing brace, after the last existing `.navigationDestination` modifier (line 73):

```swift
.sheet(isPresented: $ratingPromptService.shouldShowPrompt) {
    RatingPromptView()
}
```

The `NavigationStack` block should end like:

```swift
            .navigationDestination(for: SimulationViewModel.self) { vm in
                SimulationContainerView(viewModel: vm, navigationPath: $navigationPath)
            }
            .sheet(isPresented: $ratingPromptService.shouldShowPrompt) {
                RatingPromptView()
            }
        } // end NavigationStack
```

- [ ] **Step 3: Build to confirm it compiles**

```
mcp__xcodebuildmcp__build_sim_name_proj
```

---

## Task 7: Add Trigger to `PlayViewModel`

**Files:**
- Modify: `VideoPokerAcademy/ViewModels/PlayViewModel.swift`

The `draw()` method (lines 212–239) ends with `await clearSavedHandState()` at line 238. Add the trigger call after that line, before the closing `}`.

- [ ] **Step 1: Call `markTriggerEvent()` at the end of `draw()`**

After `await clearSavedHandState()` (line 238), before the closing `}` of `draw()`, add:

```swift
RatingPromptService.shared.markTriggerEvent()
```

The end of `draw()` should look like:

```swift
    isAnimating = false
    phase = .result

    // Clear saved hand state since hand completed normally
    await clearSavedHandState()
    RatingPromptService.shared.markTriggerEvent()
}
```

- [ ] **Step 2: Build to confirm it compiles**

```
mcp__xcodebuildmcp__build_sim_name_proj
```

---

## Task 8: Add Trigger to `DrillViewModel`

**Files:**
- Modify: `VideoPokerAcademy/ViewModels/DrillViewModel.swift`

The `completeDrill()` method (lines 166–180) runs a `Task {}` that records the drill session and refreshes stats. Add the trigger call after the stats refresh at line 178.

- [ ] **Step 1: Call `markTriggerEvent()` at the end of the `completeDrill()` Task**

After `stats = await TrainingService.shared.stats(for: drillId)` (line 178), add:

```swift
RatingPromptService.shared.markTriggerEvent()
```

The `completeDrill()` method should look like:

```swift
private func completeDrill() {
    guard let session = session else { return }

    Task {
        await TrainingService.shared.recordDrillSession(
            drillId: drillId,
            correct: session.correctCount,
            total: session.hands.count,
            evLost: session.totalEvLost
        )

        // Refresh stats
        stats = await TrainingService.shared.stats(for: drillId)
        RatingPromptService.shared.markTriggerEvent()
    }
}
```

- [ ] **Step 2: Build to confirm it compiles**

```
mcp__xcodebuildmcp__build_sim_name_proj
```

---

## Task 9: Add Trigger to `TrainingLessonQuizViewModel`

**Files:**
- Modify: `VideoPokerAcademy/ViewModels/TrainingLessonQuizViewModel.swift`

The `next()` method (lines 189–215) sets `isQuizComplete = true` and calls `progressStore.recordAttempt()` when the quiz finishes (lines 192–202). Add the trigger call after `progressStore.recordAttempt()`.

- [ ] **Step 1: Call `markTriggerEvent()` after quiz completion is recorded**

After the `progressStore.recordAttempt(...)` call (lines 198–202), add:

```swift
RatingPromptService.shared.markTriggerEvent()
```

The quiz-complete branch of `next()` should look like:

```swift
if currentIndex + 1 >= hands.count {
    // Quiz complete
    audioService.play(.quizComplete)
    isQuizComplete = true

    // Record progress
    progressStore.recordAttempt(
        lessonNumber: lesson.number,
        score: correctCount,
        totalHands: hands.count
    )
    RatingPromptService.shared.markTriggerEvent()
} else {
```

- [ ] **Step 2: Build and run all tests**

```
mcp__xcodebuildmcp__build_sim_name_proj
mcp__xcodebuildmcp__test_sim_name_proj
```

Expected: BUILD SUCCEEDED, all tests pass.

---

## Task 10: Add Debug Button to `SettingsView`

**Files:**
- Modify: `VideoPokerAcademy/Views/Settings/SettingsView.swift`

The "About" section ends at line 212 (`}`). The "Sign Out Button" comment is at line 214. Add a `#if DEBUG` section between them.

- [ ] **Step 1: Add the Developer debug section**

Between the closing `}` of the About section (line 212) and the `// Sign Out Button` comment (line 214), add:

```swift
#if DEBUG
// Developer Tools
settingsSection(title: "Developer") {
    Button {
        RatingPromptService.shared.forceShow()
    } label: {
        SettingsRowContent(
            icon: "star.bubble",
            title: "Preview Rating Prompt",
            subtitle: "Bypasses time gate — debug only",
            showChevron: false
        )
    }
}
.padding(.top, 8)
#endif
```

- [ ] **Step 2: Build to confirm it compiles**

```
mcp__xcodebuildmcp__build_sim_name_proj
```

- [ ] **Step 3: Boot simulator, install, launch, and visually verify**

```
mcp__xcodebuildmcp__boot_simulator    simulatorName: "iPhone 16"
mcp__xcodebuildmcp__install_app
mcp__xcodebuildmcp__launch_app
mcp__xcodebuildmcp__screenshot
```

Navigate to Settings → scroll to bottom. Confirm "Developer" section appears with "Preview Rating Prompt" button.

- [ ] **Step 4: Test the full flow via the debug button**

1. Tap "Preview Rating Prompt" — confirm the sheet appears with "Enjoying Video Poker Academy?" headline
2. Tap "Not really" — confirm the feedback form appears with a text field
3. Type some text — confirm "Send Feedback" button becomes enabled
4. Tap "Skip" — confirm sheet dismisses
5. Tap "Preview Rating Prompt" again — confirm it appears again (forceShow resets state)
6. Tap "Yes, love it! ★" — confirm the App Store review dialog appears (on device) or nothing crashes (in Simulator, StoreKit review is a no-op)

Take a screenshot after each step to verify:
```
mcp__xcodebuildmcp__screenshot
```

- [ ] **Step 5: Run full test suite**

```
mcp__xcodebuildmcp__test_sim_name_proj
```

Expected: All tests pass.

---

## Final Verification Checklist

- [ ] `app_feedback` table exists in Supabase with correct schema and RLS
- [ ] All 10 `RatingPromptServiceTests` pass (7 standard + 3 `forceShow` tests in DEBUG)
- [ ] Sheet presents correctly from Settings debug button (both screens work)
- [ ] "Developer" section does NOT appear in a Release build (verify by checking `#if DEBUG` is in place)
- [ ] Build succeeds with no warnings related to the new code
