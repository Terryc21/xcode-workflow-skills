---
name: security-audit
description: 'Automated security vulnerability scan for iOS/macOS apps. Covers secrets, storage, network, input validation, privacy manifest, and file protection. Triggers: "security audit", "check for secrets", "security scan".'
version: 2.1.0
author: Terry Nyberg
license: MIT
allowed-tools: [Grep, Glob, Read, Write, Bash, AskUserQuestion]
metadata:
  tier: execution
  category: analysis
---

# Security Audit

> **Quick Ref:** Automated security scan for iOS/macOS apps. Output: `.agents/research/YYYY-MM-DD-security-audit.md`

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

All findings use the **Issue Rating Table** format. Do not use prose severity tags.

---

## Pre-flight: Git Safety Check

```bash
git status --short
```

If uncommitted changes exist:

```
AskUserQuestion with questions:
[
  {
    "question": "You have uncommitted changes. Commit before proceeding?",
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

## Step 1: Scope Selection

```
AskUserQuestion with questions:
[
  {
    "question": "What type of security audit do you want?",
    "header": "Scope",
    "options": [
      {"label": "Full audit (Recommended)", "description": "All categories: secrets, storage, network, input validation, privacy"},
      {"label": "Quick scan", "description": "Secrets + network only — highest-risk categories"},
      {"label": "Focused audit", "description": "I'll specify which categories to scan"}
    ],
    "multiSelect": false
  }
]
```

If "Focused audit", ask which categories:

```
AskUserQuestion with questions:
[
  {
    "question": "Which security categories should I scan?",
    "header": "Focus",
    "options": [
      {"label": "Secrets & API Keys", "description": "Hardcoded credentials, tokens, keys"},
      {"label": "Data Storage", "description": "Keychain, UserDefaults, file protection"},
      {"label": "Network Security", "description": "HTTPS, ATS, certificate handling"},
      {"label": "Privacy & Permissions", "description": "Privacy manifest, usage descriptions"}
    ],
    "multiSelect": true
  }
]
```

### Freshness

Base all findings on current source code only. Do not read or reference
files in `.agents/`, `scratch/`, or prior audit reports. Ignore cached
findings from auto-memory or previous sessions. Every finding must come
from scanning the actual codebase as it exists now.

---

## Step 2: Automated Scanning

Run patterns for each enabled category. **Quick scan** runs only 2.1 and 2.3. **Full audit** runs all sections.

Every grep hit is a CANDIDATE — verify by reading the file before reporting (see Step 3).

### 2.1 Secrets & API Keys

```bash
# API keys and secrets — hardcoded values
# FALSE POSITIVE: property/parameter names without values, enum case names
Grep pattern="(api[_-]?key|apikey|secret[_-]?key|client[_-]?secret)\s*[:=]\s*[\"'][^\"']+[\"']" glob="**/*.swift" -i

# Secrets in config files
Grep pattern="(api[_-]?key|apikey|secret|password|token)\s*[:=]" glob="**/*.{plist,json,xcconfig}"

# Bearer tokens
Grep pattern="[Bb]earer\s+[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+" glob="**/*.swift"

# AWS credentials
Grep pattern="AKIA[0-9A-Z]{16}" glob="**/*.{swift,plist,json,xcconfig}"

# Private keys
Grep pattern="-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----" glob="**/*.{swift,pem,key}"

# Firebase/Google API keys
Grep pattern="AIza[0-9A-Za-z\-_]{35}" glob="**/*.{swift,plist,json}"

# Stripe keys
Grep pattern="(sk|pk)_(live|test)_[0-9a-zA-Z]{24}" glob="**/*.{swift,plist,json}"
```

**Common false positives:**
- `apiKey` as a struct property name (no hardcoded value) → check if value is assigned inline
- Keys in test fixtures (`*Tests.swift`) → intentional for testing, verify scope
- Placeholder values like `"YOUR_API_KEY"` → not a real secret

### 2.2 Data Storage

```bash
# Sensitive data in UserDefaults (should be in Keychain)
Grep pattern="UserDefaults.*\b(password|token|secret|apiKey|credentials)" glob="**/*.swift" -i
Grep pattern="@AppStorage.*\b(password|token|secret|key|credential)" glob="**/*.swift" -i

# Email/phone stored insecurely (often overlooked — these are PII)
# FALSE POSITIVE: email/phone used as display text, not storage
Grep pattern="(UserDefaults|@AppStorage).*\b(email|phone|address)" glob="**/*.swift" -i

# Logging sensitive data
Grep pattern="(print|NSLog|os_log|Logger|dump)\s*\(.*\b(password|token|secret|apiKey|credential)" glob="**/*.swift" -i

# Positive signal: Keychain usage (note for grading)
Grep pattern="(Keychain|SecItem|kSecClass)" glob="**/*.swift" output_mode="files_with_matches"

