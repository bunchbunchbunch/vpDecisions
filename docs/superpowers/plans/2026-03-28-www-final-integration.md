# WWW Final Integration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the remaining gaps for end-to-end Wild Wild Wild gameplay on 9/6 Jacks or Better.

**Architecture:** Three small fixes: update the Supabase strategy manifest with correct file sizes, add WWW-specific pay table rows for non-wild base games, and add a code-level guard against 100-play in WWW mode.

**Tech Stack:** Swift / SwiftUI (iOS), curl (manifest upload)

---

### Task 1: Update Strategy Manifest File Sizes

The manifest at `https://ctqefgdvqiaiumtmcjdz.supabase.co/storage/v1/object/public/strategies/manifest.json` has stale entries from a previous (incorrect) WWW implementation. The 3 JoB 9/6 entries have wrong file sizes:

| ID | Old fileSize | Correct fileSize |
|----|-------------|-----------------|
| www-jacks-or-better-9-6-1w | 1,551,224 | 17,061,836 |
| www-jacks-or-better-9-6-2w | 145,300 | 17,207,072 |
| www-jacks-or-better-9-6-3w | 12,908 | 17,219,916 |

- [ ] **Step 1: Download current manifest, update file sizes, re-upload**

```bash
# Download
curl -s "https://ctqefgdvqiaiumtmcjdz.supabase.co/storage/v1/object/public/strategies/manifest.json" -o /tmp/manifest.json

# Update the 3 entries
python3 -c "
import json
with open('/tmp/manifest.json') as f:
    d = json.load(f)

updates = {
    'www-jacks-or-better-9-6-1w': 17061836,
    'www-jacks-or-better-9-6-2w': 17207072,
    'www-jacks-or-better-9-6-3w': 17219916,
}

for entry in d:
    if entry['id'] in updates:
        entry['fileSize'] = updates[entry['id']]

with open('/tmp/manifest.json', 'w') as f:
    json.dump(d, f, indent=2)

# Verify
for entry in d:
    if entry['id'] in updates:
        print(f'{entry[\"id\"]}: {entry[\"fileSize\"]}')
"

# Upload updated manifest
curl -s -w "%{http_code}" -o /dev/null \
    -X POST "https://ctqefgdvqiaiumtmcjdz.supabase.co/storage/v1/object/strategies/manifest.json" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -H "x-upsert: true" \
    --data-binary "@/tmp/manifest.json"
```

- [ ] **Step 2: Verify the uploaded manifest**

```bash
curl -s "https://ctqefgdvqiaiumtmcjdz.supabase.co/storage/v1/object/public/strategies/manifest.json" | \
python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'{e[\"id\"]}: {e[\"fileSize\"]}') for e in d if e['id'].startswith('www-jacks-or-better-9-6-') and not '90' in e['id'] and not '940' in e['id']]"
```

Expected: All 3 entries show the new file sizes.

---

### Task 2: Add WWW Pay Table Rows for Non-Wild Base Games

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/PayTable.swift`
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/PayTableData.swift`

When playing WWW on Jacks or Better (or other non-wild games), the pay table needs "Five of a Kind" and "Wild Royal" rows that don't exist in the standard pay table. Deuces Wild already has these rows naturally.

- [ ] **Step 1: Add a computed property for WWW-adjusted rows**

In `PayTable.swift`, add a method that returns the base rows with WWW hands prepended for non-wild games:

```swift
/// Returns pay table rows adjusted for WWW mode.
/// For non-wild base games, adds Five of a Kind and Wild Royal rows.
/// For Deuces Wild (which already has these), returns rows unchanged.
func wwwRows() -> [PayTableRow] {
    // Deuces Wild already has Wild Royal and Five of a Kind
    if isDeucesWild { return rows }

    // Check if the pay table already has these rows
    let existingNames = Set(rows.map { $0.handName })
    if existingNames.contains("Five of a Kind") { return rows }

    // Derive payouts from existing rows:
    // Wild Royal = same as Royal Flush
    // Five of a Kind = same as Four of a Kind (matches Rust calculator heuristic)
    let royalPayout = rows.first { $0.handName == "Royal Flush" }?.payouts ?? [250, 500, 750, 1000, 4000]
    let quadPayout = rows.first { $0.handName == "Four of a Kind" }?.payouts ?? [25, 50, 75, 100, 125]

    var wwwRows = rows
    // Insert after Royal Flush (index 0)
    wwwRows.insert(PayTableRow(handName: "Wild Royal", payouts: royalPayout), at: 1)
    wwwRows.insert(PayTableRow(handName: "Five of a Kind", payouts: quadPayout), at: 2)
    return wwwRows
}
```

