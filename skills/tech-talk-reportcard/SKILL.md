---
name: tech-talk-reportcard
description: Technical codebase analysis with A-F grades for architecture, security, performance, code quality, UI, testing, and tooling
version: 1.0.0
author: Terry Nyberg
license: MIT
allowed-tools: [Task, Glob, Grep, Read, AskUserQuestion]
metadata:
  tier: analysis
  category: analysis
---

# Tech-Talk Report Card Generator

**Required output:** Every issue/finding MUST include Urgency, Risk, ROI, and Blast Radius ratings. Do not omit these ratings.

Generate a comprehensive technical report card for developers and technical stakeholders.

## Step 1: Initial Question

**IMPORTANT**: Before reading any files, ask the user about CLAUDE.md:

```
AskUserQuestion with questions:
[
  {
    "question": "Should the analysis consider CLAUDE.md project instructions?",
    "header": "CLAUDE.md",
    "options": [
      {"label": "Yes, use CLAUDE.md (Recommended)", "description": "Include project context, coding standards, and preferences from CLAUDE.md"},
      {"label": "No, ignore CLAUDE.md", "description": "Perform unbiased analysis without project-specific instructions - useful for fresh perspective or when CLAUDE.md may contain outdated guidance"}
    ],
    "multiSelect": false
  }
]
```

**If user selects "Yes":** Read CLAUDE.md at the repo root and summarize its key points in 3-5 bullets. Use these guidelines throughout the analysis.

**If user selects "No":** Skip reading CLAUDE.md entirely. Analyze the codebase purely on its technical merits without project-specific context. Note in the report that CLAUDE.md was intentionally excluded.

Invoke `/axiom` for iOS and macOS-specific analysis patterns.

## Step 2: Codebase Exploration

Scan the project structure and key configuration files (targets, schemes, build settings, dependencies). Analyze:

1. **Architecture & modules** - Main modules, patterns (MVC/MVVM/etc.), frameworks, data flows
2. **App purpose & features** - Purpose and primary user flows
3. **Data flow & state management** - How state is managed between layers
4. **Code health & technical debt** - Code smells, duplicate logic, tightly coupled components
5. **Performance, concurrency, security** - Issues around networking, persistence, background work
6. **APIs & compatibility** - Risky or outdated APIs
7. **Tests** - Coverage and organization, top 5 areas needing tests
8. **Platform-specific concerns** - Worker.js and non-Swift components

## Step 3: Interactive Questions

**IMPORTANT**: After initial scan, use `AskUserQuestion` to gather context:

```
AskUserQuestion with questions:
[
  {
    "question": "How would you like to run this analysis?",
    "header": "Mode",
    "options": [
      {"label": "Fast (parallel)", "description": "5 agents run simultaneously - faster, but will prompt for permissions"},
      {"label": "Quiet (sequential)", "description": "Single agent, fewer prompts - takes longer"}
    ],
    "multiSelect": false
  },
  {
    "question": "What is your primary testing priority right now?",
    "header": "Testing",
    "options": [
      {"label": "UI test stability", "description": "Focus on App Store submission readiness"},
      {"label": "Unit test coverage", "description": "Expand coverage for ViewModels and business logic"},
      {"label": "Both equally", "description": "Balance UI stability and unit test expansion"}
    ],
    "multiSelect": false
  },
  {
    "question": "Have you noticed any specific performance issues?",
    "header": "Performance",
    "options": [
      {"label": "No issues noticed", "description": "App feels responsive, no warnings"},
      {"label": "Slow loading", "description": "Dashboard or lists take time to load"},
      {"label": "Photo operations", "description": "Slowdowns with photos"},
      {"label": "Memory growth", "description": "Memory increases over time"}
    ],
    "multiSelect": true
  },
  {
    "question": "What is the backend status?",
    "header": "Backend",
    "options": [
      {"label": "Deployed and stable", "description": "Live with no known issues"},
      {"label": "Known issues exist", "description": "Rate limiting or API problems"},
      {"label": "Not deployed yet", "description": "Still in development"},
      {"label": "No backend", "description": "App is standalone"}
    ],
    "multiSelect": false
  },
  {
    "question": "What is your timeline for this audit?",
    "header": "Timeline",
    "options": [
      {"label": "Pre-release", "description": "Preparing for App Store - urgency matters"},
      {"label": "Post-release", "description": "App is live, ongoing improvement"},
      {"label": "Planning phase", "description": "Gathering info for roadmap"}
    ],
    "multiSelect": false
  },
  {
    "question": "Is there anything specific you want included in the report?",
    "header": "Custom Focus",
    "options": [
      {"label": "Standard analysis", "description": "Cover all default categories"},
      {"label": "Yes, I have specific areas", "description": "I'll describe what I want in 'Other'"}
    ],
    "multiSelect": false
  }
]
```

If user selects "Yes, I have specific areas", incorporate their custom request into the analysis.

Wait for user responses before presenting findings.