# Positive signal: Encryption usage
Grep pattern="(CryptoKit|AES|encrypt|decrypt)" glob="**/*.swift" output_mode="files_with_matches"
```

**Common false positives:**
- `email` as a form field label, not stored in UserDefaults → read context
- Logging a token variable name in a debug comment → check if actual value is logged

### 2.3 Network Security

```bash
# HTTP (non-HTTPS) URLs
# FALSE POSITIVE: http://localhost, 127.0.0.1, XML namespace URIs
Grep pattern="http://(?!localhost|127\.0\.0\.1)" glob="**/*.swift"
Grep pattern="http://" glob="**/*.plist"

# ATS exceptions
Grep pattern="NSAllowsArbitraryLoads" glob="**/*.plist"
Grep pattern="NSExceptionAllowsInsecureHTTPLoads" glob="**/*.plist"

# Custom certificate validation — may disable security
# Read the implementation to check if it WEAKENS or STRENGTHENS validation
Grep pattern="URLSessionDelegate.*didReceive challenge" glob="**/*.swift"
Grep pattern="\.serverTrust" glob="**/*.swift"

# Request/response logging in production
# FALSE POSITIVE: debug-only logging behind #if DEBUG
Grep pattern="(print|dump)\s*\(.*\b(request|response)" glob="**/*.swift"
```

**Common false positives:**
- `http://` in XML namespace strings or URL scheme detection logic → not real HTTP traffic
- `.serverTrust` used to ADD certificate pinning (strengthens security) → read the handler
- Logging behind `#if DEBUG` → won't run in production

### 2.4 Input Validation

```bash
# URL scheme handling — check if input is validated
# Read the handler to see if URL components are validated before use
Grep pattern="onOpenURL" glob="**/*.swift"
Grep pattern="func application.*open url.*options" glob="**/*.swift"

# SQL injection risk (raw SQL with interpolation)
Grep pattern="\"(SELECT|INSERT|UPDATE|DELETE).*\\\(" glob="**/*.swift" -i

# WebView JavaScript injection
Grep pattern="evaluateJavaScript.*\\\(" glob="**/*.swift"
Grep pattern="WKWebView.*loadHTMLString" glob="**/*.swift"
```

### 2.5 Privacy & Permissions

```bash
# Find and read Info.plist
Glob pattern="**/Info.plist"
# Read it and check for: NSCameraUsageDescription, NSPhotoLibraryUsageDescription,
# NSLocationWhenInUseUsageDescription, NSMicrophoneUsageDescription, etc.
# Cross-reference: if the app uses AVCaptureSession but has no NSCameraUsageDescription → issue

# Privacy manifest (required for App Store, iOS 17+)
Glob pattern="**/PrivacyInfo.xcprivacy"
# If not found → CRITICAL issue
# If found, read and verify NSPrivacyAccessedAPITypes covers all used APIs

# Check which required-reason APIs are used
Grep pattern="(fileModificationDate|systemUptime|volumeAvailableCapacity)" glob="**/*.swift"
Grep pattern="UserDefaults" glob="**/*.swift" output_mode="count"
```

**Required API declarations (if used):**

| API | Privacy Manifest Key |
|-----|---------------------|
| File timestamp APIs | `NSPrivacyAccessedAPICategoryFileTimestamp` |
| System boot time | `NSPrivacyAccessedAPICategorySystemBootTime` |
| Disk space APIs | `NSPrivacyAccessedAPICategoryDiskSpace` |
| User defaults | `NSPrivacyAccessedAPICategoryUserDefaults` |

### 2.6 File Protection (iOS)

```bash
# Check for file protection on sensitive data writes
# Correct pattern: Data.write(to:options:[.completeFileProtection])
# Incorrect: trying to set URLResourceValues.fileProtection (get-only on iOS)
Grep pattern="\.completeFileProtection" glob="**/*.swift"
Grep pattern="fileProtection" glob="**/*.swift"

# Sensitive data written without protection
# Read flagged files to check if sensitive data is written with protection options
Grep pattern="\.write\(to:" glob="**/*.swift"
```

### 2.7 Third-Party Dependencies

```bash
# SPM dependencies
Glob pattern="**/Package.resolved"
# Read the file and list dependencies

# Embedded frameworks
Glob pattern="**/*.xcframework"
Glob pattern="**/*.framework"

# For each dependency, check if a privacy manifest is bundled
```

---

## Step 3: Verification Rule (CRITICAL)

Before reporting ANY finding as a security issue:

1. **Read the flagged file** — at minimum 20 lines of context around the match
2. **Check if it's test code** — credentials in `*Tests.swift` are intentional fixtures
3. **Check for debug guards** — logging behind `#if DEBUG` doesn't ship to production
4. **Check for Keychain proximity** — a `password` variable may be read FROM Keychain, not stored insecurely
5. **Classify** — CONFIRMED, FALSE_POSITIVE, or INTENTIONAL before reporting

