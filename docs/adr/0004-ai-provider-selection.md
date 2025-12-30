# 0004: AI Provider Selection

Date: 2025-02-14
Status: Accepted

## Context
Phase 2 requires an external NLP provider for task parsing.

## Decision
Use the OpenAI API for initial AI parsing in Phase 2. Reassess later based on cost, latency, and privacy needs.

## Consequences
- Fast iteration with strong NLP quality.
- Requires API key management and network availability.

## Alternatives Considered
- Claude API (comparable capability).
- On-device Core ML (privacy-first but slower to reach quality).