## Step 4: Analysis Mode

Based on the user's "Mode" selection:

**Fast (parallel):** Launch 5 Task agents simultaneously with `subagent_type: Explore`:
- Architecture & Technical Debt
- Security Analysis
- Test Coverage Gaps
- Performance & Concurrency
- Backend (if applicable)

**Quiet (sequential):** Use direct `Read`, `Glob`, `Grep` tools in sequence:
1. Read CLAUDE.md (if not ignored) and key config files
2. Glob for file counts (`**/*.swift`, `**/Tests/**/*.swift`)
3. Grep for patterns (god classes, deprecated APIs, security markers)
4. Read sample files from each category
5. Compile findings without subagents

## Step 5: Output Format

### CLAUDE.md Summary (if included)
- Bullet 1
- Bullet 2
- Bullet 3

*If CLAUDE.md was ignored, display instead:*
> **Note:** CLAUDE.md was excluded from this analysis per user request. Findings are based purely on technical assessment without project-specific context.

### Project Metrics

```
**Swift Files:** 142 | **LOC:** ~28k | **Architecture:** MVVM | **Persistence:** SwiftData
**Unit Tests:** 47 | **UI Tests:** 12
```

### Grade Summary Line

```
**Overall: B+** (Architecture A- | Code Quality B+ | Performance B | Security A | UI B+ | Testing C+ | Tooling A-)
```

### Grades with Technical Details

Present each category as a heading with grade, then technical bullet points:

```
### Architecture: A-
Clean MVVM with proper separation of concerns.
- ViewModels use `@MainActor` correctly for SwiftData access
- Dependency injection via protocols enables testability
- Some ViewModels exceed 600 lines (refactor candidates)

### Code Quality: B+
Consistent patterns with minor debt.
- MARK sections used consistently
- A few `force unwrap` usages in legacy code
- Extension naming follows `Type+Extension.swift` convention

### Performance: B
Generally responsive with optimization opportunities.
- Image loading happens on background queue
- Some `@Query` fetches lack predicates (full table scans)
- No signposts for launch profiling

### Security: A
Strong security posture.
- Keychain used for tokens
- No hardcoded API keys
- Privacy manifest present and current

### Testing: C+
Coverage gaps in critical paths.
- Unit tests cover 47 ViewModels
- UI tests exist but some are flaky
- No tests for CloudKit sync logic
```

### Technical Debt **[HIGH]** **[MED]** **[LOW]**

Use severity tags inline:

```
**[HIGH]** `ItemListViewModel.swift` (892 lines) — God class handling list, search, and filtering
**[HIGH]** Missing error handling in `CloudSyncManager.syncAll()` — Silent failures
**[MED]** Deprecated `UIApplication.shared.keyWindow` usage in 3 files
**[MED]** Inconsistent date formatting (mix of ISO8601 and custom)
**[LOW]** Some preview code uses hardcoded strings instead of `Item.preview`
```

### Prioritized Issues

```
**1. ItemListViewModel refactor** — Urgency: High | Risk: Med | ROI: High | Blast: 8 files
   Split into ItemListViewModel, SearchViewModel, FilterViewModel

**2. CloudKit error handling** — Urgency: High | Risk: High | ROI: High | Blast: 3 files
   Add proper error propagation and user-facing messages

**3. Deprecated API cleanup** — Urgency: Med | Risk: Low | ROI: Med | Blast: 3 files
   Replace keyWindow with connectedScenes pattern
```

### Next Steps

```
### Immediate
**Fix CloudKit error handling** — Add try/catch and user alerts for sync failures
**Add loading states** — ItemListView shows spinner during fetch

### Short-term
**Refactor ItemListViewModel** — Split into focused ViewModels under 400 lines
**Add sync tests** — Cover CloudKit operations with mocked containers

### Medium-term
**Performance profiling** — Add signposts and run Time Profiler
**Increase unit test coverage** — Target 80% for ViewModels
```

## Step 6: Follow-up Question

After presenting the report, use `AskUserQuestion`:

```
AskUserQuestion with questions:
[
  {
    "question": "Would you like me to create an implementation plan?",
    "header": "Next Steps",
    "options": [
      {"label": "Yes, plan immediate items", "description": "Detailed plan for high-priority actions"},
      {"label": "Yes, plan all items", "description": "Comprehensive implementation roadmap"},
      {"label": "No, report is sufficient", "description": "End here"}
    ],
    "multiSelect": false
  }
]
```

If user selects yes, invoke `/implementation-plan` with the selected items.

---

## Output

Write the report card to `.agents/research/YYYY-MM-DD-tech-reportcard.md` for future reference.

---

## See Also

- `/plain-talk-reportcard` - Non-technical version for stakeholders
- `/performance-check` - Deeper performance analysis
- `/security-audit` - Deeper security analysis

---

## Acknowledgments

This command integrates with [Axiom](https://github.com/codeium/axiom) for iOS and macOS development analysis patterns.
