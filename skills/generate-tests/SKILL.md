---
name: generate-tests
description: 'Generate unit and UI tests for specified code with edge cases and mocks. Triggers: "generate tests", "write tests", "add tests", "test coverage".'
version: 2.1.0
author: Terry Nyberg
license: MIT
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
metadata:
  tier: execution
  category: testing
---

# Generate Tests

> **Quick Ref:** Generate unit and UI tests with proper mocking and edge case coverage. Outputs directly to Tests/ directory.

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

---

## Pre-flight: Git Safety Check

```bash
git status --short
```

If uncommitted changes exist:

```
AskUserQuestion with questions:
[
  {
    "question": "You have uncommitted changes. Commit before proceeding?",
    "header": "Git",
    "options": [
      {"label": "Commit first (Recommended)", "description": "Save current work so you can revert if this skill modifies files"},
      {"label": "Continue without committing", "description": "Proceed — I accept the risk"}
    ],
    "multiSelect": false
  }
]
```

If "Commit first": Ask for a commit message, stage changed files, and commit. Then proceed.

---

## Step 1: Detect Test Framework

Auto-detect which testing framework the project uses:

```bash
# Check for Swift Testing
Grep pattern="import Testing" glob="**/*Test*.swift" output_mode="count"

# Check for XCTest
Grep pattern="import XCTest" glob="**/*Test*.swift" output_mode="count"
```

| Detection | Framework | Syntax |
|-----------|-----------|--------|
| `import Testing` found | Swift Testing | `@Test`, `#expect`, `@Suite` |
| Only `import XCTest` | XCTest | `XCTestCase`, `XCTAssert*` |
| New project (no tests) | Swift Testing (Recommended) | Modern, concurrent-safe |

If both are present:

```
AskUserQuestion with questions:
[
  {
    "question": "Which testing framework should I use?",
    "header": "Framework",
    "options": [
      {"label": "Swift Testing (Recommended)", "description": "Modern framework with @Test, #expect, better async support"},
      {"label": "XCTest", "description": "Classic framework with XCTestCase, XCTAssert*"}
    ],
    "multiSelect": false
  }
]
```

---

## Step 2: Gather Test Requirements

```
AskUserQuestion with questions:
[
  {
    "question": "What would you like to generate tests for?",
    "header": "Target",
    "options": [
      {"label": "Specific type/file", "description": "I'll provide the name or path"},
      {"label": "Analyze coverage gaps", "description": "Find untested code and suggest tests"},
      {"label": "Feature area", "description": "Generate tests for a feature (e.g., 'authentication')"}
    ],
    "multiSelect": false
  },
  {
    "question": "What type of tests do you need?",
    "header": "Test type",
    "options": [
      {"label": "Unit tests", "description": "Test individual functions/methods in isolation"},
      {"label": "UI tests", "description": "Test user interactions and flows"},
      {"label": "All applicable", "description": "Generate appropriate tests for each layer"}
    ],
    "multiSelect": true
  }
]
```

---

## Step 3: Analyze Target Code

Read the target code and extract:

1. **Public API Surface** — public/internal functions, initializers, computed properties
2. **Dependencies** — protocol dependencies (need mocks), external services (need stubs)
3. **Side Effects** — network calls, file I/O, UserDefaults, notifications
4. **State Transitions** — how internal state changes, what triggers transitions

```bash
# Find the target file
Glob pattern="**/*TargetName*.swift"

# Read the target
Read file_path="<path_to_target>"

# Find existing tests for this target
Glob pattern="**/*TargetName*Tests.swift"
Glob pattern="**/*TargetName*Test.swift"
```

---

## Step 4: Generate Test Plan

Before writing tests, create a plan:

```markdown
## Test Plan for [TargetType]

### Unit Tests Needed

| Test Case | Input | Expected Output | Priority |
|-----------|-------|-----------------|----------|
| init_withValidData_succeeds | Valid params | Instance created | High |
| init_withMissingRequired_throws | nil required | ValidationError | High |
| fetch_whenEmpty_returnsEmptyArray | Mock empty | [] | Medium |

### Mocks Required

| Protocol | Mock Name | Behavior to Simulate |
|----------|-----------|---------------------|
| NetworkService | MockNetworkService | Success, failure, timeout |

### Edge Cases

| Scenario | Test Name |
|----------|-----------|
| Empty input | test_withEmptyInput_handlesGracefully |
| Nil optional | test_withNilOptional_usesDefault |
| Concurrent access | test_concurrentCalls_threadSafe |
```

---

## Step 5: Generate Mock Implementations

For each protocol dependency, generate a mock:

```swift
@testable import YourApp

final class MockNetworkService: NetworkServiceProtocol {
    var fetchResult: Result<[Item], Error> = .success([])
    var fetchCallCount = 0

    func fetch<T: Decodable>(from url: URL) async throws -> T {
        fetchCallCount += 1
        switch fetchResult {
        case .success(let data):
            guard let result = data as? T else {
                throw MockError.typeMismatch
            }
            return result
        case .failure(let error):
            throw error
        }
    }

    enum MockError: Error {
        case typeMismatch
    }
}
```

