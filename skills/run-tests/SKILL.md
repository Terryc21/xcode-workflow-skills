---
name: run-tests
description: Run tests with smart execution strategies - parallel, sequential, or split (UI sequential + unit parallel)
---

# Run Tests

Execute tests with configurable parallelization strategy.

## Execution Strategies

| Strategy | Flag | UI Tests | Unit Tests | Best For |
|----------|------|----------|------------|----------|
| **Smart Split** (Recommended) | `--split` | Sequential | Parallel | Daily development |
| **All Sequential** | `--sequential` | Sequential | Sequential | Maximum stability |
| **All Parallel** | `--parallel` | Parallel | Parallel | CI with clean state |

## Usage

Ask which strategy to use, then execute accordingly.

### Strategy 1: Smart Split (Recommended)

Best balance of speed and stability. UI tests run sequentially (avoids clone issues), unit tests run in parallel (fast).

```bash
# Step 1: Run UI tests sequentially
xcodebuild test \
  -scheme <SCHEME> \
  -destination 'platform=iOS Simulator,name=<SIMULATOR>' \
  -only-testing:<UI_TEST_TARGET> \
  -parallel-testing-enabled NO

# Step 2: Run unit tests in parallel
xcodebuild test \
  -scheme <SCHEME> \
  -destination 'platform=iOS Simulator,name=<SIMULATOR>' \
  -skip-testing:<UI_TEST_TARGET> \
  -parallel-testing-enabled YES
```

**Via XcodeBuildMCP:**
```
# UI tests sequential
test_sim({ extraArgs: ["-only-testing:StuffolioUITests", "-parallel-testing-enabled", "NO"] })

# Unit tests parallel
test_sim({ extraArgs: ["-skip-testing:StuffolioUITests", "-parallel-testing-enabled", "YES"] })
```

### Strategy 2: All Sequential

Maximum stability. Use when experiencing any test flakiness.

```bash
xcodebuild test \
  -scheme <SCHEME> \
  -destination 'platform=iOS Simulator,name=<SIMULATOR>' \
  -parallel-testing-enabled NO
```

**Via XcodeBuildMCP:**
```
test_sim({ extraArgs: ["-parallel-testing-enabled", "NO"] })
```

### Strategy 3: All Parallel

Fastest execution. Use with clean simulator state or in CI.

```bash
xcodebuild test \
  -scheme <SCHEME> \
  -destination 'platform=iOS Simulator,name=<SIMULATOR>' \
  -parallel-testing-enabled YES \
  -maximum-concurrent-test-simulator-destinations 2
```

**Via XcodeBuildMCP:**
```
test_sim({ extraArgs: ["-parallel-testing-enabled", "YES", "-maximum-concurrent-test-simulator-destinations", "2"] })
```

## Time Estimates

Based on Stuffolio (~4,700 total tests, ~195 UI tests):

| Strategy | Estimated Time | Notes |
|----------|---------------|-------|
| All Parallel | ~15-22 min | May have clone failures |
| Smart Split | ~50-60 min | UI sequential (~45 min) + unit parallel (~5 min) |
| All Sequential | ~60-75 min | Most stable, slowest |

**Why UI tests are slow:**
- Each test launches the app fresh (~2-3 sec)
- Simulator animations and delays
- `waitForExistence` timeouts (up to 3-5 sec each)
- Setup/teardown overhead

**Rule of thumb:** ~15-30 seconds per UI test when run sequentially.

## Pre-Run Cleanup (Optional)

If experiencing clone issues, run cleanup first:

```bash
# Kill zombie simulators
xcrun simctl shutdown all
killall Simulator 2>/dev/null

# Delete cloned simulators
xcrun simctl delete unavailable

# Optional: Clean DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/<PROJECT>-*
```

## Unattended Mode

To run tests while away from the computer, use `/run-tests --unattended`.

**What this does:**
- Skips the strategy selection prompt (uses Smart Split by default, or specify with `--sequential` / `--parallel`)
- Uses XcodeBuildMCP tools which don't require per-command approval
- Runs cleanup, then tests, then reports results

**Example invocations:**
```
/run-tests --unattended              # Smart Split (default)
/run-tests --unattended --sequential # All sequential
/run-tests --unattended --parallel   # All parallel
/run-tests --unattended --cleanup    # Run cleanup before tests
```

**Permissions required (approve once before leaving):**
| Tool | Permission | Approve With |
|------|------------|--------------|
| XcodeBuildMCP | `test_sim` | Auto-allowed (MCP tool) |
| XcodeBuildMCP | `boot_sim` | Auto-allowed (MCP tool) |
| Bash | `xcrun simctl` | "Always allow" when prompted |
| Bash | `killall Simulator` | "Always allow" when prompted |

**Tip:** If using `--cleanup`, approve the Bash permissions once, then Claude will remember for the session.

## Workflow

### Interactive Mode (default)
1. **Ask user** which strategy they want (default: Smart Split)
2. **Detect** the UI test target name from the project
3. **Execute** using XcodeBuildMCP or xcodebuild
4. **Report** results with pass/fail counts

### Unattended Mode (`--unattended`)
1. **Skip prompts** - use specified or default strategy
2. **Run cleanup** if `--cleanup` flag present
3. **Execute** using XcodeBuildMCP (no approval needed)
4. **Report** results when complete

## Auto-Detection

To find the UI test target:
```bash
# List schemes and targets
xcodebuild -list -project <PROJECT>.xcodeproj
```

Common UI test target patterns:
- `<AppName>UITests`
- `<AppName>-UITests`
- `UITests`
