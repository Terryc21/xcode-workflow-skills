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

### Category 17: Context Dropping
Navigation path has item/context available at the source but drops it before reaching
the destination. The destination supports receiving context (has a contextual initializer)
but gets the parameterless version instead.

Different from "Promise-Scope Mismatch" (destination is correct but too broad) and
"Platform Parity Gap" (entire feature broken). Context Dropping means the right destination
is opened but without the context the user expects to carry through.

**Detection patterns:**
```swift
// ❌ Platform parity: iOS passes context, macOS notification drops it
// iOS path:
.sheet(isPresented: $showFeature) {
    FeatureView(item: item, existingData: data, itemID: item.persistentModelID)
}
// macOS path:
let context: [String: Any] = [
    "item": item.title,
    "existingData": data
    // ❌ Missing "itemID" — iOS passes it, macOS doesn't
]
NotificationCenter.default.post(name: .navigateToFeature, userInfo: context)

// ❌ Navigation context struct missing fields the destination accepts
struct FeatureNavigationContext {
    let name: String
    let data: [Data]
    // ❌ Missing: itemID that FeatureView accepts as optional param
}

// ❌ Button has item in scope but destination gets no parameters
Button("Scout This Item") {
    showStuffScout = true  // opens StuffScoutView() with no item context
}
// When StuffScoutView(productName:existingImages:) exists

// ❌ Notification sender omits fields that receiver can parse
// Sender builds dict with 4 keys, receiver struct has 5 properties
```

**Safe patterns (do NOT flag):**
```swift
// ✅ All destination parameters passed on all platforms
// iOS sheet and macOS notification both include the same fields

// ✅ Parameterless init is intentional (fresh/empty state)
Button("New Scout") {
    showStuffScout = true  // intentionally opens fresh scan
}

// ✅ Context struct matches notification sender 1:1
```

**How to detect programmatically:**
1. Find views with platform-split presentation (`#if os(iOS) .sheet` / `#else .onChange`)
2. Compare parameters passed in each platform path
3. Find `NavigationContext` structs and compare their properties with the destination view's init parameters
4. Find buttons that set a `show*` flag where the destination view has both parameterless and contextual inits — check which is used
5. For NotificationCenter patterns: compare `userInfo` dictionary keys with the context struct's `init?(from:)` parsing

**Real example (caught in Stuffolio v1.0):**
- Source: AI Product Assistant "Stuff Scout" button (item in scope)
- iOS: passes `existingItemID: item.persistentModelID` to StuffScoutView
- macOS: notification `userInfo` omitted `existingItemID`
- `StuffScoutNavigationContext` struct had no `existingItemID` property
- Result: macOS Stuff Scout opened without item tracking, couldn't link results back to item
- Fix: Added `existingItemID` to notification dict, context struct, and destination init call

**Severity:** 🟡 HIGH (user loses context they expect to carry through; may cause data loss or broken feature)

### Category 18: Notification Navigation Fragility
Navigation between views uses `NotificationCenter` with untyped `[String: Any]` dictionaries
instead of typed function calls, bindings, or environment values. Any key typo, type mismatch,
or omitted field is silent at compile time and only manifests as a runtime bug.

This is a **root cause pattern** — it enables Context Dropping (Category 17) and Platform
Parity Gaps (Category 12). Flagging it proactively prevents those downstream issues.

**Detection patterns:**
```swift
// ❌ Untyped dictionary for navigation context
let context: [String: Any] = [
    "productName": item.title,
    "manufacturer": item.manufacturer as Any,  // as Any = type erasure
    "category": item.productCategory?.label as Any
]
NotificationCenter.default.post(name: .navigateToFeature, userInfo: context)

// ❌ Receiver parses with string keys — typo = silent nil
init?(from userInfo: [AnyHashable: Any]?) {
    guard let info = userInfo,
          let name = info["productName"] as? String else { return nil }
    // "produtName" typo would silently return nil
}

// ❌ Adding a new field requires updating sender AND receiver in sync
// No compiler enforcement that they match
```

