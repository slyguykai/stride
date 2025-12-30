# 0001: MVVM + Coordinators

Date: 2025-02-14
Status: Accepted

## Context
Stride needs a clear separation of concerns between UI, state management, and navigation to keep SwiftUI views lightweight and testable.

## Decision
Adopt MVVM for UI state and business logic, and use a coordinator for navigation and routing.

## Consequences
- Views remain declarative and focused on rendering.
- View models coordinate services and expose UI state.
- Navigation logic centralizes in the coordinator.

## Alternatives Considered
- MVU/Redux-style architecture (heavier ceremony for Phase 0).
- SwiftUI navigation without a coordinator (harder to test and evolve).
