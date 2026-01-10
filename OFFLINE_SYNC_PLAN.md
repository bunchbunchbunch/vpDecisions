# Offline Sync Implementation Plan

## Goal
Enable users who recently logged in to use the app fully offline, with hand attempts queued and synced when connectivity returns.

## Scope

| Feature | Include | Notes |
|---------|---------|-------|
| Network Monitor | ✅ | Foundation for offline detection |
| Hand Attempt Queue | ✅ | Store locally, sync when online |
| Auth Session | ✅ | Already cached by Supabase SDK |
| Mastery Scores | ❌ | Not implemented yet |
| Guest Mode | ❌ | Not wanted |

---

## Component 1: Network Monitor

### New File: `Services/NetworkMonitor.swift`

```swift
import Foundation
import Network

@MainActor
@Observable
class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private(set) var isOnline = true
    private(set) var connectionType: ConnectionType = .unknown

    enum ConnectionType {
        case wifi, cellular, wired, unknown
    }

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnline = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(path) ?? .unknown

                // Trigger sync when coming back online
                if path.status == .satisfied {
                    await SyncService.shared.syncPendingAttempts()
                }
            }
        }
        monitor.start(queue: queue)
    }

    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .wired }
        return .unknown
    }
}
```

### Integration Points
- Initialize in `VideoPokerTrainerApp.swift` on launch
- Access via `NetworkMonitor.shared.isOnline` anywhere needed

---

## Component 2: Hand Attempt Queue

### Database Schema Addition

Add to `LocalStrategyStore.swift`:

```swift
// New table for pending hand attempts
let createPendingAttemptsSQL = """
    CREATE TABLE IF NOT EXISTS pending_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        hand_key TEXT NOT NULL,
        hand_category TEXT NOT NULL,
        paytable_id TEXT NOT NULL,
        user_hold TEXT NOT NULL,
        optimal_hold TEXT NOT NULL,
        is_correct INTEGER NOT NULL,
        ev_difference REAL NOT NULL,
        response_time_ms INTEGER,
        created_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending'
    );
"""
```

### New File: `Services/SyncService.swift`

```swift
import Foundation

actor SyncService {
    static let shared = SyncService()

    private init() {}

    // MARK: - Save Attempt (offline-first)

    func saveAttempt(_ attempt: HandAttempt) async {
        // Always save locally first
        await LocalStrategyStore.shared.savePendingAttempt(attempt)

        // Try to sync immediately if online
        if await NetworkMonitor.shared.isOnline {
            await syncPendingAttempts()
        }
    }

    // MARK: - Sync Pending Attempts

    func syncPendingAttempts() async {
        let pending = await LocalStrategyStore.shared.getPendingAttempts()
        guard !pending.isEmpty else { return }

        for attempt in pending {
            do {
                try await SupabaseService.shared.saveHandAttempt(attempt.toHandAttempt())
                await LocalStrategyStore.shared.markAttemptSynced(id: attempt.id)
            } catch {
                // Will retry on next sync
                print("Failed to sync attempt \(attempt.id): \(error)")
                break // Stop on first failure to preserve order
            }
        }
    }

    // MARK: - Pending Count (for UI)

    func pendingAttemptCount() async -> Int {
        await LocalStrategyStore.shared.getPendingAttemptCount()
    }
}
```

### LocalStrategyStore Additions

```swift
// MARK: - Pending Attempts

struct PendingAttempt: Identifiable {
    let id: Int64
    let userId: UUID
    let handKey: String
    let handCategory: String
    let paytableId: String
    let userHold: [Int]
    let optimalHold: [Int]
    let isCorrect: Bool
    let evDifference: Double
    let responseTimeMs: Int?
    let createdAt: Date

    func toHandAttempt() -> HandAttempt {
        HandAttempt(
            userId: userId,
            handKey: handKey,
            handCategory: handCategory,
            paytableId: paytableId,
            userHold: userHold,
            optimalHold: optimalHold,
            isCorrect: isCorrect,
            evDifference: evDifference,
            responseTimeMs: responseTimeMs
        )
    }
}

func savePendingAttempt(_ attempt: HandAttempt) async { ... }
func getPendingAttempts() async -> [PendingAttempt] { ... }
func getPendingAttemptCount() async -> Int { ... }
func markAttemptSynced(id: Int64) async { ... }
func clearSyncedAttempts() async { ... }
```

### QuizViewModel Changes

```swift
// Change from:
try await SupabaseService.shared.saveHandAttempt(attempt)

// To:
await SyncService.shared.saveAttempt(attempt)
```

---

## Component 3: UI Indicators

### Offline Banner (optional)

