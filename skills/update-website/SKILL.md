---
name: update-website
description: Sync website content with app codebase - features, changelog, screenshots, docs
version: 2.0.0
author: Terry Nyberg
license: MIT
---

# Website Sync Skill

Sync website content with your app's codebase. Supports static HTML, Jekyll, Hugo, and JS frameworks.

---

## Quick Reference

| Command | What It Does |
|---------|--------------|
| `/update-website` | Run sync with saved settings |
| `/update-website --status` | Show current state without syncing |
| `/update-website --dry-run` | Preview changes without writing |
| `/update-website --audit` | Check marker coverage |
| `/update-website --gaps` | Find missing content |
| `/update-website --setup` | Re-run configuration wizard |
| `/update-website --regenerate-features` | Regenerate features.json from codebase |
| `/update-website --regenerate-faq` | Regenerate faq.json from website/codebase |
| `/update-website --regenerate-changelog` | Regenerate changelog.json from whats-new.html |
| `/update-website --check-drift` | Detailed drift report for content files |
| `/update-website --auto-regenerate` | Regenerate stale JSON files, then sync |

### Workflow Phases

```
┌─────────────────────────────────────────────────────────────┐
│  PHASE A: SETUP (First Run Only)                            │
│  Steps 1-3: Paths, website format detection                 │
├─────────────────────────────────────────────────────────────┤
│  PHASE B: CONFIGURE                                         │
│  Steps 4-9: Content selection, change source, deployment    │
├─────────────────────────────────────────────────────────────┤
│  PHASE C: EXECUTE                                           │
│  Steps 10-16: Scope, sync, screenshots, validate, deploy    │
├─────────────────────────────────────────────────────────────┤
│  PHASE D: ANALYZE (On Demand)                               │
│  Steps 17-19: Completeness, gaps, marker audit              │
└─────────────────────────────────────────────────────────────┘
```

---

## Quick Mode (Repeat Runs)

When config exists, show main menu:

```
questions:
[
  {
    "question": "Website sync ready. What would you like to do?",
    "header": "Action",
    "options": [
      {"label": "Sync all (Recommended)", "description": "Update all markers with current settings"},
      {"label": "Sync with options", "description": "Choose scope, preview, or dry-run"},
      {"label": "Check status", "description": "See current state without making changes"},
      {"label": "Analyze content", "description": "Audit markers, check completeness, find gaps"},
      {"label": "Reconfigure", "description": "Change settings or run setup wizard"}
    ],
    "multiSelect": false
  }
]
```

### If "Sync all":

Skip to Step 11 (Execute Sync) with scope = all markers.

### If "Sync with options":

```
questions:
[
  {
    "question": "Sync options:",
    "header": "Options",
    "options": [
      {"label": "Dry-run first", "description": "Preview changes without writing files"},
      {"label": "Select scope", "description": "Choose specific pages or markers"},
      {"label": "Change source", "description": "Pick different commit range"},
      {"label": "Run normally", "description": "Proceed with current settings"}
    ],
    "multiSelect": false
  }
]
```

### If "Check status":

Run Status Check (see below).

### If "Analyze content":

```
questions:
[
  {
    "question": "What analysis would you like to run?",
    "header": "Analyze",
    "options": [
      {"label": "Marker audit", "description": "Check marker coverage (Step 19)"},
      {"label": "Completeness check", "description": "Compare code ↔ website markers (Step 17)"},
      {"label": "Content gap analysis", "description": "Find undocumented features (Step 18)"},
      {"label": "Run all", "description": "Full analysis report"}
    ],
    "multiSelect": false
  }
]
```

### If "Reconfigure":

```
questions:
[
  {
    "question": "What would you like to change?",
    "header": "Config",
    "options": [
      {"label": "Content to sync", "description": "Change metadata/content/docs selection"},
      {"label": "Change source", "description": "TestFlight tag, commits, date range"},
      {"label": "Deployment settings", "description": "Git push, custom command, none"},
      {"label": "Full setup wizard", "description": "Start over from scratch"}
    ],
    "multiSelect": false
  }
]
```

---

## Status Check

Display current state without making changes:

```
Website Sync Status
═══════════════════════════════════════════════════════

Config: /path/to/app/.claude/website-sync-config.json

Paths:
  App:     /path/to/app
  Website: /path/to/website

Last sync: Feb 18, 2026 at 6:24 AM
Last commit synced: 28aeaa2 "Add async photo decoding"

Changes since last sync:
  - 3 new commits in app repo
  - 2 files with WEBSITE markers modified

Markers found:
  Website: 12 markers across 4 pages
  Code:    18 WEBSITE: blocks in source

Content Files:
  features.json: ⚠️  STALE (3 source files changed since generation)
    - Sources/Features/NewFeature/ (new folder)
    - Sources/Features/StuffScout/StuffScoutView.swift (modified)
    - Sources/Features/Dashboard/DashboardView.swift (modified)
  faq.json: ✓ Up to date
  changelog.json: ✓ Up to date (Build 25, 10 releases)
  pricing.json: ✗ Not found

Pending updates:
  - VERSION: 1.0 → 1.1 (index.html)
  - LASTCOMMIT: outdated (whats-new.html)
  - FEATURE:RecallCheck: new content available

TestFlight tag: testflight-build-25
Next tag will be: testflight-build-26
```

---

## Drift Detection

Automatically detects when JSON content files (`features.json`, `faq.json`, `changelog.json`) are out of sync with their sources.

### How It Works

1. **Track generation metadata** in each JSON file:
   ```json
   {
     "generatedFrom": "codebase-analysis",
     "generatedDate": "2026-02-18T14:35:00Z",
     "sourceSnapshot": {
       "featureFolders": ["Dashboard", "StuffScout", "Scanner", ...],
       "fileHashes": {
         "Sources/Features/StuffScout/StuffScoutView.swift": "a1b2c3d",
         "Sources/Features/Dashboard/DashboardView.swift": "e4f5g6h"
       }
     }
   }
   ```

2. **On status check or sync**, compare:
   - Current feature folders vs. `sourceSnapshot.featureFolders`
   - Current file modification dates vs. `generatedDate`
   - Optionally: file content hashes vs. `sourceSnapshot.fileHashes`

3. **Report drift**:
   - New folders added (new features)
   - Folders removed (deleted features)
   - Files modified since generation

### Drift Detection Commands

```bash
# Check drift status
/update-website --status

# Detailed drift report
/update-website --check-drift

# Auto-fix: regenerate if drift detected
/update-website --auto-regenerate
```

### Drift Severity Levels

| Level | Condition | Action |
|-------|-----------|--------|
| **None** | No changes since generation | Proceed normally |
| **Low** | Files modified, same structure | Warn, suggest regenerate |
| **Medium** | New feature folders added | Warn, offer to add new features |
| **High** | Feature folders removed | Block sync, require regenerate |

### On Drift Detection

When drift is detected during sync:

```
questions:
[
  {
    "question": "features.json is stale. 2 feature folders changed. What do you want to do?",
    "header": "Drift",
    "options": [
      {"label": "Regenerate now", "description": "Re-analyze codebase and update features.json"},
      {"label": "Continue anyway", "description": "Use existing features.json (may miss new content)"},
      {"label": "View changes", "description": "Show what's different before deciding"}
    ],
    "multiSelect": false
  }
]
```

