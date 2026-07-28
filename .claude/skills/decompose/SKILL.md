---
name: decompose
description: Turn one PRD into a reviewed, parallelism-maximizing ladder of GitHub issues with assignees and disjoint file surfaces. Use when a new PRD exists and has no backlog yet.
---

# Decompose one PRD

Input: one PRD file (matches `prdPattern` in `pairing.json`). Meant to run on
a **strong model** — a bad split costs more than any other mistake, because
every later stage inherits it.

This runs **twice**, with a human in between. `scripts/decompose.sh` decides
which half you are in; do not skip ahead.

## Pass 1 — propose the ladder

1. Read the PRD in full, plus `docs/architecture.md`, `AGENTS.md`, the
   existing `docs/backlog.md`, and `pairing.json` (who the humans are).
2. Split into rungs. The bar for one rung: **plannable, buildable and
   verifiable in one pass of the loop**. Foundation before features, core
   before UI, everything before polish.
3. Post the proposal as a comment on the epic tracking issue whose first line
   is `## Ladder` (the marker `decompose.sh` gates on). It must contain
   **five sections**:

   - **`### Rungs`** — table: `# | Title | Labels | Depends on | Assignee |
     Goal`. Every rung gets an assignee **now**: allocation is part of what
     the human approves, and they can reassign by editing the comment.
   - **`### File surface map`** — table: `# | Creates | Modifies`. Every file
     or directory each rung will touch, as concretely as the PRD allows
     (globs fine). This section is what makes parallel work safe.
   - **`### Parallel groups`** — explicit: `Group A (t=0): rungs 1, 3`,
     `Group B (after 1 merges): 2, 4`… **Invariant: two rungs may share a
     group only if their Creates ∪ Modifies are disjoint.** If two rungs need
     the same file, either sequence them or extract the shared piece into a
     **foundation rung** — smallest possible, first on the critical path
     (shared types, schemas, interfaces are the usual suspects).
   - **`### Critical path`** — the longest dependency chain, named
     (`1 → 4 → 6`), so allocation can front-load it.
   - **`### Allocation rationale`** — one line per human proving the rule:
     the critical path is assigned to be built first; at t=0 **every** human
     has at least one workable rung whose surface is disjoint from every
     other in-flight rung; nobody waits for someone else before starting.

4. Raise an ADR for anything the split itself decides that the PRD does not.
   Classify with `docs/adr/README.md`, not from feel.
5. Write no spec files and no issues in this pass. Stop.

## Pass 2 — materialise it

Only after a human has applied `ladder-approved` to the epic issue.

1. Re-read the approved `## Ladder` comment — it is the spec now, not your
   memory of pass 1; a human may have edited assignees or groups.
2. **Mechanical disjointness check before anything else:** for every declared
   parallel group, intersect the members' file surfaces. Any overlap → stop
   and post the conflict on the epic instead of creating issues.
3. For each rung, write `docs/backlog/issue-NN-slug.md` from
   `.github/ISSUE_TEMPLATE/backlog-issue.md` — every section, especially
   **Out of scope**, **Acceptance criteria**, and the **File surface** block
   (copied from the map).
4. Create the issues in ladder order: bodies verbatim from the spec files,
   labels from the ladder, **`--assignee` from the ladder**. Then reconcile
   numbering (issues and PRs share one sequence — ladder position ≠ issue
   number): prepend each body's `Ladder position: X of epic #E. Depends on:
   #real, #numbers.` line and update the index table in `docs/backlog.md`.
5. Add every issue to the project board at Stage `Backlog` (the scripts'
   `pf_board_flip` does this from `pairing.json` — no hardcoded ids).
6. Open one PR carrying the spec files and the `docs/backlog.md` index. Do
   not merge.

## Rules of the loop

The ladder is reviewed **before** any issue body exists, because that is the
cheap moment to catch a wrong split — and a wrong *allocation* is a wrong
split. Once the issues exist they are the source of truth; the spec files are
birth records.

> Draft skill — every retro should improve it or extract a step into a script.