Add to views that need network awareness:

```swift
struct OfflineBanner: View {
    @State private var networkMonitor = NetworkMonitor.shared

    var body: some View {
        if !networkMonitor.isOnline {
            HStack {
                Image(systemName: "wifi.slash")
                Text("Offline - changes will sync when connected")
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.orange)
            .cornerRadius(8)
        }
    }
}
```

### Pending Sync Indicator (Settings)

Show in SettingsView or HomeView:

```swift
@State private var pendingCount = 0

var body: some View {
    if pendingCount > 0 {
        Label("\(pendingCount) attempts pending sync", systemImage: "arrow.triangle.2.circlepath")
            .foregroundColor(.orange)
    }
}
.task {
    pendingCount = await SyncService.shared.pendingAttemptCount()
}
```

---

## Implementation Order

### Phase 1: Network Monitor
1. Create `NetworkMonitor.swift`
2. Initialize in app launch
3. Test detection works

### Phase 2: Local Attempt Storage
1. Add `pending_attempts` table to LocalStrategyStore
2. Implement save/get/mark synced methods
3. Test local persistence

### Phase 3: Sync Service
1. Create `SyncService.swift`
2. Update QuizViewModel to use SyncService
3. Test offline save + online sync

### Phase 4: UI Polish
1. Add OfflineBanner component
2. Show pending count in Settings
3. Test full flow

---

## Testing Checklist

- [ ] Network monitor detects airplane mode toggle
- [ ] Hand attempts save locally when offline
- [ ] Attempts sync automatically when coming online
- [ ] Duplicate attempts are prevented (idempotent sync)
- [ ] Pending count shows correct number
- [ ] Offline banner appears/disappears correctly
- [ ] Auth session persists for recently logged-in users
- [ ] Quiz works fully offline with bundled paytables

---

## Files to Create

| File | Description |
|------|-------------|
| `Services/NetworkMonitor.swift` | Network status detection |
| `Services/SyncService.swift` | Offline queue and sync logic |
| `Views/Components/OfflineBanner.swift` | Optional UI indicator |

## Files to Modify

| File | Changes |
|------|---------|
| `Services/LocalStrategyStore.swift` | Add pending_attempts table and methods |
| `ViewModels/QuizViewModel.swift` | Use SyncService instead of direct Supabase |
| `App/VideoPokerTrainerApp.swift` | Initialize NetworkMonitor |
| `Views/Settings/SettingsView.swift` | Show pending sync count |

---

## Component 4: Graceful Offline Handling

### Online-Only Actions

These actions require network and should be **prevented or show an alert** when offline:

| Action | Location | Handling |
|--------|----------|----------|
| Download paytable | OfflineDataView | Disable download button |
| Play unavailable game | GameSelectorView, PlayStartView, QuizStartView | Show alert, disable selection |
| Sign in (email/password) | AuthView | Disable button, show message |
| Sign up | AuthView | Disable button, show message |
| Sign out | HomeView menu | Allow (clears local session) |
| Password reset | ForgotPasswordView | Disable button, show message |
| Magic link | AuthView | Disable button, show message |
| Google OAuth | AuthView | Disable button, show message |

### Implementation Strategy

#### 1. Reusable Alert

```swift
struct OfflineAlert: ViewModifier {
    let isPresented: Binding<Bool>
    let action: String

    func body(content: Content) -> some View {
        content.alert("You're Offline", isPresented: isPresented) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(action) requires an internet connection. Please try again when you're online.")
        }
    }
}

extension View {
    func offlineAlert(isPresented: Binding<Bool>, action: String) -> some View {
        modifier(OfflineAlert(isPresented: isPresented, action: action))
    }
}
```

#### 2. AuthView Changes

```swift
struct AuthView: View {
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var showOfflineAlert = false

    var body: some View {
        // ...

        // Sign In Button
        Button {
            if networkMonitor.isOnline {
                Task { await viewModel.signInWithEmail(...) }
            } else {
                showOfflineAlert = true
            }
        } label: {
            Text(isSignUp ? "Sign Up" : "Sign In")
        }
        .disabled(!networkMonitor.isOnline)
        .opacity(networkMonitor.isOnline ? 1.0 : 0.5)

        // Offline message below form
        if !networkMonitor.isOnline {
            Label("Sign in requires internet", systemImage: "wifi.slash")
                .font(.caption)
                .foregroundColor(.orange)
        }

        // ...
        .offlineAlert(isPresented: $showOfflineAlert, action: "Signing in")
    }
}
```

#### 3. Game Selector Changes

Show unavailable games as disabled when offline:

