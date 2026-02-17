---
name: scan-similar-bugs
description: After fixing a bug, systematically find other occurrences of the same or similar patterns across the codebase
---

# Scan for Similar Bugs

After fixing a bug, use this systematic process to find other occurrences of the same or similar patterns.

## PHASE 1: Bug Classification (Do NOT skip)

1. **BUG CATEGORY** (choose one or more):
   - [ ] Data flow bypass (writes not routed correctly)
   - [ ] Missing relationship/reference
   - [ ] State synchronization failure
   - [ ] Notification/refresh missing
   - [ ] Race condition / timing
   - [ ] Resource lifecycle (retain cycle, leak, dangling)
   - [ ] **Platform-specific UI** (iOS-only or macOS-only code that should be cross-platform)
   - [ ] Other: ___

2. **ROOT CAUSE**: Why did this bug exist? (e.g., "two code paths for the same operation", "pattern applied inconsistently")

3. **INVARIANT VIOLATED**: State the rule that should ALWAYS be true.
   Format: "When [condition], then [required behavior]"

4. **AFFECTED SCOPE**: List ALL code locations where this invariant applies:
   - Files/directories to scan
   - Property names, function names, type names involved
   - Both the CORRECT pattern and INCORRECT pattern

## PHASE 2: Search Strategy

Generate grep/glob patterns for EACH of these layers:

| Layer | Description | Patterns |
|-------|-------------|----------|
| 1. Exact match | Same code pattern as the bug | |
| 2. Same category | Same bug type, different syntax | |
| 3. Related violations | Same architectural rule, different subsystem | |

## PHASE 2.5: Cross-Platform Verification (For Multi-Platform Projects)

**Required for iOS/macOS projects.** After scanning the primary platform, scan the opposite direction:

| Direction | Search For | Example Pattern |
|-----------|------------|-----------------|
| iOS → macOS | iOS-only code missing macOS equivalent | `#if os(iOS)` wrapping entire ToolbarItem |
| macOS → iOS | macOS-only code missing iOS equivalent | `#if os(macOS)` wrapping dismiss buttons |

**Common Cross-Platform Invariants:**
- When a sheet/modal is presented, ALL platforms must have a dismiss mechanism
- When a feature is available on one platform, verify if it should exist on the other
- Platform-specific styling (label/icon) is OK; platform-specific functionality is a bug

**Legitimate Platform-Only Code (DO NOT flag):**
- `placement: .keyboard` (iOS-only keyboard toolbar)
- `UIImage` / `NSImage` usage
- `.navigationBarTitleDisplayMode()` (iOS-only)
- Platform-specific API wrappers with `#if os()` around the implementation

## PHASE 3: Execute & Report

For each pattern, execute the search and report:
- [ ] Pattern 1: ___ (X matches, Y confirmed bugs)
- [ ] Pattern 2: ___ (X matches, Y confirmed bugs)
- [ ] Cross-platform scan: ___ (X matches, Y confirmed bugs)
- ...

## PHASE 4: Findings Summary

| File:Line | Severity | Platform | Description | Fix Required |
|-----------|----------|----------|-------------|--------------|
| | CRITICAL / MEDIUM / LOW | iOS/macOS/Both | | |

Only mark the task complete after ALL patterns have been checked, INCLUDING cross-platform verification.
