# Claude Code Custom Commands Reference

Generated: 2026-02-23
Plugin Version: 2.0.0

This document contains the full prompts for all custom commands in the xcode-workflow-skills plugin.

---

## Table of Contents

| Command | Version | Description |
|---------|---------|-------------|
| [/commands](#commands) | 1.0.0 | Display list of all available custom commands |
| [/enhanced-commands](#enhanced-commands) | 2.0.0 | Detailed reference with parameters and examples |
| [/tech-talk-reportcard](#tech-talk-reportcard) | 2.0.0 | Technical codebase analysis with A-F grades |
| [/plain-talk-reportcard](#plain-talk-reportcard) | 2.0.0 | Plain-language analysis for stakeholders |
| [/scan-similar-bugs](#scan-similar-bugs) | 1.0.0 | Find other occurrences of a bug pattern |
| [/review-changes](#review-changes) | 1.0.0 | Pre-commit review of staged changes |
| [/dead-code-scanner](#dead-code-scanner) | 1.0.0 | Find unused code in the codebase |
| [/implementation-plan](#implementation-plan) | 1.0.0 | Structured feature planning |
| [/safe-refactor](#safe-refactor) | 1.0.0 | Plan refactoring with blast radius analysis |
| [/debug](#debug) | 1.0.0 | Systematic debugging workflow |
| [/explain](#explain) | 1.0.0 | Deep-dive explanation of code or features |
| [/generate-tests](#generate-tests) | 1.0.0 | Generate unit and UI tests |
| [/run-tests](#run-tests) | 1.0.0 | Run tests with smart execution strategies |
| [/ui-scan](#ui-scan) | 1.0.0 | UI test environment setup and accessibility scan |
| [/security-audit](#security-audit) | 1.0.0 | Security scan for API keys, storage, network |
| [/performance-check](#performance-check) | 1.0.0 | Performance analysis for memory, CPU, energy |
| [/release-prep](#release-prep) | 1.0.0 | Pre-release checklist |
| [/release-screenshots](#release-screenshots) | 1.0.0 | Capture App Store screenshots |
| [/update-website](#update-website) | 2.0.0 | Sync website content with app codebase |

---

## Axiom Integration

These commands complement [Axiom](https://github.com/CharlesWiltgen/Axiom) for iOS-specific patterns:

| Command | Axiom Skills |
|---------|--------------|
| `/tech-talk-reportcard` | `axiom-swiftui-architecture`, `axiom-ios-performance`, `axiom-ios-concurrency`, `axiom-ios-accessibility`, `axiom-ios-testing` |
| `/plain-talk-reportcard` | `axiom-ios-accessibility`, `axiom-ios-ui`, `axiom-hig` |
| `/security-audit` | `axiom-storage-diag`, `axiom-file-protection-ref` |
| `/performance-check` | `axiom-swift-performance`, `axiom-swiftui-performance`, `axiom-ios-performance` |
| `/debug` | `axiom-memory-debugging`, `axiom-hang-diagnostics` |
| `/generate-tests` | `axiom-swift-testing`, `axiom-testing-async` |

For schema migrations, use Axiom directly: `/axiom:axiom-swiftdata-migration`

---

# /commands

**Version:** 1.0.0
**Description:** Display list of all available custom commands

See: `skills/commands/SKILL.md`

---

# /enhanced-commands

**Version:** 2.0.0
**Description:** Detailed reference with parameters, examples, and prompt templates

See: `skills/enhanced-commands/SKILL.md`

---

# /tech-talk-reportcard

**Version:** 2.0.0
**Description:** Technical codebase analysis with A-F grades for architecture, security, performance, concurrency, accessibility, code quality, UI, testing, and tooling

**Features:**
- Interactive questions (CLAUDE.md inclusion, mode, timeline, focus)
- Automated grep scans for 7 categories
- 9 grading categories with weighted scoring
- Trend comparison to previous reports
- Deep dive option invoking Axiom skills
- Output to `.agents/research/YYYY-MM-DD-tech-reportcard.md`

See: `skills/tech-talk-reportcard/SKILL.md`

---

# /plain-talk-reportcard

**Version:** 2.0.0
**Description:** Codebase analysis with A-F grades and plain-language summaries for non-technical stakeholders

**Features:**
- 7 grading categories in plain language
- Effort estimates for each issue
- Risk explanations in non-technical terms
- Plain language glossary
- Recommended action timeline
- Output to `.agents/research/YYYY-MM-DD-plain-reportcard.md`

See: `skills/plain-talk-reportcard/SKILL.md`

---

# /scan-similar-bugs

**Version:** 1.0.0
**Description:** After fixing a bug, systematically find other occurrences of the same pattern

**Features:**
- Bug classification by category
- Root cause and invariant analysis
- Multi-layer search patterns
- Output to `.agents/research/YYYY-MM-DD-similar-bugs-*.md`

See: `skills/scan-similar-bugs/SKILL.md`

---

# /review-changes

**Version:** 1.0.0
**Description:** Pre-commit review of staged changes for bugs, style issues, and missing tests

**Checklist categories:**
- Correctness (logic errors, nil safety, race conditions)
- Consistency (patterns, naming, duplication)
- Security (secrets, input validation)
- Performance (main thread, N+1 queries)
- SwiftUI specific (@State, view rebuilds)
- Test coverage

See: `skills/review-changes/SKILL.md`

---

# /dead-code-scanner

**Version:** 1.0.0
**Description:** Find unused code after refactors or as ongoing hygiene

**Features:**
- Quick mode (recent changes) or full mode (entire codebase)
- Build + test verification before removal
- Allowlist support
- Output to `.agents/research/YYYY-MM-DD-dead-code-*.md`

See: `skills/dead-code-scanner/SKILL.md`

---

# /implementation-plan

**Version:** 1.0.0
**Description:** Structured feature planning with file impact analysis, dependencies, and phased tasks

**Phases:**
1. Understanding (feature summary, user stories, acceptance criteria)
2. Codebase analysis (related code, patterns, dependencies)
3. Impact analysis (files affected by area)
4. Implementation plan (phased task list)
5. Risk assessment
6. Clarifying questions

See: `skills/implementation-plan/SKILL.md`

---

# /safe-refactor

**Version:** 1.0.0
**Description:** Plan refactoring with blast radius analysis, dependency mapping, and rollback strategy

**Features:**
- Upstream/downstream dependency mapping
- Blast radius calculation
- Step-by-step plan with working commits
- Rollback strategy

See: `skills/safe-refactor/SKILL.md`

---

# /debug

**Version:** 1.0.0
**Description:** Systematic debugging workflow - reproduce, isolate, hypothesize, verify, and fix

**Steps:**
1. Reproduce the issue
2. Isolate the code path
3. Gather evidence
4. Hypothesize (ranked by likelihood)
5. Verify each hypothesis
6. Confirm root cause
7. Implement fix
8. Verify fix
9. Scan for similar bugs

See: `skills/debug/SKILL.md`

---

# /explain

**Version:** 1.0.0
**Description:** Deep-dive explanation of how a specific file, feature, or data flow works

**Output format:**
- Overview (what, why, where)
- Key components table
- How it works (step-by-step)
- Data flow diagram
- Dependencies (upstream/downstream)
- Edge cases and gotchas
- Related code
- Quick reference for modification/debugging

See: `skills/explain/SKILL.md`

---

# /generate-tests

**Version:** 1.0.0
**Description:** Generate unit and UI tests for specified code with edge cases and mocks

**Features:**
- Auto-detection of Swift Testing vs XCTest
- Mock generation for protocol dependencies
- Edge case enumeration
- Test naming convention enforcement

See: `skills/generate-tests/SKILL.md`

---

# /run-tests

**Version:** 1.0.0
**Description:** Run tests with smart execution strategies

**Strategies:**
| Strategy | UI Tests | Unit Tests | Best For |
|----------|----------|------------|----------|
| Smart Split | Sequential | Parallel | Daily development |
| All Sequential | Sequential | Sequential | Maximum stability |
| All Parallel | Parallel | Parallel | CI with clean state |

**Features:**
- Unattended mode (`--unattended`)
- Pre-run cleanup option
- XcodeBuildMCP integration

See: `skills/run-tests/SKILL.md`

---

# /ui-scan

**Version:** 1.0.0
**Description:** UI test environment setup with splash/onboarding bypass and accessibility scan

**Features:**
- Launch argument setup for UI testing
- Onboarding/tutorial bypass helpers
- Accessibility identifier scan
- Element finding strategies

See: `skills/ui-scan/SKILL.md`

---

# /security-audit

**Version:** 1.0.0
**Description:** Automated security scan with severity scoring and remediation examples

**Scan categories:**
- Secrets & API keys
- Data storage (Keychain vs UserDefaults)
- Network security (HTTPS, ATS)
- Input validation
- Privacy & permissions
- Privacy Manifest validation

**Output:** `.agents/research/YYYY-MM-DD-security-audit.md`

See: `skills/security-audit/SKILL.md`

---

# /performance-check

**Version:** 1.0.0
**Description:** Profile-guided performance analysis for memory, CPU, energy, SwiftUI, and launch time

**Scan categories:**
- Launch time
- Main thread usage
- Memory (retain cycles, caches)
- SwiftUI performance
- Database / SwiftData
- Energy usage

**Output:** `.agents/research/YYYY-MM-DD-performance-check.md`

See: `skills/performance-check/SKILL.md`

---

# /release-prep

**Version:** 1.0.0
**Description:** Pre-release checklist including version bump, changelog, known issues, and store metadata

**Checklist:**
- Code readiness
- Version numbers
- Changelog
- App Store metadata
- Privacy & compliance
- Testing verification
- Release day steps
- Post-release monitoring

See: `skills/release-prep/SKILL.md`

---

# /release-screenshots

**Version:** 1.0.0
**Description:** Capture App Store screenshots across all required device sizes

**Features:**
- Multi-device capture (6.9", 6.5", 5.5")
- Status bar override
- Organized folder output
- XcodeBuildMCP integration

See: `skills/release-screenshots/SKILL.md`

---

# /update-website

**Version:** 2.0.0
**Description:** Sync website content with app codebase - features, changelog, screenshots, docs

See: `skills/update-website/SKILL.md`

---

*End of Commands Reference*
