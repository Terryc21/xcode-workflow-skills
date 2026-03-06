---
name: debug
description: 'Systematic debugging workflow: reproduce, isolate, hypothesize, verify, fix. Triggers: "debug", "find bug", "fix crash", "why is this broken", "not working".'
version: 2.0.0
author: Terry Nyberg
license: MIT
allowed-tools: [Read, Grep, Glob, Bash, Edit, Write, AskUserQuestion]
metadata:
  tier: execution
  category: debugging
---

# Debug

> **Quick Ref:** Systematic bug investigation: reproduce → isolate → hypothesize → verify → fix. Output: `.agents/research/YYYY-MM-DD-debug-*.md`

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

---

## Step 1: Gather Bug Report

Use AskUserQuestion if the user hasn't provided enough detail:

```
AskUserQuestion with questions:
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
git log --oneline -10 -- "**/*.swift"

# Files changed in last N commits
git diff --name-only HEAD~5

# Full diff of recent changes
git diff HEAD~3 -- "**/*.swift"
```

### 2.2: Search for Error Messages

If the user provided an error message, find it in code:

```bash
# Search for the error string in source
Grep pattern="error message text" glob="**/*.swift"

# Search for fatalError / precondition calls
Grep pattern="fatalError|preconditionFailure|assertionFailure" glob="**/*.swift"
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

```bash
# Find the entry point (e.g., button tap, view appear)
Grep pattern="<symptom_function_or_action>" glob="**/*.swift"

# Read the view/controller involved
Read file_path="<path_to_affected_file>"

# Trace function calls from the entry point
# Read each file along the call chain
```

### 3.2: Check the Blast Radius

Understand what the affected code touches:

```bash
# Find all callers of the broken function
Grep pattern="\.<brokenFunctionName>\(" glob="**/*.swift"

# Check protocol conformances if relevant
Grep pattern=":\s*<AffectedProtocol>" glob="**/*.swift"
```

### 3.3: Rule Out Environmental Factors

```bash
# Check for build configuration differences
Grep pattern="#if DEBUG|#if targetEnvironment" glob="**/*.swift"
```

---

## Step 4: Gather Evidence

**Goal:** Collect concrete data about what the code is actually doing.

### 4.1: Read the Code

Read every file in the suspected code path. Don't guess — read.

```bash
# Read the primary file
Read file_path="<path_to_suspected_file>"

# Read related files along the call chain
Read file_path="<path_to_related_file>"
```

### 4.2: Check Git History

```bash
# When was the broken code last modified?
git log --oneline -5 -- "path/to/file.swift"

# What exactly changed?
git log -p -1 -- "path/to/file.swift"

# Find when a specific pattern was introduced or removed
git log -p -S "suspiciousCode" -- "**/*.swift"
```

### 4.3: Search for Related Patterns

```bash
# Find similar patterns that might also be affected
Grep pattern="<same_pattern_as_bug>" glob="**/*.swift"

# Find TODO/FIXME comments near the affected code
Grep pattern="TODO|FIXME|HACK|WORKAROUND" path="<affected_directory>"
```

---

## Step 5: Hypothesize

**Goal:** Form ranked hypotheses based on evidence.

List possible causes ranked by likelihood:

| # | Hypothesis | Likelihood | Evidence | How to Verify |
|---|------------|------------|----------|---------------|
| 1 | [Most likely cause] | High | [What evidence supports this] | [Specific check to confirm/deny] |
| 2 | [Second possibility] | Medium | [Evidence] | [Check] |
| 3 | [Third possibility] | Low | [Evidence] | [Check] |

### Common iOS Bug Patterns

**State & Data:**
- Optional unwrapped when nil (check for `as!` and force unwraps)
- Array index out of bounds (check for subscript access without bounds checking)
- State mutation on wrong thread (check for `@MainActor` missing on UI updates)
- Stale data after model change (check if view re-renders on data change)

**Concurrency:**
- Data race (multiple tasks writing same property without synchronization)
- Deadlock (two actors waiting on each other)
- Missing `await` (forgetting to await an async call, getting old value)
- Task cancelled but not checked (long operation ignoring `Task.isCancelled`)

**Memory:**
- Retain cycle in closure (check for missing `[weak self]` in escaping closures in classes)
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

For each hypothesis, design a specific check that will definitively confirm or deny it:

```bash
# Example: Hypothesis is "nil optional crash"
# Test: Search for force unwraps in the affected file
Grep pattern="as!" path="<affected_file>"

# Example: Hypothesis is "missing weak self"
# Test: Find closures in the affected class (only relevant for classes, not structs)
Grep pattern="\.sink|\.receive|completion.*=" path="<affected_file>"

# Example: Hypothesis is "race condition"
# Test: Find shared mutable state
Grep pattern="var\s+\w+.*=" path="<affected_file>"
```

Record results for each hypothesis:

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
| `File.swift:45` | [what to change] | Low/Med/High |

**Blast radius:** How many files are affected?
**Regression risk:** Low / Medium / High
**Test coverage:** Do existing tests cover this? New tests needed?

### 8.2: Implement the Fix

Use Edit tool to make targeted changes. Keep the fix minimal — don't refactor unrelated code.

### 8.3: Check for Similar Bugs

After fixing, search for the same pattern elsewhere:

```bash
# If the bug was a force cast, find other force casts
# INTENTIONAL: as! after guard let/is check is already validated
Grep pattern="as!" glob="**/*.swift"

# If the bug was a missing weak self, find other closures in classes
# INTENTIONAL: SwiftUI struct views don't need [weak self]
Grep pattern="\.sink\s*\{[^}]*self\." glob="**/*ViewModel*.swift"
Grep pattern="\.sink\s*\{[^}]*self\." glob="**/*Manager*.swift"
```

Or use `/scan-similar-bugs` for a more thorough scan.

---

## Step 9: Verify Fix

**Goal:** Confirm the fix works and doesn't break anything.

- [ ] Bug no longer reproduces with the original steps
- [ ] Build succeeds without warnings
- [ ] Existing tests pass
- [ ] New test added to prevent regression
- [ ] No new issues introduced in related functionality

---

## Step 10: Generate Report

Write report to `.agents/research/YYYY-MM-DD-debug-{summary}.md`:

```markdown
# Bug Investigation Report

**Date:** YYYY-MM-DD
**Bug:** [one-line description]
**Urgency:** 🔴 Critical / 🟡 High / 🟢 Medium / ⚪ Low
**Status:** Fixed

## Symptoms

[What the user observed]

## Root Cause

**What:** [description]
**Where:** FileName.swift:line
**Why:** [underlying reason]
**Introduced:** [commit or date if known]

## Fix Applied

| File | Change | Lines |
|------|--------|-------|
| FileName.swift | [description] | 45-48 |

## Verification

- [x] Bug no longer reproduces
- [x] Build succeeds
- [x] Tests pass
- [ ] Regression test added

## Similar Patterns Found

[List any other instances of the same bug pattern, or "None found"]

## Prevention

[What could prevent this class of bug in the future]
```

---

## Worked Example

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

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Can't reproduce the bug | Ask for exact steps, device/simulator, iOS version, data state |
| Multiple hypotheses seem equally likely | Test the cheapest-to-verify one first |
| Fix breaks something else | Revert, widen the blast radius analysis, find the shared dependency |
| Bug is intermittent | Likely a race condition — focus on concurrency patterns |
| No error message, just wrong behavior | Add strategic print/breakpoint to narrow the code path |
| Bug only happens in release builds | Check `#if DEBUG` blocks, compiler optimizations, stripped symbols |
