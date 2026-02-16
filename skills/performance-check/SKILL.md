---
name: performance-check
description: Profile-guided performance analysis for memory, CPU, energy, and launch time
---

# Performance Check

Profile-guided performance analysis for memory, CPU, energy, and launch time.

## Analysis Areas

### 1. Launch Time
- [ ] Minimal work in App init
- [ ] No synchronous network calls at launch
- [ ] Lazy initialization of non-essential services

### 2. Main Thread Usage
- [ ] Network calls are async
- [ ] Image processing off main thread
- [ ] Database operations off main thread

### 3. Memory Usage
- [ ] No retain cycles in closures (weak self)
- [ ] Large images downsampled for display
- [ ] Caches have size limits
- [ ] Observers removed on deinit

### 4. SwiftUI Performance
- [ ] @State used for view-local state only
- [ ] Large lists use LazyVStack/LazyHStack
- [ ] Expensive computations cached outside body

### 5. Database / SwiftData
- [ ] Batch fetches instead of loops
- [ ] Large datasets paginated
- [ ] No N+1 query patterns

### 6. Energy Usage
- [ ] Location updates have appropriate accuracy
- [ ] Timers invalidated when not needed
- [ ] Animations don't run when off-screen

## Output Format

### Performance Grade: [A-F]

| Area | Grade | Issues |
|------|-------|--------|
| Launch | | |
| Main Thread | | |
| Memory | | |
| SwiftUI | | |
| Database | | |

### Critical Issues:
1.

### Optimization Opportunities:
1.
