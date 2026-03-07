---
name: plan
description: Epic decomposition into trackable, right-sized tasks. Three modes — audit-aware (codebase-audit reports), workflow-audit-aware (handoff.yaml with pre-rated findings), standalone (from scratch). Light convention scanning for projects without CLAUDE.md.
version: 1.3.0
author: Terry Nyberg
license: MIT
allowed-tools: [Glob, Grep, Read, Write, AskUserQuestion]
metadata:
  tier: analysis
  category: planning
---

# Implementation Plan Generator

> **Quick Ref:** Mode detect → ingest or analyze → interactive input → understand → size → impact → phased plan → risk → test → rollback → write → proceed.

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

**Required output:** Every task MUST include Size, Urgency, Risk, ROI, Blast Radius, and LOE ratings. Do not omit these ratings.

> **Rating format:** See `skills/shared/rating-system.md` for column definitions, indicator scale, and table formatting rules.

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

## Golden Rule

> **Plans describe WHAT to change and WHERE — never HOW.**
>
> A plan task says: "Add keyboard dismissal to AddItemView.swift:45-80 and EditItemView.swift:32-60. Acceptance: tapping outside any text field dismisses the keyboard."
>
> A plan task does NOT say: "Add `.onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder)...) }`"
>
> **Exception:** Include code (≤10 lines) ONLY when referencing an existing pattern in the repo, showing a required API signature, or documenting a known framework gotcha. See [examples.md](examples.md) for calibration.

## Step 1: Mode Detection

Detect which mode to run in: **audit-aware**, **workflow-audit-aware**, or **standalone**.

```
# Check for codebase audit reports
Glob pattern=".agents/research/*-codebase-audit.md"
Glob pattern=".agents/research/*-tech-reportcard.md"

# Check for workflow audit handoff
Glob pattern=".workflow-audit/handoff.yaml"
```

**Decision logic:**

| Condition | Mode |
|-----------|------|
| User passes `--workflow-audit` | Workflow-audit-aware (error if no handoff found) |
| User specifies audit mode | Audit-aware (error if no report found) |
| User specifies standalone mode | Standalone (ignore all reports) |
| `.workflow-audit/handoff.yaml` found AND `audit_date` <14 days | Workflow-audit-aware |
| Codebase audit report found AND <14 days old | Audit-aware |
| Report found AND ≥14 days old | Standalone (warn: "Stale audit report found — run `/codebase-audit` for fresh data") |
| Both workflow-audit and codebase-audit found | Workflow-audit-aware takes priority (more specific) |
| No report found | Standalone |

Parse the report filename date: `YYYY-MM-DD-codebase-audit.md` or `YYYY-MM-DD-tech-reportcard.md`.
Parse `audit_date` from `handoff.yaml` for workflow-audit mode.

If multiple reports exist, use the most recent one.

**Mode summary:**

| Mode | Source | Ratings Pre-computed? | Convention Scan? |
|------|--------|-----------------------|------------------|
| Audit-aware | `.agents/research/*-codebase-audit.md` | No — extract and rate | No — uses audit context |
| Workflow-audit-aware | `.workflow-audit/handoff.yaml` | Yes — use as-is | Yes — if no CLAUDE.md |
| Standalone | User-provided task description | No — rate from scratch | Yes — if no CLAUDE.md |

**Output:**

```
## Mode: [Audit-Aware / Workflow-Audit-Aware / Standalone]
Report: [filename or "none"]
Report age: [N days or "n/a"]
Staleness warnings: [count or "none"]
```

---

## Step 2A: Audit Ingest (audit-aware mode only)

> Skip this step in standalone mode — go to Step 2B.

Read the audit report and extract structured data.

```
Read file_path=".agents/research/[report-filename]"
```

### Parse grades

Look for the `GRADES_YAML` HTML comment block first:

```
<!-- GRADES_YAML
categories:
  - name: Architecture
    score: 91
    grade: A-
    ...
-->
```

If no YAML block, fall back to parsing the grade summary line:

```
**Overall: B+ (84)** (Arch A- [91] | Security C+ [77] | ...)
```

### Extract Top 10 Issues

