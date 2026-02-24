---
name: workflow-audit
description: Systematic UI workflow auditing for SwiftUI applications. Discovers entry points, traces user flows, detects dead ends and broken promises, audits data wiring, evaluates from user perspective.
version: 2.1.0
---

# Workflow Audit Skill

<workflow-audit>

You are performing a systematic workflow audit on this SwiftUI application.

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
| Incomplete Navigation | 🟠 HIGH | User must scroll/search after landing |
| Missing Auto-Activation | 🟠 HIGH | Expected mode/state not set |
| Unwired Data | 🟠 HIGH | Model data exists but feature ignores it |
| Platform Parity Gap | 🟠 HIGH | Feature works on one platform, broken on another |
| Promise-Scope Mismatch | 🟠 HIGH | Specific CTA opens generic/broad destination |
| Two-Step Flow | 🟡 MEDIUM | Intermediate selection required |
| Missing Feedback | 🟡 MEDIUM | No confirmation of success |
| Inconsistent Pattern | 🟢 LOW | Same feature accessed differently |
| Orphaned Code | 🟢 LOW | Feature exists but no entry point |

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

### If "layer2" or "trace":
1. Read flagged entry points from Layer 1
2. For each flagged entry point, trace the complete user journey
3. Document in `layer2-traces/flow-XXX.yaml`
4. Identify gaps between expected and actual journeys

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

### If "fix" or "fixes":
1. Read `layer3-results.yaml` and `layer5-data-wiring.yaml` for unfixed issues
2. Generate specific code fixes following the patterns in examples/
3. Prioritize by severity (critical first)

### If "status":
1. Read existing audit files
2. Report: issues found, fixed, remaining
3. Show priority queue for unfixed issues

## Output Format

After completing the audit, provide:

1. **Summary** - Total entry points, issues by severity
2. **Critical Issues** - Any blocking problems
3. **Data Wiring Issues** - Features using mock data or ignoring real data
4. **Recommendations** - Prioritized fix list
5. **Next Steps** - What to do next

</workflow-audit>