### Configuring Drift Detection

In `website-sync-config.json`:

```json
{
  "driftDetection": {
    "enabled": true,
    "checkOnSync": true,
    "checkOnStatus": true,
    "autoRegenerate": false,
    "watchPaths": [
      "Sources/Features/",
      "Sources/Views/Tools/"
    ],
    "ignorePaths": [
      "**/*Tests*",
      "**/*.generated.swift"
    ]
  }
}
```

---

## Dry-Run Mode

Preview all changes without writing to files:

```
Dry-Run Preview
═══════════════════════════════════════════════════════

Changes that WOULD be made:

1. index.html
   Line 97: VERSION
   - Old: "softwareVersion": "1.0"
   + New: "softwareVersion": "1.1"

2. whats-new.html
   Lines 828-834: LASTCOMMIT
   - Old: "Add photo caching improvements"
   + New: "Add async photo decoding and tests"

3. features.html
   Lines 245-260: FEATURE:RecallCheck
   + New section (content from RecallCheckView.swift)

Summary:
  Files to modify: 3
  Markers to update: 4
  New content to add: 1

No files were modified. Run without --dry-run to apply changes.
```

Use AskUserQuestion:

```
questions:
[
  {
    "question": "Apply these changes?",
    "header": "Confirm",
    "options": [
      {"label": "Yes, apply all", "description": "Write changes to files"},
      {"label": "Apply selected", "description": "Choose which changes to apply"},
      {"label": "Cancel", "description": "Don't make any changes"}
    ],
    "multiSelect": false
  }
]
```

---

## Sync History

Track past syncs in `.claude/website-sync-history.json`:

```json
{
  "syncs": [
    {
      "timestamp": "2026-02-18T06:24:30Z",
      "commit": "28aeaa2",
      "markersUpdated": 4,
      "filesModified": ["index.html", "whats-new.html"],
      "deployment": "git",
      "backupPath": "/path/to/website.backup.20260218-062430"
    },
    {
      "timestamp": "2026-02-10T14:15:00Z",
      "commit": "a1b2c3d",
      "markersUpdated": 2,
      "filesModified": ["index.html"],
      "deployment": "git",
      "backupPath": "/path/to/website.backup.20260210-141500"
    }
  ],
  "maxHistory": 50
}
```

### View History

```
questions:
[
  {
    "question": "View sync history?",
    "header": "History",
    "options": [
      {"label": "Recent syncs", "description": "Last 10 syncs with details"},
      {"label": "Find by date", "description": "Search for specific sync"},
      {"label": "Rollback options", "description": "See available restore points"}
    ],
    "multiSelect": false
  }
]
```

---

## Error Handling

### Common Errors and Recovery

| Error | Cause | Recovery |
|-------|-------|----------|
| `Marker not closed` | Missing `<!-- /SYNC:X -->` | Show location, offer to fix |
| `Source not found` | No `// WEBSITE:X` in code | Suggest creating marker or using markdown fallback |
| `Config invalid` | Malformed JSON | Show error, offer to reset config |
| `Git push failed` | Auth or network issue | Save changes locally, retry later |
| `Backup failed` | Disk space or permissions | Warn user, ask to continue without backup |

### On Error

1. **Stop immediately** — Don't apply partial changes
2. **Show clear error message** with file and line number
3. **Offer recovery options**:

```
questions:
[
  {
    "question": "Error: Marker 'FEATURE:Dashboard' not closed in features.html line 120. How to proceed?",
    "header": "Error",
    "options": [
      {"label": "Fix automatically", "description": "Add closing marker after section"},
      {"label": "Skip this marker", "description": "Continue with other markers"},
      {"label": "Open file", "description": "Let me fix it manually"},
      {"label": "Abort sync", "description": "Stop and rollback any changes"}
    ],
    "multiSelect": false
  }
]
```

---

## Backup Management

### Backup Cleanup

Old backups accumulate. Configure cleanup in config:

```json
{
  "backupConfig": {
    "keepCount": 5,
    "keepDays": 30,
    "autoCleanup": true
  }
}
```

After each sync, if `autoCleanup` is true:
1. List all backups: `ls -t [websitePath].backup.*`
2. Keep the most recent `keepCount` backups
3. Delete backups older than `keepDays`
4. Report: "Cleaned up 3 old backups"

### Manual Cleanup

```
questions:
[
  {
    "question": "Manage backups?",
    "header": "Backups",
    "options": [
      {"label": "List all", "description": "Show all backup files with sizes"},
      {"label": "Delete old", "description": "Remove backups older than 30 days"},
      {"label": "Delete all but latest", "description": "Keep only most recent backup"},
      {"label": "Configure", "description": "Change backup retention settings"}
    ],
    "multiSelect": false
  }
]
```

---

# PHASE A: SETUP

## Step 1: Load or Create Configuration

Check if config exists at `.claude/website-sync-config.json` in the current working directory.

**If config exists:** Read it and show Quick Mode menu (see above).

**If no config:** Ask about setup approach:

```
questions:
[
  {
    "question": "No website sync config found. How would you like to set up?",
    "header": "Setup",
    "options": [
      {"label": "Quick setup (Recommended)", "description": "Auto-detect settings, minimal questions"},
      {"label": "Guided wizard", "description": "Step-by-step configuration with all options"},
      {"label": "Import config", "description": "Load config from another project"}
    ],
    "multiSelect": false
  }
]
```

### If "Quick setup":

1. Auto-detect app path (current directory)
2. Auto-detect website path (look for sibling `-site` folder or `docs/` subdirectory)
3. Auto-detect website format
4. Default to: all metadata + features + FAQ, TestFlight change source, smart strategy, git deployment
5. Show summary and save config
6. Proceed to Quick Mode

### If "Guided wizard":

Continue to Step 2.

### If "Import config":

Ask for path to existing config file, copy and adapt paths.

---

## Step 2: First-Run Wizard - Gather Paths

Use AskUserQuestion:

```
questions:
[
  {
    "question": "What is the path to your app project?",
    "header": "App Path",
    "options": [
      {"label": "Current directory", "description": "Use the current working directory"},
      {"label": "Enter path", "description": "I'll provide a custom path"}
    ],
    "multiSelect": false
  }
]
```

If user selects "Enter path", ask them to type the path.

Then use AskUserQuestion:

```
questions:
[
  {
    "question": "What is the path to your website directory?",
    "header": "Website",
    "options": [
      {"label": "Sibling directory", "description": "Website is next to the app folder"},
      {"label": "Subdirectory", "description": "Website is inside the app folder (e.g., /docs)"},
      {"label": "Enter path", "description": "I'll provide a custom path"}
    ],
    "multiSelect": false
  }
]
```

Store the resolved paths.

---

## Step 3: Auto-Detect Website Format

Scan the website directory to detect format:

1. **Jekyll**: Look for `_config.yml`, `_layouts/`, `_includes/`
2. **Hugo**: Look for `config.toml`, `layouts/`, `archetypes/`
3. **Next.js/Nuxt**: Look for `next.config.js`, `nuxt.config.js`, `pages/`
4. **Static HTML**: Look for `index.html` without framework markers

Also detect templates:
- Jekyll: `_includes/*.html`, `_layouts/*.html`
- Hugo: `layouts/partials/*.html`
- Static: Scan for `<!-- #include -->` or common header/footer patterns

