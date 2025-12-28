# SwiftData Migration Strategy

Stride uses SwiftData with lightweight migrations as the default approach. The strategy is:

1. **Schema changes are additive by default**
   - Prefer adding optional fields or defaults to avoid breaking changes.

2. **Version changes are documented**
   - Each schema change gets a short note in this file (date, change, rationale).

3. **Migration testing**
   - Before release, load a store from the previous version and validate:
     - Required fields still decode
     - Relationships still resolve
     - No unexpected data loss

4. **Breaking changes**
   - If a breaking change is required, plan a manual migration step and document it here.

## Schema Change Log

- 2025-02-14: Initial schema for Task, Subtask, TaskDependency, DeferEvent, UserPattern.
