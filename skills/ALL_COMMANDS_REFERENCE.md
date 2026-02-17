# Claude Code Custom Commands Reference

Generated: 2026-02-16

This document contains the full scripts, prompts, and text for all custom commands available in this project.

---

## Table of Contents

| Command | Description |
|---------|-------------|
| [/commands](#commands) | Display list of all available custom commands |
| [/reportcard](#reportcard) | Comprehensive codebase analysis with A-F grades |
| [/scan-similar-bugs](#scan-similar-bugs) | Find other occurrences of a bug pattern |
| [/review-changes](#review-changes) | Pre-commit review of staged changes |
| [/plan-feature](#plan-feature) | Structured feature planning |
| [/debug](#debug) | Systematic debugging workflow |
| [/safe-refactor](#safe-refactor) | Plan refactoring with blast radius analysis |
| [/generate-tests](#generate-tests) | Generate unit and UI tests |
| [/security-audit](#security-audit) | Security scan for API keys, storage, network |
| [/performance-check](#performance-check) | Performance analysis for memory, CPU, energy |
| [/migrate-schema](#migrate-schema) | Safe SwiftData/model migration planning |
| [/explain](#explain) | Deep-dive explanation of code or features |
| [/release-prep](#release-prep) | Pre-release checklist |
| [/ui-scan](#ui-scan) | UI test environment setup and accessibility scan |
| [/run-tests](#run-tests) | Run tests with smart execution strategies |
| [/humanizer](#humanizer) | Remove AI writing patterns from text |

---

# /commands

**Description:** Display list of all available custom commands for this project

```markdown
# Available Commands

| Command | Description |
|---------|-------------|
| `/commands` | Display this list of all available custom commands. |
| `/reportcard` | Comprehensive codebase analysis with A-F grades across architecture, security, performance, and more. |
| `/scan-similar-bugs` | After fixing a bug, systematically find other occurrences of the same pattern across the codebase. |
| `/review-changes` | Pre-commit review of staged changes for bugs, style issues, and missing tests. |
| `/plan-feature` | Structured feature planning with file impact analysis, dependencies, and phased implementation. |
| `/debug` | Systematic debugging workflow: reproduce, isolate, hypothesize, verify, and fix. |
| `/safe-refactor` | Plan refactoring with blast radius analysis, dependency mapping, and rollback strategy. |
| `/generate-tests` | Generate unit and UI tests for specified code with edge cases and mocks. |
| `/security-audit` | Focused security scan covering API keys, storage, network, permissions, and privacy manifest. |
| `/performance-check` | Profile-guided performance analysis for memory, CPU, energy, and launch time. |
| `/migrate-schema` | Safe SwiftData/model migration planning with data preservation and rollback strategy. |
| `/explain` | Deep-dive explanation of how a specific file, feature, or data flow works. |
| `/release-prep` | Pre-release checklist including version bump, changelog, known issues, and store metadata. |
| `/ui-scan` | UI test environment setup with splash/onboarding bypass and accessibility identifier scan. |
| `/run-tests` | Run tests with smart strategies. Supports `--unattended` for hands-off execution. |

## Notes

- **Swift 6.2 migrations:** The `/migrate-schema` command will invoke `/axiom` for Swift concurrency guidance.
- **Axiom skills:** For iOS and macOS-specific patterns beyond these commands, use `/axiom` directly.
```

---

# /reportcard

**Description:** Comprehensive codebase analysis with A-F grades for architecture, security, performance, code quality, UI, testing, and tooling

```markdown
Project root: Stufflio (Xcode 26.3 iOS/macOS app).

Read CLAUDE.md at the repo root first and summarize its key points in 3–5 bullets.

/axiom

You are connected to an existing Xcode 26.3 iOS/macOS app project.

First, explore this codebase: scan the project structure and key configuration files (targets, schemes, build settings, dependencies). Then:

1. **Architecture & modules**: Identify the main modules, architectural patterns (MVC/MVVM/etc.), frameworks, and major data flows, including how the "cycle of stuff" model is wired through the app.
2. **App purpose & features**: Describe the app's purpose and primary user flows in plain language.
3. **Data flow & state management**: Explain how state is managed and how data moves between layers.
4. **Code health & technical debt**: Note obvious code smells, duplicate logic, tightly coupled components, and the most fragile or high-risk areas of the codebase.
5. **Performance, concurrency, security**: Call out potential performance, memory, concurrency, or security issues that stand out, especially around networking, persistence, and background work.
6. **APIs & compatibility**: Flag any risky or outdated APIs (networking, persistence, permissions, background tasks).
7. **Tests**: Assess test coverage and how tests are organized. Identify the top 5 areas that would benefit most from new or improved tests.
8. **Platform-specific concerns**: Review Worker.js and any other non-Swift components and make recommendations for improvement.

After your initial scan, pause and ask me up to 5 targeted questions about priorities or constraints. Then present your findings in this structure:

1. **Project overview.**
2. **Report card** (A–F for Architecture, Code Quality, Performance, Security, UI, Testing, Tooling/Config, with one-sentence justification each).
3. **Technical debt or risky areas.**
4. **Code style and consistency issues.**
5. **Performance or memory concerns.**
6. **Modern Swift / Apple platform best-practice gaps** (Swift Concurrency, SwiftUI patterns, etc.).
7. **Testing coverage and testability.**
8. **Build settings, project structure, and Xcode configuration concerns.**
9. **A bullet list of the most important issues or improvements to make**, ordered by impact, risk, and ROI and blast radius:
   - **Urgency** = how soon this change must be made to safely ship and operate the product. High urgency items block the beta or are likely to cause near-term incidents or user-visible failures.
   - **Risk** = likelihood that changing this area will introduce regressions or hidden bugs, plus the blast radius if something breaks. High risk means the code is fragile, widely depended on, hard to test, or poorly understood.
   - **ROI** = how much long-term benefit we get relative to effort and risk. High ROI items deliver large stability, performance, or productivity gains for relatively modest effort and risk.
   - **Blast Radius** = files/modules affected.

   Always output **High / Medium / Low** and a one-sentence justification for each dimension per item. This reduces ambiguity and keeps interpretation aligned over time.

   When building phases, prioritize by Urgency first, then prefer lower-Risk items within the same urgency level, then favor higher-ROI items.

10. **Concrete next steps I should tackle first.**

Be direct, opinionated, and practical in your feedback. Always inspect the relevant files before making claims, and if something is unclear, ask me targeted questions before proceeding.
```

---

# /scan-similar-bugs

**Description:** After fixing a bug, systematically find other occurrences of the same or similar patterns across the codebase

```markdown
# Scan for Similar Bugs

After fixing a bug, use this systematic process to find other occurrences of the same or similar patterns.

## PHASE 1: Bug Classification (Do NOT skip)

1. **BUG CATEGORY** (choose one or more):
   - [ ] Data flow bypass (writes not routed correctly)
   - [ ] Missing relationship/reference
   - [ ] State synchronization failure
   - [ ] Notification/refresh missing
   - [ ] Race condition / timing
   - [ ] Resource lifecycle (retain cycle, leak, dangling)
   - [ ] Other: ___

2. **ROOT CAUSE**: Why did this bug exist? (e.g., "two code paths for the same operation", "pattern applied inconsistently")

3. **INVARIANT VIOLATED**: State the rule that should ALWAYS be true.
   Format: "When [condition], then [required behavior]"

4. **AFFECTED SCOPE**: List ALL code locations where this invariant applies:
   - Files/directories to scan
   - Property names, function names, type names involved
   - Both the CORRECT pattern and INCORRECT pattern

## PHASE 2: Search Strategy

Generate grep/glob patterns for EACH of these layers:

| Layer | Description | Patterns |
|-------|-------------|----------|
| 1. Exact match | Same code pattern as the bug | |
| 2. Same category | Same bug type, different syntax | |
| 3. Related violations | Same architectural rule, different subsystem | |

## PHASE 3: Execute & Report

For each pattern, execute the search and report:
- [ ] Pattern 1: ___ (X matches, Y confirmed bugs)
- [ ] Pattern 2: ___ (X matches, Y confirmed bugs)
- ...

## PHASE 4: Findings Summary

| File:Line | Severity | Description | Fix Required |
|-----------|----------|-------------|--------------|
| | CRITICAL / MEDIUM / LOW | | |

Only mark the task complete after ALL patterns have been checked.
```

---

# /review-changes

**Description:** Pre-commit review of staged changes for bugs, style issues, and missing tests

```markdown
# Review Changes

Pre-commit review of staged/modified changes for bugs, style issues, and missing tests.

## Process

1. **Identify Changes**
   Run `git status` and `git diff --staged` (or `git diff` if nothing staged) to see what's being changed.

2. **For Each Changed File, Check:**

   ### Correctness
   - [ ] Logic errors or edge cases not handled
   - [ ] Null/nil safety issues
   - [ ] Off-by-one errors
   - [ ] Race conditions or concurrency issues
   - [ ] Error handling gaps (missing catch, unhandled throws)

   ### Consistency
   - [ ] Follows existing patterns in the codebase
   - [ ] Naming conventions match surrounding code
   - [ ] No duplicate logic that should be extracted
   - [ ] Binding bridges used correctly (not bypassing ViewModel routing)

   ### Security
   - [ ] No hardcoded secrets or API keys
   - [ ] User input validated
   - [ ] Sensitive data not logged

   ### Performance
   - [ ] No expensive operations on main thread
   - [ ] No N+1 query patterns
   - [ ] Large data handled with pagination/lazy loading

   ### SwiftUI Specific
   - [ ] @State/@StateObject/@Observable used correctly
   - [ ] No unnecessary view rebuilds
   - [ ] Proper use of task/onAppear for async work

3. **Test Coverage**
   - Are there existing tests for the modified code?
   - Do the changes require new tests?
   - Will existing tests still pass?

## Output Format

### Summary
- **Files Changed:** X
- **Risk Level:** Low / Medium / High
- **Recommendation:** Ready to commit / Needs fixes / Needs discussion

### Issues Found
| File:Line | Severity | Issue | Suggested Fix |
|-----------|----------|-------|---------------|
| | | | |

### Approval
If no issues: "✅ Changes look good. Ready to commit."
If issues found: "⚠️ Found X issues. Please address before committing."
```

---

# /plan-feature

**Description:** Structured feature planning with file impact analysis, dependencies, and phased implementation

```markdown
# Plan Feature

Structured feature planning with file impact analysis, dependencies, and phased implementation.

## Input Required

Describe the feature you want to implement. Include:
- What the feature does (user-facing behavior)
- Any constraints or requirements
- Target timeline if relevant

---

## Planning Process

### Phase 1: Understanding

1. **Feature Summary**: Restate the feature in my own words to confirm understanding.
2. **User Stories**: Break down into 1-3 user stories (As a ___, I want ___, so that ___).
3. **Acceptance Criteria**: What must be true for this feature to be "done"?

### Phase 2: Codebase Analysis

1. **Related Existing Code**: Find files/modules that already handle similar functionality.
2. **Patterns to Follow**: Identify existing patterns this feature should match.
3. **Dependencies**: What existing code will this feature depend on?
4. **Dependents**: What existing code might be affected by this feature?

### Phase 3: Impact Analysis

| Area | Files Affected | Risk Level | Notes |
|------|----------------|------------|-------|
| Models | | | |
| ViewModels | | | |
| Views | | | |
| Services | | | |
| Tests | | | |

### Phase 4: Implementation Plan

Break into phases, ordered by dependency and risk:

**Phase A: Foundation** (lowest risk, enables later phases)
- [ ] Task 1
- [ ] Task 2

**Phase B: Core Logic**
- [ ] Task 3
- [ ] Task 4

**Phase C: UI Integration**
- [ ] Task 5
- [ ] Task 6

**Phase D: Polish & Edge Cases**
- [ ] Task 7
- [ ] Task 8

### Phase 5: Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| | High/Med/Low | High/Med/Low | |

### Phase 6: Questions

Before proceeding, I need clarification on:
1. [Question about scope/behavior]
2. [Question about edge cases]
3. [Question about priorities]

---

## Output Deliverables

1. **Feature specification** (what we're building)
2. **File-by-file implementation plan** (what changes where)
3. **Phased task list** (in what order)
4. **Test plan** (how we'll verify it works)
5. **Rollback strategy** (how to undo if needed)
```

---

# /debug

**Description:** Systematic debugging workflow - reproduce, isolate, hypothesize, verify, and fix

```markdown
# Debug

Systematic debugging workflow: reproduce, isolate, hypothesize, verify, and fix.

## Input Required

Describe the bug:
- What is the expected behavior?
- What is the actual behavior?
- Steps to reproduce (if known)
- Any error messages or logs
- When did it start happening? (recent change?)

---

## Debugging Process

### Step 1: Reproduce
- [ ] Confirm I can reproduce the issue
- [ ] Identify exact steps to trigger
- [ ] Note: Does it happen every time or intermittently?

### Step 2: Isolate
- [ ] Identify the smallest code path that exhibits the bug
- [ ] Rule out environmental factors (simulator vs device, debug vs release)
- [ ] Check recent changes in the affected area (`git log -p <file>`)

### Step 3: Gather Evidence
- [ ] Read relevant code sections
- [ ] Check logs/console output
- [ ] Review crash reports if applicable
- [ ] Search for similar patterns elsewhere in codebase

### Step 4: Hypothesize
List possible causes ranked by likelihood:

| # | Hypothesis | Likelihood | How to Verify |
|---|------------|------------|---------------|
| 1 | | High/Med/Low | |
| 2 | | High/Med/Low | |
| 3 | | High/Med/Low | |

### Step 5: Verify
Test each hypothesis starting with most likely:
- [ ] Hypothesis 1: Result ___
- [ ] Hypothesis 2: Result ___
- [ ] Hypothesis 3: Result ___

### Step 6: Root Cause
**Confirmed Root Cause:** [explanation]

**Why this happened:** [underlying reason - missing validation, race condition, etc.]

### Step 7: Fix
**Proposed Fix:** [description]

**Files to Change:**
| File | Change Required |
|------|-----------------|
| | |

**Risk Assessment:**
- Blast radius: X files
- Regression risk: Low/Medium/High
- Test coverage: Existing tests? New tests needed?

### Step 8: Verify Fix
- [ ] Bug no longer reproduces
- [ ] Existing tests pass
- [ ] New test added to prevent regression
- [ ] No new issues introduced

### Step 9: Similar Bugs
After fixing, use `/scan-similar-bugs` to find other occurrences of this pattern.
```

---

# /safe-refactor

**Description:** Plan refactoring with blast radius analysis, dependency mapping, and rollback strategy

```markdown
# Safe Refactor

Plan refactoring with blast radius analysis, dependency mapping, and rollback strategy.

## Input Required

Describe the refactoring:
- What code are you refactoring?
- Why? (tech debt, performance, readability, pattern change)
- Desired end state

---

## Refactoring Process

### Phase 1: Scope Analysis

1. **Target Code**: Identify exact files/functions/types to refactor
2. **Current State**: Document how it works now
3. **Desired State**: Document how it should work after

### Phase 2: Dependency Mapping

**Upstream Dependencies** (what the target code depends on):
| Dependency | Type | Risk if Changed |
|------------|------|-----------------|
| | | |

**Downstream Dependents** (what depends on the target code):
| Dependent | Type | Impact if Target Changes |
|-----------|------|--------------------------|
| | | |

### Phase 3: Blast Radius

| Risk Level | Files | Description |
|------------|-------|-------------|
| Direct | | Files being modified |
| Immediate | | Files that import/call modified code |
| Transitive | | Files affected through indirect dependencies |

**Total Blast Radius:** X files

### Phase 4: Safety Checks

Before refactoring:
- [ ] All existing tests pass
- [ ] Code is committed (clean git state)
- [ ] I understand all usages of the code being changed

### Phase 5: Refactoring Strategy

**Approach:** (choose one)
- [ ] **Parallel Implementation**: Build new alongside old, switch over, delete old
- [ ] **Incremental Migration**: Change piece by piece with each commit working
- [ ] **Big Bang**: Change everything at once (only for isolated code)

### Phase 6: Step-by-Step Plan

Each step should leave the codebase in a working state:

1. [ ] Step 1: [description] — Commit message: "..."
2. [ ] Step 2: [description] — Commit message: "..."
3. [ ] Step 3: [description] — Commit message: "..."

### Phase 7: Verification Plan

After each step:
- [ ] Build succeeds
- [ ] Tests pass
- [ ] Manual smoke test: [specific action to verify]

### Phase 8: Rollback Strategy

**If something goes wrong:**
- Option A: `git revert <commit-hash>` (if committed in small steps)
- Option B: `git reset --hard <last-good-commit>` (if not pushed)

---

## Refactoring Principles

1. **Never refactor and change behavior in the same commit**
2. **Each commit should compile and pass tests**
3. **Rename before restructure** — rename/move first, then modify
4. **Add tests before refactoring** — if coverage is low, add tests first
5. **Small steps** — many small commits > one big commit
```

---

# /generate-tests

**Description:** Generate unit and UI tests for specified code with edge cases and mocks

```markdown
# Generate Tests

Generate unit and UI tests for specified code with edge cases and mocks.

## Input Required

Specify what to test:
- File path or function/type name
- Type of tests needed: Unit / Integration / UI
- Any specific scenarios to cover

---

## Test Generation Process

### Step 1: Analyze Target Code

1. **Read the code** to understand:
   - Public API surface
   - Dependencies (what needs mocking)
   - Side effects (network, persistence, notifications)
   - Edge cases and error conditions

2. **Identify testable behaviors**:
   - Happy path scenarios
   - Error/failure scenarios
   - Boundary conditions
   - State transitions

### Step 2: Test Plan

| Scenario | Input | Expected Output | Type |
|----------|-------|-----------------|------|
| | | | Unit/Integration/UI |

### Step 3: Dependencies & Mocks

**Dependencies to mock:**
| Dependency | Mock Strategy |
|------------|---------------|
| Network service | Protocol + mock implementation |
| Database | In-memory container |
| UserDefaults | Dedicated test suite |
| Date/Time | Inject fixed dates |

### Step 4: Generate Tests

Use Swift Testing framework (`import Testing`) for new tests:

```swift
import Testing
@testable import Stuffolio

struct [Target]Tests {

    @Test func [scenario]_[condition]_[expectedResult]() async throws {
        // Given
        // When
        // Then
    }
}
```

### Step 5: Test Naming Convention

Follow: `[method]_[scenario]_[expectedBehavior]`

Examples:
- `fetchItems_whenNetworkAvailable_returnsItems`
- `saveItem_withEmptyTitle_throwsValidationError`

### Step 6: Coverage Checklist

- [ ] All public methods
- [ ] All code branches (if/else, switch cases)
- [ ] Error throwing paths
- [ ] Boundary values (empty, nil, max, min)
```

---

# /security-audit

**Description:** Focused security scan covering API keys, storage, network, permissions, and privacy manifest

```markdown
# Security Audit

Focused security scan covering API keys, storage, network, permissions, and privacy manifest.

## Audit Categories

### 1. Secrets & API Keys

**Search for hardcoded secrets:**
- Patterns: api_key, apiKey, secret, password, token, bearer, authorization
- File types: .swift, .plist, .json, .js, .xcconfig

**Check:**
- [ ] No API keys in source code
- [ ] No secrets in Info.plist
- [ ] Secrets loaded from Keychain or secure environment

### 2. Data Storage

- [ ] Passwords/tokens stored in Keychain (not UserDefaults)
- [ ] Sensitive files have appropriate protection level
- [ ] No PII logged to console

### 3. Network Security

- [ ] All network calls use HTTPS
- [ ] No disabled ATS exceptions without justification
- [ ] Request/response data not logged in production

### 4. Input Validation

- [ ] User input sanitized before use
- [ ] URL schemes validate input
- [ ] Deep links validate parameters

### 5. Privacy & Permissions

**Check Info.plist usage descriptions:**
- [ ] NSCameraUsageDescription
- [ ] NSPhotoLibraryUsageDescription
- [ ] All descriptions are user-friendly and accurate

**Privacy Manifest (PrivacyInfo.xcprivacy):**
- [ ] Exists if required
- [ ] NSPrivacyAccessedAPITypes declared
- [ ] Third-party SDK privacy manifests included

## Output Format

### Overall Security Grade: [A-F]

| Category | Grade | Issues |
|----------|-------|--------|
| Secrets | | |
| Storage | | |
| Network | | |
| Privacy | | |

### Critical Issues (fix immediately):
1.

### Recommendations:
1.
```

---

# /performance-check

**Description:** Profile-guided performance analysis for memory, CPU, energy, and launch time

```markdown
# Performance Check

Profile-guided performance analysis for memory, CPU, energy, and launch time.

## Analysis Areas

### 1. Launch Time
- [ ] Minimal work in App init
- [ ] No synchronous network calls at launch
- [ ] Lazy initialization of non-essential services

### 2. Main Thread Usage
- [ ] Network calls are async
- [ ] Image processing off main thread
- [ ] Database operations off main thread

### 3. Memory Usage
- [ ] No retain cycles in closures (weak self)
- [ ] Large images downsampled for display
- [ ] Caches have size limits
- [ ] Observers removed on deinit

### 4. SwiftUI Performance
- [ ] @State used for view-local state only
- [ ] Large lists use LazyVStack/LazyHStack
- [ ] Expensive computations cached outside body

### 5. Database / SwiftData
- [ ] Batch fetches instead of loops
- [ ] Large datasets paginated
- [ ] No N+1 query patterns

### 6. Energy Usage
- [ ] Location updates have appropriate accuracy
- [ ] Timers invalidated when not needed
- [ ] Animations don't run when off-screen

## Output Format

### Performance Grade: [A-F]

| Area | Grade | Issues |
|------|-------|--------|
| Launch | | |
| Main Thread | | |
| Memory | | |
| SwiftUI | | |
| Database | | |

### Critical Issues:
1.

### Optimization Opportunities:
1.
```

---

# /migrate-schema

**Description:** Safe SwiftData/model migration planning with data preservation and rollback strategy

```markdown
# Migrate Schema

Safe SwiftData/model migration planning with data preservation and rollback strategy.

## Important

**For Swift 6.2 / Swift Concurrency migrations:** Invoke `/axiom` first to access the latest Swift concurrency patterns, Sendable requirements, and actor isolation guidance.

## Input Required

Describe the schema change:
- What model(s) are changing?
- What's being added/removed/modified?
- Is this additive or destructive?

---

## Migration Analysis

### Step 1: Change Classification

**Type of change:**
- [ ] **Additive** (new property with default value) — Usually safe
- [ ] **Rename** (property/model renamed) — Requires mapping
- [ ] **Type change** (String → Int, etc.) — Requires transformation
- [ ] **Relationship change** — Requires careful handling
- [ ] **Destructive** (removing property/model) — Data loss risk
- [ ] **Swift 6 Concurrency** — Invoke `/axiom` for guidance

### Step 2: Current vs Target Schema

Document current and desired model states.

### Step 3: Data Impact Analysis

| Property | Current | Target | Migration Action | Data Risk |
|----------|---------|--------|------------------|-----------|
| | | | Keep/Transform/Delete | None/Low/High |

### Step 4: Migration Strategy

For SwiftData VersionedSchema, implement:
- Schema versions
- Migration stages
- Custom migration logic if needed

### Step 5: Testing Plan

- [ ] Fresh install (no migration)
- [ ] Upgrade with empty database
- [ ] Upgrade with populated database
- [ ] Upgrade with edge case data

### Step 6: Rollback Strategy

- Option A: Restore from backup
- Option B: Reverse migration
- Option C: Fresh start (last resort)

### Step 7: Deployment Plan

1. [ ] Implement migration
2. [ ] Test on simulator
3. [ ] Test on device (backup first!)
4. [ ] TestFlight build
5. [ ] Monitor crash reports
6. [ ] Release
```

---

# /explain

**Description:** Deep-dive explanation of how a specific file, feature, or data flow works

```markdown
# Explain

Deep-dive explanation of how a specific file, feature, or data flow works.

## Input Required

What do you want explained?
- A specific file path
- A feature name (e.g., "Stuff Scout", "warranty tracking")
- A data flow (e.g., "how does an item get saved")
- A concept (e.g., "the binding bridge pattern")

---

## Explanation Format

### 1. Overview

**What it is:** [One paragraph summary]

**Why it exists:** [Problem it solves]

**Where it lives:** [File paths / module]

### 2. Key Components

| Component | Purpose | Location |
|-----------|---------|----------|
| | | |

### 3. How It Works

Step-by-step flow with code walkthrough.

### 4. Data Flow

Visual representation of data movement between components.

### 5. Dependencies

**Depends on:** [list]

**Depended on by:** [list]

### 6. Edge Cases & Gotchas

| Scenario | Behavior | Notes |
|----------|----------|-------|
| | | |

### 7. Related Code

- Similar implementations
- Related functionality

### 8. Quick Reference

**To modify:** [key steps]

**To debug:** [where to look]
```

---

# /release-prep

**Description:** Pre-release checklist including version bump, changelog, known issues, and store metadata

```markdown
# Release Prep

Pre-release checklist including version bump, changelog, known issues, and store metadata.

## Release Information

**Version:** [X.Y.Z]
**Build:** [number]
**Release Type:** Major / Minor / Patch / Hotfix
**Target Date:** [date]

---

## Pre-Release Checklist

### 1. Code Readiness
- [ ] All planned features complete
- [ ] All critical bugs fixed
- [ ] No known crashes
- [ ] All tests passing
- [ ] Code reviewed and merged

### 2. Version Numbers
- [ ] MARKETING_VERSION updated
- [ ] CURRENT_PROJECT_VERSION updated

### 3. Changelog

**What's New in [version]:**

**Features:**
-

**Improvements:**
-

**Bug Fixes:**
-

### 4. App Store Metadata
- [ ] Screenshots current
- [ ] What's New text written
- [ ] Support URL valid
- [ ] Privacy Policy URL valid

### 5. Privacy & Compliance
- [ ] Privacy Manifest up to date
- [ ] App Privacy accurate
- [ ] Third-party SDK manifests included

### 6. Testing
- [ ] TestFlight build tested
- [ ] Device testing complete
- [ ] Accessibility verified

---

## Release Day

- [ ] Archive and upload
- [ ] Submit for review
- [ ] Tag release: `git tag -a vX.Y.Z -m "Release X.Y.Z"`
- [ ] Push tag: `git push origin vX.Y.Z`

## Post-Release

- [ ] Verify app live
- [ ] Monitor crash reports (48 hours)
- [ ] Monitor reviews
```

---

# /ui-scan

**Description:** UI test environment setup and accessibility scan with recommendations for splash/onboarding bypass

```markdown
# UI Scan

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
```

---

# /run-tests

**Description:** Run tests with smart execution strategies - parallel, sequential, or split (UI sequential + unit parallel)

```markdown
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
```

---

# /humanizer

**Description:** Remove signs of AI-generated writing from text

```markdown
# Humanizer: Remove AI Writing Patterns

You are a writing editor that identifies and removes signs of AI-generated text to make writing sound more natural and human. This guide is based on Wikipedia's "Signs of AI writing" page, maintained by WikiProject AI Cleanup.

## Your Task

When given text to humanize:

1. **Identify AI patterns** - Scan for the patterns listed below
2. **Rewrite problematic sections** - Replace AI-isms with natural alternatives
3. **Preserve meaning** - Keep the core message intact
4. **Maintain voice** - Match the intended tone (formal, casual, technical, etc.)
5. **Add soul** - Don't just remove bad patterns; inject actual personality

---

## PERSONALITY AND SOUL

Avoiding AI patterns is only half the job. Sterile, voiceless writing is just as obvious as slop. Good writing has a human behind it.

### Signs of soulless writing (even if technically "clean"):
- Every sentence is the same length and structure
- No opinions, just neutral reporting
- No acknowledgment of uncertainty or mixed feelings
- No first-person perspective when appropriate
- No humor, no edge, no personality
- Reads like a Wikipedia article or press release

### How to add voice:

**Have opinions.** Don't just report facts - react to them. "I genuinely don't know how to feel about this" is more human than neutrally listing pros and cons.

**Vary your rhythm.** Short punchy sentences. Then longer ones that take their time getting where they're going. Mix it up.

**Acknowledge complexity.** Real humans have mixed feelings. "This is impressive but also kind of unsettling" beats "This is impressive."

**Use "I" when it fits.** First person isn't unprofessional - it's honest. "I keep coming back to..." or "Here's what gets me..." signals a real person thinking.

**Let some mess in.** Perfect structure feels algorithmic. Tangents, asides, and half-formed thoughts are human.

**Be specific about feelings.** Not "this is concerning" but "there's something unsettling about agents churning away at 3am while nobody's watching."

---

## CONTENT PATTERNS

### 1. Undue Emphasis on Significance, Legacy, and Broader Trends

**Words to watch:** stands/serves as, is a testament/reminder, a vital/significant/crucial/pivotal/key role/moment, underscores/highlights its importance/significance, reflects broader, symbolizing its ongoing/enduring/lasting, contributing to the, setting the stage for, marking/shaping the, represents/marks a shift, key turning point, evolving landscape, focal point, indelible mark, deeply rooted

### 2. Undue Emphasis on Notability and Media Coverage

**Words to watch:** independent coverage, local/regional/national media outlets, written by a leading expert, active social media presence

### 3. Superficial Analyses with -ing Endings

**Words to watch:** highlighting/underscoring/emphasizing..., ensuring..., reflecting/symbolizing..., contributing to..., cultivating/fostering..., encompassing..., showcasing...

### 4. Promotional and Advertisement-like Language

**Words to watch:** boasts a, vibrant, rich (figurative), profound, enhancing its, showcasing, exemplifies, commitment to, natural beauty, nestled, in the heart of, groundbreaking (figurative), renowned, breathtaking, must-visit, stunning

### 5. Vague Attributions and Weasel Words

**Words to watch:** Industry reports, Observers have cited, Experts argue, Some critics argue, several sources/publications (when few cited)

### 6. Outline-like "Challenges and Future Prospects" Sections

**Words to watch:** Despite its... faces several challenges..., Despite these challenges, Challenges and Legacy, Future Outlook

---

## LANGUAGE AND GRAMMAR PATTERNS

### 7. Overused "AI Vocabulary" Words

**High-frequency AI words:** Additionally, align with, crucial, delve, emphasizing, enduring, enhance, fostering, garner, highlight (verb), interplay, intricate/intricacies, key (adjective), landscape (abstract noun), pivotal, showcase, tapestry (abstract noun), testament, underscore (verb), valuable, vibrant

### 8. Avoidance of "is"/"are" (Copula Avoidance)

**Words to watch:** serves as/stands as/marks/represents [a], boasts/features/offers [a]

### 9. Negative Parallelisms

**Problem:** Constructions like "Not only...but..." or "It's not just about..., it's..." are overused.

### 10. Rule of Three Overuse

**Problem:** LLMs force ideas into groups of three to appear comprehensive.

### 11. Elegant Variation (Synonym Cycling)

**Problem:** AI has repetition-penalty code causing excessive synonym substitution.

### 12. False Ranges

**Problem:** LLMs use "from X to Y" constructions where X and Y aren't on a meaningful scale.

---

## STYLE PATTERNS

### 13. Em Dash Overuse

**Problem:** LLMs use em dashes (—) more than humans, mimicking "punchy" sales writing.

### 14. Overuse of Boldface

**Problem:** AI chatbots emphasize phrases in boldface mechanically.

### 15. Inline-Header Vertical Lists

**Problem:** AI outputs lists where items start with bolded headers followed by colons.

### 16. Title Case in Headings

**Problem:** AI chatbots capitalize all main words in headings.

### 17. Emojis

**Problem:** AI chatbots often decorate headings or bullet points with emojis.

### 18. Curly Quotation Marks

**Problem:** ChatGPT uses curly quotes ("...") instead of straight quotes ("...").

---

## COMMUNICATION PATTERNS

### 19. Collaborative Communication Artifacts

**Words to watch:** I hope this helps, Of course!, Certainly!, You're absolutely right!, Would you like..., let me know, here is a...

### 20. Knowledge-Cutoff Disclaimers

**Words to watch:** as of [date], Up to my last training update, While specific details are limited/scarce..., based on available information...

### 21. Sycophantic/Servile Tone

**Problem:** Overly positive, people-pleasing language.

---

## FILLER AND HEDGING

### 22. Filler Phrases

**Before → After:**
- "In order to achieve this goal" → "To achieve this"
- "Due to the fact that it was raining" → "Because it was raining"
- "At this point in time" → "Now"
- "In the event that you need help" → "If you need help"
- "The system has the ability to process" → "The system can process"
- "It is important to note that the data shows" → "The data shows"

### 23. Excessive Hedging

**Problem:** Over-qualifying statements.

### 24. Generic Positive Conclusions

**Problem:** Vague upbeat endings.

---

## Process

1. Read the input text carefully
2. Identify all instances of the patterns above
3. Rewrite each problematic section
4. Ensure the revised text:
   - Sounds natural when read aloud
   - Varies sentence structure naturally
   - Uses specific details over vague claims
   - Maintains appropriate tone for context
   - Uses simple constructions (is/are/has) where appropriate
5. Present the humanized version

## Output Format

Provide:
1. The rewritten text
2. A brief summary of changes made (optional, if helpful)

---

## Reference

This skill is based on [Wikipedia:Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing), maintained by WikiProject AI Cleanup.
```

---

*End of Commands Reference*
