---
name: tech-talk-reportcard
description: 'Technical codebase analysis with A-F grades across 9 categories. Self-contained iOS/Swift audit with automated grep scanning, verification, and Issue Rating Tables. Triggers: "tech report card", "grade my codebase", "technical audit".'
version: 3.0.0
author: Terry Nyberg
license: MIT
allowed-tools: [Glob, Grep, Read, Write, AskUserQuestion]
metadata:
  tier: analysis
  category: analysis
---

# Tech-Talk Report Card Generator

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

Generate a technical report card with A-F grades across 9 categories for iOS/Swift codebases.

All findings use the **Issue Rating Table** format. Do not use prose severity tags like `[HIGH]` or `[MED]` — always render the full rating table.

---

## Step 1: Before Starting

Ask the user about analysis options:

```
AskUserQuestion with questions:
[
  {
    "question": "Should the analysis consider CLAUDE.md project instructions?",
    "header": "CLAUDE.md",
    "options": [
      {"label": "Yes, use CLAUDE.md (Recommended)", "description": "Include project context, coding standards, and preferences from CLAUDE.md"},
      {"label": "No, ignore CLAUDE.md", "description": "Perform unbiased analysis without project-specific instructions"}
    ],
    "multiSelect": false
  },
  {
    "question": "What is your timeline?",
    "header": "Timeline",
    "options": [
      {"label": "Pre-release", "description": "Preparing for App Store — urgency matters"},
      {"label": "Post-release", "description": "App is live, ongoing improvement"},
      {"label": "Planning phase", "description": "Gathering info for roadmap"}
    ],
    "multiSelect": false
  },
  {
    "question": "Any categories to emphasize or skip?",
    "header": "Focus",
    "options": [
      {"label": "Full analysis (Recommended)", "description": "Grade all 9 categories"},
      {"label": "Skip accessibility", "description": "Not prioritizing accessibility now"},
      {"label": "Emphasize performance", "description": "Users report slowness or battery drain"},
      {"label": "Emphasize security", "description": "Handling sensitive data or preparing for review"}
    ],
    "multiSelect": true
  }
]
```

**If "Yes" for CLAUDE.md:** Read CLAUDE.md at the repo root and summarize its key points in 3-5 bullets. Use these guidelines throughout the analysis.

**If "No":** Skip CLAUDE.md. Note in the report that it was intentionally excluded.

### Freshness

Base all findings on current source code only. Do not read or reference
files in `.agents/`, `scratch/`, or prior audit reports. Ignore cached
findings from auto-memory or previous sessions. Every finding must come
from scanning the actual codebase as it exists now.

**Exception:** Reading a previous report card's **grades only** (not findings) for trend comparison is allowed in Step 2.

---

## Step 2: Trend Check

Check for a previous report to enable grade trend comparison:

```
Glob pattern=".agents/research/*-tech-reportcard.md"
```

If found, read ONLY the grade summary line from the most recent report. Do not read or reuse any findings — those must come fresh from scanning.

---

## Step 3: Codebase Exploration

Scan the project structure and key configuration files:

1. **Project metrics** — File counts, LOC (estimate via `wc -l`), targets, schemes
2. **Architecture** — Main modules, patterns (MVC/MVVM/etc.), frameworks used
3. **App purpose** — What the app does, primary user flows
4. **State management** — How data flows between layers (@Observable, SwiftData, etc.)

---

## Step 4: Automated Scans

Run all grep patterns below before compiling findings. Every section includes false-positive guidance — **read flagged files before reporting any finding**.

### 4.1 Architecture

```bash
# Large files (>500 lines) — maintainability signal
# After finding files, check line counts with wc -l
Glob pattern="**/*.swift"

# Missing @MainActor on ObservableObject
# FALSE POSITIVE: ObservableObject subclass that delegates to @MainActor property is fine
Grep pattern="class.*:.*ObservableObject" glob="**/*.swift"

# Deep view body nesting — read file and check body complexity
# Only flag if view body exceeds ~80 lines or has >3 levels of conditional nesting
Grep pattern="var body.*some View" glob="**/*View*.swift"
```

### 4.2 Code Quality

