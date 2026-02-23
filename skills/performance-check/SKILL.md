---
name: performance-check
description: Profile-guided performance analysis for memory, CPU, energy, and launch time
version: 1.0.0
author: Terry Nyberg
license: MIT
allowed-tools: [Grep, Glob, Read, AskUserQuestion]
metadata:
  tier: execution
  category: analysis
---

# Performance Check

> **Quick Ref:** Automated performance anti-pattern scan for iOS/macOS apps. Output: `.agents/research/YYYY-MM-DD-performance-check.md`

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

Profile-guided performance analysis for memory, CPU, energy, and launch time.

---

## Quick Commands

| Command | Description |
|---------|-------------|
| `/performance-check` | Full interactive analysis |
| `/performance-check --quick` | Surface scan for obvious issues |
| `/performance-check --focus=memory` | Scan only for memory issues |
| `/performance-check --focus=cpu` | Scan only for CPU/main thread issues |
| `/performance-check --focus=energy` | Scan only for battery/energy issues |
| `/performance-check --focus=swiftui` | Scan only for SwiftUI performance |
| `/performance-check --focus=launch` | Scan only for launch time issues |

---

## Step 1: Interactive Scope Selection

Use AskUserQuestion to determine analysis scope:

```
questions:
[
  {
    "question": "What type of performance analysis do you want?",
    "header": "Scope",
    "options": [
      {"label": "Full analysis (Recommended)", "description": "Scan all categories: memory, CPU, energy, SwiftUI, launch"},
      {"label": "Quick surface scan", "description": "Fast check for obvious anti-patterns only"},
      {"label": "Focused analysis", "description": "I'll specify which areas to focus on"}
    ],
    "multiSelect": false
  }
]
```

If "Focused analysis" selected, ask which categories:

```
questions:
[
  {
    "question": "Which performance areas should I analyze?",
    "header": "Focus",
    "options": [
      {"label": "Memory & Retain Cycles", "description": "Leaks, strong reference cycles, large allocations"},
      {"label": "CPU & Main Thread", "description": "Blocking operations, main thread violations"},
      {"label": "Energy & Battery", "description": "Location, timers, background work"},
      {"label": "SwiftUI Performance", "description": "View body complexity, unnecessary updates"},
      {"label": "Launch Time", "description": "App init work, synchronous operations"}
    ],
    "multiSelect": true
  }
]
```

Ask about known issues:

```
questions:
[
  {
    "question": "Have you noticed any specific performance issues?",
    "header": "Symptoms",
    "options": [
      {"label": "No issues noticed", "description": "App feels responsive, running scan proactively"},
      {"label": "Slow loading", "description": "Dashboard or lists take time to load"},
      {"label": "Memory growth", "description": "Memory increases over time"},
      {"label": "UI jank", "description": "Scrolling or animations stutter"},
      {"label": "Battery drain", "description": "App uses excessive battery"}
    ],
    "multiSelect": true
  }
]
```

---

## Step 2: Automated Scanning

Execute grep patterns for each enabled category.

### 2.1 Memory & Retain Cycles

**Search for retain cycle patterns:**

```
# Closures without weak/unowned self
Grep pattern="\{\s*\[?(?!weak|unowned).*self\." glob="*.swift"
Grep pattern="\.sink\s*\{[^}]*self\." glob="*.swift"
Grep pattern="\.receive\s*\([^)]*\)\s*\{[^}]*self\." glob="*.swift"
Grep pattern="Task\s*\{[^}]*self\." glob="*.swift"

# Timer leaks (timers not invalidated)
Grep pattern="Timer\.(scheduledTimer|publish)" glob="*.swift"

# NotificationCenter observers not removed
Grep pattern="NotificationCenter\.default\.addObserver" glob="*.swift"

# KVO observers not removed
Grep pattern="\.addObserver\(.*forKeyPath" glob="*.swift"

# Large array/dictionary literals
Grep pattern="\[[^\]]{500,}\]" glob="*.swift"
```

**Severity Scoring:**

| Pattern | Severity | Impact |
|---------|----------|--------|
| Closure capturing self strongly | HIGH | Memory leak, prevents dealloc |
| Timer without invalidation | HIGH | Continues firing, prevents dealloc |
| Observer not removed | MEDIUM | Memory leak, potential crash |
| Large inline collections | LOW | Memory spike at init |

### 2.2 CPU & Main Thread

**Search for main thread violations:**

