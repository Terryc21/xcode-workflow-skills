---
name: release-prep
description: 'Pre-release checklist with automated version bumps, changelog generation, privacy manifest validation, and store metadata review. Triggers: "release prep", "prepare release", "ready to ship", "pre-release checklist".'
version: 1.1.0
author: Terry Nyberg
license: MIT
allowed-tools: [Read, Grep, Glob, Bash, Edit, AskUserQuestion]
metadata:
  tier: execution
  category: release
---

# Release Prep

> **Quick Ref:** Automated pre-release checklist: version bump, changelog, privacy check, store metadata, archive. Output: `.agents/research/YYYY-MM-DD-release-prep-vX.Y.Z.md`

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

Pre-release checklist with automated version bumps, changelog generation, privacy manifest validation, and store metadata review.

## Quick Commands

| Command | Description |
|---------|-------------|
| `/release-prep` | Interactive — prompts for version and release type |
| `/release-prep 2.1.0` | Direct — starts with specific version |
| `/release-prep --patch` | Auto-increment patch version |
| `/release-prep --minor` | Auto-increment minor version |
| `/release-prep --changelog-only` | Generate changelog without other steps |

---

## Step 1: Determine Release Details

Use AskUserQuestion to gather release information:

```
questions:
[
  {
    "question": "What type of release is this?",
    "header": "Release type",
    "options": [
      {"label": "Patch (X.Y.Z+1)", "description": "Bug fixes only, no new features"},
      {"label": "Minor (X.Y+1.0)", "description": "New features, backwards compatible"},
      {"label": "Major (X+1.0.0)", "description": "Breaking changes or major milestone"},
      {"label": "Hotfix", "description": "Urgent production fix"}
    ],
    "multiSelect": false
  }
]
```

---

## Step 2: Find Current Version

### 2.1: Locate Version in Project

```
# Find MARKETING_VERSION in pbxproj
Grep pattern="MARKETING_VERSION" glob="*.pbxproj" output_mode="content"

# Find CURRENT_PROJECT_VERSION (build number)
Grep pattern="CURRENT_PROJECT_VERSION" glob="*.pbxproj" output_mode="content"

# Check for version in Info.plist (older projects)
Grep pattern="CFBundleShortVersionString|CFBundleVersion" glob="*.plist" output_mode="content"
```

### 2.2: Check Last Git Tag

```bash
# Get the most recent version tag
git tag --sort=-v:refname | head -5

# Get the most recent tag with its date
git log --tags --simplify-by-decoration --format="%ai %d" | head -5
```

### 2.3: Calculate New Version

Based on release type and current version, determine new version:

| Current | Patch | Minor | Major |
|---------|-------|-------|-------|
| 1.2.3 | 1.2.4 | 1.3.0 | 2.0.0 |

Record:
- **Current version:** X.Y.Z
- **New version:** X.Y.Z
- **Current build:** N
- **New build:** N+1

---

## Step 3: Bump Version Numbers

### 3.1: Update MARKETING_VERSION

Use Edit to update the version in the project file:

```
# Find the exact line in pbxproj
Grep pattern="MARKETING_VERSION = " glob="*.pbxproj" output_mode="content"

# Edit each occurrence (there may be multiple — one per build configuration)
Edit file_path="path/to/project.pbxproj"
  old_string='MARKETING_VERSION = "1.2.3"'
  new_string='MARKETING_VERSION = "1.3.0"'
  replace_all=true
```

### 3.2: Update CURRENT_PROJECT_VERSION

```
Edit file_path="path/to/project.pbxproj"
  old_string='CURRENT_PROJECT_VERSION = 45'
  new_string='CURRENT_PROJECT_VERSION = 46'
  replace_all=true
```

### 3.3: Verify

```
# Confirm versions updated correctly
Grep pattern="MARKETING_VERSION|CURRENT_PROJECT_VERSION" glob="*.pbxproj" output_mode="content"
```

---

## Step 4: Generate Changelog

### 4.1: Get Commits Since Last Release

