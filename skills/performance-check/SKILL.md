---
name: performance-check
description: 'Automated performance anti-pattern scan for iOS/macOS apps. Covers memory, CPU, energy, SwiftUI, launch time, and database. Triggers: "performance check", "performance scan", "check performance".'
version: 2.1.0
author: Terry Nyberg
license: MIT
allowed-tools: [Grep, Glob, Read, Write, Bash, AskUserQuestion]
metadata:
  tier: execution
  category: analysis
---

# Performance Check

> **Quick Ref:** Automated performance scan for iOS/macOS apps. Output: `.agents/research/YYYY-MM-DD-performance-check.md`

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

All findings use the **Issue Rating Table** format. Do not use prose severity tags.

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

## Step 1: Scope Selection

```
AskUserQuestion with questions:
[
  {
    "question": "What type of performance analysis do you want?",
    "header": "Scope",
    "options": [
      {"label": "Full analysis (Recommended)", "description": "All categories: memory, CPU, energy, SwiftUI, launch, database"},
      {"label": "Quick scan", "description": "Memory + CPU only — highest-impact categories"},
      {"label": "Focused analysis", "description": "I'll specify which areas to focus on"}
    ],
    "multiSelect": false
  }
]
```

If "Focused analysis", ask which categories:

```
AskUserQuestion with questions:
[
  {
    "question": "Which performance areas should I analyze?",
    "header": "Focus",
    "options": [
      {"label": "Memory & Retain Cycles", "description": "Leaks, strong reference cycles, large allocations"},
      {"label": "CPU & Main Thread", "description": "Blocking operations, main thread violations"},
      {"label": "Energy & Battery", "description": "Location, timers, background work"},
      {"label": "SwiftUI Performance", "description": "View body complexity, unnecessary updates"}
    ],
    "multiSelect": true
  }
]
```

Ask about symptoms:

```
AskUserQuestion with questions:
[
  {
    "question": "Have you noticed any specific performance issues?",
    "header": "Symptoms",
    "options": [
      {"label": "No issues noticed", "description": "Running scan proactively"},
      {"label": "Slow loading", "description": "Lists or screens take time to appear"},
      {"label": "Memory growth", "description": "Memory increases over time"},
      {"label": "UI jank", "description": "Scrolling or animations stutter"},
      {"label": "Battery drain", "description": "App uses excessive battery"}
    ],
    "multiSelect": true
  }
]
```

**Symptom-based priority:** If symptoms are reported, double-weight the matching category in grading:
- Slow loading → CPU & Launch Time
- Memory growth → Memory
- UI jank → SwiftUI + CPU
- Battery drain → Energy

### Freshness

Base all findings on current source code only. Do not read or reference
files in `.agents/`, `scratch/`, or prior audit reports. Ignore cached
findings from auto-memory or previous sessions. Every finding must come
from scanning the actual codebase as it exists now.

---

## Step 2: Automated Scanning

Run patterns for each enabled category. **Quick scan** runs only 2.1 and 2.2. **Full analysis** runs all sections.

Every grep hit is a CANDIDATE — verify by reading the file before reporting (see Step 3).

### 2.1 Memory & Retain Cycles

```bash
# Closures without weak self — IN CLASSES ONLY
# FALSE POSITIVE: SwiftUI struct views don't need [weak self]
# Only flag closures in *ViewModel*, *Manager*, *Service*, *Controller* files
Grep pattern="\.sink\s*\{[^}]*self\." glob="**/*ViewModel*.swift"
Grep pattern="\.sink\s*\{[^}]*self\." glob="**/*Manager*.swift"
Grep pattern="\.sink\s*\{[^}]*self\." glob="**/*Service*.swift"

# Timer leaks — check if timer is invalidated in deinit/onDisappear
Grep pattern="Timer\.(scheduledTimer|publish)" glob="**/*.swift"

# NotificationCenter observers not removed
# FALSE POSITIVE: addObserver with selector that uses #selector is fine if removeObserver exists
Grep pattern="NotificationCenter\.default\.addObserver" glob="**/*.swift"

# Positive signal: proper cleanup patterns
Grep pattern="\.cancel\(\)" glob="**/*.swift" output_mode="files_with_matches"
Grep pattern="invalidate\(\)" glob="**/*.swift" output_mode="files_with_matches"
Grep pattern="removeObserver" glob="**/*.swift" output_mode="files_with_matches"
```

