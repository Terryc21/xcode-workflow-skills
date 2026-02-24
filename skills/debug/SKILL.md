---
name: debug
description: 'Systematic debugging workflow - reproduce, isolate, hypothesize, verify, and fix. Triggers: "debug", "find bug", "fix crash", "why is this broken", "not working".'
version: 1.1.0
author: Terry Nyberg
license: MIT
allowed-tools: [Read, Grep, Glob, Bash, Edit, AskUserQuestion]
metadata:
  tier: execution
  category: debugging
---

# Debug

> **Quick Ref:** Systematic bug investigation: reproduce → isolate → hypothesize → verify → fix. Output: `.agents/research/YYYY-MM-DD-debug-*.md`

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

Systematic debugging workflow: reproduce, isolate, hypothesize, verify, and fix.

## Quick Commands

| Command | Description |
|---------|-------------|
| `/debug` | Interactive — prompts for bug description |
| `/debug MyView crashes on tap` | Direct — starts with bug description |
| `/debug --recent` | Check recent git changes for likely culprit |
| `/debug --crash` | Crash-focused mode (stack trace analysis) |

---

## Step 1: Gather Bug Report

Use AskUserQuestion if the user hasn't provided enough detail:

```
questions:
[
  {
    "question": "What type of issue are you seeing?",
    "header": "Bug type",
    "options": [
      {"label": "Crash", "description": "App crashes, EXC_BAD_ACCESS, fatal error, etc."},
      {"label": "Wrong behavior", "description": "App runs but does the wrong thing"},
      {"label": "UI issue", "description": "Layout broken, animation wrong, view not updating"},
      {"label": "Performance", "description": "Slow, laggy, high memory, battery drain"}
    ],
    "multiSelect": false
  }
]
```

Collect these details (from user message or by asking):
- **Expected behavior** — What should happen?
- **Actual behavior** — What happens instead?
- **Steps to reproduce** — How to trigger it
- **Error messages** — Console output, crash logs, compiler errors
- **When it started** — Recent change? Always broken?

---

## Step 2: Reproduce

**Goal:** Confirm the bug exists and understand the trigger conditions.

### 2.1: Check Recent Changes

If the bug started recently, look at what changed:

```bash
# Recent commits touching Swift files
git log --oneline -10 -- "*.swift"

# Files changed in last N commits
git diff --name-only HEAD~5

# Full diff of recent changes
git diff HEAD~3 -- "*.swift"
```

### 2.2: Search for Error Messages

If the user provided an error message, find it in code:

```
# Search for the error string in source
Grep pattern="error message text" glob="*.swift"

# Search for the throwing function
Grep pattern="throw.*ErrorType" glob="*.swift"

# Search for fatalError / precondition calls
Grep pattern="fatalError|preconditionFailure|assertionFailure" glob="*.swift"
```

### 2.3: Document Reproduction

Record:
- **Reproducible?** Always / intermittent / only under specific conditions
- **Minimum steps:** Fewest actions to trigger the bug
- **Environment factors:** Simulator vs device, debug vs release, iOS version

---

## Step 3: Isolate

**Goal:** Narrow down to the smallest code path that causes the bug.

### 3.1: Trace the Code Path

Start from the user-facing symptom and trace inward:

```
# Find the entry point (e.g., button tap, view appear)
Grep pattern="func.*buttonTapped|onTapGesture|\.onAppear" glob="*.swift"

# Find the view/controller involved
Grep pattern="struct.*View.*body|class.*ViewController" path="Sources" glob="*.swift"

# Trace function calls from the entry point
# Read each file along the call chain
```

### 3.2: Check the Blast Radius

Understand what the affected code touches:

```
# Find all callers of the broken function
Grep pattern="\\.brokenFunctionName\\(" glob="*.swift"

# Find all files that import the affected module
Grep pattern="import AffectedModule" glob="*.swift"

# Check protocol conformances
Grep pattern=":\\s*AffectedProtocol" glob="*.swift"
```

### 3.3: Rule Out Environmental Factors

```bash
# Check for build configuration differences
# (debug-only code, #if DEBUG blocks)
```

```
Grep pattern="#if DEBUG|#if targetEnvironment" glob="*.swift"
```

---

## Step 4: Gather Evidence

