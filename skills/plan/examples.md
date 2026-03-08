# Plan Skill — Calibration Examples

> This file helps Claude produce the right level of detail in plans. Read it before generating output.

---

## Golden Rule in Practice

Plans describe **WHAT** to change and **WHERE** — never **HOW** (implementation code).

### Bad — includes implementation code

```
Task: "Add keyboard dismissal to item entry forms"
Files: AddItemView.swift:45, EditItemView.swift:32

Add this to each view's body:
    .onTapGesture {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }

Also wrap the form in a ScrollView and add:
    .scrollDismissesKeyboard(.interactively)
```

### Good — describes what/where with acceptance criteria

```
Task: "Add keyboard dismissal to item entry forms"
Size: M (4 files)
Files: AddItemView.swift:45-80, EditItemView.swift:32-60,
       AddItemViewModel.swift, EditItemViewModel.swift
Acceptance:
  - Tapping outside any text field dismisses the keyboard
  - Scrolling the form dismisses the keyboard interactively
  - No regressions in existing form validation behavior
```

---

## Good vs Bad: Task Specifications

### Bad — full Swift implementation in a plan

```
Task: "Fix @Query not updating when predicate changes"

Replace this:
    @Query(sort: \Item.name) var items: [Item]

With this:
    @Query(filter: #Predicate<Item> { item in
        item.category == selectedCategory
    }, sort: \Item.name) var items: [Item]

Then update the view to pass selectedCategory as a binding...
[30 more lines of Swift code]
```

### Good — file:line refs + acceptance criteria

```
Task: "Fix @Query not updating when predicate changes"
Size: S (2 files)
Files: ItemListView.swift:23 (@Query declaration),
       ItemListView.swift:67 (predicate construction)
Source: Audit finding #7 (Data, MEDIUM)
Acceptance:
  - Changing category filter updates the displayed items immediately
  - No flash of stale data when switching categories
Note: Follow existing pattern in TagListView.swift:15 which already
      handles dynamic predicates correctly.
```

---

## Good vs Bad: Audit-Sourced Tasks

### Bad — verbatim audit copy, one task per finding

```
Phase B, Task 3: "Audit finding: Missing @MainActor on ItemListViewModel"
  Severity: HIGH, LOE: 1h, File: ItemListViewModel.swift:1

Phase B, Task 4: "Audit finding: Missing @MainActor on EditItemViewModel"
  Severity: HIGH, LOE: 1h, File: EditItemViewModel.swift:1

Phase B, Task 5: "Audit finding: Missing @MainActor on AddItemViewModel"
  Severity: HIGH, LOE: 1h, File: AddItemViewModel.swift:1

Phase B, Task 6: "Audit finding: Unsafe Task capture in SyncManager"
  Severity: HIGH, LOE: 2h, File: SyncManager.swift:45
```

### Good — grouped M-sized tasks with traceability

```
Phase B, Task 3: "Add @MainActor isolation to item ViewModels"
  Size: M (4 files)
  Files: ItemListViewModel.swift:1, EditItemViewModel.swift:1,
         AddItemViewModel.swift:1, ItemViewModelTests.swift
  Source: Audit findings #3, #4, #5 (Concurrency, HIGH)
  LOE: 3h
  Acceptance:
    - All three ViewModels annotated @MainActor
    - No new concurrency warnings introduced
    - Existing ViewModel tests still pass

Phase B, Task 4: "Fix unsafe Task capture in SyncManager"
  Size: M (3 files)
  Files: SyncManager.swift:45, SyncService.swift:12, SyncTests.swift
  Source: Audit finding #6 (Concurrency, HIGH)
  LOE: 2h
  Acceptance:
    - Task closures capture only Sendable values
    - Background sync completes without data races
```

---

## T-Shirt Sizing Anchors

These iOS/Swift-specific anchors calibrate S/M/L sizing:

### S — Small (1-2 files)

- Fix a single `@Query` sort descriptor
- Add one missing accessibility label
- Update a single `@AppStorage` key name
- Fix a `DateFormatter` locale issue in one file
- Add `.searchable` modifier to an existing view

### M — Medium (3-5 files) — TARGET SIZE

- Add keyboard dismissal across a feature area (view + viewmodel + tests)
- Implement a new filter option (model extension + view + viewmodel + tests)
- Fix `@MainActor` isolation for a group of related ViewModels
- Add error handling to a network call (service + viewmodel + view + tests)
- Migrate one model from `@ObservableObject` to `@Observable`

### L — Large (5+ files) — MUST SPLIT

- Refactor ViewModel to extract shared logic (touches all views that use it)
- Migrate persistence layer from UserDefaults to SwiftData
- Add offline support (model + sync service + conflict resolution + UI + tests)

**Split strategy for L:** Find the natural boundary. Model changes in one task, ViewModel adaptation in another, View updates in a third, tests alongside each.

---

## When Code IS Appropriate in a Plan

Code is allowed (≤10 lines) in these specific cases:

### 1. Referencing an existing repo pattern

```
Note: Follow the pattern established in TagListView.swift:15-25
      which uses @Query with a dynamic predicate via init injection.
```

### 2. Required API signature or migration shape

```
Note: @Observable migration requires changing from:
    class FooViewModel: ObservableObject { @Published var x = 0 }
  to:
    @Observable class FooViewModel { var x = 0 }
  Callers change @StateObject → @State, @ObservedObject → direct reference.
```

### 3. Known framework gotcha

```
Note: SwiftData @Query does not react to predicate changes after init.
      Must use the init-injection pattern (pass predicate via initializer).
      See: ItemListView.swift:23 for existing correct usage.
```

---

## Quick Reference

| Include in plan | Do NOT include in plan |
|-----------------|----------------------|
| File paths with line numbers | Full function implementations |
| Acceptance criteria | Step-by-step code changes |
| Size (S/M/L) with file count | Inline Swift code blocks >10 lines |
| Source audit finding # | Copy-pasted audit finding text |
| "Follow pattern in X.swift:Y" | "Add this exact code: ..." |
| Framework gotchas (≤10 lines) | Tutorials or explanations |
| Dependency relationships | Architecture diagrams |
| Estimated LOE in hours | Time estimates for calendar days |
