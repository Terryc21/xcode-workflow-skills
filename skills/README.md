# Xcode Workflow Skills

Claude Code plugin providing 16 workflow skills for iOS/macOS development.

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
| Command | Description |
|---------|-------------|
| `/tech-talk-reportcard` | Technical codebase analysis with A-F grades |
| `/plain-talk-reportcard` | Plain-language analysis for stakeholders |
| `/scan-similar-bugs` | Find similar bug patterns after fixing one |
| `/review-changes` | Pre-commit code review |
| `/dead-code-scanner` | Find unused code |

### Testing & Debugging
| Command | Description |
|---------|-------------|
| `/run-tests` | Smart test execution strategies |
| `/generate-tests` | Generate unit and UI tests |
| `/ui-scan` | UI test setup and accessibility scan |
| `/debug` | Systematic debugging workflow |

### Planning & Refactoring
| Command | Description |
|---------|-------------|
| `/implementation-plan` | Phased implementation planning |
| `/safe-refactor` | Refactoring with blast radius analysis |
| `/explain` | Deep-dive code explanation |

### Release & Deployment
| Command | Description |
|---------|-------------|
| `/release-prep` | Pre-release checklist |
| `/release-screenshots` | App Store screenshot capture |
| `/update-website` | Sync website with app changes |

### Security & Performance
| Command | Description |
|---------|-------------|
| `/security-audit` | Security vulnerability scan with automated grep patterns |
| `/performance-check` | Performance anti-pattern analysis |

## Features

- **Execution Directives**: All workflow skills execute automatically, not just describe
- **Interactive Questions**: Gather context before analysis
- **Output Files**: Reports saved to `.agents/research/YYYY-MM-DD-*.md`
- **Severity Scoring**: CRITICAL/HIGH/MEDIUM/LOW with remediation examples
- **Axiom Integration**: Invokes Axiom skills for iOS-specific deep dives

## Axiom Integration

These skills complement [Axiom](https://github.com/CharlesWiltgen/Axiom) for iOS-specific patterns. Install both for comprehensive coverage.

| This Plugin | Axiom Skills |
|-------------|--------------|
| `/security-audit` | `axiom-security-privacy-scanner` |
| `/performance-check` | `axiom-swift-performance`, `axiom-swiftui-performance` |
| `/debug` | `axiom-memory-debugging`, `axiom-hang-diagnostics` |
| `/generate-tests` | `axiom-swift-testing`, `axiom-testing-async` |

For schema migrations, use Axiom directly: `/axiom:axiom-swiftdata-migration`

## Requirements

- [Claude Code](https://claude.ai/claude-code) CLI
- Xcode (for iOS/macOS projects)
- Optional: [XcodeBuildMCP](https://github.com/cameroncooke/XcodeBuildMCP) for simulator automation
- Optional: [Axiom](https://github.com/CharlesWiltgen/Axiom) for iOS-specific deep dives

## Version

1.0.0

## License

MIT

## Author

Created by [Terry Nyberg](https://github.com/Terryc21)
