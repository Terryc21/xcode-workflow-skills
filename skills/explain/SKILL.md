---
name: explain
description: Deep-dive explanation of how a specific file, feature, or data flow works
version: 1.0.0
author: Terry Nyberg
license: MIT
allowed-tools: [Read, Grep, Glob, LSP]
metadata:
  tier: reference
  category: analysis
---

# Explain

> **Quick Ref:** Deep-dive explanation with code walkthrough. Output: `.agents/research/YYYY-MM-DD-explain-{topic}.md`

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

Deep-dive explanation of how a specific file, feature, or data flow works.

---

## Input Required

What do you want explained?
- A specific file path
- A feature name (e.g., "Stuff Scout", "warranty tracking")
- A data flow (e.g., "how does an item get saved")
- A concept (e.g., "the binding bridge pattern")

---

## Explanation Format

### 1. Overview

**What it is:** [One paragraph summary]

**Why it exists:** [Problem it solves]

**Where it lives:** [File paths / module]

### 2. Key Components

| Component | Purpose | Location |
|-----------|---------|----------|
| | | |

### 3. How It Works

Step-by-step flow with code walkthrough.

### 4. Data Flow

Visual representation of data movement between components.

### 5. Dependencies

**Depends on:** [list]

**Depended on by:** [list]

### 6. Edge Cases & Gotchas

| Scenario | Behavior | Notes |
|----------|----------|-------|
| | | |

### 7. Related Code

- Similar implementations
- Related functionality

### 8. Quick Reference

**To modify:** [key steps]

**To debug:** [where to look]

---

## Output

Write the explanation to `.agents/research/YYYY-MM-DD-explain-{topic}.md` for future reference.

---

## See Also

- `/implementation-plan` - When you understand the code and want to plan changes
- `/debug` - When explanation reveals a potential bug
- `/safe-refactor` - When explanation shows refactoring opportunities