```swift
struct GameSelectorView: View {
    @State private var networkMonitor = NetworkMonitor.shared

    var body: some View {
        ForEach(PayTable.allPayTables) { paytable in
            let isAvailable = paytable.isBundled || hasDownloaded(paytable.id)
            let canSelect = isAvailable || networkMonitor.isOnline

            Button {
                if isAvailable {
                    selectedPaytableId = paytable.id
                } else if networkMonitor.isOnline {
                    // Trigger download flow
                    showDownloadPrompt = true
                } else {
                    showOfflineAlert = true
                }
            } label: {
                HStack {
                    Text(paytable.name)
                    Spacer()
                    if !isAvailable {
                        Image(systemName: "arrow.down.circle")
                            .foregroundColor(networkMonitor.isOnline ? .blue : .gray)
                    }
                }
            }
            .disabled(!canSelect)
            .opacity(canSelect ? 1.0 : 0.5)
        }
    }
}
```

#### 4. OfflineDataView Changes

Disable download buttons when offline:

```swift
// In OfflineDataView.swift
Button {
    // download action
} label: {
    Label("Download", systemImage: "arrow.down.circle")
}
.disabled(!networkMonitor.isOnline)

// Show message when offline
if !networkMonitor.isOnline {
    Section {
        Label("Downloads require internet connection", systemImage: "wifi.slash")
            .foregroundColor(.orange)
    }
}
```

#### 5. PlayStartView / QuizStartView Changes

Prevent starting game with unavailable paytable:

```swift
Button("Start") {
    let isAvailable = await StrategyService.shared.hasOfflineData(paytableId: selectedPaytableId)

    if isAvailable {
        // Proceed to game
        navigationPath.append(.playGame)
    } else if networkMonitor.isOnline {
        // Will download on demand
        navigationPath.append(.playGame)
    } else {
        showOfflineAlert = true
    }
}
```

### User Experience Flow

```
User offline, taps unavailable game:
┌─────────────────────────────────────┐
│         You're Offline              │
│                                     │
│  This game hasn't been downloaded   │
│  yet. Please connect to the         │
│  internet to download it, or        │
│  choose an available game.          │
│                                     │
│           [ OK ]                    │
└─────────────────────────────────────┘

User offline, taps Sign In:
┌─────────────────────────────────────┐
│         You're Offline              │
│                                     │
│  Signing in requires an internet    │
│  connection. Please try again       │
│  when you're online.                │
│                                     │
│           [ OK ]                    │
└─────────────────────────────────────┘
```

### Visual Indicators

When offline, show subtle indicators:

1. **Disabled buttons** - 50% opacity, non-interactive
2. **Offline badge** - Small wifi.slash icon next to unavailable items
3. **Section messages** - "Requires internet" text where relevant
4. **No intrusive banners** - Don't show global offline banner unless user tries blocked action

---

## Updated Files to Modify

| File | Changes |
|------|---------|
| `Services/LocalStrategyStore.swift` | Add pending_attempts table and methods |
| `ViewModels/QuizViewModel.swift` | Use SyncService instead of direct Supabase |
| `App/VideoPokerTrainerApp.swift` | Initialize NetworkMonitor |
| `Views/Settings/SettingsView.swift` | Show pending sync count |
| `Views/Auth/AuthView.swift` | Disable auth actions when offline |
| `Views/Auth/ForgotPasswordView.swift` | Disable reset when offline |
| `Views/Home/HomeView.swift` | Check availability before navigation |
| `Views/Play/PlayStartView.swift` | Validate paytable availability |
| `Views/Quiz/QuizStartView.swift` | Validate paytable availability |
| `Views/Settings/OfflineDataView.swift` | Disable downloads when offline |
| `Views/Components/GameSelectorView.swift` | Show unavailable games as disabled |

---

## Updated Testing Checklist

- [ ] Network monitor detects airplane mode toggle
- [ ] Hand attempts save locally when offline
- [ ] Attempts sync automatically when coming online
- [ ] Duplicate attempts are prevented (idempotent sync)
- [ ] Pending count shows correct number
- [ ] Auth session persists for recently logged-in users
- [ ] Quiz works fully offline with bundled paytables
- [ ] **Sign in/up buttons disabled when offline**
- [ ] **Unavailable games show as disabled when offline**
- [ ] **Download buttons disabled when offline**
- [ ] **Helpful alert shown when tapping blocked action**
- [ ] **Available games still work perfectly offline**

---

## Notes

- Supabase SDK already caches auth sessions, so recent logins work offline
- Strategy lookups already work offline (SQLite)
- Play mode already works offline (UserDefaults)
- This plan focuses only on hand attempt sync
