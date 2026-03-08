---
name: workflow-audit
description: 'Systematic UI workflow auditing for SwiftUI applications. Discovers entry points, traces user flows, detects dead ends and broken promises, audits data wiring, evaluates from user perspective. Triggers: "workflow audit", "audit flows", "find dead ends", "check navigation".'
version: 2.2.0
author: Terry Nyberg
license: MIT
allowed-tools: [Read, Grep, Glob, Bash, Edit, Write, AskUserQuestion]
metadata:
  tier: execution
  category: analysis
---

# Workflow Audit Skill

> **Quick Ref:** 5-layer UI workflow audit: discover entry points → trace flows → detect issues → evaluate UX → verify data wiring. Output: `.workflow-audit/` in project root.

<workflow-audit>

You are performing a systematic workflow audit on this SwiftUI application.

**Required output:** Every finding MUST include Urgency, Risk, ROI, and Blast Radius ratings using the Issue Rating Table format. Do not omit these ratings.

## Quick Commands

| Command | Description |
|---------|-------------|
| `/workflow-audit` | Full 5-layer audit |
| `/workflow-audit layer1` | Discovery only — find all entry points |
| `/workflow-audit layer2` | Trace — trace critical paths |
| `/workflow-audit layer3` | Issues — detect problems across codebase |
| `/workflow-audit layer4` | Evaluate — assess user impact |
| `/workflow-audit layer5` | Data wiring — verify real data usage |
| `/workflow-audit trace "A → B → C"` | Trace a specific user flow path |
| `/workflow-audit diff` | Compare current findings against previous audit |
| `/workflow-audit fix` | Generate fixes for found issues |
| `/workflow-audit status` | Show audit progress and remaining issues |

## Overview

The Workflow Audit uses a 5-layer approach:

| Layer | Purpose | Output |
|-------|---------|--------|
| **Layer 1** | Pattern Discovery - Find all UI entry points | Entry point inventory |
| **Layer 2** | Flow Tracing - Trace critical paths in depth | Detailed flow traces |
| **Layer 3** | Issue Detection - Categorize issues across codebase | Issue catalog |
| **Layer 4** | Semantic Evaluation - Evaluate from user perspective | UX impact analysis |
| **Layer 5** | Data Wiring - Verify features use real data | Data integrity report |

## Reference Documentation