---

## Step 6: Generate Tests

### Swift Testing Format

```swift
import Testing
@testable import YourApp

@Suite("ItemViewModel Tests")
struct ItemViewModelTests {

    @Test("Initialize with valid data succeeds")
    func init_withValidData_succeeds() throws {
        let viewModel = ItemViewModel(item: .preview)
        #expect(viewModel.title == "Preview Item")
        #expect(viewModel.isLoading == false)
    }

    @Test("Fetch items when network available returns items")
    func fetch_whenNetworkAvailable_returnsItems() async throws {
        let mockService = MockNetworkService()
        mockService.fetchResult = .success([Item.preview])
        let viewModel = ItemViewModel(networkService: mockService)
        try await viewModel.fetchItems()
        #expect(viewModel.items.count == 1)
    }

    @Test("Fetch items when network fails throws error")
    func fetch_whenNetworkFails_throwsError() async {
        let mockService = MockNetworkService()
        mockService.fetchResult = .failure(NetworkError.noConnection)
        let viewModel = ItemViewModel(networkService: mockService)
        await #expect(throws: NetworkError.self) {
            try await viewModel.fetchItems()
        }
    }
}
```

### XCTest Format

```swift
import XCTest
@testable import YourApp

final class ItemViewModelTests: XCTestCase {

    var sut: ItemViewModel!
    var mockService: MockNetworkService!

    override func setUp() {
        super.setUp()
        mockService = MockNetworkService()
        sut = ItemViewModel(networkService: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    func test_init_withValidData_succeeds() {
        let viewModel = ItemViewModel(item: .preview)
        XCTAssertEqual(viewModel.title, "Preview Item")
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_fetch_whenNetworkFails_throwsError() async {
        mockService.stubbedFetchResult = .failure(NetworkError.noConnection)
        do {
            try await sut.fetchItems()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
}
```

---

## Step 7: Write Tests to Project

Determine the correct test file location:

```bash
# Find existing test directory structure
Glob pattern="**/*Tests.swift"

# Common patterns:
# Tests/AppTests/ViewModels/ItemViewModelTests.swift
# Tests/UnitTests/ItemViewModelTests.swift
```

Write the generated tests to match the existing directory structure and naming conventions.

---

## Step 8: Verify and Present Summary

### 8.1: Run Tests

```bash
# Verify generated tests compile and pass
xcodebuild test -scheme <SCHEME> -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:<TEST_TARGET> -quiet 2>&1 | tail -10
```

If tests fail, fix the issues before presenting results.

### 8.2: Display Results

**Display the summary inline** so the user sees results immediately:

```markdown
## Test Generation Complete

**Target:** ItemViewModel.swift
**Framework:** Swift Testing
**Tests Generated:** N
**Status:** All passing ✓

| Test Type | Count | File |
|-----------|-------|------|
| Unit Tests | 10 | Tests/ItemViewModelTests.swift |
| Mock | 1 | Tests/Mocks/MockNetworkService.swift |

**Coverage Added:**
- Initialization: 2 tests
- Fetch operations: 3 tests
- Error handling: 2 tests
- Edge cases: 3 tests
```

---

## Test Naming Convention

Follow: `[method]_[scenario]_[expectedBehavior]`

Examples:
- `fetchItems_whenNetworkAvailable_returnsItems`
- `saveItem_withEmptyTitle_throwsValidationError`
- `init_withNilOptional_usesDefaultValue`
- `delete_whenItemExists_removesFromList`

---

## Common Test Patterns

### Parameterized Tests (Swift Testing)

```swift
@Test(arguments: [
    ("valid@email.com", true),
    ("invalid", false),
    ("", false),
    ("a@b.c", true)
])
func validateEmail_withInput_returnsExpected(email: String, expected: Bool) {
    #expect(sut.isValidEmail(email) == expected)
}
```

### Testing @MainActor Code

```swift
@Test @MainActor func updateUI_onMainThread() {
    sut.updateTitle("New Title")
    #expect(sut.displayTitle == "New Title")
}
```

### Testing Errors (Swift Testing)

```swift
@Test func invalidInput_throwsValidationError() async {
    await #expect(throws: ValidationError.self) {
        try await sut.validate(input: "")
    }
}
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Can't find test directory | Check for `Tests/` or `*Tests/` at project root |
| Target has no protocol dependencies | Test public methods directly without mocks |
| @MainActor prevents test creation | Add `@MainActor` to test function or use `MainActor.run {}` |
| SwiftData ModelContext in tests | Create in-memory container: `ModelContainer(for:, configurations: .init(isStoredInMemoryOnly: true))` |
| Tests can't import app module | Verify test target has the app module in its dependencies |