**Common false positives:**
- `self.` inside Task {} in a SwiftUI struct → Task captures struct copy, no cycle
- Combine `.sink` with `.store(in: &cancellables)` where class has proper deinit → handled
- Timer that's invalidated in `onDisappear` or `deinit` → check for matching invalidation

### 2.2 CPU & Main Thread

```bash
# Synchronous file I/O in views (main thread blocking)
# FALSE POSITIVE: FileManager in async/Task context is fine
# Only flag synchronous calls in view body, computed properties, or onAppear
Grep pattern="(FileManager|Data\(contentsOf|String\(contentsOf)" glob="**/*View*.swift"

# Thread.sleep (any context)
Grep pattern="Thread\.sleep" glob="**/*.swift"

# Semaphore wait (potential deadlock)
Grep pattern="\.wait\(\)" glob="**/*.swift"

# Synchronous dispatch to main (DEADLOCK if called from main thread)
# DispatchQueue.main.sync from main thread = guaranteed deadlock
# DispatchQueue.main.sync from background thread = safe but legacy pattern
Grep pattern="DispatchQueue\.main\.sync" glob="**/*.swift"

# Heavy computation patterns — chained collection operations
# Read file to check if data set is large enough to matter
Grep pattern="\.filter\(.*\.filter\(" glob="**/*.swift"

# DispatchQueue.main.async — legacy concurrency
# CLASSIFY: animation delay (asyncAfter) vs state update (async) vs layout workaround
Grep pattern="DispatchQueue\.main\.(async|sync)" glob="**/*.swift"
```

**Common false positives:**
- `DispatchQueue.main.asyncAfter` for animation timing → intentional
- `FileManager` inside `Task {}` or async method → runs off main thread
- `.wait()` on DispatchGroup from background queue → safe

### 2.3 Energy & Battery

```bash
# Continuous location updates (high battery cost)
Grep pattern="startUpdatingLocation" glob="**/*.swift"
Grep pattern="allowsBackgroundLocationUpdates\s*=\s*true" glob="**/*.swift"
Grep pattern="desiredAccuracy.*best" glob="**/*.swift"

# Sub-second timers (excessive CPU wake-ups)
Grep pattern="Timer.*interval:\s*0\." glob="**/*.swift"

# Polling instead of push/observation
# Read file to check if a reactive pattern (Combine, AsyncSequence) would be better
Grep pattern="Timer.*interval.*fetch" glob="**/*.swift" -i

# Continuous animation without pause
Grep pattern="\.repeatForever\(\)" glob="**/*.swift"

# Idle timer disabled (screen stays on indefinitely)
Grep pattern="idleTimerDisabled\s*=\s*true" glob="**/*.swift"

# Positive signal: significant location (low energy)
Grep pattern="startMonitoringSignificantLocationChanges" glob="**/*.swift" output_mode="files_with_matches"
```

**Common false positives:**
- `startUpdatingLocation` that's stopped in `onDisappear` or after fix → check for matching stop
- `desiredAccuracy.*best` in a navigation app → may be required
- `.repeatForever()` on a loading spinner → appropriate for active UI

### 2.4 SwiftUI Performance

```bash
# Expensive work in view body — formatters, decoders created every render
# Read file to check if these are actually inside `var body`
Grep pattern="DateFormatter\(\)" glob="**/*View*.swift"
Grep pattern="NumberFormatter\(\)" glob="**/*View*.swift"
Grep pattern="JSONDecoder\(\)" glob="**/*View*.swift"

# @State with reference types (won't trigger updates properly)
# NOTE: @State with @Observable classes IS correct (iOS 17+)
# Only flag @State with non-@Observable reference types (NS*, UI*, or plain classes)
Grep pattern="@State\s+(private\s+)?var\s+\w+\s*:\s*(NS|UI)" glob="**/*.swift"

# GeometryReader overuse (forces layout passes)
# Read file — GeometryReader is fine in isolated leaf views, problematic when nested
Grep pattern="GeometryReader" glob="**/*.swift"

# @Query without predicate (full table scans)
# Read file to check: is .count the only access? → should use fetchCount
# Does the view filter client-side? → predicate should be on the query
# INTENTIONAL: views that genuinely need all records (e.g., main item list) are OK
Grep pattern="@Query\s+(private\s+)?var" glob="**/*.swift"

# Large view bodies (>80 lines) — check for complexity
Grep pattern="var body.*some View" glob="**/*View*.swift" output_mode="files_with_matches"

# Positive signal: lazy containers for lists
Grep pattern="Lazy(V|H)Stack" glob="**/*.swift" output_mode="files_with_matches"
Grep pattern="Lazy(V|H)Grid" glob="**/*.swift" output_mode="files_with_matches"
```

