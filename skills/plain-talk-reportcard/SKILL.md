---
name: plain-talk-reportcard
description: Codebase analysis with A-F grades and plain-language summaries for non-technical stakeholders
version: 2.0.0
author: Terry Nyberg
license: MIT
allowed-tools: [Task, Glob, Grep, Read, Write, AskUserQuestion]
metadata:
  tier: analysis
  category: analysis
---

# Plain-Talk Report Card Generator

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

**Required output:** Every issue/finding MUST include Urgency, Risk, ROI, and Blast Radius ratings. For non-technical audiences, briefly explain what each rating means in parentheses.

Generate a comprehensive codebase report card with findings explained in plain, non-technical language suitable for project managers, executives, or non-developer stakeholders.

---

## Step 1: Initial Questions

**IMPORTANT**: Before scanning, use `AskUserQuestion` to gather context:

```
AskUserQuestion with questions:
[
  {
    "question": "Should the analysis consider CLAUDE.md project instructions?",
    "header": "CLAUDE.md",
    "options": [
      {"label": "Yes, use CLAUDE.md (Recommended)", "description": "Include project context and team preferences"},
      {"label": "No, ignore CLAUDE.md", "description": "Fresh perspective without project-specific context"}
    ],
    "multiSelect": false
  },
  {
    "question": "How would you like to run this analysis?",
    "header": "Mode",
    "options": [
      {"label": "Fast (parallel)", "description": "Multiple scans at once - faster, more prompts"},
      {"label": "Quiet (sequential)", "description": "One thing at a time - slower, fewer prompts"}
    ],
    "multiSelect": false
  },
  {
    "question": "Does this app have a backend/server component?",
    "header": "Backend",
    "options": [
      {"label": "Yes", "description": "Include server/API analysis"},
      {"label": "No", "description": "App is standalone, no server"}
    ],
    "multiSelect": false
  },
  {
    "question": "What is your timeline?",
    "header": "Timeline",
    "options": [
      {"label": "Pre-release", "description": "Preparing for App Store - urgency matters"},
      {"label": "Post-release", "description": "App is live, ongoing improvement"},
      {"label": "Planning phase", "description": "Gathering info for roadmap"}
    ],
    "multiSelect": false
  },
  {
    "question": "Any areas to emphasize?",
    "header": "Focus",
    "options": [
      {"label": "Standard analysis", "description": "Cover all categories equally"},
      {"label": "Emphasize user experience", "description": "Focus on what users see and feel"},
      {"label": "Emphasize reliability", "description": "Focus on crashes, errors, data safety"},
      {"label": "Emphasize accessibility", "description": "Focus on usability for all users"}
    ],
    "multiSelect": false
  }
]
```

**If user selects "Yes" for CLAUDE.md:** Read CLAUDE.md and summarize in 2-3 non-technical bullets.

---

## Step 2: Check for Previous Reports

Check for existing reports to show progress over time:

```bash
Glob pattern=".agents/research/*-plain-reportcard.md"
```

If previous reports exist, note the most recent one for trend comparison.

---

## Step 3: Automated Scans

Run these scans to gather data. The results will be translated into plain language in the report.

### 3.1 Project Size & Health

```bash
# Count Swift files
Glob pattern="**/*.swift" | count

# Count test files
Glob pattern="**/*Test*.swift" | count

# Check for documentation
Glob pattern="**/README.md"
```

### 3.2 User Experience Indicators

```bash
# Loading states (good UX)
Grep pattern="ProgressView|\.loading|isLoading" glob="**/*.swift" output_mode="count"

# Error handling (user-friendly errors)
Grep pattern="(alert|errorMessage|showError)" glob="**/*.swift" output_mode="count"

# Empty states (when no data)
Grep pattern="(emptyState|EmptyView|noItems)" glob="**/*.swift" output_mode="count"
```

### 3.3 Accessibility Indicators

```bash
# Accessibility labels (screen reader support)
Grep pattern="\.accessibilityLabel" glob="**/*.swift" output_mode="count"

# Dynamic Type (adjustable text size)
Grep pattern="\.font\(\.system\(size:" glob="**/*.swift" output_mode="count"

# High contrast support
Grep pattern="colorScheme|\.accessibilityContrast" glob="**/*.swift" output_mode="count"
```

### 3.4 Reliability Indicators

```bash
# Crash-prone patterns (force unwraps)
Grep pattern="!" glob="**/*.swift" output_mode="count"

# Error handling
Grep pattern="(catch|throws|Result<)" glob="**/*.swift" output_mode="count"

# Data backup/sync
Grep pattern="(CloudKit|iCloud|backup)" glob="**/*.swift" output_mode="count"
```

