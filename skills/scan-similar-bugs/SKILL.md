---
name: scan-similar-bugs
description: 'After fixing a bug, systematically find other instances of the same pattern. Triggers: "scan for similar bugs", "find other instances", "check for similar issues", "scan similar bugs".'
metadata:
  tier: execution
  dependencies:
    - bug-hunt  # for bug pattern identification
---

# Scan Similar Bugs Skill

> **Quick Ref:** After fixing a bug, search codebase for similar anti-patterns. Output: `.agents/research/YYYY-MM-DD-similar-bugs-*.md`

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

Systematic scan to find other instances of the same bug pattern after a fix.

## Step 1: Determine Bug Pattern Source

Ask the user how they want to identify the bug pattern:

```
I can scan for similar bugs in two ways:

1. **Describe the bug** - Tell me the pattern you want to find
   Example: "Sheet attached to Section instead of main body"

2. **Infer from recent fix** - I'll analyze what we just fixed
   I'll look at the changes from this session to identify the bug pattern

Which approach would you like?
```

Use the AskUserQuestion tool with these options:
- **Option 1: "Let me describe the bug pattern"** - User will provide description, then choose to proceed, clarify, edit, or cancel
- **Option 2: "Scan for the bug I just fixed"** - Infer from recent edits in this session

---

## Step 2A: If User Describes the Bug

Ask the user to describe the bug pattern they want to find:

```
Describe the bug pattern you're looking for.

Example: "Force unwrapping optionals without guards" or
"Closures that capture self strongly"
```

After the user provides their description, summarize your understanding and present options:

```
I understand you want to find:

**Bug Pattern:** [summarized pattern]
**Anti-pattern:** [what the bad code looks like]
**Correct Pattern:** [what it should be instead]
**Will Search:** [file types/directories]

How would you like to proceed?
```

Use AskUserQuestion with these options:
- **Option 1: "Proceed with scan"** - Start scanning with current understanding
- **Option 2: "Explain in simpler terms"** - User wants to clarify/simplify their description
- **Option 3: "Let me edit the description"** - User wants to refine what they described
- **Option 4: "Stop - cancel this scan"** - Exit the skill

If user selects Option 2 or 3, gather the updated description and present options again.
If user selects Option 4, exit gracefully with a message.
If user selects Option 1, proceed to Step 3.

---

## Step 2B: If Inferring from Recent Fix

Analyze the recent changes in this session:
1. Review the edits made (use conversation context)
2. Identify the anti-pattern that was fixed:
   - What was wrong? (the bug)
   - What was the fix? (correct pattern)
   - Why was it wrong? (root cause)

Example inference:
```
Based on our recent fix:
- **Bug Pattern:** `.sheet()` modifier attached to Section instead of stable parent
- **Why Wrong:** Section re-renders cause sheet dismissal
- **Correct Pattern:** `.sheet()` attached to main body/NavigationStack
- **Files to Scan:** *.swift files with .sheet() modifiers
```

Confirm with user before proceeding:
```
I identified this pattern from our recent fix:

**Anti-pattern:** [description]
**Should be:** [correct pattern]
**Will search:** [file patterns]

Does this look right? Should I proceed with the scan?
```

---

## Step 3: Execute the Scan

### 3.1: Search for Anti-Pattern

Use Grep to find instances of the bug pattern:

```bash
# Example: Find sheets attached to sections
Grep pattern=".sheet\(isPresented" glob="*.swift"

# Then read each file to check context
```

### 3.2: Analyze Each Instance

For each match found:
1. Read the surrounding context (50 lines)
2. Determine if it's the anti-pattern or correct usage
3. Classify as:
   - **BUG:** Matches anti-pattern, needs fix
   - **OK:** Correct usage, no action needed
   - **REVIEW:** Unclear, needs human review

### 3.3: Create Findings Report

Write report to `.agents/research/YYYY-MM-DD-similar-bugs-<name>.md`:

```markdown
# Similar Bug Scan: [Bug Pattern Name]

**Date:** YYYY-MM-DD
**Pattern:** [Anti-pattern description]
**Correct:** [Correct pattern description]

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
- file.swift:123 - [brief note]

## Needs Review
These instances are unclear:
- file.swift:456 - [why unclear]
```

---

## Step 4: Report to User

Summarize findings:
1. How many bugs found
2. How many correct usages (for reference)
3. How many need review
4. Location of detailed report
5. Ask if user wants to fix the bugs now

---

## Common Bug Patterns to Scan

| Pattern | Anti-Pattern | Correct |
|---------|-------------|---------|
| Sheet placement | `.sheet` on Section/child view | `.sheet` on NavigationStack/body |
| State in view | `@State` computed in body | `@State` at view level |
| Force unwrap | `!` without guard | Optional binding or guard |
| Closure capture | Strong self in closure | `[weak self]` |
| Main thread | UI update off main | `@MainActor` or `DispatchQueue.main` |

---

## Examples

### Example 1: User Describes Bug

**User says:** `/scan-similar-bugs`
**Agent asks:** Which approach?
**User selects:** "Let me describe the bug pattern"
**User says:** "Find places where we use force unwrap on optionals"

**Result:** Agent scans for `!` usage, filters out safe cases (IBOutlets, known-safe), reports risky force unwraps.

### Example 2: Infer from Fix

**User says:** `/scan-similar-bugs`
**Agent asks:** Which approach?
**User selects:** "Scan for the bug I just fixed"

**Agent infers:** We just moved `.sheet()` from Section to body because sheets were dismissing unexpectedly.

**Result:** Agent scans all `.sheet()` usages, finds 2 more attached to Sections, reports them.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Too many false positives | Refine search pattern, add context checks |
| Can't infer bug from session | Ask user to describe the pattern instead |
| Pattern too broad | Ask user to narrow scope (specific files/dirs) |
