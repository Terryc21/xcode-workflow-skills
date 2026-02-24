# Layer 3: Issue Detection

## Purpose

Layer 3 systematically scans ALL entry points from Layer 1 and applies issue detection rules. Unlike Layer 2 (which traces specific flows in depth), Layer 3 does a breadth-first scan to categorize issues across the entire codebase.

## Issue Categories

### Category 1: Dead Ends
Entry point leads nowhere or to wrong destination.

**Detection patterns:**
```swift
// Navigation to section that doesn't contain the feature
selectedSection = .tools  // but feature not in ToolsView

// Sheet case exists but handler missing
case .featureName  // in enum but no case in sheetContent(for:)

// View exists but no entry point
struct OrphanedFeatureView  // never presented
```

**Severity:** 🔴 CRITICAL

### Category 2: Incomplete Navigation
User lands on section but must find feature manually.

**Detection patterns:**
```swift
// Section navigation without deep link
selectedSection = .tools  // lands at top, feature buried

// No scroll target or anchor
// No programmatic focus
```

**Severity:** 🟠 HIGH

### Category 3: Missing Auto-Activation
Feature requires mode/state that isn't set.

**Detection patterns:**
```swift
// Navigation without state setup
selectedSection = .myProducts  // but isSelectMode not set

// Sheet without pre-population
activeSheet = .edit  // but selectedItem not set
```

**Severity:** 🟠 HIGH

### Category 4: Promise-Scope Mismatch
A specific-sounding CTA opens a generic/overly-broad destination. The user is promised
a focused action but gets a container with the action buried among unrelated content.

Different from "Wrong Destination" (user is in the right place, just too much of it)
and "Incomplete Navigation" (about scroll position, not destination scope).

**Detection patterns:**
```swift
// Specific CTA → Generic wrapper (the AppleCare pattern)
// CTA says "Track AppleCare+" but opens EditItemSheetWrapper (full edit form)
.sheet(isPresented: $showingAppleCareEdit) {
    EditItemSheetWrapper(item: item)  // 🔴 5+ screens for a 1-screen task
}

// onItemSelected callback leads to broad wrapper instead of focused view
onItemSelected: { item in
    selectedItem = item
    showingFullEditForm = true  // Should open focused sub-form
}

// Sheet handler opens generic view for specific feature
case .specificFeature:
    GenericAllPurposeView(item: item)  // Should be FocusedFeatureView
```

**How to detect programmatically:**
1. Find CTA labels with specific verbs ("Track X", "Set Y", "Add Z", "Manage W")
2. Trace to the destination view
3. Count distinct sections/concerns in that destination
4. If CTA specificity = 1 concern but destination has 3+ unrelated sections → flag

**Real example (caught in v2.1.0):**
- CTA: "Track AppleCare+" (1 concern: extended warranty)
- Destination: `EditItemSheetWrapper` (5+ sections: title, photos, warranty, support, location...)
- Fix: `AppleCareDirectEditSheet` wrapping `ExtendedWarrantyFormView` directly

**Severity:** 🟠 HIGH (user confusion, broken trust in CTAs)

### Category 5: Two-Step Flows (Friction)
User must make intermediate selection before reaching feature.

**Detection patterns:**
```swift
// Item picker before feature
activeSheet = .aiPicker  // then shows AI view
activeSheet = .appleCareTracking  // then shows edit

// Confirmation before action
showingConfirmation = true  // then performs action
```

**Severity:** 🟡 MEDIUM (acceptable if necessary, flag for review)

### Category 6: Missing Feedback
Action completes without user confirmation.

**Detection patterns:**
```swift
// Save without toast
try modelContext.save()  // no ToastManager call

// Delete without confirmation
modelContext.delete(item)  // no confirmationDialog

// Navigation without indication
selectedSection = .xxx  // no loading/transition feedback
```

**Severity:** 🟡 MEDIUM

### Category 7: Inconsistent Patterns
Same feature accessed differently in different places.

**Detection patterns:**
```swift
// Feature A accessed via sheet in location 1
activeSheet = .featureA

// Same feature accessed via navigation in location 2
selectedSection = .featureASection
```

**Severity:** 🟢 LOW (but creates maintenance burden)

### Category 8: Orphaned Features
Views/features that exist but have no entry point.

**Detection patterns:**
```swift
// View defined but never instantiated
struct FeatureView: View  // grep shows no usage

// Sheet case defined but never assigned
case .orphanedSheet  // grep shows no `= .orphanedSheet`
```

**Severity:** 🟡 MEDIUM (wasted code or missing discovery)

### Category 9: Duplicate Code
Same logic implemented in multiple places.

**Severity:** 🟡 MEDIUM (maintenance burden)

### Category 10: Mock Data (Layer 5)
Feature displays hardcoded/fake data instead of real model data.

**Detection patterns:**
```swift
// asyncAfter with hardcoded data (fake fetch)
DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
    self.data = HardcodedResult(score: 7, cost: "$85")
}

// Static arrays pretending to be fetched results
let alternatives = [
    Alternative(name: "Product X", price: "$299")
]

// Placeholder AI (no real backend call)
isLoadingAI = true
asyncAfter { self.aiResult = StaticData() }
```

