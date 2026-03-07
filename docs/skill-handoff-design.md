# Skill Handoff Design: Audit → Rating → Planning

**Status:** Implemented
**Date:** 2026-03-06 (design) · 2026-03-07 (implementation)
**Context:** Derived from a complete audit → fix cycle on the Stuffolio project (24 issues found, all fixed in one session)

---

## Three Components

The workflow audit and fix process decomposes into three separable components:

### 1. Rating System (shared format)

A standalone format definition consumed by both the audit and planning skills.

**Owns:**
- Column definitions (Urgency, Risk: Fix, Risk: No Fix, ROI, Blast Radius, Fix Effort)
- Indicator scale (🔴 🟡 🟢 ⚪ 🟠 with meanings)
- Urgency tiers (Critical / High / Medium / Low)
- Sorting rules (urgency descending, then ROI)
- Table rendering format (see hard rule below)

**Does not own:**
- When to display ratings (that's up to the consuming skill/CLAUDE.md)
- Project-specific severity thresholds

**Form factor:** Micro-skill or shared reference file importable by other skills.

**Hard formatting rule — Table, not list:**

> ALL findings MUST be presented in a single markdown table. Each finding is ONE ROW. Ratings are COLUMNS read left-to-right. Never expand findings into individual sections with bullet-pointed ratings.

**Correct — scannable table (one row per finding):**

```markdown
| # | Finding | Urgency | Risk: Fix | Risk: No Fix | ROI | Blast Radius | Fix Effort |
|---|---------|---------|-----------|--------------|-----|--------------|------------|
| 1 | Missing confirmation dialog | 🟡 High | ⚪ Low | 🟡 High | 🟠 Excellent | ⚪ 1 file | Trivial |
| 2 | Silent delete operation | 🟢 Medium | ⚪ Low | 🟢 Medium | 🟠 Excellent | ⚪ 1 file | Trivial |
```

**Wrong — vertical list (one block per finding):**

```markdown
### Finding 1: Missing confirmation dialog
- **Urgency:** 🟡 High
- **Risk: Fix:** ⚪ Low
- **Risk: No Fix:** 🟡 High
- **ROI:** 🟠 Excellent
- **Blast Radius:** ⚪ 1 file
- **Fix Effort:** Trivial

### Finding 2: Silent delete operation
- **Urgency:** 🟢 Medium
- ...
```

The table format lets you compare all findings at a glance. The vertical list forces scrolling through N separate blocks. Same data, completely different usability. This distinction matters — when asked for a "table", produce the horizontal row format, not the vertical block format. They are not the same thing.

### 2. Audit Skill (finds problems)

Scans the actual codebase, discovers entry points, traces flows, detects issues, evaluates UX, verifies data wiring.

**Owns:**
- 5-layer scan methodology (Discovery → Tracing → Detection → Evaluation → Data Wiring)
- Grep/glob patterns for SwiftUI entry points
- Issue categorization (Dead End, Mock Data, Missing Feedback, Orphaned Code, etc.)
- Structured output files (`.workflow-audit/*.yaml`)
- Handoff brief generation (distills findings for planning skill)

**Does not own:**
- Fix implementation patterns
- Task grouping / phasing
- Prompting workflow (Proceed / Explain / Defer / Remove)
- Project-specific code conventions

**Hard rule — Freshness:**
> The audit MUST scan actual source code as it exists now. It MUST NOT read or reference:
> - Prior audit reports (`.workflow-audit/` from previous runs)
> - Auto-memory files
> - Scratch files or agent notes
> - Session transcripts or cached findings
>
> Every finding must be independently verifiable from the current codebase. This is a top-level rule, not a suggestion.

**Rationale:** Stale findings cause false positives (reporting fixed issues) and false negatives (missing new issues). The audit's value comes from being a reliable snapshot of current state.

### 3. Planning Skill (organizes fixes)

Consumes audit findings and project context, produces a phased implementation plan with prompting gates.

**Owns:**
- Grouping issues into fix phases (Trivial / Small / Medium / Large)
- Batching related fixes (e.g., "5 missing confirmation dialogs" → 1 task)
- Per-task prompting workflow before implementation
- Reading project conventions (from CLAUDE.md or codebase scanning)

**Does not own:**
- Issue discovery (that's the audit's job)
- Rating definitions (imports from shared rating system)
- Actual code implementation (that's the execution phase)

**Reads:**
- Audit handoff brief (structured findings with ratings)
- CLAUDE.md (project conventions, patterns, preferences)
- Codebase (to discover conventions if no CLAUDE.md exists)

---

## Prompting System

The planning skill gates each task with a decision prompt before implementation begins.

**Options:**
1. **Proceed** — implement now (always the first/recommended option)
2. **Simple explanation** — explain in plain terms, then re-prompt
3. **Defer** — save for later (add to backlog with ratings + effort estimate)
4. **Remove from plan** — delete this task entirely

**When to prompt:**
- Before starting each task or phase
- NOT during the audit (audit just reports)
- NOT per-issue (tasks may batch multiple issues)

**Batch mode:** User can approve an entire phase at once ("Execute Phase 1") to skip per-task prompting for trivial fixes.

---

## Handoff: Audit → Planning

### The Problem

The audit outputs detailed YAML files and a summary markdown. The planning skill needs a focused brief, not raw audit artifacts. Too much detail and the planning skill drowns in context. Too little and it re-discovers things.

### Handoff Brief Format

The audit generates a handoff brief (`.workflow-audit/handoff.yaml`) containing:

```yaml
# Handoff Brief — generated by workflow-audit
# Consumed by planning skill

project: Stuffolio
audit_date: 2026-03-06
source_files_scanned: 795

summary:
  total_issues: 24
  critical: 0
  high: 7
  medium: 11
  low: 6

file_timestamps:
  Sources/Features/Dashboard/Views/DashboardView+SheetContent.swift: "2026-03-06T14:22:00Z"
  Sources/Features/Settings/Views/ToolsView.swift: "2026-03-05T09:15:00Z"
  # ... one entry per file referenced in issues[]

issues:
  - id: 1
    finding: ".appleCareTracking — full handler but zero UI triggers"
    category: orphaned_feature
    urgency: high
    risk_fix: low
    risk_no_fix: high
    roi: excellent
    blast_radius: 1 file
    fix_effort: small
    files:
      - Sources/Features/Dashboard/Views/DashboardView+SheetContent.swift
    suggested_fix: "Add trigger to ToolsView and/or QuickFind"
    group_hint: "orphaned_features"  # optional — planning skill uses for grouping suggestions

  - id: 2
    # ... more issues
```

### What the Brief Includes
- Issue ID, finding description, category
- All rating columns (pre-computed by audit)
- Affected file paths
- Brief suggested fix direction (what, not how)

### What the Brief Excludes
- Full flow traces (Layer 2 detail)
- Semantic evaluation prose (Layer 4 narrative)
- Raw grep output
- Implementation code

---

## Staleness Detection

The planning skill warns (but does not block) when audit findings may be stale.

**How it works:**
1. Read `audit_date` from `handoff.yaml`
2. Read `file_timestamps` map from `handoff.yaml`
3. For each file in the timestamps map, compare the recorded mod date to the file's current mod date
4. If any file has changed since the audit: warn with a list of changed files
5. If `audit_date` is >14 days ago: warn about overall staleness

**Output:**
```
⚠️ Staleness warning: 3 files changed since audit (2026-03-06):
  - Sources/Features/Dashboard/Views/DashboardView+SheetContent.swift (modified 2026-03-07)
  - Sources/Views/Components/SheetStyles.swift (modified 2026-03-07)
  Issues #1, #4, #7 may need re-verification.
```

**Behavior:** Warning only. The planning skill proceeds with flagged issues but notes they should be spot-checked during implementation.

---

## End-of-Audit Suggestion

After presenting audit results, the workflow-audit skill prints:

```
💡 To generate a phased fix plan from these findings, run: /plan --workflow-audit
```

This is a suggestion, not automatic invocation. The user decides when/if to plan.

---

## Light Convention Scanning

When the planning skill operates on a project without CLAUDE.md (or with a minimal one), it runs a light scan to detect conventions before planning:

| Convention | Detection Method |
|------------|-----------------|
| Platform targets | `grep -r "#if os(" Sources/` |
| Data framework | Look for `@Model` (SwiftData), `NSManagedObject` (CoreData), `GRDB` |
| Haptic feedback | `grep -r "HapticManager\|UINotificationFeedbackGenerator" Sources/` |
| Toast/notification | `grep -r "ToastManager\|toast\|snackbar" Sources/` |
| Confirmation dialogs | `grep -r "\.alert.*destructive\|confirmationDialog" Sources/` |
| Navigation pattern | `grep -r "NavigationSplitView\|TabView\|NavigationStack" Sources/` |

**Output:** "Detected Conventions" table displayed before planning begins. Not stored — computed fresh each run.

**Scope:** Light scan only. This is NOT a codebase audit. It detects enough context to produce sensible fix plans without requiring a CLAUDE.md.

---

## CLAUDE.md Dependency

### Current State
Both skills are highly dependent on CLAUDE.md for project-specific conventions.

### Mitigation for Projects Without CLAUDE.md
The planning skill could scan for conventions automatically:
- Grep for haptic patterns → "this project uses HapticManager"
- Grep for toast/notification patterns → "this project uses ToastManager"
- Check for confirmation dialog conventions → "this project uses .alert with cancel/destructive buttons"
- Detect platform targets → "this project builds for iOS + macOS"

This is essentially auto-generating a partial CLAUDE.md. It reduces the dependency but won't capture preferences, naming conventions, or architectural decisions.

**Recommendation:** The planning skill should work without CLAUDE.md (using convention scanning) but produce better results with one. Document this as a "good / better / best" spectrum:
- **Good:** No CLAUDE.md → skill scans for conventions
- **Better:** Minimal CLAUDE.md → platforms, frameworks, key patterns
- **Best:** Full CLAUDE.md → complete project context

---

## Resolved Decisions

| Question | Decision | Rationale |
|----------|----------|-----------|
| Handoff granularity | Individual issues + optional `group_hint` field | Planning skill decides grouping, but audit can suggest via hints |
| Stale audit detection | Warn on stale files (compare file mod dates to `audit_date`) | Don't block — just warn so the user can decide |
| Audit → Planning automation | Suggest at end: print `/plan --workflow-audit` command | Not automatic, but discoverable |
| Convention scanning depth | Light scan: platforms, frameworks, haptic/toast patterns | Enough to work without CLAUDE.md, not a full audit |

---

## Reference: Session That Informed This Design

**Project:** Stuffolio v1.0 (25)
**Audit findings:** 24 issues across 5 layers
**Fix phases (manually created):**
- Phase 1 (Trivial, ~10 min each): 5 confirmation dialogs, 1 context menu fix, 1 color fix, 4 feedback additions
- Phase 2 (Small, ~30 min each): 2 feature wiring tasks
- Phase 3 (Dead code): 6 file deletions, 1 dead enum case

**What worked:** Audit accuracy was high (all 24 findings verified). Rating system enabled fast prioritization. Phase grouping by effort was intuitive.

**What was manual:** Phase grouping, pattern discovery for fixes (reading existing confirmation dialogs to match conventions), per-task prompting, build verification.

---

## Implementation Notes (2026-03-07)

| File | Changes |
|------|---------|
| `skills/shared/rating-system.md` | **Created** — extracted rating format, column definitions, indicator scale, urgency tiers, sorting rules, table formatting hard rule |
| `skills/workflow-audit/SKILL.md` | Added table formatting hard rule reference, handoff brief generation spec (format + file_timestamps + group_hint), end-of-audit suggestion |
| `skills/plan/SKILL.md` | Added workflow-audit-aware mode detection, Step 2C (handoff ingest with staleness checking), Step 2D (light convention scanning), updated traceability to support group_hint |
| `docs/skill-handoff-design.md` | Replaced Open Questions with Resolved Decisions, added staleness detection / convention scanning / end-of-audit suggestion specs, marked Implemented |
