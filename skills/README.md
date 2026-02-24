# Xcode Workflow Skills

Claude Code plugin providing 20 workflow skills for iOS/macOS development.

## Installation

```bash
# Clone the repository
git clone https://github.com/Terryc21/xcode-workflow-skills.git

# Install as Claude Code plugin
claude plugin install '/path/to/xcode-workflow-skills'

# Or install from GitHub directly:
claude plugin install Terryc21/xcode-workflow-skills
```

## Skills Included

### Code Analysis
| Command | Version | Description |
|---------|---------|-------------|
| `/tech-talk-reportcard` | 2.0.0 | Technical codebase analysis with A-F grades (architecture, security, performance, concurrency, accessibility) |
| `/plain-talk-reportcard` | 2.0.0 | Plain-language analysis for stakeholders with effort estimates |
| `/scan-similar-bugs` | 1.0.0 | Find similar bug patterns after fixing one |
| `/review-changes` | 1.1.0 | Pre-commit code review |
| `/dead-code-scanner` | 1.0.0 | Find unused code |
| `/workflow-audit` | 2.1.1 | Systematic UI workflow auditing |

### Testing & Debugging
| Command | Version | Description |
|---------|---------|-------------|
| `/run-tests` | 1.0.0 | Smart test execution strategies |
| `/generate-tests` | 1.0.0 | Generate unit and UI tests |
| `/ui-scan` | 1.0.0 | UI test setup and accessibility scan |
| `/debug` | 1.1.0 | Systematic debugging workflow |

### Planning & Refactoring
| Command | Version | Description |
|---------|---------|-------------|
| `/implementation-plan` | 1.0.0 | Phased implementation planning |
| `/safe-refactor` | 1.1.0 | Refactoring with blast radius analysis |
| `/explain` | 1.1.0 | Deep-dive code explanation |

### Release & Deployment
| Command | Version | Description |
|---------|---------|-------------|
| `/release-prep` | 1.1.0 | Pre-release checklist with automated version bumps |
| `/release-screenshots` | 1.0.0 | App Store screenshot capture |
| `/update-website` | 2.0.1 | Sync website with app changes |

### Security & Performance
| Command | Version | Description |
|---------|---------|-------------|
| `/security-audit` | 1.0.0 | Security vulnerability scan with automated grep patterns |
| `/performance-check` | 1.0.0 | Performance anti-pattern analysis |

## Features

- **Execution Directives**: All workflow skills execute automatically, not just describe
- **Interactive Questions**: Gather context before analysis using AskUserQuestion
- **Automated Scans**: Grep patterns detect issues automatically
- **Output Files**: Reports saved to `.agents/research/YYYY-MM-DD-*.md`
- **Trend Comparison**: Compare to previous reports to track progress
- **Severity Scoring**: CRITICAL/HIGH/MEDIUM/LOW with remediation examples
- **Deep Dive Options**: Invoke Axiom skills for category-specific analysis
- **Axiom Integration**: Complements Axiom for iOS-specific deep dives

## Report Card Skills (v2.0.0)

The report card skills received major improvements:

### `/tech-talk-reportcard`
- **9 grading categories**: Architecture, Code Quality, Performance, Concurrency, Security, Accessibility, Testing, UI/UX, Data
- **Automated grep scans** for each category
- **Trend comparison** to previous reports (grade changes ↑↓→)
- **Deep dive option** - invoke Axiom skills for category-specific analysis
- **CLAUDE.md integration** - optionally include project context

### `/plain-talk-reportcard`
- **7 grading categories** in plain language
- **Effort estimates** for each issue (e.g., "~2 days")
- **Risk explanations** (e.g., "Risk if ignored: Bad reviews")
- **Plain language glossary** translates technical terms
- **Recommended timeline** (Week 1, Week 2-3, Month 2)

## Axiom Integration

These skills complement [Axiom](https://github.com/CharlesWiltgen/Axiom) for iOS-specific patterns. Install both for comprehensive coverage.

| This Plugin | Axiom Skills |
|-------------|--------------|
| `/tech-talk-reportcard` | `axiom-swiftui-architecture`, `axiom-ios-performance`, `axiom-ios-concurrency`, `axiom-ios-accessibility`, `axiom-ios-testing` |
| `/plain-talk-reportcard` | `axiom-ios-accessibility`, `axiom-ios-ui`, `axiom-hig` |
| `/security-audit` | `axiom-storage-diag`, `axiom-file-protection-ref` |
| `/performance-check` | `axiom-swift-performance`, `axiom-swiftui-performance`, `axiom-ios-performance` |
| `/debug` | `axiom-memory-debugging`, `axiom-hang-diagnostics` |
| `/generate-tests` | `axiom-swift-testing`, `axiom-testing-async` |

For schema migrations, use Axiom directly: `/axiom:axiom-swiftdata-migration`

## Requirements

- [Claude Code](https://claude.ai/claude-code) CLI
- Xcode (for iOS/macOS projects)
- Optional: [XcodeBuildMCP](https://github.com/cameroncooke/XcodeBuildMCP) for simulator automation
- Optional: [Axiom](https://github.com/CharlesWiltgen/Axiom) for iOS-specific deep dives

## Version

2.1.0

## License

MIT

## Author

Created by [Terry Nyberg](https://github.com/Terryc21)
