---
name: release-prep
description: Pre-release checklist including version bump, changelog, known issues, and store metadata
---

# Release Prep

Pre-release checklist including version bump, changelog, known issues, and store metadata.

## Release Information

**Version:** [X.Y.Z]
**Build:** [number]
**Release Type:** Major / Minor / Patch / Hotfix
**Target Date:** [date]

---

## Pre-Release Checklist

### 1. Code Readiness
- [ ] All planned features complete
- [ ] All critical bugs fixed
- [ ] No known crashes
- [ ] All tests passing
- [ ] Code reviewed and merged

### 2. Version Numbers
- [ ] MARKETING_VERSION updated
- [ ] CURRENT_PROJECT_VERSION updated

### 3. Changelog

**What's New in [version]:**

**Features:**
-

**Improvements:**
-

**Bug Fixes:**
-

### 4. App Store Metadata
- [ ] Screenshots current
- [ ] What's New text written
- [ ] Support URL valid
- [ ] Privacy Policy URL valid

### 5. Privacy & Compliance
- [ ] Privacy Manifest up to date
- [ ] App Privacy accurate
- [ ] Third-party SDK manifests included

### 6. Testing
- [ ] TestFlight build tested
- [ ] Device testing complete
- [ ] Accessibility verified

---

## Release Day

- [ ] Archive and upload
- [ ] Submit for review
- [ ] Tag release: `git tag -a vX.Y.Z -m "Release X.Y.Z"`
- [ ] Push tag: `git push origin vX.Y.Z`

## Post-Release

- [ ] Verify app live
- [ ] Monitor crash reports (48 hours)
- [ ] Monitor reviews
