---
name: run-tests
description: 'Run tests with smart execution strategies - parallel, sequential, or split (UI sequential + unit parallel). Triggers: "run tests", "run my tests", "execute tests".'
version: 2.0.0
author: Terry Nyberg
license: MIT
allowed-tools: [Bash, Glob, Grep, Read, AskUserQuestion]
metadata:
  tier: execution
  category: testing
---

# Run Tests

> **Quick Ref:** Smart test execution with split strategies (UI sequential + unit parallel).

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

---

## Step 1: Detect Test Configuration

```bash
# Find available schemes
xcodebuild -list -json 2>/dev/null | head -30

# Find test targets
Glob pattern="**/*Tests.swift"
Glob pattern="**/*UITests*.swift"
```

Identify:
- **Scheme name** — from `xcodebuild -list`
- **UI test target** — typically `<AppName>UITests`
- **Unit test target** — typically `<AppName>Tests`

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

## Step 4: Report Results

Parse the output and present:

```markdown
## Test Results

**Strategy:** Smart Split
**Duration:** X minutes

| Target | Tests | Passed | Failed |
|--------|-------|--------|--------|
| Unit Tests | N | N | 0 |
| UI Tests | N | N | 0 |
| **Total** | **N** | **N** | **0** |
```

If failures occurred, list each:

```markdown
## Failures

| Test | Error | File |
|------|-------|------|
| testName | Expected X but got Y | File.swift:45 |
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
