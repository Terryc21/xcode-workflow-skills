---
name: dead-code-scanner
description: 'Find unused code after refactors or as ongoing hygiene. Two modes: quick (post-refactor, recent changes) and full (entire codebase). Triggers: "find dead code", "find unused code", "cleanup unused", "dead code scan", "code hygiene".'
version: 2.1.0
author: Terry Nyberg
license: MIT
allowed-tools: [Grep, Glob, Read, Bash, LSP, Write, AskUserQuestion]
metadata:
  tier: execution
  category: analysis
---

# Dead Code Scanner

> **Quick Ref:** Find orphaned code after refactors or for ongoing hygiene. Output: `.agents/research/YYYY-MM-DD-dead-code-*.md`

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

**Required output:** Every finding MUST include Urgency, Risk, ROI, and Blast Radius ratings using the Issue Rating Table format. Do not omit these ratings.

**Safety Rule:** NEVER auto-delete code. Report only. Require explicit user approval for any removal.

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

## Step 1: Determine Scan Mode

```
AskUserQuestion with questions:
[
  {
    "question": "How would you like to scan for unused code?",
    "header": "Mode",
    "options": [
      {"label": "Quick (post-refactor)", "description": "Scan recently changed files only — fast and targeted"},
      {"label": "Full (hygiene)", "description": "Scan entire codebase — comprehensive, takes longer"},
      {"label": "Custom scope", "description": "I'll specify which files or directories to scan"}
    ],
    "multiSelect": false
  }
]
```

### Freshness

Base all findings on current source code only. Do not read or reference
files in `.agents/`, `scratch/`, or prior audit reports. Ignore cached
findings from auto-memory or previous sessions. Every finding must come
from scanning the actual codebase as it exists now.

---

## Step 2: Determine File Scope

### Quick Mode

```bash
# Get recently modified Swift files (last 5 commits)
git diff --name-only HEAD~5 | grep "\.swift$"
```

### Full Mode

```bash
# All Swift source files (excluding tests and generated code)
Glob pattern="**/*.swift"
# Manually exclude test files and generated code from the results
```

### Custom Mode

Ask user for specific paths, then:

```bash
Glob pattern="<user_specified_path>/**/*.swift"
```

---

## Step 3: Extract Declarations

For each file in scope, find private/fileprivate declarations:

```bash
# Private/fileprivate functions
Grep pattern="(private|fileprivate)\s+func\s+(\w+)" glob="**/*.swift" output_mode="content"

# Private/fileprivate types
Grep pattern="(private|fileprivate)\s+(class|struct|enum|protocol)\s+(\w+)" glob="**/*.swift" output_mode="content"

# Private/fileprivate properties
Grep pattern="(private|fileprivate)\s+(var|let)\s+(\w+)" glob="**/*.swift" output_mode="content"

# Private typealiases
Grep pattern="(private|fileprivate)\s+typealias\s+(\w+)" glob="**/*.swift" output_mode="content"
```

Build a symbol table from the results:

| Symbol | Type | Access | File | Line |
|--------|------|--------|------|------|
| formatDate | func | private | ItemHelper.swift | 45 |
| oldEndpoint | let | private | Constants.swift | 12 |

---

## Step 4: Scan for References

For each symbol in the table, search for usage. Prefer LSP when available:

```bash
# Option A: LSP (most accurate — handles type inference, protocol witnesses)
LSP operation="findReferences" filePath="path/to/file.swift" line=45 character=12

# Option B: Grep fallback (when LSP is unavailable)
Grep pattern="\bsymbolName\b" glob="**/*.swift" output_mode="content"
```

**Filter results — exclude:**
- The declaration line itself
- Comments (`//` or `/* */` context)
- String literals

**Classify each symbol:**

| Refs Found | Classification | Confidence |
|------------|----------------|------------|
| 0 references (private) | UNUSED | HIGH |
| 0 references (fileprivate) | UNUSED | HIGH |
| 0 references (internal) | UNUSED | MEDIUM |
| 1 reference (self-only) | UNUSED | HIGH |
| 1 reference (test-only) | TEST_ONLY | MEDIUM |

---

## Step 5: Apply Swift-Specific Exclusions

Do NOT flag these as unused (even with 0 references):

```swift
// Entry points & system callbacks
@main                          // App entry
@UIApplicationMain             // Legacy app entry
#Preview                       // SwiftUI previews
func application(              // UIApplicationDelegate
func scene(                    // UISceneDelegate

// Interface Builder & Objective-C
@IBAction                      // Storyboard actions
@IBOutlet                      // Storyboard connections
@objc                          // ObjC runtime visibility
dynamic                        // ObjC dynamic dispatch

// Codable synthesis
enum CodingKeys                // Codable
init(from decoder:             // Decodable
encode(to encoder:             // Encodable

// SwiftUI protocol requirements
var body: some View            // View protocol
func makeBody(                 // ViewModifier/Shape

// Intentionally kept
@available(*, deprecated       // Deprecated but kept for compatibility
```

Also check for string-based invocation:

```bash
# Selector-based calls (dynamic usage)
Grep pattern="#selector|NSSelectorFromString|perform\(Selector" glob="**/*.swift" output_mode="content"
```

Also check if a method satisfies a protocol requirement — protocol-required methods are not "unused" even if never called directly:

```bash
# Check if the type conforms to a protocol that requires this method
Grep pattern=":\s*\w+Protocol|:\s*\w+Delegate|:\s*\w+DataSource" path="<file_with_symbol>" output_mode="content"

# Or use LSP to find protocol implementations
LSP operation="goToImplementation" filePath="path/to/file.swift" line=45 character=12
```

