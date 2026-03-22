# Game Selector Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Group game families by category in the selector dropdown and sort paytable variants by return percentage with percentages displayed.

**Architecture:** Add `GameFamilyCategory` enum for grouping, add return percentage data to `PayTable`, update shared `GameSelectorView` with sectioned/sorted dropdowns, then refactor Play and Quiz start views to use the shared component.

**Tech Stack:** Swift 6.0, SwiftUI, iOS 17+

**Spec:** `docs/superpowers/specs/2026-03-20-game-selector-redesign.md`

---

### Task 1: Add GameFamilyCategory enum and category property

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/GameFamily.swift`

- [ ] **Step 1: Add GameFamilyCategory enum**

Add above the existing `GameFamily` enum:

```swift
enum GameFamilyCategory: String, CaseIterable, Identifiable {
    case standard
    case bonusPoker
    case doubleBonus
    case tripleBonus
    case aces
    case jackpot
    case ddbVariants
    case wildCards

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .bonusPoker: return "Bonus Poker"
        case .doubleBonus: return "Double Bonus"
        case .tripleBonus: return "Triple Bonus"
        case .aces: return "Aces"
        case .jackpot: return "Jackpot"
        case .ddbVariants: return "DDB Variants"
        case .wildCards: return "Wild Cards"
        }
    }

    static var displayOrder: [GameFamilyCategory] {
        [.standard, .bonusPoker, .doubleBonus, .tripleBonus,
         .aces, .jackpot, .ddbVariants, .wildCards]
    }
}
```

- [ ] **Step 2: Add category property and families(for:) to GameFamily**

Add inside the `GameFamily` enum, after the existing `isWildGame` property:

```swift
var category: GameFamilyCategory {
    switch self {
    // Standard
    case .jacksOrBetter, .tensOrBetter, .allAmerican:
        return .standard
    // Bonus Poker
    case .bonusPoker, .bonusPokerDeluxe, .bonusPokerPlus:
        return .bonusPoker
    // Double Bonus
    case .doubleBonus, .doubleDoubleBonus, .superDoubleBonus:
        return .doubleBonus
    // Triple Bonus
    case .tripleBonus, .tripleBonusPlus, .tripleDoubleBonus, .tripleTripleBonus:
        return .tripleBonus
    // Aces
    case .acesBonus, .acesAndEights, .acesAndFaces, .bonusAcesFaces,
         .superAces, .royalAcesBonus, .whiteHotAces:
        return .aces
    // Jackpot
    case .doubleJackpot, .doubleDoubleJackpot:
        return .jackpot
    // DDB Variants
    case .ddbAcesFaces, .ddbPlus:
        return .ddbVariants
    // Wild Cards
    case .deucesWild, .looseDeuces:
        return .wildCards
    }
}

static func families(for category: GameFamilyCategory) -> [GameFamily] {
    allCases.filter { $0.category == category }
        .sorted { $0.displayName < $1.displayName }
}
```

- [ ] **Step 3: Build to verify**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: Build succeeds with no errors.

---

### Task 2: Add return percentages to PayTable

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/PayTable.swift`

- [ ] **Step 1: Add returnPercentages dictionary and computed property**

Add after the `isBigWin` method (around line 79), before the `variantName` property:

```swift
/// Return percentage under optimal play. Values from PayTableData.swift comments and PAYTABLES.md.
static let returnPercentages: [String: Double] = [
    // Jacks or Better
    "jacks-or-better-9-6": 99.54,
    "jacks-or-better-9-5": 98.45,
    "jacks-or-better-8-6": 98.39,
    "jacks-or-better-8-5": 97.30,
    "jacks-or-better-8-5-35": 99.66,
    "jacks-or-better-7-5": 96.15,
    "jacks-or-better-6-5": 95.00,
    "jacks-or-better-9-6-90": 100.00,
    "jacks-or-better-9-6-940": 99.90,

    // Tens or Better
    "tens-or-better-6-5": 99.14,

    // All American
    "all-american-40-7": 100.72,
    "all-american-35-8": 99.60,
    "all-american-30-8": 98.49,
    "all-american-25-8": 97.37,

    // Bonus Poker
    "bonus-poker-8-5": 99.17,
    "bonus-poker-7-5": 98.01,
    "bonus-poker-7-5-1200": 99.09,
    "bonus-poker-6-5": 96.87,

    // Bonus Poker Deluxe
    "bonus-poker-deluxe-9-6": 99.64,
    "bonus-poker-deluxe-9-5": 98.55,
    "bonus-poker-deluxe-8-6": 98.49,
    "bonus-poker-deluxe-8-5": 97.40,
    "bonus-poker-deluxe-7-5": 96.25,
    "bonus-poker-deluxe-6-5": 95.36,
    // "bonus-poker-deluxe-8-6-100": ~100% progressive, omitted

    // Bonus Poker Plus
    "bonus-poker-plus-10-7": 99.61,
    "bonus-poker-plus-9-6": 98.34,

    // Double Bonus
    "double-bonus-10-7": 100.17,
    "double-bonus-10-7-80": 100.52,
    "double-bonus-10-7-4": 100.77,
    "double-bonus-10-6": 98.88,
    "double-bonus-9-7-5": 99.11,
    "double-bonus-9-6-5": 97.81,
    "double-bonus-9-6-4": 96.38,
    // "double-bonus-10-7-100": ~100% progressive, omitted

    // Double Double Bonus
    "double-double-bonus-10-6": 100.07,
    "double-double-bonus-9-6": 98.98,
    "double-double-bonus-9-5": 97.87,
    "double-double-bonus-8-5": 96.79,
    "double-double-bonus-7-5": 95.71,
    "double-double-bonus-6-5": 94.66,
    // "double-double-bonus-10-6-100": ~100% progressive, omitted

    // Super Double Bonus
    "super-double-bonus-9-5": 99.69,
    "super-double-bonus-8-5": 98.69,
    "super-double-bonus-7-5": 97.77,
    "super-double-bonus-6-5": 96.87,

    // Triple Double Bonus
    "triple-double-bonus-9-7": 99.58,
    "triple-double-bonus-9-6": 98.15,
    "triple-double-bonus-8-5": 95.97,

    // Triple Bonus
    "triple-bonus-9-5": 99.94,
    "triple-bonus-8-5": 98.52,
    "triple-bonus-7-5": 97.45,

    // Triple Bonus Plus
    "triple-bonus-plus-9-5": 99.80,
    "triple-bonus-plus-8-5": 98.73,
    "triple-bonus-plus-7-5": 97.67,

    // Triple Triple Bonus
    "triple-triple-bonus-9-6": 99.75,
    "triple-triple-bonus-9-5": 98.61,
    "triple-triple-bonus-8-5": 97.61,
    "triple-triple-bonus-7-5": 96.55,

    // Deuces Wild
    "deuces-wild-full-pay": 100.76,
    "deuces-wild-nsud": 99.73,
    "deuces-wild-illinois": 98.91,
    "deuces-wild-colorado": 96.77,
    "deuces-wild-25-15-9": 100.76,
    "deuces-wild-25-12-9": 99.81,
    "deuces-wild-25-15-8": 100.36,
    "deuces-wild-20-15-9": 99.89,
    "deuces-wild-20-12-9": 99.42,
    "deuces-wild-44-nsud": 99.73,
    "deuces-wild-44-illinois": 98.91,
    "deuces-wild-44-apdw": 99.96,

    // Loose Deuces
    "loose-deuces-500-17": 101.60,
    "loose-deuces-500-15": 100.97,
    "loose-deuces-500-12": 100.15,
    "loose-deuces-400-12": 99.20,

    // Double Jackpot
    "double-jackpot-8-5": 99.63,
    "double-jackpot-7-5": 98.49,

    // Double Double Jackpot
    "double-double-jackpot-10-6": 100.35,
    "double-double-jackpot-9-6": 99.27,

    // Aces & Eights
    "aces-and-eights-8-5": 99.78,
    "aces-and-eights-7-5": 98.63,

    // Aces & Faces
    "aces-and-faces-8-5": 99.26,
    "aces-and-faces-7-6": 98.85,
    "aces-and-faces-7-5": 98.12,
    "aces-and-faces-6-5": 96.97,

    // Aces Bonus
    "aces-bonus-8-5": 99.40,
    "aces-bonus-7-5": 98.25,
    "aces-bonus-6-5": 97.11,

    // Bonus Aces & Faces
    "bonus-aces-faces-8-5": 99.26,
    "bonus-aces-faces-7-5": 98.12,
    "bonus-aces-faces-6-5": 96.97,

    // Super Aces
    "super-aces-8-5": 99.94,
    "super-aces-7-5": 98.85,
    "super-aces-6-5": 97.78,

    // Royal Aces Bonus
    "royal-aces-bonus-9-6": 99.58,
    "royal-aces-bonus-10-5": 99.20,
    "royal-aces-bonus-8-6": 98.51,
    "royal-aces-bonus-9-5": 97.55,

    // White Hot Aces
    "white-hot-aces-9-5": 99.80,
    "white-hot-aces-8-5": 98.50,
    "white-hot-aces-7-5": 97.44,
    "white-hot-aces-6-5": 96.39,

    // DDB Aces & Faces
    "ddb-aces-faces-9-6": 99.47,
    "ddb-aces-faces-9-5": 98.37,

    // DDB Plus
    "ddb-plus-9-6": 99.68,
    "ddb-plus-9-5": 98.57,
    "ddb-plus-8-5": 97.49,
]

var returnPercentage: Double? {
    PayTable.returnPercentages[id]
}
```

