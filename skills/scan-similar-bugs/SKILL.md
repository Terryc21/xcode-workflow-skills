---
name: scan-similar-bugs
description: 'After fixing a bug, systematically find other instances of the same pattern. Triggers: "scan for similar bugs", "find other instances", "check for similar issues", "scan similar bugs".'
version: 2.1.0
author: Terry Nyberg
license: MIT
allowed-tools: [Grep, Glob, Read, Write, Edit, Bash, AskUserQuestion]
metadata:
  tier: execution
  category: debugging
---

# Scan Similar Bugs

> **Quick Ref:** After fixing a bug, search codebase for similar anti-patterns. Output: `.agents/research/YYYY-MM-DD-similar-bugs-*.md`

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

---

## Step 1: Determine Bug Pattern Source

```
AskUserQuestion with questions:
[
  {
    "question": "How should I identify the bug pattern?",
    "header": "Source",
    "options": [
      {"label": "Describe the bug", "description": "I'll tell you what pattern to find"},
      {"label": "Infer from recent fix", "description": "Analyze what we just fixed in this session"}
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

## Step 2A: If User Describes the Bug

Ask the user to describe the pattern, then summarize:

```markdown
**Bug Pattern:** [summarized pattern]
**Anti-pattern:** [what the bad code looks like]
**Correct Pattern:** [what it should be instead]
**Will Search:** [file types/directories]
```

Confirm with AskUserQuestion:

```
AskUserQuestion with questions:
[
  {
    "question": "Does this match what you're looking for?",
    "header": "Confirm",
    "options": [
      {"label": "Yes, scan now", "description": "Start scanning with this pattern"},
      {"label": "Let me clarify", "description": "I'll refine the description"},
      {"label": "Cancel", "description": "Stop — don't scan"}
    ],
    "multiSelect": false
  }
]
```

---

## Step 2B: If Inferring from Recent Fix

Analyze the recent changes in this session:
1. Review the edits made (use conversation context)
2. Identify the anti-pattern that was fixed:
   - What was wrong? (the bug)
   - What was the fix? (correct pattern)
   - Why was it wrong? (root cause)

Present inference and confirm before proceeding (same AskUserQuestion as 2A).

---

## Step 3: Execute the Scan

### 3.1: Search for Anti-Pattern

Build grep patterns based on the identified bug pattern:

```bash
# Example: Find sheets attached to sections
Grep pattern="\.sheet\(isPresented" glob="**/*.swift" output_mode="files_with_matches"

# Example: Find force unwraps
# INTENTIONAL: as! after guard let/is check is already validated
Grep pattern="as!" glob="**/*.swift"

# Example: Find closures missing weak self
# INTENTIONAL: SwiftUI struct views don't need [weak self] — only flag classes
Grep pattern="\.sink\s*\{[^}]*self\." glob="**/*ViewModel*.swift"
Grep pattern="\.sink\s*\{[^}]*self\." glob="**/*Manager*.swift"
```

### 3.2: Check Git History (Optional)

```bash
# Find when the anti-pattern was introduced
git log -p -S "<anti_pattern_code>" --all -- "*.swift" | head -30
```

### 3.3: Verification Rule

Before classifying ANY match:

1. **Read the flagged file** — at minimum 20 lines around the match
2. **Check for intentional usage** — comments, validation guards, design patterns
3. **Check structural context** — a pattern inside a guard/if-let chain may be safe
4. **Classify** as:
   - **BUG:** Matches anti-pattern, needs fix
   - **OK:** Correct usage, no action needed
   - **REVIEW:** Unclear, needs human review

---

## Step 4: Generate Report

**Display the summary table and all findings inline**, then write to `.agents/research/YYYY-MM-DD-similar-bugs-<name>.md`:

```markdown
# Similar Bug Scan: [Bug Pattern Name]

**Date:** YYYY-MM-DD
**Pattern:** [Anti-pattern description]
**Correct:** [Correct pattern description]
**Files Scanned:** N

## Summary

| Status | Count |
|--------|-------|
| Bugs Found | X |
| OK (Correct Usage) | Y |
| Needs Review | Z |

## Bugs Found

### 1. [File:Line]
**Current code:**
```swift
// problematic code
```

**Should be:**
```swift
// suggested fix
```

### 2. [File:Line]
...

## Correct Usage (Reference)
These instances use the correct pattern:
- file.swift:123 — [brief note]

## Needs Review
These instances are unclear:
- file.swift:456 — [why unclear]
```

---

## Step 5: Follow-up

```
AskUserQuestion with questions:
[
  {
    "question": "How would you like to proceed?",
    "header": "Next",
    "options": [
      {"label": "Fix all bugs now", "description": "Walk through each BUG finding and apply fixes"},
      {"label": "Fix selected bugs", "description": "I'll choose which ones to fix"},
      {"label": "Report is sufficient", "description": "I'll handle fixes manually"}
    ],
    "multiSelect": false
  }
]
```

If fixing: Walk through each BUG finding, show the problematic code, propose a fix, apply after user approval.

---

## Common Bug Patterns

| Pattern | Anti-Pattern | Correct | Notes |
|---------|-------------|---------|-------|
| Sheet placement | `.sheet` on Section/child view | `.sheet` on NavigationStack/body | Causes unexpected dismissal |
| Force unwrap | `as!` without prior validation | Optional binding or guard | INTENTIONAL if after `is` check |
| Closure capture | Strong `self` in escaping closure in class | `[weak self]` in classes | INTENTIONAL in SwiftUI struct views |
| Main thread | UI update off main thread | `@MainActor` or `.task {}` | Check async context |
| State in body | `@State` computed in `var body` | `@State` at view declaration level | Resets on every render |
| Missing predicate | `@Query var items` with client-side filter | `@Query(filter:)` with predicate | INTENTIONAL if view needs all records |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Too many matches | Narrow the glob to specific directories (e.g., `**/*ViewModel*.swift`) |
| Can't infer bug from session | Ask user to describe the pattern instead |
| Pattern too broad | Ask user to narrow scope to specific files/directories |
| All matches are correct usage | Report zero bugs — the pattern may be localized to the original file |
| Mixed intentional and buggy | Classify each individually — don't batch-judge |