```
# Synchronous network calls
Grep pattern="URLSession.*\.dataTask.*\.wait\(\)" glob="*.swift"
Grep pattern="Data\(contentsOf:\s*URL" glob="*.swift"

# Synchronous file I/O on main thread
Grep pattern="FileManager.*\.contents\(" glob="*.swift"
Grep pattern="String\(contentsOf" glob="*.swift"

# Heavy computation patterns
Grep pattern="for.*in.*\.sorted\(" glob="*.swift"
Grep pattern="\.filter\(.*\.filter\(" glob="*.swift"
Grep pattern="\.map\(.*\.map\(.*\.map\(" glob="*.swift"

# Expensive operations in view body
Grep pattern="var body.*\{[^}]*(DateFormatter|NumberFormatter|JSONDecoder)" glob="*.swift"

# Missing @MainActor
Grep pattern="DispatchQueue\.main\.(async|sync)" glob="*.swift"
```

**Check for blocking calls:**

```
# Thread.sleep on main
Grep pattern="Thread\.sleep" glob="*.swift"

# Semaphore wait (potential deadlock)
Grep pattern="\.wait\(\)" glob="*.swift"

# Synchronous dispatch to main
Grep pattern="DispatchQueue\.main\.sync" glob="*.swift"
```

**Severity Scoring:**

| Pattern | Severity | Impact |
|---------|----------|--------|
| Sync network on main | CRITICAL | UI freeze, potential ANR |
| DispatchQueue.main.sync | HIGH | Deadlock risk |
| Thread.sleep on main | HIGH | UI unresponsive |
| Heavy computation in body | MEDIUM | View render delays |
| Triple-nested map/filter | LOW | CPU spike, can optimize |

### 2.3 Energy & Battery

**Search for energy anti-patterns:**

```
# Continuous location updates
Grep pattern="startUpdatingLocation" glob="*.swift"
Grep pattern="allowsBackgroundLocationUpdates\s*=\s*true" glob="*.swift"
Grep pattern="desiredAccuracy.*best" glob="*.swift"

# Frequent timers
Grep pattern="Timer.*interval:\s*[0-1]\." glob="*.swift"
Grep pattern="Timer.*interval:\s*0\." glob="*.swift"

# Polling instead of push
Grep pattern="Timer.*interval.*fetch" glob="*.swift"

# Background refresh abuse
Grep pattern="BGAppRefreshTaskRequest" glob="*.swift"

# Animation running continuously
Grep pattern="\.repeatForever\(\)" glob="*.swift"
Grep pattern="withAnimation.*\.animation\(.*repeat" glob="*.swift"

# Wake locks / preventing sleep
Grep pattern="idleTimerDisabled\s*=\s*true" glob="*.swift"
```

**Severity Scoring:**

| Pattern | Severity | Impact |
|---------|----------|--------|
| Continuous location (best accuracy) | HIGH | Significant battery drain |
| Sub-second timers | MEDIUM | CPU wake-ups, battery |
| Polling pattern | MEDIUM | Network + CPU overhead |
| Continuous animation | LOW | GPU usage when visible |
| Idle timer disabled | LOW | Screen stays on |

### 2.4 SwiftUI Performance

**Search for SwiftUI anti-patterns:**

```
# Expensive work in body
Grep pattern="var body:.*View\s*\{" -A 50 glob="*.swift" | grep -E "(DateFormatter|NumberFormatter|JSONDecoder|try\?|await)"

# @State with reference types
Grep pattern="@State\s+(var|let)\s+\w+\s*:\s*(NS|UI|Any|class)" glob="*.swift"

# Large bodies (symptom of complexity)
# Count lines between "var body: some View {" and its closing brace

# Missing lazy loading
Grep pattern="VStack\s*\{" glob="*.swift"
Grep pattern="HStack\s*\{" glob="*.swift"
# (Should use LazyVStack/LazyHStack for long lists)

# GeometryReader overuse
Grep pattern="GeometryReader" glob="*.swift"

# Excessive environmentObject/observedObject
Grep pattern="@(EnvironmentObject|ObservedObject)" glob="*.swift"

# Animation on entire view hierarchy
Grep pattern="\.animation\(.*,\s*value:\s*\w+\)" glob="*.swift"
```

**Check for @Observable/@ObservableObject issues:**