**Security-specific false positives:**
- Property/parameter named `apiKey` with no hardcoded value
- `http://localhost` or `http://127.0.0.1` — development only
- Test credentials in test files — intentional fixtures
- Keychain access followed by force unwrap — may be intentional crash-on-missing-credential
- `.serverTrust` used to ADD pinning, not bypass validation

---

## Step 4: Grading

### Grade Criteria

| Grade | Criteria |
|-------|----------|
| A | No secrets in code, Keychain for all credentials, privacy manifest complete, HTTPS everywhere, file protection on sensitive writes |
| B | No secrets in code, mostly Keychain usage, privacy manifest present but minor gaps, HTTPS everywhere |
| C | No production secrets but test keys in code, mixed storage (some UserDefaults for sensitive data), privacy manifest incomplete |
| D | Secrets or tokens in code, sensitive data in UserDefaults, missing privacy manifest, HTTP URLs |
| F | Production API keys/credentials in code, no Keychain usage, no privacy manifest |

### Category Grades

Grade each scanned category independently:

| Category | What to Evaluate |
|----------|-----------------|
| Secrets & API Keys | Any hardcoded secrets? How are credentials managed? |
| Data Storage | Keychain vs UserDefaults for sensitive data? Logging sanitized? |
| Network Security | HTTPS everywhere? ATS configured? Certificate handling sound? |
| Input Validation | URL schemes validated? SQL parameterized? WebView inputs sanitized? |
| Privacy & Permissions | Privacy manifest present and complete? Usage descriptions accurate? |
| File Protection | Sensitive files written with protection? Correct API usage? |

### Overall Grade

The weakest category dominates. Formula: start with the average of all categories, then cap at one grade above the lowest category. Security is only as strong as its weakest link.

Example: If 5 categories are A but Secrets is D → Overall is C (capped at one grade above D, regardless of the A categories).

---

## Step 5: Output

**Display the executive summary, grade summary, issue table, and privacy status inline**, then write report to `.agents/research/YYYY-MM-DD-security-audit.md`.

### Report Structure

```markdown
# Security Audit Report

**Date:** YYYY-MM-DD
**Project:** [name]
**Scan Type:** Full / Quick / Focused

## Executive Summary

[2-3 sentences: overall security posture, biggest risk, top recommendation]

## Grade Summary

Overall: [grade] (Secrets [grade] | Storage [grade] | Network [grade] | Validation [grade] | Privacy [grade] | File Protection [grade])

## Positive Findings

[What's done well — Keychain usage, HTTPS, encryption, privacy manifest present]

## Issue Rating Table

| # | Finding | Urgency | Risk: Fix | Risk: No Fix | ROI | Blast Radius | Fix Effort |
|---|---------|---------|-----------|-------------|-----|-------------|------------|
| 1 | ... | 🔴 Critical | ... | ... | ... | ... | ... |

## Privacy Manifest Status

| Requirement | Status |
|-------------|--------|
| PrivacyInfo.xcprivacy exists | ✓/✗ |
| NSPrivacyAccessedAPITypes declared | ✓/✗ |
| Third-party SDK manifests included | ✓/✗ |

## Remediation Examples

[For each critical/high finding, show current vulnerable code and secure fix]
```

Use the Issue Rating scale:
- **Urgency:** 🔴 CRITICAL (actively exploitable) · 🟡 HIGH (serious if exploited) · 🟢 MEDIUM (moderate risk) · ⚪ LOW (minor)
- **ROI:** 🟠 Excellent · 🟢 Good · 🟡 Marginal · 🔴 Poor
- **Fix Effort:** Trivial / Small / Medium / Large

---

## Step 6: Follow-up

```
AskUserQuestion with questions:
[
  {
    "question": "How would you like to proceed?",
    "header": "Next",
    "options": [
      {"label": "Fix critical issues now", "description": "Walk through each critical/high issue with fixes"},
      {"label": "Re-scan specific category", "description": "Deeper scan on one area"},
      {"label": "Report is sufficient", "description": "Report saved to .agents/research/"}
    ],
    "multiSelect": false
  }
]
```

If "Fix critical issues now": Walk through each 🔴/🟡 finding, show the vulnerable code, propose a secure fix, apply after user approval.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Too many grep hits for `password`/`token` | Narrow glob to specific directories, exclude test files |
| Can't find Info.plist | Check for `.plist` in project root, target folders, or Xcode-generated location |
| Privacy manifest not found | May not exist yet — flag as critical and offer to create one |
| False positive rate too high | Read more context (30+ lines), check if value is hardcoded vs passed in |
| Dependency has no privacy manifest | Check SDK documentation — some declare in their own bundle |