```bash
# Commits since last tag, one per line
git log v1.2.3..HEAD --oneline --no-merges

# Commits with full messages (for more context)
git log v1.2.3..HEAD --format="%h %s" --no-merges

# If no tags exist, use a date range
git log --since="2026-01-01" --oneline --no-merges
```

### 4.2: Categorize Changes

Sort commits into categories by reading each commit message:

```markdown
## What's New in [version]

### Features
- [New capabilities added]

### Improvements
- [Enhancements to existing features]

### Bug Fixes
- [Issues resolved]

### Under the Hood
- [Technical changes users don't directly see]
```

### 4.3: Write App Store "What's New" Text

Draft concise, user-facing release notes (max 4000 characters for App Store):

```
Keep it brief and user-focused:
- Lead with the most impactful change
- Use plain language (no technical jargon)
- 3-8 bullet points is ideal
- Include a thank-you or feedback prompt at the end
```

---

## Step 5: Code Readiness Check

### 5.1: Test Status

```bash
# Run tests (or check if they pass)
xcodebuild test -scheme AppName -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5
```

### 5.2: Check for Debug Code Left Behind

```
# Find debug prints
Grep pattern="print\\(|NSLog\\(|debugPrint\\(" glob="*.swift" -i output_mode="count"

# Find TODO/FIXME that might be blockers
Grep pattern="TODO|FIXME|HACK|XXX" glob="*.swift" output_mode="content"

# Find #if DEBUG blocks that might hide issues
Grep pattern="#if DEBUG" glob="*.swift" output_mode="content"

# Find hardcoded test data
Grep pattern="localhost|127\\.0\\.0\\.1|test@|example\\.com" glob="*.swift" output_mode="content"
```

### 5.3: Check for Warnings

```bash
# Build and count warnings
xcodebuild build -scheme AppName -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep "warning:" | wc -l
```

---

## Step 6: Privacy & Compliance

### 6.1: Privacy Manifest

```
# Check if PrivacyInfo.xcprivacy exists
Glob pattern="**/PrivacyInfo.xcprivacy"

# If found, read its contents
Read file_path="path/to/PrivacyInfo.xcprivacy"

# Check for required API declarations (iOS 17+)
# These APIs require reason declarations:
Grep pattern="NSPrivacyAccessedAPIType" glob="*.xcprivacy" output_mode="content"
```

### 6.2: Required API Reasons

Check if the app uses APIs that require privacy reason declarations:

```
# File timestamp APIs
Grep pattern="creationDate|modificationDate|fileModificationDate" glob="*.swift"

# Disk space APIs
Grep pattern="volumeAvailableCapacity|systemFreeSize" glob="*.swift"

# User defaults APIs
Grep pattern="UserDefaults|NSUserDefaults" glob="*.swift"

# System boot time APIs
Grep pattern="systemUptime|bootTime|processInfo" glob="*.swift"
```

If any are found but not declared in the privacy manifest, flag it.

### 6.3: Third-Party SDK Privacy Manifests

```
# Check that third-party packages include privacy manifests
Glob pattern="**/PrivacyInfo.xcprivacy" path="SourcePackages"
Glob pattern="**/PrivacyInfo.xcprivacy" path="Pods"
```

---

## Step 7: App Store Metadata

### 7.1: Screenshots

```
# Check if screenshot assets exist and when they were last updated
Glob pattern="**/Screenshots/**/*.png"
Glob pattern="**/Screenshots/**/*.jpg"
```

Ask user: Are screenshots up to date? If not, suggest `/release-screenshots`.

### 7.2: URLs

```
# Check for support URL in Info.plist or project settings
Grep pattern="support.*url|privacy.*url|marketing.*url" glob="*.plist" -i output_mode="content"
```

Remind user to verify:
- [ ] Support URL is valid and loads
- [ ] Privacy Policy URL is valid and loads
- [ ] Marketing URL is valid (if applicable)

---

## Step 8: Archive Readiness

### 8.1: Signing Check

