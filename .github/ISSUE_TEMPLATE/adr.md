---
name: ADR — architecture decision record
about: One architectural decision made while building. Low risk is auto-approved; high risk blocks until a human says go.
title: 'ADR: '
labels: adr
assignees: ''
---

<!--
Prefer `scripts/adr.sh new` — it allocates the number, writes the file from
docs/adr/0000-template.md, and opens this issue with the right labels. Use this
form by hand only for a decision raised outside a build session.

The ADR itself lives in `docs/adr/NNNN-slug.md` and lands in a PR. This issue is
the notification and, for high risk, the gate. Classify with the rubric in
`docs/adr/README.md` — not from memory. Delete every comment block before you
post.
-->

## ADR file

<!-- `docs/adr/NNNN-slug.md` — link it. If the file isn't written yet, this
     issue is premature. -->

## Decision

<!-- One or two sentences, present tense. The full reasoning stays in the file;
     this is the version a human reads in a notification. -->

## Risk

<!-- Tick exactly one, and cite the rubric line from docs/adr/README.md. -->

- [ ] **Low** — auto-approved. None of the high-risk lines apply, it is
      reversible in one PR, adds no public surface, and ships tested.
      This issue is a record: it is opened and closed together.
- [ ] **High** — needs a human. Rubric line(s): <!-- 1–8 -->

## What this blocks

<!-- The issue and/or PR that cannot proceed until this is decided, or "nothing
     — recorded after the fact". For high risk, the blocked issue's board card
     goes to Human Review. -->

- Blocks #

## Alternatives rejected

<!-- Briefly. If there were none, say so and expect to be asked why this is an
     ADR at all. -->

-

## Human gate (high risk only)

<!-- The agent stops here. A human does one of the two: -->

- Approve: `gh issue edit <n> --add-label adr-approved`, then
  `scripts/adr.sh accept NNNN` on resume.
- Reject: close this issue with a comment saying what to do instead. The ADR
  file is deleted, not left `proposed` — CI fails while a proposed high-risk ADR
  is in the tree.