**Severity:** 🔴 CRITICAL (users see fictional data presented as real)

### Category 11: Unwired Data (Layer 5)
Model tracks data that a feature should use but doesn't.

**Detection patterns:**
```swift
// Decision logic ignoring available data
func computePath() -> DecisionPath {
    // Uses 2 of 10+ available properties
    if item.assetAge > lifespan { return .replace }
    return .keep
    // Ignores: repair costs, warranty, condition, market price
}

// Feature computes values that the model already provides
let estimatedCost = categoryBasedEstimate()  // but item.averageRepairCostInCents exists
```

**Severity:** 🟠 HIGH (feature is less useful than it should be)

### Category 12: Platform Parity Gap (Layer 5)
Feature works on one platform but breaks on another.

**Detection patterns:**
```swift
// iOS-only dismiss traps macOS users
#if os(iOS)
ToolbarItem(placement: .cancellationAction) {
    Button("Done") { dismiss() }
}
#endif

// Extension references wrapper computed property that breaks on macOS
// In Extension.swift:
FeatureSheet(items: computedProperty)  // "cannot find in scope" on macOS
```

**Severity:** 🟠 HIGH (entire feature broken on one platform)

## Detection Process

### Step 1: Entry Point Audit
For each entry point in Layer 1 inventory:
1. Identify action type (sheet, navigation, state change)
2. Trace to immediate destination
3. Check if destination matches user expectation

### Step 2: Destination Audit
For each destination view:
1. Count entry points that lead here
2. Flag if 0 entry points (orphaned)
3. Flag if inconsistent access patterns

### Step 3: Feedback Audit
For each action:
1. Check for success feedback (toast, banner, navigation)
2. Check for error handling
3. Check for loading states

### Step 4: Pattern Consistency Audit
Group similar features:
1. Compare access patterns
2. Flag inconsistencies
3. Identify best pattern to standardize on

## Output Schema

```yaml
issues:
  - id: "issue-001"
    category: "dead_end"
    severity: "critical"
    entry_point: "promo-repairAdvisor"
    expected: "Repair Advisor feature"
    actual: "Tools section (feature not there)"
    file: "DashboardView+PromotionCards.swift"
    line: 110
    recommendation: "Create DamagedItemsPickerSheet"

  - id: "issue-002"
    category: "incomplete_navigation"
    severity: "high"
    entry_point: "promo-priceWatch"
    expected: "Price Watch visible"
    actual: "Tools section top (must scroll)"
    file: "DashboardView+PromotionCards.swift"
    line: 78
    recommendation: "Use activeSheet = .priceWatch"
```

## Automated Checks

### Check 1: Sheet Case Coverage
```bash
# Find all DashboardSheetType cases
grep "case " DashboardModels.swift | grep -v "//"

# Find all sheetContent handlers
grep "case \." DashboardView+SheetContent.swift

# Compare - any cases without handlers?
```

### Check 2: Orphaned Views
```bash
# Find all View structs
grep -r "struct.*: View" Sources/ --include="*.swift"

# For each, check if it's instantiated somewhere
# Views only in Previews are likely orphaned
```

### Check 3: Promise-Scope Mismatch
```bash
# Find sheet presentations that use generic wrappers
# These are prime candidates for scope mismatch when the CTA is specific
grep -rn "EditItemSheetWrapper\|FullEditView\|SettingsView" Sources/ --include="*.swift" \
  | grep -i "sheet\|present"

# Find onItemSelected callbacks — trace what they open
grep -A5 "onItemSelected" Sources/ --include="*.swift" \
  | grep "showing\|activeSheet\|EditItem"

# Cross-reference: specific CTA labels vs destination view scope
# Look for labels with specific verbs that open broad wrappers
grep -B5 "EditItemSheetWrapper" Sources/ --include="*.swift" \
  | grep "Track\|Set\|Add\|Manage\|Configure"
```

### Check 4: Entry Point Coverage
```bash
# Find all sheet/navigation triggers
grep -r "activeSheet = \." Sources/
grep -r "selectedSection = \." Sources/

# Compare against feature list
# Any features without triggers?
```

## Integration with Layer 2

Layer 3 uses Layer 2 traces as examples but scales to all entry points:

| Layer 2 | Layer 3 |
|---------|---------|
| Deep trace of 3 flows | Shallow check of ~200 entry points |
| Manual investigation | Automated pattern matching |
| Detailed recommendations | Categorized issue list |
| 30-60 min per flow | 5-10 sec per entry point |

## Success Criteria

Layer 3 is complete when:
1. All entry points from Layer 1 have been checked
2. Issues are categorized by type and severity
3. Orphaned features are identified
4. Pattern inconsistencies are documented
5. Issue count by category is reported
6. Promise-scope mismatches identified (specific CTAs → generic destinations)
7. Mock data and placeholder AI identified (Layer 5 categories 10-12)
8. Model data coverage audited for key features
