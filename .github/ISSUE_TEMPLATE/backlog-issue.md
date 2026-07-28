---
name: Backlog issue
about: One rung of the ladder — small enough for one plan → build → verify pass.
title: ''
labels: ''
assignees: ''
---

<!--
One issue = one pass of the loop. If it can't be planned, built and verified
in one sitting, split it. Every rung has exactly ONE assignee (no assignee, no
work) and a declared file surface (parallel work is only safe because
surfaces are disjoint). Delete every comment block before you post.

Inputs, always: the PRD this rung comes from, and docs/architecture.md.
Constraints that bind every issue live in AGENTS.md — don't restate them.
-->

Ladder position: X of epic #E. Depends on: #A, #B.

## Goal

<!-- One or two sentences. What is true after this merges that isn't true
     now? Written for a reader who has not read the backlog. -->

## File surface

<!-- The files/dirs this rung may create or modify (globs fine). Copied from
     the approved ladder's surface map. Touching anything outside this list
     is a coordination event: comment on the issue FIRST. -->

- Creates:
- Modifies:

## In scope

-

## Out of scope

<!-- The most valuable section. What a reasonable agent might helpfully add,
     that you do not want yet. Name the rung the work belongs to. -->

-

## Acceptance criteria

<!-- Observable and checkable, not "works correctly". Each line something
     verify can hold the diff against and answer yes/no. Include the
     adversarial cases: boundaries, repeats, corrupt input, empty first load. -->

- [ ]
- [ ]
- [ ]

## Tests this needs

<!-- Which layer, and what it pins. If you can't name the tests, the issue
     isn't specified yet. -->

-

## Reference

- PRD section:
- `docs/architecture.md` decision(s) this must respect:

## Loop

<!-- Tick as you go; mirrors the Stage field on the board: {{BOARD_URL}} -->

- [ ] **Planned** — `## Plan` comment posted on this issue
- [ ] **Building** — branch `issue-<n>-<slug>`, code + tests, inside the surface
- [ ] **Verifying** — PR open; claimed by `scripts/verify.sh` (async, cross-vendor)
- [ ] **Human Review** — verdict posted; a human calls merge or fix-first
