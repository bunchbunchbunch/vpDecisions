# Game Selector Redesign

## Goal

Improve game selector navigability by grouping game families into logical categories and sorting paytable variants by return percentage.

## Scope

**In scope:**
- `GameSelectorView` (shared component used by Analyzer, Simulation)
- Play mode's inline game selector in `PlayStartView` (refactor to use shared `GameSelectorView`)
- Quiz mode's inline game selector in `QuizStartView` (refactor to use shared `GameSelectorView`)
- `GameFamily` model (add category grouping)
- `PayTable` model (add return percentage data)

**Out of scope:**
- `TrainingGameSelectorView` (separate curated experience)
- Backend/Supabase changes
- `PopularGameButton` component
- `PaytableRegistry` (no changes needed; it manages download lifecycle, not display)

## Data Model Changes

### GameFamilyCategory enum

New enum in `GameFamily.swift`:

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

    var displayName: String { ... }

    static var displayOrder: [GameFamilyCategory] {
        [.standard, .bonusPoker, .doubleBonus, .tripleBonus,
         .aces, .jackpot, .ddbVariants, .wildCards]
    }
}
```

Add computed property on `GameFamily`:

```swift
var category: GameFamilyCategory { ... }

static func families(for category: GameFamilyCategory) -> [GameFamily] { ... }
```

### Category mapping

| Category | Families |
|----------|----------|
| Standard | Jacks or Better, Tens or Better, All American |
| Bonus Poker | Bonus Poker, Bonus Poker Deluxe, Bonus Poker Plus |
| Double Bonus | Double Bonus, Double Double Bonus, Super Double Bonus |
| Triple Bonus | Triple Bonus, Triple Bonus Plus, Triple Double Bonus, Triple Triple Bonus |
| Aces | Aces Bonus, Aces & Eights, Aces & Faces, Bonus Aces & Faces, Super Aces, Royal Aces Bonus, White Hot Aces |
| Jackpot | Double Jackpot, Double Double Jackpot |
| DDB Variants | DDB Aces & Faces, DDB Plus |
| Wild Cards | Deuces Wild, Loose Deuces |

### PayTable return percentages

Add a static dictionary on `PayTable` mapping paytable ID to return percentage, and a computed property to look it up.

```swift
static let returnPercentages: [String: Double] = [
    "jacks-or-better-9-6": 99.54,
    "jacks-or-better-9-5": 98.45,
    // ... all paytables with known values
]

