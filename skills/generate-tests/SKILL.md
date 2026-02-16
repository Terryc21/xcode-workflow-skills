---
name: generate-tests
description: Generate unit and UI tests for specified code with edge cases and mocks
---

# Generate Tests

Generate unit and UI tests for specified code with edge cases and mocks.

## Input Required

Specify what to test:
- File path or function/type name
- Type of tests needed: Unit / Integration / UI
- Any specific scenarios to cover

---

## Test Generation Process

### Step 1: Analyze Target Code

1. **Read the code** to understand:
   - Public API surface
   - Dependencies (what needs mocking)
   - Side effects (network, persistence, notifications)
   - Edge cases and error conditions

2. **Identify testable behaviors**:
   - Happy path scenarios
   - Error/failure scenarios
   - Boundary conditions
   - State transitions

### Step 2: Test Plan

| Scenario | Input | Expected Output | Type |
|----------|-------|-----------------|------|
| | | | Unit/Integration/UI |

### Step 3: Dependencies & Mocks

**Dependencies to mock:**
| Dependency | Mock Strategy |
|------------|---------------|
| Network service | Protocol + mock implementation |
| Database | In-memory container |
| UserDefaults | Dedicated test suite |
| Date/Time | Inject fixed dates |

### Step 4: Generate Tests

Use Swift Testing framework (`import Testing`) for new tests:

```swift
import Testing
@testable import Stuffolio

struct [Target]Tests {

    @Test func [scenario]_[condition]_[expectedResult]() async throws {
        // Given
        // When
        // Then
    }
}
```

### Step 5: Test Naming Convention

Follow: `[method]_[scenario]_[expectedBehavior]`

Examples:
- `fetchItems_whenNetworkAvailable_returnsItems`
- `saveItem_withEmptyTitle_throwsValidationError`

### Step 6: Coverage Checklist

- [ ] All public methods
- [ ] All code branches (if/else, switch cases)
- [ ] Error throwing paths
- [ ] Boundary values (empty, nil, max, min)