```bash
# Force casts — crash risk
# FALSE POSITIVE: as! in test code or after is/guard let check is safe
Grep pattern="as!" glob="**/*.swift"

# Force unwraps (excluding IBOutlets and test files)
# FALSE POSITIVE: dictionary literals, known-safe patterns, test assertions
Grep pattern="[^I]!" glob="**/*.swift"

# Bare try? swallowing errors silently
# FALSE POSITIVE: try? in optional chaining where nil is the expected fallback
Grep pattern="try\?" glob="**/*.swift"

# TODO/FIXME/HACK markers
Grep pattern="(TODO|FIXME|HACK|XXX):" glob="**/*.swift"
```

### 4.3 Security

```bash
# Hardcoded secrets
Grep pattern="(api[_-]?key|apikey|secret[_-]?key|client[_-]?secret|password|token)\s*[:=]\s*[\"'][^\"']+[\"']" glob="**/*.swift" -i

# Sensitive data in UserDefaults
Grep pattern="(UserDefaults|@AppStorage).*\b(password|token|secret|apiKey|credential)" glob="**/*.swift" -i

# HTTP URLs (non-HTTPS)
# FALSE POSITIVE: http://localhost, XML namespace URIs, protocol-detection logic
Grep pattern="http://" glob="**/*.swift"

# Logging sensitive data
Grep pattern="(print|NSLog|os_log|Logger).*\b(password|token|secret|key|credential)" glob="**/*.swift" -i
```

### 4.4 Performance

**NOTE:** These patterns produce CANDIDATES. Verify each by reading the file.

```bash
# @Query without predicate (full table scans)
# CLASSIFY: COUNT_ONLY (.count access → use fetchCount), FILTER_THEN_USE, or FULL_ACCESS (OK)
Grep pattern="@Query\s+(private\s+)?var" glob="**/*.swift"

# Main thread file I/O
# FALSE POSITIVE: FileManager in async methods or Task.detached is fine
# Only flag synchronous file I/O in view body, computed properties, or onAppear
Grep pattern="(FileManager|Data\(contentsOf|String\(contentsOf)" glob="**/*View*.swift"

# Missing [weak self] in closures
# FALSE POSITIVE: SwiftUI struct views don't need weak self — only flag in classes
Grep pattern="\{\s*\[(?!weak|unowned)" glob="**/*ViewModel*.swift"
Grep pattern="\{\s*\[(?!weak|unowned)" glob="**/*Manager*.swift"
Grep pattern="\{\s*\[(?!weak|unowned)" glob="**/*Service*.swift"

# Timer usage (potential battery drain)
Grep pattern="Timer\.(scheduledTimer|publish)" glob="**/*.swift"

# Continuous location
Grep pattern="startUpdatingLocation" glob="**/*.swift"
```

### 4.5 Concurrency (Swift 6 Readiness)

**NOTE:** Each hit MUST be verified by reading the file. See Verification Rule below.

```bash
# Missing @MainActor on ViewModel
Grep pattern="(class|struct).*ViewModel(?!.*@MainActor)" glob="**/*ViewModel.swift"

# Dispatch to main thread (legacy pattern)
# CLASSIFY: animation delay (asyncAfter) vs state update (async) vs layout workaround
# Only state updates without asyncAfter are true migration candidates
Grep pattern="DispatchQueue\.main\.(async|sync)" glob="**/*.swift"

# Actor isolation issues
# FALSE POSITIVE: nonisolated on UIKit delegate protocol methods is REQUIRED
Grep pattern="nonisolated.*func" glob="**/*.swift"
```

### 4.6 Accessibility

```bash
# Fixed font sizes (breaks Dynamic Type)
Grep pattern="\.font\(\.system\(size:" glob="**/*.swift"

# Check for accessibilityLabel coverage
Grep pattern="\.accessibilityLabel" glob="**/*.swift" output_mode="count"

# Check for accessibilityIdentifier (UI testing support)
Grep pattern="\.accessibilityIdentifier" glob="**/*.swift" output_mode="count"

# Images that may need accessibility descriptions
# Read flagged files — decorative images should use .accessibilityHidden(true)
Grep pattern="Image\(systemName:" glob="**/*.swift"
Grep pattern="Image\(\"" glob="**/*.swift"
```

### 4.7 Testing

```bash
# Test file inventory
Glob pattern="**/*Tests.swift"
Glob pattern="**/*Test.swift"
Glob pattern="**/*UITests*.swift"

# Framework usage
Grep pattern="import Testing" glob="**/*Test*.swift" output_mode="count"
Grep pattern="import XCTest" glob="**/*Test*.swift" output_mode="count"

# Async test support
Grep pattern="@Test.*async" glob="**/*Test*.swift" output_mode="count"
```

