# Xcode Workflow Skills for Claude Code

A collection of Claude Code skills optimized for iOS/macOS development with Xcode.

## Installation

### Quick Install (All Skills)

```bash
# Clone to your user skills directory
git clone https://github.com/Terryc21/xcode-workflow-skills.git /tmp/xcode-workflow-skills

# Copy skills to Claude Code
cp -r /tmp/xcode-workflow-skills/skills/* ~/.claude/skills/

# Clean up
rm -rf /tmp/xcode-workflow-skills
```

### Install Individual Skills

```bash
# Example: Install only the debug skill
git clone --depth 1 https://github.com/Terryc21/xcode-workflow-skills.git /tmp/xws
cp -r /tmp/xws/skills/debug ~/.claude/skills/
rm -rf /tmp/xws
```

## Available Skills

### Code Analysis & Review

| Skill | Command | Description |
|-------|---------|-------------|
| tech-talk-reportcard | `/tech-talk-reportcard` | Technical codebase analysis with A-F grades for developers |
| plain-talk-reportcard | `/plain-talk-reportcard` | Codebase analysis with plain-language summaries for non-technical stakeholders |
| scan-similar-bugs | `/scan-similar-bugs` | Find similar bug patterns codebase-wide after a fix |
| review-changes | `/review-changes` | Pre-commit review of staged changes |

### Planning & Refactoring

| Skill | Command | Description |
|-------|---------|-------------|
| implementation-plan | `/implementation-plan` | Structured implementation planning with file impact analysis |
| safe-refactor | `/safe-refactor` | Refactor plan with blast radius analysis |
| migrate-schema | `/migrate-schema` | SwiftData migration with data preservation |

### Debugging & Testing

| Skill | Command | Description |
|-------|---------|-------------|
| debug | `/debug` | Systematic debugging workflow |
| generate-tests | `/generate-tests` | Generate unit and UI tests with edge cases |
| run-tests | `/run-tests` | Run tests with smart strategies |
| ui-scan | `/ui-scan` | UI test setup with accessibility scan |

### Security & Performance

| Skill | Command | Description |
|-------|---------|-------------|
| security-audit | `/security-audit` | Scan API keys, storage, network, privacy |
| performance-check | `/performance-check` | Profile memory, CPU, energy, launch time |

### Release & Documentation

| Skill | Command | Description |
|-------|---------|-------------|
| release-prep | `/release-prep` | Pre-release checklist with version bump |
| release-screenshots | `/release-screenshots` | Capture App Store screenshots |
| explain | `/explain` | Deep-dive explanation of file/feature/data flow |
| enhanced-commands | `/enhanced-commands` | Reference docs with parameters and examples |

## Usage

After installation, use any skill by typing its command in Claude Code:

```
/tech-talk-reportcard
```

Many skills include interactive questions to gather context before analysis.

## Features

- **Interactive Questions**: Report cards and implementation plans use `AskUserQuestion` to gather context
- **Mode Selection**: Choose between Fast (parallel agents) or Quiet (sequential, fewer prompts)
- **Grade Summaries**: Quick-scan format with inline grades and severity tags
- **iOS/Swift Focus**: Optimized for SwiftUI, SwiftData, CloudKit workflows

## Requirements

- [Claude Code](https://claude.com/claude-code) CLI
- Xcode (for iOS/macOS projects)
- Optional: [Axiom skills](https://github.com/tinyspeck/axiom) for advanced iOS patterns

## Compatibility

- iOS 17.6+ / macOS 14.6+
- Swift 6.2
- Xcode 26+

## License

MIT License - Feel free to use, modify, and share.

## Contributing

Contributions welcome! Please open an issue or PR.

## Author

Created by [@Terryc21](https://github.com/Terryc21)
