# Pattern Library

SwiftUI patterns to detect during workflow audits. Adapt these regex patterns to your project's naming conventions.

## Entry Point Patterns

### 1. Sheet Triggers (HIGH VALUE)

Central sheet management is the easiest pattern to audit.

```bash
# Generic patterns
grep -r "activeSheet\s*=\s*\." Sources/ --include="*.swift"
grep -r "showingSheet\s*=\s*true" Sources/ --include="*.swift"
grep -r "\.sheet\s*(" Sources/ --include="*.swift"

# Find sheet enum definition
grep -rE "enum\s+\w*Sheet\w*\s*:" Sources/ --include="*.swift"
```

**Audit Focus:**
- Every enum case should have a handler
- Handler should present the correct view
- View should match user expectation from trigger label

### 2. Tab/Section Navigation (HIGH VALUE)

Tab changes and section navigation.

```bash
# Tab selection
grep -r "selectedTab\s*=" Sources/ --include="*.swift"
grep -r "selection\s*=" Sources/ --include="*.swift" | grep -i tab

# Section navigation
grep -r "selectedSection\s*=" Sources/ --include="*.swift"

# NavigationPath changes
grep -r "\.append\s*(" Sources/ --include="*.swift" | grep -i path
```

**Audit Focus:**
- Does navigation land on correct section?
- Is deep linking supported (scroll to specific item)?
- Is expected state set (selection mode, filters)?

### 3. Promotion/Feature Cards (HIGH VALUE)

Feature discovery UI - prime audit targets.

```bash
# Common naming patterns
grep -rE "(Promotion|Feature|Action|Tip|Discovery)Card" Sources/ --include="*.swift"

# Cards with actions
grep -rE "title:\s*\"[^\"]+\"[\s\S]*action:" Sources/ --include="*.swift"
```

**Audit Focus:**
- Does card title match destination?
- Is destination the feature itself (not a section containing it)?
- Any intermediate steps required?

### 4. Context Menus (MEDIUM VALUE)

Right-click / long-press actions on items.

```bash
grep -r "\.contextMenu\s*{" Sources/ --include="*.swift"
grep -r "\.contextMenu\s*(" Sources/ --include="*.swift"
```

**Audit Focus:**
- Do actions work on the correct item?
- Are destructive actions confirmed?
- Is feedback provided after action?

### 5. Swipe Actions (MEDIUM VALUE)

Swipe gestures on list rows.

```bash
grep -r "\.swipeActions" Sources/ --include="*.swift"
```

**Audit Focus:**
- Do swipe actions match context menu actions?
- Are they available on the expected rows?
- Is feedback provided?

### 6. Navigation Links (MEDIUM VALUE)

Direct navigation without sheets.

```bash
grep -r "NavigationLink\s*(" Sources/ --include="*.swift"
```

**Audit Focus:**
- Does destination view exist?
- Is required state passed correctly?
- Is back navigation clean?

### 7. Boolean State Triggers (LOW VALUE - NOISY)

Individual showing states can be noisy.

```bash
# This will match many files - use selectively
grep -rE "showing\w+\s*=\s*true" Sources/ --include="*.swift"
grep -rE "isPresented\s*=\s*true" Sources/ --include="*.swift"
```

**Recommendation:** Skip in broad scans. Use for targeted investigation.

### 8. Toolbar Items (LOW VALUE - HARD TO PARSE)

Multiline patterns are hard to grep.

```bash
# Find files with toolbar buttons
grep -l "ToolbarItem" Sources/**/*.swift
```

**Recommendation:** Read toolbar-heavy files manually.

---

## Action Patterns

### Sheet-Based Feature Access (GOOD)

```swift
// Direct feature access via sheet
action: { activeSheet = .priceWatch }
```

**Why Good:**
- Immediate access
- Clear destination
- Easy to audit (follow enum case)

### Item Picker Flow (GOOD when necessary)

```swift
// Two-step flow when item context required
case .aiAssistant:
    ItemPickerSheet(
        items: eligibleItems,
        onItemSelected: { item in
            selectedItem = item
            showAIAssistant = true
        }
    )
```

