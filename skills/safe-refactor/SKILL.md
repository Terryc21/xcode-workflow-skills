---
name: safe-refactor
description: 'Plan refactoring with blast radius analysis, dependency mapping, and rollback strategy. Triggers: "refactor", "safe refactor", "restructure", "rename type", "extract protocol".'
version: 2.2.0
author: Terry Nyberg
license: MIT
allowed-tools: [Glob, Grep, Read, Bash, Edit, Write, LSP, AskUserQuestion]
metadata:
  tier: analysis
  category: refactoring
---

# Safe Refactor

> **Quick Ref:** Blast radius analysis → dependency mapping → step-by-step plan → verify after each step. Every commit compiles and passes tests. Output: `.agents/research/YYYY-MM-DD-refactor-{target}.md`

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

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

## Step 1: Identify Refactoring Candidates

Scan for files exceeding file size thresholds and display a risk assessment table.

### 1.1: Find Oversized Files

Check CLAUDE.md for project-specific file size guidelines. If none exist, use these defaults:

| Type | Pattern | Target | Refactor Trigger |
|------|---------|--------|-----------------|
| Views | `*View*.swift` | <400 | >600 lines |
| ViewModels | `*ViewModel*.swift` | <300 | >500 lines |
| Managers/Services | `*Manager*.swift`, `*Service*.swift` | <400 | >600 lines |
| Models | `*Model*.swift`, `*+*.swift`, `*Enums*.swift` | <600 | >1000 lines |

```bash
# First: check CLAUDE.md for project-specific thresholds
Grep pattern="File Size|Split When|lines" path="CLAUDE.md" output_mode="content"
# If found, use those thresholds instead of the defaults above

# Find files exceeding thresholds (exclude Tests/ and generated code)
# Adjust the numeric thresholds below if CLAUDE.md defines different values

# Views over trigger
find Sources -name "*View*.swift" -not -path "*/Tests/*" -exec wc -l {} + | sort -rn | awk '$1 > 600 {print}'

# ViewModels over trigger
find Sources -name "*ViewModel*.swift" -exec wc -l {} + | sort -rn | awk '$1 > 500 {print}'

# Managers/Services over trigger
find Sources \( -name "*Manager*.swift" -o -name "*Service*.swift" \) -not -path "*/Tests/*" -exec wc -l {} + | sort -rn | awk '$1 > 600 {print}'

# Models over trigger
find Sources \( -name "*Model*.swift" -o -name "*Enums*.swift" \) -not -path "*/Tests/*" | xargs wc -l | sort -rn | awk '$1 > 1000 {print}'
```

### 1.2: Gather Risk Metrics

For each oversized file, collect:

```bash
# For each file: line count, function count, #if os blocks, struct/class/extension blocks
lines=$(wc -l < "$file")
funcs=$(grep -cE "^\s+(func |private func |static func )" "$file")
platform=$(grep -cE "#if os\(|#if canImport" "$file")
blocks=$(grep -cE "^(struct|class|extension|enum) " "$file")

# Check for test coverage
find Tests -name "*${basename}*" | wc -l
```

### 1.3: Display Risk Assessment Table

Present one table per file type, using the Issue Rating Table format (from CLAUDE.md if defined, otherwise use the scale below):

```markdown
## Refactoring Risk Assessment — Oversized Files

### Views (trigger: >600 lines)

| # | File | Lines | Over | Urgency | Risk: Fix | Risk: No Fix | ROI | Blast Radius | Fix Effort | Tests |
|---|------|-------|------|---------|-----------|-------------|-----|-------------|------------|-------|
| 1 | `FileName.swift` | N | +N | 🟢/🟡/⚪ | 🟢/🟡/⚪ | 🟢/🟡/⚪ | 🟠/🟢/🟡/🔴 | 🟢/🟡/⚪ | S/M/L | Yes/No/Partial |

### ViewModels (trigger: >500 lines)
...

### Managers/Services (trigger: >600 lines)
...

### Models (trigger: >1000 lines)
...
```

**Rating scale** (use CLAUDE.md scale if project defines one):

| Indicator | General meaning | ROI meaning |
|-----------|----------------|-------------|
| 🔴 | Critical / high concern | Poor return |
| 🟡 | High / notable | Marginal return |
| 🟢 | Medium / moderate | Good return |
| ⚪ | Low / negligible | — |
| 🟠 | Pass / positive | Excellent return |

