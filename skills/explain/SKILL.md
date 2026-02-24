---
name: explain
description: 'Deep-dive explanation of how a specific file, feature, or data flow works. Triggers: "explain", "how does X work", "walk me through", "what does this do".'
version: 1.1.0
author: Terry Nyberg
license: MIT
allowed-tools: [Read, Grep, Glob, LSP]
metadata:
  tier: reference
  category: analysis
---

# Explain

> **Quick Ref:** Deep-dive explanation with code walkthrough. Output: `.agents/research/YYYY-MM-DD-explain-{topic}.md`

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

Deep-dive explanation of how a specific file, feature, or data flow works.

## Quick Commands

| Command | Description |
|---------|-------------|
| `/explain ItemDetailView.swift` | Explain a specific file |
| `/explain "warranty tracking"` | Explain a feature by name |
| `/explain "how does an item get saved"` | Explain a data flow |
| `/explain ItemHelper --deps` | Show dependency graph for a type |

---

## Step 1: Determine What to Explain

If the user provides a file path, read it directly. If they provide a feature or concept name, find the relevant code:

```
# Find files by name
Glob pattern="**/*FeatureName*.swift"

# Find files that mention the feature/concept
Grep pattern="FeatureKeyword" glob="*.swift" output_mode="files_with_matches"

# Find the entry point (view, view model, manager)
Grep pattern="struct.*FeatureName.*View|class.*FeatureName" glob="*.swift" output_mode="content"
```

Read every relevant file — don't explain code you haven't read.

---

## Step 2: Explain — Overview

After reading the code, document:

**What it is:** [One paragraph summary — what this code does]

**Why it exists:** [The problem it solves or user need it fulfills]

**Where it lives:** [File paths, module/directory]

---

## Step 3: Explain — Key Components

Identify the main types, protocols, and functions:

```
# List types defined in the file
Grep pattern="^(class|struct|enum|protocol|actor)\\s+\\w+" path="Sources/Features/FeatureName" glob="*.swift" output_mode="content"

# List public/internal functions
Grep pattern="^\\s+(func|var|let)\\s+\\w+" path="path/to/file.swift" output_mode="content"
```

Present as a table:

| Component | Purpose | Location |
|-----------|---------|----------|
| `ItemDetailViewModel` | Manages item display and editing state | Sources/Features/ItemDetail/ItemDetailViewModel.swift |
| `ItemDetailView` | SwiftUI view for displaying item details | Sources/Features/ItemDetail/ItemDetailView.swift |
| `ItemHelperProtocol` | Abstracts item operations for testability | Sources/Helpers/ItemHelperProtocol.swift |

---

## Step 4: Explain — How It Works

Trace the execution flow step by step. For each step, reference the actual code:

```
1. User taps item in list → ItemListView.swift:45
   NavigationLink triggers with selected item

2. ItemDetailView initializes → ItemDetailView.swift:12
   Creates ItemDetailViewModel with the item

3. View model loads data → ItemDetailViewModel.swift:28
   .task modifier calls loadItemDetails()

4. Details populated → ItemDetailViewModel.swift:35
   @Published properties updated, view re-renders
```

Use LSP for tracing definitions and references when available:

```
LSP operation="goToDefinition" filePath="path/to/file.swift" line=45 character=12
LSP operation="findReferences" filePath="path/to/file.swift" line=28 character=10
```

---

## Step 5: Explain — Data Flow

Show how data moves between components:

```
[User Tap]
    ↓
ItemListView (NavigationLink)
    ↓ passes Item
ItemDetailView (creates view model)
    ↓ item reference
ItemDetailViewModel (@Published properties)
    ↓ async load
NetworkService.fetchDetails(item.id)
    ↓ returns DetailResponse
ItemDetailViewModel.details = response
    ↓ @Published triggers
ItemDetailView re-renders with details
```

---

## Step 6: Explain — Dependencies

### Upstream (what this code depends on)

```
# Find imports
Grep pattern="^import " path="path/to/file.swift" output_mode="content"

# Find injected dependencies
Grep pattern="init\\(" path="path/to/file.swift" output_mode="content"

# Find protocol conformances
Grep pattern=":\\s*\\w+Protocol|:\\s*\\w+Delegate" path="path/to/file.swift" output_mode="content"
```

### Downstream (what depends on this code)

```
# Find all files that reference this type
Grep pattern="TypeName" glob="*.swift" output_mode="files_with_matches"
```

**Depends on:** [list with file paths]

**Depended on by:** [list with file paths]

---

## Step 7: Explain — Edge Cases & Gotchas

Look for:
- Optional handling (what happens when data is nil?)
- Error paths (what happens when network fails?)
- Boundary conditions (empty lists, maximum values)
- Concurrency considerations (actor isolation, main thread requirements)

| Scenario | Behavior | Notes |
|----------|----------|-------|
| Item has no category | Shows "Uncategorized" | Nil coalescing at ViewModel.swift:34 |
| Network timeout | Shows cached data | Falls back to SwiftData query |
| Empty search results | Shows empty state view | Handled by ContentUnavailableView |

---

## Step 8: Write Report

Write the explanation to `.agents/research/YYYY-MM-DD-explain-{topic}.md` for future reference.

Include a "Quick Reference" section at the end:

```markdown
## Quick Reference

**To modify this feature:** Start at [primary file], the entry point is [function/view]

**To debug issues:** Check [key file:line] where [critical logic happens]

**To add tests:** Mock [protocol] and test [key methods]
```

---

## See Also

- `/implementation-plan` — When you understand the code and want to plan changes
- `/debug` — When explanation reveals a potential bug
- `/safe-refactor` — When explanation shows refactoring opportunities
