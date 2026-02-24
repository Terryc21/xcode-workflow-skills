---
name: tech-talk-reportcard
description: Technical codebase analysis with A-F grades for architecture, security, performance, concurrency, accessibility, code quality, UI, testing, and tooling
version: 2.0.0
author: Terry Nyberg
license: MIT
allowed-tools: [Task, Glob, Grep, Read, Write, AskUserQuestion]
metadata:
  tier: analysis
  category: analysis
---

# Tech-Talk Report Card Generator

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

**Required output:** Every issue/finding MUST include Urgency, Risk, ROI, and Blast Radius ratings. Do not omit these ratings.

Generate a comprehensive technical report card for developers and technical stakeholders.

---

## Step 1: Initial Questions

**IMPORTANT**: Before reading any files, ask the user about analysis options:

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
    "question": "How would you like to run this analysis?",
    "header": "Mode",
    "options": [
      {"label": "Fast (parallel)", "description": "Multiple agents run simultaneously - faster, more prompts"},
      {"label": "Quiet (sequential)", "description": "Single agent, fewer prompts - takes longer"}
    ],
    "multiSelect": false
  },
  {
    "question": "What is your timeline for this audit?",
    "header": "Timeline",
    "options": [
      {"label": "Pre-release", "description": "Preparing for App Store - urgency matters"},
      {"label": "Post-release", "description": "App is live, ongoing improvement"},
      {"label": "Planning phase", "description": "Gathering info for roadmap"}
    ],
    "multiSelect": false
  },
  {
    "question": "Any categories to emphasize or skip?",
    "header": "Focus",
    "options": [
      {"label": "Full analysis (Recommended)", "description": "Grade all categories"},
      {"label": "Skip accessibility", "description": "Not prioritizing accessibility now"},
      {"label": "Skip backend", "description": "App is standalone, no backend"},
      {"label": "Emphasize performance", "description": "Users report slowness or battery drain"}
    ],
    "multiSelect": true
  }
]
```

**If user selects "Yes" for CLAUDE.md:** Read CLAUDE.md at the repo root and summarize its key points in 3-5 bullets. Use these guidelines throughout the analysis.

**If user selects "No":** Skip reading CLAUDE.md entirely. Note in the report that CLAUDE.md was intentionally excluded.

---

## Step 2: Check for Previous Reports

Before scanning, check for existing reports to enable trend comparison:

```bash
Glob pattern=".agents/research/*-tech-reportcard.md"
```

If previous reports exist, note the most recent one for comparison in the final output.

---

## Step 3: Codebase Exploration

Scan the project structure and key configuration files. Analyze:

1. **Project metrics** - File counts, LOC, targets, schemes
2. **Architecture & modules** - Main modules, patterns (MVC/MVVM/etc.), frameworks
3. **App purpose & features** - Purpose and primary user flows
4. **Data flow & state management** - How state is managed between layers

---

## Step 4: Automated Scans

Run these grep patterns to detect issues automatically. Execute all scans before compiling findings.

### 4.1 Architecture Patterns

```bash
# God classes - ViewModels > 500 lines (check manually after grep)
Grep pattern="class.*ViewModel" glob="**/*ViewModel.swift" output_mode="files_with_matches"

# Missing @MainActor on ObservableObject
Grep pattern="class.*:.*ObservableObject(?!.*@MainActor)" glob="**/*.swift"

# Circular dependencies (imports within same module)
Grep pattern="^import\s+" glob="**/*.swift" output_mode="content"
```

### 4.2 Security Patterns

```bash
# Hardcoded secrets
Grep pattern="(api[_-]?key|apikey|secret[_-]?key|client[_-]?secret|password|token)\s*[:=]\s*[\"'][^\"']+[\"']" glob="**/*.swift" -i

# Sensitive data in UserDefaults
Grep pattern="UserDefaults.*\.(password|token|secret|apiKey|credentials)" glob="**/*.swift" -i

# Force unwraps in auth code
Grep pattern="!" glob="**/*Auth*.swift"