**Rating guidelines for file-size refactoring:**
- **Urgency**: 🟡 High if file is actively being modified (frequent merge conflicts); 🟢 Medium if over by >100 lines; ⚪ Low if barely over threshold
- **Risk: Fix**: 🟡 High if many `#if os` blocks (>8) or no test coverage; 🟢 Medium if moderate complexity; ⚪ Low if isolated
- **Risk: No Fix**: 🟡 High if causing merge conflicts or blocking other work; 🟢 Medium if growing; ⚪ Low if stable
- **ROI**: 🔴 Poor if barely over threshold (<20 lines); 🟡 Marginal if high blast radius; 🟢 Good if isolated with clear split points; 🟠 Excellent if blocking other work
- **Blast Radius**: Based on downstream dependents (grep for type name usage)
- **Fix Effort**: Small (<2h), Medium (2-4h), Large (4h+)

If no files exceed thresholds, report "All files within size guidelines — no refactoring candidates found" and skip to Step 2.

---

## Step 2: Gather Refactoring Details

If Step 1 found candidates, ask the user to pick a target. Otherwise, ask what they want to refactor.

```
AskUserQuestion with questions:
[
  {
    "question": "What kind of refactoring?",
    "header": "Refactor type",
    "options": [
      {"label": "Rename/Move", "description": "Rename a type, function, or move files to a new location"},
      {"label": "Extract", "description": "Extract protocol, split type, pull out shared code"},
      {"label": "Restructure", "description": "Change architecture pattern (e.g., add view model, change DI)"},
      {"label": "Simplify", "description": "Reduce complexity, remove duplication, flatten hierarchy"}
    ],
    "multiSelect": false
  }
]
```

Collect:
- **Target code** — What's being refactored (from Step 1 table or user-specified)
- **Reason** — Tech debt, performance, readability, pattern change
- **Desired end state** — How it should look after

### Freshness

Base all analysis on current source code only. Do not read or reference
files in `.agents/`, `scratch/`, or prior audit reports. Every dependency
and blast radius finding must come from scanning the actual codebase as it
exists now.

---

## Phase 1: Scope Analysis

### 1.1: Identify Target Code

```bash
# Find the target type/file
Glob pattern="**/*TargetName*.swift"

# Read the target code
Read file_path="<path_to_target>"
```

### 1.2: Document Current State

After reading, note:
- What does this code do?
- How large is it? (lines, methods, properties)
- What patterns does it use currently?

---

## Phase 2: Dependency Mapping

### 2.1: Upstream Dependencies (what target imports/uses)

```bash
# Find imports in the target file
Grep pattern="^import " path="<target_file>" output_mode="content"

# Find types referenced in the target file
Grep pattern=":\s*\w+Service|:\s*\w+Manager|:\s*\w+Repository" path="<target_file>" output_mode="content"
```

Record:

| Dependency | Type | Risk if Changed |
|------------|------|-----------------|
| NetworkService | Protocol | Low — protocol won't change |
| Item | Model | Medium — property access may change |

### 2.2: Downstream Dependents (what imports/uses target)

```bash
# Option A: LSP (most accurate — handles type inference, renames)
LSP operation="findReferences" filePath="<target_file>" line=<N> character=<N>

# Option B: Grep fallback
# Find all files that reference the target type
Grep pattern="TargetTypeName" glob="**/*.swift" output_mode="files_with_matches"

# Find all usages of the target's public/internal API
Grep pattern="\.targetMethod\(|targetProperty" glob="**/*.swift" output_mode="content"
```

Record:

| Dependent | Type | Impact if Target Changes |
|-----------|------|--------------------------|
| ItemDetailView.swift | View | Must update — directly uses view model |
| ItemListView.swift | View | Low — only creates the view model |
| Tests/ItemViewModelTests.swift | Test | Must update — tests all public API |

---

## Phase 3: Blast Radius

### 3.1: Calculate Direct, Immediate, and Transitive Impact

```bash
# Direct: The target file itself

# Immediate: Files that directly reference the target
Grep pattern="TargetTypeName" glob="**/*.swift" output_mode="files_with_matches"

# Transitive: Files that reference the immediate dependents
# For each immediate file, search for ITS references
Grep pattern="ImmediateTypeName" glob="**/*.swift" output_mode="files_with_matches"
```

### 3.2: Summarize Blast Radius

| Risk Level | Files | Description |
|------------|-------|-------------|
| Direct | 1 | Target file |
| Immediate | N | Files that reference target |
| Transitive | N | Files that reference immediate dependents |

**Total Blast Radius:** N files

---

## Phase 4: Safety Checks

Before refactoring, verify:

- [ ] Code is committed (handled by Pre-flight check)
- [ ] All usages of the code being changed are understood (from Phase 2)
- [ ] All existing tests pass (verify if needed)