### 3.5 Security Indicators

```bash
# Secure storage
Grep pattern="(Keychain|SecItem|kSecClass)" glob="**/*.swift" output_mode="count"

# Encryption
Grep pattern="(encrypt|AES|CryptoKit)" glob="**/*.swift" output_mode="count"

# Privacy manifest
Glob pattern="**/PrivacyInfo.xcprivacy"
```

---

## Step 4: Analysis Categories

Translate technical findings into plain language for each category:

### Category Descriptions (for stakeholders)

| Category | What It Means | Why It Matters |
|----------|---------------|----------------|
| **User Experience** | How the app feels to use | Happy users, good reviews |
| **Reliability** | Does the app crash or lose data? | Trust and retention |
| **Accessibility** | Can everyone use it? | Wider audience, legal compliance |
| **Security** | Is user data protected? | Trust, privacy laws |
| **Performance** | Is the app fast and efficient? | User satisfaction, battery life |
| **Code Health** | Is the code maintainable? | Future feature speed, bug fixes |
| **Testing** | Is the app well-tested? | Fewer bugs, confident releases |

---

## Step 5: Output Format

### CLAUDE.md Summary (if included)

*Project context:*
- [Non-technical summary point 1]
- [Non-technical summary point 2]

*If excluded:*
> **Note:** Project-specific context was excluded per request.

### Project Overview

```
**App Size:** Medium (~28,000 lines of code across 142 files)
**Test Coverage:** Partial (47 unit tests, 12 automated UI tests)
**Last Updated:** [date from git]
```

### Grade Summary Line

```
**Overall: B+** (Experience B+ | Reliability A- | Accessibility C+ | Security A | Performance B | Health B+ | Testing C+)
```

### Trend Comparison (if previous report exists)

```
**Progress Since Last Report (Jan 15):**
- User Experience: B → B+ (improved)
- Accessibility: C → C+ (improved)
- Testing: C → C+ (improved)
- Security: A → A (maintained)
```

### Executive Summary

Write 2-3 sentences summarizing the app's health:

> The app is in good shape for release with strong security and reliability. The main areas for improvement are accessibility (making the app usable for everyone) and test coverage (automated checks that catch bugs before users see them). These improvements would take approximately 2-3 weeks of focused effort.

### Grades with Plain-Language Details

```markdown
### User Experience: B+
**What this means:** The app is pleasant to use with room for minor polish.

**What's working well:**
- Clean, intuitive design that users can navigate easily
- App responds quickly to taps and gestures
- Good use of animations that feel natural

**What could be better:**
- **[HIGH]** Some screens don't show loading indicators — users may think the app froze
- **[MED]** Error messages use technical language instead of helpful guidance
- **[LOW]** A few buttons are slightly too small on smaller phones

---

### Reliability: A-
**What this means:** The app is stable and protects user data well.

**What's working well:**
- Data is saved automatically and synced to the cloud
- App recovers gracefully from network problems
- No crash-prone code patterns detected

**What could be better:**
- **[MED]** Some error scenarios show blank screens instead of helpful messages

---

### Accessibility: C+
**What this means:** Basic accessibility is present, but gaps exist that could exclude some users.

**Why this matters:**
- 1 in 4 adults have a disability that may affect app use
- Apple may reject apps with poor accessibility
- Legal requirements (ADA, WCAG) may apply

**What's working well:**
- Text can be resized using system settings
- Most buttons can be activated with VoiceOver

**What needs attention:**
- **[HIGH]** 23 buttons are missing descriptions for screen reader users
- **[HIGH]** 8 images have no text alternatives
- **[MED]** Some text doesn't adjust when users increase text size

---

### Security: A
**What this means:** User data is well-protected.

**What's working well:**
- Passwords and tokens stored in secure vault (Keychain)
- All network connections are encrypted
- No sensitive data accidentally logged
- Privacy manifest present for App Store compliance

---

### Testing: C+
**What this means:** Some automated testing exists, but gaps could let bugs slip through.

**What's working well:**
- 47 automated tests for core logic
- 12 automated tests for user interface flows

**What needs attention:**
- **[MED]** No tests for cloud sync — bugs here could cause data loss
- **[MED]** Some UI tests are unreliable (pass sometimes, fail sometimes)
```

### Issues by Priority

Use plain language and explain impact:

