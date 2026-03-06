---
name: review-changes
description: 'Pre-commit review of staged/unstaged changes for bugs, security, performance, and missing tests. Scoped to changed files only. Triggers: "review changes", "review my code", "check before commit", "pre-commit review".'
version: 2.1.0
author: Terry Nyberg
license: MIT
allowed-tools: [Bash, Glob, Grep, Read, Write, LSP, AskUserQuestion]
metadata:
  tier: execution
  category: analysis
---

# Review Changes

> **Quick Ref:** Pre-commit code review scoped to changed files. Output: inline summary with Issue Rating Table.

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

All findings use the **Issue Rating Table** format. Do not use prose severity tags.

---

## Step 1: Identify Changes

### 1.1: Get Changed Files

```bash
# Check what's staged vs unstaged
git status --short

# Get staged changes (preferred — these are what will be committed)
git diff --staged --name-only

# If nothing staged, get all uncommitted changes
git diff --name-only
```

Note which mode you're using: staged, unstaged, or last commit (`git diff HEAD~1 --name-only`).

### 1.2: Get Full Diff

```bash
# Staged diff with context
git diff --staged

# Or unstaged
git diff
```

### 1.3: Read Each Changed File

For every changed `.swift` file, **read the full file** to understand context:

```
Read file_path="path/to/changed/file.swift"
```

**Important:** Don't review diffs in isolation. Read the full file to understand surrounding context, imports, class structure, and existing patterns.

### 1.4: CLAUDE.md Check (Optional)

If the project has a CLAUDE.md, read it to understand project-specific coding standards and conventions. Apply those standards during the review.

---

## Step 2: Review Each Changed File

For every changed file, check for these patterns. **Only flag issues in changed or added lines** — don't report pre-existing issues in untouched code.

### 2.1 Correctness

Look in the diff for:

```bash
# Force casts — crash if wrong type
# FALSE POSITIVE: as! after guard let/is check is already validated
Grep pattern="as!" path="<changed_file>"

# Force try — crashes on error instead of handling
Grep pattern="try!" path="<changed_file>"

# Bare try? — silently swallows errors
# FALSE POSITIVE: try? where nil is the designed fallback
# INTENTIONAL: try? for operations where failure is acceptable (e.g., file deletion)
Grep pattern="try\?" path="<changed_file>"

# Empty catch blocks — swallowing errors
Grep pattern="catch\s*\{\s*\}" path="<changed_file>"
```

Also check manually:
- Off-by-one errors in loops and array indexing
- Boundary conditions (empty arrays, zero values)
- Boolean logic inversions (`&&` vs `||`, misplaced `!`)
- Switch statements missing cases (without `@unknown default`)

### 2.2 Security

```bash
# Hardcoded secrets in changed files
Grep pattern="(api[_-]?key|apikey|secret[_-]?key|client[_-]?secret)\s*[:=]\s*[\"'][^\"']+[\"']" path="<changed_file>" -i

# Sensitive data being logged
Grep pattern="(print|NSLog|os_log|Logger).*\b(password|token|secret|credential)" path="<changed_file>" -i

# HTTP URLs (non-HTTPS)
# FALSE POSITIVE: http://localhost, XML namespace URIs
Grep pattern="http://" path="<changed_file>"
```

### 2.3 Performance

Look in the diff for:
- File I/O or network calls not in async/Task context
- Formatters (`DateFormatter()`, `NumberFormatter()`) created inside view body (should be cached)
- `@Query` without predicate when only a subset is needed (INTENTIONAL if view genuinely needs all records)
- Sorting/filtering in `var body` (recomputed every render)

### 2.4 Concurrency

Look in the diff for:
- `DispatchQueue.main.async` — should this use `@MainActor` instead?
- `Task {}` in a non-isolated context — does it need `@MainActor`?
- Mutable `var` properties in classes accessed from multiple tasks without actor protection
- Missing `@MainActor` on ViewModels that access `ModelContext`

### 2.5 SwiftUI Patterns

