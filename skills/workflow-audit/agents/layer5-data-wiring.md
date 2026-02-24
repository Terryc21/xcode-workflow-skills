# Layer 5: Data Wiring Audit

## Purpose

Layer 5 verifies that features use **real user data** instead of mock/hardcoded values, and that model capabilities are fully wired into the features that need them. While Layers 1-4 audit navigation and UX, Layer 5 audits whether the data flowing through those workflows is genuine.

## Why This Layer Exists

A feature can pass all navigation audits (correct entry point, proper sheet handling, good feedback) and still be useless if it shows fabricated data. The Repair/Keep/Replace feature was the canonical example: well-architected UI, correct navigation, but the decision engine used a 4-rule if/else chain ignoring repair costs, warranty data, and Price Watch prices that the app already tracked.

**The symptom:** Feature looks functional. User makes decisions based on it. Data is fake.

## What Layer 5 Catches

| Issue Type | Example | Severity |
|------------|---------|----------|
| **Mock Data** | `asyncAfter` delay + hardcoded values simulating a fetch | 🔴 Critical |
| **Unwired Data** | Item has `rmaRecords` with repair costs, but decision engine ignores them | 🟠 High |
| **Placeholder AI** | "Find Alternatives" button that returns static array | 🔴 Critical |
| **Simplified Logic** | 4-rule if/else when 10+ data points are available | 🟠 High |
| **Platform Parity** | Extension file can't resolve properties on macOS | 🟠 High |
| **Unused Integration** | Price Watch tracks prices, but no feature reads them | 🟠 High |

## Detection Process

### Step 1: Model Inventory

Catalog what data the app actually tracks:

```bash
# Find all @Model classes and their properties
grep -rn "@Model" Sources/Models/ --include="*.swift" -l

# Find relationships (data that connects models)
grep -rn "var.*:.*\[.*\]?" Sources/Models/ --include="*.swift" | grep -v "//"

# Find computed properties that aggregate data
grep -rn "var.*:.*{" Sources/Models/ --include="*.swift" | grep -i "total\|average\|count\|cost\|price"
```

Build a table of what data exists:

| Model | Property | Type | Description |
|-------|----------|------|-------------|
| Item | rmaRecords | [RMARecord]? | Repair/return history |
| Item | maintenanceRecords | [MaintenanceRecord]? | Maintenance log |
| Item | currentMarketPriceInCents | Int? | Price Watch data |
| Item | warrantyDeductibleInCents | Int? | User-entered |
| RMARecord | repairCostInCents | Int? | Actual repair cost |
| RMARecord | issueDescription | String | What broke |

### Step 2: Feature Data Consumption Audit

For each feature view/viewmodel, check what model data it reads:

```bash
# Find what properties a feature file references
grep -n "item\.\|\.rma\|\.maintenance\|\.price\|\.cost\|\.warranty" Sources/Features/RepairKeepReplace/ --include="*.swift" -r
```

Build a cross-reference matrix:

| Feature | Data Available | Data Used | Data Ignored |
|---------|---------------|-----------|--------------|
| RepairKeepReplace | repair costs, warranty, ratings, market price, condition | age, rating | repair costs, warranty, market price, condition |
| CoverageInsights | warranty dates, deductibles, coverage types | warranty dates | deductibles |

### Step 3: Mock Data Detection

Scan for patterns that indicate fake data:

```bash
# Pattern 1: asyncAfter with hardcoded data (fake fetch)
grep -rn "asyncAfter" Sources/Features/ --include="*.swift" -A 10 | grep -B 5 "=.*[0-9]\|\".*\$"

# Pattern 2: Static arrays pretending to be fetched data
grep -rn "let.*=.*\[" Sources/Features/ --include="*.swift" | grep -i "alternative\|suggestion\|recommendation"

# Pattern 3: Hardcoded scores/ratings in non-test code
grep -rn "Score.*=.*[0-9]\|rating.*=.*[0-9]" Sources/Features/ --include="*.swift" | grep -v "test\|Test\|preview\|Preview\|@available"

# Pattern 4: Placeholder strings that look like real data
grep -rn '"\$[0-9]' Sources/Features/ --include="*.swift" | grep -v "test\|Test\|format\|placeholder"

# Pattern 5: Functions that simulate work but do nothing real
grep -rn "func fetch\|func load\|func compute" Sources/Features/ --include="*.swift" -A 15 | grep "asyncAfter\|sleep\|\.random"
```

### Step 4: Integration Gap Detection

Check if features that should talk to each other actually do:

```bash
# Find all Manager/Service classes
grep -rn "class.*Manager\|class.*Service" Sources/ --include="*.swift" | grep -v "test\|Test"

# For each, check if feature views reference them
# Example: PriceWatchManager exists — does RepairKeepReplace use it?
grep -rn "PriceWatch\|priceWatch" Sources/Features/RepairKeepReplace/ --include="*.swift"
```

### Step 5: Platform Parity Check

