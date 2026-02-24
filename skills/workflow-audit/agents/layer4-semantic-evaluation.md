# Layer 4: Semantic Evaluation

## Purpose

Layer 4 evaluates workflows from the **user's perspective**. While Layers 1-3 analyze code structure, Layer 4 asks: "Does this workflow help the user achieve their goal?"

## User Goals Analysis

### Goal Categories

| Category | User Intent | Example |
|----------|-------------|---------|
| **Discovery** | "What can this app do?" | Sees promotion card, explores |
| **Action** | "I want to do X" | Add item, track warranty |
| **Problem-Solving** | "I have a problem" | Damaged item, expiring warranty |
| **Optimization** | "Make things better" | Clean up, organize, export |

### Goal-to-Workflow Mapping

For each user goal, trace the optimal path:

```yaml
goal: "Track warranty for my new Apple device"
user_type: "New user with Apple product"
optimal_workflow:
  steps: 3
  path:
    - "See AppleCare+ card on dashboard"
    - "Tap card, select device"
    - "Enter warranty details"
actual_workflow: "Matches optimal (after recent fix)"
rating: "Good"
```

## Evaluation Criteria

### Criterion 1: Goal Discoverability
Can users find the feature that helps them?

| Rating | Definition |
|--------|------------|
| Excellent | Feature appears contextually when relevant |
| Good | Feature is in logical location |
| Fair | Feature exists but hidden |
| Poor | Feature hard to find or missing |

### Criterion 2: Path Efficiency
How many steps to reach the goal?

| Rating | Steps | Example |
|--------|-------|---------|
| Optimal | 1-2 | Tap → Done |
| Acceptable | 3-4 | Tap → Select → Configure → Done |
| Suboptimal | 5+ | Navigation → Scroll → Search → Tap → Done |
| Broken | ∞ | Cannot complete |

### Criterion 3: Feedback Clarity
Does user know they succeeded?

| Rating | Definition |
|--------|------------|
| Clear | Immediate visual/haptic confirmation |
| Adequate | State change visible |
| Unclear | No obvious feedback |
| Misleading | Wrong feedback shown |

### Criterion 4: Error Recovery
What happens if user makes mistake?

| Rating | Definition |
|--------|------------|
| Graceful | Clear error message + recovery path |
| Acceptable | Error shown, user figures out fix |
| Frustrating | Error but unclear cause |
| Catastrophic | Data loss, no recovery |

## Semantic Analysis Template

```yaml
scenario:
  id: "sem-001"
  user_persona: "New iPhone user"
  context: "Just added iPhone to inventory"
  goal: "Track AppleCare+ warranty"

evaluation:
  discoverability:
    rating: "excellent"
    reason: "Promotion card appears automatically when Apple product without warranty exists"

  path_efficiency:
    rating: "acceptable"
    steps: 4
    path: ["See card", "Tap card", "Select device", "Enter warranty"]
    optimal_possible: 3
    gap: "Could pre-select if only one Apple device"

  feedback_clarity:
    rating: "clear"
    reason: "Item saves, toast confirms, warranty visible in detail"

  error_recovery:
    rating: "graceful"
    reason: "Cancel available at every step, no data loss"

  overall_rating: "Good"
  improvement_opportunity: "Skip device picker if only one eligible"
```

## User Personas for Stuffolio

### Persona 1: Warranty Tracker
**Goal:** Never miss a warranty deadline
**Key workflows:**
- Add new item with warranty
- See expiring warranties
- File warranty claim

### Persona 2: Insurance Documenter
**Goal:** Have proof of ownership if needed
**Key workflows:**
- Add items with photos + receipts
- Export inventory report
- Prepare insurance claim

### Persona 3: Collector/Enthusiast
**Goal:** Catalog valuable collection
**Key workflows:**
- Stuff Scout for identification
- Track values over time
- Legacy planning

### Persona 4: Practical Organizer
**Goal:** Know what I own and where
**Key workflows:**
- Bulk import existing inventory
- Search/filter items
- Location tracking

## Evaluation Matrix

| Workflow | Discovery | Efficiency | Feedback | Recovery | Overall |
|----------|-----------|------------|----------|----------|---------|
| Add Item | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Excellent |
| Track AppleCare | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Good |
| Price Watch | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Fair |
| Repair Advisor | ⭐⭐⭐⭐ | ⭐ | N/A | N/A | **Broken** |
| Bulk Actions | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Fair |
| AI Assistant | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Good |

## Semantic Issues Found

### Issue S1: Broken Promise (Critical)
**Promotion Card:** "Repair Advisor - get repair guidance"
**User Expectation:** Tool to help decide repair vs replace
**Actual Experience:** Lands on Tools, cannot find feature
**User Feeling:** Frustration, distrust of promotion cards
**Fix Priority:** Immediate

### Issue S2: Scroll Tax (High)
**Promotion Card:** "Price Watch"
**User Expectation:** Immediate access to price tracking
**Actual Experience:** Land on Tools, scroll through 2 categories
**User Feeling:** Mild annoyance, wasted time
**Fix Priority:** High

### Issue S3: Mode Mystery (High)
**Promotion Card:** "Bulk Actions"
**User Expectation:** Ready to select multiple items
**Actual Experience:** Normal list, must find Select button
**User Feeling:** Confusion, "where are the bulk actions?"
**Fix Priority:** High

### Issue S4: Two-Step Dance (Acceptable)
**Feature:** AI Assistant
**User Expectation:** Get AI help with product
**Actual Experience:** Must select item first
**User Feeling:** Minor friction, understandable
**Fix Priority:** Low (optimization only)

## Recommendations

### Design Principle: Honor the Promise
> When a promotion card says "Do X", tapping it should DO X.
> Not "go to a place where you might find X."

### Design Principle: Context-Aware Shortcuts
> If user's context implies a specific item, skip the picker.
> - 1 damaged item → Open Repair Advisor for that item
> - 1 Apple product → Open AppleCare for that product

### Design Principle: State Preservation
> When navigating to a feature, set up the expected state.
> - "Bulk Actions" → Enter Select mode
> - "Expiring Soon" → Filter to expiring items

## Integration with Layers 1-3

| Layer | Finds | Example |
|-------|-------|---------|
| Layer 1 | Entry points exist | "Repair Advisor card exists" |
| Layer 2 | Technical flow | "Card → Tools → Dead end" |
| Layer 3 | Issue category | "Dead end, critical severity" |
| **Layer 4** | **User impact** | "Breaks trust, user feels misled" |

Layer 4 answers: "Why does this matter to users?"