Report findings to user:

```
Detected website format: [FORMAT]
Template system: [Yes/No]
Template files found: [LIST]
```

Use AskUserQuestion to confirm:

```
questions:
[
  {
    "question": "Is this detection correct?",
    "header": "Confirm",
    "options": [
      {"label": "Yes, continue", "description": "Detection is accurate"},
      {"label": "No, let me specify", "description": "I'll provide the correct format"}
    ],
    "multiSelect": false
  }
]
```

---

# PHASE B: CONFIGURE

## Step 4: Select Content to Sync

Use AskUserQuestion:

```
questions:
[
  {
    "question": "What metadata should be synced?",
    "header": "Metadata",
    "options": [
      {"label": "Version & build info", "description": "Version numbers, build dates"},
      {"label": "Changelog", "description": "Update changelog from commits"},
      {"label": "Latest activity", "description": "Most recent commit info"}
    ],
    "multiSelect": true
  }
]
```

Then ask about rich content:

```
questions:
[
  {
    "question": "What page content should be synced?",
    "header": "Content",
    "options": [
      {"label": "Feature descriptions", "description": "Feature explanations from code"},
      {"label": "How-to guides", "description": "Step-by-step instructions"},
      {"label": "Screenshots", "description": "Capture and place app screenshots"},
      {"label": "FAQ entries", "description": "Questions and answers from code"}
    ],
    "multiSelect": true
  }
]
```

Then ask about documentation:

```
questions:
[
  {
    "question": "Any documentation to sync?",
    "header": "Docs",
    "options": [
      {"label": "User manual sections", "description": "In-app help synced to website"},
      {"label": "Help text", "description": "Contextual help from the app"},
      {"label": "Support pages", "description": "Troubleshooting and contact info"},
      {"label": "None", "description": "No additional docs"}
    ],
    "multiSelect": true
  }
]
```

---

## Step 5: Select Change Source

Use AskUserQuestion to determine what changes to sync:

```
questions:
[
  {
    "question": "What changes should be synced to the website?",
    "header": "Source",
    "options": [
      {"label": "Since last TestFlight (Recommended)", "description": "All changes since last archived build"},
      {"label": "Last commit only", "description": "Only the most recent commit"},
      {"label": "Specific commit range", "description": "I'll specify which commits to include"}
    ],
    "multiSelect": false
  }
]
```

### If "Since last TestFlight":

1. **Find TestFlight tags** in the app repository:
   ```bash
   git tag -l "testflight-*" --sort=-version:refname | head -5
   git tag -l "build-*" --sort=-version:refname | head -5
   ```

2. **If tags found**, show them to user:
   ```
   Found TestFlight tags:
   - testflight-build-25 (Feb 10, 2026)
   - testflight-build-24 (Feb 5, 2026)

   Syncing changes since: testflight-build-25
   ```

3. **If no tags found**, fall back to archive detection:
   ```bash
   # Find most recent archive
   ls -t ~/Library/Developer/Xcode/Archives/*/*.xcarchive 2>/dev/null | head -1
   ```

   Extract archive date and use:
   ```bash
   git log --since="[archive-date]" --oneline
   ```

4. **Get all commits since last TestFlight**:
   ```bash
   git log testflight-build-25..HEAD --oneline
   ```

5. **Store the reference point** for changelog generation.

### If "Last commit only":

```bash
git log -1 --oneline
```

### If "Specific commit range":

Ask user for the commit range:
```
questions:
[
  {
    "question": "How would you like to specify the range?",
    "header": "Range",
    "options": [
      {"label": "Number of commits", "description": "Last N commits (e.g., last 10)"},
      {"label": "Since date", "description": "All commits since a specific date"},
      {"label": "Commit hash range", "description": "From one commit to another"}
    ],
    "multiSelect": false
  }
]
```

Then gather the specific input and run:
- Number: `git log -N --oneline`
- Date: `git log --since="YYYY-MM-DD" --oneline`
- Hash range: `git log [start]..[end] --oneline`

---

## Step 6: Configure Update Strategy

Use AskUserQuestion:

```
questions:
[
  {
    "question": "How should updates be applied?",
    "header": "Strategy",
    "options": [
      {"label": "Smart (Recommended)", "description": "Only update sections matching code changes"},
      {"label": "Full scan", "description": "Check all sync markers regardless of changes"},
      {"label": "Manual review", "description": "Show all changes for approval before writing"}
    ],
    "multiSelect": false
  }
]
```

---

## Step 7: Screenshot Configuration (if selected)

If user selected Screenshots in Step 4:

Use AskUserQuestion:

```
questions:
[
  {
    "question": "How should screenshots be captured?",
    "header": "Screenshots",
    "options": [
      {"label": "Simulator capture", "description": "Use XcodeBuildMCP to capture from simulator"},
      {"label": "Manual upload", "description": "I'll provide screenshot files"},
      {"label": "Skip for now", "description": "Don't update screenshots this run"}
    ],
    "multiSelect": false
  }
]
```

If "Simulator capture": Ask for simulator name and screens to capture.

---

## Step 8: Deployment Options

Use AskUserQuestion:

```
questions:
[
  {
    "question": "Configure deployment?",
    "header": "Deploy",
    "options": [
      {"label": "Git commit & push", "description": "Commit changes and push to remote"},
      {"label": "Custom command", "description": "Run a custom deploy script"},
      {"label": "None", "description": "Just update files locally"}
    ],
    "multiSelect": false
  }
]
```

---

## Step 9: Save Configuration

Write config to `.claude/website-sync-config.json`:

```json
{
  "appPath": "[resolved app path]",
  "websitePath": "[resolved website path]",
  "detectedFormat": "[jekyll|hugo|nextjs|static-html]",
  "hasTemplates": true,
  "templateFiles": ["header.html", "footer.html"],
  "syncMetadata": ["version", "changelog", "lastcommit"],
  "syncContent": ["features", "howto", "screenshots", "faq"],
  "syncDocs": ["manual", "help", "support"],
  "contentSources": {
    "code": "Sources/",
    "markdown": "docs/website/",
    "config": ".claude/website-content.yaml"
  },
  "changeSource": "testflight",
  "updateStrategy": "smart",
  "screenshotConfig": {
    "method": "simulator",
    "simulator": "iPhone 16 Pro",
    "screens": ["Dashboard", "ItemDetail", "StuffScout"]
  },
  "deployment": "git",
  "testflightTagging": {
    "enabled": true,
    "prefix": "testflight-build-",
    "lastTag": "testflight-build-25"
  },
  "contentFiles": {
    "features": {
      "path": ".claude/website-content/features.json",
      "lastGenerated": "2026-02-18T14:35:00Z",
      "status": "current"
    },
    "faq": {
      "path": ".claude/website-content/faq.json",
      "lastGenerated": "2026-02-18T15:30:00Z",
      "status": "current"
    },
    "changelog": {
      "path": ".claude/website-content/changelog.json",
      "lastGenerated": "2026-02-18T16:30:00Z",
      "status": "current",
      "sourceFile": "whats-new.html"
    }
  },
  "driftDetection": {
    "enabled": true,
    "checkOnSync": true,
    "checkOnStatus": true,
    "autoRegenerate": false,
    "watchPaths": ["Sources/Features/", "Sources/Views/Tools/"]
  },
  "lastRun": null,
  "lastSyncedCommit": null
}
```

