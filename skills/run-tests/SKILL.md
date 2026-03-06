---
name: run-tests
description: 'Run tests with smart execution strategies - parallel, sequential, or split (UI sequential + unit parallel). Triggers: "run tests", "run my tests", "execute tests".'
version: 2.1.0
author: Terry Nyberg
license: MIT
allowed-tools: [Bash, Glob, Grep, Read, Write, AskUserQuestion]
metadata:
  tier: execution
  category: testing
---

# Run Tests

> **Quick Ref:** Smart test execution with split strategies (UI sequential + unit parallel).

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

---

## Pre-flight: Git Safety Check

```bash
git status --short
```

If uncommitted changes exist:

```
AskUserQuestion with questions:
[
  {
    "question": "You have uncommitted changes. Commit before proceeding?",
    "header": "Git",
    "options": [
      {"label": "Commit first (Recommended)", "description": "Save current work so you can revert if this skill modifies files"},
      {"label": "Continue without committing", "description": "Proceed — I accept the risk"}
    ],
    "multiSelect": false
  }
]
```

If "Commit first": Ask for a commit message, stage changed files, and commit. Then proceed.

---

## Step 1: Detect Test Configuration

```bash
# Find available schemes and test targets
xcodebuild -list -json 2>/dev/null | head -50

# Find test files to identify target names
Glob pattern="**/*Tests.swift"
Glob pattern="**/*UITests*.swift"
```

Extract from the JSON output:
- **Scheme name** — from `schemes` array
- **Test targets** — from `targets` array (names ending in `Tests` or `UITests`)

If multiple schemes exist, confirm with the user:

```
AskUserQuestion with questions:
[
  {
    "question": "Which scheme should I test?",
    "header": "Scheme",
    "options": [
      {"label": "<detected_scheme_1>", "description": "Main app scheme"},
      {"label": "<detected_scheme_2>", "description": "Other scheme"}
    ],
    "multiSelect": false
  }
]
```

---

## Step 2: Choose Strategy

```
AskUserQuestion with questions:
[
  {
    "question": "Which test execution strategy?",
    "header": "Strategy",
    "options": [
      {"label": "Smart Split (Recommended)", "description": "UI tests sequential + unit tests parallel — best balance"},
      {"label": "All Sequential", "description": "Maximum stability, slowest execution"},
      {"label": "All Parallel", "description": "Fastest, may have simulator clone issues"},
      {"label": "Unit tests only", "description": "Skip UI tests — faster feedback"}
    ],
    "multiSelect": false
  }
]
```

---

## Step 3: Execute Tests

### Strategy: Smart Split (Recommended)

```bash
# Step 1: Run UI tests sequentially
xcodebuild test \
  -scheme <SCHEME> \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:<UI_TEST_TARGET> \
  -parallel-testing-enabled NO \
  2>&1 | tail -20

# Step 2: Run unit tests in parallel
xcodebuild test \
  -scheme <SCHEME> \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -skip-testing:<UI_TEST_TARGET> \
  -parallel-testing-enabled YES \
  2>&1 | tail -20
```

### Strategy: All Sequential

```bash
xcodebuild test \
  -scheme <SCHEME> \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -parallel-testing-enabled NO \
  2>&1 | tail -20
```

### Strategy: All Parallel

```bash
xcodebuild test \
  -scheme <SCHEME> \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -parallel-testing-enabled YES \
  -maximum-concurrent-test-simulator-destinations 2 \
  2>&1 | tail -20
```

### Strategy: Unit Tests Only

```bash
xcodebuild test \
  -scheme <SCHEME> \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -skip-testing:<UI_TEST_TARGET> \
  2>&1 | tail -20
```

---

## Step 4: Display Results

Parse the xcodebuild output and **display the results inline**:

```markdown
## Test Results

**Strategy:** Smart Split
**Scheme:** <SCHEME>
**Duration:** X minutes
**Status:** All Passing ✓ / X Failures ✗

| Target | Tests | Passed | Failed |
|--------|-------|--------|--------|
| Unit Tests | N | N | 0 |
| UI Tests | N | N | 0 |
| **Total** | **N** | **N** | **0** |
```

If failures occurred, list each with file references:

```markdown
## Failures

| # | Test | Error | File |
|---|------|-------|------|
| 1 | testName | Expected X but got Y | File.swift:45 |
```

### Read Failing Test Files

For each failure, read the test file to understand context:

```bash
Read file_path="path/to/FailingTest.swift"
```

---

## Step 5: Write Report (If Failures)

If any tests failed, write a report for tracking:

```bash
Write file_path=".agents/research/YYYY-MM-DD-test-results.md" content="[report]"
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
      {"label": "Debug failures", "description": "Investigate and fix failing tests"},
      {"label": "Re-run failed tests", "description": "Run only the failing tests again"},
      {"label": "Results are sufficient", "description": "I'll handle it from here"}
    ],
    "multiSelect": false
  }
]
```

---

## Pre-Run Cleanup (If Needed)

If experiencing simulator issues, offer cleanup:

```bash
# Kill zombie simulators
xcrun simctl shutdown all
killall Simulator 2>/dev/null

# Delete cloned simulators
xcrun simctl delete unavailable

# Optional: Clean DerivedData for this project
rm -rf ~/Library/Developer/Xcode/DerivedData/<PROJECT>-*
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Unable to boot simulator" | Run `xcrun simctl shutdown all` then retry |
| Parallel tests fail but sequential pass | Use Smart Split strategy |
| "No such module" error | Clean DerivedData and rebuild |
| UI tests time out | Increase `waitForExistence` timeout or use sequential mode |
| Can't find scheme | Run `xcodebuild -list` to see available schemes |
| Multiple test targets unclear | Check target names in `xcodebuild -list -json` output |
