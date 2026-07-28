# ADR 0003 — Toolchain dependencies declared at init

- **Status:** accepted
- **Risk:** low
- **Date:** 2026-07-29
- **Issue:** #12
- **Blocks:** — (records PR #10's dependency additions)

## Context

The full-mode verify verdict on PR #10 (finding 1) correctly noted that
typescript, vitest and @types/node arrived with no ADR, and the rubric makes
dependency changes high-risk by default.

## Decision

The dev toolchain named by the pair-init interview and AGENTS.md Commands —
typescript, vitest, @types/node — is recorded as a single init-time decision.
These are the commands' implementations, chosen at bootstrap, not per-rung
choices.

## Why this over the alternatives

One ADR per dev-tool would be ceremony without information; leaving them
unrecorded routs the gate (the verdict's point).

## Risk classification

Low as a RECORD of the init decision (reversible in one PR, tested by the
suite that runs on them). Future dependency additions remain high-risk per
rubric line 1.

## Consequences

The verify finding is answered; the rubric stays intact for anything added
after init. Kit follow-up: pair-init should create this ADR automatically.
