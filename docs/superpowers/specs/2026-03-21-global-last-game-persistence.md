# Global Last-Game Persistence

## Problem

When entering Quiz or Analyzer mode, the game always resets to Jacks or Better 9/6. Play mode persists its own selection via `PlayPersistence`, but there's no cross-mode memory. Users who primarily play Double Double Bonus must re-select it every time they switch modes.

## Solution

Store a single `lastSelectedPaytableId` in UserDefaults. All modes read it as their default and all modes write to it when the user changes their selection.

## Design

### Storage

- **Key:** `lastSelectedPaytableId` (UserDefaults string)
- **Default:** `PayTable.jacksOrBetter96.id`
- **Validation:** On read, verify the ID exists in `PayTable.allPayTables`. If not, fall back to default.

### Read/Write Helper

Add two static methods to `PayTable`:

```swift
extension PayTable {
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
}
```

### Write Path

`GameSelectorView` already has an `onChange(of: selectedPaytableId)` handler. Add a single line to persist the selection:

```swift
PayTable.lastSelectedId = selectedPaytableId
```

Since every mode uses `GameSelectorView`, this covers all write paths with one change.

**Semantic:** The key tracks the last *changed* game, not the last *used* game. If a user opens a mode and starts without changing the pre-selected game, the global key is not updated. This is correct — only intentional selection actions persist.

### Read Path

Each mode initializes its `@State` with the persisted value instead of hardcoded JoB 9/6:

| File | Current Default | New Default |
|------|----------------|-------------|
| `PlayStartView` | Loaded from `PlayPersistence` | `PayTable.lastSelectedId` (only if PlayPersistence has no saved settings) |
| `HomeView` (Quiz) | `PayTable.jacksOrBetter96.id` | `PayTable.lastSelectedId` |
| `HandAnalyzerView` | `PayTable.jacksOrBetter96.id` | `PayTable.lastSelectedId` |
| `SimulationViewModel` | `PayTable.jacksOrBetter96.id` | `PayTable.lastSelectedId` |

**Play mode note:** Play already persists its own `selectedPaytableId` in `PlaySettings`. The global last-game should only apply as the initial default when Play has no saved settings. Play's own persistence takes priority for Play mode. However, when the user changes the game in Play mode (via GameSelectorView), it still writes to the global key.

**Quiz mode note:** `HomeView` holds `@State selectedPaytable: PayTable` which flows into `QuizStartView`. The fix goes in `HomeView`'s initialization, resolving the ID to a `PayTable` instance:
```swift
@State private var selectedPaytable = PayTable.allPayTables.first { $0.id == PayTable.lastSelectedId } ?? PayTable.jacksOrBetter96
```

## Files Changed

1. **`PayTable.swift`** — Add `lastSelectedId` computed property
2. **`GameSelectorView.swift`** — Write to `PayTable.lastSelectedId` on change
3. **`HomeView.swift`** — Initialize `selectedPaytable` from `PayTable.lastSelectedId`
4. **`HandAnalyzerView.swift`** — Initialize from `PayTable.lastSelectedId`
5. **`PlayStartView.swift`** — Use `PayTable.lastSelectedId` as fallback default
6. **`SimulationViewModel.swift`** — Initialize from `PayTable.lastSelectedId`

## Edge Cases

- **Deleted/invalid paytable ID:** Getter validates against `allPayTables`, falls back to JoB 9/6
- **First launch:** No stored value, falls back to JoB 9/6 (same as current behavior)
- **Play mode's own persistence:** Play's `PlayPersistence` settings take priority; global key is fallback only
