# Rating Prompt Feature — Design Spec

**Date:** 2026-03-22
**Status:** Approved

---

## Overview

Ask users to rate the app after they've had meaningful time to experience it. Uses a custom two-screen prompt: satisfied users are routed to the App Store, unsatisfied users can submit a short feedback note.

---

## Trigger Conditions

The prompt is shown **once per install**, when **all** of the following are true:

1. At least **3 days** have passed since first app launch
2. The prompt has **not** been shown before (`ratingPromptShown == false`)
3. The user has just completed one of these actions:
   - The deal-draw cycle finishes in **Play mode** (after `phase = .result` is set in `draw()`)
   - A **Drill session** ends (after session summary is computed in `DrillViewModel`)
   - A **Training lesson quiz** completes (after `isQuizComplete = true` in `TrainingLessonQuizViewModel.next()`)

Once shown (regardless of which button the user taps), `ratingPromptShown` is set to `true` and the prompt never appears again.

---

## Architecture

### `RatingPromptService`

New `ObservableObject` class matching the existing service pattern in the project. Accessed as a singleton (`RatingPromptService.shared`) so ViewModels can call it directly without requiring SwiftUI environment access.

**Persisted state (UserDefaults):**
- `firstLaunchDate: Date` — written once on first launch, never overwritten
- `ratingPromptShown: Bool` — set to `true` after prompt is displayed

**Published state:**
- `@Published var shouldShowPrompt: Bool` — drives the sheet presentation in `HomeView`

**Named constant:**
```swift
private static let minimumTimeInterval: TimeInterval = 3 * 86_400 // 3 days
```

**Public API:**
```swift
func markTriggerEvent()               // called by ViewModels; shows prompt if conditions met
func dismiss()                        // user tapped "Yes" or "Skip"; sets shouldShowPrompt = false
func submitFeedback(_ text: String) async  // sends feedback to Supabase, then dismisses

#if DEBUG
func forceShow()                      // resets ratingPromptShown + shows prompt; debug only
#endif
```

**Internal logic of `markTriggerEvent()`:**
```swift
guard !ratingPromptShown else { return }
guard let firstLaunch = firstLaunchDate,
      Date().timeIntervalSince(firstLaunch) >= Self.minimumTimeInterval else { return }
ratingPromptShown = true
shouldShowPrompt = true
```

**`forceShow()` implementation (DEBUG only):**
```swift
#if DEBUG
func forceShow() {
    ratingPromptShown = false                          // reset so dismiss() doesn't think state is dirty
    UserDefaults.standard.set(false, forKey: "ratingPromptShown")
    shouldShowPrompt = true
}
#endif
```
`forceShow()` resets `ratingPromptShown` to `false` before showing, so repeated test invocations work correctly. Because it is compiled out in release builds, it has no production impact.

### ViewModel Integration

Three ViewModels call `RatingPromptService.shared.markTriggerEvent()` at their natural completion points. The service is accessed as a singleton — no SwiftUI environment injection required in ViewModels.

| ViewModel | File | Trigger location |
|-----------|------|-----------------|
| `PlayViewModel` | `ViewModels/PlayViewModel.swift` | End of `draw()`, after `phase = .result` |
| `DrillViewModel` | `ViewModels/DrillViewModel.swift` | After session summary is finalized (end of session) |
| `TrainingLessonQuizViewModel` | `ViewModels/TrainingLessonQuizViewModel.swift` | Inside `next()` when `currentIndex + 1 >= hands.count` (i.e., `isQuizComplete = true`) |

### Sheet Presentation

The sheet is attached to `HomeView` using the service injected as an `@EnvironmentObject`:

```swift
.sheet(isPresented: $ratingPromptService.shouldShowPrompt) {
    RatingPromptView()
        .environmentObject(ratingPromptService)
}
```

`HomeView` receives `ratingPromptService` as an `@EnvironmentObject` injected at the app entry point.

---

## UI Flow

```
[Trigger event fires]
        ↓
[RatingPromptView — Screen 1]
  "Enjoying Video Poker Academy?"
  ┌─────────────────────┐  ┌──────────────┐
  │  Yes, love it! ★    │  │  Not really  │
  └─────────────────────┘  └──────────────┘
        ↓                         ↓
  SKStoreReviewController    [Screen 2 — Feedback form]
  .requestReview()           "What could we do better?"
  + dismiss()                [ multiline text field   ]
                             ┌──────────────┐  [Skip]
                             │ Send Feedback│
                             └──────────────┘
                                   ↓
                             submitFeedback(text)
                             (silent failure on error)
                             + dismiss()
```

