# 0002: SwiftData + Swift Concurrency

Date: 2025-02-14
Status: Accepted

## Context
Stride targets iOS 17+ and needs a modern persistence layer with CloudKit compatibility and a safe async model.

## Decision
Use SwiftData for persistence and Swift Concurrency (async/await, actors) for asynchronous work and shared state.

## Consequences
- Native integration with iOS frameworks and CloudKit.
- Clear concurrency model without manual threading.
- Model annotations and actor isolation will guide architecture.

## Alternatives Considered
- Core Data + manual CloudKit stack (more boilerplate).
- Combine-based async patterns (less direct for structured concurrency).