```bash
# Find extension files
grep -rl "extension.*View" Sources/ --include="*.swift" | grep "+"

# For each, check for properties that might not resolve cross-platform
# Look for computed properties that reference private vars
grep -rn "private var.*ViewModel\|@State private var.*VM" Sources/ --include="*.swift"

# Find iOS-only dismiss buttons
grep -rn "#if os(iOS)" Sources/ --include="*.swift" -A 3 | grep -i "dismiss\|toolbar\|done"

# Build both platforms
# build_sim && build_macos
```

### Step 6: Decision Logic Audit

For features with decision/recommendation logic, check complexity vs data availability:

```bash
# Find decision functions
grep -rn "func compute\|func decide\|func recommend\|func calculate" Sources/Features/ --include="*.swift"

# Count decision factors vs available data points
# If decision uses 3 factors but 10 are available, flag it
```

**Decision quality checklist:**
- [ ] Does the decision use ALL relevant model properties?
- [ ] Are weights/scores based on real data or hardcoded?
- [ ] Does confidence reflect how much data is actually available?
- [ ] Are cost comparisons using real costs or estimates?

## Output Schema

```yaml
data_wiring_audit:
  project: "Stuffolio"
  audit_date: "YYYY-MM-DD"

  model_inventory:
    total_properties: 45
    total_relationships: 8
    cost_properties: 6  # Properties tracking money

  feature_audits:
    - feature: "RepairKeepReplace"
      files:
        - "RepairKeepReplaceView.swift"
        - "RepairKeepReplaceModels.swift"
      data_available: 12
      data_used: 4
      data_ignored: 8
      mock_data_found: true
      mock_patterns:
        - type: "asyncAfter_fake_fetch"
          file: "RepairKeepReplaceView.swift"
          line: 312
          description: "fetchRepairInfo() uses asyncAfter with hardcoded RepairContext"
        - type: "static_alternatives"
          file: "RepairKeepReplaceView.swift"
          line: 357
          description: "fetchAlternatives() returns hardcoded AIAlternative array"
      unwired_data:
        - property: "rmaRecords.repairCostInCents"
          available_in: "Item model"
          should_inform: "Repair cost comparison"
        - property: "currentMarketPriceInCents"
          available_in: "Item model (Price Watch)"
          should_inform: "Replace cost estimate"
      severity: "critical"

  integration_gaps:
    - source: "PriceWatchManager"
      target: "RepairKeepReplace"
      data_available: "currentMarketPriceInCents"
      currently_used: false
      impact: "Decision engine can't compare repair vs replace cost"

  platform_parity:
    - file: "DashboardView+SheetContent.swift"
      issue: "Computed properties not resolved on macOS"
      platform_affected: "macOS"
      severity: "high"

  summary:
    mock_data_issues: 2
    unwired_data_issues: 8
    integration_gaps: 3
    platform_issues: 1
    total_issues: 14
```

## Severity Classification

| Pattern | Severity | Rationale |
|---------|----------|-----------|
| asyncAfter + hardcoded data | 🔴 Critical | User sees fake data, makes real decisions |
| Static array pretending to be AI result | 🔴 Critical | Feature appears to work but doesn't |
| Decision logic ignoring available data | 🟠 High | Feature works but gives poor advice |
| Model property never read by relevant feature | 🟠 High | Missed opportunity, user entered data for nothing |
| Manager/service exists but feature doesn't use it | 🟠 High | Integration gap |
| Extension can't resolve cross-platform | 🟠 High | Build failure on one platform |
| Simplified scoring when richer data exists | 🟡 Medium | Works but suboptimal |

## Real-World Example: RepairKeepReplace

**Before Layer 5 audit:**
- `fetchRepairInfo()` used `asyncAfter` + hardcoded `RepairContext`
- `fetchAlternatives()` returned static `AIAlternative` array
- Decision engine: 4-rule if/else (age > lifespan? rating < 3?)
- Ignored: repair costs, warranty deductible, market price, maintenance costs, condition, brand history

**After Layer 5 fix:**
- `fetchRepairInfo()` computes from `item.averageRepairCostInCents`, RMA issue descriptions
- `fetchAlternatives()` removed; button opens `AIProductAssistantView` (real AI backend)
- Decision engine: weighted scoring across 4 paths using 10+ data points
- Cost comparison section shows real repair vs replace costs
- Confidence reflects actual data availability

**Impact:** Feature went from "looks functional but shows fake data" to "genuinely useful for real purchase decisions."

## Integration with Layers 1-4

| Layer | Finds | Example |
|-------|-------|---------|
| Layer 1 | Entry point exists | "Repair Advisor card exists" |
| Layer 2 | Navigation works | "Card opens picker, picker opens advisor" |
| Layer 3 | No dead ends | "All sheet cases handled" |
| Layer 4 | Good UX | "3-step flow, clear feedback" |
| **Layer 5** | **Data is real** | "Decision uses actual repair costs, not $85-150 placeholder" |

Layer 5 answers: "Is the data the user sees genuine and complete?"

## When to Run Layer 5

- After adding a new feature that uses model data
- When a feature has "fetch" or "compute" functions
- When integrating two features (does data flow between them?)
- Before release (are any features still using placeholder data?)
- When adding new model properties (do existing features know about them?)