Both screens live inside a single file `RatingPromptView.swift`, using an internal `enum Screen { case prompt, feedback }` state switch. No `NavigationStack` is used inside the sheet — the transition between screens is driven by a `switch` on the state enum.

### Screen 1 — Prompt

- Headline: "Enjoying Video Poker Academy?"
- Subtext: "Your rating helps other players find the app."
- Primary button: "Yes, love it! ★" → calls `SKStoreReviewController.requestReview()` then `dismiss()`
- Secondary button: "Not really" → sets `screen = .feedback`

### Screen 2 — Feedback Form

- Headline: "What could we do better?"
- Single `TextEditor` (multiline) with placeholder text
- "Send Feedback" button — enabled only when field is non-empty
- "Skip" text button — calls `dismiss()` without submitting
- On submit: calls `await ratingPromptService.submitFeedback(text)`, then calls `dismiss()`
- **Error handling:** if submission fails (network error, Supabase error), the error is logged to console and `dismiss()` is called silently. No error state is shown to the user — feedback is best-effort.

---

## Data

### Feedback Submission

Feedback text is sent to a new Supabase table `app_feedback`:

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | auto |
| `user_id` | uuid | nullable — populated from auth session if available, null for unauthenticated users |
| `feedback` | text | user-entered text |
| `app_version` | text | from `Bundle.main.infoDictionary["CFBundleShortVersionString"]` |
| `created_at` | timestamptz | auto |

**RLS policy:** `INSERT` is allowed for all users including anonymous (no `auth.uid()` check). `SELECT`/`UPDATE`/`DELETE` are restricted to service role only. This ensures unauthenticated users can submit feedback.

Submission uses the existing `SupabaseService` pattern.

---

## First Launch Date Tracking

`firstLaunchDate` is written in `VideoPokerAcademyApp.swift` at startup, before the `RatingPromptService` singleton is initialized:

```swift
if UserDefaults.standard.object(forKey: "firstLaunchDate") == nil {
    UserDefaults.standard.set(Date(), forKey: "firstLaunchDate")
}
```

---

## Debug / Testing

A **"Preview Rating Prompt"** button is added to the Settings screen, compiled only in `#if DEBUG` builds. It calls `RatingPromptService.shared.forceShow()`.

```swift
#if DEBUG
Section("Developer") {
    Button("Preview Rating Prompt") {
        RatingPromptService.shared.forceShow()
    }
}
#endif
```

This button does not appear in App Store builds.

---

## Files to Create / Modify

| File | Action |
|------|--------|
| `Services/RatingPromptService.swift` | **Create** — new `ObservableObject` service |
| `Views/Components/RatingPromptView.swift` | **Create** — both prompt and feedback screens (single file, internal `Screen` enum) |
| `App/VideoPokerAcademyApp.swift` | **Modify** — set `firstLaunchDate` on first launch; inject `RatingPromptService.shared` as `.environmentObject()` |
| `Views/Home/HomeView.swift` | **Modify** — attach `.sheet(isPresented:)` driven by `ratingPromptService.shouldShowPrompt` |
| `ViewModels/PlayViewModel.swift` | **Modify** — call `RatingPromptService.shared.markTriggerEvent()` at end of `draw()` after `phase = .result` |
| `ViewModels/DrillViewModel.swift` | **Modify** — call `RatingPromptService.shared.markTriggerEvent()` after session finalization |
| `ViewModels/TrainingLessonQuizViewModel.swift` | **Modify** — call `RatingPromptService.shared.markTriggerEvent()` inside `next()` when quiz is complete |
| `Views/Settings/SettingsView.swift` | **Modify** — add `#if DEBUG` section with "Preview Rating Prompt" button |
| Supabase migration | **Create** — `app_feedback` table with RLS policy allowing anonymous inserts |

---

## Out of Scope

- Re-prompting users who said "Not really" (prompt shown once only)
- A/B testing prompt copy
- Analytics events on prompt shown/dismissed
- Prompt shown more than once per install
