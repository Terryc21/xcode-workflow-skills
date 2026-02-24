# Layer 2: Flow Tracing Methodology

## Purpose

Layer 2 takes entry points from Layer 1 and traces the complete user journey:
- What happens when the user taps?
- Where do they land?
- Can they complete their goal?
- What feedback do they receive?

## Tracing Process

### Step 1: Identify Entry Point
From Layer 1 inventory, select an entry point to trace.

### Step 2: Follow the Code Path
```
Entry Point → Action → Destination → User Goal
```

For each step, document:
- File and line number
- State changes
- View transitions
- Feedback shown

### Step 3: Promise Check (CTA-to-Destination Scope)

Compare the CTA label's specificity against the destination view's scope:

| CTA Specificity | Destination Scope | Verdict |
|----------------|-------------------|---------|
| Specific ("Track AppleCare+") | Focused (ExtendedWarrantyForm) | ✅ Match |
| Specific ("Track AppleCare+") | Broad (EditItemSheetWrapper) | 🔴 Mismatch |
| General ("Edit Product") | Broad (EditItemSheetWrapper) | ✅ Match |
| General ("Settings") | Focused (NotificationSettings) | ⚠️ Over-specific |

**How to assess:**
1. Count concerns in the CTA label (1 = specific, 2+ = general)
2. Count distinct sections in the destination view
3. If CTA concerns = 1 but destination sections >= 3 → **Promise-Scope Mismatch**

**Real example caught:** "Track AppleCare+" (1 concern) → `EditItemSheetWrapper` (5+ sections)
**Fix:** Create `AppleCareDirectEditSheet` wrapping only `ExtendedWarrantyFormView`

### Step 4: Map Expected vs Actual

| Aspect | Expected | Actual | Gap? |
|--------|----------|--------|------|
| Landing | Feature visible | Section landing | ⚠️ |
| Scope | Focused on CTA promise | Broad/generic | ⚠️ |
| Feedback | Success toast | None | ⚠️ |
| Next step | Clear CTA | Ambiguous | ⚠️ |

### Step 5: Classify Issue Severity

| Severity | Description | Example |
|----------|-------------|---------|
| 🔴 Critical | User cannot complete goal | Dead end, crash |
| 🟠 High | User confused, extra steps | Wrong landing, no feedback |
| 🟡 Medium | Friction but completable | Slow path, redundant steps |
| 🟢 Low | Minor polish | Inconsistent wording |

## Flow Documentation Template

```yaml
flow_trace:
  id: "flow-001"
  name: "Price Watch from Dashboard"
  entry_point: "promo-priceWatch"

  steps:
    - step: 1
      action: "User taps Price Watch promotion card"
      file: "DashboardView+PromotionCards.swift:78"
      code: "selectedSection = .tools"

    - step: 2
      action: "App navigates to Tools section"
      file: "AppNavigationView.swift"
      result: "ToolsView displayed"

    - step: 3
      action: "User must scroll to find Price Watch"
      issue: "No auto-scroll to feature"
      severity: "high"

  expected_journey:
    - "Tap card"
    - "See Price Watch immediately"
    - "Start tracking prices"

  actual_journey:
    - "Tap card"
    - "Land on Tools section top"
    - "Scroll through other tools"
    - "Find Price Watch"
    - "Start tracking prices"

  gap_analysis:
    type: "incomplete_navigation"
    extra_steps: 2
    user_confusion_risk: "medium"

  recommendation:
    option_a: "Deep link to Price Watch section"
    option_b: "Show Price Watch as sheet instead"
    preferred: "option_b"
```

## Priority Queue (from Layer 1)

| Priority | Entry Point | Issue Type |
|----------|-------------|------------|
| 1 | promo-priceWatch | Incomplete navigation |
| 2 | promo-repairAdvisor | Incomplete navigation |
| 3 | promo-bulkOperations | Missing auto-activation |
| 4 | aiAssistant | Two-step flow |
| 5 | appleCareTracking | Two-step flow |

## Output Artifacts

- `layer2-traces/flow-XXX.yaml` - Individual flow traces
- `layer2-summary.md` - Aggregated findings
