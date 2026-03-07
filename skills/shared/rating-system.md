# Rating System — Shared Reference

> **Imported by:** `workflow-audit/SKILL.md`, `plan/SKILL.md`
> **Source of truth** for rating format, column definitions, and indicator scales.

---

## Table Format (Hard Rule)

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
- ...
```

The table format lets you compare all findings at a glance. The vertical list forces scrolling through N separate blocks. These are NOT the same thing.

---

## Column Definitions

| Column | Meaning |
|--------|---------|
| **Urgency** | How time-sensitive — must it be fixed before release? |
| **Risk: Fix** | What could break when making the change |
| **Risk: No Fix** | Cost of leaving it — crash, data loss, user-visible bug |
| **ROI** | Return on effort (inverted — 🟠 = excellent, 🔴 = poor) |
| **Blast Radius** | Files, views, tests, subsystems touched |
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
