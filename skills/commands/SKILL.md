---
name: commands
description: Display list of all available custom commands for this project
version: 2.1.0
author: Terry Nyberg
license: MIT
allowed-tools: [Read]
metadata:
  tier: reference
  category: reference
---

# Available Commands

## Code Analysis & Review

| Command | Version | Description |
|---------|---------|-------------|
| `/tech-talk-reportcard` | 3.0.0 | Technical codebase analysis with A-F grades for developers (architecture, security, performance, concurrency, accessibility, testing). |
| `/plain-talk-reportcard` | 3.0.0 | Codebase analysis with A-F grades and plain-language summaries for non-technical stakeholders. |
| `/codebase-audit` | 2.0.0 | Hybrid codebase audit with automated scans and parallel agent analysis. |
| `/review-changes` | 2.1.0 | Pre-commit review of staged/unstaged changes for bugs, style issues, and missing tests. |
| `/dead-code-scanner` | 2.1.0 | Find unused code after refactors or as ongoing hygiene. Two modes: quick and full. |
| `/workflow-audit` | 2.1.1 | Systematic UI workflow auditing — entry points, flow tracing, dead ends, data wiring. |

## Testing & Debugging

| Command | Version | Description |
|---------|---------|-------------|
| `/run-tests` | 2.1.0 | Run tests with smart strategies: parallel, sequential, or split (UI sequential + unit parallel). |
| `/generate-tests` | 2.1.0 | Generate unit and UI tests for specified code with edge cases and mocks. |
| `/ui-scan` | 2.1.0 | UI test environment setup with accessibility identifier scan and onboarding bypass. |
| `/debug` | 2.1.0 | Systematic debugging workflow: reproduce, isolate, hypothesize, verify, and fix. |
| `/scan-similar-bugs` | 2.1.0 | After fixing a bug, systematically find other occurrences of the same pattern across the codebase. |

## Planning & Refactoring

| Command | Version | Description |
|---------|---------|-------------|
| `/plan` | 1.2.0 | Epic decomposition into trackable tasks. Audit-aware mode ingests report card findings. |
| `/implementation-plan` | 1.1.0 | *(Deprecated — use `/plan` instead)* Structured implementation planning. |
| `/safe-refactor` | 2.2.0 | Plan refactoring with blast radius analysis, dependency mapping, and rollback strategy. |
| `/explain` | 2.1.0 | Deep-dive explanation of how a specific file, feature, or data flow works. |

## Release & Deployment

| Command | Version | Description |
|---------|---------|-------------|
| `/release-prep` | 2.1.0 | Pre-release checklist with version bumps, privacy manifest, code readiness, and metadata checks. |
| `/release-screenshots` | 2.1.0 | Capture App Store screenshots across all required device sizes using simulator automation. |
| `/update-website` | 2.0.1 | Sync website content with app codebase — features, changelog, screenshots, docs. |

## Security & Performance

| Command | Version | Description |
|---------|---------|-------------|
| `/security-audit` | 2.1.0 | Focused security scan covering secrets, storage, network, privacy manifests, and auth. |
| `/performance-check` | 2.1.0 | Profile-guided performance analysis for memory, CPU, energy, SwiftUI, and launch time. |

## Reference

| Command | Version | Description |
|---------|---------|-------------|
| `/commands` | 2.0.0 | Display this list of all available custom commands. |
| `/enhanced-commands` | 2.0.0 | Reference docs with examples and output locations for all commands. |

---

## Notes

- **Platform support:** All commands work for both iOS and macOS Swift projects.
- **Interactive questions:** Analysis commands use `AskUserQuestion` prompts to gather context before scanning.
- **Table format:** All report cards output findings in structured tables for easy scanning.
- **Output files:** Analysis commands write reports to `.agents/research/YYYY-MM-DD-*.md` for future reference.