**Safe patterns (do NOT flag):**
```swift
// ✅ Typed callback/closure
let onNavigateToScout: (Item, [Data]) -> Void

// ✅ Environment-based navigation
@Environment(\.navigateToScout) var navigateToScout

// ✅ Binding-based state change
@Binding var selectedSection: AppSection

// ✅ Notification used for non-navigation purposes (sync events, refresh triggers)
NotificationCenter.default.post(name: .dataDidSync, object: nil)
```

**How to detect programmatically:**
1. Find all `NotificationCenter.default.post` calls with `userInfo` that isn't nil
2. Check if the notification name contains navigation-related keywords (navigate, show, open, present)
3. Find the corresponding receiver (`.onReceive` or `publisher(for:)`)
4. Flag as fragility risk — recommend typed alternative

**Severity:** 🟡 HIGH (silent bugs, no compiler safety, enables downstream issues)

### Category 19: Sheet Presentation Asymmetry
Same feature uses fundamentally different presentation mechanisms on different platforms —
e.g., iOS uses `.sheet` with direct view init, macOS uses NotificationCenter → navigation.
The two paths are maintained independently and drift apart over time.

Different from "Platform Parity Gap" (feature broken on one platform) — here both platforms
work, but the different mechanisms create a maintenance burden and context-dropping risk.

**Detection patterns:**
```swift
// ❌ Completely different presentation mechanisms per platform
#if os(iOS)
.sheet(isPresented: $showFeature) {
    FeatureView(param1: a, param2: b, param3: c)
}
#else
.onChange(of: showFeature) { _, new in
    if new {
        NotificationCenter.default.post(name: .navigate, userInfo: [...])
        dismiss()
    }
}
#endif

// ❌ iOS uses sheet, macOS uses inline navigation
// Parameters must be maintained in two completely different formats:
// iOS: direct init params
// macOS: [String: Any] dict → context struct → init params
```

**Safe patterns (do NOT flag):**
```swift
// ✅ Same mechanism, minor platform differences
.sheet(isPresented: $showFeature) {
    FeatureView(item: item)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
}

// ✅ Platform-specific STYLING, not mechanism
#if os(iOS)
.sheet(isPresented: $show) { FeatureView(item: item) }
#else
.sheet(isPresented: $show) { FeatureView(item: item).frame(width: 500) }
#endif
```

**How to detect programmatically:**
1. Find `#if os(iOS)` blocks that contain `.sheet` or `.fullScreenCover`
2. Check if the `#else` block uses a different mechanism (notification, navigation, binding)
3. If the presentation mechanism differs fundamentally → flag
4. Compare parameter counts between the two paths

**Real example (Stuffolio v1.0):**
- AI Product Assistant "Stuff Scout" button
- iOS: `.sheet { StuffScoutView(productName:manufacturer:category:existingImages:existingItemID:) }` — 5 params
- macOS: `NotificationCenter.post(userInfo: [...])` → context struct → init — started with 4 params, missed `existingItemID`
- The asymmetry caused Context Dropping on macOS

**Severity:** 🟡 HIGH (maintenance burden, drift risk, enables context dropping)

### Category 20: Stale Navigation Context
A view stores navigation context in `@State` for later use, but the context can become
stale — the source item could be deleted, modified, or the context may never be cleared.

**Detection patterns:**
```swift
// ❌ Cached context with no clearing mechanism
@State private var featureContext: FeatureNavigationContext?
// Never set to nil after use or on disappear

// ❌ Context cached but source item can be deleted
@State private var stuffScoutContext: StuffScoutNavigationContext?
// If the user deletes the item while Scout is open, context points to deleted item

// ❌ Context persists across navigation changes
// User navigates away and back — stale context from previous visit is reused
selectedSection = .stuffScout  // uses old stuffScoutContext

// ❌ Context set in onReceive but only cleared in onDisappear
// If notification fires twice, second context overwrites first silently
.onReceive(notification) { stuffScoutContext = parse($0) }
```

**Safe patterns (do NOT flag):**
```swift
// ✅ Context cleared after use
.onDisappear { featureContext = nil }

// ✅ Context cleared when navigating away
.onChange(of: selectedSection) { _, new in
    if new != .stuffScout { stuffScoutContext = nil }
}

// ✅ Context is a computed property (always fresh)
var featureContext: FeatureContext? {
    guard let item = selectedItem else { return nil }
    return FeatureContext(item: item)
}

// ✅ Context validated before use
if let context = stuffScoutContext, modelContext.model(for: context.itemID) != nil {
    FeatureView(context: context)
}
```