---

## Step 6: Verify Before Reporting

Before reporting ANY finding:

1. **Read the flagged file** — at minimum 20 lines of context
2. **Check for `// dead-code:ignore` annotation** — inline marker to skip
3. **Check protocol conformance** — method may satisfy a protocol requirement
4. **Classify** — CONFIRMED, FALSE_POSITIVE, or EXCLUDED

---

## Step 7: Generate Report

**Display the summary table and all findings inline**, then write to `.agents/research/YYYY-MM-DD-dead-code-{mode}.md`:

```markdown
# Dead Code Scan Report

**Date:** YYYY-MM-DD
**Mode:** Quick (HEAD~5) / Full
**Files Scanned:** N
**Symbols Analyzed:** N

## Summary

| Confidence | Count | Action |
|------------|-------|--------|
| HIGH | X | Safe to remove |
| MEDIUM | Y | Verify before removing |

## Issue Rating Table

| # | Finding | Urgency | Risk: Fix | Risk: No Fix | ROI | Blast Radius | Fix Effort |
|---|---------|---------|-----------|-------------|-----|-------------|------------|
| 1 | `formatLegacyDate()` — private func, ItemHelper.swift:45 (15 lines, HIGH confidence) | 🟢 Medium | ⚪ Low | ⚪ Low | 🟠 Excellent | ⚪ 1 file | Trivial |
| 2 | `oldAPIEndpoint` — private let, Constants.swift:12 (HIGH confidence) | ⚪ Low | ⚪ Low | ⚪ Low | 🟠 Excellent | ⚪ 1 file | Trivial |
| 3 | `processLegacyData()` — internal func, DataManager.swift:89 (MEDIUM confidence, test-only ref) | ⚪ Low | 🟢 Medium | ⚪ Low | 🟡 Marginal | 🟢 2 files | Small |

Use the Issue Rating scale:
- **Urgency:** 🔴 CRITICAL (blocks build/causes crash) · 🟡 HIGH (confuses maintainers, hides real code) · 🟢 MEDIUM (clutters codebase) · ⚪ LOW (minor noise)
- **Risk: Fix:** Risk of removing the code (⚪ Low for HIGH confidence private, 🟡 High for MEDIUM confidence internal)
- **Risk: No Fix:** Cost of leaving dead code (confusion, build time, false grep hits)
- **ROI:** 🟠 Excellent · 🟢 Good · 🟡 Marginal · 🔴 Poor
- **Blast Radius:** How many files reference or import the dead symbol
- **Fix Effort:** Trivial (delete lines) / Small (delete + update imports) / Medium (extract or restructure) / Large (cross-module)

## Detailed Findings

### HIGH Confidence (Safe to Remove)

These symbols have no references and are private/fileprivate scope.

### 1. `formatLegacyDate()` — private func
**File:** Sources/Helpers/ItemHelper.swift:45
**Lines:** 15

```swift
// Current code (can be removed):
private func formatLegacyDate(_ date: Date) -> String {
    // ...
}
```

### 2. `oldAPIEndpoint` — private let
**File:** Sources/Config/Constants.swift:12

```swift
private let oldAPIEndpoint = "https://api.v1.example.com"
```

### MEDIUM Confidence (Verify First)

These need human review before removal.

### 3. `processLegacyData()` — internal func
**File:** Sources/Managers/DataManager.swift:89
**Note:** Only referenced in test file `DataManagerTests.swift:45`

## Excluded (Known Safe)

| Symbol | Reason |
|--------|--------|
| `handleIntent()` | @objc exposed |
| `body` | SwiftUI View protocol |
```

---

## Step 8: Follow-up

```
AskUserQuestion with questions:
[
  {
    "question": "How would you like to proceed?",
    "header": "Next",
    "options": [
      {"label": "Remove HIGH items", "description": "Walk through each safe-to-remove item with verification"},
      {"label": "Review MEDIUM items", "description": "Discuss ambiguous items before deciding"},
      {"label": "Report is sufficient", "description": "I'll handle removals manually"}
    ],
    "multiSelect": false
  }
]
```

If removing: For each item, show the code, confirm with user, remove, then verify the build still succeeds before moving to the next item.

---

## Git History (Quick Mode)

For unused symbols, find when they became orphaned:

```bash
# Find the commit that removed the last reference
git log -p -S "symbolName" --all -- "**/*.swift" | head -30
```

This helps understand why the symbol is now unused (e.g., a refactor removed the caller).

---

## Grep Patterns Reference

### Find Private Functions
```
(private|fileprivate)\s+func\s+(\w+)\s*\(
```

### Find Private Types
```
(private|fileprivate)\s+(class|struct|enum|protocol)\s+(\w+)
```

### Find Private Properties
```
(private|fileprivate)\s+(var|let)\s+(\w+)
```

### Find Unused Imports
```
^import\s+(\w+)
# Then check if any type from that module is used in the file
```

---

## Limitations

This skill may miss:
1. **Reflection-based calls** not in string form
2. **Protocol extensions** with complex generic constraints
3. **Cross-module usage** in multi-target projects
4. **Runtime-generated selectors**
5. **Storyboard/XIB references** (not in Swift files)

When in doubt, classify as MEDIUM confidence for human review.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Too many symbols to check | Narrow scope to specific directories or recent commits |
| Can't determine if symbol is used | Read 30+ lines of context, check for protocol conformance |
| Symbol is used only in tests | Classify as TEST_ONLY — flag for review, don't auto-remove |
| Internal symbol might be cross-module | Only scan private/fileprivate — skip internal unless confident |
| Build fails after removal | Revert immediately — the symbol was used via a path the scan missed |
