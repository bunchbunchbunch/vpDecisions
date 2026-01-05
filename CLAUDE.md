# Claude Code Instructions

## Git Rules

- Do not push to git without explicit permission from the user

---

# iOS Project

## Project Overview
- **Platform**: iOS 17+
- **Language**: Swift 6.0
- **UI Framework**: SwiftUI
- **Architecture**: MVVM with @Observable

---

## AUTONOMOUS WORKFLOW (CRITICAL)

You have access to XcodeBuildMCP tools. **USE THEM** to validate your work. Do not ask me to test—test yourself.

### Time & Iterations Don't Matter

I don't care how long it takes or how many iterations you need. Take 10 attempts, take 20—whatever it takes. **My goal is to minimize the times I have to manually test or intervene.**

Be thorough. Be persistent. Keep trying different approaches if the first doesn't work. I would rather you spend 15 minutes iterating silently than present me broken code after 30 seconds.

**Thoroughness > Speed. Working code > Fast code.**

### After Writing Any Code:

1. **BUILD IMMEDIATELY**
   ```
   mcp__xcodebuildmcp__build_sim_name_proj
   ```

2. **IF BUILD FAILS**: Read the errors. Fix them. Rebuild. Repeat until it compiles. Do not stop or ask for help until you've tried at least 3 fix attempts.

3. **ONCE IT BUILDS, RUN TESTS**
   ```
   mcp__xcodebuildmcp__test_sim_name_proj
   ```

4. **IF TESTS FAIL**: Read the failures. Fix the code. Re-run tests. Repeat until green.

5. **FOR UI CHANGES**: Boot simulator, install, launch, and take a screenshot to verify visually:
   ```
   mcp__xcodebuildmcp__boot_simulator
   mcp__xcodebuildmcp__install_app
   mcp__xcodebuildmcp__launch_app
   mcp__xcodebuildmcp__screenshot
   ```

6. **CAPTURE LOGS** if there are runtime crashes:
   ```
   mcp__xcodebuildmcp__capture_logs
   ```

### The Golden Rule
**DO NOT present code to me until it builds and tests pass.** Iterate silently. Fix errors yourself. Only show me the working result.

---

## Build Commands Reference

| Action | Command |
|--------|---------|
| Build for Simulator | `mcp__xcodebuildmcp__build_sim_name_proj` |
| Run Tests | `mcp__xcodebuildmcp__test_sim_name_proj` |
| Clean Build | `mcp__xcodebuildmcp__clean` |
| List Simulators | `mcp__xcodebuildmcp__list_simulators` |
| Boot Simulator | `mcp__xcodebuildmcp__boot_simulator` |
| Install App | `mcp__xcodebuildmcp__install_app` |
| Launch App | `mcp__xcodebuildmcp__launch_app` |
| Screenshot | `mcp__xcodebuildmcp__screenshot` |
| Capture Logs | `mcp__xcodebuildmcp__capture_logs` |
| List Schemes | `mcp__xcodebuildmcp__list_schemes` |
| Discover Projects | `mcp__xcodebuildmcp__discover_projects` |

---

## Coding Standards

### Swift Style
- Use Swift 6 strict concurrency (`Sendable`, `@MainActor`, `async/await`)
- Prefer `@Observable` over `ObservableObject`
- Use `guard` for early exits
- Prefer value types (structs) over classes
- No force unwrapping (`!`) without justification

### SwiftUI Patterns
- Extract views when they exceed ~80 lines
- Use `@State` for local view state only
- Use `@Environment` for dependency injection
- Use `NavigationStack` (not deprecated `NavigationView`)
- Use `@Bindable` for bindings to @Observable objects

### Error Handling
```swift
enum AppError: LocalizedError {
    case networkError(underlying: Error)
    case validationError(message: String)

    var errorDescription: String? {
        switch self {
        case .networkError(let error): return error.localizedDescription
        case .validationError(let msg): return msg
        }
    }
}
```

### Testing
- Write unit tests for all ViewModel logic
- Use Swift Testing framework (`@Test`, `#expect`) when possible
- Test edge cases and error paths

---

## When Debugging

1. **Reproduce first**: Build and run to see the actual error
2. **Capture logs**: Use `mcp__xcodebuildmcp__capture_logs`
3. **Read the full error**: Swift errors often have useful suggestions
4. **Fix incrementally**: One change at a time, rebuild after each
5. **Verify the fix**: Run relevant tests, don't assume it worked

---

## DO NOT

- ❌ Show me code that doesn't compile
- ❌ Ask "should I build this?" — just build it
- ❌ Ask "should I run tests?" — just run them
- ❌ Stop after first error — try to fix it yourself
- ❌ Use deprecated APIs when modern alternatives exist
- ❌ Create massive monolithic views
- ❌ Skip the build step
- ❌ Optimize for speed over correctness

---

## GIT RESTRICTIONS (STRICT)

**NEVER** perform these Git operations without my explicit approval:
- `git commit` — Always ask before committing
- `git push` — Always ask before pushing
- `git checkout` / `git switch` — Ask before switching branches
- `git reset` — Ask before any reset operations
- `git merge` — Ask before merging

**Permission is per-action, not per-session.** If I give you permission to commit/push once, that permission applies ONLY to that specific action. You must ask again for each subsequent commit or push.

**Always commit AND push together.** Never just commit without pushing. When I approve a commit, always push it immediately after.

**You MAY freely use** (no permission needed):
- `git status`
- `git diff`
- `git log`
- `git branch` (to list branches)
- `git stash` (to save work temporarily)

When I ask you to commit or push, confirm what you're about to do first.

---

## DO

- ✅ Build after every significant code change
- ✅ Run tests after implementation
- ✅ Fix errors autonomously — keep trying until it works
- ✅ Take screenshots to verify UI changes
- ✅ Take as many iterations as needed — patience is fine
- ✅ Try multiple approaches if the first doesn't work
- ✅ Tell me what you tried when you're truly stuck (after 5+ attempts)
- ✅ Show me the final working code with test results
- ✅ Ask before any Git commits or pushes

---

## Project Structure
```
MyApp/
├── App/                    # App entry point
├── Features/               # Feature modules
│   └── [FeatureName]/
│       ├── Views/          # SwiftUI views
│       ├── ViewModels/     # @Observable classes
│       └── Models/         # Data models
├── Core/                   # Shared code
│   ├── Extensions/
│   ├── Services/
│   └── Networking/
├── Resources/              # Assets, Localizations
└── Tests/
```

---

## Session Start Checklist

When starting work on this project:
1. Run `mcp__xcodebuildmcp__discover_projects` to find the workspace/project
2. Run `mcp__xcodebuildmcp__list_schemes` to see available schemes
3. Do a test build to ensure everything is configured correctly
