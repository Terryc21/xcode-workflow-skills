---
name: plain-talk-reportcard
description: Codebase analysis with A-F grades and plain-language summaries for non-technical stakeholders
version: 1.0.0
author: Terry Nyberg
license: MIT
allowed-tools: [Task, Glob, Grep, Read, AskUserQuestion]
metadata:
  tier: analysis
  category: analysis
---

# Plain-Talk Report Card Generator

**Required output:** Every issue/finding MUST include Urgency, Risk, ROI, and Blast Radius ratings. Do not omit these ratings. For non-technical audiences, briefly explain what each rating means.

Generate a comprehensive codebase report card with findings explained in plain, non-technical language.

## Step 1: Interactive Questions

**IMPORTANT**: Before scanning, use the `AskUserQuestion` tool to ask these questions interactively:

```
AskUserQuestion with questions:
[
  {
    "question": "How would you like to run this analysis?",
    "header": "Mode",
    "options": [
      {"label": "Fast (parallel)", "description": "5 agents run simultaneously - faster, but will prompt for permissions"},
      {"label": "Quiet (sequential)", "description": "Single agent, fewer prompts - takes longer"}
    ],
    "multiSelect": false
  },
  {
    "question": "Are you using a Cloudflare backend for this project?",
    "header": "Backend",
    "options": [
      {"label": "Yes", "description": "Include Cloudflare Worker endpoints, rate limiting, and validation in analysis"},
      {"label": "No", "description": "Skip backend analysis, focus on the app only"}
    ],
    "multiSelect": false
  },
  {
    "question": "Is there anything you want excluded from the report?",
    "header": "Exclusions",
    "options": [
      {"label": "Grade everything", "description": "Full analysis with no exclusions"},
      {"label": "Skip file size/LOC counts", "description": "Don't grade based on lines of code"},
      {"label": "Skip test coverage", "description": "Don't analyze test files"},
      {"label": "Skip backend/Worker.js", "description": "Focus only on Swift code"}
    ],
    "multiSelect": true
  },
  {
    "question": "What is your timeline?",
    "header": "Timeline",
    "options": [
      {"label": "Pre-release audit", "description": "Preparing for App Store - urgency matters"},
      {"label": "Post-release maintenance", "description": "App is live, ongoing improvement"},
      {"label": "Planning phase", "description": "Gathering info for roadmap"}
    ],
    "multiSelect": false
  },
  {
    "question": "Where is the project located?",
    "header": "Location",
    "options": [
      {"label": "Current directory", "description": "Use the current working directory"},
      {"label": "Specify path", "description": "I'll provide the path in 'Other'"}
    ],
    "multiSelect": false
  },
  {
    "question": "Is there anything specific you want included in the report?",
    "header": "Custom Focus",
    "options": [
      {"label": "Standard analysis", "description": "Cover all default categories"},
      {"label": "Yes, I have specific areas", "description": "I'll describe what I want in 'Other'"}
    ],
    "multiSelect": false
  }
]
```

If user selects "Yes, I have specific areas", incorporate their custom request into the analysis.

Wait for user responses before proceeding.

## Step 2: Analysis Mode

Based on the user's "Mode" selection:

**Fast (parallel):** Launch 5 Task agents simultaneously with `subagent_type: Explore`:
- Architecture & Code Organization
- UI/UX Implementation
- Security
- Data Architecture
- Backend (if applicable)

**Quiet (sequential):** Use direct `Read`, `Glob`, `Grep` tools in sequence:
1. Read CLAUDE.md and key config files
2. Glob for file counts (`**/*.swift`)
3. Grep for patterns (security, architecture markers)
4. Read sample files from each category
5. Compile findings without subagents

## Step 3: Analysis Areas

Scan the codebase for:

1. **Architecture & Code Organization** - Project structure, separation of concerns, design patterns
2. **UI/UX Implementation** - SwiftUI views, components, navigation, accessibility
3. **Platform-Specific UI** - iPad/iPhone/Mac adaptation, widgets, system integration
4. **Security** - Authentication, data storage, network security, API keys, privacy
5. **Data Architecture** - SwiftData models, relationships, persistence
6. **User Workflows** - Item creation, search, sync, bulk operations
7. **Backend** (if applicable) - Cloudflare Worker endpoints, rate limiting, validation

## Step 4: Output Format

### Grade Summary Line

Start with an inline summary for quick scanning:

```
**Overall: B+** (Architecture A- | UI/UX B+ | Security A | Data B | Workflows B+ | Backend A-)
```

### Executive Summary

[2-3 sentence plain-language summary of the app's health and readiness]

### Grades with Details

Present each category as a heading with grade, then bullet details:

```
### Architecture: A-
Your code is well-organized and follows modern patterns.
- Uses clear separation between views, data, and logic
- Files are reasonably sized and easy to navigate
- Some older patterns could be modernized

### UI/UX: B+
The app looks polished and is easy to use.
- Clean design that works on iPhone and iPad
- Good accessibility support for most users
- A few screens could use better loading indicators

### Security: A
Your users' data is well-protected.
- Sensitive data stored securely
- Network connections are encrypted
- No API keys exposed in code
```

### Issues by Priority

Use severity tags and section headers:

```
### Immediate **[HIGH]**
**Missing loading states** — Users may think the app froze when data is loading
**Accessibility labels** — Screen reader users can't navigate some buttons

### Soon **[MED]**
**Error messages** — Some errors show technical jargon instead of helpful guidance

### Eventually **[LOW]**
**Code organization** — Some files are getting large and could be split up
```

### Action Items

```
### Immediate
**Add loading indicators** — Users need feedback when the app is working
**Fix accessibility labels** — Makes the app usable for everyone

### Short-term
**Improve error messages** — Help users understand and recover from problems

### Medium-term
**Refactor large files** — Makes future updates easier and safer
```

## Step 5: Follow-up Question

After presenting the report, use `AskUserQuestion` to ask:

```
AskUserQuestion with questions:
[
  {
    "question": "Would you like me to create an implementation plan for any of these recommendations?",
    "header": "Next Steps",
    "options": [
      {"label": "Yes, plan immediate items", "description": "Create detailed plan for high-priority actions"},
      {"label": "Yes, plan all items", "description": "Create comprehensive implementation roadmap"},
      {"label": "No, report is sufficient", "description": "End here, I have what I need"}
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

## See Also

- `/tech-talk-reportcard` - Technical version for developers
- `/implementation-plan` - Create action plans from report findings
