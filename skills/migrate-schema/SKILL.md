---
name: migrate-schema
description: Safe SwiftData/model migration planning with data preservation and rollback strategy
---

# Migrate Schema

Safe SwiftData/model migration planning with data preservation and rollback strategy.

## Important

**For Swift 6.2 / Swift Concurrency migrations:** Invoke `/axiom` first to access the latest Swift concurrency patterns, Sendable requirements, and actor isolation guidance.

## Input Required

Describe the schema change:
- What model(s) are changing?
- What's being added/removed/modified?
- Is this additive or destructive?

---

## Migration Analysis

### Step 1: Change Classification

**Type of change:**
- [ ] **Additive** (new property with default value) — Usually safe
- [ ] **Rename** (property/model renamed) — Requires mapping
- [ ] **Type change** (String → Int, etc.) — Requires transformation
- [ ] **Relationship change** — Requires careful handling
- [ ] **Destructive** (removing property/model) — Data loss risk
- [ ] **Swift 6 Concurrency** — Invoke `/axiom` for guidance

### Step 2: Current vs Target Schema

Document current and desired model states.

### Step 3: Data Impact Analysis

| Property | Current | Target | Migration Action | Data Risk |
|----------|---------|--------|------------------|-----------|
| | | | Keep/Transform/Delete | None/Low/High |

### Step 4: Migration Strategy

For SwiftData VersionedSchema, implement:
- Schema versions
- Migration stages
- Custom migration logic if needed

### Step 5: Testing Plan

- [ ] Fresh install (no migration)
- [ ] Upgrade with empty database
- [ ] Upgrade with populated database
- [ ] Upgrade with edge case data

### Step 6: Rollback Strategy

- Option A: Restore from backup
- Option B: Reverse migration
- Option C: Fresh start (last resort)

### Step 7: Deployment Plan

1. [ ] Implement migration
2. [ ] Test on simulator
3. [ ] Test on device (backup first!)
4. [ ] TestFlight build
5. [ ] Monitor crash reports
6. [ ] Release