**Note on deuces-wild-20-12-9:** The value 99.42 is estimated. Verify by running the Rust calculator or querying the `paytable_returns` Supabase table. Update if needed.

- [ ] **Step 2: Add variantDisplayName computed property**

Add after the existing `variantName` computed property (around line 115):

```swift
/// Variant name with return percentage for display in selectors (e.g., "9/6 99.54%")
var variantDisplayName: String {
    let base = variantName
    guard let pct = returnPercentage else { return base }
    return String(format: "%@ %.2f%%", base, pct)
}
```

- [ ] **Step 3: Build to verify**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: Build succeeds with no errors.

---

### Task 3: Update GameSelectorView

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Components/GameSelectorView.swift`

- [ ] **Step 1: Replace the full GameSelectorView implementation**

Replace the entire file content with:

```swift
import SwiftUI

struct GameSelectorView: View {
    @Binding var selectedPaytableId: String
    @State private var selectedFamily: GameFamily = .jacksOrBetter

    var body: some View {
        VStack(spacing: 12) {
            familyPickerSection
            paytablePickerSection
        }
        .onAppear {
            initializeSelectedFamily()
        }
        .onChange(of: selectedPaytableId) { _, newId in
            if let paytable = PayTable.allPayTables.first(where: { $0.id == newId }) {
                selectedFamily = paytable.family
            }
        }
    }

    private func initializeSelectedFamily() {
        if let paytable = PayTable.allPayTables.first(where: { $0.id == selectedPaytableId }) {
            selectedFamily = paytable.family
        }
    }

    // MARK: - Family Picker

    private var familyPickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Game Family")
                .font(.caption)
                .foregroundColor(.secondary)

