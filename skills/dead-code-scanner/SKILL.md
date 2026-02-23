---
name: dead-code-scanner
description: 'Find unused code after refactors or as ongoing hygiene. Two modes: quick (post-refactor, recent changes) and full (entire codebase). Triggers: "find dead code", "find unused code", "cleanup unused", "dead code scan", "code hygiene".'
version: 1.0.0
author: Terry Nyberg
license: MIT
allowed-tools: [Grep, Glob, Read, Bash, Edit, AskUserQuestion]
metadata:
  tier: execution
  category: analysis
---

# Dead Code Scanner Skill

> **Quick Ref:** Find orphaned code after refactors or for ongoing hygiene. Output: `.agents/research/YYYY-MM-DD-dead-code-*.md`

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

## Quick Commands

| Command | Description |
|---------|-------------|
| `/dead-code` | Interactive mode selection |
| `/dead-code quick` | Scan recent changes (HEAD~5) |
| `/dead-code full` | Scan entire codebase |
| `/dead-code remove` | Remove with build verification |
| `/dead-code remove --verify-with-tests` | Remove with build + targeted tests (safest) |
| `/dead-code ignore <symbol>` | Add symbol to allowlist |

---

## Safety Philosophy

```
RULE 1: NEVER auto-delete code. Report only.
RULE 2: Require explicit user approval for any removal.
RULE 3: Verify with build + tests before committing removals.
RULE 4: Support allowlists and annotations for known exceptions.
RULE 5: Track false positives to improve over time.
```

---

## Step 1: Determine Scan Mode

Use AskUserQuestion to determine how to scan:

```
How would you like to scan for unused code?

1. **Quick (Post-Refactor)** - Scan recently changed files only
   Fast, targeted, best after completing a refactor

2. **Full (Hygiene)** - Scan entire codebase
   Comprehensive, takes longer, best for periodic cleanup

3. **Custom** - Specify files or directories
   Target specific areas of the codebase
```

Options:
- **Quick scan (recent changes)** - Analyze files changed in last N commits
- **Full scan (entire codebase)** - Comprehensive analysis
- **Custom scope** - User specifies paths

If Quick mode selected, ask for commit range:
```
How far back should I look?

1. Last commit only (HEAD~1)
2. Last 5 commits (HEAD~5) [Recommended]
3. Last 10 commits (HEAD~10)
4. Since specific commit (I'll provide hash)
```

---

## Step 2: Check for Configuration Files

### 2.1: Load Allowlist

Check for `.dead-code-ignore` in project root:

```yaml
# .dead-code-ignore format:
symbols:
  - name: "legacyBridgeMethod"
    reason: "Called via ObjC runtime"

  - pattern: "Widget*"
    reason: "Widget entry points - system invoked"

files:
  - path: "Sources/Intents/*.swift"
    reason: "App Intents - invoked by system"

  - path: "Sources/PublicAPI/*"
    reason: "Public framework interface"

patterns:
  - regex: "@objc.*func"
    reason: "Objective-C exposed methods"
```

If file doesn't exist, note this and continue. Step 12 will offer to generate it.

### 2.2: Load False Positive History

Check for `.dead-code-history.yaml`:

```yaml
# Auto-maintained by skill
false_positives:
  - symbol: "configureAppearance"
    file: "AppDelegate.swift"
    flagged_date: "2026-02-20"
    reason: "Called via UIAppearance proxy"
```

If file doesn't exist, Step 12 will create it automatically.

Exclude any symbols listed here from report.

---

## Step 3: Extract Symbols to Analyze

### 3.1: Determine File Scope

**Quick Mode:**
```bash
# Get recently modified Swift files
git diff --name-only HEAD~N | grep "\.swift$"
```

**Full Mode:**
```bash
# All Swift files except tests and generated
find Sources -name "*.swift" -not -path "*/Tests/*" -not -name "*.generated.swift"
```

### 3.2: Extract Declarations

For each file in scope, use Grep to find declarations:

```swift
// Functions
private func methodName(
fileprivate func methodName(
internal func methodName(
func methodName(  // internal by default

// Types
private class ClassName
private struct StructName
private enum EnumName
private protocol ProtocolName

// Properties
private var propertyName
private let constantName
fileprivate var propertyName

// Type aliases
private typealias AliasName
```

**Grep patterns:**
```
Pattern: (private|fileprivate)\s+(func|class|struct|enum|protocol|var|let|typealias)\s+(\w+)
```

### 3.3: Build Symbol Table

Create in-memory table:

| Symbol | Type | Access | File | Line | Status |
|--------|------|--------|------|------|--------|
| formatDate | func | private | ItemHelper.swift | 45 | pending |
| oldEndpoint | let | private | Constants.swift | 12 | pending |

---

## Step 4: Scan for References

For each symbol in the table:

### 4.1: Search for Usage

```
Grep pattern="\\b{symbolName}\\b" path="Sources" glob="*.swift"
```

### 4.2: Filter Results

Exclude from reference count:
- The declaration line itself
- Comments (`//` or `/* */` context)
- String literals (`"..."` context)
- Symbol appearing in `.dead-code-ignore`
- Symbol with `// dead-code:ignore` annotation

### 4.3: Classify Symbol

| Refs Found | Access Level | Classification | Confidence |
|------------|--------------|----------------|------------|
| 0 | private | UNUSED | HIGH |
| 0 | fileprivate | UNUSED | HIGH |
| 0 | internal | UNUSED | MEDIUM |
| 0 | public | POSSIBLY_API | LOW |
| 1 (only in tests) | private | TEST_ONLY | MEDIUM |
| 1 (self-reference) | any | UNUSED | HIGH |

---

## Step 5: Apply Swift-Specific Exclusions

### 5.1: Auto-Exclude Patterns

Do NOT flag these as unused (even with 0 refs):

```swift
// Entry points
@main                      // App entry
@UIApplicationMain         // Legacy app entry
#Preview                   // SwiftUI previews

// Interface Builder
@IBAction                  // Storyboard actions
@IBOutlet                  // Storyboard connections
@IBDesignable              // Interface Builder rendering
@IBInspectable             // Interface Builder properties

// Objective-C interop
@objc                      // ObjC runtime visibility
@objcMembers               // Entire class exposed
dynamic                    // ObjC dynamic dispatch

// System callbacks
func application(          // UIApplicationDelegate
func scene(                // UISceneDelegate
func userNotificationCenter( // UNUserNotificationCenterDelegate

// Codable
CodingKeys                 // Codable synthesis
init(from decoder:         // Decodable
encode(to encoder:         // Encodable

// SwiftUI
var body: some View        // View protocol requirement
func makeBody(             // ViewModifier/Shape requirements

// Combine
var cancellables           // Often stored but not "called"

// Intentionally kept
@available(*, deprecated   // Deprecated but kept for compatibility
```

### 5.2: Check for String-Based Invocation

Scan for symbol name in strings (reflection/selectors):

```swift
// These patterns indicate dynamic usage:
NSSelectorFromString("symbolName")
#selector(symbolName)
perform(Selector("symbolName"))
NSStringFromClass(ClassName.self)
```

If found, mark as DYNAMIC_USAGE and exclude.

### 5.3: Check Protocol Conformance

If symbol is a method, check if it satisfies a protocol requirement:

```swift
// If class conforms to protocol that requires this method,
// it's not "unused" even if never called directly
protocol Delegate {
    func didUpdate()  // Required
}

class Handler: Delegate {
    func didUpdate() { }  // "Unused" but required
}
```

---

## Step 6: Check Inline Annotations

Scan for annotation comments near declarations:

```swift
// dead-code:ignore - Called via reflection
private func dynamicHandler() { }

// dead-code:ignore:until:2026-06-01 - Migration period
func migrateV2ToV3() { }

// dead-code:ignore:reason:Widget entry point
class WarrantyWidget { }
```

Parse annotations and exclude matching symbols.

---

## Step 7: Correlate with Git History (Quick Mode)

For unused symbols, find when they became orphaned:

```bash
# Find the commit that removed the last reference
git log -p -S "symbolName" --all -- "*.swift" | head -50
```

