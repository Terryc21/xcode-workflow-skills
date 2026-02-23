---
name: enhanced-commands
description: Enhanced list of custom Claude commands for iOS and macOS Swift projects with detailed prompts, parameters, and examples.
version: 1.0.0
author: Terry Nyberg
license: MIT
allowed-tools: [Read]
metadata:
  tier: reference
  category: reference
---

Display the following command reference to the user:

# Enhanced Commands

Commands are grouped by category for easier navigation. Each includes:
- **Parameters**: Required/optional flags.
- **Example**: Sample usage.
- **Output**: Where results are saved.

## Code Analysis & Review

| Command | Description |
|---------|-------------|
| `/tech-talk-reportcard` | Technical codebase analysis with A-F grades (architecture, security, performance, etc.) for developers. |
| `/plain-talk-reportcard` | Codebase analysis with A-F grades and plain-language summaries for non-technical stakeholders. |
| `/scan-similar-bugs` | Find similar bug patterns codebase-wide after a fix. |
| `/review-changes` | Pre-commit review of staged changes for bugs, style, tests. |
| `/dead-code-scanner` | Find unused code after refactors or as ongoing hygiene. |

**`/tech-talk-reportcard` Details**
- Parameters: `[path]` (default: entire repo), `--focus=security`
- Example: `/tech-talk-reportcard Sources/ --focus=performance`
- Output: `.agents/research/YYYY-MM-DD-tech-reportcard.md`
- Features: Interactive questions before analysis, table-formatted output, prioritized issues with Urgency/Risk/ROI ratings.

**`/security-audit` Details**
- Parameters: `--quick` (surface only), `--focus=secrets|storage|network|privacy`
- Example: `/security-audit --focus=secrets`
- Output: `.agents/research/YYYY-MM-DD-security-audit.md`
- Features: Automated grep patterns, severity scoring (CRITICAL/HIGH/MEDIUM/LOW), remediation code examples, Privacy Manifest validation.

**`/performance-check` Details**
- Parameters: `--quick` (surface only), `--focus=memory|cpu|energy|swiftui|launch`
- Example: `/performance-check --focus=memory`
- Output: `.agents/research/YYYY-MM-DD-performance-check.md`
- Features: Automated anti-pattern detection, Instruments integration suggestions, before/after code examples.

**`/dead-code-scanner` Details**
- Parameters: `quick` (recent changes), `full` (entire codebase), `remove` (with verification)
- Example: `/dead-code quick`, `/dead-code remove --verify-with-tests`
- Output: `.agents/research/YYYY-MM-DD-dead-code-*.md`
- Features: Build + test verification before removal, allowlist support, false positive tracking.

## Planning & Refactoring

| Command | Description |
|---------|-------------|
| `/implementation-plan` | Implementation planning with file impacts, deps, phases, and interactive questions. |
| `/safe-refactor` | Refactor plan with blast radius, deps, rollback. |

**`/implementation-plan` Details**
- Parameters: `feature-name`, `--phase=1`
- Example: `/implementation-plan user-auth --phase=1`
- Features: Interactive questions for work type/risk/timeline, table-formatted impact analysis, phased task lists, risk assessment, rollback strategy.

## Debugging & Testing

| Command | Description |
|---------|-------------|
| `/debug` | Systematic debug: reproduce, isolate, hypothesize, fix. |
| `/generate-tests` | Unit/UI tests with edges, mocks. Auto-detects Swift Testing vs XCTest. |
| `/run-tests` | Smart test runs, supports `--unattended`. |
| `/ui-scan` | UI setup with onboarding bypass, accessibility scan. |

**`/debug` Details**
- Parameters: `issue-description`, `[file]`
- Example: `/debug "Crash on login" AuthView.swift`
- Features: Hypothesis table, root cause analysis, similar bug scan integration.

**`/generate-tests` Details**
- Parameters: `TypeName` or `path/to/File.swift`, `--ui` for UI tests
- Example: `/generate-tests ItemViewModel`, `/generate-tests --ui ItemListView`
- Features: Auto-detects test framework (Swift Testing or XCTest), generates mocks, covers edge cases.

**`/run-tests` Details**
- Parameters: `--split` (UI sequential + unit parallel), `--sequential`, `--parallel`, `--unattended`
- Example: `/run-tests --unattended --cleanup`
- Features: Smart split strategy for stability, unattended mode for hands-off execution.

## Release & Deployment

| Command | Description |
|---------|-------------|
| `/release-prep` | Checklist: version, changelog, metadata. |
| `/release-screenshots` | Capture App Store screenshots across all required device sizes. |
| `/update-website` | Sync website content with app codebase. |
| `/explain` | Deep-dive on file/feature/data flow. |

**`/release-prep` Details**
- Parameters: `--bump=major|minor|patch`
- Example: `/release-prep --bump=minor`
- Features: Version bump, changelog generation, App Store metadata checklist.

**`/release-screenshots` Details**
- Parameters: (interactive)
- Example: `/release-screenshots`
- Features: Multi-device capture (6.9", 6.5", 5.5"), status bar override, organized folder output.

## Interactive Features

All analysis commands include:

1. **Interactive Questions**: Use `AskUserQuestion` tool to gather context before analysis
2. **Table Format Output**: All findings presented in structured tables
3. **Output Files**: Reports saved to `.agents/research/` for future reference
4. **Follow-up Actions**: Option to generate implementation plans or fixes from findings

## Axiom Integration

For iOS-specific deep dives, commands invoke Axiom skills:

| Command | Axiom Skills Invoked |
|---------|---------------------|
| `/security-audit` | `axiom-security-privacy-scanner`, `axiom-storage`, `axiom-networking` |
| `/performance-check` | `axiom-swift-performance`, `axiom-swiftui-performance`, `axiom-memory-debugging`, `axiom-energy` |
| `/debug` | `axiom-memory-debugging`, `axiom-hang-diagnostics`, `axiom-swiftui-debugging` |
| `/generate-tests` | `axiom-swift-testing`, `axiom-testing-async`, `axiom-xctest-automation` |

For schema migrations, use Axiom directly: `/axiom:axiom-swiftdata-migration`

## Notes

- **Execution directives**: All workflow skills include "YOU MUST EXECUTE THIS WORKFLOW" to ensure action, not just description.
- **Validation**: All prompts check inputs (e.g., "If no path, scan repo root").
- **Output standardization**: Analysis skills write to `.agents/research/YYYY-MM-DD-*.md`.
