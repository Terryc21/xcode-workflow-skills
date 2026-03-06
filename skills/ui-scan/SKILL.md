---
name: ui-scan
description: 'UI test environment setup and accessibility scan with recommendations for splash/onboarding bypass. Triggers: "ui scan", "accessibility scan", "ui test setup".'
version: 2.0.0
author: Terry Nyberg
license: MIT
allowed-tools: [Grep, Glob, Read, Write, AskUserQuestion]
metadata:
  tier: execution
  category: testing
---

# UI Scan

> **Quick Ref:** UI test environment setup: splash/onboarding bypass, accessibility identifier scan, element finding strategies.

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

---

## Step 1: Determine Scan Focus

```
AskUserQuestion with questions:
[
  {
    "question": "What would you like to scan for?",
    "header": "Focus",
    "options": [
      {"label": "Full scan (Recommended)", "description": "Accessibility identifiers + test environment setup + recommendations"},
      {"label": "Accessibility only", "description": "Scan for missing accessibility identifiers and labels"},
      {"label": "Test setup only", "description": "Check for onboarding/splash bypass support"}
    ],
    "multiSelect": false
  }
]
```

---

## Step 2: Scan for Missing Accessibility Identifiers

```bash
# Find buttons without accessibility identifiers
Grep pattern="Button\(" glob="**/*.swift" output_mode="files_with_matches"

# Find images without accessibility descriptions
Grep pattern="Image\(" glob="**/*.swift" output_mode="files_with_matches"

# Count existing accessibility label usage
Grep pattern="\.accessibilityLabel" glob="**/*.swift" output_mode="count"

# Count existing accessibility identifier usage
Grep pattern="\.accessibilityIdentifier" glob="**/*.swift" output_mode="count"

# Find hardcoded font sizes (Dynamic Type gap)
Grep pattern="\.font\(\.system\(size:" glob="**/*.swift" output_mode="content"
```

For each file with missing identifiers, read it to verify the finding and check surrounding context.

### Identifier Naming Patterns

| Element Type | Pattern | Example |
|--------------|---------|---------|
| Tab bar items | `tab-{name}` | `tab-home`, `tab-items` |
| Toolbar actions | `action-{name}` | `action-add`, `action-sync` |
| Form fields | `field-{name}` | `field-title`, `field-email` |
| Cards/Options | `{context}-{name}` | `chooser-photo`, `chooser-manual` |
| Navigation | `nav-{destination}` | `nav-settings`, `nav-back` |

---

## Step 3: Check Test Environment Setup

Scan for UI test bypass support:

```bash
# Check for UI testing launch argument handling
Grep pattern="uitesting|isUITesting|UI_TESTING" glob="**/*.swift" output_mode="content"

# Check for splash skip support
Grep pattern="skip-splash|skipSplash" glob="**/*.swift" output_mode="content"

# Check for onboarding bypass
Grep pattern="skipOnboarding|skip.*onboarding" glob="**/*.swift" output_mode="content" -i

# Find existing UI test files
Glob pattern="**/*UITests*.swift"
Glob pattern="**/*UITest*.swift"
```

### Required App-Side Support

If not already present, the app needs:

```swift
// Detect UI testing mode
private var isUITesting: Bool {
    ProcessInfo.processInfo.arguments.contains("--uitesting")
}
```

### Required Test-Side Setup

```swift
override func setUpWithError() throws {
    try super.setUpWithError()
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["--uitesting", "-skip-splash"]
    app.launch()
}
```

---

## Step 4: Element Finding Strategies

Check which element finding strategies the existing tests use:

```bash
# Check for identifier-based finding
Grep pattern="\.matching\(identifier:" glob="**/*UITest*.swift" output_mode="count"

# Check for label-based finding
Grep pattern="app\.(buttons|staticTexts|textFields)\[" glob="**/*UITest*.swift" output_mode="count"

# Check for predicate-based finding
Grep pattern="NSPredicate" glob="**/*UITest*.swift" output_mode="count"
```

### Recommended Strategy Priority

1. **Accessibility identifier** — most stable across localizations
2. **Label text** — works for static labels but breaks with i18n
3. **Predicate** — partial match, use as fallback

---

## Step 5: Generate Report

Write findings to `.agents/research/YYYY-MM-DD-ui-scan.md`:

```markdown
# UI Scan Report

**Date:** YYYY-MM-DD

## Accessibility Identifier Coverage

| Metric | Count |
|--------|-------|
| Files with Buttons | N |
| Files with .accessibilityIdentifier | N |
| Files with .accessibilityLabel | N |
| Coverage estimate | X% |

## Missing Identifiers

| File | Element Type | Recommendation |
|------|-------------|----------------|
| [path] | Button | Add .accessibilityIdentifier("action-name") |
| [path] | Image | Add .accessibilityLabel("description") |

## Test Environment Status

| Check | Status |
|-------|--------|
| `--uitesting` argument handled | Yes/No |
| Splash bypass | Yes/No |
| Onboarding bypass | Yes/No |
| Tutorial bypass | Yes/No |

## Recommendations

1. [Priority recommendation]
2. [Next recommendation]
```

---

## Step 6: Follow-up

```
AskUserQuestion with questions:
[
  {
    "question": "How would you like to proceed?",
    "header": "Next",
    "options": [
      {"label": "Add missing identifiers", "description": "Walk through each gap and add identifiers"},
      {"label": "Set up test environment", "description": "Add uitesting bypass to the app"},
      {"label": "Report is sufficient", "description": "I'll handle changes manually"}
    ],
    "multiSelect": false
  }
]
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| No UI test files found | Create a UI test target in Xcode first |
| Too many missing identifiers | Prioritize interactive elements (buttons, fields, nav) first |
| Onboarding always appears in tests | Add `--uitesting` argument check to onboarding gate |
| Elements not findable by tests | Use `.accessibilityIdentifier()` instead of label-based finding |
