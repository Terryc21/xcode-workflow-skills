# Skills directory

This directory contains all 22 skills included in the Xcode Workflow Skills plugin.

For installation instructions, usage, and the full skill reference, see the [root README](../README.md).

## Quick reference

| Directory | Command | Description |
|-----------|---------|-------------|
| `codebase-audit` | `/codebase-audit` | Comprehensive audit with A-F grades across 24 domains |
| `commands` | `/commands` | List all available skills |
| `dead-code-scanner` | `/dead-code-scanner` | Find unused code after refactoring |
| `debug` | `/debug` | Systematic debugging workflow |
| `enhanced-commands` | `/enhanced-commands` | Skill list with usage examples |
| `explain` | `/explain` | Deep-dive code explanation |
| `generate-tests` | `/generate-tests` | Generate unit and UI tests |
| `implementation-plan` | `/implementation-plan` | Phased implementation planning |
| `performance-check` | `/performance-check` | Performance anti-pattern scan |
| `plain-talk-reportcard` | `/plain-talk-reportcard` | Plain-language codebase analysis |
| `plan` | `/plan` | Epic decomposition into tasks |
| `release-prep` | `/release-prep` | Pre-release checklist |
| `release-screenshots` | `/release-screenshots` | App Store screenshot capture |
| `review-changes` | `/review-changes` | Pre-commit code review |
| `run-tests` | `/run-tests` | Smart test execution |
| `safe-refactor` | `/safe-refactor` | Refactoring with blast radius analysis |
| `scan-similar-bugs` | `/scan-similar-bugs` | Find similar bug patterns |
| `security-audit` | `/security-audit` | Security vulnerability scan |
| `tech-talk-reportcard` | `/tech-talk-reportcard` | Technical codebase analysis with A-F grades |
| `ui-scan` | `/ui-scan` | UI test setup and accessibility scan |
| `update-website` | `/update-website` | Sync website with app changes |
| `workflow-audit` | `/workflow-audit` | 5-layer UI workflow audit with 20 issue categories, 14 automated checks, regression canaries, targeted flow tracing, and diff mode |

The `shared/` directory contains reference documents used by multiple skills (rating system, etc.).

## Cautionary Note: AI-Powered Audit Plugins

**Plugins like `workflow-audit` are tools, not oracles.**

These plugins systematically scan your codebase using pattern matching and heuristics. They can surface real issues you'd miss manually — but they have inherent limitations:

**What they're good at:**
- Finding structural inconsistencies (orphaned code, missing handlers, type mismatches)
- Catching patterns that compile but fail silently at runtime
- Enforcing consistency across platforms (iOS vs macOS parity)
- Providing a repeatable, systematic checklist

**What they can miss:**
- Business logic correctness — a plugin can verify a button exists, not that it does the right thing
- User experience nuance — "buried" is a judgment call that depends on content height, screen size, and context
- False positives — code flagged as "orphaned" may be intentionally retained for future use
- False negatives — novel bug patterns not covered by existing checks won't be detected

**How to use them responsibly:**
- Treat findings as leads to investigate, not verdicts to act on blindly
- Verify critical findings manually before committing fixes
- Expect the plugin to evolve — today's checks won't catch tomorrow's new patterns
- Don't assume a clean audit means zero issues; it means zero *known-pattern* issues
- Review the skill's detection patterns periodically to understand what it actually checks vs what you assume it checks

**Bottom line:** An audit plugin replaces neither testing nor human review. It's a force multiplier for the reviewer, not a replacement.