```
# Published properties that fire too often
Grep pattern="@Published\s+var\s+\w+\s*=" glob="*.swift"

# ObservableObject without specific property observation
Grep pattern="class\s+\w+:\s*ObservableObject" glob="*.swift"
```

**Severity Scoring:**

| Pattern | Severity | Impact |
|---------|----------|--------|
| DateFormatter in body | HIGH | Created every render |
| @State with class type | HIGH | Won't trigger updates properly |
| VStack instead of LazyVStack (long list) | MEDIUM | All items rendered |
| Excessive GeometryReader | MEDIUM | Forces layout passes |
| Many @Published properties | LOW | Potential over-invalidation |

### 2.5 Launch Time

**Search for launch time issues:**

```
# Work in App init
Grep pattern="@main.*struct.*App.*\{" -A 30 glob="*.swift"

# Synchronous operations at launch
Grep pattern="init\(\).*\{[^}]*(UserDefaults|Keychain|FileManager|URLSession)" glob="*.swift"

# Heavy imports (check for large frameworks)
Grep pattern="import\s+(AVFoundation|CoreML|Vision|ARKit|SceneKit|SpriteKit)" glob="*.swift"

# Analytics/SDK initialization
Grep pattern="(Firebase|Analytics|Crashlytics|Facebook)\.configure" glob="*.swift"

# Database setup in App init
Grep pattern="init\(\).*\{[^}]*(ModelContainer|NSPersistentContainer)" glob="*.swift"
```

**Severity Scoring:**

| Pattern | Severity | Impact |
|---------|----------|--------|
| Sync network at launch | CRITICAL | Launch blocked |
| Heavy framework import | MEDIUM | Increases binary load |
| Analytics init in App.init | MEDIUM | Adds to launch time |
| UserDefaults read in init | LOW | Usually fast |

### 2.6 Database / SwiftData

**Search for database performance issues:**

```
# N+1 query patterns
Grep pattern="for.*in.*\{[^}]*\.fetch\(" glob="*.swift"
Grep pattern="\.forEach.*\{[^}]*\.fetch\(" glob="*.swift"

# Large fetches without pagination
Grep pattern="@Query\s+(var|let)" glob="*.swift"
Grep pattern="\.fetch\([^)]*\)" glob="*.swift"

# Missing predicates (full table scans)
Grep pattern="FetchDescriptor<\w+>\(\)" glob="*.swift"
Grep pattern="@Query\s+var\s+\w+:\s*\[\w+\]" glob="*.swift"

# Synchronous context operations
Grep pattern="modelContext\.(insert|delete|save)" glob="*.swift"
```

**Severity Scoring:**

| Pattern | Severity | Impact |
|---------|----------|--------|
| N+1 query pattern | HIGH | O(n) database calls |
| @Query without predicate | MEDIUM | Full table scan |
| Missing pagination | MEDIUM | Memory spike |
| Sync save on main | LOW | May block briefly |

---

## Step 3: Integration with Instruments

For issues found, suggest Instruments templates to profile:

| Issue Type | Instruments Template | What to Look For |
|------------|---------------------|------------------|
| Memory leaks | Leaks | Leaked objects over time |
| Retain cycles | Allocations | Growth without release |
| Main thread blocking | Time Profiler | Long calls on main |
| Energy drain | Energy Log | High CPU/location wake |
| SwiftUI renders | SwiftUI | View body invocations |
| Launch time | App Launch | Pre-main and main phases |

To run via command line:

```bash
# Record a Time Profiler trace
xcrun xctrace record --template "Time Profiler" --device "iPhone 16 Pro" --output ./trace.trace --attach "com.yourapp.id"

# Record a Leaks trace
xcrun xctrace record --template "Leaks" --device "iPhone 16 Pro" --output ./leaks.trace --attach "com.yourapp.id"
```

---

## Step 4: Generate Report

Write report to `.agents/research/YYYY-MM-DD-performance-check.md`:

```markdown
# Performance Analysis Report

**Date:** YYYY-MM-DD HH:MM
**Project:** [Project Name]
**Scan Type:** [Full/Quick/Focused]
**Symptoms Reported:** [None / List]

## Summary

| Category | Grade | Critical | High | Medium | Low |
|----------|-------|----------|------|--------|-----|
| Memory & Retain Cycles | A-F | X | X | X | X |
| CPU & Main Thread | A-F | X | X | X | X |
| Energy & Battery | A-F | X | X | X | X |
| SwiftUI Performance | A-F | X | X | X | X |
| Launch Time | A-F | X | X | X | X |
| Database | A-F | X | X | X | X |
| **Overall** | **A-F** | **X** | **X** | **X** | **X** |

## Critical Issues (Fix Immediately)

### 1. [Issue Title]
**File:** path/to/file.swift:42
**Severity:** CRITICAL
**Category:** Memory
**Impact:** [What happens - e.g., "Memory grows indefinitely, app will be killed by OS"]

```swift
// Current code (problematic):
class MyViewController {
    var completion: (() -> Void)?

