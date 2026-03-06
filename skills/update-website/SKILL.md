---
name: update-website
description: 'Sync website content with app codebase - features, changelog, FAQ, docs. Triggers: "update website", "sync website", "website sync".'
version: 3.0.0
author: Terry Nyberg
license: MIT
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, AskUserQuestion]
metadata:
  tier: execution
  category: release
---

# Website Sync Skill

> Sync Stuffolio website (static HTML + JSON content files) with the app codebase.

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

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
┌───────────────────────────────────────────────────┐
│  PHASE A: SETUP (First Run Only)                  │
│  Steps 1-2: Paths, config creation                │
├───────────────────────────────────────────────────┤
│  PHASE B: CONFIGURE                               │
│  Steps 3-6: Content, change source, strategy      │
├───────────────────────────────────────────────────┤
│  PHASE C: EXECUTE                                 │
│  Steps 7-10: Scope, sync, validate, summary       │
├───────────────────────────────────────────────────┤
│  PHASE D: ANALYZE (On Demand)                     │
│  Steps 11-13: Completeness, gaps, marker audit    │
└───────────────────────────────────────────────────┘
```

---

## Permissions

```
AskUserQuestion with questions:
[
  {
    "question": "How should Claude handle bash commands, file edits, and writes during this skill run?",
    "header": "Permissions",
    "options": [
      {"label": "Autonomous (Recommended)", "description": "Proceed without per-action approval prompts — destructive actions still require approval"},
      {"label": "Supervised", "description": "Ask for approval before each bash command, file edit, or write"}
    ],
    "multiSelect": false
  }
]
```

If **Autonomous**: proceed through all steps without per-action approval prompts. Destructive actions (file deletion, git reset, dropping data) still require explicit user approval.
If **Supervised**: request approval before each bash command, file edit, or write.

---

## Pre-flight: Git Safety Check

Check BOTH repositories for uncommitted changes:

```bash
# App repo
cd "[appPath]" && git status --short

