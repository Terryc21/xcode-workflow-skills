---
name: generate-tests
description: Generate unit and UI tests for specified code with edge cases and mocks
version: 1.0.0
author: Terry Nyberg
license: MIT
allowed-tools: [Read, Write, Glob, Grep, AskUserQuestion]
metadata:
  tier: execution
  category: testing
---

# Generate Tests

> **Quick Ref:** Generate unit and UI tests with proper mocking and edge case coverage. Outputs directly to Tests/ directory.

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

Generate unit and UI tests for specified code with edge cases, mocks, and proper test naming.

---

## Quick Commands

| Command | Description |
|---------|-------------|
| `/generate-tests MyViewModel` | Generate unit tests for a specific type |
| `/generate-tests path/to/File.swift` | Generate tests for a specific file |
| `/generate-tests --ui MyView` | Generate UI tests for a view |
| `/generate-tests --coverage` | Analyze existing coverage and suggest tests |

---

## Step 1: Detect Test Framework

**Auto-detect which testing framework the project uses:**

```
# Check for Swift Testing
Grep pattern="import Testing" path="Tests" glob="*.swift"

# Check for XCTest
Grep pattern="import XCTest" path="Tests" glob="*.swift"

# Check Package.swift for testing dependencies
Grep pattern="swift-testing|XCTest" path="Package.swift"
```

**Framework Selection:**

| Detection | Framework | Syntax |
|-----------|-----------|--------|
| `import Testing` found | Swift Testing | `@Test`, `#expect`, `@Suite` |
| Only `import XCTest` | XCTest | `XCTestCase`, `XCTAssert*` |
| New project (no tests) | Swift Testing (Recommended) | Modern, concurrent-safe |

If both are present, use AskUserQuestion:

```
questions:
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

Use AskUserQuestion to understand what to test:

```
questions:
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
  }
]
```

If "Specific type/file" selected, ask for details:

```
questions:
[
  {
    "question": "What type of tests do you need?",
    "header": "Test Type",
    "options": [
      {"label": "Unit tests", "description": "Test individual functions/methods in isolation"},
      {"label": "Integration tests", "description": "Test components working together"},
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

1. **Public API Surface**
   - Public/internal functions
   - Initializers
   - Properties that should be tested

2. **Dependencies**
   - Protocol dependencies (need mocks)
   - External services (need stubs)
   - Database access (need test containers)

3. **Side Effects**
   - Network calls
   - File I/O
   - UserDefaults access
   - Notifications posted

4. **State Transitions**
   - How does internal state change?
   - What triggers transitions?

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
| fetch_whenNetworkAvailable_returnsData | Mock success | [Items] | High |
| fetch_whenNetworkFails_throwsError | Mock failure | NetworkError | High |
| fetch_whenEmpty_returnsEmptyArray | Mock empty | [] | Medium |

### Mocks Required

| Protocol | Mock Name | Behavior to Simulate |
|----------|-----------|---------------------|
| NetworkService | MockNetworkService | Success, failure, timeout |
| DatabaseService | MockDatabaseService | CRUD operations |

### Edge Cases

| Scenario | Test Name |
|----------|-----------|
| Empty input | test_withEmptyInput_handlesGracefully |
| Nil optional | test_withNilOptional_usesDefault |
| Maximum values | test_withMaxInt_doesNotOverflow |
| Concurrent access | test_concurrentCalls_threadSafe |
```

---

## Step 5: Generate Mock Implementations

For each protocol dependency, generate a mock:

### Swift Testing Mock Pattern

```swift
// MockNetworkService.swift
@testable import YourApp

final class MockNetworkService: NetworkServiceProtocol {
    // Configuration
    var fetchResult: Result<[Item], Error> = .success([])
    var fetchCallCount = 0
    var lastFetchRequest: URLRequest?

    func fetch<T: Decodable>(from url: URL) async throws -> T {
        fetchCallCount += 1
        lastFetchRequest = URLRequest(url: url)

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

### XCTest Mock Pattern

```swift
// MockNetworkService.swift
@testable import YourApp

class MockNetworkService: NetworkServiceProtocol {
    var stubbedFetchResult: Result<Data, Error>!
    var fetchCalled = false

    func fetch(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        fetchCalled = true
        completion(stubbedFetchResult)
    }
}
```

---

## Step 6: Generate Unit Tests

### Swift Testing Format

```swift
import Testing
@testable import YourApp

@Suite("ItemViewModel Tests")
struct ItemViewModelTests {

    // MARK: - Initialization

    @Test("Initialize with valid data succeeds")
    func init_withValidData_succeeds() throws {
        let viewModel = ItemViewModel(item: .preview)

        #expect(viewModel.title == "Preview Item")
        #expect(viewModel.isLoading == false)
    }

    @Test("Initialize with nil item uses empty state")
    func init_withNilItem_usesEmptyState() {
        let viewModel = ItemViewModel(item: nil)

        #expect(viewModel.title == "")
        #expect(viewModel.isEmpty == true)
    }

    // MARK: - Fetching

    @Test("Fetch items when network available returns items")
    func fetch_whenNetworkAvailable_returnsItems() async throws {
        let mockService = MockNetworkService()
        mockService.fetchResult = .success([Item.preview])

        let viewModel = ItemViewModel(networkService: mockService)
        try await viewModel.fetchItems()

        #expect(viewModel.items.count == 1)
        #expect(mockService.fetchCallCount == 1)
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

    @Test("Fetch items when empty returns empty array")
    func fetch_whenEmpty_returnsEmptyArray() async throws {
        let mockService = MockNetworkService()
        mockService.fetchResult = .success([])

        let viewModel = ItemViewModel(networkService: mockService)
        try await viewModel.fetchItems()

        #expect(viewModel.items.isEmpty)
    }

    // MARK: - Edge Cases

    @Test("Handle concurrent fetch calls safely",
          .tags(.concurrency))
    func fetch_concurrentCalls_threadSafe() async throws {
        let mockService = MockNetworkService()
        mockService.fetchResult = .success([Item.preview])

        let viewModel = ItemViewModel(networkService: mockService)

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    try? await viewModel.fetchItems()
                }
            }
        }

        // Should complete without crashes
        #expect(mockService.fetchCallCount == 10)
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

    // MARK: - Initialization

    func test_init_withValidData_succeeds() {
        let viewModel = ItemViewModel(item: .preview)

        XCTAssertEqual(viewModel.title, "Preview Item")
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Fetching

    func test_fetch_whenNetworkAvailable_returnsItems() async throws {
        mockService.stubbedFetchResult = .success([Item.preview])

        try await sut.fetchItems()

        XCTAssertEqual(sut.items.count, 1)
        XCTAssertTrue(mockService.fetchCalled)
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

## Step 7: Generate UI Tests

For UI tests, create helper methods and actual tests:

```swift
import XCTest

final class ItemListUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state"]
        app.launch()
    }

    // MARK: - Navigation

    func test_tapItem_navigatesToDetail() throws {
        // Given
        let itemList = app.collectionViews["item-list"]
        XCTAssertTrue(itemList.waitForExistence(timeout: 5))

        // When
        let firstItem = itemList.cells.firstMatch
        firstItem.tap()

        // Then
        let detailView = app.otherElements["item-detail-view"]
        XCTAssertTrue(detailView.waitForExistence(timeout: 3))
    }

    func test_addButton_showsAddSheet() throws {
        // Given
        let addButton = app.buttons["action-add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))

        // When
        addButton.tap()

        // Then
        let addSheet = app.sheets.firstMatch
        XCTAssertTrue(addSheet.waitForExistence(timeout: 3))
    }

    // MARK: - Data Entry

    func test_createItem_withValidData_showsInList() throws {
        // Navigate to add
        app.buttons["action-add"].tap()

        // Enter data
        let titleField = app.textFields["field-title"]
        titleField.tap()
        titleField.typeText("Test Item")

        // Save
        app.buttons["action-save"].tap()

        // Verify
        let itemCell = app.cells.staticTexts["Test Item"]
        XCTAssertTrue(itemCell.waitForExistence(timeout: 5))
    }
}
```

---

## Step 8: Write Tests to Project

Determine the correct test file location:

```
# Find existing test directory structure
Glob pattern="Tests/**/*Tests.swift"

# Common patterns:
# Tests/UnitTests/ViewModels/ItemViewModelTests.swift
# Tests/YourAppTests/ItemViewModelTests.swift
# YourAppTests/ItemViewModelTests.swift
```

Write the generated tests to the appropriate location.

---

## Step 9: Present Summary

```
## Test Generation Complete

**Target:** ItemViewModel.swift
**Framework:** Swift Testing
**Tests Generated:** 12

| Test Type | Count | File |
|-----------|-------|------|
| Unit Tests | 10 | Tests/ItemViewModelTests.swift |
| Mock | 1 | Tests/Mocks/MockNetworkService.swift |
| UI Tests | 2 | UITests/ItemListUITests.swift |

**Coverage Added:**
- Initialization: 2 tests
- Fetch operations: 4 tests
- Error handling: 3 tests
- Edge cases: 3 tests

**Next Steps:**
1. Run tests to verify: `swift test` or Cmd+U
2. Review generated mocks for completeness
3. Add additional edge cases as needed
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

## For iOS-Specific Testing Patterns

This skill focuses on test generation workflow. For deep iOS-specific testing patterns:

- **Swift Testing patterns:** Invoke `/axiom:axiom-swift-testing`
- **Async testing:** Invoke `/axiom:axiom-testing-async`
- **UI test automation:** Invoke `/axiom:axiom-xctest-automation`
- **UI recording:** Invoke `/axiom:axiom-ui-recording`

---

## See Also

- `/run-tests` - Execute the generated tests
- `/ui-scan` - Set up UI test environment with onboarding bypass
- `/debug` - When tests fail unexpectedly

---

## Common Test Patterns

### Testing Async Code (Swift Testing)

```swift
@Test func fetchData_completesWithinTimeout() async throws {
    let result = try await withTimeout(seconds: 5) {
        try await sut.fetchData()
    }
    #expect(result.count > 0)
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

### Testing @MainActor Code

```swift
@Test @MainActor func updateUI_onMainThread() {
    sut.updateTitle("New Title")
    #expect(sut.displayTitle == "New Title")
}
```

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