```markdown
### Issues Summary

| Priority | Count | What This Means |
|----------|-------|-----------------|
| **Immediate** | 3 | Should fix before release |
| **Soon** | 5 | Fix within 2-4 weeks |
| **Eventually** | 8 | Nice to have, lower priority |

---

### Immediate (Fix Before Release)

**1. Add loading indicators**
- **Impact:** Users think the app froze when loading data
- **Effort:** ~2 days
- **Risk if ignored:** Bad reviews, user frustration

**2. Add screen reader labels to buttons**
- **Impact:** Blind users cannot use 23 buttons
- **Effort:** ~1 day
- **Risk if ignored:** App Store rejection, accessibility complaints

**3. Fix image descriptions**
- **Impact:** Screen readers say "image" instead of what the image shows
- **Effort:** ~4 hours
- **Risk if ignored:** Poor experience for visually impaired users

---

### Soon (Next 2-4 Weeks)

**4. Improve error messages**
- **Impact:** Users see "Error code 500" instead of "Please try again"
- **Effort:** ~3 days

**5. Add cloud sync tests**
- **Impact:** Sync bugs might not be caught before release
- **Effort:** ~1 week

---

### Eventually (Backlog)

**6. Increase text size support**
- **Impact:** Users with vision impairments may struggle to read

**7. Refactor large code files**
- **Impact:** Future features take longer to build
```

### Recommended Timeline

```markdown
### Recommended Action Plan

**Week 1: Critical Fixes**
- Add loading indicators (2 days)
- Add accessibility labels (1 day)
- Fix image descriptions (4 hours)

**Week 2-3: Quality Improvements**
- Improve error messages (3 days)
- Add cloud sync tests (1 week)

**Month 2: Polish**
- Increase text size support
- Code organization improvements
```

---

## Step 6: Deep Dive Option

After presenting the report, offer focused deep dives:

> **Note:** Some deep dives require [Axiom](https://github.com/CharlesWiltgen/Axiom) to be installed. Security details use the built-in `/security-audit` skill.

```
AskUserQuestion with questions:
[
  {
    "question": "Would you like more detail on any area?",
    "header": "Deep Dive",
    "options": [
      {"label": "Accessibility details", "description": "Requires Axiom - full accessibility gap analysis"},
      {"label": "User experience details", "description": "Requires Axiom - screen-by-screen UX analysis"},
      {"label": "Security details", "description": "Uses built-in /security-audit - no extra install needed"},
      {"label": "No, this is enough", "description": "The overview is sufficient"}
    ],
    "multiSelect": true
  }
]
```

If user selects deep dives:
- **Accessibility:** Invoke `axiom-ios-accessibility` (requires Axiom)
- **User experience:** Invoke `axiom-ios-ui`, `axiom-hig` (requires Axiom)
- **Security:** Invoke `/security-audit` (built-in, always available)

If Axiom is not installed and user selects an Axiom-dependent option:
> Axiom is not installed. Install it with: `claude plugin install CharlesWiltgen/Axiom`

---

## Step 7: Follow-up Question

After deep dives (or if skipped), ask about next steps:

```
AskUserQuestion with questions:
[
  {
    "question": "Would you like me to create an action plan?",
    "header": "Next Steps",
    "options": [
      {"label": "Yes, plan immediate items", "description": "Detailed plan for high-priority fixes"},
      {"label": "Yes, plan everything", "description": "Comprehensive roadmap with timeline"},
      {"label": "No, report is enough", "description": "End here"}
    ],
    "multiSelect": false
  }
]
```

If user selects yes, invoke `/implementation-plan` with the selected items.

---

## Output

Write the report card to `.agents/research/YYYY-MM-DD-plain-reportcard.md` for future reference.

---

## Plain Language Glossary

When these terms appear, translate them:

| Technical Term | Plain Language |
|----------------|----------------|
| Accessibility | Making the app usable by everyone, including people with disabilities |
| API | The way the app talks to servers |
| Crash | The app unexpectedly closes |
| Force unwrap | Code that can cause crashes if data is missing |
| Keychain | Apple's secure storage vault for passwords |
| Retain cycle | A bug that slowly uses up memory |
| SwiftData | Apple's system for saving data on the device |
| UI test | Automated robot that clicks through the app |
| Unit test | Automated check for a small piece of logic |
| VoiceOver | Apple's screen reader for blind users |
| WCAG | International guidelines for accessibility |

---

## See Also

- `/tech-talk-reportcard` - Technical version for developers
- `/implementation-plan` - Create action plans from report findings
- `/release-prep` - Pre-release checklist
