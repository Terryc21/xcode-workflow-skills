# Layer 1: Pattern Discovery Summary

**Scan Date:** 2026-02-23
**Project:** Stuffolio v1.0

---

## Discovery Results

| Category | Count | Status |
|----------|-------|--------|
| Promotion Cards | 7 | ✅ Fully cataloged |
| Sheet Types | 29 | ✅ Fully cataloged |
| Context Menus | 12 files | ✅ Files identified |
| Swipe Actions | 9 files | ✅ Files identified |
| Navigation Links | 6 files | 🟡 Needs deeper scan |
| Toolbar Items | TBD | 🟡 Pattern needs refinement |
| Boolean Triggers | 155 files | ⚠️ Too broad - needs filtering |

**Total Entry Points:** ~200+ (estimated)

---

## Key Findings

### 1. Central Sheet Management (Good Pattern)
The app uses a centralized `DashboardSheetType` enum with 29 cases. This is a well-structured approach:
- Single point of truth for all sheets
- Easy to audit completeness
- Clear destination mapping in `sheetContent(for:)`

### 2. Promotion Cards with Incomplete Navigation (Issue Found)
Three promotion cards navigate to a section but don't deep-link to the feature:

| Card | Current Action | Expected |
|------|----------------|----------|
| Price Watch | `selectedSection = .tools` | Scroll to Price Watch |
| Repair Advisor | `selectedSection = .tools` | Scroll to Repair Advisor |
| Bulk Actions | `selectedSection = .myProducts` | Activate Select mode |

**Impact:** User taps card → lands on generic section → must find feature manually

### 3. Two-Step Flows (Potential UX Friction)
Two features require a picker before showing the main view:
- **AI Assistant**: Item picker → AI view
- **AppleCare Tracking**: Product list → Edit warranty

These are intentional but should be evaluated for:
- Clear instructions (✅ AppleCare has instructions now)
- Skip option when single item exists
- Return navigation clarity

### 4. High-Complexity Files
| File | Triggers | Concern |
|------|----------|---------|
| DashboardView.swift | 30+ sheets | Central hub - acceptable |
| EnhancedItemDetailView.swift | 15+ states | May need refactoring |

---

## Patterns Identified

### Effective Patterns
1. **Enum-based sheet management** - Scalable, type-safe
2. **Promotion cards with dismissal** - User can hide unwanted suggestions
3. **Conditional visibility** - Cards only appear when relevant

### Patterns Needing Attention
1. **Deep linking gap** - Section navigation without scrolling to target
2. **Boolean state explosion** - 155 files with `showing* = true` patterns
3. **Context menus inconsistency** - Different actions available in different contexts

---

## Layer 2 Investigation Queue

Priority order based on user impact:

1. **Promotion Card Deep Linking** (High)
   - Files: `DashboardView+PromotionCards.swift`
   - Fix: Add scroll target or direct sheet

2. **Select Mode Auto-Activation** (Medium)
   - Files: `MyProductsView.swift`, promotion cards
   - Fix: Pass activation flag through navigation

3. **Two-Step Flow Optimization** (Medium)
   - Files: AI picker, AppleCare tracking
   - Evaluate: Skip picker when single item exists?

4. **Context Menu Consistency** (Low)
   - Files: 12 files with context menus
   - Audit: Are the same actions available everywhere?

---

## Files for Layer 2 Analysis

### Must Read
- `Sources/Features/Dashboard/Views/DashboardView.swift`
- `Sources/Views/Tools/ToolsView.swift`
- `Sources/Views/Navigation/MyProductsView.swift`

### Should Read
- All 12 context menu files
- All 9 swipe action files

### Optional
- Boolean trigger files (filter for actual workflows)

---

## Output Artifacts

| File | Purpose |
|------|---------|
| `layer1-patterns.md` | Regex patterns for discovery |
| `layer1-inventory.yaml` | Structured entry point catalog |
| `layer1-summary.md` | This summary |

---

## Next: Layer 2 (Flow Tracing)

Layer 2 will:
1. Start from flagged entry points
2. Trace user journey to completion
3. Identify dead ends, missing feedback, confusion points
4. Map expected vs actual behavior