- [ ] **Step 2: Update PlayView to use wwwRows when in WWW mode**

In `PlayView.swift`, wherever `paytable.rows` is used for display, check the variant:

At line ~859 (compact paytable in portrait):
```swift
// Before:
ForEach(Array(paytable.rows.prefix(4)), id: \.handName) { row in

// After:
let displayRows = viewModel.settings.variant.isWildWildWild ? paytable.wwwRows() : paytable.rows
ForEach(Array(displayRows.prefix(4)), id: \.handName) { row in
```

At line ~1545 (full paytable in landscape):
```swift
// Before:
ForEach(paytable.rows, id: \.handName) { row in

// After:
let displayRows = viewModel.settings.variant.isWildWildWild ? paytable.wwwRows() : paytable.rows
ForEach(displayRows, id: \.handName) { row in
```

Search for ALL other references to `paytable.rows` in PlayView.swift and apply the same pattern.

- [ ] **Step 3: Update calculatePayout in PlayViewModel**

The `calculatePayout` function looks up hand names in `currentPaytable?.rows`. For WWW mode, it needs to use `wwwRows()` so that "Five of a Kind" and "Wild Royal" resolve to payouts:

In `PlayViewModel.swift`, find `calculatePayout` and update:

```swift
private func calculatePayout(handName: String?) -> Int {
    guard let handName = handName, let paytable = currentPaytable else { return 0 }

    let rows = settings.variant.isWildWildWild ? paytable.wwwRows() : paytable.rows
    guard let row = rows.first(where: { $0.handName == handName }) else { return 0 }

    let coinIndex = min(settings.coinsPerLine, 5) - 1
    return row.payouts[coinIndex]
}
```

- [ ] **Step 4: Build and run tests**

Run: `mcp__xcodebuildmcp__build_sim_name_proj` then `mcp__xcodebuildmcp__test_sim_name_proj`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/PayTable.swift \
        ios-native/VideoPokerAcademy/VideoPokerAcademy/Models/PayTableData.swift \
        ios-native/VideoPokerAcademy/VideoPokerAcademy/Views/Play/PlayView.swift \
        ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/PlayViewModel.swift
git commit -m "feat(ios): add WWW pay table rows (Five of a Kind, Wild Royal) for non-wild games"
```

---

### Task 3: Add 100-Play Code Guard + Visual Verification

**Files:**
- Modify: `ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/PlayViewModel.swift`

- [ ] **Step 1: Add guard in deal()**

In `PlayViewModel.swift`, in the `deal()` function right after `guard canDeal else { return }` (line ~201):

```swift
// Prevent 100-play for WWW (wilds are shared across lines, incompatible with independent decks)
if settings.variant.isWildWildWild && settings.lineCount == .oneHundred {
    settings.lineCount = .ten
}
```

This silently downgrades to 10-line if 100-play somehow gets selected in WWW mode (defensive, since the UI already prevents it).

- [ ] **Step 2: Build and run tests**

Run: `mcp__xcodebuildmcp__build_sim_name_proj` then `mcp__xcodebuildmcp__test_sim_name_proj`

- [ ] **Step 3: Visual verification in simulator**

```
mcp__xcodebuildmcp__boot_simulator
mcp__xcodebuildmcp__install_app
mcp__xcodebuildmcp__launch_app
mcp__xcodebuildmcp__screenshot
```

Navigate to Play Mode:
1. Select "Jacks or Better 9/6"
2. Select "Wild³" variant
3. Verify: description text shows "2× bet cost · 0–3 wild cards added to deck each deal"
4. Verify: 100-play is dimmed
5. Select 3 lines, tap "Start Playing"
6. Tap "Deal" — verify wild count banner appears
7. If jokers are dealt, verify they display as joker cards
8. Hold some cards, tap "Draw"
9. Verify hands are evaluated correctly (check for Five of a Kind, Wild Royal possibilities)
10. Take screenshots at each step

- [ ] **Step 4: Commit**

```bash
git add ios-native/VideoPokerAcademy/VideoPokerAcademy/ViewModels/PlayViewModel.swift
git commit -m "feat(ios): add 100-play guard for WWW mode"
```
