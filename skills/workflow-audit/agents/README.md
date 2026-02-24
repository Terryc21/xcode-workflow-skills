# Workflow Audit Skill

A systematic approach to discovering, tracing, evaluating, and verifying UI workflows in SwiftUI applications.

## Overview

The Workflow Audit Skill uses a 5-layer approach to identify workflow issues:

| Layer | Purpose | Output |
|-------|---------|--------|
| **Layer 1: Pattern Discovery** | Find all UI entry points | Entry point inventory |
| **Layer 2: Flow Tracing** | Trace critical paths in depth | Detailed flow traces |
| **Layer 3: Issue Detection** | Categorize issues across codebase | Issue catalog |
| **Layer 4: Semantic Evaluation** | Evaluate from user perspective | UX impact analysis |
| **Layer 5: Data Wiring** | Verify features use real data | Data integrity report |

## Quick Start

### 1. Run Layer 1 Discovery
```bash
# Find promotion cards
grep -r "PromotionCard\s*(" Sources/ --include="*.swift"

# Find sheet triggers
grep -r "activeSheet = \." Sources/ --include="*.swift"

# Find navigation
grep -r "selectedSection = \." Sources/ --include="*.swift"

# Find context menus
grep -r "\.contextMenu" Sources/ --include="*.swift"
```

### 2. Check Layer 3 Automated Tests
```bash
# Sheet coverage: all enum cases should have handlers
# Compare DashboardSheetType cases vs sheetContent(for:) handlers

# Orphan check: views should be instantiated somewhere
# grep for "struct XxxView: View" then verify usage
```

### 3. Review Outputs
- `layer1-inventory.yaml` - All entry points cataloged
- `layer2-traces/` - Detailed flow traces
- `layer3-results.yaml` - Categorized issues
- `layer4-semantic-evaluation.md` - User impact analysis
- `layer5-data-wiring.yaml` - Data integrity audit

## Issue Categories

| Category | Severity | Description |
|----------|----------|-------------|
| Dead End | 🔴 CRITICAL | Entry point leads nowhere |
| Wrong Destination | 🔴 CRITICAL | Entry point leads to wrong place |
| Mock Data | 🔴 CRITICAL | Fake data displayed as real |
| Incomplete Navigation | 🟠 HIGH | User must scroll/search after landing |
| Missing Auto-Activation | 🟠 HIGH | Expected mode/state not set |
| Unwired Data | 🟠 HIGH | Real data exists but isn't used |
| Platform Parity Gap | 🟠 HIGH | Feature works on iOS but not macOS |
| Two-Step Flow | 🟡 MEDIUM | Intermediate selection required |
| Missing Feedback | 🟡 MEDIUM | No confirmation of success |
| Inconsistent Pattern | 🟢 LOW | Same feature accessed differently |
| Orphaned Code | 🟢 LOW | Feature exists but no entry point |

## Pattern Library

### Good Patterns

**Sheet-based feature access:**
```swift
// ✅ Good - immediate access
action: { activeSheet = .stuffScout }
```

**Item picker for context-dependent features:**
```swift
// ✅ Good - provides necessary context
case .appleCareTracking:
    AppleCareTrackingSheet(
        appleProducts: appleProductsWithoutAppleCare,
        onItemSelected: { item in /* show feature */ }
    )
```

### Problematic Patterns

**Section navigation for feature discovery:**
```swift
// ❌ Bad - user lands at section top, not feature
action: { selectedSection = .tools }
```

**Navigation without state setup:**
```swift
// ❌ Bad - expected mode not activated
action: { selectedSection = .myProducts }
// Should also set: isSelectMode = true
```

## Files

```
.agents/workflow-audit/
├── README.md                      # This file
├── layer1-patterns.md             # Discovery regex patterns
├── layer1-inventory.yaml          # Entry point catalog
├── layer1-summary.md              # Layer 1 findings
├── layer2-methodology.md          # Flow tracing process
├── layer2-summary.md              # Layer 2 findings
├── layer2-traces/                 # Detailed flow traces
│   ├── flow-001-pricewatch.yaml
│   ├── flow-002-repairadvisor.yaml
│   └── flow-003-bulkactions.yaml
├── layer3-issue-detection.md      # Issue detection methodology
├── layer3-results.yaml            # Categorized issues
├── layer4-semantic-evaluation.md  # User impact analysis
└── layer5-data-wiring.md          # Data wiring methodology
```

## Results Summary (Stuffolio v1.0)

### Issues Found: 8

| Severity | Count | Key Issue |
|----------|-------|-----------|
| 🔴 Critical | 1 | Repair Advisor dead end |
| 🟠 High | 3 | Price Watch scroll, Bulk Actions mode, duplicate code |
| 🟡 Medium | 2 | Two-step flows, inconsistent patterns |
| 🟢 Low | 2 | Missing feedback (edge cases), orphaned code |

### Recommended Fix Order

1. **Bulk Actions** (5 min) - Change to `activeSheet = .bulkEdit`
2. **Price Watch** (15 min) - Add sheet type, use `activeSheet`
3. **Repair Advisor** (2-3 hrs) - Create `DamagedItemsPickerSheet`
4. **Duplicate code** (30 min) - Remove redundant `@ViewBuilder` cards

## Usage in Other Projects

This skill can be adapted to any SwiftUI project:

1. **Identify entry point patterns** - What UI elements trigger navigation/sheets?
2. **Create pattern library** - Regex patterns for your project's conventions
3. **Run Layer 1 discovery** - Catalog all entry points
4. **Flag suspicious patterns** - Navigation without deep link, missing state setup
5. **Trace critical flows** - Focus on user-facing features
6. **Evaluate user impact** - Does the workflow help users achieve their goals?

## Design Principles

### 1. Honor the Promise
> When a button/card says "Do X", tapping it should DO X.
> Not "go somewhere you might find X."

### 2. Context-Aware Shortcuts
> If user's context implies a specific item, skip pickers.
> One damaged item → Open repair advisor for that item.

### 3. State Preservation
> When navigating to a feature, set up the expected state.
> "Bulk Actions" → Enter Select mode automatically.

### 4. Consistent Access Patterns
> Same feature should be accessed the same way everywhere.
> Standardize on sheet pattern for feature discovery.

### 5. Data Integrity
> Never show mock/hardcoded data when real user data exists.
> If the model tracks it, the feature should use it.

## Maintenance

Re-run this audit when:
- Adding new promotion cards or feature discovery UI
- Adding new sections or navigation destinations
- Refactoring sheet management
- User reports "I can't find X" issues
