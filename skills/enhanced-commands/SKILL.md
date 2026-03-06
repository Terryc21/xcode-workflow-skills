---
name: enhanced-commands
description: Enhanced list of custom Claude commands for iOS and macOS Swift projects with examples and output locations.
version: 2.2.0
author: Terry Nyberg
license: MIT
allowed-tools: [Read]
metadata:
  tier: reference
  category: reference
---

Display the following command reference to the user:

# Enhanced Commands

Commands are grouped by category. Each includes examples and output locations.

## Code Analysis & Review

| Command | Description |
|---------|-------------|
| `/tech-talk-reportcard` | Technical codebase analysis with A-F grades (architecture, security, performance, concurrency, accessibility, etc.) for developers. |
| `/plain-talk-reportcard` | Codebase analysis with A-F grades and plain-language summaries for non-technical stakeholders. |
| `/codebase-audit` | Hybrid codebase audit with automated scans and parallel agent analysis. |
| `/scan-similar-bugs` | Find similar bug patterns codebase-wide after a fix. |
| `/review-changes` | Pre-commit review of staged/unstaged changes for bugs, style, tests. |
| `/dead-code-scanner` | Find unused code after refactors or as ongoing hygiene. |
| `/workflow-audit` | Systematic UI workflow auditing — entry points, flow tracing, dead ends, data wiring. |

**`/tech-talk-reportcard` Details** (v3.0.0)
- Output: `.agents/research/YYYY-MM-DD-tech-reportcard.md`
- Features:
  - Interactive questions (CLAUDE.md inclusion, mode, timeline, focus)
  - Automated grep scans for architecture, security, performance, concurrency, accessibility, testing, energy
  - 9 grading categories: Architecture, Code Quality, Performance, Concurrency, Security, Accessibility, Testing, UI/UX, Data
  - Trend comparison to previous reports (grade changes)
  - Prioritized issues with Urgency/Risk/ROI/Blast ratings

**`/plain-talk-reportcard` Details** (v3.0.0)
- Output: `.agents/research/YYYY-MM-DD-plain-reportcard.md`
- Features:
  - 7 grading categories in plain language: User Experience, Reliability, Accessibility, Security, Performance, Code Health, Testing
  - Trend comparison to previous reports
  - Plain language glossary translates technical terms
  - Effort estimates and risk explanations for each issue

**`/security-audit` Details** (v2.1.0)
- Output: `.agents/research/YYYY-MM-DD-security-audit.md`
- Features: Automated grep patterns, severity scoring (CRITICAL/HIGH/MEDIUM/LOW), remediation code examples, Privacy Manifest validation.

**`/performance-check` Details** (v2.1.0)
- Output: `.agents/research/YYYY-MM-DD-performance-check.md`
- Features: Automated anti-pattern detection, before/after code examples, profiling recommendations.

**`/dead-code-scanner` Details** (v2.1.0)
- Output: `.agents/research/YYYY-MM-DD-dead-code-*.md`
- Features: Quick (post-refactor) or full (hygiene) scan modes, Swift-specific exclusions, confidence classification.

**`/workflow-audit` Details** (v2.1.1)
- Output: `.workflow-audit/` directory in project root
- Features: 5-layer analysis (discovery, trace, issues, evaluation, data wiring), issue categories with severity, design principle validation.

## Planning & Refactoring

| Command | Description |
|---------|-------------|
| `/plan` | Epic decomposition into trackable tasks. Audit-aware or standalone mode. |
| `/implementation-plan` | *(Deprecated — use `/plan`)* Structured implementation planning. |
| `/safe-refactor` | Refactor plan with blast radius, deps, rollback. |

**`/plan` Details** (v1.2.0)
- Output: `.agents/research/YYYY-MM-DD-implementation-plan.md`
- Features: Auto-detects audit reports for audit-aware mode, T-shirt sizing, Golden Rule (WHAT not HOW), phased task lists with Urgency/Risk/ROI/Blast ratings, rollback strategy.

## Debugging & Testing

| Command | Description |
|---------|-------------|
| `/debug` | Systematic debug: reproduce, isolate, hypothesize, fix. |
| `/generate-tests` | Unit/UI tests with edges, mocks. Auto-detects Swift Testing vs XCTest. |
| `/run-tests` | Smart test execution with split strategies (UI sequential + unit parallel). |
| `/ui-scan` | Accessibility identifier scan and UI test environment setup. |
| `/scan-similar-bugs` | After fixing a bug, find the same pattern across the codebase. |

**`/debug` Details** (v2.1.0)
- Output: `.agents/research/YYYY-MM-DD-debug-*.md`
- Features: Concrete evidence-gathering (git log, grep patterns), common iOS bug pattern checklist, hypothesis table, root cause report, similar bug scan integration.

**`/generate-tests` Details** (v2.1.0)
- Features: Auto-detects test framework (Swift Testing or XCTest), generates mocks, covers edge cases, parameterized test support.

**`/run-tests` Details** (v2.1.0)
- Features: Smart split strategy (UI sequential + unit parallel), all sequential, all parallel, or unit-only modes.

## Release & Deployment

| Command | Description |
|---------|-------------|
| `/release-prep` | Pre-release checklist: version, changelog, privacy, metadata, code readiness. |
| `/release-screenshots` | Capture App Store screenshots across all required device sizes. |
| `/update-website` | Sync website content with app codebase. |
| `/explain` | Deep-dive on file/feature/data flow. |

**`/release-prep` Details** (v2.1.0)
- Output: `.agents/research/YYYY-MM-DD-release-prep-vX.Y.Z.md`
- Features: Automated version bump, changelog generation, privacy manifest validation, deployment target check, ATS check, entitlements check, app icon validation, localization completeness.

**`/release-screenshots` Details** (v2.1.0)
- Features: Multi-device capture (6.9", 6.5", 5.5"), status bar override, organized folder output, device frame support.

## Interactive Features

All analysis commands include:

1. **Interactive Questions**: Use `AskUserQuestion` tool to gather context before analysis
2. **Table Format Output**: All findings presented in structured tables
3. **Output Files**: Reports saved to `.agents/research/` for future reference
4. **Follow-up Actions**: Option to generate implementation plans or fixes from findings

## Notes

- **Execution directives**: All workflow skills include "YOU MUST EXECUTE THIS WORKFLOW" to ensure action, not just description.
- **Output standardization**: Analysis skills write to `.agents/research/YYYY-MM-DD-*.md`.