**Why Good:**
- Provides necessary context
- Clear user flow
- Handles multiple items gracefully

### Section Navigation for Features (PROBLEMATIC)

```swift
// Landing on section, not feature
action: { selectedSection = .tools }
// User must scroll to find PriceWatch
```

**Why Bad:**
- User lands at section top
- Must search for feature
- Breaks "honor the promise" principle

**Fix:**
```swift
// Option A: Use sheet
action: { activeSheet = .priceWatch }

// Option B: Deep link
action: {
    selectedSection = .tools
    scrollTarget = "priceWatch"
}
```

### Navigation Without State Setup (PROBLEMATIC)

```swift
// "Bulk Edit" card without mode activation
action: { selectedSection = .myItems }
```

**Why Bad:**
- User expects selection mode
- Must find and tap "Select" button
- Breaks expectation set by card

**Fix:**
```swift
action: {
    selectedSection = .myItems
    isSelectMode = true
}
```

---

## Destination Patterns

### Centralized Sheet Handler (RECOMMENDED)

```swift
func sheetContent(for sheet: SheetType) -> some View {
    switch sheet {
    case .addItem:
        AddItemView()
    case .settings:
        SettingsView()
    // ... all cases handled
    }
}
```

**Why Good:**
- Single source of truth
- Easy to audit (all cases visible)
- Compiler warns on missing cases

### Inline Sheet Presentation (HARDER TO AUDIT)

```swift
.sheet(isPresented: $showingAddItem) {
    AddItemView()
}
.sheet(isPresented: $showingSettings) {
    SettingsView()
}
// Sheets scattered across views
```

**Why Harder:**
- Must grep entire codebase
- Easy to miss entry points
- Harder to maintain consistency

---

## Feedback Patterns

### Success Toast (GOOD)

```swift
func saveItem() {
    try modelContext.save()
    ToastManager.shared.success("Item saved")
    dismiss()
}
```

### Confirmation Dialog (GOOD for destructive)

```swift
.confirmationDialog("Delete item?", isPresented: $showingDelete) {
    Button("Delete", role: .destructive) {
        delete()
    }
    Button("Cancel", role: .cancel) { }
}
```

### No Feedback (PROBLEMATIC)

```swift
func saveItem() {
    try modelContext.save()
    dismiss()  // Did it work? User doesn't know
}
```

---

## Pattern Effectiveness Summary

| Pattern | Files Typically Found | Noise Level | Recommendation |
|---------|----------------------|-------------|----------------|
| Sheet enum triggers | 10-50 | Low | ✅ Primary focus |
| Promotion cards | 1-5 | Very Low | ✅ High priority |
| Context menus | 5-20 | Low | ✅ Check |
| Swipe actions | 5-15 | Low | ✅ Check |
| Navigation links | 5-30 | Medium | ✅ Check |
| Boolean states | 100+ | Very High | ⚠️ Selective only |
| Toolbar items | 20-50 | High | ⚠️ Manual review |

---

## Data Wiring Patterns (Layer 5)

### Mock Fetch (CRITICAL - Category 9)

```swift
// ❌ BAD: Fake async fetch with hardcoded data
func fetchRepairInfo() {
    isLoading = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
        self.repairInfo = RepairContext(
            repairabilityScore: 7,           // Hardcoded
            estimatedRepairCost: "$85-150",   // Made up
            commonFailurePoints: ["Battery"]  // Not from data
        )
        self.isLoading = false
    }
}
```

```swift
// ✅ GOOD: Real computation from model data
func fetchRepairInfo() {
    let avgCost = item.averageRepairCostInCents
    let issues = item.rmaRecords?.map { $0.issueDescription } ?? []

    self.repairInfo = RepairContext(
        repairabilityScore: categoryScore(for: item.category),
        estimatedRepairCost: avgCost.map { formatCents($0) },
        commonFailurePoints: Array(Set(issues)).prefix(3).map { $0 }
    )
}
```

