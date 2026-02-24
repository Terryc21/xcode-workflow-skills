---
name: review-changes
description: 'Pre-commit review of staged changes for bugs, style issues, and missing tests. Concrete patterns, not just checklists. Triggers: "review changes", "review my code", "check before commit", "pre-commit review".'
version: 1.1.0
author: Terry Nyberg
license: MIT
allowed-tools: [Bash, Glob, Grep, Read, AskUserQuestion]
metadata:
  tier: execution
  category: analysis
---

# Review Changes

> **Quick Ref:** Pre-commit code review: correctness, security, performance, style, tests. Output: summary with file:line issues table.

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

Pre-commit review of staged/modified changes for bugs, style issues, and missing tests.

## Quick Commands

| Command | Description |
|---------|-------------|
| `/review-changes` | Review all uncommitted changes |
| `/review-changes --staged` | Review only staged changes |
| `/review-changes --last-commit` | Review the most recent commit |
| `/review-changes path/to/File.swift` | Review changes in a specific file |

---

## Step 1: Identify Changes

### 1.1: Get the Diff

```bash
# Check what's staged vs unstaged
git status --short

# Get staged changes (preferred — these are what will be committed)
git diff --staged --name-only

# If nothing staged, get all uncommitted changes
git diff --name-only

# For last commit review
git diff HEAD~1 --name-only
```

### 1.2: Get Full Diff Content

```bash
# Staged diff with context
git diff --staged

# Or unstaged diff
git diff

# Or last commit
git diff HEAD~1
```

### 1.3: Read Each Changed File

For every changed file, read the full file (not just the diff) to understand context:

```
# Read each changed file
Read file_path="Sources/Features/ItemDetail/ItemDetailViewModel.swift"
```

**Important:** Don't review diffs in isolation. Read the full file to understand surrounding context, imports, class structure, and patterns.

---

## Step 2: Correctness Review

For each changed file, check for these concrete patterns:

### 2.1: Null/Nil Safety

```
# Force unwraps (potential crash points)
Grep pattern="\\w+!" glob="*.swift" output_mode="content"
# Exclude IBOutlets and common safe patterns — review each manually

# Implicit unwrapped optionals in declarations
Grep pattern="var \\w+:.*\\!" glob="*.swift" output_mode="content"

# Force try (swallowing error details)
Grep pattern="try!" glob="*.swift" output_mode="content"

# Force cast (crash if wrong type)
Grep pattern="as!" glob="*.swift" output_mode="content"
```

### 2.2: Logic Errors

Look for in the diff:
- Off-by-one errors in loops and array indexing
- Boundary conditions (empty arrays, zero values, max values)
- Boolean logic inversions (`&&` vs `||`, `!` misplaced)
- Unreachable code after early returns
- Switch statements missing cases (without `@unknown default`)

### 2.3: Error Handling

```
# Functions that throw but callers might not handle errors
Grep pattern="try\\s" glob="*.swift" output_mode="content"

# Catch blocks that swallow errors silently
Grep pattern="catch\\s*\\{\\s*\\}" glob="*.swift" output_mode="content"

# Optional try that silently returns nil on error
Grep pattern="try\\?" glob="*.swift" output_mode="content"
```

### 2.4: Concurrency Issues

```
# Mutable state without actor/synchronization protection
# Look for var properties in classes that might be accessed from multiple tasks
Grep pattern="class \\w+[^{]*\\{" glob="*.swift" output_mode="content"

# @MainActor usage — is UI code properly isolated?
Grep pattern="@MainActor" glob="*.swift" output_mode="content"

# Task {} without checking cancellation
Grep pattern="Task\\s*\\{" glob="*.swift" output_mode="content"

# nonisolated access to actor state
Grep pattern="nonisolated" glob="*.swift" output_mode="content"
```

---

## Step 3: Security Review

```
# Hardcoded secrets, API keys, tokens
Grep pattern="(api[_-]?key|secret|token|password|credential)\\s*[:=]\\s*\"[^\"]+\"" glob="*.swift" -i output_mode="content"

# URLs with credentials embedded
Grep pattern="https?://[^@]+@" glob="*.swift" output_mode="content"

# Sensitive data being logged
Grep pattern="(print|NSLog|os_log|Logger).*\\b(password|token|secret|ssn|credit)" glob="*.swift" -i output_mode="content"

# User input used directly without validation
# (Look for text field values passed directly to URLs, database queries, etc.)
```

---

## Step 4: Performance Review

```
# Expensive operations that might be on main thread
# Look for file I/O, network calls, or heavy computation not in Task/async
Grep pattern="FileManager|URLSession|Data\\(contentsOf" glob="*.swift" output_mode="content"

# Large data operations without pagination
Grep pattern="fetchAll|\.fetch\\(" glob="*.swift" output_mode="content"

# String interpolation in loops (potential allocation overhead)
Grep pattern="for .* in .*(\"\\\\\\()" glob="*.swift" output_mode="content"

# Repeated work that could be cached
# (Look for identical function calls in the same scope)
```

---

## Step 5: SwiftUI-Specific Review