---

# PHASE C: EXECUTE

## Step 10: Select Update Scope

Use AskUserQuestion:

```
questions:
[
  {
    "question": "What should be updated?",
    "header": "Scope",
    "options": [
      {"label": "All markers", "description": "Update every sync marker found"},
      {"label": "Select pages", "description": "Choose which pages to update"},
      {"label": "Select markers", "description": "Choose specific markers to update"}
    ],
    "multiSelect": false
  }
]
```

### If "Select pages":

1. List all pages with markers:
   ```
   Pages with sync markers:
   ☐ index.html (2 markers: VERSION, FEATURES)
   ☐ whats-new.html (3 markers: CURRENT_VERSION, LASTCOMMIT, CHANGELOG)
   ☐ features.html (5 markers: FEATURE:Dashboard, FEATURE:StuffScout, ...)
   ☐ support.html (4 markers: FAQ:Sync, FAQ:Photos, HELP:Warranties, ...)
   ```

2. Use AskUserQuestion with multiSelect to let user pick pages.

3. Only markers on selected pages will be updated.

### If "Select markers":

1. List all markers found across the site:
   ```
   Available markers:

   Metadata:
   ☐ VERSION (index.html)
   ☐ CHANGELOG (whats-new.html)
   ☐ LASTCOMMIT (whats-new.html)

   Content:
   ☐ FEATURE:Dashboard (features.html)
   ☐ FEATURE:StuffScout (features.html)
   ☐ HOWTO:AddingPhotos (support.html)

   Screenshots:
   ☐ SCREENSHOT:Dashboard (features.html)
   ☐ SCREENSHOT:ItemDetail (features.html)
   ```

2. Use AskUserQuestion with multiSelect to let user pick specific markers.

3. Only selected markers will be updated.

---

## Step 11: Execute Sync

### 11.1 Create Backup

Create timestamped backup of website directory:
```
cp -r [websitePath] [websitePath].backup.[timestamp]
```

### 11.2 Gather Source Data

**Based on Change Source (from Step 5):**

- **Since TestFlight**: Use commits from `git log [last-tag]..HEAD`
- **Last commit only**: Use `git log -1`
- **Specific range**: Use the user-specified range

**For Smart strategy:**
Run `git diff --name-only [change-source-ref]` in app directory to find changed files.
Map changed files to sync markers.

**For Full scan:**
Find all sync markers in website files.

### 11.3 Find Sync Markers

Search website files for markers:
```
<!-- SYNC:FileName.swift -->
...content...
<!-- /SYNC:FileName.swift -->
```

Also look for:
- `<!-- SYNC:VERSION -->` - App version from Info.plist or Package.swift
- `<!-- SYNC:CHANGELOG -->` - Git log formatted as changelog
- `<!-- SYNC:FEATURE:SectionName -->` - Feature lists from code comments
- `<!-- SYNC:LASTCOMMIT -->` - Output of `git log -1 --stat`
- `<!-- SYNC:TESTFLIGHT_CHANGES -->` - All commits since last TestFlight build

### 11.4 Extract Content from Codebase

For each marker found, extract content based on marker type:

#### Metadata Markers

| Marker | Source |
|--------|--------|
| `VERSION` | Info.plist, Package.swift, or version file |
| `CHANGELOG` | Git log based on change source selection |
| `LASTCOMMIT` | `git log -1 --stat` |
| `TESTFLIGHT_CHANGES` | `git log [last-tag]..HEAD` formatted as release notes |

#### Content Markers

| Marker | Source Priority |
|--------|-----------------|
| `FEATURE:Name` | 1. `.claude/website-content/features.json` → 2. `// WEBSITE:FEATURE:Name` in code → 3. `docs/website/FEATURE-Name.md` |
| `HOWTO:Name` | 1. `// WEBSITE:HOWTO:Name` in code → 2. `docs/website/HOWTO-Name.md` |
| `SCREENSHOT:Name` | Capture from simulator + caption from `// WEBSITE:SCREENSHOT:Name` |
| `FAQ:Name` | 1. `.claude/website-content/faq.json` → 2. `// WEBSITE:FAQ:Name` in code → 3. `docs/website/FAQ-Name.md` |
| `CHANGELOG` | 1. `.claude/website-content/changelog.json` → 2. Git log |
| `TESTFLIGHT_CHANGES` | 1. `.claude/website-content/changelog.json` (current release) → 2. `git log [last-tag]..HEAD` |
| `CURRENT_VERSION` | 1. `.claude/website-content/changelog.json` → 2. Info.plist |
| `HELP:Name` | 1. Help strings in code → 2. Localizable.strings with `WEBSITE_HELP_` prefix |
| `MANUAL:Name` | 1. In-app onboarding text → 2. `docs/website/MANUAL-Name.md` |
| `PRICING` | 1. `.claude/website-content/pricing.json` → 2. StoreKit config → 3. `.claude/website-content.yaml` |

#### Extraction Process

1. **Check JSON content files first** (highest priority):
   ```
   .claude/website-content/features.json  → for FEATURE:* markers
   .claude/website-content/faq.json       → for FAQ:* markers
   .claude/website-content/changelog.json → for CHANGELOG, TESTFLIGHT_CHANGES, CURRENT_VERSION markers
   .claude/website-content/pricing.json   → for PRICING marker
   ```

   **For FEATURE markers:** Look up by `id` field
   - `<!-- SYNC:FEATURE:stuff-scout -->` → find `"id": "stuff-scout"`
   - Generate HTML from `name`, `tagline`, `description`, `bullets`

   **For FAQ markers:** Look up by `marker` field (multiple FAQs can share one marker)
   - `<!-- SYNC:FAQ:iCloudSync -->` → find all entries with `"marker": "iCloudSync"`
   - Generate `<details>` blocks from `question` and `answer`
   - Group multiple FAQs under the same marker for consolidated sections

2. **Search code for markers** (if not in JSON):
   ```bash
   grep -r "// WEBSITE:" --include="*.swift" [appPath]/Sources/
   ```

3. **Parse marker blocks**: Extract content between `// WEBSITE:TYPE:Name` and `// /WEBSITE`

4. **Check markdown fallback**: If no code marker, look for `docs/website/TYPE-Name.md`

5. **Check config fallback**: For structured content, check `.claude/website-content.yaml`

6. **Format for HTML**: Convert JSON/markdown to HTML, wrap in appropriate tags based on marker type

### 11.5 Generate Updates

For each section with changes:
- Show diff preview to user
- If "Manual review" strategy, use AskUserQuestion for each change:

```
questions:
[
  {
    "question": "Apply this change to [filename]?",
    "header": "Review",
    "options": [
      {"label": "Yes", "description": "Apply this update"},
      {"label": "No", "description": "Skip this update"},
      {"label": "Edit", "description": "Let me modify before applying"}
    ],
    "multiSelect": false
  }
]
```

### 11.6 Apply Updates

Use Edit tool to update each section between sync markers.
Preserve content outside markers.

---

## Step 12: Screenshots (if configured)

If screenshot capture was selected:

1. Use `mcp__XcodeBuildMCP__build_run_sim` to launch app
2. For each screen:
   - Navigate to the screen (use `mcp__XcodeBuildMCP__tap`, `mcp__XcodeBuildMCP__type_text`)
   - Use `mcp__XcodeBuildMCP__screenshot` to capture
   - Save to configured screenshot path
