# ADR 0002 — Engine state shape frozen by the foundation rung

- **Status:** accepted
- **Risk:** high
- **Date:** 2026-07-29
- **Issue:** #11
- **Blocks:** #4

## Context

Rungs 2 (engine), 3 (save), and 4 (CLI) all consume the engine state shape,
and 2 ∥ 3 run in parallel on disjoint surfaces — which is only safe if the
shared shape is frozen before they start. The verify verdict on PR #10
correctly found this cross-rung contract implemented with no ADR recording it.

## Decision

`GameState` is `{word, guessed[], remaining, phase}` with `Phase = playing |
won | lost`; `GuessResult = {state, outcome}` with `GuessOutcome = hit | miss
| repeat | invalid`; `MAX_WRONG = 8` — declared in full by the foundation
rung (#4). Later rungs fill these shapes and never widen them; any change to
the (future) serialised shape is an ADR + `schemaVersion` event.

## Why this over the alternatives

- **Let each rung grow the type:** kills the parallel group’s disjointness —
  rungs 2 and 3 would both edit types.ts. Rejected: it defeats the ladder.
- **Richer shape now (timestamps, scores):** speculation beyond prd0.
- This is a **forced** decision: the rung is unbuildable without a shape (no
  status quo), the recommendation is clear and minimal, and the revert is one
  PR (nothing outside this branch consumes it yet).

## Risk classification

Rubric line 5 (a public surface other layers consume) and line 2 (the future
persisted state). Forced conditions (a)–(c) hold → ADR 0013 path: implemented
in PR #10, Status `proposed-implemented`, human rules at merge.

## Consequences

- Rungs 2–4 build against a stable contract; the parallel group stays safe.
- The shape’s invariants are pinned by tests added in the same PR (the verify
  verdict’s P2 finding): type-level assertions, module purity, strict pin.
- Widening later requires a new ADR — the expensive direction is guarded.