    func setup() {
        completion = {
            self.doSomething()  // Strong capture of self
        }
    }
}
```

**Remediation:**
```swift
// Fixed:
class MyViewController {
    var completion: (() -> Void)?

    func setup() {
        completion = { [weak self] in
            self?.doSomething()
        }
    }
}
```

---

### 2. [Next Issue]
...

## High Priority Issues

...

## Medium Priority Issues

...

## Low Priority Issues

...

## Instruments Profiling Recommendations

Based on findings, run these Instruments templates:

1. **Leaks** - To verify retain cycles in [list files]
2. **Time Profiler** - To measure actual impact of [issue]
3. **Energy Log** - To quantify battery impact

## Optimization Opportunities

### Quick Wins (Low Effort, High Impact)
1. [Optimization 1]
2. [Optimization 2]

### Medium Effort
1. [Optimization 1]
2. [Optimization 2]

### Requires Refactoring
1. [Optimization 1]
2. [Optimization 2]

## Before/After Examples

### Example 1: [Title]

**Before (X ms / Y MB):**
```swift
// Slow code
```

**After (X ms / Y MB):**
```swift
// Optimized code
```

**Improvement:** X% faster / Y% less memory
```

---

## Step 5: Present Interactive Summary

Show summary to user:

```
## Performance Analysis Complete

**Overall Grade:** [A-F]

| Severity | Count |
|----------|-------|
| CRITICAL | X |
| HIGH | X |
| MEDIUM | X |
| LOW | X |

**Top Issues:**
1. [Highest impact issue]
2. [Second highest]
3. [Third highest]

**Full report:** .agents/research/YYYY-MM-DD-performance-check.md

What would you like to do?
```

Use AskUserQuestion:

```
questions:
[
  {
    "question": "How would you like to proceed?",
    "header": "Next",
    "options": [
      {"label": "Fix critical issues now", "description": "Walk through each critical issue with fixes"},
      {"label": "See full report", "description": "Display the detailed markdown report"},
      {"label": "Run Instruments", "description": "Get xctrace commands to profile specific issues"},
      {"label": "Export for review", "description": "Report saved, I'll review later"}
    ],
    "multiSelect": false
  }
]
```

---

## For iOS-Specific Deep Dives

This skill focuses on workflow orchestration. For deep iOS-specific performance analysis:

- **Swift performance patterns:** Invoke `/axiom:axiom-swift-performance`
- **SwiftUI performance:** Invoke `/axiom:axiom-swiftui-performance`
- **Memory debugging:** Invoke `/axiom:axiom-memory-debugging`
- **Energy optimization:** Invoke `/axiom:axiom-energy`
- **Concurrency profiling:** Invoke `/axiom:axiom-concurrency-profiling`

---

## See Also

- `/tech-talk-reportcard` - Comprehensive codebase analysis including performance
- `/security-audit` - Security analysis (complements performance)
- `/debug` - When performance issues cause specific bugs

---

## Common False Positives

| Pattern | Why It's OK | How to Verify |
|---------|-------------|---------------|
| `Task { self.x }` with no stored ref | Task completes, no cycle | Check if Task is stored |
| VStack in short list (<20 items) | Lazy not needed for small lists | Count items |
| Timer that's definitely invalidated | Pattern exists but handled | Find matching invalidate |
| DispatchQueue.main.sync from bg | Sometimes necessary | Check caller thread |

---

## Appendix: Performance Budgets

Recommended targets for iOS apps:

| Metric | Target | Measurement |
|--------|--------|-------------|
| Cold launch | < 400ms | Instruments App Launch |
| Warm launch | < 200ms | Instruments App Launch |
| Memory (idle) | < 50MB | Instruments Allocations |
| Memory (active) | < 150MB | Instruments Allocations |
| Frame rate | 60 fps (120 on ProMotion) | Core Animation FPS |
| Main thread hitches | < 1% of frames | Instruments Hitches |