# Website repo
cd "[websitePath]" && git status --short
```

If either repo has uncommitted changes:

```
AskUserQuestion with questions:
[
  {
    "question": "[Repo name] has uncommitted changes. Commit before proceeding?",
    "header": "Git",
    "options": [
      {"label": "Commit first (Recommended)", "description": "Save current work so you can revert if this skill modifies files"},
      {"label": "Continue without committing", "description": "Proceed — I accept the risk"}
    ],
    "multiSelect": false
  }
]
```

If "Commit first": Ask for a commit message, stage changed files, and commit. Then proceed.

---

## Quick Mode (Repeat Runs)

When config exists at `.claude/website-sync-config.json`, show main menu:

```
AskUserQuestion with questions:
[
  {
    "question": "Website sync ready. What would you like to do?",
    "header": "Action",
    "options": [
      {"label": "Sync all (Recommended)", "description": "Update all markers with current settings"},
      {"label": "Sync with options", "description": "Choose scope, preview, or dry-run"},
      {"label": "Check status", "description": "See current state without making changes"},
      {"label": "Analyze content", "description": "Audit markers, check completeness, find gaps"}
    ],
    "multiSelect": false
  }
]
```

### If "Sync all":

Skip to Step 8 (Execute Sync) with scope = all markers.

### If "Sync with options":

```
AskUserQuestion with questions:
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
AskUserQuestion with questions:
[
  {
    "question": "What analysis would you like to run?",
    "header": "Analyze",
    "options": [
      {"label": "Marker audit", "description": "Check marker coverage across all pages"},
      {"label": "Completeness check", "description": "Compare JSON content ↔ website markers"},
      {"label": "Content gap analysis", "description": "Find undocumented features"},
      {"label": "Run all", "description": "Full analysis report"}
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

Config: [appPath]/.claude/website-sync-config.json

Paths:
  App:     [appPath]
  Website: [websitePath]

Last sync: [date]
Last commit synced: [hash] "[message]"

Changes since last sync:
  - N new commits in app repo
  - N files with content changes

Markers found:
  features.html:  19 markers (FEATURE:*)
  support.html:   18 markers (FAQ:*)
  Stuffolio_Users_Manual.html: 5 markers (Sources/*)
  whats-new.html: 3 markers (CURRENT_VERSION, LASTCOMMIT, TESTFLIGHT_CHANGES)
  index.html:     1 marker (VERSION)
  10 other pages:  0 markers

Content Files:
  features.json: [status] (generated [date])
  faq.json:      [status] (generated [date])
  changelog.json: [status] (generated [date])

TestFlight tag: testflight-build-[N]
Next tag will be: testflight-build-[N+1]
```

---

## Drift Detection

Detects when JSON content files are out of sync with their sources.

### How It Works

1. **Track generation metadata** in each JSON file (generatedDate, sourceSnapshot)
2. **On status check or sync**, compare current feature folders and file dates against the snapshot
3. **Report drift**: new folders, removed folders, modified files

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
AskUserQuestion with questions:
[
  {
    "question": "[file].json is stale. N source files changed. What do you want to do?",
    "header": "Drift",
    "options": [
      {"label": "Regenerate now", "description": "Re-analyze sources and update the JSON file"},
      {"label": "Continue anyway", "description": "Use existing JSON (may miss new content)"},
      {"label": "View changes", "description": "Show what's different before deciding"}
    ],
    "multiSelect": false
  }
]
```

### Drift Detection Config

In `website-sync-config.json`:

```json
{
  "driftDetection": {
    "enabled": true,
    "checkOnSync": true,
    "checkOnStatus": true,
    "autoRegenerate": false,
    "watchPaths": ["Sources/Features/", "Sources/Views/Tools/", "Sources/Managers/"],
    "ignorePaths": ["**/*Tests*", "**/*.generated.swift"]
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

Summary:
  Files to modify: N
  Markers to update: N
  New content to add: N

No files were modified. Run without --dry-run to apply changes.
```

```
AskUserQuestion with questions:
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
      "timestamp": "2026-03-04T05:00:00Z",
      "commit": "bf1e466",
      "markersUpdated": 4,
      "filesModified": ["index.html", "whats-new.html"],
      "backupPath": "[websitePath].backup.20260304-050000"
    }
  ],
  "maxHistory": 50
}
```

---

## Error Handling

| Error | Cause | Recovery |
|-------|-------|----------|
| `Marker not closed` | Missing `<!-- /SYNC:X -->` | Show location, offer to fix |
| `JSON key not found` | No matching entry in content JSON | Suggest adding entry or check marker name |
| `Config invalid` | Malformed JSON | Show error, offer to reset config |
| `Backup failed` | Disk space or permissions | Warn user, ask to continue without backup |

### On Error

1. **Stop immediately** — Don't apply partial changes
2. **Show clear error message** with file and line number
3. **Offer recovery options**:

```
AskUserQuestion with questions:
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

Configure in `website-sync-config.json`:

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
1. List all backups: `ls -t "[websitePath]".backup.*`
2. Keep the most recent `keepCount` backups
3. Delete backups older than `keepDays`

---

# PHASE A: SETUP

## Step 1: Load or Create Configuration

Check if config exists at `.claude/website-sync-config.json` in the app working directory.

**If config exists:** Read it and show Quick Mode menu (see above).

**If no config:**

```
AskUserQuestion with questions:
[
  {
    "question": "No website sync config found. How would you like to set up?",
    "header": "Setup",
    "options": [
      {"label": "Quick setup (Recommended)", "description": "Auto-detect settings, minimal questions"},
      {"label": "Guided wizard", "description": "Step-by-step configuration with all options"}
    ],
    "multiSelect": false
  }
]
```

### If "Quick setup":

1. Auto-detect app path (current working directory)
2. Auto-detect website path (look for sibling `-site` folder, e.g., `stuffolio-site`)
3. Default to: all metadata + features + FAQ, TestFlight change source, smart strategy, deployment = none
4. Show summary and save config
5. Proceed to Quick Mode

### If "Guided wizard":

Continue to Step 2.

---

## Step 2: Gather Paths

```
AskUserQuestion with questions:
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

Then:

```
AskUserQuestion with questions:
[
  {
    "question": "What is the path to your website directory?",
    "header": "Website",
    "options": [
      {"label": "Sibling directory", "description": "Website is next to the app folder (e.g., stuffolio-site)"},
      {"label": "Enter path", "description": "I'll provide a custom path"}
    ],
    "multiSelect": false
  }
]
```

Store the resolved paths. Website format is always `static-html`.

---

# PHASE B: CONFIGURE

## Step 3: Select Content to Sync

```
AskUserQuestion with questions:
[
  {
    "question": "What content should be synced to the website?",
    "header": "Content",
    "options": [
      {"label": "Version & build info", "description": "VERSION, CURRENT_VERSION markers"},
      {"label": "Feature descriptions", "description": "FEATURE:* markers from features.json"},
      {"label": "FAQ entries", "description": "FAQ:* markers from faq.json"},
      {"label": "Changelog & activity", "description": "LASTCOMMIT, TESTFLIGHT_CHANGES, CHANGELOG markers"}
    ],
    "multiSelect": true
  }
]
```

Then ask about documentation:

```
AskUserQuestion with questions:
[
  {
    "question": "Any documentation to sync?",
    "header": "Docs",
    "options": [
      {"label": "User manual sections", "description": "MANUAL:* and Sources/* markers"},
      {"label": "Help text", "description": "HELP:* markers from in-app help"},
      {"label": "None", "description": "No additional docs"}
    ],
    "multiSelect": true
  }
]
```

---

## Step 4: Select Change Source

```
AskUserQuestion with questions:
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
   git tag -l "testflight-build-*" --sort=-version:refname | head -5
   ```

2. **If tags found**, show to user and use latest tag as baseline.

3. **Get all commits since last TestFlight**:
   ```bash
   git log testflight-build-[N]..HEAD --oneline
   ```

### If "Last commit only":

```bash
git log -1 --oneline
```

### If "Specific commit range":

Ask user for number of commits, date, or hash range.

---

## Step 5: Configure Update Strategy

```
AskUserQuestion with questions:
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

## Step 6: Save Configuration

Write config to `.claude/website-sync-config.json`:

```json
{
  "appPath": "[resolved app path]",
  "websitePath": "[resolved website path]",
  "detectedFormat": "static-html",
  "hasTemplates": false,
  "syncContent": ["version", "current_version", "lastcommit", "features", "faq"],
  "changeSource": "testflight",
  "updateStrategy": "smart",
  "deployment": "none",
  "testflightTagging": {
    "enabled": true,
    "prefix": "testflight-build-",
    "lastTag": "testflight-build-[N]"
  },
  "driftDetection": {
    "enabled": true,
    "checkOnSync": true,
    "checkOnStatus": true,
    "autoRegenerate": false,
    "watchPaths": ["Sources/Features/", "Sources/Views/Tools/", "Sources/Managers/"],
    "ignorePaths": ["**/*Tests*", "**/*.generated.swift"]
  },
  "contentFiles": {
    "features": {
      "path": ".claude/website-content/features.json",
      "lastGenerated": null,
      "status": "current"
    },
    "faq": {
      "path": ".claude/website-content/faq.json",
      "lastGenerated": null,
      "status": "current"
    },
    "changelog": {
      "path": ".claude/website-content/changelog.json",
      "lastGenerated": null,
      "status": "current",
      "sourceFile": "whats-new.html"
    }
  },
  "lastRun": null,
  "lastSyncedCommit": null
}
```

---

# PHASE C: EXECUTE

## Step 7: Select Update Scope

```
AskUserQuestion with questions:
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

1. List all pages with markers (scan website HTML files for `<!-- SYNC:` patterns)
2. Use AskUserQuestion with multiSelect to let user pick pages
3. Only markers on selected pages will be updated

### If "Select markers":

1. List all markers found across the site, grouped by type
2. Use AskUserQuestion with multiSelect to let user pick specific markers

---

## Step 8: Execute Sync

### 8.1 Create Backup

Create timestamped backup of website directory:
```bash
cp -r "[websitePath]" "[websitePath].backup.[timestamp]"
```

### 8.2 Gather Source Data

**Based on Change Source (from Step 4 or config):**

- **Since TestFlight**: Use commits from `git log [last-tag]..HEAD`
- **Last commit only**: Use `git log -1`
- **Specific range**: Use the user-specified range

**For Smart strategy:**
Run `git diff --name-only [change-source-ref]` in app directory to find changed files. Map changed files to sync markers.

**For Full scan:**
Find all sync markers in website files.

### 8.3 Find SYNC Markers in HTML

Search website files for marker pairs:
```html
<!-- SYNC:TYPE:Name -->
...content...
<!-- /SYNC:TYPE:Name -->
```

#### Current Marker Types in Use

| Marker Pattern | Pages | Count |
|---------------|-------|-------|
| `FEATURE:*` | features.html | 19 |
| `FAQ:*` | support.html | 18 |
| `Sources/*` | Stuffolio_Users_Manual.html | 5 |
| `CURRENT_VERSION` | whats-new.html | 1 |
| `LASTCOMMIT` | whats-new.html | 1 |
| `TESTFLIGHT_CHANGES` | whats-new.html | 1 |
| `VERSION` | index.html | 1 |

### 8.4 Extract Content from JSON Files

Content is sourced from `.claude/website-content/` JSON files:

| Marker | Source File | Lookup Key |
|--------|-----------|------------|
| `FEATURE:Name` | `features.json` | `"id": "name"` (kebab-case) |
| `FAQ:Name` | `faq.json` | `"marker": "Name"` |
| `CHANGELOG` | `changelog.json` | All non-archived releases |
| `TESTFLIGHT_CHANGES` | `changelog.json` | Current release's `changes` object |
| `CURRENT_VERSION` | `changelog.json` | `currentBuild` + `currentStatus` |
| `VERSION` | Info.plist / CLAUDE.md | App version string |
| `LASTCOMMIT` | Git | `git log -1 --stat` |
| `HELP:Name` | Help strings in code | Localizable.strings with `WEBSITE_HELP_` prefix |
| `MANUAL:Name` | In-app onboarding text | Documentation files |
| `Sources/Path/` | Swift source files | Direct code extraction |

#### Feature Matching

When syncing `<!-- SYNC:FEATURE:stuff-scout -->`:

1. Look up `features.json` for entry with `"id": "stuff-scout"`
2. Generate HTML from `name`, `tagline`, `description`, `bullets`
3. If not found in JSON, log a warning

#### FAQ Matching

When syncing `<!-- SYNC:FAQ:iCloudSync -->`:

1. Look up `faq.json` for all entries with `"marker": "iCloudSync"`
2. Multiple FAQs can share one marker (grouped content)
3. Generate `<details>` blocks from `question` and `answer`

#### Changelog Matching

When syncing changelog markers:

1. `<!-- SYNC:CURRENT_VERSION -->` → Uses `currentBuild` and `currentStatus`
2. `<!-- SYNC:TESTFLIGHT_CHANGES -->` → Uses the current release's `changes` object
3. `<!-- SYNC:CHANGELOG -->` → Uses all non-archived releases

### 8.5 Generate Updates

For each marker with changes:
- Show diff preview to user
- If "Manual review" strategy, use AskUserQuestion for each change

### 8.6 Apply Updates

Use Edit tool to update content between sync markers.
Preserve all content outside markers.

---

## Step 9: Validation

Run validation checks:

1. **Marker integrity**: All opened markers have closing tags
2. **HTML validation**: Check for unclosed tags in updated sections
3. **Link validation**: Check internal links resolve
4. **Image validation**: Verify referenced images exist

Report any issues found.

---

## Step 10: Summary

Output summary:

```
Website Sync Complete
═══════════════════════════════════════════════════════

Updated:
- [N] markers updated
- [N] files modified

Deployment: Manual (use git commit/push in website repo)

Backup location: [path]
To rollback: cp -r "[backup]" "[websitePath]"
```

Update `lastRun` and `lastSyncedCommit` in config file.
Add entry to sync history.

### Optional: TestFlight Tagging

After successful sync, offer to tag the current app commit:

```
AskUserQuestion with questions:
[
  {
    "question": "Create a TestFlight tag for this sync point?",
    "header": "Tag",
    "options": [
      {"label": "Yes, auto-name", "description": "Create tag: testflight-build-[N+1]"},
      {"label": "No", "description": "Skip tagging"}
    ],
    "multiSelect": false
  }
]
```

If "Yes": Find highest existing tag number, increment, and create:
```bash
git tag testflight-build-[N+1]
```

Note: Do NOT push the tag without explicit user approval.

### Optional: Screenshots

To capture screenshots for the website, use Claude-in-Chrome browser automation:

1. Open the app in the simulator or use existing screenshots
2. Use `mcp__claude-in-chrome__computer` to capture screenshots from the browser
3. Save to the website's screenshot directory

Screenshots are manual — this skill does not auto-capture from the simulator.

---

# PHASE D: ANALYZE

## Step 11: Completeness Check

Compare JSON content to website markers to ensure nothing is missing.

### 11.1 Scan JSON Content Files

Read each JSON content file and extract available entries:
- `features.json` → list all feature `id` values
- `faq.json` → list all `marker` values
- `changelog.json` → list all release entries

### 11.2 Scan Website for All Sync Markers

Search all HTML files for `<!-- SYNC:` markers:

```bash
grep -r "<!-- SYNC:" --include="*.html" "[websitePath]/"
```

Group by page and type.

### 11.3 Compare and Report

```
Completeness Report
═══════════════════════════════════════════════════════

FEATURE markers:
  ✓ In JSON AND on website: N
  ✗ In JSON but MISSING from website: N
    - [list]
  ? On website but NOT in JSON: N
    - [list]

FAQ markers:
  ✓ In JSON AND on website: N
  ✗ In JSON but MISSING from website: N

Overall completeness: N/N (X%)
```

### 11.4 Offer to Fix Gaps

```
AskUserQuestion with questions:
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

## Step 12: Content Gap Analysis

Intelligent analysis that finds missing content even WITHOUT markers.

Use Issue Rating tables (per CLAUDE.md) for all findings.

### 12.1 Scan App Structure

Analyze the codebase to find all documentable content:
- Feature folders in `Sources/Features/`
- View files and their capabilities
- Manager files and services
- User-facing strings and error messages

### 12.2 Scan Website Content

Analyze website pages for actual content (not just markers):
- Sections found per page
- Features mentioned
- FAQ entries
- Version information

### 12.3 Cross-Reference and Find Gaps

Compare app capabilities to website documentation:

```
Content Gap Analysis
═══════════════════════════════════════════════════════

FEATURES PAGE
───────────────────────────────────────────────────────

App features NOT documented on website:
  ✗ [FeatureName]
    Source: Sources/Features/[Name]/
    Suggested section: Add to features.html
```

Present findings with Issue Rating table:

| # | Finding | Urgency | Risk: Fix | Risk: No Fix | ROI | Blast Radius | Fix Effort |
|---|---|---|---|---|---|---|---|
| 1 | [Gap description] | 🟢 Medium | ⚪ Low | 🟢 Medium | 🟢 Good | ⚪ Low | Small |

### 12.4 Generate Content Suggestions

For each gap, generate suggested content from code analysis and offer to add.

```
AskUserQuestion with questions:
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

---

## Step 13: Marker Audit

Scan the website to assess marker coverage and suggest improvements.

### 13.1 Scan Website Pages

Find all HTML files in the website directory. For each page, count total sync markers and their types.

### 13.2 Detect Unmarked Content

Scan each page for content that COULD be synced but has no marker:

| Pattern to Find | Suggests Adding |
|-----------------|-----------------|
| Version numbers (e.g., "1.0", "v2.1.0") | `SYNC:VERSION` |
| "What's New" or "Changelog" sections | `SYNC:CHANGELOG` or `SYNC:TESTFLIGHT_CHANGES` |
| Feature headings with bullet lists | `SYNC:FEATURE:SectionName` |
| "Latest update" or recent activity text | `SYNC:LASTCOMMIT` |
| FAQ / Q&A sections | `SYNC:FAQ:TopicName` |

### 13.3 Report Coverage

```
Marker Audit Results
═══════════════════════════════════════════════════════

Pages scanned: [N]

✓ Pages with markers:
  - features.html (19 markers: FEATURE:*)
  - support.html (18 markers: FAQ:*)
  - Stuffolio_Users_Manual.html (5 markers: Sources/*)
  - whats-new.html (3 markers: CURRENT_VERSION, LASTCOMMIT, TESTFLIGHT_CHANGES)
  - index.html (1 marker: VERSION)

✗ Pages without markers:
  - compare.html
  - family-sharing.html
  - story.html
  - beta-testing-guide.html
  - quick-start.html
  - quick-reference.html
  - testflight-invite.html
  - privacy.html
  - terms.html
  - app-map.html

Suggestions:
  - [page] line [N]: Found [pattern] — add SYNC:[TYPE] marker?

Coverage: [X]% of pages have at least one sync marker
```

### 13.4 Offer to Add Markers

```
AskUserQuestion with questions:
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

---

## Rollback

Restore website to a previous state.

### List Available Backups

```bash
ls -lt "[websitePath]".backup.* | head -10
```

### Select and Restore

```
AskUserQuestion with questions:
[
  {
    "question": "Which backup to restore?",
    "header": "Restore",
    "options": [
      {"label": "Most recent", "description": "[date and details]"},
      {"label": "Choose from list", "description": "Select a specific backup"},
      {"label": "Cancel", "description": "Don't restore"}
    ],
    "multiSelect": false
  }
]
```

### Execute Restore

1. **Create safety backup** of current state:
   ```bash
   cp -r "[websitePath]" "[websitePath].pre-rollback.[timestamp]"
   ```

2. **Restore selected backup**:
   ```bash
   cp -r "[backupPath]/"* "[websitePath]/"
   ```

3. **Update config** to reflect rollback (set `lastSyncedCommit` to backup's commit)

4. **Report** completion with paths and instructions.

---

# REFERENCE

## Sync Marker Format

All markers use HTML comment syntax:

```html
<!-- SYNC:TYPE:Name -->
...synced content...
<!-- /SYNC:TYPE:Name -->
```

### Marker Types

#### Metadata Markers

| Marker | Source | Example |
|--------|--------|---------|
| `VERSION` | Info.plist / CLAUDE.md | `"softwareVersion": "1.0"` |
| `CURRENT_VERSION` | changelog.json | `Build 25` |
| `LASTCOMMIT` | `git log -1 --stat` | Commit hash + message |
| `TESTFLIGHT_CHANGES` | changelog.json | Release notes list |
| `CHANGELOG` | changelog.json | All releases |

#### Content Markers

| Marker | Source | HTML Output |
|--------|--------|-------------|
| `FEATURE:Name` | features.json (by `id`) | `<h3>`, `<p>`, `<ul>` |
| `FAQ:Name` | faq.json (by `marker`) | `<details>` / `<summary>` |
| `HELP:Name` | Help strings in code | `<div class="help-section">` |
| `MANUAL:Name` | In-app documentation | `<section>` |
| `Sources/Path/` | Swift source files | Extracted documentation |

## JSON Content Files

Stored in `.claude/website-content/`:

| File | Regenerate Command | Used By |
|------|-------------------|---------|
| `features.json` | `--regenerate-features` | `FEATURE:*` markers |
| `faq.json` | `--regenerate-faq` | `FAQ:*` markers |
| `changelog.json` | `--regenerate-changelog` | `CHANGELOG`, `TESTFLIGHT_CHANGES`, `CURRENT_VERSION` |

### features.json Structure

```json
{
  "generatedFrom": "codebase-analysis",
  "generatedDate": "2026-02-18",
  "appVersion": "1.0",
  "categories": { "ai": { "name": "AI Features", "order": 1 } },
  "features": [
    {
      "id": "stuff-scout",
      "name": "Stuff Scout",
      "tagline": "AI-powered identification",
      "description": "Camera-first AI identification...",
      "bullets": ["Photo-based identification", "..."],
      "category": "ai",
      "isPremium": true,
      "sourceFiles": ["Sources/Features/StuffScout/"]
    }
  ]
}
```

### faq.json Structure

```json
{
  "generatedFrom": "website-analysis",
  "generatedDate": "2026-02-18T15:30:00Z",
  "categories": { "data-sync": { "name": "Data & Sync", "order": 3 } },
  "faqs": [
    {
      "id": "sync-across-devices",
      "question": "Does Stuffolio sync across devices?",
      "answer": "Yes, via iCloud sync...",
      "category": "data-sync",
      "marker": "iCloudSync",
      "relatedFeatures": ["icloud-sync"]
    }
  ]
}
```

### changelog.json Structure

```json
{
  "generatedFrom": "website-extraction",
  "generatedDate": "2026-03-02T17:00:00Z",
  "currentBuild": 25,
  "currentStatus": "beta",
  "releases": [
    {
      "version": "1.0",
      "build": 25,
      "date": "2026-02-10",
      "tag": "testflight-build-25",
      "isCurrent": true,
      "summary": "Critical fixes...",
      "changes": {
        "new": ["Feature 1"],
        "improved": ["Improvement 1"],
        "fixed": ["Bug fix 1"]
      }
    }
  ]
}
```

### Generating Content Files

| Command | What It Does |
|---------|--------------|
| `--regenerate-features` | Analyze `Sources/Features/` folders, view files, and managers to create features.json |
| `--regenerate-faq` | Analyze existing FAQ markers in support.html and code comments to create faq.json |
| `--regenerate-changelog` | Extract release entries from whats-new.html to create changelog.json |

The skill suggests regenerating when source files change (drift detection).
