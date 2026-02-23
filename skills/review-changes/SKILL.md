---
name: review-changes
description: Pre-commit review of staged changes for bugs, style issues, and missing tests
version: 1.0.0
author: Terry Nyberg
license: MIT
allowed-tools: [Bash, Glob, Grep, Read]
metadata:
  tier: execution
  category: analysis
---

# Review Changes

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

Pre-commit review of staged/modified changes for bugs, style issues, and missing tests.

## Process

1. **Identify Changes**
   Run `git status` and `git diff --staged` (or `git diff` if nothing staged) to see what's being changed.

2. **For Each Changed File, Check:**

   ### Correctness
   - [ ] Logic errors or edge cases not handled
   - [ ] Null/nil safety issues
   - [ ] Off-by-one errors
   - [ ] Race conditions or concurrency issues
   - [ ] Error handling gaps (missing catch, unhandled throws)

   ### Consistency
   - [ ] Follows existing patterns in the codebase
   - [ ] Naming conventions match surrounding code
   - [ ] No duplicate logic that should be extracted
   - [ ] Binding bridges used correctly (not bypassing ViewModel routing)

   ### Security
   - [ ] No hardcoded secrets or API keys
   - [ ] User input validated
   - [ ] Sensitive data not logged

   ### Performance
   - [ ] No expensive operations on main thread
   - [ ] No N+1 query patterns
   - [ ] Large data handled with pagination/lazy loading

   ### SwiftUI Specific
   - [ ] @State/@StateObject/@Observable used correctly
   - [ ] No unnecessary view rebuilds
   - [ ] Proper use of task/onAppear for async work

3. **Test Coverage**
   - Are there existing tests for the modified code?
   - Do the changes require new tests?
   - Will existing tests still pass?

## Output Format

### Summary
- **Files Changed:** X
- **Risk Level:** Low / Medium / High
- **Recommendation:** Ready to commit / Needs fixes / Needs discussion

### Issues Found
| File:Line | Severity | Issue | Suggested Fix |
|-----------|----------|-------|---------------|
| | | | |

### Approval
If no issues: "✅ Changes look good. Ready to commit."
If issues found: "⚠️ Found X issues. Please address before committing."

---

## See Also

- `/debug` - When review reveals a bug that needs investigation
- `/security-audit` - For deeper security analysis
- `/scan-similar-bugs` - After fixing an issue found during review