**How to detect programmatically:**
1. Find `@State` properties with `Context`, `NavigationContext`, or `Info` in the type name
2. Check if the property is set to nil somewhere (`.onDisappear`, `.onChange`, explicit reset)
3. If no clearing mechanism exists → flag as stale context risk
4. Check if the context references a `PersistentIdentifier` or model ID without validating it still exists

**Severity:** 🟢 MEDIUM (edge case but can cause crashes or stale data display)

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

### Check 9: Context Dropping
```bash
# Step 1: Find platform-split presentations (iOS sheet vs macOS notification)
grep -rn "#if os(iOS)" Sources/ --include="*.swift" \
  | xargs -I{} grep -l "\.sheet\|\.fullScreenCover" {} 2>/dev/null

# Step 2: For each, find the macOS #else block and compare parameters
# Look for NotificationCenter.post with userInfo dict
grep -B2 -A15 "NotificationCenter.default.post" Sources/ --include="*.swift" \
  | grep -E "userInfo|let context"

# Step 3: Find NavigationContext structs and list their properties
grep -rn "NavigationContext\|NavigationInfo" Sources/ --include="*.swift"

# Step 4: Compare context struct properties with destination view init params
# Find views that accept both parameterless and contextual inits
grep -rn "init(productName\|init(item\|init(context" Sources/ --include="*.swift"

# Step 5: Find show* flags set from item-context closures where destination
# uses parameterless init
grep -B10 "show.*= true" Sources/ --include="*.swift" \
  | grep -E "item\.|onItemSelected"
```

### Check 10: Notification Navigation Fragility
```bash
# Step 1: Find NotificationCenter posts with userInfo (navigation-related)
grep -rn "NotificationCenter.default.post" Sources/ --include="*.swift" \
  | grep -v "object: nil)" \
  | grep -i "userInfo"

# Step 2: Find the notification names used for navigation
grep -rn "\.requestNavigate\|\.navigateTo\|\.showFeature\|\.openSection" Sources/ --include="*.swift"

# Step 3: Find corresponding receivers
grep -rn "\.onReceive\|publisher(for:" Sources/ --include="*.swift" \
  | grep -i "navigate\|show\|open"

# Step 4: For each sender/receiver pair, compare:
# - Number of keys in sender's userInfo dict
# - Number of properties parsed in receiver's init/handler
# - Any string key used in sender that doesn't appear in receiver (or vice versa)
```

### Check 11: Sheet Presentation Asymmetry
```bash
# Step 1: Find files with platform-conditional sheet presentations
grep -rn "#if os(iOS)" Sources/ --include="*.swift" \
  | cut -d: -f1 | sort -u > /tmp/platform_split.txt

# Step 2: For each, check if iOS uses .sheet and macOS uses a different mechanism
for f in $(cat /tmp/platform_split.txt); do
  ios_sheet=$(grep -c "\.sheet\|\.fullScreenCover" "$f" 2>/dev/null || echo 0)
  notification=$(grep -c "NotificationCenter.default.post" "$f" 2>/dev/null || echo 0)
  if [ "$ios_sheet" -gt 0 ] && [ "$notification" -gt 0 ]; then
    echo "ASYMMETRY: $f (iOS sheet + macOS notification)"
  fi
done

# Step 3: For asymmetric files, count parameters in each path
# iOS: count arguments in View init call inside .sheet { }
# macOS: count keys in userInfo dictionary
```