            Menu {
                ForEach(GameFamilyCategory.displayOrder) { category in
                    Section(category.displayName) {
                        ForEach(GameFamily.families(for: category)) { family in
                            Button {
                                selectedFamily = family
                                let familyPaytables = sortedPaytables(for: family)
                                if !familyPaytables.contains(where: { $0.id == selectedPaytableId }),
                                   let first = familyPaytables.first {
                                    selectedPaytableId = first.id
                                }
                            } label: {
                                HStack {
                                    Text(family.displayName)
                                    if selectedFamily == family {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedFamily.displayName)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }

    // MARK: - Paytable Picker

    private var paytablePickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pay Table")
                .font(.caption)
                .foregroundColor(.secondary)

            let variants = sortedPaytables(for: selectedFamily)

            Menu {
                ForEach(variants) { paytable in
                    Button {
                        selectedPaytableId = paytable.id
                    } label: {
                        HStack {
                            Text(paytable.variantDisplayName)
                            if selectedPaytableId == paytable.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    if let selectedPaytable = PayTable.allPayTables.first(where: { $0.id == selectedPaytableId }) {
                        Text(selectedPaytable.variantDisplayName)
                            .foregroundColor(.primary)
                    } else {
                        Text("Select a pay table")
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }

    // MARK: - Helpers

    /// Returns paytables for a family sorted by return percentage descending.
    /// Paytables with unknown return percentage are sorted to the end.
    private func sortedPaytables(for family: GameFamily) -> [PayTable] {
        PayTable.paytables(for: family).sorted { a, b in
            let aReturn = a.returnPercentage ?? -1
            let bReturn = b.returnPercentage ?? -1
            return aReturn > bReturn
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedId = "jacks-or-better-9-6"

        var body: some View {
            VStack {
                GameSelectorView(selectedPaytableId: $selectedId)
                    .padding()

                Text("Selected: \(selectedId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    return PreviewWrapper()
}
```

- [ ] **Step 2: Build to verify**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: Build succeeds with no errors.

---

### Task 4: Refactor PlayStartView to use shared GameSelectorView

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/PlayStartView.swift`

- [ ] **Step 1: Replace inline game selector with GameSelectorView**

In `PlayStartView`, find the `allGamesSection` property (around line 174). Replace the entire `allGamesSection` computed property (including its `.onAppear` at lines 271-276) with:

```swift
private var allGamesSection: some View {
    VStack(alignment: .leading, spacing: 8) {
        Text("All Games")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(AppTheme.Colors.textSecondary)

        GameSelectorView(selectedPaytableId: $settings.selectedPaytableId)
    }
}
```

- [ ] **Step 2: Update popularGamesSection**

Remove the `selectedFamily = game.family` line from the popular games chip action (line 162), since `GameSelectorView` manages its own family state. The action should only set `settings.selectedPaytableId`:

```swift
GameChip(
    title: game.name,
    isSelected: settings.selectedPaytableId == game.id
) {
    settings.selectedPaytableId = game.id
}
```

- [ ] **Step 3: Remove unused properties**

Remove the following from `PlayStartView`:
- `@State private var selectedFamily: GameFamily = .jacksOrBetter` (line 8)
- `longestFamilyName` computed property (line 280)
- `selectedVariantName` computed property (line 284)

Keep `@State private var networkMonitor` and `showOfflineAlert` only if they're used elsewhere in the view (e.g., the start button's offline check).

- [ ] **Step 4: Build to verify**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: Build succeeds. Fix any compilation errors from removed properties being referenced elsewhere.

---

### Task 5: Refactor QuizStartView to use shared GameSelectorView

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Home/HomeView.swift`

- [ ] **Step 1: Replace inline game selector with GameSelectorView**

In `QuizStartView` (starts around line 509 in HomeView.swift), find the `allGamesSection` property (around line 698). Replace the entire `allGamesSection` computed property with:

```swift
private var allGamesSection: some View {
    VStack(alignment: .leading, spacing: 8) {
        Text("All Games")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(AppTheme.Colors.textSecondary)

        GameSelectorView(selectedPaytableId: $selectedPaytableId)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
```

- [ ] **Step 2: Update popularGamesSection**

Remove `selectedFamily = game.family` from the popular games chip action (line 685), since `GameSelectorView` manages its own family state. The action should set `selectedPaytableId` and `selectedPaytable`:

```swift
GameChip(
    title: game.name,
    isSelected: selectedPaytableId == game.id
) {
    selectedPaytableId = game.id
    selectedPaytable = game
}
```

- [ ] **Step 3: Add onChange handler to sync selectedPaytable**

`QuizStartView` maintains both `selectedPaytableId` (String) and `selectedPaytable` (PayTable binding). Add an `onChange` handler so that when `GameSelectorView` changes the ID, the PayTable binding stays in sync. Add to the body:

```swift
.onChange(of: selectedPaytableId) { _, newId in
    if let paytable = PayTable.allPayTables.first(where: { $0.id == newId }) {
        selectedPaytable = paytable
    }
}
```

- [ ] **Step 4: Remove unused properties**

Remove from `QuizStartView`:
- `@State private var selectedFamily: GameFamily = .jacksOrBetter` (line 515) — no longer needed; `GameSelectorView` manages its own family state
- `longestFamilyName` computed property (line 521)
- `selectedVariantName` computed property (line 525)

- [ ] **Step 5: Build to verify**

Run: `mcp__xcodebuildmcp__build_sim_name_proj`
Expected: Build succeeds. Fix any compilation errors from removed properties.

---

### Task 6: Visual verification

- [ ] **Step 1: Boot simulator and install**

```
mcp__xcodebuildmcp__boot_simulator
mcp__xcodebuildmcp__install_app
mcp__xcodebuildmcp__launch_app
```

- [ ] **Step 2: Screenshot home screen**

Run: `mcp__xcodebuildmcp__screenshot`

Navigate to each mode and take screenshots to verify the game selector looks correct:

- [ ] **Step 3: Verify Play mode selector**

Navigate to Play mode start screen. Verify:
- Family dropdown shows sections (Standard, Bonus Poker, etc.)
- Variant dropdown shows return percentages and is sorted highest first

Take screenshot: `mcp__xcodebuildmcp__screenshot`

- [ ] **Step 4: Verify Quiz mode selector**

Navigate to Quiz mode start screen. Verify:
- Popular game chips still work
- Family/variant dropdowns use the shared component with sections and percentages

Take screenshot: `mcp__xcodebuildmcp__screenshot`

- [ ] **Step 5: Verify Analyzer selector**

Navigate to Hand Analyzer. Verify the dropdowns show sections and percentages.

Take screenshot: `mcp__xcodebuildmcp__screenshot`

- [ ] **Step 6: Verify Simulation selector**

Navigate to Simulation. Verify the dropdowns show sections and percentages.

Take screenshot: `mcp__xcodebuildmcp__screenshot`
