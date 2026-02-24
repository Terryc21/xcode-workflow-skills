# Workflow Audit Skill

A systematic approach to discovering, tracing, evaluating, and verifying UI workflows in SwiftUI applications.

## Overview

The Workflow Audit Skill uses a 5-layer approach to identify workflow issues before users encounter them:

| Layer | Purpose | Output | Time |
|-------|---------|--------|------|
| **Layer 1: Pattern Discovery** | Find all UI entry points | Entry point inventory | 30-60 min |
| **Layer 2: Flow Tracing** | Trace critical paths in depth | Detailed flow traces | 30-60 min/flow |
| **Layer 3: Issue Detection** | Categorize issues across codebase | Issue catalog | 1-2 hours |
| **Layer 4: Semantic Evaluation** | Evaluate from user perspective | UX impact analysis | 1-2 hours |
| **Layer 5: Data Wiring** | Verify features use real data | Data integrity report | 1-2 hours |

## When to Use This Skill

- **Pre-release audit** - Before App Store submission
- **After adding new features** - Verify new entry points work
- **User feedback** - "I can't find X" complaints
- **Refactoring navigation** - Verify nothing broke
- **Design review** - Evaluate workflow efficiency

## Quick Start

### 1. Identify Your Project's Patterns

Every SwiftUI project has patterns for:
- **Sheet management** - How sheets are presented
- **Navigation** - Tab bar, NavigationStack, sidebar
- **Entry points** - Cards, buttons, menus that trigger actions

Look for centralized enums like `SheetType`, state variables like `selectedTab`, or navigation paths.

### 2. Run Layer 1 Discovery

```bash
# Find sheet triggers (adapt pattern to your naming)
grep -r "activeSheet = \." Sources/ --include="*.swift"
grep -r "showingSheet = " Sources/ --include="*.swift"

# Find navigation changes
grep -r "selectedTab = " Sources/ --include="*.swift"
grep -r "NavigationLink" Sources/ --include="*.swift"

# Find feature cards / promotional UI
grep -r "FeatureCard\|PromotionCard\|ActionCard" Sources/ --include="*.swift"

# Find context menus and swipe actions
grep -r "\.contextMenu" Sources/ --include="*.swift"
grep -r "\.swipeActions" Sources/ --include="*.swift"
```

### 3. Check for Common Issues

```bash
# Orphan check: enum cases without handlers
# Compare: enum XxxSheetType cases vs switch cases in sheet content

# Dead code: Views never instantiated
grep -r "struct.*: View" Sources/ | while read line; do
  view=$(echo "$line" | sed 's/.*struct \([A-Za-z]*\):.*/\1/')
  if ! grep -rq "$view(" Sources/; then
    echo "Possibly orphaned: $view"
  fi
done
```

### 4. Review Issue Categories

See [issue-categories.md](issue-categories.md) for the full taxonomy.

## Design Principles

### 1. Honor the Promise
> When a button/card says "Do X", tapping it should DO X.
> Not "go somewhere you might find X."

**Bad:**
```swift
// Card says "Price Tracker" but lands on generic Tools section
action: { selectedSection = .tools }
```

**Good:**
```swift
// Card says "Price Tracker" - opens Price Tracker
action: { activeSheet = .priceTracker }
```

### 2. Context-Aware Shortcuts
> If user's context implies a specific item, skip pickers.

**Good:**
```swift
// Only one item matches - go directly
if eligibleItems.count == 1 {
    showFeature(for: eligibleItems[0])
} else {
    showItemPicker(items: eligibleItems)
}
```

### 3. State Preservation
> When navigating to a feature, set up the expected state.

**Bad:**
```swift
// "Bulk Edit" card just navigates to list
action: { selectedSection = .myItems }
```

**Good:**
```swift
// "Bulk Edit" card activates selection mode
action: {
    selectedSection = .myItems
    isSelectMode = true
}
```

### 4. Consistent Access Patterns
> Same feature should be accessed the same way everywhere.

If "Export" is available via sheet in one place and navigation in another, users get confused. Standardize.

## Files in This Skill

```
workflow-audit-skill/
├── README.md                     # This file
├── quick-start.md                # Getting started guide
├── issue-categories.md           # Issue taxonomy and severity
├── pattern-library.md            # SwiftUI patterns to detect
├── templates/
│   ├── layer1-inventory.yaml     # Entry point catalog template
│   ├── layer2-flow-trace.yaml    # Flow trace template
│   ├── layer3-issue.yaml         # Issue documentation template
│   ├── layer4-evaluation.yaml    # Semantic evaluation template
│   └── layer5-data-wiring.yaml   # Data integrity audit template
└── examples/
    ├── good-patterns.swift       # Patterns to emulate
    └── bad-patterns.swift        # Anti-patterns to avoid
```

## Using This Skill on a New Project

1. **Copy the skill directory** to `.agents/workflow-audit/` in your project
2. **Adapt pattern-library.md** to your project's conventions
3. **Run Layer 1 discovery** to create your inventory
4. **Prioritize flows to trace** based on risk
5. **Document issues** using the templates
6. **Fix and verify** using the semantic evaluation criteria

## Issue Severity Guide

| Severity | User Impact | Example |
|----------|-------------|---------|
| 🔴 **Critical** | Cannot complete goal, fake data | Dead end, mock data, placeholder AI |
| 🟠 **High** | Extra steps, missing data, broken platform | Unwired data, platform parity gap |
| 🟡 **Medium** | Friction but completable | Intermediate picker, simplified logic |
| 🟢 **Low** | Minor polish | Inconsistent wording, missing feedback |

## Integration with Other Audits

This skill complements:
- **Accessibility audit** - Can users with disabilities complete workflows?
- **Performance audit** - Are workflows responsive?
- **Error handling audit** - What happens when things go wrong?

## Maintenance

Re-run this audit when:
- Adding new promotional cards or feature discovery UI
- Adding new sections or navigation destinations
- Refactoring sheet/navigation management
- Users report "I can't find X" issues
- Major version updates

## License

MIT - Use freely in your projects.