Read these files for methodology and patterns (paths relative to this skill's directory):

- `agents/README.md` - Overview and quick start
- `agents/layer1-patterns.md` - Discovery regex patterns
- `agents/layer2-methodology.md` - Flow tracing process
- `agents/layer3-issue-detection.md` - Issue categories
- `agents/layer4-semantic-evaluation.md` - User impact analysis
- `agents/layer5-data-wiring.md` - Data integrity methodology

For templates and examples:
- `agents-skill/templates/` - YAML templates for each layer
- `agents-skill/examples/` - Good and bad patterns

> **Note:** These paths are relative to the skill directory (`~/.claude/skills/workflow-audit/`). When reading these files, resolve from the skill's installed location, not the current working directory.

## Issue Categories

| Category | Severity | Description |
|----------|----------|-------------|
| Dead End | 🔴 CRITICAL | Entry point leads nowhere |
| Wrong Destination | 🔴 CRITICAL | Entry point leads to wrong place |
| Mock Data | 🔴 CRITICAL | Feature shows fabricated data when real data exists |
| Incomplete Navigation | 🟡 HIGH | User must scroll/search after landing |
| Missing Auto-Activation | 🟡 HIGH | Expected mode/state not set |
| Unwired Data | 🟡 HIGH | Model data exists but feature ignores it |
| Platform Parity Gap | 🟡 HIGH | Feature works on one platform, broken on another |
| Promise-Scope Mismatch | 🟡 HIGH | Specific CTA opens generic/broad destination |
| Buried Primary Action | 🟡 HIGH | Primary button hidden below scroll fold |
| Dismiss Trap | 🟡 HIGH | Only visible action is Cancel/back, no forward path |
| Two-Step Flow | 🟢 MEDIUM | Intermediate selection required |
| Missing Feedback | 🟢 MEDIUM | No confirmation of success |
| Gesture-Only Action | 🟢 MEDIUM | Feature only accessible via swipe/long-press |
| Loading State Trap | 🟢 MEDIUM | Spinner with no cancel/timeout/escape |
| Context Dropping | 🟡 HIGH | Navigation path loses item context between platforms or via notifications |
| Notification Nav Fragility | 🟡 HIGH | Untyped NotificationCenter dict used for navigation context |
| Sheet Presentation Asymmetry | 🟡 HIGH | Different presentation mechanisms per platform for same feature |
| Stale Navigation Context | 🟢 MEDIUM | Cached context with no clearing/validation mechanism |
| Inconsistent Pattern | ⚪ LOW | Same feature accessed differently |
| Orphaned Code | ⚪ LOW | Feature exists but no entry point |

## Design Principles

### 1. Honor the Promise
> When a button/card says "Do X", tapping it should DO X.
> Not "go somewhere you might find X."

### 2. Context-Aware Shortcuts
> If user's context implies a specific item, skip pickers.

### 3. State Preservation
> When navigating to a feature, set up the expected state.

### 4. Consistent Access Patterns
> Same feature should be accessed the same way everywhere.

### 5. Data Integrity
> If the app tracks data relevant to a feature, the feature must use it.
> Never show mock/hardcoded data when real user data exists.
> Never ignore model relationships that would improve decisions.

### 6. Primary Action Visibility
> The primary action must be visible without scrolling after the user completes the key interaction.
> Pin Save/Continue/Done buttons outside ScrollView or in toolbar. Never bury them below tall content.

### 7. Escape Hatch
> Every view must have a visible way to go forward OR back. Cancel alone is not enough after user completes a step.

### 8. Gesture Discoverability
> Every action available via gesture (swipe, long-press) should also be accessible via a visible button or menu.

### Freshness

Base all findings on current source code only. Do not read or reference
files in `.agents/`, `scratch/`, or prior audit reports. Ignore cached
findings from auto-memory or previous sessions. Every finding must come
from scanning the actual codebase as it exists now.

## Execution Instructions

When invoked, perform the workflow audit:

### If no arguments or "full":
Run all 5 layers sequentially, outputting findings to `.workflow-audit/` in the project root

### If "layer1" or "discovery":
1. Scan for sheet triggers: `grep -r "activeSheet = \." Sources/`
2. Scan for navigation: `grep -r "selectedSection = \." Sources/`
3. Scan for promotion cards: `grep -r "PromotionCard\|CompactPromotionCard" Sources/`
4. Scan for context menus: `grep -r "\.contextMenu" Sources/`
5. Catalog all entry points in `layer1-inventory.yaml`
6. Flag suspicious patterns for Layer 2 investigation

### If "layer2" or "trace" (no path argument):
1. Read flagged entry points from Layer 1
2. For each flagged entry point, trace the complete user journey
3. Document in `layer2-traces/flow-XXX.yaml`
4. Identify gaps between expected and actual journeys

### If "trace" with path argument (e.g., `trace "Dashboard → Add Item → Photo → Save"`):
Targeted flow trace — trace a specific user journey described in natural language:
1. Parse the path description into discrete steps (split on `→`, `->`, or `,`)
2. For each step, identify the SwiftUI view, button, or action that triggers it:
   - Search for view names, sheet triggers, navigation actions matching each step
   - Use `grep -r` for button labels, sheet cases, navigation destinations
3. Trace the complete code path step by step:
   - File and line number for each transition
   - State changes (sheet presentations, navigation, @State mutations)
   - View transitions (what view appears at each step)
4. At each step, check for issues:
   - Is the expected next action visible without scrolling? (Buried Primary Action)
   - Does the user have a forward path? (Dismiss Trap)
   - Does the CTA match the destination scope? (Promise-Scope Mismatch)
   - Is feedback shown on completion? (Missing Feedback)
5. Document the trace and any issues found
6. Output: Issue Rating Table for any findings, plus the step-by-step trace

### If "layer3" or "issues":
1. Scan ALL entry points for common issues
2. Check for orphaned sheet cases (enum vs handler mismatch)
3. Check for orphaned views (defined but never instantiated)
4. Categorize by severity
5. Output to `layer3-results.yaml`

### If "layer4" or "evaluate":
1. For each issue, assess user impact
2. Rate: discoverability, efficiency, feedback, recovery
3. Map violations to design principles
4. Output to `layer4-semantic-evaluation.md`

### If "layer5" or "data-wiring" or "wiring":
1. Inventory model properties and relationships (what data the app tracks)
2. For each feature view, check what model data it actually reads
3. Detect mock/hardcoded data patterns (asyncAfter delays, static arrays, placeholder strings)
4. Cross-reference: model capabilities vs feature consumption
5. Flag unwired integrations (e.g., Price Watch data exists but decision engine ignores it)
6. Check platform parity (extension files, #if os() blocks, dismiss buttons)
7. Output to `layer5-data-wiring.yaml`

### If "diff":
Compare current codebase against the previous audit to show what changed:
1. Read existing `.workflow-audit/layer3-results.yaml` and `.workflow-audit/handoff.yaml`
2. For each previously-reported issue, check if the referenced file + line still has the problem:
   - Read the file at the reported line number
   - Check if the problematic pattern still exists
   - If fixed, mark as "RESOLVED"
   - If file was modified but pattern persists, mark as "STILL OPEN"
   - If file was deleted or moved, mark as "FILE CHANGED — verify manually"
3. Run a quick scan for NEW issues not in the previous report (new files, new ScrollView+button combos, new sheets without handlers)
4. Output a diff summary:
   ```
   Audit Diff: <previous date> → <current date>
   ✅ Resolved: <count> issues fixed since last audit
   🔴 Still Open: <count> issues remain
   🆕 New: <count> new issues detected
   📁 Changed: <count> files modified since audit (may need re-verification)
   ```
5. Show the full Issue Rating Table with a Status column prepended (✅/🔴/🆕)

### If "fix" or "fixes":
1. Read `layer3-results.yaml` and `layer5-data-wiring.yaml` for unfixed issues
2. Generate specific code fixes following the patterns in examples/
3. Prioritize by severity (critical first)

### If "status":
1. Read existing audit files
2. Report: issues found, fixed, remaining
3. Show priority queue for unfixed issues

## Output Format

> **CRITICAL FORMATTING RULE:** The Issue Rating Table below IS the output. Do NOT create separate sections for "Critical Issues", "Data Wiring Issues", "Recommendations", or any other vertical breakdown of findings. Every finding — navigation issues, data wiring issues, orphaned code, missing feedback, design violations — goes into ONE table as ONE row. Context goes in the Finding column. No exceptions.

After completing the audit, provide:

1. **One-line summary** — entry point count, issue count by severity (one sentence, not a section)
2. **Issue Rating Table** — every finding in a single table (see below)
3. **One-line next step** — suggest `/plan --workflow-audit` if fixes are needed

That's it. Three items. No other sections.

### Issue Rating Table

> **Reference:** See `skills/shared/rating-system.md` for full column definitions, indicator scale, and sorting rules.

**Hard formatting rule — Table, not list:** ALL findings MUST be in a single markdown table. Each finding is ONE ROW. Ratings are COLUMNS read left-to-right. Never expand findings into individual sections, vertical blocks, or bullet-pointed ratings. Do NOT create separate headed sections for categories of findings (e.g., "Data Wiring Issues", "Critical Issues", "Orphaned Views"). ALL categories go in the same table. The Finding column carries the context.

All findings MUST be presented in this format, sorted by Urgency then ROI:

```markdown
| # | Finding | Urgency | Risk: Fix | Risk: No Fix | ROI | Blast Radius | Fix Effort |
|---|---------|---------|-----------|-------------|-----|-------------|------------|
| 1 | Dead end: "View Warranty" → empty sheet | 🔴 Critical | ⚪ Low | 🔴 Critical | 🟠 Excellent | 🟢 2 files | Trivial |
| 2 | Promise-scope mismatch: "Track Price" opens generic list | 🟡 High | 🟢 Medium | 🟡 High | 🟠 Excellent | 🟡 4 files | Small |
```

Use the Issue Rating scale:
- **Urgency:** 🔴 CRITICAL (dead end, wrong destination, mock data) · 🟡 HIGH (broken promise, missing activation, unwired data) · 🟢 MEDIUM (two-step flow, missing feedback) · ⚪ LOW (inconsistency, orphaned code)
- **Risk: Fix:** Risk of the fix introducing regressions
- **Risk: No Fix:** User-facing consequence of leaving the issue
- **ROI:** 🟠 Excellent · 🟢 Good · 🟡 Marginal · 🔴 Poor
- **Blast Radius:** How many files/entry points are affected
- **Fix Effort:** Trivial / Small / Medium / Large

### End-of-Audit Suggestion

After presenting audit results, always print:

```
💡 To generate a phased fix plan from these findings, run: /plan --workflow-audit
```

---

## Handoff Brief Generation

After completing all layers (full audit) or `fix` mode, generate `.workflow-audit/handoff.yaml` for consumption by the planning skill.

### When to Generate

- After a full 5-layer audit completes
- After `fix` mode completes (refreshes the brief with current state)
- NOT after individual layer runs (layer1, layer2, etc.)

### Format

```yaml
# Handoff Brief — generated by workflow-audit
# Consumed by /plan --workflow-audit

project: <project name from directory>
audit_date: <ISO 8601 date>
source_files_scanned: <count>

summary:
  total_issues: <count>
  critical: <count>
  high: <count>
  medium: <count>
  low: <count>

file_timestamps:
  <file path>: "<ISO 8601 mod date>"
  # one entry per unique file referenced in issues[]

issues:
  - id: <sequential number>
    finding: "<description>"
    category: <dead_end|wrong_destination|mock_data|incomplete_navigation|missing_activation|unwired_data|platform_gap|promise_scope_mismatch|buried_primary_action|dismiss_trap|two_step_flow|missing_feedback|gesture_only_action|loading_state_trap|inconsistent_pattern|orphaned_code>
    urgency: <critical|high|medium|low>
    risk_fix: <critical|high|medium|low>
    risk_no_fix: <critical|high|medium|low>
    roi: <excellent|good|marginal|poor>
    blast_radius: "<description, e.g. '1 file' or '4 files'>"
    fix_effort: <trivial|small|medium|large>
    files:
      - <file path>
    suggested_fix: "<what to do, not how>"
    group_hint: "<optional grouping suggestion, e.g. 'missing_confirmations'>"
```

### File Timestamps

For each unique file path referenced across all issues, record its modification date at audit time. This enables the planning skill to detect staleness — if a file changed after the audit, affected issues may need re-verification.

```bash
# Get file mod date (macOS)
stat -f "%Sm" -t "%Y-%m-%dT%H:%M:%SZ" "<file path>"
```

### Group Hints

Optional field suggesting how the planning skill might batch issues:
- Issues with the same `group_hint` are candidates for a single task
- The planning skill is free to ignore hints and group differently
- Common hints: `missing_confirmations`, `missing_feedback`, `orphaned_features`, `dead_code`, `platform_parity`

</workflow-audit>