Scan the report for the prioritized findings list. Each finding should have:
- Category
- Severity (CRITICAL / HIGH / MEDIUM / LOW)
- Description
- File:line reference
- LOE estimate

### Detect special conditions

| Condition | What to extract |
|-----------|----------------|
| **Incomplete (I) grade** | Category name + trigger description + file:line |
| **DO NOT SHIP** recommendation | All blocker items listed under the recommendation |
| **CRITICAL findings** | Full finding details |

### Produce Report Digest

```markdown
## Report Digest

| Source | Date | Overall Grade |
|--------|------|---------------|
| [codebase-audit / tech-reportcard] | [date] | [grade] |

### Incomplete Triggers (if any)
| Category | Trigger | File |
|----------|---------|------|
| [category] | [description] | [file:line] |

### Ship Recommendation
[SHIP / CONDITIONAL SHIP / DO NOT SHIP] — [reason]

### Top Issues
| # | Category | Severity | Issue | File | LOE |
|---|----------|----------|-------|------|-----|
| 1 | [cat] | CRITICAL | [desc] | [file:line] | [Xh] |
| 2 | [cat] | HIGH | [desc] | [file:line] | [Xh] |
| ... | | | | | |
```

---

## Step 2B: Codebase Analysis (standalone mode only)

> Skip this step in audit-aware mode — audit already did this work.

### Freshness

Base all analysis on current source code only. Do not read or reference
files in `.agents/`, `scratch/`, or prior audit reports (those are ingested
in Step 2A only). Every finding must come from scanning the actual codebase
as it exists now.

Scan the codebase for context relevant to the planned work:

```
# Find files related to the feature area
Glob pattern="**/*FeatureName*.swift"
Grep pattern="FeatureKeyword" glob="**/*.swift" output_mode="files_with_matches"

# Find existing patterns to follow
Grep pattern="class.*ViewModel|struct.*View.*body" glob="**/*.swift" output_mode="files_with_matches"

# Find dependencies that will be affected
Grep pattern="import.*ModuleName|ModuleName\\." glob="**/*.swift" output_mode="files_with_matches"

# Find test files for affected areas
Glob pattern="Tests/**/*FeatureName*Tests.swift"
```

Produce:

### Related Code Table

| File/Module | Relevance | Notes |
|-------------|-----------|-------|
| [path] | High/Med/Low | [How it relates] |

### Patterns to Follow Table

| Pattern | Example Location | Apply To |
|---------|------------------|----------|
| [Pattern name] | [File path] | [Where to use] |

### Dependencies Table

| This Feature Depends On | Type |
|-------------------------|------|
| [Module/file] | Required/Optional |

| This Feature Will Affect | Impact |
|--------------------------|--------|
| [Module/file] | High/Med/Low |

---

## Step 2C: Workflow Audit Ingest (workflow-audit-aware mode only)

> Skip this step in audit-aware or standalone mode.

Read the workflow audit handoff brief and ingest pre-rated findings.

```
Read file_path=".workflow-audit/handoff.yaml"
```

### Parse Handoff Brief

Extract:
- `project`, `audit_date`, `source_files_scanned`
- `summary` counts (critical/high/medium/low)
- All `issues[]` with their pre-computed ratings

**Ratings are pre-computed** — do NOT re-rate issues from the handoff brief. The audit skill already applied the rating system. Use the ratings as-is for planning.

### Staleness Check

Compare `file_timestamps` from the handoff against current file modification dates:

```bash
# For each file in file_timestamps, check if it changed
stat -f "%Sm" -t "%Y-%m-%dT%H:%M:%SZ" "<file path>"
```

**If files changed since audit:**
- List changed files and affected issue IDs
- Warn but do NOT block: "These issues may need spot-checking during implementation"
- Flag affected issues in the plan output

**If `audit_date` >14 days old:**
- Warn: "Workflow audit is stale — consider re-running `/workflow-audit` for fresh data"

### Group Hint Processing

Read `group_hint` values from issues. Use them as suggestions for task grouping in Step 7:
- Issues sharing a `group_hint` are candidates for a single task
- Respect T-shirt sizing rules — don't create L-sized tasks just to honor hints
- Hints are suggestions, not mandates

