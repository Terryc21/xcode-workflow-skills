---
name: safe-refactor
description: Plan refactoring with blast radius analysis, dependency mapping, and rollback strategy
---

# Safe Refactor

Plan refactoring with blast radius analysis, dependency mapping, and rollback strategy.

## Input Required

Describe the refactoring:
- What code are you refactoring?
- Why? (tech debt, performance, readability, pattern change)
- Desired end state

---

## Refactoring Process

### Phase 1: Scope Analysis

1. **Target Code**: Identify exact files/functions/types to refactor
2. **Current State**: Document how it works now
3. **Desired State**: Document how it should work after

### Phase 2: Dependency Mapping

**Upstream Dependencies** (what the target code depends on):
| Dependency | Type | Risk if Changed |
|------------|------|-----------------|
| | | |

**Downstream Dependents** (what depends on the target code):
| Dependent | Type | Impact if Target Changes |
|-----------|------|--------------------------|
| | | |

### Phase 3: Blast Radius

| Risk Level | Files | Description |
|------------|-------|-------------|
| Direct | | Files being modified |
| Immediate | | Files that import/call modified code |
| Transitive | | Files affected through indirect dependencies |

**Total Blast Radius:** X files

### Phase 4: Safety Checks

Before refactoring:
- [ ] All existing tests pass
- [ ] Code is committed (clean git state)
- [ ] I understand all usages of the code being changed

### Phase 5: Refactoring Strategy

**Approach:** (choose one)
- [ ] **Parallel Implementation**: Build new alongside old, switch over, delete old
- [ ] **Incremental Migration**: Change piece by piece with each commit working
- [ ] **Big Bang**: Change everything at once (only for isolated code)

### Phase 6: Step-by-Step Plan

Each step should leave the codebase in a working state:

1. [ ] Step 1: [description] — Commit message: "..."
2. [ ] Step 2: [description] — Commit message: "..."
3. [ ] Step 3: [description] — Commit message: "..."

### Phase 7: Verification Plan

After each step:
- [ ] Build succeeds
- [ ] Tests pass
- [ ] Manual smoke test: [specific action to verify]

### Phase 8: Rollback Strategy

**If something goes wrong:**
- Option A: `git revert <commit-hash>` (if committed in small steps)
- Option B: `git reset --hard <last-good-commit>` (if not pushed)

---

## Refactoring Principles

1. **Never refactor and change behavior in the same commit**
2. **Each commit should compile and pass tests**
3. **Rename before restructure** — rename/move first, then modify
4. **Add tests before refactoring** — if coverage is low, add tests first
5. **Small steps** — many small commits > one big commit