```
# Check code signing settings
Grep pattern="CODE_SIGN_IDENTITY|DEVELOPMENT_TEAM|PROVISIONING_PROFILE" glob="*.pbxproj" output_mode="content"
```

### 8.2: Build Configuration

Verify release build configuration:

```
# Check that Release configuration exists
Grep pattern="Release" glob="*.pbxproj" output_mode="count"

# Check optimization settings
Grep pattern="SWIFT_OPTIMIZATION_LEVEL|GCC_OPTIMIZATION_LEVEL" glob="*.pbxproj" output_mode="content"
```

---

## Step 9: Generate Release Prep Report

Create report at `.agents/research/YYYY-MM-DD-release-prep-vX.Y.Z.md`:

```markdown
# Release Prep Report — vX.Y.Z

**Date:** YYYY-MM-DD
**Version:** X.Y.Z (Build NN)
**Release Type:** Patch / Minor / Major
**Status:** Ready / Blocked

## Version Bump

- [x] MARKETING_VERSION: X.Y.Z-1 → X.Y.Z
- [x] CURRENT_PROJECT_VERSION: N-1 → N

## Changelog

### What's New in X.Y.Z

**Features:**
- [list]

**Improvements:**
- [list]

**Bug Fixes:**
- [list]

### App Store "What's New" (copy-paste ready)
```
[User-facing release notes text]
```

## Code Readiness

| Check | Status | Notes |
|-------|--------|-------|
| Tests passing | ✓ / ✗ | X tests, Y passed |
| Debug code removed | ✓ / ✗ | N print statements found |
| No blocking TODOs | ✓ / ✗ | List if any |
| Build warnings | ✓ / ✗ | N warnings |

## Privacy & Compliance

| Check | Status | Notes |
|-------|--------|-------|
| Privacy manifest exists | ✓ / ✗ | |
| API reasons declared | ✓ / ✗ | |
| Third-party manifests | ✓ / ✗ | |

## App Store Metadata

| Check | Status | Notes |
|-------|--------|-------|
| Screenshots current | ✓ / ✗ | Last updated: date |
| What's New text | ✓ | See above |
| Support URL valid | ✓ / ✗ | |
| Privacy URL valid | ✓ / ✗ | |

## Release Commands

When ready:
```bash
# Archive (or use Xcode: Product → Archive)
xcodebuild archive -scheme AppName -archivePath build/AppName.xcarchive

# Tag the release
git tag -a vX.Y.Z -m "Release X.Y.Z"
git push origin vX.Y.Z
```

## Post-Release Monitoring

- [ ] Verify app is live on App Store
- [ ] Monitor crash reports for 48 hours
- [ ] Check App Store reviews
- [ ] Update website if needed (`/update-website`)
```

---

## Step 10: Present Summary

Show the user a concise summary:

```
## Release Prep Complete — vX.Y.Z

**Status:** Ready to ship / Blocked (N issues)

| Area | Status |
|------|--------|
| Version bumped | ✓ |
| Changelog generated | ✓ |
| Tests passing | ✓ / ✗ |
| Privacy manifest | ✓ / ✗ |
| Store metadata | ✓ / ✗ |

**Full report:** .agents/research/2026-02-24-release-prep-v1.3.0.md

**Blocking issues (if any):**
1. [issue description]

**Next steps:**
1. Review the changelog in the report
2. Archive and upload via Xcode
3. Submit for App Store review
4. Run `/release-screenshots` if screenshots need updating
```

---

## For iOS-Specific Release Workflows

This skill focuses on the checklist and automation. For deep iOS-specific concerns:

- **Security pre-check:** Run `/security-audit` before releasing
- **Accessibility check:** Run Axiom agent `/axiom:audit accessibility`
- **App Store code review:** Invoke `/app-store-code-review`

---

## See Also

- `/release-screenshots` — Capture App Store screenshots
- `/update-website` — Sync website with app changes
- `/security-audit` — Pre-release security verification
- `/review-changes` — Review final changes before tagging