**Goal:** Collect concrete data about what the code is actually doing.

### 4.1: Read the Code

Read every file in the suspected code path. Don't guess — read.

```
# Read the primary file
Read file_path="Sources/Features/ItemDetail/ItemDetailViewModel.swift"

# Read related files
Read file_path="Sources/Services/NetworkService.swift"
```

### 4.2: Check Git History

```bash
# When was the broken code last modified?
git log --oneline -5 -- "path/to/file.swift"

# What exactly changed?
git log -p -1 -- "path/to/file.swift"

# Who changed it and why? (commit message context)
git log --format="%h %an %s" -5 -- "path/to/file.swift"

# Find when a specific line/pattern was introduced or removed
git log -p -S "suspiciousCode" -- "*.swift"
```

### 4.3: Search for Related Patterns

```
# Find similar patterns that might also be broken
Grep pattern="same pattern as the bug" glob="*.swift"

# Find TODO/FIXME comments near the affected code
Grep pattern="TODO|FIXME|HACK|WORKAROUND" path="Sources/Features/AffectedFeature"
```

---

## Step 5: Hypothesize

**Goal:** Form ranked hypotheses based on evidence.

List possible causes ranked by likelihood. Use this table format:

| # | Hypothesis | Likelihood | Evidence | How to Verify |
|---|------------|------------|----------|---------------|
| 1 | [Most likely cause] | High | [What evidence supports this] | [Specific check to confirm/deny] |
| 2 | [Second possibility] | Medium | [Evidence] | [Check] |
| 3 | [Third possibility] | Low | [Evidence] | [Check] |

### Common iOS Bug Patterns to Consider

**State & Data:**
- Optional unwrapped when nil (check for `!` force unwraps)
- Array index out of bounds (check for subscript access without bounds checking)
- State mutation on wrong thread (check for `@MainActor` missing on UI updates)
- Stale data after model change (check if view re-renders on data change)

**Concurrency:**
- Data race (multiple tasks writing same property without synchronization)
- Deadlock (two actors waiting on each other)
- Missing `await` (forgetting to await an async call, getting old value)
- Task cancelled but not checked (long operation ignoring `Task.isCancelled`)

**Memory:**
- Retain cycle in closure (check for missing `[weak self]` in escaping closures)
- Delegate not declared `weak` (strong reference cycle)
- Timer not invalidated (keeps firing after view dismissed)
- Observation leak (NotificationCenter observer not removed)

**UI:**
- View not updating (missing `@Published`, wrong property wrapper)
- Layout constraint conflict (ambiguous Auto Layout)
- Off-main-thread UI update (background queue modifying UI)
- Animation state stuck (completion handler not called)

---

## Step 6: Verify Hypotheses

**Goal:** Test each hypothesis starting with the most likely.

For each hypothesis:

### 6.1: Design a Specific Test

Don't just re-read the code — design a check that will definitively confirm or deny the hypothesis.

```
# Example: Hypothesis is "nil optional crash"
# Test: Search for force unwraps in the affected file
Grep pattern="\\!" path="Sources/Features/ItemDetail" glob="*.swift" output_mode="content"

# Example: Hypothesis is "missing weak self"
# Test: Find closures capturing self in the affected class
Grep pattern="\\{[^}]*self\\." path="Sources/Features/ItemDetail/ItemDetailViewModel.swift" output_mode="content"

# Example: Hypothesis is "race condition"
# Test: Find shared mutable state
Grep pattern="var\\s+\\w+.*=|nonisolated|@unchecked Sendable" path="Sources/Features/ItemDetail" glob="*.swift" output_mode="content"
```

### 6.2: Record Results

For each hypothesis tested:

```
Hypothesis 1: [description]
  Test: [what I checked]
  Result: CONFIRMED / DENIED / INCONCLUSIVE
  Evidence: [what I found]
```

Continue until root cause is identified.

---

## Step 7: Root Cause Analysis

**Goal:** Document the confirmed root cause clearly.

```markdown
## Root Cause

**What:** [One-sentence description of the bug]

**Why:** [Underlying reason — why did this code get written this way?]

**Where:** [File:line where the bug lives]

**When introduced:** [Commit hash/date if identifiable]
```

---

## Step 8: Fix

