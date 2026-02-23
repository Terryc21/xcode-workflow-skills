---
name: debug
description: Systematic debugging workflow - reproduce, isolate, hypothesize, verify, and fix
version: 1.0.0
author: Terry Nyberg
license: MIT
allowed-tools: [Read, Grep, Glob, Bash, AskUserQuestion]
metadata:
  tier: execution
  category: debugging
---

# Debug

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

Systematic debugging workflow: reproduce, isolate, hypothesize, verify, and fix.

## Input Required

Describe the bug:
- What is the expected behavior?
- What is the actual behavior?
- Steps to reproduce (if known)
- Any error messages or logs
- When did it start happening? (recent change?)

---

## Debugging Process

### Step 1: Reproduce
- [ ] Confirm I can reproduce the issue
- [ ] Identify exact steps to trigger
- [ ] Note: Does it happen every time or intermittently?

### Step 2: Isolate
- [ ] Identify the smallest code path that exhibits the bug
- [ ] Rule out environmental factors (simulator vs device, debug vs release)
- [ ] Check recent changes in the affected area (`git log -p <file>`)

### Step 3: Gather Evidence
- [ ] Read relevant code sections
- [ ] Check logs/console output
- [ ] Review crash reports if applicable
- [ ] Search for similar patterns elsewhere in codebase

### Step 4: Hypothesize
List possible causes ranked by likelihood:

| # | Hypothesis | Likelihood | How to Verify |
|---|------------|------------|---------------|
| 1 | | High/Med/Low | |
| 2 | | High/Med/Low | |
| 3 | | High/Med/Low | |

### Step 5: Verify
Test each hypothesis starting with most likely:
- [ ] Hypothesis 1: Result ___
- [ ] Hypothesis 2: Result ___
- [ ] Hypothesis 3: Result ___

### Step 6: Root Cause
**Confirmed Root Cause:** [explanation]

**Why this happened:** [underlying reason - missing validation, race condition, etc.]

### Step 7: Fix
**Proposed Fix:** [description]

**Files to Change:**
| File | Change Required |
|------|-----------------|
| | |

**Risk Assessment:**
- Blast radius: X files
- Regression risk: Low/Medium/High
- Test coverage: Existing tests? New tests needed?

### Step 8: Verify Fix
- [ ] Bug no longer reproduces
- [ ] Existing tests pass
- [ ] New test added to prevent regression
- [ ] No new issues introduced

### Step 9: Similar Bugs
After fixing, use `/scan-similar-bugs` to find other occurrences of this pattern.

---

## For iOS-Specific Debugging

This skill focuses on workflow orchestration. For deep iOS-specific debugging:

- **Memory debugging:** Invoke `/axiom:axiom-memory-debugging`
- **Hang diagnostics:** Invoke `/axiom:axiom-hang-diagnostics`
- **SwiftUI debugging:** Invoke `/axiom:axiom-swiftui-debugging`

---

## See Also

- `/scan-similar-bugs` - Find similar bug patterns after fixing
- `/review-changes` - Review the fix before committing
