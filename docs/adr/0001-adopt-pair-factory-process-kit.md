# ADR 0001 — Adopt pair-factory process kit

- **Status:** accepted
- **Risk:** low
- **Date:** 2026-07-29
- **Issue:** — (no issue: recorded in the init commit)
- **Blocks:** — (bootstrap)

## Context

This repo exists to prove the pair-factory kit end-to-end (solo mode). It
needs the full process from commit zero.

## Decision

The repo adopts the pair-factory kit wholesale: ownership flow, async codex
verify, ADR machinery, parallelism-carved decompose, board + session log.

## Why this over the alternatives

Ad-hoc process would prove nothing; the kit under test IS the point.

## Risk classification

Low: reversible in one PR (delete the kit files), no public surface, the
dry-run checklist is the test.

## Consequences

Every subsequent change follows AGENTS.md. Deviations found during the dry
run get fixed in the kit repo, not patched around here.