### Produce Handoff Digest

```markdown
## Handoff Digest

| Field | Value |
|-------|-------|
| Project | [name] |
| Audit Date | [date] |
| Files Scanned | [count] |
| Total Issues | [count] |

### Issue Summary (from audit)

| # | Finding | Urgency | Risk: Fix | Risk: No Fix | ROI | Blast Radius | Fix Effort | Group Hint | Stale? |
|---|---------|---------|-----------|--------------|-----|--------------|------------|------------|--------|
| 1 | [finding] | [urgency] | [risk_fix] | [risk_no_fix] | [roi] | [blast] | [effort] | [hint] | [Yes/No] |

### Staleness Warnings (if any)
| File | Audit Date | Current Date | Affected Issues |
|------|------------|--------------|-----------------|
| [path] | [date] | [date] | #1, #4 |
```

---

## Step 2D: Light Convention Scanning (workflow-audit-aware and standalone modes)

> Skip in audit-aware mode (codebase audit provides enough context).
> Skip if project has a comprehensive CLAUDE.md (>100 lines with code patterns).

Detect project conventions automatically when no CLAUDE.md is available:

```bash
# Platform targets
grep -r "#if os(" Sources/ | head -5

# Data framework
grep -rl "@Model" Sources/ | head -3          # SwiftData
grep -rl "NSManagedObject" Sources/ | head -3  # CoreData
grep -rl "GRDB" Sources/ | head -3             # GRDB

# Feedback patterns
grep -rl "HapticManager\|UINotificationFeedbackGenerator" Sources/ | head -3
grep -rl "ToastManager\|toast\|snackbar" Sources/ | head -3

# Confirmation patterns
grep -rl "\.alert.*destructive\|confirmationDialog" Sources/ | head -3

# Navigation pattern
grep -rl "NavigationSplitView\|TabView\|NavigationStack" Sources/ | head -3
```

### Output: Detected Conventions Table

Display before planning begins:

