# Layer 1: Pattern Discovery

## Overview

Layer 1 scans the codebase for UI entry points - places where users can trigger navigation, sheets, or actions. The goal is to create a complete inventory of "things users can tap."

## SwiftUI Entry Point Patterns

### 1. Promotion Cards (HIGH VALUE — may be absent)
Feature discovery cards on dashboard. These are prime workflow audit targets.

```regex
# File-based search (grep -l)
PromotionCard\s*\(
CompactPromotionCard\s*\(

# Content extraction (grep -o with context)
PromotionCard\s*\([\s\S]*?title:\s*"([^"]+)"
```

**Note:** This pattern may return 0 matches if promotion cards have been removed from the codebase. This is expected — report as "Pattern no longer present (0 matches)" rather than silently skipping.

### 2. Sheet Triggers (HIGH VALUE)
Central sheet management via enum. Best pattern for auditing.

```regex
# Find all sheet case assignments
activeSheet\s*=\s*\.(\w+)

# Find sheet enum definition
enum\s+\w*Sheet\w*\s*:\s*\w+\s*\{[\s\S]*?\}
```

**Discovered:** 29 cases in `DashboardSheetType`, 70+ trigger sites

### 3. Context Menus (MEDIUM VALUE)
Long-press / right-click actions on list items.

```regex
\.contextMenu\s*\{
```

**Discovered:** 12 files with context menus

### 4. Swipe Actions (MEDIUM VALUE)
Swipe gestures on list rows.

```regex
\.swipeActions
```

**Discovered:** 9 files with swipe actions

### 5. Navigation Links (MEDIUM VALUE)
Direct navigation without sheets.

```regex
NavigationLink\s*\(
```

**Discovered:** 6 files (relatively rare - app prefers sheets)

### 6. Boolean State Triggers (LOW VALUE - TOO BROAD)
The `showing\w+ = true` pattern matches 155 files. Too noisy for automated scanning.

**Recommendation:** Skip this pattern in Layer 1. Use targeted grep when investigating specific views in Layer 2.

### 7. Toolbar Items (NEEDS REFINEMENT)
Multiline regex doesn't work well with grep. Use file-based search instead.

```regex
# Find files with toolbar buttons
ToolbarItem[\s\S]*Button
```

**Recommendation:** Read toolbar-heavy files directly in Layer 2.

## Zero-Match Handling

When a scanned pattern returns 0 results, do NOT silently skip it. Instead:

1. **Report it** in the Layer 1 inventory: `"<PatternName>: 0 matches — pattern no longer present in codebase"`
2. **Check if the pattern was recently removed** (git log for deleted files matching the pattern name)
3. **Update the discovery count** — if a pattern previously found N items and now finds 0, this signals a codebase change worth noting

This prevents confusion in the audit output where a category appears to be "clean" when it was actually never scanned.

## Pattern Effectiveness

| Pattern | Files Found | Noise Level | Recommendation |
|---------|-------------|-------------|----------------|
| PromotionCard | 0-1 | Very Low | ✅ Use (report 0 if absent) |
| activeSheet = | 70+ | Low | ✅ Use |
| .contextMenu | 12 | Low | ✅ Use |
| .swipeActions | 9 | Low | ✅ Use |
| NavigationLink | 6 | Low | ✅ Use |
| showing* = true | 155 | Very High | ❌ Skip |
| ToolbarItem+Button | 0 | N/A | 🔄 Refine |

## Output Schema

```yaml
entry_points:
  - id: "dashboard-card-001"
    type: "promotion_card"
    label: "Track AppleCare+"
    file: "DashboardView+PromotionCards.swift"
    line: 91
    action: "activeSheet = .appleCareTracking"
    action_type: "sheet"
    destination: ".appleCareTracking"
    condition: "hasUntrackedAppleProducts"
    flags:
      - "two_step_flow"
```

## Flags for Layer 2

During discovery, flag entry points that may have workflow issues:

| Flag | Description |
|------|-------------|
| `two_step_flow` | Requires intermediate picker/selection |
| `promise_scope_mismatch` | Specific CTA opens generic/broad destination |
| `incomplete_navigation` | Lands on section, not specific feature |
| `no_confirmation` | Destructive action without confirmation |
| `missing_feedback` | No success/error indication |
| `orphaned` | Destination view has no entry point |

## Learnings from Stuffolio Scan

1. **Centralized sheets are auditable** - The `DashboardSheetType` enum makes it easy to catalog all sheets
2. **Promotion cards are workflow entry points** - They represent intentional feature discovery paths
3. **Boolean state explosion is real** - 155 files with `showing*` state variables
4. **Context menus vary by context** - Different actions available in different list views