**Goal:** Implement the minimal correct fix.

### 8.1: Plan the Fix

Before editing, document:

| File | Change Required | Risk |
|------|-----------------|------|
| `ItemDetailViewModel.swift:45` | Add nil check before force unwrap | Low |
| `NetworkService.swift:112` | Add `[weak self]` to closure | Low |

**Blast radius:** How many files are affected?
**Regression risk:** Low / Medium / High
**Test coverage:** Do existing tests cover this? New tests needed?

### 8.2: Implement the Fix

Use Edit tool to make targeted changes. Keep the fix minimal — don't refactor unrelated code.

### 8.3: Check for Similar Bugs

After fixing, search for the same pattern elsewhere:

```
# If the bug was a force unwrap, find all force unwraps
Grep pattern="\\w+!" glob="*.swift" output_mode="content"

# If the bug was a missing weak self, find other closures
Grep pattern="\\{[^}]*\\bself\\b" glob="*.swift"
```

---

## Step 9: Verify Fix

**Goal:** Confirm the fix works and doesn't break anything.

- [ ] Bug no longer reproduces with the original steps
- [ ] Build succeeds without warnings
- [ ] Existing tests pass
- [ ] New test added to prevent regression (use `/generate-tests` if needed)
- [ ] No new issues introduced in related functionality

---

## Step 10: Generate Report

Create report at `.agents/research/YYYY-MM-DD-debug-{summary}.md`:

```markdown
# Bug Investigation Report

**Date:** YYYY-MM-DD HH:MM
**Bug:** [one-line description]
**Severity:** Critical / High / Medium / Low
**Status:** Fixed

## Symptoms

[What the user observed]

## Root Cause

**What:** [description]
**Where:** FileName.swift:line
**Why:** [underlying reason]
**Introduced:** [commit or date if known]

## Fix Applied

**Files Changed:**

| File | Change | Lines |
|------|--------|-------|
| FileName.swift | Added nil check | 45-48 |

**Diff Summary:**
[Brief description of changes]

## Verification

- [x] Bug no longer reproduces
- [x] Build succeeds
- [x] Tests pass
- [ ] Regression test added

## Similar Patterns Found

[List any other instances of the same bug pattern, or "None found"]

## Prevention

[What could prevent this class of bug in the future — e.g., "Add SwiftLint rule for force unwraps"]
```

---

## Worked Example

Here's a condensed example of the workflow in action:

```
User: "My app crashes when I tap an item in the list"

Step 1 — Gather: Crash on tap, EXC_BAD_ACCESS, started after last commit
Step 2 — Reproduce: git log shows ItemDetailView.swift changed yesterday
Step 3 — Isolate: Trace: List tap → NavigationLink → ItemDetailView.init → viewModel.loadItem()
Step 4 — Evidence: Read ItemDetailViewModel.swift, find `item.category!` on line 34
Step 5 — Hypothesize:
  #1: Force unwrap of nil optional (HIGH) — category is Optional, forced
  #2: Array index out of bounds (LOW) — no array access nearby
Step 6 — Verify: Check data — category is nil for items imported from CSV
Step 7 — Root cause: Force unwrap of item.category which is nil for CSV imports
Step 8 — Fix: Replace `item.category!` with `item.category ?? "Uncategorized"`
Step 9 — Verify: Build passes, tap works, added test for nil category
Step 10 — Report: Written to .agents/research/2026-02-24-debug-item-detail-crash.md
```

---

## For iOS-Specific Debugging

This skill focuses on workflow orchestration. For deep iOS-specific debugging:

- **Memory debugging:** Invoke `/axiom:axiom-memory-debugging`
- **Hang diagnostics:** Invoke `/axiom:axiom-hang-diagnostics`
- **SwiftUI debugging:** Invoke `/axiom:axiom-swiftui-debugging`
- **Xcode debugging:** Invoke `/axiom:axiom-xcode-debugging`
- **Concurrency profiling:** Invoke `/axiom:axiom-concurrency-profiling`

---

## See Also

- `/scan-similar-bugs` — Find similar bug patterns after fixing
- `/review-changes` — Review the fix before committing
- `/generate-tests` — Generate regression tests for the fix
- `/run-tests` — Run tests to verify the fix
