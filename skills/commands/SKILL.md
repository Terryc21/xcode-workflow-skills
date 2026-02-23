---
name: commands
description: Display list of all available custom commands for this project
version: 1.0.0
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
| `/tech-talk-reportcard` | 1.0.0 | Technical codebase analysis with A-F grades for developers (architecture, security, performance, testing). |
| `/plain-talk-reportcard` | 1.0.0 | Codebase analysis with A-F grades and plain-language summaries for non-technical stakeholders. |
| `/review-changes` | 1.0.0 | Pre-commit review of staged changes for bugs, style issues, and missing tests. |
| `/dead-code-scanner` | 1.0.0 | Find unused code after refactors or as ongoing hygiene. |

## Testing & Debugging

| Command | Version | Description |
|---------|---------|-------------|
| `/run-tests` | 1.0.0 | Run tests with smart strategies. Supports `--unattended` for hands-off execution. |
| `/generate-tests` | 1.0.0 | Generate unit and UI tests for specified code with edge cases and mocks. |
| `/ui-scan` | 1.0.0 | UI test environment setup with splash/onboarding bypass and accessibility identifier scan. |
| `/debug` | 1.0.0 | Systematic debugging workflow: reproduce, isolate, hypothesize, verify, and fix. |
| `/scan-similar-bugs` | 1.0.0 | After fixing a bug, systematically find other occurrences of the same pattern across the codebase. |

## Planning & Refactoring

| Command | Version | Description |
|---------|---------|-------------|
| `/implementation-plan` | 1.0.0 | Structured implementation planning with file impact analysis, dependencies, and phased tasks. |
| `/safe-refactor` | 1.0.0 | Plan refactoring with blast radius analysis, dependency mapping, and rollback strategy. |
| `/explain` | 1.0.0 | Deep-dive explanation of how a specific file, feature, or data flow works. |

## Release & Deployment

| Command | Version | Description |
|---------|---------|-------------|
| `/release-prep` | 1.0.0 | Pre-release checklist including version bump, changelog, known issues, and store metadata. |
| `/release-screenshots` | 1.0.0 | Capture App Store screenshots across all required device sizes using XcodeBuildMCP. |
| `/update-website` | 2.0.0 | Sync website content with app codebase - features, changelog, screenshots, docs. |

## Security & Performance

| Command | Version | Description |
|---------|---------|-------------|
| `/security-audit` | 1.0.0 | Automated security scan with severity scoring, grep patterns, and remediation examples. |
| `/performance-check` | 1.0.0 | Profile-guided performance analysis for memory, CPU, energy, SwiftUI, and launch time. |

## Reference

| Command | Version | Description |
|---------|---------|-------------|
| `/commands` | 1.0.0 | Display this list of all available custom commands. |
| `/enhanced-commands` | 1.0.0 | Reference docs with parameters, examples, and prompt templates for all commands. |

---

## Report Card Commands

| Command | Audience | Output Style |
|---------|----------|--------------|
| `/tech-talk-reportcard` | Developers | Technical details, code references, Swift patterns |
| `/plain-talk-reportcard` | Non-technical stakeholders | Plain language, user impact focus |

---

## Notes

- **Platform support:** All commands work for both iOS and macOS Swift projects.
- **Interactive questions:** Report card, security audit, and performance check commands use interactive prompts to gather context before analysis.
- **Table format:** All report cards output findings in structured tables for easy scanning.
- **Output files:** Analysis commands write reports to `.agents/research/YYYY-MM-DD-*.md` for future reference.
- **Axiom integration:** For iOS and macOS-specific deep dives, commands invoke Axiom skills where appropriate.

---

## Axiom Integration

These commands complement [Axiom](https://github.com/CharlesWiltgen/Axiom) for iOS-specific patterns:

| This Plugin | Axiom Skills |
|-------------|--------------|
| `/security-audit` | `/axiom:axiom-security-privacy-scanner` |
| `/performance-check` | `/axiom:axiom-swift-performance`, `/axiom:axiom-swiftui-performance` |
| `/debug` | `/axiom:axiom-memory-debugging`, `/axiom:axiom-hang-diagnostics` |
| `/generate-tests` | `/axiom:axiom-swift-testing`, `/axiom:axiom-testing-async` |

For schema migrations, use Axiom directly: `/axiom:axiom-swiftdata-migration`
