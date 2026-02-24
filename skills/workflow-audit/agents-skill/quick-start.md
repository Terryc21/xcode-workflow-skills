# Quick Start Guide

Get started auditing workflows in your SwiftUI project.

## Step 1: Set Up (5 minutes)

1. Copy this directory to `.agents/workflow-audit/` in your project
2. Read `pattern-library.md` to understand what patterns to look for
3. Identify your project's conventions:
   - Sheet management pattern (enum? scattered bindings?)
   - Navigation pattern (tabs? sections? NavigationStack?)
   - Feature discovery UI (cards? buttons? menus?)

## Step 2: Layer 1 Discovery (30-60 minutes)

Run these searches and document in `layer1-inventory.yaml`:

```bash
# Adapt patterns to your project's naming conventions

# Sheet triggers
grep -r "activeSheet = \." Sources/ --include="*.swift"
grep -r "showingSheet = " Sources/ --include="*.swift"
grep -rE "\.sheet\s*\(item:" Sources/ --include="*.swift"

# Navigation
grep -r "selectedTab = " Sources/ --include="*.swift"
grep -r "selectedSection = " Sources/ --include="*.swift"

# Feature cards
grep -rE "(Feature|Promotion|Action)Card" Sources/ --include="*.swift"

# Context menus
grep -r "\.contextMenu" Sources/ --include="*.swift"
```

### Flag Suspicious Patterns

While cataloging, flag entry points that:
- Use section navigation for specific features
- Have labels implying mode (e.g., "Bulk Edit") without state setup
- Lead to views that require item context

## Step 3: Prioritize Flows to Trace (15 minutes)

Not all flows need deep tracing. Prioritize:

| Priority | Type | Example |
|----------|------|---------|
| High | Promotional cards | Feature discovery UI |
| High | Flagged navigation | Section nav for features |
| Medium | Context menus | Destructive actions |
| Low | Settings/admin | Less critical paths |

Pick 3-5 flows for Layer 2 deep traces.

## Step 4: Layer 2 Flow Tracing (30-60 min per flow)

For each prioritized flow, create `layer2-traces/flow-XXX.yaml`:

1. **Start at entry point** - Find the button/card in code
2. **Follow the action** - What happens on tap?
3. **Trace to destination** - What view appears?
4. **Check user goal** - Can user complete the task?
5. **Note feedback** - Is success/failure shown?

### Quick Trace Template

```yaml
flow:
  entry_point: "Card title"
  action: "activeSheet = .xxx"
  destination: "XxxView"
  goal_achievable: true/false
  feedback_shown: true/false
  issue: "Brief description if any"
```

## Step 5: Layer 3 Issue Detection (1-2 hours)

Scan ALL entry points for common issues:

### Check 1: Dead Ends
```bash
# Find sheet enum cases
grep "case " Models/SheetType.swift | wc -l

# Find handler cases
grep "case \." Views/SheetContent.swift | wc -l

# Difference = potential dead ends
```

### Check 2: Orphaned Views
```bash
# Views defined but never used
for view in $(grep -r "struct.*: View" Sources/ -h | sed 's/.*struct \([A-Za-z]*\):.*/\1/'); do
  count=$(grep -r "$view(" Sources/ | grep -v "#Preview" | wc -l)
  [ "$count" -eq 0 ] && echo "Orphaned: $view"
done
```

### Check 3: Pattern Consistency
Group entry points by destination. Same feature should have same access pattern everywhere.

## Step 6: Layer 4 Semantic Evaluation (1-2 hours)

Answer these questions for each issue:

1. **What did user expect?** (Based on UI label)
2. **What actually happened?** (Based on code trace)
3. **How would user feel?** (Confused, frustrated, satisfied)
4. **What's the business impact?** (Abandonment, support tickets)

## Step 7: Fix and Verify

### Fix Priority
1. 🔴 Critical (dead ends) - Fix immediately
2. 🟠 High (confusion) - Fix before release
3. 🟡 Medium (friction) - Fix if time
4. 🟢 Low (polish) - Backlog

### Verification Checklist
After each fix:
- [ ] Entry point opens correct destination
- [ ] User can complete goal
- [ ] Feedback is shown on success/failure
- [ ] No regression in related flows

## Common Quick Fixes

### Fix: Section Navigation → Sheet

**Before:**
```swift
action: { selectedSection = .tools }
```

**After:**
```swift
// 1. Add sheet case
enum SheetType {
    case priceWatch  // Add this
}

// 2. Add handler
case .priceWatch:
    PriceWatchView()

// 3. Update action
action: { activeSheet = .priceWatch }
```

### Fix: Missing State Setup

**Before:**
```swift
action: { selectedSection = .myItems }
```

**After:**
```swift
action: {
    selectedSection = .myItems
    isSelectMode = true  // Add state setup
}
```

### Fix: Item Picker for Context Features

**Before:**
```swift
// Links to wrong destination or crashes
action: { selectedSection = .tools }
```

**After:**
```swift
// 1. Create picker sheet
struct ItemPickerSheet: View {
    let items: [Item]
    let onSelect: (Item) -> Void
    // Show list, call onSelect on tap
}

// 2. Add sheet type
case .itemPicker

// 3. Handle selection → open feature
```

## Time Estimates

| Phase | Time | Output |
|-------|------|--------|
| Setup | 5 min | Understanding of project patterns |
| Layer 1 | 30-60 min | Entry point inventory |
| Layer 2 | 30-60 min/flow | 3-5 detailed flow traces |
| Layer 3 | 1-2 hours | Complete issue catalog |
| Layer 4 | 1-2 hours | User impact analysis |
| **Total** | **4-8 hours** | **Complete audit** |

## When to Re-run

- Before major releases
- After adding feature discovery UI
- After navigation refactoring
- When users report "can't find X"