### Check 12: Stale Navigation Context
```bash
# Step 1: Find @State properties with Context/Info types
grep -rn "@State.*private.*var.*[Cc]ontext\|@State.*private.*var.*[Ii]nfo\|@State.*private.*var.*[Nn]avigation" \
  Sources/ --include="*.swift"

# Step 2: For each, check if it's ever set to nil
# Extract variable name, then search for "varName = nil"
grep -rn "@State.*private.*var.*Context" Sources/ --include="*.swift" \
  | while IFS=: read -r file line content; do
    varname=$(echo "$content" | sed 's/.*var \([a-zA-Z]*\).*/\1/')
    has_clear=$(grep -c "$varname = nil" "$file" 2>/dev/null || echo 0)
    if [ "$has_clear" -eq 0 ]; then
      echo "STALE RISK: $file:$line — $varname never set to nil"
    fi
  done

# Step 3: Check if context references PersistentIdentifier without validation
grep -rn "PersistentIdentifier" Sources/ --include="*.swift" \
  | grep -i "context\|navigation"
```

## Regression Canaries

After fixing a workflow issue, generate a "canary" — a specific check that detects if the
issue recurs. Canaries are stored in `.workflow-audit/canaries.yaml` and can be run as a
quick regression check before release.

### Canary Format

```yaml
canaries:
  - id: "canary-001"
    issue_ref: "issue-017"  # original issue ID
    description: "StuffScoutNavigationContext must include existingItemID"
    check_type: "grep_match"
    file: "Sources/Views/Navigation/AppNavigationView.swift"
    pattern: "existingItemID.*PersistentIdentifier"
    expect: "match"  # fail if pattern NOT found
    added: "2026-03-08"

  - id: "canary-002"
    issue_ref: "issue-017"
    description: "macOS notification must include existingItemID key"
    check_type: "grep_match"
    file: "Sources/AI_Backend/AIProductAssistantView.swift"
    pattern: "existingItemID.*persistentModelID"
    expect: "match"
    added: "2026-03-08"

  - id: "canary-003"
    issue_ref: "issue-013"
    description: "Continue button must appear before sourcePickerContent in UnifiedPhotoFlow"
    check_type: "line_order"
    file: "Sources/Features/ItemManagement/Views/UnifiedPhotoFlow.swift"
    first_pattern: "Continue with AI Analysis"
    second_pattern: "sourcePickerContent"
    expect: "first_before_second"
    added: "2026-03-08"
```

### Canary Check Types

| Type | Description | Pass condition |
|------|-------------|----------------|
| `grep_match` | Pattern must exist in file | Pattern found |
| `grep_absent` | Pattern must NOT exist in file | Pattern not found |
| `line_order` | Two patterns must appear in specific order | First before second |
| `param_count` | Count params in a function/dict | Count matches expected |
| `platform_parity` | Same pattern must exist in both iOS and macOS blocks | Found in both |

### Running Canaries

```bash
# Quick canary check — run all canaries against current source
# Each canary is a simple grep/awk check that takes <1 second

for canary in $(yq '.canaries[].id' .workflow-audit/canaries.yaml); do
  file=$(yq ".canaries[] | select(.id == \"$canary\") | .file" .workflow-audit/canaries.yaml)
  pattern=$(yq ".canaries[] | select(.id == \"$canary\") | .pattern" .workflow-audit/canaries.yaml)
  expect=$(yq ".canaries[] | select(.id == \"$canary\") | .expect" .workflow-audit/canaries.yaml)

  if [ "$expect" = "match" ]; then
    grep -q "$pattern" "$file" && echo "✅ $canary" || echo "❌ $canary REGRESSION"
  elif [ "$expect" = "absent" ]; then
    grep -q "$pattern" "$file" && echo "❌ $canary REGRESSION" || echo "✅ $canary"
  fi
done
```

### When to Generate Canaries

The workflow-audit `fix` command should automatically generate a canary for each fix:

1. After fixing a Context Dropping issue → canary verifying the field exists in both paths
2. After fixing a Buried Primary Action → canary verifying button order
3. After fixing a Platform Parity Gap → canary verifying pattern exists on both platforms
4. After fixing a Dismiss Trap → canary verifying forward action exists

Canaries are **additive** — they accumulate over time and form a regression safety net.

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
13. Context dropping identified (navigation paths that lose item/context between platforms or via notifications)
14. Notification navigation fragility flagged (untyped NotificationCenter used for navigation)
15. Sheet presentation asymmetry flagged (different mechanisms per platform for same feature)
16. Stale navigation context identified (cached context with no clearing mechanism)
17. Regression canaries generated for each fix (stored in `.workflow-audit/canaries.yaml`)
