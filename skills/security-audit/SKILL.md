---
name: security-audit
description: Focused security scan covering API keys, storage, network, permissions, and privacy manifest
---

# Security Audit

Focused security scan covering API keys, storage, network, permissions, and privacy manifest.

## Audit Categories

### 1. Secrets & API Keys

**Search for hardcoded secrets:**
- Patterns: api_key, apiKey, secret, password, token, bearer, authorization
- File types: .swift, .plist, .json, .js, .xcconfig

**Check:**
- [ ] No API keys in source code
- [ ] No secrets in Info.plist
- [ ] Secrets loaded from Keychain or secure environment

### 2. Data Storage

- [ ] Passwords/tokens stored in Keychain (not UserDefaults)
- [ ] Sensitive files have appropriate protection level
- [ ] No PII logged to console

### 3. Network Security

- [ ] All network calls use HTTPS
- [ ] No disabled ATS exceptions without justification
- [ ] Request/response data not logged in production

### 4. Input Validation

- [ ] User input sanitized before use
- [ ] URL schemes validate input
- [ ] Deep links validate parameters

### 5. Privacy & Permissions

**Check Info.plist usage descriptions:**
- [ ] NSCameraUsageDescription
- [ ] NSPhotoLibraryUsageDescription
- [ ] All descriptions are user-friendly and accurate

**Privacy Manifest (PrivacyInfo.xcprivacy):**
- [ ] Exists if required
- [ ] NSPrivacyAccessedAPITypes declared
- [ ] Third-party SDK privacy manifests included

## Output Format

### Overall Security Grade: [A-F]

| Category | Grade | Issues |
|----------|-------|--------|
| Secrets | | |
| Storage | | |
| Network | | |
| Privacy | | |

### Critical Issues (fix immediately):
1.

### Recommendations:
1.