3. Use `mcp__XcodeBuildMCP__stop_app_sim` when done

---

## Step 13: Validation

Run validation checks:

1. **HTML validation**: Check for unclosed tags, broken links
2. **Image validation**: Verify all referenced images exist
3. **Link validation**: Check internal links resolve
4. **Template validation**: Ensure includes/partials exist

Report any issues found.

---

## Step 14: Deployment (if configured)

**For Git:**
```bash
cd [websitePath]
git add -A
git commit -m "Sync website with app [version] - [timestamp]"
git push
```

**For Custom command:**
Run the configured deploy command.

---

## Step 15: TestFlight Tagging (Optional)

After successful sync, offer to tag the current commit for future reference:

Use AskUserQuestion:

```
questions:
[
  {
    "question": "Create a TestFlight tag for this sync point?",
    "header": "Tag",
    "options": [
      {"label": "Yes, auto-name", "description": "Create tag: testflight-build-[N+1]"},
      {"label": "Yes, custom name", "description": "I'll provide the tag name"},
      {"label": "No", "description": "Skip tagging"}
    ],
    "multiSelect": false
  }
]
```

### If "Yes, auto-name":

1. Find the highest existing build number:
   ```bash
   git tag -l "testflight-build-*" | sort -V | tail -1
   ```

2. Increment and create new tag:
   ```bash
   git tag testflight-build-26
   git push origin testflight-build-26
   ```

### If "Yes, custom name":

Ask for tag name, then:
```bash
git tag [user-provided-name]
git push origin [user-provided-name]
```

---

## Step 16: Summary

Output summary:

```
Website Sync Complete

Updated:
- [X] sections updated
- [X] screenshots captured
- [X] files modified

Deployment: [status]

Backup location: [path]
To rollback: cp -r [backup] [websitePath]
```

Update `lastRun` in config file.

---

# PHASE D: ANALYZE

## Step 17: Completeness Check

Compare code markers to website markers to ensure nothing is missing.

### 17.1 Scan Code for All Content Markers

Search the codebase for all `// WEBSITE:` blocks:

```bash
grep -r "// WEBSITE:" --include="*.swift" [appPath]/Sources/ | grep -v "/WEBSITE"
```

Group by type:
```
Content markers found in code:

FEATURE: (8 total)
  - Dashboard, StuffScout, SmartScanner, RecallCheck
  - Warranties, Maintenance, Loans, Export

HOWTO: (5 total)
  - AddingPhotos, QuickAdd, UsingStuffScout, TrackingLoans, ExportingData

FAQ: (12 total)
  - DataSync, PhotoStorage, Pricing, CancelSubscription, ...

HELP: (6 total)
  - WarrantyTypes, CoveragePhases, MaintenanceFrequency, ...
```

### 17.2 Scan Website for All Sync Markers

Search all HTML files for `<!-- SYNC:` markers:

```bash
grep -r "<!-- SYNC:" --include="*.html" [websitePath]/
```

Group by page and type.

### 17.3 Compare and Report

```
Completeness Report

FEATURE markers:
  ✓ In code AND on website: 6
  ✗ In code but MISSING from website: 2
    - RecallCheck (add to features.html?)
    - SmartScanner (add to features.html?)
  ? On website but NOT in code: 0

HOWTO markers:
  ✓ In code AND on website: 3
  ✗ In code but MISSING from website: 2
    - TrackingLoans (add to support.html?)
    - ExportingData (add to support.html?)

FAQ markers:
  ✓ In code AND on website: 8
  ✗ In code but MISSING from website: 4

Overall completeness: 17/24 (71%)
```

### 17.4 Offer to Fix Gaps

Use AskUserQuestion:

```
questions:
[
  {
    "question": "How should missing content be handled?",
    "header": "Gaps",
    "options": [
      {"label": "Add all missing markers", "description": "Insert markers for all gaps found"},
      {"label": "Review one by one", "description": "Approve each addition individually"},
      {"label": "Export list", "description": "Save gap report to file for later"},
      {"label": "Skip", "description": "Just show the report"}
    ],
    "multiSelect": false
  }
]
```

---

## Step 18: Content Gap Analysis

Intelligent analysis that finds missing content even WITHOUT markers.

### 18.1 Scan App Structure

Analyze the codebase to find all documentable content:

```
Scanning app structure...

Views/Screens found:
  - DashboardView.swift
  - ItemDetailView.swift
  - StuffScoutView.swift
  - WarrantyFormView.swift
  - MaintenanceView.swift
  - LoanTrackingView.swift
  - RecallCheckView.swift
  - DataReviewView.swift
  - ExportView.swift
  - SettingsView.swift
  ... (47 total)

Features detected (folders in Sources/Features/):
  - Dashboard, StuffScout, SmartScanner, Warranties
  - Maintenance, Loans, RecallCheck, DataReview
  - Export, Import, Insurance, Depreciation
  ... (15 total)

User-facing strings:
  - Localizable.strings: 234 entries
  - Help strings: 18 entries
  - Error messages: 42 entries

Settings/Preferences:
  - Notification settings: 8 options
  - Sync settings: 4 options
  - Display settings: 6 options
```

### 18.2 Scan Website Content

Analyze website pages for actual content (not just markers):

```
Scanning website content...

features.html:
  - Sections found: 8
  - Features mentioned: Dashboard, Stuff Scout, Warranties,
    Maintenance, Loans, Export, Import, Insights

whats-new.html:
  - Version entries: 5
  - Last updated: Feb 10, 2026

support.html:
  - FAQ entries: 15
  - How-to guides: 6
  - Contact methods: 3

beta-testing-guide.html:
  - Beta features documented: 4
  - Known issues listed: 7
  - Feedback instructions: Yes
```

### 18.3 Cross-Reference and Find Gaps

Compare app capabilities to website documentation:

```
Content Gap Analysis

═══════════════════════════════════════════════════════
FEATURES PAGE
═══════════════════════════════════════════════════════

App features NOT documented on website:
  ✗ RecallCheck
    Source: Sources/Features/RecallCheck/
    Description from code: "Check products against CPSC recall database"
    Suggested section: Add to features.html

  ✗ DataReview
    Source: Sources/Features/DataReview/
    Description from code: "Review data quality, find missing photos"
    Suggested section: Add to features.html

  ✗ DuplicateFinder
    Source: Sources/Features/DuplicateFinder/
    Description from code: "Identify and merge duplicate items"
    Suggested section: Add to features.html

Website content with no matching app feature:
  ? "Cloud Backup" mentioned but no CloudBackup feature folder
    Action: Verify if outdated or rename to match code

Coverage: 10/13 features documented (77%)

═══════════════════════════════════════════════════════
FAQ / SUPPORT PAGE
═══════════════════════════════════════════════════════

Common user questions NOT in FAQ:
  ✗ "How do I delete my account?"
    Source: Found in support emails / common query

  ✗ "Why are my photos not syncing?"
    Source: Error state in PhotoSyncManager.swift

  ✗ "How do I restore a deleted item?"
    Source: Feature exists in TrashView.swift

Error states NOT documented:
  ✗ "iCloud unavailable" — no troubleshooting guide
  ✗ "Subscription expired" — no FAQ entry
  ✗ "Network timeout" — no help text

Coverage: 15/23 potential FAQ topics covered (65%)

═══════════════════════════════════════════════════════
BETA TESTING GUIDE
═══════════════════════════════════════════════════════

Recent features NOT in beta guide:
  ✗ Async photo decoding (added in last 5 commits)
  ✗ Coverage phase notifications (new feature)

TestFlight-specific content missing:
  ✗ How to submit feedback via TestFlight
  ✗ Known limitations of beta build
  ✗ Features in development (from TODO/FIXME comments)

═══════════════════════════════════════════════════════
WHAT'S NEW PAGE
═══════════════════════════════════════════════════════

Commits since last website update: 12

User-facing changes NOT documented:
  ✗ "Add async photo decoding" — performance improvement
  ✗ "Fix warranty notification timing" — bug fix
  ✗ "Add coverage phase alerts" — new feature

Coverage: Last sync was 8 days ago, 3 notable changes undocumented
```

