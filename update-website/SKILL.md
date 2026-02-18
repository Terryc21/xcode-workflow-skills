---
name: update-website
description: Sync website content with app codebase - features, changelog, screenshots, docs
version: 1.0.0
author: Terry Nyberg
license: MIT
---

# Website Sync Skill

Sync website content with your app's codebase. Supports static HTML, Jekyll, Hugo, and JS frameworks.

## Step 1: Load or Create Configuration

Check if config exists at `.claude/website-sync-config.json` in the current working directory.

**If config exists:** Read it and skip to Step 4 (Quick Mode).

**If no config:** Continue to Step 2 (First-Run Wizard).

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

## Step 4: Select Content to Sync

Use AskUserQuestion:

```
questions:
[
  {
    "question": "What content should be synced?",
    "header": "Content",
    "options": [
      {"label": "Features", "description": "Feature lists extracted from code"},
      {"label": "Version & metadata", "description": "Version numbers, build info"},
      {"label": "Screenshots", "description": "Capture new app screenshots"},
      {"label": "Changelog", "description": "Update changelog from commits"}
    ],
    "multiSelect": true
  }
]
```

Then ask about additional content:

```
questions:
[
  {
    "question": "Any additional documentation to sync?",
    "header": "Docs",
    "options": [
      {"label": "Privacy policy", "description": "Privacy documentation"},
      {"label": "Support docs", "description": "Help and support pages"},
      {"label": "User manual", "description": "User guide sections"},
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
  "syncContent": ["features", "version", "changelog"],
  "additionalDocs": ["privacy", "support", "manual"],
  "changeSource": "testflight",
  "updateStrategy": "smart",
  "screenshotConfig": {
    "method": "simulator",
    "simulator": "iPhone 16 Pro",
    "screens": ["home", "detail", "settings"]
  },
  "deployment": "git",
  "testflightTagging": {
    "enabled": true,
    "prefix": "testflight-build-",
    "lastTag": "testflight-build-25"
  },
  "lastRun": null,
  "lastSyncedCommit": null
}
```

---

## Step 10: Execute Sync

### 10.1 Create Backup

Create timestamped backup of website directory:
```
cp -r [websitePath] [websitePath].backup.[timestamp]
```

### 10.2 Gather Source Data

**Based on Change Source (from Step 5):**

- **Since TestFlight**: Use commits from `git log [last-tag]..HEAD`
- **Last commit only**: Use `git log -1`
- **Specific range**: Use the user-specified range

**For Smart strategy:**
Run `git diff --name-only [change-source-ref]` in app directory to find changed files.
Map changed files to sync markers.

**For Full scan:**
Find all sync markers in website files.

### 10.3 Find Sync Markers

Search website files for markers:
```
<!-- SYNC:FileName.swift -->
...content...
<!-- /SYNC:FileName.swift -->
```

Also look for:
- `<!-- SYNC:VERSION -->` - App version from Info.plist or Package.swift
- `<!-- SYNC:CHANGELOG -->` - Git log formatted as changelog
- `<!-- SYNC:FEATURES:SectionName -->` - Feature lists from code comments
- `<!-- SYNC:LASTCOMMIT -->` - Output of `git log -1 --stat`
- `<!-- SYNC:TESTFLIGHT_CHANGES -->` - All commits since last TestFlight build

### 10.4 Extract Content from Codebase

For each marker found:

1. **Code files**: Extract relevant sections (marked with `// WEBSITE:` comments)
2. **VERSION**: Read from Info.plist, Package.swift, or version file
3. **CHANGELOG**: Based on change source:
   - TestFlight: `git log [last-tag]..HEAD --oneline` (all changes since last build)
   - Last commit: `git log -1 --oneline`
   - Specific range: User-specified commits
4. **LASTCOMMIT**: Run `git log -1 --stat` or `git show --stat`
5. **FEATURES**: Parse feature comments from code
6. **TESTFLIGHT_CHANGES**: Format commits since last TestFlight as release notes

### 10.5 Generate Updates

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

### 10.6 Apply Updates

Use Edit tool to update each section between sync markers.
Preserve content outside markers.

---

## Step 11: Screenshots (if configured)

If screenshot capture was selected:

1. Use `mcp__XcodeBuildMCP__build_run_sim` to launch app
2. For each screen:
   - Navigate to the screen (use `mcp__XcodeBuildMCP__tap`, `mcp__XcodeBuildMCP__type_text`)
   - Use `mcp__XcodeBuildMCP__screenshot` to capture
   - Save to configured screenshot path
3. Use `mcp__XcodeBuildMCP__stop_app_sim` when done

---

## Step 12: Validation

Run validation checks:

1. **HTML validation**: Check for unclosed tags, broken links
2. **Image validation**: Verify all referenced images exist
3. **Link validation**: Check internal links resolve
4. **Template validation**: Ensure includes/partials exist

Report any issues found.

---

## Step 13: Deployment (if configured)

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

## Step 14: TestFlight Tagging (Optional)

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

## Step 15: Summary

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

## Quick Mode (Repeat Runs)

When config exists, use AskUserQuestion:

```
questions:
[
  {
    "question": "Website sync ready. What would you like to do?",
    "header": "Action",
    "options": [
      {"label": "Run sync", "description": "Sync with current settings"},
      {"label": "Change content", "description": "Select different content to sync"},
      {"label": "Reconfigure", "description": "Run full setup wizard again"},
      {"label": "Show config", "description": "Display current configuration"}
    ],
    "multiSelect": false
  }
]
```

---

## Rollback

If user asks to rollback:

1. List available backups (sorted by date)
2. Use AskUserQuestion to select backup
3. Restore: `cp -r [backup] [websitePath]`
4. Confirm restoration

---

## Sync Marker Reference

Add these markers to website files:

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
Changes since last TestFlight build:
- Add async photo decoding
- Fix scroll performance
- Add photo operation tests
<!-- /SYNC:TESTFLIGHT_CHANGES -->

<!-- SYNC:FEATURES:Dashboard -->
- Feature 1
- Feature 2
<!-- /SYNC:FEATURES:Dashboard -->

<!-- SYNC:Sources/Views/ItemDetailView.swift -->
Code documentation here
<!-- /SYNC:Sources/Views/ItemDetailView.swift -->
```

In your code, mark extractable content:

```swift
// WEBSITE: Dashboard Features
// - Quick access to recent items
// - Smart search with filters
// - Photo gallery view
// /WEBSITE
```
