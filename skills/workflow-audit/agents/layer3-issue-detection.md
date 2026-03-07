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

### Category 13: Buried Primary Action
Primary action button (Save, Continue, Done, Submit) placed inside a ScrollView after
tall content, making it invisible without scrolling. Users see only "Cancel" and feel trapped.

**Detection patterns:**
```swift
// ❌ Primary action buried below tall content in ScrollView
ScrollView {
    VStack {
        headerSection          // tall
        comparisonSection      // tall
        optionCards            // 4+ tall cards
        sourcePickerContent    // 5-7 tall cards

        // Primary action buried off-screen:
        Button("Continue") { ... }
            .buttonStyle(.borderedProminent)
    }
}

// ❌ .borderedProminent or .controlSize(.large) button as last child
//    in ScrollView with 4+ tall elements above it
```

**Safe patterns (do NOT flag):**
```swift
// ✅ Button pinned OUTSIDE ScrollView (WhatsNewSheet pattern)
VStack(spacing: 0) {
    ScrollView { content }
    Divider()
    actionButtons.padding()  // pinned below scroll
}

// ✅ Button in .toolbar
.toolbar {
    ToolbarItem(placement: .confirmationAction) {
        Button("Done") { ... }
    }
}

// ✅ Standard Form sections (each section has own scroll)
Form {
    Section { ... }
    Section { Button("Save") { ... } }
}

// ✅ Bottom action bar outside ScrollView
VStack(spacing: 0) {
    ScrollView { photoGrid }
    bottomActionBar  // separate view pinned below
}
```

**How to detect programmatically:**
1. Find files containing both `ScrollView` and `.borderedProminent` or `.controlSize(.large)`
2. Check if the button is the LAST child inside the ScrollView's VStack
3. Count tall elements above the button (sections, cards, option rows)
4. If 4+ tall elements above and button is last child → flag
5. Exclude: buttons in `.toolbar`, buttons outside ScrollView, Form-based layouts

**Real examples (caught in Stuffolio v1.0):**
- `UnifiedPhotoFlow.swift`: "Continue with AI Analysis" buried below 5-7 source picker cards
  - Beta tester reported being unable to find their way forward
  - Fix: Moved Continue button immediately after photo thumbnails
- `ConflictResolutionView.swift`: "Resolve Conflict" buried below comparison + 4 option cards
  - Fix: Pinned action buttons outside ScrollView with Divider

**Severity:** 🟡 HIGH (user feels trapped, only sees Cancel)

### Category 14: Dismiss Trap
A view where the only visible action is Cancel/Dismiss/back with no forward path shown.
The user completed a step (e.g., selected a photo, filled a form) but cannot see how to proceed.
Related to but distinct from Buried Primary Action — here the forward action may not exist at all,
or it may be conditionally hidden.

**Detection patterns:**
```swift
// ❌ Only toolbar action is cancel, no Done/Save/Continue visible
.toolbar {
    ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") { dismiss() }
    }
    // No .confirmationAction or .primaryAction
}

// ❌ Forward button conditionally hidden — user doesn't know why
if viewModel.isValid {  // condition not obvious to user
    Button("Save") { ... }
}

// ❌ Sheet with no forward action in body or toolbar
NavigationStack {
    content
    .toolbar {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
    }
    // No save/done/continue anywhere
}
```

**Safe patterns (do NOT flag):**
```swift
// ✅ Cancel + Done/Save in toolbar
.toolbar {
    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { ... } }
    ToolbarItem(placement: .confirmationAction) { Button("Done") { ... } }
}

// ✅ Cancel in toolbar + primary action in body (visible without scroll)
.toolbar { ToolbarItem(placement: .cancellationAction) { ... } }
// Body has visible .borderedProminent button

// ✅ Read-only/info sheets (dismiss is the only expected action)
// e.g., HelpView, WhatsNewSheet, about screens
```