### 18.4 Generate Content Suggestions

For each gap, generate suggested content from code analysis:

```
Suggested Content Additions

1. RecallCheck feature (for features.html)
   ─────────────────────────────────────
   Extracted from: RecallCheckView.swift, RecallService.swift

   <h3>Recall Check</h3>
   <p>Automatically check your products against the CPSC recall
   database. Get notified if any of your items have been recalled
   and see recommended actions.</p>
   <ul>
     <li>Searches by product name and manufacturer</li>
     <li>Shows hazard details and remedy options</li>
     <li>Links to official CPSC recall notices</li>
   </ul>

2. Photo Sync FAQ (for support.html)
   ─────────────────────────────────────
   Extracted from: PhotoSyncManager.swift error handling

   <details>
     <summary>Why are my photos not syncing?</summary>
     <p>Photos sync via iCloud. Check that:</p>
     <ul>
       <li>You're signed into iCloud on all devices</li>
       <li>iCloud Drive is enabled for Stuffolio</li>
       <li>You have available iCloud storage</li>
       <li>You're connected to WiFi (large photos)</li>
     </ul>
   </details>
```

### 18.5 Offer to Add Content

Use AskUserQuestion:

```
questions:
[
  {
    "question": "Content gaps found. What would you like to do?",
    "header": "Gaps",
    "options": [
      {"label": "Add all suggested content", "description": "Insert generated content for all gaps"},
      {"label": "Review suggestions", "description": "Approve each addition individually"},
      {"label": "Add markers only", "description": "Insert empty markers to fill in later"},
      {"label": "Export report", "description": "Save analysis to file"}
    ],
    "multiSelect": false
  }
]
```

### If "Review suggestions":

For each gap, show the suggested content and ask:

```
questions:
[
  {
    "question": "Add RecallCheck to features.html?",
    "header": "Add",
    "options": [
      {"label": "Yes, use suggestion", "description": "Add the generated content"},
      {"label": "Yes, but edit first", "description": "Let me modify before adding"},
      {"label": "Skip", "description": "Don't add this content"},
      {"label": "Mark as N/A", "description": "This doesn't need documentation"}
    ],
    "multiSelect": false
  }
]
```

---

## Step 19: Marker Audit

Scan the website to assess marker coverage and suggest improvements.

### 19.1 Scan Website Pages

Find all HTML files in the website directory:
```bash
find [websitePath] -name "*.html" -type f
```

For each page, count:
- Total sync markers found
- Types of markers (VERSION, CHANGELOG, FEATURES, etc.)

### 19.2 Detect Unmarked Content

Scan each page for content that COULD be synced but has no marker:

| Pattern to Find | Suggests Adding |
|-----------------|-----------------|
| Version numbers (e.g., "1.0", "v2.1.0") | `SYNC:VERSION` |
| "What's New" or "Changelog" sections | `SYNC:CHANGELOG` or `SYNC:TESTFLIGHT_CHANGES` |
| "Features" or bullet lists under feature headings | `SYNC:FEATURE:SectionName` |
| "Latest update" or recent activity text | `SYNC:LASTCOMMIT` |
| Manual/documentation sections | `SYNC:Sources/Path/File.swift` |

### 19.3 Report Coverage

Output a summary:

```
Marker Audit Results

Pages scanned: [N]

✓ Pages with markers:
  - index.html (1 marker: VERSION)
  - whats-new.html (3 markers: CURRENT_VERSION, LASTCOMMIT, CHANGELOG)

✗ Pages without markers:
  - features.html
  - support.html
  - privacy.html

Suggestions:
  - index.html line 45: Found "Version 1.0" — add SYNC:VERSION marker?
  - features.html line 120: Found "Features" heading with list — add SYNC:FEATURES marker?
  - changelog.html line 30: Found "What's New" section — add SYNC:TESTFLIGHT_CHANGES marker?

Coverage: [X]% of pages have at least one sync marker
```

### 19.4 Offer to Add Markers

Use AskUserQuestion:

```
questions:
[
  {
    "question": "Would you like to add suggested markers?",
    "header": "Add",
    "options": [
      {"label": "Add all suggestions", "description": "Insert all recommended markers"},
      {"label": "Review one by one", "description": "Approve each marker individually"},
      {"label": "Skip", "description": "Just show the report, don't modify files"}
    ],
    "multiSelect": false
  }
]
```

### If "Add all suggestions":

For each suggestion, use Edit tool to wrap the content with sync markers.

### If "Review one by one":

For each suggestion, show the context and use AskUserQuestion:

```
questions:
[
  {
    "question": "Add SYNC:VERSION marker to index.html line 45?",
    "header": "Marker",
    "options": [
      {"label": "Yes", "description": "Add this marker"},
      {"label": "No", "description": "Skip this one"},
      {"label": "Custom", "description": "Use a different marker type"}
    ],
    "multiSelect": false
  }
]
```

---

## Rollback

Restore website to a previous state.

### List Available Backups

```bash
ls -lt [websitePath].backup.* | head -10
```

Show with details:
```
Available Restore Points

1. Feb 18, 2026 6:24 AM (2 hours ago)
   Backup: website.backup.20260218-062430
   Size: 12.4 MB
   Commit synced: 28aeaa2 "Add async photo decoding"

2. Feb 10, 2026 2:15 PM (8 days ago)
   Backup: website.backup.20260210-141500
   Size: 12.1 MB
   Commit synced: a1b2c3d "Fix warranty display"

3. Feb 5, 2026 10:30 AM (13 days ago)
   Backup: website.backup.20260205-103000
   Size: 11.8 MB
   Commit synced: x9y8z7w "Initial sync"
```

### Select Backup

```
questions:
[
  {
    "question": "Which backup to restore?",
    "header": "Restore",
    "options": [
      {"label": "Most recent", "description": "Feb 18, 2026 6:24 AM"},
      {"label": "Choose from list", "description": "Select a specific backup"},
      {"label": "By date", "description": "Find backup from a specific date"},
      {"label": "Cancel", "description": "Don't restore"}
    ],
    "multiSelect": false
  }
]
```

### Restore Options

```
questions:
[
  {
    "question": "How should the restore be performed?",
    "header": "Method",
    "options": [
      {"label": "Full restore", "description": "Replace entire website with backup"},
      {"label": "Selective restore", "description": "Choose specific files to restore"},
      {"label": "Preview diff", "description": "See what would change before restoring"}
    ],
    "multiSelect": false
  }
]
```

