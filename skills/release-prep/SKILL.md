---
name: release-prep
description: 'Pre-release checklist: version bump, changelog, privacy manifest, store metadata, archive readiness. Triggers: "release prep", "prepare release", "ready to ship", "pre-release checklist".'
version: 2.1.0
author: Terry Nyberg
license: MIT
allowed-tools: [Read, Grep, Glob, Bash, Edit, Write, AskUserQuestion]
metadata:
  tier: execution
  category: release
---

# Release Prep

> **Quick Ref:** Automated pre-release checklist: version bump, changelog, privacy check, store metadata, archive. Output: `.agents/research/YYYY-MM-DD-release-prep-vX.Y.Z.md`

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

---

## Step 1: Determine Release Details

```
AskUserQuestion with questions:
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

```bash
# Find MARKETING_VERSION in pbxproj
Grep pattern="MARKETING_VERSION" glob="**/*.pbxproj" output_mode="content"

# Find CURRENT_PROJECT_VERSION (build number)
Grep pattern="CURRENT_PROJECT_VERSION" glob="**/*.pbxproj" output_mode="content"

# Check for version in Info.plist (older projects)
Grep pattern="CFBundleShortVersionString|CFBundleVersion" glob="**/*.plist" output_mode="content"
```

### 2.2: Check Last Git Tag

```bash
# Get the most recent version tag
git tag --sort=-v:refname | head -5

# Get the most recent tag with its date
git log --tags --simplify-by-decoration --format="%ai %d" | head -5
```

### 2.3: Calculate New Version

Based on release type and current version:

| Current | Patch | Minor | Major |
|---------|-------|-------|-------|
| 1.2.3 | 1.2.4 | 1.3.0 | 2.0.0 |

Record:
- **Current version:** X.Y.Z → **New version:** X.Y.Z
- **Current build:** N → **New build:** N+1

---

## Step 3: Bump Version Numbers

### 3.1: Update MARKETING_VERSION

```bash
# Find the exact line in pbxproj
Grep pattern="MARKETING_VERSION = " glob="**/*.pbxproj" output_mode="content"

# Edit each occurrence (there may be multiple — one per build configuration)
# Use Edit with replace_all=true
```

### 3.2: Update CURRENT_PROJECT_VERSION

```bash
# Same approach — find and replace all occurrences
Grep pattern="CURRENT_PROJECT_VERSION = " glob="**/*.pbxproj" output_mode="content"
```

### 3.3: Verify

```bash
# Confirm versions updated correctly
Grep pattern="MARKETING_VERSION|CURRENT_PROJECT_VERSION" glob="**/*.pbxproj" output_mode="content"
```

---

## Step 4: Generate Changelog

### 4.1: Get Commits Since Last Release

```bash
# Commits since last tag, one per line
git log <last_tag>..HEAD --oneline --no-merges

# If no tags exist, use a date range
git log --since="2026-01-01" --oneline --no-merges
```

### 4.2: Categorize Changes

Sort commits into categories:

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

Draft user-facing release notes (max 4000 characters):
- Lead with the most impactful change
- Use plain language (no technical jargon)
- 3-8 bullet points is ideal

---

## Step 5: Code Readiness Check

### 5.1: Test Status

Ask the user before running tests (they may take a while or require specific configuration):

```
AskUserQuestion with questions:
[
  {
    "question": "Should I run the test suite now?",
    "header": "Tests",
    "options": [
      {"label": "Yes, run tests", "description": "Run xcodebuild test (may take a few minutes)"},
      {"label": "Skip tests", "description": "I'll run tests separately or they've already passed"},
      {"label": "Check last results", "description": "Just check the most recent test outcome"}
    ],
    "multiSelect": false
  }
]
```

If running tests, determine the scheme and simulator:

```bash
# Find available schemes
xcodebuild -list -json 2>/dev/null | head -30

# Run tests — adjust scheme and destination for the project
xcodebuild test -scheme <AppName> -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -10
```

### 5.2: Check for Debug Code Left Behind

```bash
# Pass 1: Find all debug prints
Grep pattern="print\(|NSLog\(|debugPrint\(" glob="**/*.swift" output_mode="files_with_matches"
# Pass 2: For each flagged file, read it and check if prints are inside #if DEBUG
# Prints inside #if DEBUG blocks are SAFE — they're stripped from release builds
# Only report prints that are NOT behind #if DEBUG as issues