# HTTP URLs (non-HTTPS)
Grep pattern="http://" glob="**/*.swift"

# Logging sensitive data
Grep pattern="(print|NSLog|os_log|Logger).*\((password|token|secret|key)" glob="**/*.swift" -i
```

### 4.3 Performance Patterns

```bash
# Missing [weak self] in closures
Grep pattern="\{\s*\[(?!weak|unowned)" glob="**/*.swift"

# @Query without predicate (full table scans)
Grep pattern="@Query\s+(private\s+)?var" glob="**/*.swift"

# Main thread file I/O
Grep pattern="(FileManager|Data\(contentsOf|String\(contentsOf)" glob="**/*View*.swift"

# Synchronous network calls
Grep pattern="\.dataTask\(.*\)\.resume\(\)" glob="**/*.swift"
```

### 4.4 Concurrency Patterns (Swift 6 Readiness)

```bash
# Sendable violations - mutable class without @unchecked
Grep pattern="class.*(?<!@unchecked Sendable)" glob="**/*.swift"

# Actor isolation issues
Grep pattern="nonisolated.*func.*async" glob="**/*.swift"

# Task without explicit priority
Grep pattern="Task\s*\{" glob="**/*.swift"

# Missing @MainActor on ViewModel
Grep pattern="(class|struct).*ViewModel(?!.*@MainActor)" glob="**/*ViewModel.swift"

# Dispatch to main thread (legacy pattern)
Grep pattern="DispatchQueue\.main\.(async|sync)" glob="**/*.swift"
```

### 4.5 Accessibility Patterns

```bash
# Missing accessibility labels on buttons/images
Grep pattern="Button\(.*\)\s*\{" glob="**/*.swift"
Grep pattern="Image\(" glob="**/*.swift"

# Check for accessibilityLabel usage
Grep pattern="\.accessibilityLabel" glob="**/*.swift" output_mode="count"

# Check for accessibilityIdentifier (UI testing)
Grep pattern="\.accessibilityIdentifier" glob="**/*.swift" output_mode="count"

# Dynamic Type support
Grep pattern="\.font\(\.system\(size:" glob="**/*.swift"
```

### 4.6 Testing Patterns

```bash
# Test file count
Glob pattern="**/*Tests.swift"
Glob pattern="**/*Test.swift"

# Swift Testing vs XCTest usage
Grep pattern="import Testing" glob="**/*Test*.swift" output_mode="count"
Grep pattern="import XCTest" glob="**/*Test*.swift" output_mode="count"

# Async test support
Grep pattern="@Test.*async" glob="**/*Test*.swift" output_mode="count"

# UI test coverage
Glob pattern="**/*UITests*.swift"
```

### 4.7 Energy Patterns

```bash
# Timer usage (potential battery drain)
Grep pattern="Timer\.(scheduledTimer|publish)" glob="**/*.swift"

# Continuous location
Grep pattern="startUpdatingLocation" glob="**/*.swift"

# Background tasks
Grep pattern="BGTaskScheduler" glob="**/*.swift"

