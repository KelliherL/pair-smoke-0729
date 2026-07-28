# ADR 0004 — Full-mode verify is experimental until sandboxed execution works

- **Status:** proposed
- **Risk:** high
- **Scope:** process
- **Date:** 2026-07-29
- **Issue:** — (retro PR carries it; solo repo)
- **Blocks:** — (process change)

## Context

The dry run's full-mode verify (PR #10) proved the machinery (clone, setup,
codex in workspace-write, methodical falsification) but captured hard limits:
node tooling cannot execute inside the Windows codex sandbox (EPERM lstat on
the home directory, git index locks blocked) and codex resolves the machine's
stale system node. The mutation table ran; the suite results did not.

## Decision

AGENTS.md and the verify defaults treat `--mode full` as **experimental**:
diff mode remains the default and the verdict-required standard; full mode
may be used, but its verdicts must state what actually executed, and a full-
mode pass whose commands all failed environmentally does not satisfy the
falsification requirement — the builder's own mutation evidence (or an
interactive verify) does instead.

## Why this over the alternatives

- Pretending full mode works invites false confidence in unexecuted suites.
- Removing it discards working machinery and the capture that improves it.

## Risk classification

Rubric line 7 (process change). Solo repo: the second-human rule is waived by
construction; the ruling is still explicit and labelled.

## Consequences

Revisit when sandbox exec or a wrapper-side mutation runner lands in the kit.