# Find TODO/FIXME that might be release blockers
# NOTE: not all TODOs are blockers — read each to assess urgency
Grep pattern="(TODO|FIXME|HACK|XXX):" glob="**/*.swift" output_mode="content"

# Find hardcoded test data
Grep pattern="localhost|127\\.0\\.0\\.1|test@|example\\.com" glob="**/*.swift" output_mode="content"
```

### 5.3: Check for Warnings

```bash
# Build and count warnings — adjust scheme and destination for the project
xcodebuild build -scheme <AppName> -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep "warning:" | wc -l
```

### 5.4: Deployment Target

```bash
# Verify minimum deployment target is intentional
Grep pattern="IPHONEOS_DEPLOYMENT_TARGET" glob="**/*.pbxproj" output_mode="content"
```

---

## Step 6: Privacy & Compliance

### 6.1: Privacy Manifest

```bash
# Check if PrivacyInfo.xcprivacy exists
Glob pattern="**/PrivacyInfo.xcprivacy"

# If found, read its contents
# Check for required API declarations (iOS 17+)
```

### 6.2: Required API Reasons

Check if the app uses APIs that require privacy reason declarations:

```bash
# File timestamp APIs
Grep pattern="creationDate|modificationDate|fileModificationDate" glob="**/*.swift"

# Disk space APIs
Grep pattern="volumeAvailableCapacity|systemFreeSize" glob="**/*.swift"

# User defaults APIs — if >0, requires NSPrivacyAccessedAPICategoryUserDefaults in privacy manifest
Grep pattern="UserDefaults" glob="**/*.swift" output_mode="count"

# System boot time APIs
Grep pattern="systemUptime|processInfo\.systemUptime" glob="**/*.swift"
```

If any are found but not declared in the privacy manifest, flag it.

### 6.3: Third-Party SDK Privacy Manifests

```bash
# Check that third-party packages include privacy manifests
Glob pattern="**/PrivacyInfo.xcprivacy"
# Cross-reference with Package.resolved to identify SDKs missing manifests
```

### 6.4: App Transport Security (ATS)

```bash
# Check for ATS exceptions — NSAllowsArbitraryLoads disables HTTPS enforcement
Grep pattern="NSAllowsArbitraryLoads" glob="**/*.plist" output_mode="content"

# Check for per-domain exceptions (more targeted, may be acceptable)
Grep pattern="NSExceptionDomains" glob="**/*.plist" output_mode="content"
```

If `NSAllowsArbitraryLoads = true` is found, flag as a potential App Store blocker — Apple may reject apps with blanket ATS exceptions without justification.

### 6.5: Entitlements Check

```bash
# Find entitlements files
Glob pattern="**/*.entitlements"

# If found, read contents and verify capabilities match what the app actually uses
# Unused entitlements should be removed before submission
```

---

## Step 7: App Store Metadata

### 7.1: App Icon

```bash
# Verify app icon asset exists and has all required sizes
Glob pattern="**/AppIcon.appiconset/Contents.json"

# If found, read the Contents.json to check for missing sizes
# A complete icon set prevents App Store Connect rejection
```

### 7.2: Launch Screen

```bash
# Check for launch screen configuration (required for App Store)
Grep pattern="UILaunchScreen|UILaunchStoryboardName" glob="**/*.plist" output_mode="content"

# Or check for LaunchScreen storyboard
Glob pattern="**/LaunchScreen.storyboard"
```

### 7.3: Screenshots

```bash
# Check if screenshot assets exist
Glob pattern="**/Screenshots/**/*.png"
Glob pattern="**/Screenshots/**/*.jpg"

# If found, verify dimensions match App Store requirements
# Required: 6.9" (1320x2868), 6.5" (1242x2688), 5.5" (1242x2208)
for f in $(find . -path "*/Screenshots/*.png" -o -path "*/Screenshots/*.jpg" 2>/dev/null); do
  sips -g pixelWidth -g pixelHeight "$f" 2>/dev/null
done
```

Ask user: Are screenshots up to date with current UI?

### 7.4: URLs

```bash
# Check for support URL in project settings
Grep pattern="support.*url|privacy.*url|marketing.*url" glob="**/*.plist" -i output_mode="content"
```

Remind user to verify:
- [ ] Support URL is valid and loads
- [ ] Privacy Policy URL is valid and loads
- [ ] Marketing URL is valid (if applicable)

### 7.5: Localization Completeness

```bash
# Find all localization directories
Glob pattern="**/*.lproj"