**Common false positives:**
- `DateFormatter()` in a static/cached property → only created once, safe
- `GeometryReader` in a single leaf view for responsive layout → appropriate
- `@Query var items` that genuinely needs all items (e.g., total count display) → verify usage

### 2.5 Launch Time

```bash
# Work in App init — read the app entry point file
Grep pattern="@main" glob="**/*.swift"
# After finding @main, read that file to check for synchronous work in init()

# Heavy framework imports (increases binary load time)
# Read file — only flag if framework is imported but barely used
Grep pattern="import\s+(AVFoundation|CoreML|Vision|ARKit|SceneKit|SpriteKit)" glob="**/*.swift" output_mode="files_with_matches"

# Analytics/SDK initialization
Grep pattern="(Firebase|Analytics|Crashlytics)\.configure" glob="**/*.swift"

# Database setup in App init
Grep pattern="ModelContainer\(" glob="**/*.swift"
# Read file — ModelContainer in App.init is normal; flag only if combined with synchronous fetches
```

**Common false positives:**
- `import AVFoundation` in a camera-specific file → normal, not a launch issue
- `ModelContainer` in App struct → standard SwiftData pattern
- Analytics init → often required to be early; flag only if it blocks UI

### 2.6 Database / SwiftData

```bash
# N+1 query patterns — fetching inside a loop
Grep pattern="for.*in.*\{" glob="**/*.swift"
# After finding loops, check if .fetch() or ModelContext operations appear inside

# FetchDescriptor without predicate (full table scan)
Grep pattern="FetchDescriptor<\w+>\(\)" glob="**/*.swift"

# Synchronous context saves on main thread
# FALSE POSITIVE: save() after a single insert in a button action is fine
Grep pattern="modelContext\.save\(\)" glob="**/*View*.swift"

# Positive signal: batch operations
Grep pattern="(enumerate|batchInsert|batchDelete)" glob="**/*.swift" output_mode="files_with_matches"
```

**Common false positives:**
- `modelContext.save()` in a button action handler → usually fine (single save)
- `FetchDescriptor<>()` when the app genuinely needs all records → verify intent

---

## Step 3: Verification Rule (CRITICAL)

Before reporting ANY finding as a performance issue:

1. **Read the flagged file** — at minimum 20 lines of context around the match
2. **Check execution context** — code inside `Task {}` or `async` methods runs off main thread
3. **Check for cleanup** — timer/observer creation needs matching invalidation/removal; check `deinit`, `onDisappear`, `.cancel()`
4. **SwiftUI struct vs class** — `[weak self]` is only needed in classes, never in SwiftUI struct views
5. **Classify** — CONFIRMED, FALSE_POSITIVE, or INTENTIONAL before reporting

**Performance-specific false positives:**
- Closure capturing `self` in a SwiftUI struct → no retain cycle possible
- `FileManager` usage inside `Task {}` → off main thread, safe
- `DispatchQueue.main.asyncAfter` with comment about animation → intentional
- `@Query var items` that's used for display, not just `.count` → appropriate
- `GeometryReader` in a single leaf view → not a problem
- Timer with matching `invalidate()` in `deinit` or `onDisappear` → handled

---

## Step 4: Grading

### Grade Criteria

| Grade | Criteria |
|-------|----------|
| A | No main-thread blocking, proper memory management, lazy loading, efficient queries |
| B | Minor issues (1-2 unoptimized queries, formatters that could be cached), good overall patterns |
| C | Several medium issues (missing lazy containers for large lists, some main-thread I/O, uncached formatters) |
| D | Significant blocking (synchronous I/O in views, retain cycles, continuous location without need) |
| F | Critical issues (deadlock risk, memory leaks in core flows, unthrottled timers) |

### Category Grades

Grade each scanned category independently:

| Category | What to Evaluate |
|----------|--------------------|
| Memory | Retain cycle risk? Timer/observer cleanup? Proper [weak self] in classes? |
| CPU & Main Thread | Synchronous I/O in views? Deadlock risk? Legacy DispatchQueue usage? |
| Energy | Location accuracy appropriate? Timer frequency? Polling vs push? |
| SwiftUI | Formatters in body? @Query efficiency? Lazy containers? View complexity? |
| Launch Time | Work in App init? Heavy frameworks? Synchronous setup? |
| Database | N+1 patterns? Unfiltered fetches? Batch operations used? |

### Overall Grade

Weighted average (symptom-reported categories get 2x weight):

```
Default weights: Memory 20% | CPU 20% | Energy 15% | SwiftUI 20% | Launch 10% | Database 15%
```

Convert: A=4, B=3, C=2, D=1, F=0 (with +/- as ±0.3). Multiply by weight, sum, convert back.

---

## Step 5: Output

**Display the executive summary, grade summary, issue table, and Instruments recommendations inline**, then write report to `.agents/research/YYYY-MM-DD-performance-check.md`.

### Report Structure

```markdown
# Performance Analysis Report

**Date:** YYYY-MM-DD
**Project:** [name]
**Scan Type:** Full / Quick / Focused
**Symptoms Reported:** [None / List]

## Executive Summary

[2-3 sentences: overall performance posture, biggest risk, top recommendation]

## Grade Summary

Overall: [grade] (Memory [grade] | CPU [grade] | Energy [grade] | SwiftUI [grade] | Launch [grade] | Database [grade])

## Positive Findings

[What's done well — lazy loading, proper cleanup, efficient queries, async patterns]

## Issue Rating Table

| # | Finding | Urgency | Risk: Fix | Risk: No Fix | ROI | Blast Radius | Fix Effort |
|---|---------|---------|-----------|-------------|-----|-------------|------------|
| 1 | ... | 🔴 Critical | ... | ... | ... | ... | ... |

## Instruments Profiling Recommendations

[For each critical/high finding, suggest which Instruments template to use]

## Remediation Examples

[For each critical/high finding, show current code and optimized fix]
```

Use the Issue Rating scale:
- **Urgency:** 🔴 CRITICAL (crash/deadlock risk) · 🟡 HIGH (noticeable lag/drain) · 🟢 MEDIUM (suboptimal) · ⚪ LOW (minor)
- **ROI:** 🟠 Excellent · 🟢 Good · 🟡 Marginal · 🔴 Poor
- **Fix Effort:** Trivial / Small / Medium / Large

---

## Step 6: Follow-up

```
AskUserQuestion with questions:
[
  {
    "question": "How would you like to proceed?",
    "header": "Next",
    "options": [
      {"label": "Fix critical issues now", "description": "Walk through each critical/high issue with fixes"},
      {"label": "Re-scan specific category", "description": "Deeper scan on one area"},
      {"label": "Report is sufficient", "description": "Report saved to .agents/research/"}
    ],
    "multiSelect": false
  }
]
```

If "Fix critical issues now": Walk through each 🔴/🟡 finding, show the problematic code, propose an optimized fix, apply after user approval.

---

## Instruments Reference

When suggesting profiling, use this mapping:

| Issue Type | Instruments Template | What to Look For |
|------------|---------------------|------------------|
| Memory leaks | Leaks | Leaked objects over time |
| Retain cycles | Allocations | Growth without release |
| Main thread blocking | Time Profiler | Long calls on main thread |
| Energy drain | Energy Log | High CPU/location/network |
| SwiftUI renders | SwiftUI | View body invocation count |
| Launch time | App Launch | Pre-main and post-main phases |

---

## Performance Budgets

Recommended targets for iOS apps:

| Metric | Target | Measurement |
|--------|--------|-------------|
| Cold launch | < 400ms | Instruments App Launch |
| Warm launch | < 200ms | Instruments App Launch |
| Memory (idle) | < 50MB | Instruments Allocations |
| Memory (active) | < 150MB | Instruments Allocations |
| Frame rate | 60 fps (120 on ProMotion) | Core Animation FPS |
| Main thread hitches | < 1% of frames | Instruments Hitches |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Too many grep hits for closures | Narrow glob to `**/*ViewModel*.swift` or `**/*Manager*.swift` |
| Can't determine if Timer is invalidated | Search for `invalidate()` in the same file |
| @Query seems fine but app is slow | Check if `.count` is the only access — should use fetchCount |
| False positive rate too high | Read more context (30+ lines), check if code is in async scope |
| GeometryReader flagged but seems OK | Check if it's a leaf view (fine) vs nested in a list (problematic) |
