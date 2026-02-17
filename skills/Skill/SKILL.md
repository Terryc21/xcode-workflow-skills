---
name: commands
description: Display list of all available custom commands for this project
---

# Available Commands

| Command | Description |
|---------|-------------|
| `/commands` | Display this list of all available custom commands. |
| `/tech-talk-reportcard` | Technical codebase analysis with A-F grades for developers (architecture, security, performance, testing). |
| `/plain-talk-reportcard` | Codebase analysis with A-F grades and plain-language summaries for non-technical stakeholders. |
| `/implementation-plan` | Structured implementation planning with file impact analysis, dependencies, and phased tasks. |
| `/scan-similar-bugs` | After fixing a bug, systematically find other occurrences of the same pattern across the codebase. |
| `/review-changes` | Pre-commit review of staged changes for bugs, style issues, and missing tests. |
| `/debug` | Systematic debugging workflow: reproduce, isolate, hypothesize, verify, and fix. |
| `/safe-refactor` | Plan refactoring with blast radius analysis, dependency mapping, and rollback strategy. |
| `/generate-tests` | Generate unit and UI tests for specified code with edge cases and mocks. |
| `/security-audit` | Focused security scan covering API keys, storage, network, permissions, and privacy manifest. |
| `/performance-check` | Profile-guided performance analysis for memory, CPU, energy, and launch time. |
| `/migrate-schema` | Safe SwiftData/model migration planning with data preservation and rollback strategy. |
| `/explain` | Deep-dive explanation of how a specific file, feature, or data flow works. |
| `/release-prep` | Pre-release checklist including version bump, changelog, known issues, and store metadata. |
| `/release-screenshots` | Capture App Store screenshots across all required device sizes using XcodeBuildMCP. |
| `/ui-scan` | UI test environment setup with splash/onboarding bypass and accessibility identifier scan. |
| `/run-tests` | Run tests with smart strategies. Supports `--unattended` for hands-off execution. |
| `/enhanced-commands` | Reference docs with parameters, examples, and prompt templates for all commands. |

## Report Card Commands

| Command | Audience | Output Style |
|---------|----------|--------------|
| `/tech-talk-reportcard` | Developers | Technical details, code references, Swift patterns |
| `/plain-talk-reportcard` | Non-technical stakeholders | Plain language, user impact focus |

## Notes

- **Platform support:** All commands work for both iOS and macOS Swift projects.
- **Interactive questions:** Report card and implementation plan commands use interactive prompts to gather context before analysis.
- **Table format:** All report cards output findings in structured tables for easy scanning.
- **Swift 6.2 migrations:** The `/migrate-schema` command will invoke `/axiom` for Swift concurrency guidance.
- **Axiom skills:** For iOS and macOS-specific patterns beyond these commands, use `/axiom` directly.

## Acknowledgments

These commands integrate with [Axiom](https://github.com/codeium/axiom) for iOS and macOS development patterns. Axiom provides 100+ specialized skills covering SwiftUI, SwiftData, concurrency, performance profiling, and Apple platform best practices.
