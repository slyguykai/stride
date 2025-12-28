# 0003: Minimal Dependencies Policy

Date: 2025-02-14
Status: Accepted

## Context
Stride should keep its dependency surface small for performance, maintenance, and privacy.

## Decision
Prefer Apple frameworks. Third-party dependencies require justification and an ADR that documents the tradeoff.

## Consequences
- Slower to adopt some tooling but lower maintenance burden.
- Clear documentation for each dependency addition.

## Alternatives Considered
- Broad adoption of third-party packages (faster prototyping, higher risk).