### 4.8 UI/UX Patterns

```bash
# Deprecated APIs
Grep pattern="@available.*deprecated" glob="**/*.swift"
Grep pattern="UIApplication\.shared\.open" glob="**/*.swift"

# Missing loading/error states — views with async calls but no loading indicator
Grep pattern="\.task\s*\{" glob="**/*View*.swift"

# Platform conditionals — check for consistent behavior
Grep pattern="#if.*os\(" glob="**/*.swift"
```

### 4.9 Data & Persistence

```bash
# SwiftData models
Grep pattern="@Model" glob="**/*.swift"

# Migration support
Grep pattern="VersionedSchema" glob="**/*.swift"
Grep pattern="SchemaMigrationPlan" glob="**/*.swift"

# Core Data usage (legacy check)
Grep pattern="NSManagedObject|NSPersistentContainer" glob="**/*.swift"

# UserDefaults for non-trivial data (should use proper persistence)
Grep pattern="UserDefaults\.standard\.(set|object)" glob="**/*.swift"
```

---

## Step 5: Verification Rule (CRITICAL)

Grep patterns produce CANDIDATES, not confirmed issues. Before reporting ANY finding:

1. **Read the flagged file** — at minimum 20 lines of context around the match
2. **Check structural context** — a pattern inside a nested closure may be safe depending on the outer scope
3. **Classify before reporting** — label each hit as CONFIRMED, FALSE_POSITIVE, or INTENTIONAL
4. **Never report grep counts as issue counts** — e.g., "60 DispatchQueue.main calls" is a grep count; the real issue count requires classifying each call

**Common false positives:**
- `Task {}` inside `@MainActor` class/view body → inherits isolation, safe
- `DispatchQueue.main.asyncAfter` for animation/layout → intentional
- `nonisolated` on protocol requirement methods → required by protocol
- `http://` in XML namespace URIs → not a real HTTP endpoint
- `as!` after `guard let` or `is` check → already validated
- `try?` in optional chaining for expected-nil paths → intentional

---

## Step 6: Grading

### Grade Scale

| Grade | Meaning | Guideline |
|-------|---------|-----------|
| A | Excellent | Best practices, minimal issues. 0-1 confirmed findings. |
| B | Good | Solid, minor gaps. 2-4 low/medium findings. |
| C | Adequate | Functional but notable gaps. Multiple medium findings or 1+ high. |
| D | Poor | Significant issues. Multiple high findings. |
| F | Failing | Critical problems, not production-ready. |

Use +/- modifiers (e.g., B+, C-) for granularity. Convert to points: A=4, B=3, C=2, D=1, F=0 (with +/- as ±0.3).

### Category Weights

| Category | Weight | What to Evaluate |
|----------|--------|-----------------|
| Architecture | 15% | Separation of concerns, file sizes, module boundaries, dependency direction |
| Code Quality | 10% | Force unwraps, force casts, error swallowing, TODO density, naming |
| Performance | 15% | Main-thread blocking, @Query efficiency, memory patterns, energy |
| Concurrency | 10% | @MainActor coverage, DispatchQueue legacy, Swift 6 readiness |
| Security | 15% | Hardcoded secrets, storage safety, network security, logging |
| Accessibility | 10% | Dynamic Type, VoiceOver labels, accessibility identifiers |
| Testing | 15% | Coverage breadth, framework choice, async test support |
| UI/UX | 5% | Deprecated APIs, loading/error states, platform parity |
| Data/Persistence | 5% | Schema migrations, model design, storage choices |

### Overall Grade Calculation

Multiply each category's point value by its weight, sum, and convert back:

```
Overall = (Arch × 0.15) + (Quality × 0.10) + (Perf × 0.15) + (Concurrency × 0.10)
        + (Security × 0.15) + (A11y × 0.10) + (Testing × 0.15) + (UI × 0.05) + (Data × 0.05)
```

Convert: 3.7+ = A-, 3.3-3.69 = B+, 3.0-3.29 = B, 2.7-2.99 = B-, etc.

### Timeline Adjustment