# Check for missing keys across localization files
Glob pattern="**/*.lproj/Localizable.strings"
Glob pattern="**/*.lproj/Localizable.xcstrings"

# If multiple languages exist, verify key counts match across .lproj directories
```

---

## Step 8: Archive Readiness

### 8.1: Signing Check

```bash
# Check code signing settings
Grep pattern="CODE_SIGN_IDENTITY|DEVELOPMENT_TEAM|PROVISIONING_PROFILE" glob="**/*.pbxproj" output_mode="content"
```

### 8.2: Build Configuration

```bash
# Check optimization settings for Release
Grep pattern="SWIFT_OPTIMIZATION_LEVEL|GCC_OPTIMIZATION_LEVEL" glob="**/*.pbxproj" output_mode="content"
```

### 8.3: Package Dependencies

```bash
# Check for Package.resolved — ensures reproducible builds
Glob pattern="**/Package.resolved"

# If found, read it to check for:
# - Deprecated or archived packages (note the URLs for user review)
# - Very old versions that may have known issues
```

---

## Step 9: Generate Report

**Display the full checklist, changelog, code readiness, privacy status, and metadata summary inline**, then write report to `.agents/research/YYYY-MM-DD-release-prep-vX.Y.Z.md`:

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

**Bug Fixes:**
- [list]

### App Store "What's New" (copy-paste ready)

[User-facing release notes text]

## Code Readiness

| Check | Status | Notes |
|-------|--------|-------|
| Tests passing | ✓ / ✗ | X tests, Y passed |
| Debug code removed | ✓ / ✗ | N non-DEBUG prints found |
| No blocking TODOs | ✓ / ✗ | List if any |
| Build warnings | ✓ / ✗ | N warnings |
| Deployment target | ✓ | iOS X.Y |

## Privacy & Compliance

| Check | Status | Notes |
|-------|--------|-------|
| Privacy manifest exists | ✓ / ✗ | |
| API reasons declared | ✓ / ✗ | |
| Third-party manifests | ✓ / ✗ | |
| ATS configured | ✓ / ✗ | |
| Entitlements match | ✓ / ✗ | |

## App Store Metadata

| Check | Status | Notes |
|-------|--------|-------|
| App icon complete | ✓ / ✗ | |
| Launch screen exists | ✓ / ✗ | |
| Screenshots current | ✓ / ✗ | |
| What's New text | ✓ | See above |
| Support URL valid | ✓ / ✗ | |
| Privacy URL valid | ✓ / ✗ | |
| Localizations complete | ✓ / ✗ / N/A | |

## Release Commands

When ready:
```bash
# Archive (or use Xcode: Product → Archive)
xcodebuild archive -scheme <AppName> -archivePath build/<AppName>.xcarchive

# Tag the release
git tag -a vX.Y.Z -m "Release X.Y.Z"
git push origin vX.Y.Z
```

## Post-Release Monitoring

- [ ] Verify app is live on App Store
- [ ] Monitor crash reports for 48 hours
- [ ] Check App Store reviews
```

---

## Step 10: Follow-up

```
AskUserQuestion with questions:
[
  {
    "question": "How would you like to proceed?",
    "header": "Next",
    "options": [
      {"label": "Fix blocking issues", "description": "Address any ✗ items before release"},
      {"label": "Archive and submit", "description": "Ready to build for App Store"},
      {"label": "Report is sufficient", "description": "I'll handle the rest manually"}
    ],
    "multiSelect": false
  }
]
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Can't find pbxproj | Check for `.xcodeproj` directory: `Glob pattern="**/*.xcodeproj"` |
| Multiple MARKETING_VERSION lines | Normal — one per build config (Debug/Release). Use `replace_all=true` |
| No git tags exist | Use date-based log: `git log --since="YYYY-MM-DD"` |
| Privacy manifest missing | Flag as blocker — required for App Store since iOS 17 |
| Tests fail | Flag as blocker — don't release with failing tests |
| Print statements found | Read each — only flag prints NOT inside `#if DEBUG` blocks |
| App icon missing sizes | Check `Contents.json` — modern Xcode uses a single 1024x1024 image |
| NSAllowsArbitraryLoads = true | Flag as blocker — Apple requires justification for blanket ATS exceptions |
| No launch screen | Flag as blocker — required for App Store submission |
| Localization keys mismatch | Compare key counts across `.lproj` directories — missing keys show default language |
| Can't determine scheme | Run `xcodebuild -list -json` to find available schemes |
