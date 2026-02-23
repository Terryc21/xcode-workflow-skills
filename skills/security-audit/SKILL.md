---
name: security-audit
description: Focused security scan covering API keys, storage, network, permissions, and privacy manifest
version: 1.0.0
author: Terry Nyberg
license: MIT
allowed-tools: [Grep, Glob, Read, AskUserQuestion]
metadata:
  tier: execution
  category: analysis
---

# Security Audit

> **Quick Ref:** Automated security vulnerability scan for iOS/macOS apps. Output: `.agents/research/YYYY-MM-DD-security-audit.md`

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

Comprehensive security scan covering API keys, storage, network, permissions, and privacy manifest.

---

## Quick Commands

| Command | Description |
|---------|-------------|
| `/security-audit` | Full interactive audit |
| `/security-audit --quick` | Surface scan only |
| `/security-audit --focus=secrets` | Scan only for hardcoded secrets |
| `/security-audit --focus=storage` | Scan only for storage issues |
| `/security-audit --focus=network` | Scan only for network issues |
| `/security-audit --focus=privacy` | Scan only for privacy manifest issues |

---

## Step 1: Interactive Scope Selection

Use AskUserQuestion to determine audit scope:

```
questions:
[
  {
    "question": "What type of security audit do you want?",
    "header": "Scope",
    "options": [
      {"label": "Full audit (Recommended)", "description": "Scan all categories: secrets, storage, network, privacy"},
      {"label": "Quick surface scan", "description": "Fast check for obvious issues only"},
      {"label": "Focused audit", "description": "I'll specify which category to focus on"}
    ],
    "multiSelect": false
  }
]
```

If "Focused audit" selected, ask which categories:

```
questions:
[
  {
    "question": "Which security categories should I scan?",
    "header": "Focus",
    "options": [
      {"label": "Secrets & API Keys", "description": "Hardcoded credentials, tokens, keys"},
      {"label": "Data Storage", "description": "Keychain usage, UserDefaults, file protection"},
      {"label": "Network Security", "description": "HTTPS, ATS, certificate pinning"},
      {"label": "Privacy & Permissions", "description": "Privacy manifest, usage descriptions"}
    ],
    "multiSelect": true
  }
]
```

---

## Step 2: Automated Scanning

Execute grep patterns for each enabled category.

### 2.1 Secrets & API Keys

**Search for hardcoded secrets:**

```
# API keys and secrets
Grep pattern="(api[_-]?key|apikey|secret[_-]?key|client[_-]?secret)\s*[:=]\s*[\"'][^\"']+[\"']" glob="*.swift"
Grep pattern="(api[_-]?key|apikey|secret|password|token)\s*[:=]" glob="*.{plist,json,xcconfig}"

# Bearer tokens
Grep pattern="[Bb]earer\s+[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+" glob="*.swift"

# AWS credentials
Grep pattern="AKIA[0-9A-Z]{16}" glob="*.{swift,plist,json,xcconfig}"

# Private keys
Grep pattern="-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----" glob="*.{swift,pem,key}"

# Firebase/Google API keys
Grep pattern="AIza[0-9A-Za-z\-_]{35}" glob="*.{swift,plist,json}"

# Stripe keys
Grep pattern="(sk|pk)_(live|test)_[0-9a-zA-Z]{24}" glob="*.{swift,plist,json}"
```

**Severity Scoring:**

| Pattern | Severity | Risk |
|---------|----------|------|
| Production API key in code | CRITICAL | Immediate credential theft |
| Test/staging key in code | HIGH | Exposure if pushed to repo |
| Bearer token hardcoded | CRITICAL | Session hijacking |
| AWS credentials | CRITICAL | Cloud account compromise |
| Private key in repo | CRITICAL | Full system compromise |

### 2.2 Data Storage

**Search for insecure storage:**

```
# Sensitive data in UserDefaults (should be in Keychain)
Grep pattern="UserDefaults.*\.(password|token|secret|apiKey|credentials)" glob="*.swift"
Grep pattern="@AppStorage.*\b(password|token|secret|key|credential)" glob="*.swift"

# Missing Keychain usage
Grep pattern="(password|token|secret|credential).*=.*\"" glob="*.swift"

# Force unwrapping in security-critical code
Grep pattern="!\s*$" path="**/Auth/**" glob="*.swift"
Grep pattern="!\s*$" path="**/Keychain/**" glob="*.swift"
Grep pattern="!\s*$" path="**/Security/**" glob="*.swift"

# Logging sensitive data
Grep pattern="(print|NSLog|os_log|logger)\s*\(.*\b(password|token|secret|apiKey|credential)" glob="*.swift"
```

**Severity Scoring:**