```
# Property wrapper usage
Grep pattern="@State |@StateObject |@ObservedObject |@EnvironmentObject |@Bindable |@Observable " glob="*.swift" output_mode="content"

# Common mistakes:
# - @ObservedObject when @StateObject is needed (object recreated on view rebuild)
# - @State for reference types (should use @StateObject or @State with @Observable)

# Expensive work in view body
# (Look for function calls, filtering, sorting inside body computed property)
Grep pattern="var body.*View" glob="*.swift" -A 20 output_mode="content"

# Missing .task or .onAppear for async loading
Grep pattern="Task\\s*\\{" glob="*.swift" output_mode="content"
# Verify these are inside .task { } modifier, not bare Task { } in init or body
```

---

## Step 6: Style & Consistency

### 6.1: Check Against Existing Patterns

Read surrounding code to verify the new code follows the same patterns:

- Naming conventions (camelCase functions, PascalCase types)
- File organization (MARK sections, property ordering)
- Error handling style (Result vs throws vs optional)
- Dependency injection style (init injection vs environment)

### 6.2: Code Duplication

```
# Search for similar patterns already in codebase
# Take a key function/pattern from the changed code and search for duplicates
Grep pattern="functionNameOrPattern" glob="*.swift" output_mode="files_with_matches"
```

If duplicate logic exists, flag it and suggest extracting to a shared function.

---

## Step 7: Test Coverage

### 7.1: Check for Existing Tests

```
# Find test files for the changed source files
# If changed: Sources/Features/Scanner/ScannerViewModel.swift
# Look for: Tests/**/ScannerViewModel*Tests.swift

Glob pattern="Tests/**/*Tests.swift"

# Check if the changed functions have test coverage
Grep pattern="test.*FunctionName|FunctionName" path="Tests" glob="*.swift"
```

### 7.2: Evaluate Test Needs

For each changed file, assess:

| Change Type | Test Needed? |
|-------------|--------------|
| New public function | Yes — unit test |
| Bug fix | Yes — regression test |
| New UI view | Consider — UI test or snapshot |
| Refactor (no behavior change) | Existing tests should still pass |
| Config/constant change | Usually no |

### 7.3: Flag Missing Tests

If important new logic lacks tests, note it in the report with a suggestion to run `/generate-tests`.

---

## Step 8: Generate Review Report

Present findings in this format:

```markdown
## Code Review Summary

**Scope:** [staged changes / unstaged / last commit]
**Files Changed:** N
**Lines Added/Removed:** +X / -Y
**Risk Level:** Low / Medium / High
**Recommendation:** Ready to commit / Needs fixes / Needs discussion

### Issues Found

| # | File:Line | Severity | Category | Issue | Suggested Fix |
|---|-----------|----------|----------|-------|---------------|
| 1 | ItemDetailVM.swift:45 | High | Correctness | Force unwrap of optional `item.category!` | Use `item.category ?? "Default"` |
| 2 | NetworkService.swift:89 | Medium | Security | API key hardcoded in source | Move to Keychain or .xcconfig |
| 3 | ListView.swift:23 | Low | Performance | Sorting in body — triggers on every rebuild | Move to computed property or .onChange |

### Positive Notes

- [Anything done well — good patterns, clean code, proper error handling]

### Test Coverage

| Changed File | Has Tests? | Tests Needed? |
|--------------|------------|---------------|
| ItemDetailVM.swift | Yes (12 tests) | Add edge case for nil category |
| NetworkService.swift | No | Yes — unit tests for new endpoint |

### Verdict

[One of:]
- ✅ **Ready to commit.** No issues found.
- ⚠️ **N issues found.** Address items #1, #2 before committing. Item #3 is optional.
- 🛑 **Blocked.** Critical issues #1, #2 must be fixed first.
```

---

## Worked Example

```
User: /review-changes

Step 1: git diff --staged --name-only
  → ItemDetailViewModel.swift
  → NetworkService.swift

Step 2: Read both files, review diff

Findings:
  #1 HIGH — ItemDetailViewModel.swift:45
     Force unwrap `item.category!` — will crash if category is nil
     Fix: Use nil coalescing `item.category ?? "Uncategorized"`

  #2 MEDIUM — NetworkService.swift:12
     API base URL hardcoded: "https://api.example.com"
     Fix: Move to configuration file or environment variable

  #3 LOW — ItemDetailViewModel.swift:78
     print() statement left in from debugging
     Fix: Remove or replace with os_log

Verdict: ⚠️ 3 issues found. Fix #1 (crash risk) before committing.
         #2 and #3 are recommended but not blocking.
```

---

## For iOS-Specific Code Review

This skill focuses on general code review patterns. For deep iOS-specific analysis:

- **Security deep-dive:** Run `/security-audit`
- **Performance deep-dive:** Run `/performance-check`
- **SwiftUI architecture:** Invoke Axiom agent `/axiom:audit swiftui-architecture`
- **Concurrency correctness:** Invoke Axiom agent `/axiom:audit concurrency`

---

## See Also

- `/debug` — When review reveals a bug that needs investigation
- `/security-audit` — For deeper security analysis
- `/scan-similar-bugs` — After fixing an issue found during review
- `/generate-tests` — Generate tests for uncovered changes