```markdown
## Detected Conventions

| Convention | Detected | Evidence |
|------------|----------|----------|
| Platforms | iOS + macOS | `#if os(iOS)` in 45 files |
| Data Framework | SwiftData | `@Model` in 12 files |
| Haptic Feedback | Yes | `HapticManager` in 8 files |
| Toast/Notifications | Yes | `ToastManager` in 15 files |
| Confirmation Dialogs | Yes | `.alert` with destructive in 22 files |
| Navigation | NavigationSplitView + TabView | Split view in 3 files, TabView in 1 |
```

This informs fix planning (e.g., "this project uses HapticManager, so feedback fixes should use it too").

---

## Step 3: Interactive Input

**IMPORTANT**: Use `AskUserQuestion` to gather requirements.

### Common questions (both modes)

```
AskUserQuestion with questions:
[
  {
    "question": "What type of work are you planning?",
    "header": "Work Type",
    "options": [
      {"label": "New feature", "description": "Adding new functionality to the app"},
      {"label": "Bug fix / improvement", "description": "Fixing issues or enhancing existing features"},
      {"label": "Refactoring", "description": "Restructuring code without changing behavior"},
      {"label": "Audit remediation", "description": "Fixing findings from a codebase audit or report card"}
    ],
    "multiSelect": false
  },
  {
    "question": "What is your risk tolerance?",
    "header": "Risk",
    "options": [
      {"label": "Conservative", "description": "Minimize risk, smaller incremental changes"},
      {"label": "Balanced", "description": "Reasonable risk for reasonable gains"},
      {"label": "Aggressive", "description": "Accept higher risk for faster delivery"}
    ],
    "multiSelect": false
  },
  {
    "question": "What is your timeline?",
    "header": "Timeline",
    "options": [
      {"label": "Urgent (days)", "description": "Must ship this week"},
      {"label": "Normal (1-2 weeks)", "description": "Standard development cycle"},
      {"label": "Flexible (weeks+)", "description": "No immediate deadline"}
    ],
    "multiSelect": false
  }
]
```

### Scope question (audit-aware and workflow-audit-aware modes)

After the common questions, also ask:

```
AskUserQuestion with questions:
[
  {
    "question": "What scope should the plan cover?",
    "header": "Scope",
    "options": [
      {"label": "Blockers only", "description": "Incomplete triggers + DO NOT SHIP items only"},
      {"label": "Top 10 issues", "description": "The 10 highest-priority findings from the report"},
      {"label": "All findings", "description": "Comprehensive plan covering every finding"},
      {"label": "Pick specific items", "description": "I'll choose which findings to include"}
    ],
    "multiSelect": false
  }
]
```

If "Pick specific items" is selected, present the numbered findings list and ask which to include.

In standalone mode, ask for the feature/task description if not already provided via command arguments.

---

## Step 4: Understanding Phase

### Standalone mode output

#### Feature Summary Table

| Aspect | Details |
|--------|---------|
| **What** | [Restate the feature/task in your own words] |
| **Why** | [User benefit or business value] |
| **Scope** | [What's included and excluded] |

#### User Stories Table

| # | As a... | I want... | So that... |
|---|---------|-----------|------------|
| 1 | [user type] | [capability] | [benefit] |
| 2 | [user type] | [capability] | [benefit] |

#### Acceptance Criteria Table

| # | Criterion | How to Verify |
|---|-----------|---------------|
| 1 | [What must be true] | [Test or check] |
| 2 | [What must be true] | [Test or check] |

### Audit-aware mode output

#### Issue Summary Table

| # | Category | Issue | Urgency | Risk | ROI | Blast | LOE | Blocker? |
|---|----------|-------|---------|------|-----|-------|-----|----------|
| 1 | [cat] | [short description] | H/M/L | H/M/L | H/M/L | H/M/L | [Xh] | Yes/No |
| 2 | [cat] | [short description] | H/M/L | H/M/L | H/M/L | H/M/L | [Xh] | Yes/No |

**Blocker?** = Yes if the finding is an Incomplete trigger or DO NOT SHIP item.

---

## Step 5: T-Shirt Sizing

Apply T-shirt sizes to every task before building the phased plan.

### Size Definitions

| Size | Files Touched | Typical Scope | Target |
|------|---------------|---------------|--------|
| **S** | 1-2 files | Single fix, one-liner, config change | Combine sequential S tasks into one work unit |
| **M** | 3-5 files | Feature area fix, cross-cutting concern | Ideal task size — most tasks should be M |
| **L** | 5+ files | Architectural change, multi-system refactor | Split into 2-3 M tasks |

### Sizing Rules

1. **Target M** — Most tasks should touch 3-5 files. This is the sweet spot for reviewable, testable work units.
2. **Combine S** — Two or three sequential S tasks in the same area become one M task.
3. **Split L** — Any task touching 5+ files must be split. Find natural boundaries (model vs view vs tests).
4. **Minimize overlap** — Tasks in the same phase should not modify the same files. If two tasks both touch `ItemListView.swift`, combine them or reorder to eliminate conflicts.
5. **Count tests separately** — If a task requires test changes, the test file counts toward the file total.

### Sizing Output

After sizing, annotate each task:

```
Task: "Add keyboard dismissal to item entry forms"
Size: M (4 files: AddItemView, EditItemView, AddItemViewModel, EditItemViewModel)
```

---

## Step 6: Impact Analysis Table

| Area | Files Affected | Risk Level | Notes |
|------|----------------|------------|-------|
| Models | [list] | High/Med/Low | [details] |
| ViewModels | [list] | High/Med/Low | [details] |
| Views | [list] | High/Med/Low | [details] |
| Services/Managers | [list] | High/Med/Low | [details] |
| Tests | [list] | High/Med/Low | [details] |

In audit-aware mode, populate this table from the report findings. Group findings by area and aggregate risk levels.

---

## Step 7: Implementation Plan Table

### Audit-aware mode

Include **Phase A: Blockers** as the first phase if there are Incomplete triggers or DO NOT SHIP items.

| Phase | # | Task | Size | Files | Urgency | Risk | ROI | Blast | LOE | Depends On |
|-------|---|------|------|-------|---------|------|-----|-------|-----|------------|
| **A: Blockers** | 1 | [Incomplete trigger / DO NOT SHIP fix] | M | [files] | Critical | H | H | [scope] | [Xh] | - |
| **A: Blockers** | 2 | [Next blocker fix] | M | [files] | Critical | H | H | [scope] | [Xh] | - |
| B: High Priority | 3 | [HIGH severity fix] | M | [files] | H | M | H | [scope] | [Xh] | Phase A |
| B: High Priority | 4 | [HIGH severity fix] | M | [files] | H | M | H | [scope] | [Xh] | Task 3 |
| C: Medium Priority | 5 | [MEDIUM finding] | M | [files] | M | M | M | [scope] | [Xh] | Phase B |
| D: Low / Polish | 6 | [LOW finding / improvement] | S | [files] | L | L | M | [scope] | [Xh] | - |

**Each task row MUST include:**
- **Size:** S/M/L (from Step 5)
- **Urgency:** How soon this needs to happen (Critical/H/M/L)
- **Risk:** What could go wrong (H/M/L)
- **ROI:** Value delivered per effort (H/M/L)
- **Blast:** How much of the app is affected (H/M/L or specific scope like "ItemList feature")
- **LOE:** Estimated hours
- **Depends On:** Task # or Phase that must complete first

### Standalone mode

Same table structure, but no Phase A: Blockers. Use standard phasing:

| Phase | # | Task | Size | Files | Urgency | Risk | ROI | Blast | LOE | Depends On |
|-------|---|------|------|-------|---------|------|-----|-------|-----|------------|
| A: Foundation | 1 | [Foundation task] | M | [files] | H | L | H | [scope] | [Xh] | - |
| B: Core Logic | 2 | [Core implementation] | M | [files] | H | M | H | [scope] | [Xh] | Phase A |
| C: UI Integration | 3 | [UI work] | M | [files] | M | M | H | [scope] | [Xh] | Phase B |
| D: Polish | 4 | [Polish / edge cases] | S | [files] | L | L | M | [scope] | [Xh] | Phase C |

### Task traceability

In audit-aware and workflow-audit-aware modes, every task MUST trace back to its source finding(s):

```
Task 3: "Fix actor isolation in BackgroundSyncManager"
Source: Audit finding #4 (Concurrency, HIGH)
Size: M (3 files: BackgroundSyncManager.swift, SyncService.swift, SyncServiceTests.swift)
```

```
Task 2: "Add confirmation dialogs to 5 destructive actions"
Source: Workflow-audit issues #3, #5, #8, #11, #14 (missing_confirmations)
Size: M (5 files)
Stale: No
```

Group related findings into single M-sized tasks where they share the same files or logical area. Do NOT create one task per finding — combine related findings. In workflow-audit mode, use `group_hint` as a starting point for grouping.

---

## Step 8: Risk Assessment Table

| Risk | Likelihood | Impact | Mitigation | Phase |
|------|------------|--------|------------|-------|
| [Risk description] | High/Med/Low | High/Med/Low | [How to mitigate] | [Which phase] |

In audit-aware mode, seed this table from cross-domain correlations in the report (e.g., concurrency issues that affect data persistence).

---

## Step 9: Test Plan Table

| Test Type | What to Test | Priority | Phase |
|-----------|--------------|----------|-------|
| Unit | [Functionality] | High/Med/Low | [Phase letter] |
| Integration | [Functionality] | High/Med/Low | [Phase letter] |
| UI | [Functionality] | High/Med/Low | [Phase letter] |

The **Phase** column ties each test to its implementation phase — tests for Phase A tasks are written/run during Phase A.

---

## Step 10: Rollback Strategy Table

| Phase | Scenario | Rollback Action |
|-------|----------|-----------------|
| [Phase letter] | [What could go wrong] | [How to undo] |

Per-phase rollback ensures each phase can be independently reverted if needed.

---

## Step 11: Write Output

**Display the full implementation plan inline** (mode, digest/analysis, feature spec, sizing, impact, phased plan, risks, test plan, rollback), then write to `.agents/research/` for future reference:

```
Write file_path=".agents/research/YYYY-MM-DD-implementation-plan.md" content="[full plan output]"
```

Use today's date. Include all tables, the mode header, and the report digest (if audit-aware).

---

## Step 12: Deliverables + Proceed

### Deliverables Checklist

| Deliverable | Status |
|-------------|--------|
| Mode detection | Done |
| Report digest (audit) / Codebase analysis (standalone) | Done |
| Feature spec / Issue summary | Done |
| T-shirt sizing | Done |
| Impact analysis | Done |
| Phased implementation plan | Done |
| Risk assessment | Done |
| Test plan | Done |
| Rollback strategy | Done |
| Written to file | Done |

### Ready to Proceed?

```
AskUserQuestion with questions:
[
  {
    "question": "How would you like to proceed?",
    "header": "Action",
    "options": [
      {"label": "Start Phase A", "description": "Begin implementation with the first phase"},
      {"label": "Refine the plan", "description": "Discuss or adjust before starting"},
      {"label": "Save for later", "description": "Plan is saved — pick it up anytime"}
    ],
    "multiSelect": false
  }
]
```

---

## Worked Example: Standalone Mode (Abbreviated)

```
User: "/plan add search feature"

