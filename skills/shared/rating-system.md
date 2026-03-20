# Rating System — Shared Reference

> **Imported by:** `workflow-audit/SKILL.md`, `plan/SKILL.md`
> **Source of truth** for rating format, column definitions, and indicator scales.

---

## Table Format (Hard Rule)

> ALL findings MUST be presented in a single markdown table. Each finding is ONE ROW. Ratings are COLUMNS read left-to-right. Never expand findings into individual sections with bullet-pointed ratings.

**Also wrong — separate headed sections per category:**

```markdown
## Data Wiring Issues
- 0 mock data in production features
- Cross-feature flows: PriceWatch → RepairKeepReplace — connected

## Orphaned Views
- InformationHelpView — never instantiated
- ToolsHelpView — never instantiated
```

This is the same problem as the vertical list: it breaks findings into scrollable blocks instead of keeping them in one scannable table. Data wiring findings, orphaned views, missing confirmations — ALL go in the same table. Use the Finding column for context (e.g., "Data wiring: diyNotes defined but never shown in UI").

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
- ...
```

The table format lets you compare all findings at a glance. The vertical list forces scrolling through N separate blocks. These are NOT the same thing.

---

## Display Requirements

### Terminal Width Detection

Before rendering any rating table, check terminal width:

```bash
tput cols
```

- **160+ columns:** Render the **full 8-column table** inline.
- **Under 160 columns:** Render the **compact 4-column table** inline. Write the **full 8-column table** to the report file only. Display this notice after the compact table:

> **Compact view** — your terminal is [N] columns wide (160+ needed for full table). The complete Issue Rating Table with all 8 columns has been written to the report file. Open that file or widen your terminal to 160+ columns to view it as a single table.

### Compact Table Format

When terminal is under 160 columns, use this inline:

```markdown
| # | Finding | Urgency | Fix Effort |
|---|---------|---------|------------|
| 1 | Description | 🔴 Critical | Trivial |
| 2 | Description | 🟡 High | Small |
```

The compact table keeps the two most actionable columns (Urgency + Fix Effort). Full ratings are in the report file.

### Report File

The report file (`.agents/research/YYYY-MM-DD-*.md`) **always** contains the full 8-column table regardless of terminal width.

---

## Column Definitions

| Column | Meaning |
|--------|---------|
| **Urgency** | How time-sensitive — must it be fixed before release? |
| **Risk: Fix** | What could break when making the change |
| **Risk: No Fix** | Cost of leaving it — crash, data loss, user-visible bug |
| **ROI** | Return on effort (inverted — 🟠 = excellent, 🔴 = poor) |
| **Blast Radius** | Number of files the fix touches (e.g., "⚪ 1 file", "🟢 3 files", "🟡 12 files"). Count by grepping for callers/references before rating. |
| **Fix Effort** | Trivial / Small / Medium / Large |

---

## Indicator Scale

| Indicator | General meaning | ROI meaning |
|-----------|----------------|-------------|
| 🔴 | Critical / high concern | Poor return — reconsider |
| 🟡 | High / notable | Marginal return |
| 🟢 | Medium / moderate | Good return |
| ⚪ | Low / negligible | — |
| 🟠 | Pass / positive (test results, status) | Excellent return |

---

## Urgency Tiers

| Tier | Meaning | Examples |
|------|---------|----------|
| 🔴 CRITICAL | Pre-launch blocker OR data loss / crash risk | Dead end, wrong destination, mock data in production |
| 🟡 HIGH | User-visible or stability risk; fix before release | Broken promise, missing activation, unwired data, platform gap |
| 🟢 MEDIUM | Real issue; acceptable to schedule | Two-step flow, missing feedback |
| ⚪ LOW | Nice-to-have; minimal impact | Inconsistency, orphaned code |

---

## Sorting Rules

1. Sort by **Urgency** descending (🔴 → 🟡 → 🟢 → ⚪)
2. Within same urgency, sort by **ROI** descending (🟠 → 🟢 → 🟡 → 🔴)

---

## When to Apply

- Any fix, plan step, or architectural decision
- Any audit finding (including output from Axiom audit skills)
- Any time a prompt explicitly asks for a **"Rating"**

## Opt-Out

- **Persistent off:** If the project's CLAUDE.md has `## Issue Rating Criteria [OFF]`, skip all rating tables
- **Per-prompt:** If the user's message includes `--no-rating`, omit the rating table for that response only
