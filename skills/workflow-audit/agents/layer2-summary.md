# Layer 2: Flow Tracing Summary

**Scan Date:** 2026-02-23
**Project:** Stuffolio v1.0

---

## Executive Summary

**3 workflows traced, 3 issues found:**

| Flow | Entry Point | Severity | Issue |
|------|-------------|----------|-------|
| flow-001 | Price Watch card | 🟠 HIGH | Incomplete navigation - lands on Tools, must scroll |
| flow-002 | Repair Advisor card | 🔴 CRITICAL | Wrong destination - links to Tools, feature is elsewhere |
| flow-003 | Bulk Actions card | 🟠 HIGH | Missing auto-activation - Select mode not enabled |

---

## Critical Finding: Repair Advisor Dead End

The "Repair Advisor" promotion card is **completely broken**:

- **Card says:** "Repair Advisor - get repair guidance"
- **Card links to:** Tools section
- **Feature actually lives:** Item Detail → "Repair, Keep, or Replace?"
- **User experience:** Taps card → lands on Tools → cannot find feature → confusion

**Root Cause:** The feature requires an item to be selected first. The card should show a damaged items picker (like AppleCare+ tracking now does).

**Recommended Fix:** Follow the AppleCare+ pattern - create `DamagedItemsPickerSheet` that lists damaged items and opens `RepairKeepReplaceView` for the selected item.

---

## Pattern Analysis

### Issue Pattern: Navigation-Only Cards

Three promotion cards use `selectedSection = .xxx` which only navigates to a section:

```swift
// Current pattern (problematic)
action: { selectedSection = .tools }
action: { selectedSection = .myProducts }
```

**Problems:**
1. User lands at top of section, not at feature
2. No deep linking, no scroll targets
3. Features requiring item context have no way to get it

### Better Pattern: Sheet-Based Cards

Four promotion cards use `activeSheet = .xxx` which works correctly:

```swift
// Working pattern
action: { activeSheet = .stuffScout }
action: { activeSheet = .quickFind }
action: { activeSheet = .appleCareTracking }  // ← just fixed
```

**Benefits:**
1. Immediate access to feature
2. Feature gets focus, no scrolling needed
3. Clear entry → action → exit flow

---

## Recommendations by Priority

### Immediate (Pre-Release)

| Issue | Fix | Effort |
|-------|-----|--------|
| Repair Advisor dead end | Create DamagedItemsPickerSheet | 2-3 hours |
| Price Watch scrolling | Change to `activeSheet = .priceWatch` | 5 minutes |
| Bulk Actions no activation | Change to `activeSheet = .bulkEdit` | 5 minutes |

### Quick Wins

**Bulk Actions card (5 minutes):**
```swift
// DashboardView+PromotionCards.swift:126
// FROM:
action: { selectedSection = .myProducts }

// TO:
action: { activeSheet = .bulkEdit }  // ✅ Already exists in DashboardSheetType
```

**Price Watch card (15-20 minutes):**
```swift
// Step 1: Add case to DashboardModels.swift
case priceWatch  // Add after line 30

// Step 2: Add handler to DashboardView+SheetContent.swift
case .priceWatch:
    PriceWatchView()

// Step 3: Update promotion card action
// DashboardView+PromotionCards.swift:78
action: { activeSheet = .priceWatch }
```

Note: `priceWatch` case does NOT exist yet in DashboardSheetType - must be added.

### Medium Effort (2-3 Hours)

**Repair Advisor card - Create item picker flow:**

1. Create `DamagedItemsPickerSheet.swift` (copy from AppleCareTrackingSheet)
2. Add `case damagedItemsPicker` to `DashboardSheetType`
3. Add sheet content handler in `DashboardView+SheetContent.swift`
4. Update card action: `action: { activeSheet = .damagedItemsPicker }`
5. On item selection, open `RepairKeepReplaceView`

---

## Flow Trace Files

| File | Flow |
|------|------|
| `layer2-traces/flow-001-pricewatch.yaml` | Price Watch card → Tools |
| `layer2-traces/flow-002-repairadvisor.yaml` | Repair Advisor → Dead end |
| `layer2-traces/flow-003-bulkactions.yaml` | Bulk Actions → My Products |

---

## Metrics

| Metric | Value |
|--------|-------|
| Flows traced | 3 |
| Critical issues | 1 |
| High issues | 2 |
| Quick fixes available | 2 |
| Features requiring item picker | 2 (AppleCare ✅, Repair Advisor ❌) |

---

## Next Steps

1. **Fix Price Watch card** - 5 min (verify sheet type exists)
2. **Fix Bulk Actions card** - 5 min
3. **Fix Repair Advisor card** - 2-3 hours (create picker sheet)
4. **Continue Layer 2** - Trace two-step flows (AI Assistant, AppleCare)
5. **Layer 3** - Issue detection across all entry points
