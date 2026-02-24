---
name: ui-scan
description: UI test environment setup and accessibility scan with recommendations for splash/onboarding bypass
version: 1.0.0
author: Terry Nyberg
license: MIT
allowed-tools: [mcp__XcodeBuildMCP, Grep, Read]
metadata:
  tier: execution
  category: testing
---

# UI Scan

> **Quick Ref:** UI test environment setup: splash/onboarding bypass, accessibility identifier scan, element finding strategies, parallel vs sequential execution.

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

Set up UI test environment and scan for accessibility/testability issues.

## Test Execution Mode

**How would you like to run UI tests?**

| Option | Flag | Pros | Cons |
|--------|------|------|------|
| **Parallel** (Default) | `-parallel-testing-enabled YES` | Faster execution | May cause "Clone X" simulator failures |
| **Sequential** | `-parallel-testing-enabled NO` | More stable, no clone issues | Slower execution |

### Running Tests Sequentially (Recommended for stability)

```bash
# Via xcodebuild
xcodebuild test \
  -scheme YourScheme \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -parallel-testing-enabled NO

# Via XcodeBuildMCP - add to extraArgs
test_sim({ extraArgs: ["-parallel-testing-enabled", "NO"] })
```

### Running Tests in Parallel (Faster but less stable)

```bash
# Via xcodebuild (default behavior)
xcodebuild test \
  -scheme YourScheme \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -parallel-testing-enabled YES \
  -maximum-concurrent-test-simulator-destinations 2

# Via XcodeBuildMCP
test_sim({ extraArgs: ["-parallel-testing-enabled", "YES", "-maximum-concurrent-test-simulator-destinations", "2"] })
```

### Fixing Parallel Test Failures

If you see `"Clone X of iPhone 17 Pro"` failures:

1. **Kill zombie simulators:**
   ```bash
   xcrun simctl shutdown all
   killall Simulator
   ```

2. **Delete cloned simulators:**
   ```bash
   xcrun simctl delete unavailable
   ```

3. **Clean DerivedData:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/YourProject-*
   ```

4. **Switch to sequential execution** (most reliable fix)

---

## Phase 1: Test Environment Setup

### Launch Arguments for UI Tests

Add these to your UI test setup to bypass splash and onboarding:

```swift
override func setUpWithError() throws {
    try super.setUpWithError()
    continueAfterFailure = false

    app = XCUIApplication()
    app.launchArguments = [
        "--uitesting",      // Signal UI test mode
        "-skip-splash",     // Skip splash screen delays
        "--reset-state"     // Optional: Reset for clean state
    ]
    app.launch()

    // Skip onboarding if it appears
    skipOnboardingIfPresent()
}
```

### App-Side Support Required

Add to your app's main view (e.g., `StuffolioApp.swift`):

```swift
// Detect UI testing mode
private var isUITesting: Bool {
    ProcessInfo.processInfo.arguments.contains("--uitesting")
}

// Skip onboarding in UI tests
} else if !hasCompletedOnboarding && !isUITesting {
    OnboardingView()
}

// Skip tutorials in UI tests
.fullScreenCover(isPresented: Binding(
    get: { hasCompletedOnboarding && !hasSeenFirstUse && !showingSplash && !isUITesting },
    set: { _ in }
)) {
    FirstUseTutorialView()
}
```

### Skip Onboarding Helper

Add to your UI test base class:

```swift
func skipOnboardingIfPresent() {
    // Skip button on onboarding
    let skipButton = app.buttons["Skip"]
    if skipButton.waitForExistence(timeout: 3) && skipButton.isHittable {
        skipButton.tap()
        _ = skipButton.waitForNonExistence(timeout: 3)
    }

    // Skip tutorial if it appears
    let tutorialSkip = app.buttons["Skip Tutorial"]
    if tutorialSkip.waitForExistence(timeout: 2) && tutorialSkip.isHittable {
        tutorialSkip.tap()
    }

    // Get Started button (onboarding completion)
    let getStartedButton = app.buttons["Get Started"]
    if getStartedButton.waitForExistence(timeout: 1) && getStartedButton.isHittable {
        getStartedButton.tap()
    }
}
```

## Phase 2: Accessibility Scan

### Check for Missing Identifiers

Scan views for elements that need accessibility identifiers:

```bash
# Find buttons without accessibility identifiers
grep -r "Button(" --include="*.swift" | grep -v "accessibilityIdentifier"
```

### Recommended Identifier Patterns

| Element Type | Pattern | Example |
|--------------|---------|---------|
| Tab bar items | `tab-{name}` | `tab-home`, `tab-items` |
| Toolbar actions | `action-{name}` | `action-add`, `action-sync` |
| Form fields | `field-{name}` | `field-title`, `field-email` |
| Cards/Options | `{context}-{name}` | `chooser-photo`, `chooser-manual` |
| Navigation | `nav-{destination}` | `nav-settings`, `nav-back` |

### Adding Identifiers

```swift
// Buttons
Button("Add") { ... }
    .accessibilityIdentifier("action-add")

// Option cards
AddItemOptionCard(title: "Photo", ...)
    .accessibilityIdentifier("chooser-\(title.lowercased())")

// Tab items
.tabItem { Label("Home", systemImage: "house") }
    .accessibilityIdentifier("tab-home")
```

## Phase 3: Element Finding Strategies

### Robust Element Discovery

```swift
func findElement(_ name: String, type: String = "button") -> XCUIElement {
    // Strategy 1: By accessibility identifier
    let byId = app.buttons.matching(identifier: name).firstMatch
    if byId.exists { return byId }

    // Strategy 2: By label
    let byLabel = app.buttons[name].firstMatch
    if byLabel.exists { return byLabel }

    // Strategy 3: By predicate (partial match)
    let predicate = NSPredicate(format: "label CONTAINS[c] %@", name)
    let byPredicate = app.buttons.matching(predicate).firstMatch
    if byPredicate.exists { return byPredicate }

    // Strategy 4: Any element type
    let anyElement = app.descendants(matching: .any)
        .matching(identifier: name).firstMatch

    return anyElement
}
```

## Phase 4: Common Issues Checklist

- [ ] Splash screen has `isRunningTests` check
- [ ] Onboarding checks for `--uitesting` argument
- [ ] Tutorials skip in UI test mode
- [ ] All interactive elements have accessibility identifiers
- [ ] Tab bar has `accessibilityIdentifier("main-tab-bar")`
- [ ] Navigation buttons are discoverable
- [ ] Sheets/modals have Cancel/Done buttons with standard labels

## Output

### Test Execution Choice
- [ ] **Parallel** - Faster, uses simulator clones (may be unstable)
- [ ] **Sequential** - Slower, single simulator (more stable)

### Environment Status
- [ ] `--uitesting` flag handled in app
- [ ] `-skip-splash` flag handled
- [ ] Onboarding bypass working
- [ ] Tutorial bypass working

### Accessibility Gaps Found
| File | Element | Recommendation |
|------|---------|----------------|
| | | |

### Test Stability Recommendations
1. Use `-parallel-testing-enabled NO` if seeing clone failures
2. Add accessibility identifiers to all interactive elements
3. Ensure onboarding/tutorials skip in `--uitesting` mode