Extract:
- Last commit that referenced this symbol
- Commit message (helps understand why it's now unused)
- Date of last reference removal

---

## Step 8: Generate Report

Create report at `.agents/research/YYYY-MM-DD-dead-code-{mode}.md`:

```markdown
# Dead Code Scan Report

**Date:** YYYY-MM-DD HH:MM
**Mode:** Quick (HEAD~5) | Full
**Scanned:** X files
**Symbols Analyzed:** Y
**Configuration:** .dead-code-ignore loaded | not found

## Summary

| Confidence | Count | Action |
|------------|-------|--------|
| HIGH | X | Safe to remove |
| MEDIUM | Y | Verify before removing |
| LOW | Z | Likely needed (API/public) |

## HIGH Confidence (Safe to Remove)

These symbols have no references and are private/fileprivate scope.

### 1. `formatLegacyDate()` — private func
**File:** Sources/Helpers/ItemHelper.swift:45
**Last referenced:** commit abc123 (2026-02-01) "Refactor date handling"

```swift
// Current code (can be removed):
private func formatLegacyDate(_ date: Date) -> String {
    // ... 15 lines
}
```

**Action:** [ ] Remove (no dependencies)

---

### 2. `oldAPIEndpoint` — private let
**File:** Sources/Config/Constants.swift:12
**Last referenced:** commit def456 (2026-01-28) "Migrate to API v2"

```swift
private let oldAPIEndpoint = "https://api.v1.example.com"
```

**Action:** [ ] Remove (API v1 no longer used)

---

## MEDIUM Confidence (Verify First)

These need human review before removal.

### 1. `processLegacyData()` — internal func
**File:** Sources/Managers/DataManager.swift:89
**References:** 1 (in test file only)
**Note:** Only called from `DataManagerTests.swift:45`

**Question:** Is this test still needed? If not, remove both.

---

## LOW Confidence (Likely Needed)

These appear unused but are probably intentional.

### 1. `PublicAPIMethod()` — public func
**File:** Sources/PublicAPI/Framework.swift:23
**Note:** Public API - may be used by external consumers

**Recommendation:** Add to `.dead-code-ignore` if intentional:
```yaml
symbols:
  - name: "PublicAPIMethod"
    reason: "Public framework API"
```

---

## Excluded (Known Safe)

These were not flagged due to allowlist or annotations:

| Symbol | Reason |
|--------|--------|
| `handleIntent()` | `.dead-code-ignore`: App Intents |
| `legacyBridge()` | Annotation: `// dead-code:ignore` |

---

## Recommended Actions

1. **Remove HIGH confidence items** (X symbols, ~Y lines)
2. **Review MEDIUM confidence items** (X symbols)
3. **Add to allowlist** (X false positives identified)

### Quick Commands

To remove HIGH confidence items one-by-one with verification:
```
/dead-code remove --interactive
```

To add false positives to allowlist:
```
/dead-code ignore <symbol-name> --reason "explanation"
```
```

---

## Step 9: Present Interactive Summary

Show summary to user:

```
## Dead Code Scan Complete

**Mode:** Quick (last 5 commits)
**Files Scanned:** 23
**Symbols Analyzed:** 156

### Results

| Confidence | Count |
|------------|-------|
| HIGH (safe to remove) | 4 |
| MEDIUM (verify first) | 2 |
| LOW (likely needed) | 1 |

**Full report:** .agents/research/2026-02-22-dead-code-quick.md

What would you like to do?
```

Use AskUserQuestion:
- **Review HIGH confidence items** — Go through safe-to-remove items
- **See full report** — Display detailed markdown report
- **Remove with build check** — Interactive removal with compilation verification
- **Remove with test verification** — Interactive removal with build AND targeted tests (safest)
- **Done for now** — Exit, user will handle manually

---

## Step 10: Interactive Removal (If Requested)

### 10.1: Safety Checks

Before any removal:

```bash
# Ensure clean git state
git status --porcelain
# If not clean, warn user and require commit/stash first
```

### 10.2: Create Safety Branch

```bash
git checkout -b dead-code-cleanup-YYYY-MM-DD
```

### 10.3: Interactive Review

For each HIGH confidence item:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Symbol: formatLegacyDate()
File:   Sources/Helpers/ItemHelper.swift:45
Type:   private func (15 lines)
Last referenced: commit abc123 "Refactor date handling"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Code preview - 15 lines]

Actions:
  [R] Remove this symbol
  [S] Skip for now
  [I] Add to .dead-code-ignore (false positive)
  [V] View more context (±50 lines)
  [Q] Quit interactive mode

Choice: _
```

### 10.4: Verify After Each Removal

After removing a symbol, verification depends on the mode selected:

#### Mode A: Build Check Only (faster)

```bash
# 1. Build check
xcodebuild -scheme AppName -destination 'platform=iOS Simulator,name=iPhone 15' build

# 2. If build fails:
#    - Auto-revert the change
#    - Add to .dead-code-history.yaml as false positive
#    - Show error to user
#    - Continue to next symbol

# 3. If build succeeds:
#    - Commit the removal
```

#### Mode B: Test Verification (safest, recommended)

```bash
# 1. Build check (same as above)
xcodebuild build

# 2. If build succeeds, proceed to test discovery...
```

### 10.5: Test Discovery (--verify-with-tests mode)

When test verification is enabled, find tests related to the removed symbol:

#### 10.5.1: Direct File Match

```bash
# If symbol was in Sources/Helpers/ItemHelper.swift
# Look for: Tests/**/ItemHelperTests.swift
#           Tests/**/ItemHelper*Tests.swift

find Tests -name "*$(basename -s .swift $MODIFIED_FILE)*Tests.swift"
```

#### 10.5.2: Import Match

```bash
# Find test files that import types from the modified file
# Extract types defined in modified file:
grep -E "^(class|struct|enum|protocol)\s+\w+" $MODIFIED_FILE | awk '{print $2}'

# Then find test files importing those types:
grep -l "import.*TypeName" Tests/**/*.swift
```

#### 10.5.3: Symbol Reference Match

```bash
# Find test files that reference the removed symbol name
grep -l "\b${SYMBOL_NAME}\b" Tests/**/*.swift
```

#### 10.5.4: Module/Feature Match

```bash
# If symbol was in Sources/Features/Scanner/ScannerHelper.swift
# Run all tests in: Tests/Features/Scanner/
# Or matching: Tests/**/Scanner*Tests.swift
```

### 10.6: Run Targeted Tests

Execute only the discovered related tests (not full suite):

```bash
# Example: Run specific test files
xcodebuild test \
  -scheme AppName \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:AppTests/ItemHelperTests \
  -only-testing:AppTests/DateFormattingTests
```

Display progress:

```
Verifying removal of: formatLegacyDate()

Step 1: Build check...
        ✓ Build succeeded

Step 2: Discovering related tests...
        Found: ItemHelperTests.swift (12 tests)
        Found: DateFormattingTests.swift (3 tests)
        Total: 15 tests to run

Step 3: Running targeted tests...
        [████████████████████] 15/15

        ✓ All 15 tests passed

Removal verified safe. Proceeding...
```

### 10.7: Handle Test Failures

If any tests fail during verification:

```
Verifying removal of: processItems()

Step 1: Build check...
        ✓ Build succeeded

Step 2: Discovering related tests...
        Found: DataManagerTests.swift (8 tests)

Step 3: Running targeted tests...
        [████████░░░░░░░░░░░░] 6/8

        ✗ 2 tests FAILED

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  FALSE POSITIVE DETECTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Failed tests:
  • DataManagerTests.testBatchProcessing
  • DataManagerTests.testAsyncDataFlow

The removed symbol is still needed by these tests.

Actions:
  [R] Revert and continue (recommended)
  [F] Force removal anyway (tests may need updating)
  [V] View test failure details
  [Q] Quit and revert all changes

Choice: _
```

#### On Revert:

```bash
# Restore the removed code
git checkout -- $MODIFIED_FILE

# Record as false positive
echo "- symbol: $SYMBOL_NAME
  file: $FILE_PATH
  flagged_date: $(date +%Y-%m-%d)
  reason: 'Tests depend on this symbol'
  failed_tests:
    - DataManagerTests.testBatchProcessing
    - DataManagerTests.testAsyncDataFlow
  scan_mode: $MODE" >> .dead-code-history.yaml
```

#### Display After Revert:

```
✓ Reverted removal of processItems()
✓ Added to .dead-code-history.yaml as false positive
✓ Future scans will skip this symbol

Continuing to next item...
```

### 10.8: Test Verification Summary

At the end of the session, show verification summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Dead Code Removal Summary (with test verification)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Symbols processed:     7
Successfully removed:  5  (build + tests passed)
False positives:       2  (tests failed, auto-reverted)
Skipped by user:       0

Tests executed:        47 (targeted, not full suite)
Test time:             23 seconds

Removed symbols:
  ✓ formatLegacyDate()    ItemHelper.swift
  ✓ oldAPIEndpoint        Constants.swift
  ✓ legacyParser()        Parser.swift
  ✓ unusedCallback        Delegate.swift
  ✓ tempDebugFlag         Config.swift

False positives (reverted):
  ✗ processItems()        DataManager.swift
    Reason: Tests failed (testBatchProcessing, testAsyncDataFlow)

  ✗ helperMethod()        Utilities.swift
    Reason: Tests failed (testHelperIntegration)

Branch: dead-code-cleanup-2026-02-22
Commits: 5 (one per successful removal)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 10.9: Commit Successful Removals

After verification passes (build-only or build+tests):

```bash
git add <modified-file>
git commit -m "Remove unused: symbolName

Dead code cleanup via /dead-code-scanner
- Symbol: symbolName
- File: path/to/file.swift
- Last referenced: commit abc123
- Confidence: HIGH
- Verification: build + tests (15 tests passed)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Step 11: Handle False Positives

When user marks something as "false positive" (Option I):

### 11.1: Add to Allowlist

Ask for reason:
```
Why should this be ignored in future scans?
```

Append to `.dead-code-ignore`:

```yaml
symbols:
  - name: "symbolName"
    reason: "User provided reason"
    added: "2026-02-22"
```

### 11.2: Update History

Append to `.dead-code-history.yaml`:

```yaml
false_positives:
  - symbol: "symbolName"
    file: "path/to/file.swift"
    flagged_date: "2026-02-22"
    reason: "User provided reason"
    scan_mode: "quick"
```

---

## Step 12: Create Missing Config Files

### 12.1: Create .dead-code-ignore (If Missing)

If `.dead-code-ignore` doesn't exist, offer to create:

```
Would you like me to create a .dead-code-ignore file with common Swift exclusions?

This will automatically exclude:
- App Intents and Widgets
- @objc exposed methods
- SwiftUI previews
- Codable implementations
```

If user agrees, write this content to `.dead-code-ignore` in project root:

```yaml
# .dead-code-ignore
# Configuration file for dead-code-scanner skill
# Place this file in your project root
#
# Symbols and patterns listed here will be excluded from dead code reports.
# Use this for known false positives and intentionally "unused" code.

# =============================================================================
# FILE EXCLUSIONS
# Entire files or directories to skip
# =============================================================================
files:
  # App Intents - invoked by Siri/Shortcuts, not direct code calls
  - path: "Sources/**/Intents/*.swift"
    reason: "App Intents - invoked by Siri/Shortcuts"

  # Widgets - system invokes these entry points
  - path: "Sources/**/Widgets/*.swift"
    reason: "Widget extensions - invoked by system"

  # Intent handlers
  - path: "**/*Intent.swift"
    reason: "Intent handlers - system invoked"

  # Live Activities
  - path: "**/*LiveActivity*.swift"
    reason: "Live Activity extensions"

  # Uncomment if building a framework with public API:
  # - path: "Sources/PublicAPI/*"
  #   reason: "Public framework interface - used by consumers"

# =============================================================================
# SYMBOL EXCLUSIONS
# Specific named symbols to ignore
# =============================================================================
symbols: []
  # Example:
  # - name: "legacyMigrationHelper"
  #   reason: "Called via reflection during migration"
  #
  # - name: "DebugMenuViewController"
  #   reason: "Only instantiated in debug builds via string"

# =============================================================================
# PATTERN EXCLUSIONS
# Regex patterns matching code that should be ignored
# =============================================================================
patterns:
  # Objective-C exposed methods (runtime access)
  - regex: "@objc\\s+(dynamic\\s+)?func"
    reason: "Objective-C exposed for runtime access"

  # Interface Builder connections
  - regex: "@IBAction\\s+func"
    reason: "Interface Builder actions"
  - regex: "@IBOutlet"
    reason: "Interface Builder outlets"

  # SwiftUI previews
  - regex: "#Preview\\s*\\{"
    reason: "SwiftUI preview blocks - needed for Xcode"

  # Codable implementations
  - regex: "enum\\s+CodingKeys"
    reason: "Codable synthesis"

  # Combine cancellables (stored but not "called")
  - regex: "var\\s+cancellables.*Set<AnyCancellable>"
    reason: "Combine subscription storage"

# =============================================================================
# NOTES
# =============================================================================
#
# You can also use inline annotations in code:
#
#   // dead-code:ignore - Called via reflection
#   private func dynamicHandler() { }
#
#   // dead-code:ignore:until:2026-06-01 - Migration period
#   func migrateV2ToV3() { }
#
# These will be automatically detected and excluded from reports.
```

### 12.2: Create .dead-code-history.yaml (If Missing)

If `.dead-code-history.yaml` doesn't exist, create it automatically (no user prompt needed):

```yaml
# .dead-code-history.yaml
# Auto-maintained by dead-code-scanner skill
# Tracks false positives to improve future scans
#
# DO NOT manually edit unless correcting an error.
# The skill updates this file when you mark items as false positives.

false_positives: []
  # Example entry (auto-generated):
  # - symbol: "configureAppearance"
  #   file: "Sources/App/AppDelegate.swift"
  #   line: 45
  #   flagged_date: "2026-02-22"
  #   reason: "Called via UIAppearance proxy - runtime invocation"
  #   scan_mode: "quick"
  #   added_to_ignore: true

# Statistics (auto-updated)
stats:
  total_scans: 0
  total_symbols_removed: 0
  total_false_positives: 0
  last_scan: null
```

### 12.3: Distribution Note

This skill is self-contained. Users only need the SKILL.md file:
- Config files are generated directly in the user's project
- No template folder required
- All YAML content is embedded in this skill definition

---

## Appendix A: Grep Patterns Reference

### Find Private Functions
```
(private|fileprivate)\s+func\s+(\w+)\s*\(
```

### Find Private Types
```
(private|fileprivate)\s+(class|struct|enum|protocol)\s+(\w+)
```

### Find Private Properties
```
(private|fileprivate)\s+(var|let)\s+(\w+)
```

### Find Unused Imports
```
^import\s+(\w+)
# Then check if any type from that module is used
```

### Find TODO: Remove Comments
```
//\s*(TODO|FIXME):\s*(remove|delete|cleanup)
```

---

## Appendix B: Confidence Scoring

| Factor | Points |
|--------|--------|
| private access | +3 |
| fileprivate access | +2 |
| internal access | +1 |
| public access | -2 |
| 0 references | +3 |
| 1 reference (self only) | +2 |
| 1 reference (test only) | +1 |
| Has @objc | -3 |
| Has @IBAction/@IBOutlet | -3 |
| In Intents/Widgets folder | -3 |
| In allowlist | -10 (exclude) |
| Has ignore annotation | -10 (exclude) |
| Recent git removal of refs | +1 |

**Thresholds:**
- HIGH: Score >= 5
- MEDIUM: Score 2-4
- LOW: Score < 2

---

## Appendix C: Limitations

This skill may miss:
1. **Reflection-based calls** not in string form
2. **Protocol extensions** with complex generic constraints
3. **Cross-module usage** in multi-target projects
4. **Runtime-generated selectors**
5. **Storyboard/XIB references** (use separate scan)

When in doubt, mark as MEDIUM confidence for human review.