---

## Phase 5: Choose Strategy

| Approach | When to Use | Risk |
|----------|-------------|------|
| **Parallel Implementation** | Large changes, need old code during transition | Low — old code untouched until switch |
| **Incremental Migration** | Medium changes, can do piece by piece | Low — each step verified |
| **Big Bang** | Small changes, isolated code with good test coverage | Medium — all-or-nothing |

Use AskUserQuestion if the best approach isn't obvious.

---

## Phase 6: Step-by-Step Plan

Each step MUST leave the codebase compiling and tests passing.

Example plan format:

```
Step 1: Extract protocol from ItemDetailViewModel
  Files: ItemDetailViewModel.swift (new protocol), ItemDetailView.swift (type annotation)
  Commit: "Extract ItemDetailViewModelProtocol for testability"
  Verify: Build + tests pass

Step 2: Create MockItemDetailViewModel conforming to protocol
  Files: Tests/Mocks/MockItemDetailViewModel.swift (new)
  Commit: "Add mock view model for testing"
  Verify: Build + tests pass

Step 3: Update ItemDetailView to accept protocol instead of concrete type
  Files: ItemDetailView.swift
  Commit: "Use protocol type in ItemDetailView for dependency injection"
  Verify: Build + tests pass
```

---

## Phase 7: Verification

After each step:

- [ ] Build succeeds (no compiler errors or warnings)
- [ ] All tests pass
- [ ] Manual smoke test: [specific action to verify]

---

## Phase 8: Rollback Strategy

**If something goes wrong:**
- **Small steps committed?** → `git revert <commit-hash>` for the broken step
- **Not yet pushed?** → `git reset --hard <last-good-commit>`
- **Parallel implementation?** → Delete new code, old code is untouched

---

## Phase 9: Generate Report

**Display the refactoring plan and all findings inline**, then write to `.agents/research/YYYY-MM-DD-refactor-{target}.md`:

```markdown
# Refactoring Plan

**Date:** YYYY-MM-DD
**Target:** [type/file being refactored]
**Strategy:** Incremental / Parallel / Big Bang

## Blast Radius

| Risk Level | Files | Description |
|------------|-------|-------------|
| Direct | 1 | Target file |
| Immediate | N | Files that reference target |
| Transitive | N | Files that reference immediate dependents |
| **Total** | **N** | |

## Step-by-Step Plan

| Step | Change | Files | Commit Message |
|------|--------|-------|----------------|
| 1 | [change] | [files] | "message" |
| 2 | [change] | [files] | "message" |

## Status

| Step | Build | Tests | Verified |
|------|-------|-------|----------|
| 1 | ✓ / ✗ | ✓ / ✗ | ✓ / ✗ |
```

---

## Worked Example

```
User: "Refactor ItemHelper into a protocol so I can mock it in tests"

Phase 1 — Scope:
  Target: ItemHelper.swift (class, 120 lines, 8 methods)
  Reason: Can't mock in tests — concrete class with no protocol
  Desired: ItemHelperProtocol + ItemHelper + MockItemHelper

Phase 2 — Dependencies:
  Upstream: Foundation, SwiftData (Item model)
  Downstream: ItemDetailViewModel (uses 3 methods), ItemListViewModel (uses 1 method),
              2 test files (create ItemHelper directly)

Phase 3 — Blast Radius: 5 files (1 direct + 2 view models + 2 tests)

Phase 4 — Safety: Tests pass, clean git state ✓

Phase 5 — Strategy: Incremental (3 small steps)

Phase 6 — Plan:
  Step 1: Extract ItemHelperProtocol from ItemHelper (keep conformance)
          Commit: "Extract ItemHelperProtocol"
  Step 2: Update view models to use protocol type
          Commit: "Use ItemHelperProtocol in view models"
  Step 3: Create MockItemHelper + update tests
          Commit: "Add MockItemHelper for testing"

Phase 7 — Verify: Build + tests after each step ✓
```

---

## Refactoring Principles

1. **Never refactor and change behavior in the same commit**
2. **Each commit should compile and pass tests**
3. **Rename before restructure** — rename/move first, then modify
4. **Add tests before refactoring** — if coverage is low, add tests first
5. **Small steps** — many small commits > one big commit

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Blast radius too large (>20 files) | Consider parallel implementation or incremental approach |
| Can't find all dependents | Search for the type name as a string, not just usage patterns |
| Tests fail after step | Revert the step, re-analyze, try a smaller change |
| Circular dependencies found | Break the cycle first as a separate preparatory step |
| Rename causes test failures | Update tests in the same commit as the rename |
