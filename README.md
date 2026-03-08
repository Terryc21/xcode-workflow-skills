# Xcode Workflow Skills

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin with 22 workflow skills for iOS and macOS development. Covers the full development lifecycle: planning, coding, testing, debugging, auditing, and shipping.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — Anthropic's CLI for Claude. If you don't have it yet, install it with:
  ```bash
  npm install -g @anthropic-ai/claude-code
  ```
- Xcode (for iOS/macOS projects)

## Installation

### Option 1: Install from GitHub (recommended)

Open your terminal and run:

```bash
claude plugin marketplace add Terryc21/xcode-workflow-skills
claude plugin install xcode-workflow-skills
```

The first command adds the repo as a marketplace. The second installs the plugin. All 22 skills are immediately available as slash commands in any project.

### Option 2: Install from a local copy

If you prefer to clone the repo first (useful if you want to browse or customize the skills):

```bash
# Clone the repository
git clone https://github.com/Terryc21/xcode-workflow-skills.git

# Add the local copy as a marketplace and install
claude plugin marketplace add ./xcode-workflow-skills
claude plugin install xcode-workflow-skills
```

### Verify installation

After installing, open Claude Code in any Xcode project and type:

```
/commands
```

You should see a list of all available skills. If the command isn't recognized, try restarting Claude Code.

## Standalone Workflow Audit

Just want the workflow audit skill? Install the lightweight standalone version (3 skills instead of 22):

```bash
claude plugin marketplace add Terryc21/workflow-audit
claude plugin install workflow-audit
```

## Skills

### Code Analysis & Review

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/review-changes` | Pre-commit review of staged/unstaged changes for bugs, security issues, performance problems, and missing tests. | Before every commit to catch issues early. |
| `/scan-similar-bugs` | After fixing a bug, search the entire codebase for the same anti-pattern. | Right after fixing a bug to prevent recurrence elsewhere. |
| `/dead-code-scanner` | Find unused functions, classes, imports, and orphaned files. Supports quick (post-refactor) and full (codebase-wide) modes. | After refactoring or during periodic code cleanup. |

### Report Cards

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/tech-talk-reportcard` | Technical codebase analysis with A-F grades across 9 categories (architecture, security, performance, concurrency, accessibility, testing, UI/UX, data). Includes automated grep scans and trend comparison. | Assessing technical health for developers and tech leads. |
| `/plain-talk-reportcard` | Same analysis, explained in plain language with effort estimates and risk explanations. Includes a glossary that translates technical terms. | Presenting codebase health to managers, executives, or non-technical stakeholders. |
| `/codebase-audit` | Comprehensive audit combining A-F grading with domain-specific agent scanning across 24 audit domains. Includes ship/no-ship recommendation and regression detection. | Before major releases for a thorough quality gate. |

### Planning & Architecture

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/plan` | Decompose epics into trackable, right-sized tasks with risk/ROI ratings. Can ingest findings from `/codebase-audit` or `/tech-talk-reportcard`. | Planning features, bug fixes, and refactors with clear priorities. |
| `/safe-refactor` | Refactoring with blast radius analysis, dependency mapping, and step-by-step rollback strategy. Verifies compilation after each step. | Safely executing renames, protocol extractions, file splits, and other structural changes. |
| `/explain` | Deep-dive explanation of how a specific file, feature, or data flow works, with code walkthrough. | Understanding unfamiliar or complex code before modifying it. |

### Testing & Debugging

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/run-tests` | Execute tests with smart strategies: parallel, sequential, or split (UI sequential + unit parallel). | Running test suites with optimal speed and reliability. |
| `/generate-tests` | Generate unit and UI tests with proper mocking, edge cases, and coverage for specified code. | Creating comprehensive test suites for new or modified features. |
| `/ui-scan` | Set up UI test environment and run accessibility scans. Handles splash screen bypass and onboarding skip. | Setting up UI testing infrastructure or identifying accessibility issues. |
| `/debug` | Systematic bug investigation: reproduce, isolate, hypothesize, verify, fix. | Investigating crashes, unexpected behavior, or user-reported issues. |

### Security & Performance

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/security-audit` | Automated security scan covering hardcoded secrets, insecure storage, network issues, input validation, and privacy manifest compliance. | Before release or during periodic security reviews. |
| `/performance-check` | Scan for performance anti-patterns: memory leaks, main-thread I/O, excessive redraws, launch time issues, and energy waste. | When users report slowness, battery drain, or before performance-sensitive releases. |

### Release & Deployment

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/release-prep` | Pre-release checklist: version bump, changelog, privacy manifest, App Store metadata, and archive readiness. | Before shipping any release to validate all submission requirements. |
| `/release-screenshots` | Capture App Store screenshots across all required device sizes using simulator automation. | Generating marketing assets for App Store submission. |
| `/update-website` | Sync marketing website content with app changes: features, changelog, screenshots, documentation. | After a release to keep the website current. |

### Workflow & UI Auditing

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/workflow-audit` | 5-layer UI workflow audit with 20 issue categories and 14 automated checks: discover entry points, trace user flows, detect dead ends, buried buttons, dismiss traps, context dropping, notification fragility, notification type-safety, sheet asymmetry, stale context, simulated delays, and more. Includes regression canaries, targeted flow tracing, and diff mode. | Auditing SwiftUI navigation, finding abandoned flows, and validating user journeys. |

### Reference

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/commands` | List all available skills with versions. | Quick reference to find the right skill. |
| `/enhanced-commands` | Same list with usage examples and output locations. | When you need examples of how to invoke a skill. |

## How It Works

Each skill is a structured prompt that guides Claude Code through a specific workflow. Skills:

- **Execute automatically** — they run the workflow, not just describe it
- **Ask context questions** — gather your preferences before starting
- **Use automated scans** — grep patterns detect issues systematically
- **Save reports** — output goes to `.agents/research/YYYY-MM-DD-*.md`
- **Track trends** — compare against previous reports to measure progress

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

## Acknowledgements

Special thanks to [Charles Wiltgen](https://github.com/CharlesWiltgen) for his work on [Axiom](https://charleswiltgen.github.io/Axiom/), an excellent collection of iOS development skills for Claude Code. If you're looking for deep-dive iOS-specific analysis (concurrency, memory debugging, SwiftUI performance, accessibility compliance, and more), Axiom is highly recommended.

## Version

2.2.0

## License

MIT

## Author

Created by [Terry Nyberg](https://github.com/Terryc21)