# Polling patterns
Grep pattern="(while.*true|repeat.*while)" glob="**/*.swift"
```

---

## Step 5: Analysis Mode Execution

Based on the user's "Mode" selection:

**Fast (parallel):** Launch Task agents simultaneously with `subagent_type: Explore`:

| Agent | Focus | Axiom Skills to Reference |
|-------|-------|---------------------------|
| Architecture | Patterns, modularity, dependencies | `axiom-swiftui-architecture`, `axiom-app-composition` |
| Security | Auth, storage, network, secrets | (your `/security-audit`) |
| Performance | Memory, CPU, launch, SwiftUI | `axiom-ios-performance`, `axiom-swift-performance`, `axiom-swiftui-performance` |
| Concurrency | Swift 6, actors, Sendable | `axiom-ios-concurrency`, `axiom-swift-concurrency` |
| Testing | Coverage, framework, stability | `axiom-ios-testing`, `axiom-swift-testing` |

**Quiet (sequential):** Use direct `Read`, `Glob`, `Grep` tools in sequence, referencing Axiom skill patterns where relevant.

---

## Step 6: Grading Criteria

### Grade Scale

| Grade | Meaning | Criteria |
|-------|---------|----------|
| A | Excellent | Best practices followed, minimal issues |
| B | Good | Solid implementation, minor improvements needed |
| C | Adequate | Functional but has notable gaps |
| D | Poor | Significant issues requiring attention |
| F | Failing | Critical problems, not production-ready |

### Category Weights

| Category | Weight | Axiom Deep-Dive |
|----------|--------|-----------------|
| Architecture | 15% | `axiom-swiftui-architecture` |
| Code Quality | 10% | — |
| Performance | 15% | `axiom-ios-performance` |
| Concurrency | 10% | `axiom-ios-concurrency` |
| Security | 15% | `/security-audit` |
| Accessibility | 10% | `axiom-ios-accessibility` |
| Testing | 15% | `axiom-ios-testing` |
| UI/UX | 5% | `axiom-ios-ui`, `axiom-hig` |
| Data/Persistence | 5% | `axiom-ios-data` |

---

## Step 7: Output Format

### CLAUDE.md Summary (if included)
- Bullet 1
- Bullet 2
- Bullet 3

*If CLAUDE.md was ignored, display instead:*
> **Note:** CLAUDE.md was excluded from this analysis per user request.

### Project Metrics

```
**Swift Files:** 142 | **LOC:** ~28k | **Architecture:** MVVM | **Persistence:** SwiftData
**Unit Tests:** 47 | **UI Tests:** 12 | **Test Framework:** Swift Testing
```

### Grade Summary Line

```
**Overall: B+** (Arch A- | Quality B+ | Perf B | Concurrency B- | Security A | A11y C+ | Testing C+ | UI B+ | Data B)
```

### Trend Comparison (if previous report exists)

```
**vs Previous (2024-01-15):**
- Architecture: B+ → A- (↑)
- Testing: C → C+ (↑)
- Concurrency: C+ → B- (↑)
- Security: A → A (→)
```

### Grades with Technical Details

Present each category with grade and technical findings:

```markdown
### Architecture: A-
Clean MVVM with proper separation of concerns.
- ViewModels use `@MainActor` correctly for SwiftData access
- Dependency injection via protocols enables testability
- **[MED]** `ItemListViewModel.swift` (892 lines) exceeds 500-line threshold

**Axiom reference:** For refactoring patterns, see `axiom-swiftui-architecture`

### Concurrency: B-
Partial Swift 6 readiness with some legacy patterns.
- **[HIGH]** 12 ViewModels missing `@MainActor` annotation
- **[MED]** 8 uses of `DispatchQueue.main.async` should migrate to `@MainActor`
- `Sendable` conformance added to data transfer types

**Axiom reference:** For Swift 6 migration, see `axiom-ios-concurrency`

### Accessibility: C+
Basic support present, gaps in key areas.
- **[HIGH]** 23 Button views missing `.accessibilityLabel`
- **[MED]** 8 Image views missing accessibility descriptions
- Dynamic Type supported in 70% of text views
- VoiceOver tested on main flows

**Axiom reference:** For WCAG compliance, see `axiom-ios-accessibility`
```

### Technical Debt Summary

```markdown
### Technical Debt

| Severity | Count | Top Issues |
|----------|-------|------------|
| **[HIGH]** | 3 | Missing @MainActor, God class, No error handling |
| **[MED]** | 8 | Deprecated APIs, Missing accessibility, Legacy concurrency |
| **[LOW]** | 12 | Code style, Documentation gaps |
```

### Prioritized Issues

```markdown
### Prioritized Issues

**1. Add @MainActor to ViewModels** — Urgency: High | Risk: Med | ROI: High | Blast: 12 files
   Swift 6 will require this. Add `@MainActor` to all ViewModels accessing UI state.

**2. ItemListViewModel refactor** — Urgency: High | Risk: Med | ROI: High | Blast: 8 files
   Split into ItemListViewModel, SearchViewModel, FilterViewModel