Look in the diff for:
- `@ObservedObject` where `@StateObject` is needed (object recreated on view rebuild)
- `@StateObject` or `@ObservedObject` with `@Observable` classes (should use `@State` instead — iOS 17+)
- `@State` with non-`@Observable` reference types (won't trigger updates)
- Bare `Task {}` in view body instead of `.task {}` modifier
- Missing loading/error states for async operations

### 2.6 Style & Consistency

Read surrounding code in each changed file to verify:
- Naming conventions match existing patterns (camelCase, PascalCase)
- Error handling style is consistent (Result vs throws vs optional)
- File organization matches (MARK sections, property ordering)
- No leftover `print()` debug statements

### 2.7 Code Duplication

For key functions/patterns in the diff, search for similar existing code:

```bash
# Search for similar patterns already in codebase
Grep pattern="<key_pattern_from_diff>" glob="**/*.swift" output_mode="files_with_matches"
```

If duplicate logic exists, flag it and suggest extracting to a shared function.

---

## Step 3: Verification Rule

Before reporting ANY finding:

1. **Confirm it's in changed/added code** — don't flag pre-existing issues
2. **Read context** — at minimum 20 lines around the match
3. **Check for intentional patterns** — `try?` may be designed fallback, `as!` may follow validation
4. **Use LSP when available** — `findReferences` to check if a new function is called, `goToDefinition` to verify types
5. **Classify** — CONFIRMED, FALSE_POSITIVE, or PRE_EXISTING

---

## Step 4: Test Coverage Check

### 4.1: Find Existing Tests

```bash
# Find test files for each changed source file
# If changed: Sources/Features/Scanner/ScannerViewModel.swift
# Look for: Tests/**/Scanner*Tests.swift
Glob pattern="**/*Tests.swift"
```

### 4.2: Evaluate Test Needs

| Change Type | Test Needed? |
|-------------|--------------|
| New public function/method | Yes — unit test |
| Bug fix | Yes — regression test |
| New UI view | Consider — snapshot or UI test |
| Refactor (no behavior change) | Existing tests should still pass |
| Config/constant change | Usually no |

### 4.3: Flag Missing Tests

If important new logic lacks tests, note it in the report.

---

## Step 5: Generate Review Report

**Display the full review summary, issue table, and verdict inline:**

```markdown
## Code Review Summary

**Scope:** [staged / unstaged / last commit]
**Files Changed:** N
**Lines Added/Removed:** +X / -Y
**Verdict:** [Ready to commit / Needs fixes / Blocked]

## Positive Notes

[Anything done well — good patterns, clean code, proper error handling]

## Issue Rating Table

| # | Finding | Urgency | Risk: Fix | Risk: No Fix | ROI | Blast Radius | Fix Effort |
|---|---------|---------|-----------|-------------|-----|-------------|------------|
| 1 | file.swift:45 — Force unwrap of optional `item.category!` | 🟡 High | ⚪ Low | 🟡 High | 🟠 Excellent | ⚪ 1 file | Trivial |

## Test Coverage

| Changed File | Has Tests? | Tests Needed? |
|--------------|------------|---------------|
| ItemDetailVM.swift | Yes (12 tests) | Add edge case for nil category |
| NetworkService.swift | No | Yes — unit tests for new endpoint |

## Verdict

[One of:]
- **Ready to commit.** No issues found.
- **N issues found.** Address items #1, #2 before committing. Item #3 is optional.
- **Blocked.** Critical issues #1, #2 must be fixed first.
```

Use the Issue Rating scale:
- **Urgency:** 🔴 CRITICAL (crash/data loss) · 🟡 HIGH (fix before commit) · 🟢 MEDIUM (should fix) · ⚪ LOW (nice-to-have)
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
      {"label": "Fix issues now", "description": "Walk through each issue with fixes, then re-review"},
      {"label": "Commit as-is", "description": "Issues noted but acceptable for now"},
      {"label": "Review is sufficient", "description": "I'll fix manually"}
    ],
    "multiSelect": false
  }
]
```

If "Fix issues now": Walk through each finding, show the problematic code, propose a fix, apply after user approval. After all fixes, re-run a quick review to confirm.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| No staged changes | Fall back to `git diff` for unstaged, or `git diff HEAD~1` for last commit |
| Too many changed files | Focus on `.swift` files first; skip assets, configs unless security-relevant |
| Pre-existing issues tempting to fix | Note them separately as "out of scope" — don't mix with review findings |
| Can't determine if pattern is intentional | Read 30+ lines of context; check if there's a comment explaining the choice |
| Changed file is a test file | Review test quality: assertions present, edge cases covered, no `sleep()` |