- **Pre-release:** Double-weight Security and Performance findings
- **Post-release:** Standard weights
- **Planning:** Double-weight Architecture and Testing findings

---

## Step 7: Output Format

Structure the report as follows. Write to `.agents/research/YYYY-MM-DD-tech-reportcard.md`.

### 1. Executive Summary (2-3 sentences)

A narrative overview a developer can read in 10 seconds. Example:
> This codebase has clean architecture and strong security practices but carries significant concurrency debt ahead of Swift 6. Testing coverage is the biggest gap — only ViewModels have tests. Accessibility needs attention before App Store submission.

### 2. CLAUDE.md Summary (if included)

3-5 bullet points from CLAUDE.md. If excluded, note: "CLAUDE.md was excluded per user request."

### 3. Project Metrics

```
Swift Files: 142 | LOC: ~28k | Architecture: MVVM | Persistence: SwiftData
Unit Tests: 47 | UI Tests: 12 | Test Framework: Swift Testing
```

### 4. Grade Summary Line

```
Overall: B+ (Arch A- | Quality B+ | Perf B | Concurrency B- | Security A | A11y C+ | Testing C+ | UI B+ | Data B)
```

### 5. Trend Comparison (if previous report exists)

```
vs Previous (YYYY-MM-DD):
  Architecture: B+ → A- (↑) | Testing: C → C+ (↑) | Security: A → A (→)
```

### 6. Per-Category Grades

For each category, provide:
- **Grade** and 1-sentence summary
- **Strengths** — what's done well (bullet list)
- **Findings** — confirmed issues only (NOT grep counts)

Example:
```
### Architecture: A-
Clean MVVM with proper separation of concerns.

**Strengths:**
- ViewModels use @MainActor correctly for SwiftData access
- Dependency injection via protocols enables testability

**Findings:**
- ItemListViewModel.swift (892 lines) exceeds 500-line threshold
- 2 circular import patterns between Managers/ and Views/
```

### 7. Issue Rating Table

Consolidate ALL findings into a single Issue Rating Table, sorted by urgency descending then ROI:

```
| # | Finding | Urgency | Risk: Fix | Risk: No Fix | ROI | Blast Radius | Fix Effort |
|---|---------|---------|-----------|-------------|-----|-------------|------------|
| 1 | ... | 🔴 Critical | ... | ... | ... | ... | ... |
| 2 | ... | 🟡 High | ... | ... | ... | ... | ... |
```

Use the Issue Rating scale:
- **Urgency:** 🔴 CRITICAL (pre-launch blocker/crash risk) · 🟡 HIGH (fix before release) · 🟢 MEDIUM (schedule it) · ⚪ LOW (nice-to-have)
- **Risk Fix/No Fix:** 🔴 Critical · 🟡 High · 🟢 Medium · ⚪ Low
- **ROI:** 🟠 Excellent · 🟢 Good · 🟡 Marginal · 🔴 Poor
- **Blast Radius:** 🔴 Critical · 🟡 High · 🟢 Medium · ⚪ Low
- **Fix Effort:** Trivial / Small / Medium / Large

### 8. Next Steps

Group by timeline:

```
Immediate (This Week):
- [Finding #1] — one-line rationale

Short-term (This Month):
- [Finding #3] — one-line rationale

Medium-term (This Quarter):
- [Finding #5] — one-line rationale
```

---

## Step 8: Follow-up

After presenting the report, ask:

```
AskUserQuestion with questions:
[
  {
    "question": "What would you like to do next?",
    "header": "Next",
    "options": [
      {"label": "Fix critical issues now", "description": "Walk through each critical/high issue with code fixes"},
      {"label": "Create implementation plan", "description": "Generate a prioritized plan from the findings"},
      {"label": "Report is sufficient", "description": "End here — report saved to .agents/research/"}
    ],
    "multiSelect": false
  }
]
```

If "Fix critical issues now": Walk through each 🔴/🟡 finding, show the problematic code, propose a fix, and apply after user approval.

If "Create implementation plan": Group findings into phases and present as a structured plan.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Too many grep hits to verify | Narrow glob pattern (e.g., `**/*View*.swift` instead of `**/*.swift`) |
| Category has no findings | Grade A — note "No issues detected" and list what was scanned |
| Can't determine architecture pattern | Read the app entry point and 3-4 representative views to infer |
| Previous report has different categories | Compare only matching categories in trend |
