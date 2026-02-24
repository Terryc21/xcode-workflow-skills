---
name: workflow-audit
description: Systematic UI workflow auditing for SwiftUI applications. Discovers entry points, traces user flows, detects dead ends and broken promises, evaluates from user perspective.
version: 1.0.0
author: Stuffolio Development
license: MIT
tags:
  - swiftui
  - ios
  - macos
  - audit
  - ux
  - navigation
  - workflow
---

# Workflow Audit Skill

Systematically audit UI workflows in SwiftUI applications to find dead ends, broken promises, and UX friction before users encounter them.

## When to Use

- **Pre-release audit** - Before App Store submission
- **After adding features** - Verify new entry points work correctly
- **User feedback** - When users report "I can't find X"
- **Navigation refactoring** - Verify nothing broke
- **Design review** - Evaluate workflow efficiency

## Invocation

```
/skill workflow-audit
```

Or for specific phases:
```
/skill workflow-audit layer1    # Discovery only
/skill workflow-audit layer2    # Flow tracing
/skill workflow-audit layer3    # Issue detection
/skill workflow-audit layer4    # Semantic evaluation
/skill workflow-audit fix       # Generate fixes for found issues
```

## What It Does

### Layer 1: Pattern Discovery
- Scans for sheet triggers, navigation changes, feature cards
- Catalogs all UI entry points
- Flags suspicious patterns for investigation

### Layer 2: Flow Tracing
- Traces critical user journeys step by step
- Maps expected vs actual paths
- Identifies where flows break down

### Layer 3: Issue Detection
- Categorizes issues by type and severity
- Checks for orphaned views and dead ends
- Audits pattern consistency

### Layer 4: Semantic Evaluation
- Evaluates from user perspective
- Assesses discoverability, efficiency, feedback
- Maps violations to design principles

## Issue Severity

| Severity | Description | Action |
|----------|-------------|--------|
| 🔴 Critical | User cannot complete goal | Fix immediately |
| 🟠 High | Extra steps, confusion | Fix before release |
| 🟡 Medium | Friction but completable | Fix if time |
| 🟢 Low | Minor polish | Backlog |

## Issue Categories

1. **Dead End** - Entry point leads nowhere
2. **Wrong Destination** - Entry point leads to wrong place
3. **Incomplete Navigation** - User must scroll/search after landing
4. **Missing Auto-Activation** - Expected mode not set
5. **Two-Step Flow** - Intermediate selection required
6. **Missing Feedback** - No confirmation of success
7. **Inconsistent Pattern** - Same feature accessed differently
8. **Orphaned Feature** - Feature exists but no entry point

## Design Principles Enforced

### 1. Honor the Promise
> When UI says "Do X", tapping it should DO X.
> Not "go somewhere you might find X."

### 2. Context-Aware Shortcuts
> Skip pickers when only one item is eligible.

### 3. State Preservation
> Set expected state when navigating (e.g., selection mode).

### 4. Consistent Access
> Same feature = same access pattern everywhere.

## Output Files

After running the skill:

```
.agents/workflow-audit/
├── layer1-inventory.yaml       # All entry points
├── layer1-summary.md           # Discovery findings
├── layer2-traces/
│   └── flow-XXX.yaml           # Individual flow traces
├── layer2-summary.md           # Flow trace findings
├── layer3-results.yaml         # Categorized issues
└── layer4-evaluation.md        # User impact analysis
```

## Integration

This skill complements:
- `/axiom:audit accessibility` - Can users with disabilities complete flows?
- `/axiom:audit swiftui-nav` - Navigation correctness
- `/axiom:audit swiftui-performance` - Are flows responsive?

## Requirements

- SwiftUI project with Sources/ directory
- Grep/ripgrep available for pattern matching
- Read access to all Swift files

## Adaptation

When using on a new project:

1. **Identify your patterns** - How does your app manage sheets/navigation?
2. **Adapt pattern-library.md** - Update grep patterns for your conventions
3. **Run Layer 1** - Create your entry point inventory
4. **Prioritize flows** - Pick critical paths to trace
5. **Document issues** - Use the templates
6. **Fix and verify** - Apply design principles

## Time Estimates

| Phase | Time |
|-------|------|
| Layer 1: Discovery | 30-60 min |
| Layer 2: Flow Tracing | 30-60 min/flow |
| Layer 3: Issue Detection | 1-2 hours |
| Layer 4: Evaluation | 1-2 hours |
| **Full Audit** | **4-8 hours** |

## Changelog

### v1.0.0 (Feb 2026)
- Initial release
- 4-layer methodology
- Issue category taxonomy
- Pattern library for SwiftUI
- YAML templates for all layers
- Good/bad pattern examples
