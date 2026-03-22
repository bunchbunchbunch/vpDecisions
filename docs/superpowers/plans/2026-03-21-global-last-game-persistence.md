# Global Last-Game Persistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist the user's last-selected game across all modes (Play, Quiz, Analyzer, Simulation) so it becomes the default when entering any mode.

**Architecture:** Single UserDefaults key (`lastSelectedPaytableId`) with a static computed property on `PayTable` for read/write. `GameSelectorView` writes on every selection change; each mode reads at initialization.

**Tech Stack:** Swift, SwiftUI, UserDefaults

**Spec:** `docs/superpowers/specs/2026-03-21-global-last-game-persistence.md`

---

### Task 1: Add `lastSelectedId` helper to PayTable

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/PayTable.swift`

- [ ] **Step 1: Add the static computed property**

At the top of `PayTable.swift`, after the struct definition and before the `family` computed property, add an extension (or add directly to the struct) with a static computed property:

```swift
// MARK: - Last Selected Game Persistence

static var lastSelectedId: String {
    get {
        let id = UserDefaults.standard.string(forKey: "lastSelectedPaytableId")
        if let id, allPayTables.contains(where: { $0.id == id }) {
            return id
        }
        return PayTable.jacksOrBetter96.id
    }
    set {
        UserDefaults.standard.set(newValue, forKey: "lastSelectedPaytableId")
    }
}
```

- [ ] **Step 2: Build to verify compilation**

Run: `mcp__xcodebuildmcp__build_sim_name_proj` (VideoPokerAcademy scheme)
Expected: Build succeeds.

---

### Task 2: Write to global key from GameSelectorView

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Components/GameSelectorView.swift`

- [ ] **Step 1: Add persistence write in onChange handler**

In `GameSelectorView.swift`, the existing `onChange(of: selectedPaytableId)` handler (line 15) currently updates `selectedFamily`. Add a line to persist the selection globally:

```swift
.onChange(of: selectedPaytableId) { _, newId in
    if let paytable = PayTable.allPayTables.first(where: { $0.id == newId }) {
        selectedFamily = paytable.family
    }
    PayTable.lastSelectedId = newId
}
```

- [ ] **Step 2: Build to verify compilation**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: Build succeeds.

---

### Task 3: Read global default in HomeView (Quiz mode)

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Home/HomeView.swift`

- [ ] **Step 1: Update selectedPaytable initialization**

In `HomeView.swift` line 27, change the `@State` initialization from hardcoded JoB 9/6 to reading from the global key:

Before:
```swift
@State private var selectedPaytable = PayTable.jacksOrBetter96 {
```

After:
```swift
@State private var selectedPaytable = PayTable.allPayTables.first(where: { $0.id == PayTable.lastSelectedId }) ?? PayTable.jacksOrBetter96 {
```

- [ ] **Step 2: Build to verify compilation**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: Build succeeds.

---

### Task 4: Read global default in HandAnalyzerView

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Analyzer/HandAnalyzerView.swift`

- [ ] **Step 1: Update both state initializations**

In `HandAnalyzerView.swift` lines 6-7, change both defaults:

Before:
```swift
@State private var selectedFamily: GameFamily = .jacksOrBetter
@State private var selectedPaytableId: String = PayTable.jacksOrBetter96.id
```

After:
```swift
@State private var selectedFamily: GameFamily = (PayTable.allPayTables.first(where: { $0.id == PayTable.lastSelectedId }) ?? PayTable.jacksOrBetter96).family
@State private var selectedPaytableId: String = PayTable.lastSelectedId
```

- [ ] **Step 2: Build to verify compilation**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: Build succeeds.

---

### Task 5: Read global default in SimulationViewModel

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/SimulationViewModel.swift`

- [ ] **Step 1: Update selectedPaytableId initialization**

In `SimulationViewModel.swift` line 16, change the default:

Before:
```swift
@Published var selectedPaytableId: String = PayTable.jacksOrBetter96.id
```

After:
```swift
@Published var selectedPaytableId: String = PayTable.lastSelectedId
```

- [ ] **Step 2: Build to verify compilation**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: Build succeeds.

---

### Task 6: Read global default in PlaySettings (fallback for Play mode)

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/PlayModels.swift`

- [ ] **Step 1: Update PlaySettings default**

In `PlayModels.swift` line 167, change the default for `selectedPaytableId` so that when no saved settings exist, it uses the global last-selected game:

Before:
```swift
var selectedPaytableId: String = PayTable.jacksOrBetter96.id
```

After:
```swift
var selectedPaytableId: String = PayTable.lastSelectedId
```

Note: This only affects the default value for new `PlaySettings` instances. Existing users with saved settings will decode their persisted value from UserDefaults — `Codable` decoding overrides the struct default.

- [ ] **Step 2: Build to verify compilation**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: Build succeeds.

---

### Task 7: Final build, test, and visual verification

- [ ] **Step 1: Full build**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: Build succeeds with no warnings related to changes.

- [ ] **Step 2: Run tests**

Run: `mcp__xcodebuildmcp__test_sim_name_proj`
Expected: All tests pass.

- [ ] **Step 3: Visual verification**

Boot simulator, install, launch, and take a screenshot:
1. `mcp__xcodebuildmcp__boot_simulator`
2. `mcp__xcodebuildmcp__install_app`
3. `mcp__xcodebuildmcp__launch_app`
4. Navigate to Play mode, select a non-default game (e.g., Double Double Bonus 9/6)
5. Go back to home, enter Quiz mode — verify the selected game is now Double Double Bonus 9/6
6. Go back, enter Analyzer — verify same game is pre-selected
7. `mcp__xcodebuildmcp__screenshot` at each step to confirm