### If "Selective restore":

```
Files that differ from backup:
☐ index.html (VERSION marker changed)
☐ whats-new.html (LASTCOMMIT, CHANGELOG changed)
☐ features.html (FEATURE:RecallCheck added)
☐ support.html (FAQ entries updated)
```

Let user select which files to restore.

### Execute Restore

1. **Create safety backup** of current state:
   ```bash
   cp -r [websitePath] [websitePath].pre-rollback.[timestamp]
   ```

2. **Restore selected backup**:
   ```bash
   cp -r [backupPath]/* [websitePath]/
   ```

3. **Update config** to reflect rollback:
   - Set `lastSyncedCommit` to backup's commit
   - Add rollback entry to history

4. **Report**:
   ```
   Restore Complete

   Restored from: website.backup.20260218-062430
   Files restored: 4
   Safety backup: website.pre-rollback.20260218-084500

   Note: Git status may show changes. Commit or discard as needed.
   ```

---

# REFERENCE

## Sync Marker Reference

### Metadata Markers

Basic app information synced automatically:

```html
<!-- SYNC:VERSION -->
1.0.0
<!-- /SYNC:VERSION -->

<!-- SYNC:CHANGELOG -->
- v1.0.0: Initial release
<!-- /SYNC:CHANGELOG -->

<!-- SYNC:LASTCOMMIT -->
commit abc123...
<!-- /SYNC:LASTCOMMIT -->

<!-- SYNC:TESTFLIGHT_CHANGES -->
- Add async photo decoding
- Fix scroll performance
<!-- /SYNC:TESTFLIGHT_CHANGES -->
```

---

### Content Markers

Rich content synced from your codebase:

#### Feature Descriptions
```html
<!-- SYNC:FEATURE:StuffScout -->
<h3>Stuff Scout</h3>
<p>AI-powered identification for antiques and collectibles...</p>
<!-- /SYNC:FEATURE:StuffScout -->
```

**Source:** Pulls from code comment block:
```swift
// WEBSITE:FEATURE:StuffScout
// AI-powered identification for antiques and collectibles.
// Take a photo and get instant identification, history, and value estimates.
// /WEBSITE
```

#### How-To Guides
```html
<!-- SYNC:HOWTO:AddingPhotos -->
<ol>
  <li>Open the item detail view</li>
  <li>Tap the camera icon</li>
  ...
</ol>
<!-- /SYNC:HOWTO:AddingPhotos -->
```

**Source:** Pulls from markdown or code:
```swift
// WEBSITE:HOWTO:AddingPhotos
// 1. Open the item detail view
// 2. Tap the camera icon
// 3. Choose "Take Photo" or "Choose from Library"
// 4. Crop and adjust as needed
// 5. Tap Save
// /WEBSITE
```

#### Screenshots with Captions
```html
<!-- SYNC:SCREENSHOT:Dashboard -->
<figure>
  <img src="screenshots/dashboard.png" alt="Dashboard view">
  <figcaption>The Dashboard shows your inventory at a glance</figcaption>
</figure>
<!-- /SYNC:SCREENSHOT:Dashboard -->
```

**Source:** Captures from simulator + pulls caption from:
```swift
// WEBSITE:SCREENSHOT:Dashboard
// The Dashboard shows your inventory at a glance
// /WEBSITE
```

#### FAQ Entries
```html
<!-- SYNC:FAQ:DataSync -->
<details>
  <summary>How does iCloud sync work?</summary>
  <p>Your data syncs automatically across all devices...</p>
</details>
<!-- /SYNC:FAQ:DataSync -->
```

**Source:** Pulls from FAQ config or code:
```swift
// WEBSITE:FAQ:DataSync
// Q: How does iCloud sync work?
// A: Your data syncs automatically across all devices signed into the same iCloud account. Changes typically appear within seconds.
// /WEBSITE
```

#### In-App Help Text
```html
<!-- SYNC:HELP:WarrantyTypes -->
<div class="help-section">
  <p>Warranties can be Standard, Extended, or Lifetime...</p>
</div>
<!-- /SYNC:HELP:WarrantyTypes -->
```

**Source:** Pulls from your app's help strings or localization:
```swift
// In HelpStrings.swift or Localizable.strings
// WEBSITE:HELP:WarrantyTypes
static let warrantyTypesHelp = """
Warranties can be Standard, Extended, or Lifetime.
- Standard: Manufacturer's original warranty
- Extended: Purchased additional coverage
- Lifetime: Covered for the life of the product
"""
// /WEBSITE
```

#### Pricing & Plans
```html
<!-- SYNC:PRICING -->
<div class="pricing-table">
  <div class="plan">
    <h3>Monthly</h3>
    <p class="price">$2.99/month</p>
  </div>
  ...
</div>
<!-- /SYNC:PRICING -->
```

**Source:** Pulls from StoreKit configuration or pricing config file.

#### User Manual Sections
```html
<!-- SYNC:MANUAL:GettingStarted -->
<section>
  <h2>Getting Started</h2>
  <p>Welcome to Stuffolio...</p>
</section>
<!-- /SYNC:MANUAL:GettingStarted -->
```

**Source:** Pulls from in-app onboarding text or documentation files.

---

### Content Source Priority

When extracting content, check these locations in order:

1. **JSON content files** — `.claude/website-content/features.json`, `faq.json`, `pricing.json`
2. **Code comments** — `// WEBSITE:TYPE:Name` blocks in Swift/JS/Python files
3. **Markdown docs** — `docs/website/TYPE-Name.md` files
4. **Config files** — `.claude/website-content.yaml`
5. **Localization** — `Localizable.strings` entries prefixed with `WEBSITE_`

#### Why JSON First?

JSON content files are the **preferred source** because they:
- Are generated from codebase analysis (single source of truth)
- Include structured metadata (category, icon, premium status)
- Can be edited without touching code
- Support multiple output formats (website, App Store, press kit)

---

### Code Markers for Content

In your Swift code, mark extractable content:

```swift
// WEBSITE:FEATURE:Dashboard
// Quick access to your entire inventory with smart filtering,
// search, and at-a-glance status for warranties and maintenance.
// /WEBSITE

// WEBSITE:HOWTO:QuickAdd
// 1. Tap the + button on the Dashboard
// 2. Choose "Quick Add" for fast entry
// 3. Enter the item name and tap Save
// 4. Add details later by editing the item
// /WEBSITE

// WEBSITE:FAQ:PhotoStorage
// Q: Where are my photos stored?
// A: Photos are stored in iCloud and synced across your devices.
// They don't count against your device storage.
// /WEBSITE
```

---

### Markdown Content Files

Alternatively, create markdown files in `docs/website/`:

```
docs/website/
├── FEATURE-Dashboard.md
├── FEATURE-StuffScout.md
├── HOWTO-AddingPhotos.md
├── HOWTO-QuickAdd.md
├── FAQ-PhotoStorage.md
└── HELP-WarrantyTypes.md
```

Each file contains the content to sync:

```markdown
<!-- docs/website/FEATURE-StuffScout.md -->
# Stuff Scout

AI-powered identification for antiques, collectibles, and unknown items.

Take a photo of any item and Stuff Scout will:
- Identify what it is
- Research its history and origins
- Estimate current market value
- Suggest how to catalog it
```

