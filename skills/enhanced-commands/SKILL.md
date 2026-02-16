---
name: enhanced-commands
description: Enhanced list of custom Claude commands for Stuffolio iOS project with detailed prompts, parameters, and examples.
---

Display the following command reference to the user:

# Enhanced Stuffolio Commands

Commands are grouped by category for easier navigation. Each includes:
- **Parameters**: Required/optional flags.
- **Example**: Sample usage.
- **Prompt Template**: Core Claude instruction (copy to sub-files for modularity).

## Code Analysis & Review
| Command | Description |
|---------|-------------|
| `/tech-talk-reportcard` | Technical codebase analysis with A-F grades (architecture, security, performance, etc.) for developers. |
| `/plain-talk-reportcard` | Codebase analysis with A-F grades and plain-language summaries for non-technical stakeholders. |
| `/scan-similar-bugs` | Find similar bug patterns codebase-wide after a fix. |
| `/review-changes` | Pre-commit review of staged changes for bugs, style, tests. |

**`/tech-talk-reportcard` Details**
- Parameters: `[path]` (default: entire repo), `--focus=security`
- Example: `/tech-talk-reportcard Sources/ --focus=performance`
- Features: Interactive questions before analysis, table-formatted output, prioritized issues with Urgency/Risk/ROI ratings.

**`/plain-talk-reportcard` Details**
- Parameters: none
- Example: `/plain-talk-reportcard`
- Features: Interactive questions, plain-language explanations, action items explained for non-technical stakeholders. Optionally generates `/implementation-plan`.

## Planning & Refactoring
| Command | Description |
|---------|-------------|
| `/implementation-plan` | Implementation planning with file impacts, deps, phases, and interactive questions. |
| `/safe-refactor` | Refactor plan with blast radius, deps, rollback. |
| `/migrate-schema` | SwiftData migration with data preservation. |

**`/implementation-plan` Details**
- Parameters: `feature-name`, `--phase=1`
- Example: `/implementation-plan user-auth --phase=1`
- Features: Interactive questions for work type/risk/timeline, table-formatted impact analysis, phased task lists, risk assessment, rollback strategy.

## Debugging & Testing
| Command | Description |
|---------|-------------|
| `/debug` | Systematic debug: reproduce, isolate, hypothesize, fix. |
| `/generate-tests` | Unit/UI tests with edges, mocks. |
| `/run-tests` | Smart test runs, supports `--unattended`. |
| `/ui-scan` | UI setup with onboarding bypass, accessibility scan. |

**`/debug` Details**
- Parameters: `issue-description`, `[file]`
- Example: `/debug "Crash on login" AuthView.swift`
- Prompt Template: "Debug [issue] in [file]: 1. Reproduce steps. 2. Isolate (logs, breakpoints). 3. Hypothesize causes. 4. Verify fix. Output structured steps + code patch."

## Security & Performance
| Command | Description |
|---------|-------------|
| `/security-audit` | Scan API keys, storage, network, privacy. |
| `/performance-check` | Profile memory/CPU/energy/launch. |

**`/security-audit` Details**
- Parameters: `--quick` (surface only)
- Example: `/security-audit`
- Prompt Template: "Audit Stuffolio for: hardcoded keys, insecure storage, network (TLS), permissions, Info.plist privacy. List findings, severity (CVSS), fixes. Cross-check with App Privacy manifest."

## Release & Explain
| Command | Description |
|---------|-------------|
| `/release-prep` | Checklist: version, changelog, metadata. |
| `/explain` | Deep-dive on file/feature/data flow. |
| `/commands` | Show this list. |

**`/release-prep` Details**
- Parameters: `--bump=major`
- Example: `/release-prep --bump=minor`
- Prompt Template: "Prep Stuffolio release: Bump version [bump], generate changelog from git, list known issues, update store metadata. Output checklist Markdown."

## Interactive Features

All report card and implementation plan commands now include:

1. **Interactive Questions**: Use `AskUserQuestion` tool to gather context before analysis
2. **Table Format Output**: All findings presented in structured tables
3. **Follow-up Actions**: Option to generate implementation plans from report card findings

## Notes
- **Modular Use**: Save each "Details" section as `[command].md` for direct Claude loading.
- **Swift 6.2**: `/migrate-schema` invokes `/axiom` for concurrency.
- **Validation**: All prompts check inputs (e.g., "If no path, scan repo root").
- **Extensibility**: Use `/axiom` for iOS patterns. Add `/validate-skills` meta-command: "Test all commands on sample code."