**3. Accessibility labels** — Urgency: Med | Risk: Low | ROI: High | Blast: 15 files
   Add `.accessibilityLabel()` to all interactive elements
```

### Next Steps

```markdown
### Immediate (This Week)
- **Add @MainActor to ViewModels** — Prevents Swift 6 migration pain
- **Fix accessibility labels** — App Store may reject for accessibility gaps

### Short-term (This Month)
- **Refactor ItemListViewModel** — Split into focused ViewModels under 400 lines
- **Migrate DispatchQueue to async/await** — Modern concurrency patterns

### Medium-term (This Quarter)
- **Performance profiling** — Add signposts and run Time Profiler
- **Increase test coverage** — Target 80% for ViewModels
```

---

## Step 8: Deep Dive Option

After presenting the report, offer category-specific deep dives:

> **Note:** Deep dives require [Axiom](https://github.com/CharlesWiltgen/Axiom) to be installed. If Axiom is not available, skip this step or inform the user they can install Axiom for deeper analysis.

```
AskUserQuestion with questions:
[
  {
    "question": "Would you like a deep dive into any category?",
    "header": "Deep Dive",
    "options": [
      {"label": "Performance deep dive", "description": "Requires Axiom - Instruments workflows and profiling guidance"},
      {"label": "Concurrency audit", "description": "Requires Axiom - Swift 6 compliance and actor isolation"},
      {"label": "Accessibility audit", "description": "Requires Axiom - WCAG compliance and VoiceOver testing"},
      {"label": "Memory leak check", "description": "Requires Axiom - retain cycle detection with Instruments"},
      {"label": "No deep dive needed", "description": "The overview is sufficient"}
    ],
    "multiSelect": true
  }
]
```

If user selects a deep dive:
- **Performance:** Invoke `axiom-ios-performance`
- **Concurrency:** Invoke `axiom-ios-concurrency`
- **Accessibility:** Invoke `axiom-ios-accessibility`
- **Memory:** Invoke `axiom-memory-debugging`

If Axiom is not installed, inform the user:
> Axiom is not installed. Install it with: `claude plugin install CharlesWiltgen/Axiom`

---

## Step 9: Follow-up Question

After deep dives (or if skipped), ask about implementation:

```
AskUserQuestion with questions:
[
  {
    "question": "Would you like me to create an implementation plan?",
    "header": "Next Steps",
    "options": [
      {"label": "Yes, plan immediate items", "description": "Detailed plan for high-priority actions"},
      {"label": "Yes, plan all items", "description": "Comprehensive implementation roadmap"},
      {"label": "No, report is sufficient", "description": "End here"}
    ],
    "multiSelect": false
  }
]
```

If user selects yes, invoke `/implementation-plan` with the selected items.

---

## Output

Write the report card to `.agents/research/YYYY-MM-DD-tech-reportcard.md` for future reference.

---

## Axiom Integration Reference

| Category | Axiom Skills | When to Invoke |
|----------|--------------|----------------|
| Architecture | `axiom-swiftui-architecture`, `axiom-app-composition` | Refactoring recommendations |
| Performance | `axiom-ios-performance`, `axiom-swift-performance`, `axiom-swiftui-performance` | Deep dive requested |
| Concurrency | `axiom-ios-concurrency`, `axiom-swift-concurrency` | Swift 6 migration |
| Memory | `axiom-memory-debugging` | Leak detection |
| Testing | `axiom-ios-testing`, `axiom-swift-testing` | Test framework guidance |
| Accessibility | `axiom-ios-accessibility` | WCAG compliance audit |
| Data | `axiom-ios-data`, `axiom-swiftdata` | Persistence patterns |
| UI | `axiom-ios-ui`, `axiom-hig` | Design compliance |
| Energy | `axiom-energy` | Battery drain issues |
| Navigation | `axiom-swiftui-nav` | Deep linking, state restoration |

---

## See Also

- `/plain-talk-reportcard` - Non-technical version for stakeholders
- `/performance-check` - Deeper performance analysis
- `/security-audit` - Deeper security analysis
- `/implementation-plan` - Create action plans from findings