Step 1: Mode = Standalone (no audit reports found)
Step 2B: Codebase analysis — found ItemListView, ItemListViewModel, Item model
Step 3: Work type = New feature, Risk = Balanced, Timeline = Normal
Step 4: Feature spec — search bar filtering items by title, category, notes
Step 5: T-shirt sizing — M (4 files: ItemListView, ItemListViewModel, Item+Search, SearchTests)
Step 6: Impact — Views (1 file), ViewModels (1 file), Models (1 extension), Tests (1 file)
Step 7: Plan
  Phase A: Add searchText @State + .searchable to ItemListView (M, 3 files)
  Phase B: Unit tests for filter matching (S, 1 file)
Step 8: Risk — Low (additive change)
Step 9: Tests — Unit: filter matching, empty query, case sensitivity (Phase A)
Step 10: Rollback — Revert .searchable modifier, remove filter computed property
Step 11: Written to .agents/research/2026-02-25-implementation-plan.md
Step 12: Ready to proceed?
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Can't find audit report | Check `.agents/research/` for `*-codebase-audit.md` or `*-tech-reportcard.md` |
| Report is stale (>14 days) | Run `/codebase-audit` or `/tech-talk-reportcard` first, then re-plan |
| Too many findings to plan | Use "Blockers only" or "Top 10 issues" scope to focus |
| Tasks too large (L-sized) | Split along natural boundaries: model/view/test, or by sub-feature |
| Dependencies between phases unclear | Draw the dependency chain from data model → service → viewmodel → view |
| User unclear on scope | Use standalone mode with AskUserQuestion to clarify iteratively |