---

### Config-Based Content

For structured content like pricing, use a config file:

```yaml
# .claude/website-content.yaml
pricing:
  monthly:
    name: "Monthly"
    price: "$2.99"
    period: "month"
  annual:
    name: "Annual"
    price: "$19.99"
    period: "year"
    savings: "Save 44%"

features:
  highlights:
    - "Unlimited items"
    - "iCloud sync"
    - "AI identification"
    - "Warranty tracking"
```

---

### JSON Content Files (Recommended)

Store structured content in `.claude/website-content/` for the best sync experience.

#### features.json

Generated from codebase analysis. Used for `SYNC:FEATURE:*` markers.

```json
{
  "generatedFrom": "codebase-analysis",
  "generatedDate": "2026-02-18",
  "appVersion": "1.0",
  "categories": {
    "ai": { "name": "AI Features", "order": 1, "icon": "sparkles" },
    "core": { "name": "Core Experience", "order": 2, "icon": "square.grid.2x2" }
  },
  "features": [
    {
      "id": "stuff-scout",
      "name": "Stuff Scout",
      "tagline": "AI-powered identification",
      "description": "Camera-first AI identification for antiques and collectibles.",
      "bullets": [
        "Photo-based product identification",
        "Automatic warranty extraction",
        "Price history analysis"
      ],
      "category": "ai",
      "icon": "camera.viewfinder",
      "isPremium": true,
      "isAIPowered": true,
      "addedInVersion": "1.0",
      "sourceFiles": ["Sources/Features/StuffScout/"]
    }
  ]
}
```

#### How Features Are Matched

When syncing `<!-- SYNC:FEATURE:stuff-scout -->`:

1. Look up `features.json` for entry with `"id": "stuff-scout"`
2. Generate HTML from `name`, `tagline`, `description`, `bullets`
3. If not found, fall back to code markers or markdown

#### Generating features.json

Run `/update-website --regenerate-features` to create or update:

```
Analyze the codebase and create features.json based on:
- Feature folders in Sources/Features/
- View files and their capabilities
- Manager files and services
- Existing documentation
```

The skill will suggest regenerating when source files change (drift detection).

#### Generating faq.json

Run `/update-website --regenerate-faq` to create or update:

```
Analyze the website and codebase to create faq.json based on:
- Existing FAQ markers in support.html
- FAQ content within <!-- SYNC:FAQ:* --> blocks
- Code comments with // WEBSITE:FAQ: markers
- Error handling patterns (for troubleshooting FAQs)
```

The generated faq.json links each FAQ to:
- Its website marker (for sync matching)
- Related features from features.json
- A category for organization

#### faq.json

Generated from website analysis or codebase. Used for `SYNC:FAQ:*` markers.

```json
{
  "generatedFrom": "website-analysis",
  "generatedDate": "2026-02-18T15:30:00Z",
  "appVersion": "1.0",
  "sourceSnapshot": {
    "websiteFile": "support.html",
    "faqMarkers": ["AddingItems", "StuffScout", "iCloudSync", "Privacy", ...]
  },
  "categories": {
    "getting-started": { "name": "Getting Started", "order": 1, "icon": "arrow.right.circle" },
    "ai-features": { "name": "AI Features", "order": 2, "icon": "sparkles" },
    "data-sync": { "name": "Data & Sync", "order": 3, "icon": "icloud" },
    "warranties": { "name": "Warranties", "order": 4, "icon": "shield.checkerboard" },
    "troubleshooting": { "name": "Troubleshooting", "order": 9, "icon": "wrench.and.screwdriver" }
  },
  "faqs": [
    {
      "id": "sync-across-devices",
      "question": "Does Stuffolio sync across devices?",
      "answer": "Yes, if you enable iCloud sync. Your data syncs through your personal iCloud account — we never see it.",
      "category": "data-sync",
      "marker": "iCloudSync",
      "relatedFeatures": ["icloud-sync"]
    }
  ],
  "summary": {
    "totalFaqs": 57,
    "byCategory": { "getting-started": 7, "ai-features": 7, "troubleshooting": 10 },
    "markers": 18
  }
}
```

#### How FAQs Are Matched

When syncing `<!-- SYNC:FAQ:iCloudSync -->`:

1. Look up `faq.json` for entries with `"marker": "iCloudSync"`
2. Multiple FAQs can share the same marker (grouped content)
3. Generate HTML `<details>` blocks from `question` and `answer`
4. If not found, fall back to code markers or markdown
```

#### changelog.json

Generated from whats-new.html extraction. Used for `SYNC:CHANGELOG`, `SYNC:TESTFLIGHT_CHANGES`, and `SYNC:CURRENT_VERSION` markers.

```json
{
  "generatedFrom": "website-extraction",
  "generatedDate": "2026-02-18T16:30:00Z",
  "appVersion": "1.0",
  "currentBuild": 25,
  "currentStatus": "beta",
  "sourceSnapshot": {
    "websiteFile": "whats-new.html",
    "lastTag": "testflight-build-25",
    "extractedBuilds": 10
  },
  "releases": [
    {
      "version": "1.0",
      "build": 25,
      "date": "2026-02-10",
      "tag": "testflight-build-25",
      "status": "beta",
      "isCurrent": true,
      "summary": "Critical fixes for App Store readiness...",
      "highlights": [
        {
          "label": "Critical Fix",
          "title": "CloudKit Batch Sync",
          "description": "Replaced sequential record uploads with batch operations..."
        }
      ],
      "changes": {
        "new": ["Feature 1", "Feature 2"],
        "improved": ["Improvement 1"],
        "fixed": ["Bug fix 1"],
        "changed": ["Change 1"]
      }
    }
  ],
  "summary": {
    "totalReleases": 10,
    "currentVersion": "1.0",
    "currentBuild": 25,
    "firstBetaDate": "2025-12-20",
    "latestReleaseDate": "2026-02-10",
    "archivedReleases": 2
  }
}
```

#### How Changelog Is Matched

When syncing changelog markers:

1. `<!-- SYNC:CURRENT_VERSION -->` → Uses `currentBuild` and `currentStatus`
2. `<!-- SYNC:TESTFLIGHT_CHANGES -->` → Uses the current release's `changes` object
3. `<!-- SYNC:CHANGELOG -->` → Uses all non-archived releases

#### Generating changelog.json

Run `/update-website --regenerate-changelog` to create or update:

```
Extract release information from whats-new.html based on:
- Version/build headers (e.g., "Build 25 — February 10, 2026")
- Summary paragraphs
- Highlight cards
- Categorized change lists (New, Improved, Fixed, Changed)
```

The generated changelog.json:
- Tracks all releases from initial beta to current
- Marks older releases as `archived: true` when no longer shown
- Links to TestFlight tags for drift detection
- Provides structured data for multiple output formats

#### pricing.json

For `SYNC:PRICING` marker:

```json
{
  "plans": [
    {
      "id": "monthly",
      "name": "Monthly",
      "price": 2.99,
      "currency": "USD",
      "period": "month",
      "features": ["All premium features", "Cancel anytime"]
    },
    {
      "id": "annual",
      "name": "Annual",
      "price": 19.99,
      "currency": "USD",
      "period": "year",
      "savings": "Save 44%",
      "features": ["All premium features", "Best value"]
    }
  ]
}
```