**How to detect programmatically:**
1. Find views with `.toolbar` containing only `.cancellationAction`
2. Check if the view body contains any `.borderedProminent`, `.confirmationAction`, or explicit "Save"/"Done"/"Continue" buttons
3. If no forward action found → flag as dismiss trap
4. Exclude: read-only views (help, about, info, what's new), confirmation dialogs

**Severity:** 🟡 HIGH (user feels stuck after completing a step)

### Category 15: Gesture-Only Action
Feature or action accessible only via gesture (swipe, long-press, context menu) with no
visible button or menu alternative. Users who don't discover the gesture cannot access the feature.

**Detection patterns:**
```swift
// ❌ Action only in swipeActions, no button equivalent
.swipeActions(edge: .trailing) {
    Button("Archive") { archiveItem() }
}
// No "Archive" button or menu item elsewhere in the view

// ❌ Feature only in contextMenu
.contextMenu {
    Button("Duplicate") { duplicateItem() }
    Button("Move to...") { showMovePicker() }
}
// No toolbar menu, no action sheet, no visible button for these

// ❌ Drag-to-reorder is only way to sort
// No "Sort" button or menu alternative
```

**Safe patterns (do NOT flag):**
```swift
// ✅ Swipe action + toolbar/menu equivalent
.swipeActions { Button("Delete") { ... } }
.toolbar {
    ToolbarItem { Menu { Button("Delete") { ... } } }
}

// ✅ Context menu with visible primary action button
Button("Edit") { editItem() }  // visible button
.contextMenu {
    Button("Edit") { editItem() }       // gesture shortcut
    Button("Duplicate") { duplicate() } // additional convenience
}

// ✅ Standard list delete (swipe-to-delete with .onDelete)
// This is a well-known iOS convention, acceptable as gesture-only
```

**How to detect programmatically:**
1. Find `.swipeActions` and `.contextMenu` usage
2. Extract action labels/names from gesture blocks
3. Search the same view for visible button equivalents with matching action
4. If an action exists ONLY in gesture blocks → flag
5. Exclude: `.onDelete` (standard iOS pattern), supplementary convenience actions

**Severity:** 🟢 MEDIUM (feature is undiscoverable for some users)

### Category 16: Loading State Trap
A view shows a loading indicator (ProgressView, spinner, "Loading...") with no way for
the user to cancel, go back, or timeout. If the operation hangs, the user is trapped.

**Detection patterns:**
```swift
// ❌ ProgressView with dismiss disabled and no cancel
.interactiveDismissDisabled(isLoading)
// No cancel button, no timeout

// ❌ Full-screen loading overlay with no escape
if isLoading {
    ZStack {
        Color.black.opacity(0.4)
        ProgressView("Loading...")
    }
    .ignoresSafeArea()
    // No cancel button, no timeout
}

// ❌ Async operation with no timeout or cancellation
func loadData() async {
    isLoading = true
    let result = await slowNetworkCall()  // could hang forever
    isLoading = false
    // No Task cancellation, no timeout
}
```

**Safe patterns (do NOT flag):**
```swift
// ✅ Loading with cancel button
if isLoading {
    VStack {
        ProgressView()
        Button("Cancel") { task?.cancel(); isLoading = false }
    }
}

// ✅ Loading with timeout
Task {
    isLoading = true
    let result = try await withTimeout(seconds: 30) { await fetch() }
    isLoading = false
}

// ✅ Loading that doesn't block interaction (inline indicator)
HStack {
    Text(item.title)
    if item.isSyncing { ProgressView().controlSize(.small) }
}

// ✅ Brief loading (< 2 sec typical) for local operations
// e.g., saving to SwiftData, generating thumbnail
```

**How to detect programmatically:**
1. Find `ProgressView` usage paired with `.interactiveDismissDisabled(true)` or full-screen overlays
2. Check if a cancel/back button is available during the loading state
3. Check if the async operation has a timeout or cancellation mechanism
4. If loading blocks interaction AND no cancel AND no timeout → flag
5. Exclude: inline progress indicators, brief local operations, determinate progress bars

**Severity:** 🟢 MEDIUM (user trapped if operation hangs; rare but frustrating)

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

### Check 5: Buried Primary Action
```bash
# Step 1: Find files with primary action buttons
grep -rn "\.borderedProminent\|\.controlSize(.large)" Sources/ --include="*.swift" \
  | cut -d: -f1 | sort -u > /tmp/primary_buttons.txt

# Step 2: Find files with ScrollView
grep -rn "ScrollView" Sources/ --include="*.swift" \
  | cut -d: -f1 | sort -u > /tmp/scrollviews.txt

# Step 3: Cross-reference — files with BOTH are candidates
comm -12 /tmp/primary_buttons.txt /tmp/scrollviews.txt

# Step 4: For each candidate, manually check:
# - Is the button INSIDE the ScrollView? (not pinned outside)
# - Is it the last child of a VStack inside ScrollView?
# - Are there 4+ tall elements (sections, cards, option rows) above it?
# - Exclude: .toolbar buttons, Form sections, bottom action bars
```

### Check 6: Dismiss Traps
```bash
# Step 1: Find views with only cancellationAction in toolbar
grep -rn "cancellationAction" Sources/ --include="*.swift" \
  | cut -d: -f1 | sort -u > /tmp/cancel_views.txt

# Step 2: Find views with confirmationAction or primaryAction
grep -rn "confirmationAction\|primaryAction" Sources/ --include="*.swift" \
  | cut -d: -f1 | sort -u > /tmp/forward_views.txt

# Step 3: Files with cancel but no forward action in toolbar
comm -23 /tmp/cancel_views.txt /tmp/forward_views.txt

# Step 4: For each candidate, check if body has visible .borderedProminent button
# Exclude: HelpView, WhatsNewSheet, info/about views
```

### Check 7: Gesture-Only Actions
```bash
# Step 1: Find swipeActions and contextMenu usage
grep -rn "\.swipeActions\|\.contextMenu" Sources/ --include="*.swift"

# Step 2: For each file with gesture actions, extract action labels
grep -A10 "\.swipeActions\|\.contextMenu" Sources/ --include="*.swift" \
  | grep "Button("

# Step 3: Check if those same action labels appear as visible buttons
# in the same view (outside gesture blocks)
```

### Check 8: Loading State Traps
```bash
# Step 1: Find ProgressView paired with interactiveDismissDisabled
grep -rn "interactiveDismissDisabled" Sources/ --include="*.swift"

# Step 2: Find full-screen loading overlays
grep -B5 -A5 "ProgressView" Sources/ --include="*.swift" \
  | grep -l "ignoresSafeArea\|ZStack"

# Step 3: For each, check if cancel button exists during loading state
# Check if async operation has timeout/cancellation
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
9. Buried primary actions identified (ScrollView buttons requiring scroll to discover)
10. Dismiss traps identified (views with only Cancel and no forward path)
11. Gesture-only actions identified (features only in swipe/context menu)
12. Loading state traps identified (blocking spinners with no cancel/timeout)