| Pattern | Severity | Risk |
|---------|----------|------|
| Password in UserDefaults | CRITICAL | Easily readable by backup tools |
| Token in @AppStorage | CRITICAL | Plaintext in plist files |
| Logging credentials | HIGH | Exposed in device logs |
| Force unwrap in auth code | MEDIUM | Crash → DoS vector |

### 2.3 Network Security

**Search for network vulnerabilities:**

```
# HTTP (non-HTTPS) URLs
Grep pattern="http://(?!localhost|127\.0\.0\.1)" glob="*.swift"
Grep pattern="http://" glob="*.plist"

# ATS exceptions
Grep pattern="NSAllowsArbitraryLoads.*true" glob="*.plist"
Grep pattern="NSExceptionAllowsInsecureHTTPLoads.*true" glob="*.plist"

# Disabled certificate validation
Grep pattern="URLSessionDelegate.*didReceive challenge" glob="*.swift"
Grep pattern="\.serverTrust" glob="*.swift"
Grep pattern="SecTrustSetAnchorCertificates" glob="*.swift"

# Request/response logging in production
Grep pattern="(print|dump)\s*\(\s*request" glob="*.swift"
Grep pattern="(print|dump)\s*\(\s*response" glob="*.swift"
```

**Severity Scoring:**

| Pattern | Severity | Risk |
|---------|----------|------|
| HTTP URL (non-localhost) | HIGH | Man-in-the-middle attacks |
| NSAllowsArbitraryLoads | HIGH | Bypasses all ATS protections |
| Custom cert validation | MEDIUM | May disable security checks |
| Logging requests | LOW | Data exposure in debug |

### 2.4 Input Validation

**Search for validation gaps:**

```
# Unvalidated URL scheme handling
Grep pattern="func application.*open url.*options" glob="*.swift"
Grep pattern="onOpenURL" glob="*.swift"

# SQL injection risk (if using raw SQL)
Grep pattern="\"SELECT.*\\\(.*\)\"" glob="*.swift"
Grep pattern="\"INSERT.*\\\(.*\)\"" glob="*.swift"

# WebView JavaScript injection
Grep pattern="evaluateJavaScript.*\\\(" glob="*.swift"
Grep pattern="WKWebView.*loadHTMLString" glob="*.swift"
```

### 2.5 Privacy & Permissions

**Check Info.plist usage descriptions:**

```
# Read Info.plist and check for required keys
Read Info.plist

# Required descriptions if feature is used:
# - NSCameraUsageDescription
# - NSPhotoLibraryUsageDescription
# - NSPhotoLibraryAddUsageDescription
# - NSLocationWhenInUseUsageDescription
# - NSLocationAlwaysUsageDescription
# - NSMicrophoneUsageDescription
# - NSContactsUsageDescription
# - NSCalendarsUsageDescription
```

**Check Privacy Manifest:**

```
# Find PrivacyInfo.xcprivacy
Glob pattern="**/PrivacyInfo.xcprivacy"

# If not found → CRITICAL issue (required for iOS 17+)

# If found, read and verify:
# - NSPrivacyAccessedAPITypes declared for all used APIs
# - NSPrivacyTracking set appropriately
# - NSPrivacyTrackingDomains listed if tracking
```

**Required API declarations (if used):**

| API | Privacy Manifest Key | Required Reason |
|-----|---------------------|-----------------|
| File timestamp APIs | `NSPrivacyAccessedAPICategoryFileTimestamp` | Must declare reason |
| System boot time | `NSPrivacyAccessedAPICategorySystemBootTime` | Must declare reason |
| Disk space APIs | `NSPrivacyAccessedAPICategoryDiskSpace` | Must declare reason |
| Active keyboards | `NSPrivacyAccessedAPICategoryActiveKeyboards` | Must declare reason |
| User defaults | `NSPrivacyAccessedAPICategoryUserDefaults` | Must declare reason |

---

## Step 3: Check Third-Party SDK Privacy Manifests

For each dependency, verify privacy manifest inclusion:

```bash
# List SPM dependencies
cat Package.resolved | grep "\"package\"" || echo "No SPM dependencies"

# Check for embedded frameworks
find . -name "*.xcframework" -o -name "*.framework" | head -20
```

For each SDK, check if privacy manifest is bundled or needs to be added.

---

## Step 4: Generate Report

Write report to `.agents/research/YYYY-MM-DD-security-audit.md`:

```markdown
# Security Audit Report

**Date:** YYYY-MM-DD HH:MM
**Project:** [Project Name]
**Scan Type:** [Full/Quick/Focused]

## Summary

| Category | Grade | Critical | High | Medium | Low |
|----------|-------|----------|------|--------|-----|
| Secrets & API Keys | A-F | X | X | X | X |
| Data Storage | A-F | X | X | X | X |
| Network Security | A-F | X | X | X | X |
| Input Validation | A-F | X | X | X | X |
| Privacy & Permissions | A-F | X | X | X | X |
| **Overall** | **A-F** | **X** | **X** | **X** | **X** |

## Critical Issues (Fix Immediately)

### 1. [Issue Title]
**File:** path/to/file.swift:42
**Severity:** CRITICAL
**Risk:** [What could happen]

```swift
// Current code (vulnerable):
let apiKey = "sk_live_abc123..."  // HARDCODED API KEY
```

**Remediation:**
```swift
// Secure approach:
guard let apiKey = KeychainService.shared.getValue(forKey: "apiKey") else {
    throw SecurityError.missingCredentials
}
```

---

### 2. [Next Issue]
...

## High Priority Issues

### 1. [Issue Title]
...

## Medium Priority Issues

...

## Low Priority Issues

...

## Privacy Manifest Status

| Requirement | Status | Notes |
|-------------|--------|-------|
| PrivacyInfo.xcprivacy exists | ✓/✗ | |
| NSPrivacyAccessedAPITypes declared | ✓/✗ | |
| Third-party SDK manifests included | ✓/✗ | |

## Recommendations

### Immediate Actions
1. [Action 1]
2. [Action 2]

### Short-term Improvements
1. [Action 1]
2. [Action 2]

### Best Practices to Adopt
1. [Practice 1]
2. [Practice 2]
```

---

## Step 5: Present Interactive Summary

Show summary to user:

```
## Security Audit Complete

**Overall Grade:** [A-F]

| Severity | Count |
|----------|-------|
| CRITICAL | X |
| HIGH | X |
| MEDIUM | X |
| LOW | X |

**Full report:** .agents/research/YYYY-MM-DD-security-audit.md

What would you like to do?
```

Use AskUserQuestion:

```
questions:
[
  {
    "question": "How would you like to proceed?",
    "header": "Next",
    "options": [
      {"label": "Fix critical issues now", "description": "Walk through each critical issue with fixes"},
      {"label": "See full report", "description": "Display the detailed markdown report"},
      {"label": "Export for review", "description": "Report saved, I'll review later"},
      {"label": "Re-scan specific category", "description": "Run deeper scan on one area"}
    ],
    "multiSelect": false
  }
]
```

---

## Severity Definitions

| Severity | CVSS Range | Response Time | Description |
|----------|------------|---------------|-------------|
| **CRITICAL** | 9.0-10.0 | Immediate | Actively exploitable, data exposure imminent |
| **HIGH** | 7.0-8.9 | Within 24 hours | Serious vulnerability, high impact if exploited |
| **MEDIUM** | 4.0-6.9 | Within 1 week | Moderate risk, requires specific conditions |
| **LOW** | 0.1-3.9 | Next release | Minor issue, limited impact |

---

## For iOS-Specific Deep Dives

This skill focuses on workflow orchestration. For deep iOS-specific security analysis:

- **Keychain best practices:** Invoke `/axiom:axiom-storage`
- **App Transport Security:** Invoke `/axiom:axiom-networking`
- **Privacy Manifest details:** Invoke `/axiom:axiom-privacy-ux`
- **Secure coding patterns:** Invoke `/axiom:axiom-security-privacy-scanner`

---

## See Also

- `/review-changes` - Pre-commit review including security checks
- `/release-prep` - Pre-release checklist including security verification
- `/performance-check` - Performance analysis (complements security)

---

## Common False Positives

| Pattern | Why It's OK | How to Verify |
|---------|-------------|---------------|
| `apiKey` in struct property name | Just a property name, not a value | Check if value is hardcoded |
| `http://localhost` | Local development only | Verify not shipped to production |
| Test credentials in test files | Intentional for testing | Verify in `*Tests.swift` only |
| Keychain access with `!` | May be intentional crash | Review surrounding error handling |

---

## Appendix: Grep Patterns Reference

### All Secrets Patterns (Combined)
```
(api[_-]?key|apikey|secret[_-]?key|client[_-]?secret|password|token|bearer|authorization|credential)\s*[:=]\s*[\"'][^\"']+[\"']
```

### All Storage Patterns (Combined)
```
(UserDefaults|@AppStorage).*\b(password|token|secret|apiKey|credential)
```

### All Network Patterns (Combined)
```
http://(?!localhost|127\.0\.0\.1)|NSAllowsArbitraryLoads.*true
```

### All Logging Patterns (Combined)
```
(print|NSLog|os_log|logger|dump)\s*\(.*\b(password|token|secret|apiKey|credential|request|response)
```
