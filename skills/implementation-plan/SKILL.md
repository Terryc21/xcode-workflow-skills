---
name: implementation-plan
description: Structured implementation planning with file impact analysis, dependencies, and phased tasks
version: 1.0.0
author: Terry Nyberg
license: MIT
allowed-tools: [Glob, Grep, Read, AskUserQuestion]
metadata:
  tier: analysis
  category: refactoring
---

# Implementation Plan Generator

**Required output:** Every task/issue MUST include Urgency, Risk, ROI, and Blast Radius ratings. Do not omit these ratings.

Create detailed implementation plans with impact analysis, phased tasks, and risk assessment.

## Step 1: Interactive Input

**IMPORTANT**: Use `AskUserQuestion` to gather requirements:

```
AskUserQuestion with questions:
[
  {
    "question": "What type of work are you planning?",
    "header": "Work Type",
    "options": [
      {"label": "New feature", "description": "Adding new functionality to the app"},
      {"label": "Bug fix / improvement", "description": "Fixing issues or enhancing existing features"},
      {"label": "Refactoring", "description": "Restructuring code without changing behavior"},
      {"label": "Report card items", "description": "Implementing recommendations from a report card"}
    ],
    "multiSelect": false
  },
  {
    "question": "What is your risk tolerance?",
    "header": "Risk",
    "options": [
      {"label": "Conservative", "description": "Minimize risk, smaller incremental changes"},
      {"label": "Balanced", "description": "Reasonable risk for reasonable gains"},
      {"label": "Aggressive", "description": "Accept higher risk for faster delivery"}
    ],
    "multiSelect": false
  },
  {
    "question": "What is your timeline?",
    "header": "Timeline",
    "options": [
      {"label": "Urgent (days)", "description": "Must ship this week"},
      {"label": "Normal (1-2 weeks)", "description": "Standard development cycle"},
      {"label": "Flexible (weeks+)", "description": "No immediate deadline"}
    ],
    "multiSelect": false
  }
]
```

Wait for responses, then ask for the feature/task description if not already provided.

---

## Step 2: Understanding Phase

After gathering input, produce:

### Feature Summary Table

| Aspect | Details |
|--------|---------|
| **What** | [Restate the feature/task in your own words] |
| **Why** | [User benefit or business value] |
| **Scope** | [What's included and excluded] |

### User Stories Table

| # | As a... | I want... | So that... |
|---|---------|-----------|------------|
| 1 | [user type] | [capability] | [benefit] |
| 2 | [user type] | [capability] | [benefit] |

### Acceptance Criteria Table

| # | Criterion | How to Verify |
|---|-----------|---------------|
| 1 | [What must be true] | [Test or check] |
| 2 | [What must be true] | [Test or check] |

---

## Step 3: Codebase Analysis

Scan the codebase and produce:

### Related Code Table

| File/Module | Relevance | Notes |
|-------------|-----------|-------|
| [path] | High/Med/Low | [How it relates] |

### Patterns to Follow Table

| Pattern | Example Location | Apply To |
|---------|------------------|----------|
| [Pattern name] | [File path] | [Where to use] |

### Dependencies Table

| This Feature Depends On | Type |
|-------------------------|------|
| [Module/file] | Required/Optional |

| This Feature Will Affect | Impact |
|--------------------------|--------|
| [Module/file] | High/Med/Low |

---

## Step 4: Impact Analysis Table

| Area | Files Affected | Risk Level | Notes |
|------|----------------|------------|-------|
| Models | [list] | High/Med/Low | [details] |
| ViewModels | [list] | High/Med/Low | [details] |
| Views | [list] | High/Med/Low | [details] |
| Services/Managers | [list] | High/Med/Low | [details] |
| Tests | [list] | High/Med/Low | [details] |

---

## Step 5: Implementation Plan Table

| Phase | Task | Files | Risk | Depends On |
|-------|------|-------|------|------------|
| A: Foundation | [Task 1] | [files] | Low | - |
| A: Foundation | [Task 2] | [files] | Low | Task 1 |
| B: Core Logic | [Task 3] | [files] | Med | Phase A |
| B: Core Logic | [Task 4] | [files] | Med | Task 3 |
| C: UI Integration | [Task 5] | [files] | Med | Phase B |
| C: UI Integration | [Task 6] | [files] | Low | Task 5 |
| D: Polish | [Task 7] | [files] | Low | Phase C |
| D: Polish | [Task 8] | [files] | Low | - |

---

## Step 6: Risk Assessment Table

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk description] | High/Med/Low | High/Med/Low | [How to mitigate] |

---

## Step 7: Test Plan Table

| Test Type | What to Test | Priority |
|-----------|--------------|----------|
| Unit | [Functionality] | High/Med/Low |
| Integration | [Functionality] | High/Med/Low |
| UI | [Functionality] | High/Med/Low |

---

## Step 8: Rollback Strategy Table

| Scenario | Rollback Action |
|----------|-----------------|
| [What could go wrong] | [How to undo] |

---

## Step 9: Clarifying Questions

If anything is unclear, use `AskUserQuestion` before finalizing:

```
AskUserQuestion with questions:
[
  {
    "question": "[Specific question about scope/behavior]",
    "header": "Scope",
    "options": [
      {"label": "[Option A]", "description": "[What this means]"},
      {"label": "[Option B]", "description": "[What this means]"}
    ],
    "multiSelect": false
  }
]
```

---

## Step 10: Final Deliverables Summary

| Deliverable | Status |
|-------------|--------|
| Feature specification | ✅ Complete |
| File-by-file plan | ✅ Complete |
| Phased task list | ✅ Complete |
| Test plan | ✅ Complete |
| Rollback strategy | ✅ Complete |

---

## Step 11: Ready to Proceed?

Use `AskUserQuestion` to confirm:

```
AskUserQuestion with questions:
[
  {
    "question": "How would you like to proceed?",
    "header": "Action",
    "options": [
      {"label": "Start Phase A", "description": "Begin implementation with foundation tasks"},
      {"label": "Refine the plan", "description": "Discuss or adjust before starting"},
      {"label": "Save for later", "description": "Keep plan but don't start now"}
    ],
    "multiSelect": false
  }
]
```