**Detection:**
```bash
# Find asyncAfter in non-UI code (fake fetches)
grep -rn "asyncAfter" Sources/Features/ --include="*.swift" -B 2 -A 10
# If followed by hardcoded data assignment, flag as mock
```

### Unwired Model Data (HIGH - Category 10)

```swift
// ❌ BAD: Decision ignores available data
func computePath() -> DecisionPath {
    if item.assetAge > lifespan * 0.8 { return .replace }
    if item.userRating ?? 5 < 3 { return .replace }
    return .keep
    // Ignores: repair costs, warranty, condition, brand, market price
}
```

```swift
// ✅ GOOD: Decision uses all available data
func computePath() -> DecisionPath {
    var scores: [DecisionPath: Int] = [.repair: 10, .keep: 0, .replace: 0, .alternatives: 0]

    // Use repair cost data
    if let avgRepair = item.averageRepairCostInCents,
       let replacement = item.bestReplacementCostInCents,
       avgRepair < (replacement * 40 / 100) {
        scores[.repair, default: 0] += 15
    }

    // Use warranty data
    if item.hasActiveWarranty { scores[.repair, default: 0] += 10 }

    // Use rating data
    if let rating = item.userRating, rating >= 4 { scores[.keep, default: 0] += 10 }

    // Use brand data
    if item.wouldBuyAgain == false { scores[.alternatives, default: 0] += 15 }

    return scores.max(by: { $0.value < $1.value })?.key ?? .keep
}
```

**Detection:**
```bash
# Find decision/compute functions
grep -rn "func compute\|func decide\|func recommend" Sources/Features/ --include="*.swift"

# Count model properties referenced vs available
grep -cn "item\." Sources/Features/FeatureName/ --include="*.swift"
```

### Placeholder AI (CRITICAL - Category 9)

```swift
// ❌ BAD: Static data pretending to be AI result
func fetchAlternatives() {
    isLoadingAI = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        self.alternatives = [
            AIAlternative(name: "Product X", price: "$299"),
            AIAlternative(name: "Product Y", price: "$199"),
        ]
        self.isLoadingAI = false
    }
}
```

```swift
// ✅ GOOD: Cross-link to real AI backend
Button("Find Alternatives with AI") {
    showingAIAlternatives = true
}
.sheet(isPresented: $showingAIAlternatives) {
    AIProductAssistantView(item: item, initialQuery: .currentPrice)
}
```

### Platform Parity (HIGH - Category 11)

```swift
// ❌ BAD: iOS-only dismiss traps macOS users
#if os(iOS)
ToolbarItem(placement: .cancellationAction) {
    Button("Done") { dismiss() }
}
#endif
```

```swift
// ✅ GOOD: Cross-platform dismiss
ToolbarItem(placement: .cancellationAction) {
    Button("Done") { dismiss() }
}
```

```swift
// ❌ BAD: Extension references wrapper that breaks on macOS
// In DashboardView+Extension.swift:
AppleCareSheet(items: appleProductsWithoutAppleCare)  // can't find in scope

// ✅ GOOD: Inline the filtering
AppleCareSheet(items: allItems.filter { item in
    guard let m = item.manufacturer, m.localizedCaseInsensitiveContains("apple") else { return false }
    if let w = item.extendedWarranty { return !w.isAppleCare }
    return true
})
```

**Detection:**
```bash
# Build both platforms
build_sim && build_macos

# Find iOS-only dismiss patterns
grep -rn "#if os(iOS)" Sources/ --include="*.swift" -A 3 | grep -i "dismiss\|done\|toolbar"
```

---

## Project-Specific Adaptation

When using this skill on a new project:

1. **Find your sheet pattern**
   - Is there a central `SheetType` enum?
   - Or are sheets scattered with `isPresented` bindings?

2. **Find your navigation pattern**
   - Tab-based? Section-based? NavigationStack?
   - What state variables control navigation?

3. **Identify feature cards**
   - What components display promotional/feature discovery UI?
   - Naming convention used?

4. **Document in layer1-patterns.md**
   - Create project-specific version
   - Add grep patterns that work for your codebase