---

## Worked Example: Audit-Aware Mode (Abbreviated)

```
User: "/plan --audit" (recent codebase-audit report exists)

Step 1: Mode = Audit-Aware, Report: 2026-02-20-codebase-audit.md (5 days old)
Step 2A: Report Digest
  Overall: C+ (77), Incomplete in Security (hardcoded API key)
  Ship: DO NOT SHIP
  Top 10: 2 CRITICAL, 3 HIGH, 5 MEDIUM
Step 3: Work type = Audit remediation, Risk = Conservative, Scope = Top 10 issues
Step 4: Issue Summary — 10 rows with Urgency/Risk/ROI/Blast/LOE, 1 blocker
Step 5: T-shirt sizing — grouped into 6 M-sized tasks + 1 S task
Step 6: Impact — Models (2 files), Services (3 files), Views (4 files), Tests (3 files)
Step 7: Plan
  Phase A: Blockers — Remove hardcoded API key, move to Keychain (M, 3 files)
  Phase B: High — Fix actor isolation in SyncManager, add missing @MainActor (M, 4 files)
  Phase C: Medium — Add accessibility labels, fix Dynamic Type (M, 5 files → split into 2 tasks)
Step 8: Risk — Keychain migration could break existing users (Phase A, mitigate with fallback read)
Step 9: Tests — Unit: Keychain wrapper (A), actor isolation (B), accessibility (C)
Step 10: Rollback — Phase A: revert Keychain, restore inline key. Phase B: revert actor changes.
Step 11: Written to .agents/research/2026-02-25-implementation-plan.md
Step 12: Ready to proceed?
```

