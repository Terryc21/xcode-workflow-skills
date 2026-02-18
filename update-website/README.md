# Update Website Skill

Sync your website content with your app's codebase automatically.

## Installation

Copy the `update-website` folder to your `.claude/skills/` directory:

```bash
cp -r update-website ~/.claude/skills/
```

## Usage

```
/update-website
```

First run walks you through setup. Subsequent runs use saved config.

## Change Source Options

The skill asks what changes to sync:

| Source | Description |
|--------|-------------|
| **Since last TestFlight** | All commits since the last tagged build (recommended) |
| **Last commit only** | Just the most recent commit |
| **Specific range** | Choose commits by count, date, or hash range |

### TestFlight Tags

Tag your builds for reliable change tracking:

```bash
# After uploading to TestFlight
git tag testflight-build-25
git push origin testflight-build-25
```

The skill auto-detects tags matching `testflight-*` or `build-*` patterns.

---

## Sync Markers

Add markers to your HTML files where content should be synced:

### Version Number
```html
"softwareVersion": "1.0", <!-- SYNC:VERSION -->
```

### Current Version Block
```html
<!-- SYNC:CURRENT_VERSION -->
<div class="current-version">
  <p class="version-number">Version 1.0 (Build 25)</p>
  <p class="version-date">February 10, 2026</p>
</div>
<!-- /SYNC:CURRENT_VERSION -->
```

### Latest Commit
```html
<!-- SYNC:LASTCOMMIT -->
<div class="dev-activity">
  <code>Commit message here</code>
  <p>Date • Summary</p>
</div>
<!-- /SYNC:LASTCOMMIT -->
```

### TestFlight Changes (Since Last Build)
```html
<!-- SYNC:TESTFLIGHT_CHANGES -->
<ul>
  <li>Add async photo decoding</li>
  <li>Fix scroll performance</li>
  <li>Add photo operation tests</li>
</ul>
<!-- /SYNC:TESTFLIGHT_CHANGES -->
```

### Feature List
```html
<!-- SYNC:FEATURES:Dashboard -->
<ul>
  <li>Feature 1</li>
  <li>Feature 2</li>
</ul>
<!-- /SYNC:FEATURES:Dashboard -->
```

### Changelog
```html
<!-- SYNC:CHANGELOG -->
- v1.0.1: Bug fixes
- v1.0.0: Initial release
<!-- /SYNC:CHANGELOG -->
```

### Code-Linked Content
```html
<!-- SYNC:Sources/Views/ItemDetailView.swift -->
Documentation synced from code comments
<!-- /SYNC:Sources/Views/ItemDetailView.swift -->
```

## Code Markers

In your Swift code, mark content for extraction:

```swift
// WEBSITE: Feature Name
// - Feature description 1
// - Feature description 2
// /WEBSITE
```

## Config File

Stored at `.claude/website-sync-config.json`:

```json
{
  "appPath": "/path/to/MyApp",
  "websitePath": "/path/to/website",
  "detectedFormat": "static-html",
  "syncContent": ["version", "changelog", "features"],
  "updateStrategy": "smart",
  "deployment": "git"
}
```

## Update Strategies

| Strategy | Description |
|----------|-------------|
| **Smart** | Only update markers matching recent code changes |
| **Full scan** | Check all markers regardless of changes |
| **Manual review** | Approve each change before applying |

## Supported Website Formats

- Static HTML
- Jekyll (`_config.yml`)
- Hugo (`config.toml`)
- Next.js/Nuxt (`next.config.js`)

## Features

- Auto-detects website format and templates
- Creates timestamped backups before changes
- Optional screenshot capture via XcodeBuildMCP
- Git deployment (commit + push)
- Validation checks (links, images, HTML)
- Rollback support

## License

MIT