var returnPercentage: Double? {
    PayTable.returnPercentages[id]
}
```

**Missing/approximate values:**

The following paytables have no return percentage in code comments and need values looked up or computed:
- `deuces-wild-illinois`
- `deuces-wild-colorado`
- `deuces-wild-25-15-9`
- `deuces-wild-25-12-9`
- `deuces-wild-25-15-8`
- `deuces-wild-20-15-9`
- `deuces-wild-20-12-9`
- `deuces-wild-44-nsud`
- `deuces-wild-44-illinois`
- `deuces-wild-44-apdw`

The following have approximate values (`~100%` because they depend on progressive jackpot amounts):
- `bonus-poker-deluxe-8-6-100`
- `double-bonus-10-7-100`
- `double-double-bonus-10-6-100`

**Fallback:** If `returnPercentage` is `nil`, display only the variant name with no percentage. Sort paytables with unknown percentages to the end of the list.

### variantDisplayName (new computed property)

Add a **new** computed property `variantDisplayName` on `PayTable`. Do not modify the existing `variantName` property (used elsewhere).

```swift
var variantDisplayName: String {
    let base = variantName
    guard let pct = returnPercentage else { return base }
    return String(format: "%@ %.2f%%", base, pct)
}
```

**Special case:** Some variant names already contain parenthesized percentages (e.g., `"9/6 (94.0%)"` for `jacks-or-better-9-6-940`). For these, the `variantDisplayName` should still append the return percentage since the parenthesized value represents a different thing (e.g., RF payout), while the appended value is the overall return. Result: `"9/6 (94.0%) 99.90%"`. This is acceptable because the parenthesized portion is paytable-specific context, not a return percentage.

**Formatting:** Always 2 decimal places (e.g., `99.54%`, `100.76%`, `95.00%`).

## GameSelectorView Changes

### Family dropdown

Replace flat `ForEach(GameFamily.allCases)` with sectioned iteration:

```swift
Menu {
    ForEach(GameFamilyCategory.displayOrder) { category in
        Section(category.displayName) {
            ForEach(GameFamily.families(for: category)) { family in
                Button { ... } label: {
                    Text(family.displayName)
                }
            }
        }
    }
} label: {
    // Show selected family name (no download counts)
}
```

Changes from current:
- Add section headers for each category
- Remove `(X/Y)` download counts from family labels
- Families ordered alphabetically within each section

### Variant dropdown

Replace Downloaded/Not Downloaded split with single sorted list:

```swift
Menu {
    ForEach(sortedVariants) { paytable in
        Button {
            selectedPaytableId = paytable.id
        } label: {
            Text(paytable.variantDisplayName)
        }
    }
} label: {
    // Show selected variant's variantDisplayName
}
```

Where `sortedVariants` are all paytables for the selected family sorted by `returnPercentage` descending (unknown percentages sorted to end).

Changes from current:
- Remove Downloaded/Not Downloaded sections
- Remove download status icons (checkmark, download arrow)
- Sort by return percentage (highest first, unknown last)
- Each item shows `variantDisplayName` (e.g., "9/6 99.54%")
- Remove offline warning banner

### Auto-selection on family change

Only auto-select when the current paytable is not a member of the newly selected family (matching existing behavior). When auto-selecting, pick the first variant in the sorted list (highest return percentage).

### Removed features

- Download count display on family picker
- Download status icons on variant picker
- Downloaded/Not Downloaded sectioning
- Offline warning banner
- `availablePaytableIds` tracking and `loadAvailablePaytables()` async loading
- `NetworkMonitor` dependency

### Labels

Keep existing labels: "Game Family" and "Pay Table".

## Play Mode Integration

### Current state

`PlayStartView` (`Views/Play/PlayStartView.swift`) has its own inline game selector with two dropdown `Menu`s for family and variant selection, duplicating `GameSelectorView` logic.

### Change

Refactor `PlayStartView` to use the shared `GameSelectorView(selectedPaytableId:)` instead of its inline dropdowns.

## Quiz Mode Integration

### Current state

`QuizStartView` (defined inside `HomeView.swift`) has its own inline game selector with:
- Popular game chips (`FlowLayout` of `GameChip` views)
- Two inline dropdown `Menu`s for family and variant selection
- Quiz size selector (10, 25, 100)

### Change

Replace the two inline dropdown `Menu`s with the shared `GameSelectorView(selectedPaytableId:)`. Keep:
- Popular game chips (quick-select, separate from `GameSelectorView`)
- Quiz size selector
- Weak spots toggle

**Bridging note:** `GameSelectorView` takes `Binding<String>` (paytable ID). `QuizStartView` currently maintains a `selectedPaytable: PayTable` binding. After refactoring, derive the `PayTable` from the ID via `PayTable.allPayTables.first(where: { $0.id == selectedPaytableId })` where needed (e.g., when starting the quiz).

## Files Modified

| File | Change |
|------|--------|
| `Models/GameFamily.swift` | Add `GameFamilyCategory` enum, `category` property, `families(for:)` static method |
| `Models/PayTable.swift` | Add `returnPercentages` dictionary, `returnPercentage` computed property, `variantDisplayName` computed property |
| `Views/Components/GameSelectorView.swift` | Sectioned family dropdown, sorted variant dropdown with return %, remove download indicators |
| `Views/Play/PlayStartView.swift` | Refactor to use shared `GameSelectorView` |
| `Views/Home/HomeView.swift` | Refactor `QuizStartView` to use shared `GameSelectorView` |
