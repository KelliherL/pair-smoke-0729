# Architecture Decision Records

One file per decision, numbered, never rewritten once accepted.
`docs/architecture.md` keeps the decision log — one row per **accepted** ADR;
the reasoning lives here. Every ADR also gets a GitHub issue: a record for low
risk, a gate for high.

## Why an agent writes these at all

The loop throws away context on purpose. The cost of a wrong-but-recorded
decision is one PR; the cost of an unrecorded one is a session archaeology
dig. The bar: **would a competent stranger reading the diff in three weeks
need the reason?** Then it is an ADR.

## Risk classification — the rubric

High risk if **any one** line applies (the asymmetry is on purpose):

1. It adds, removes, or swaps a dependency.
2. 2. It changes the persisted save shape (`.hangman-save.json`,
   `schemaVersion`, the serialised `GameState`).
3. It weakens or reinterprets any hard constraint in `AGENTS.md`.
4. It reverses or reinterprets an existing decision-log row.
5. It changes a public surface another layer consumes.
6. It changes domain rules beyond what the current PRD decides.
7. It changes the process itself — the loop, the skills, `scripts/`, CI,
   rulesets, or the issue/PR templates. (These are also `--scope process`:
   approval must come from a human other than the proposer.)
8. **You are not sure which bucket it belongs in. Unsure is high. Always.**

**Low risk** requires none of the above **and** all three of: reversible in
one PR · no new public surface · fully covered by tests in the same PR.

**Forced decisions** — a high-risk decision where (a) the status quo is not an
available option, (b) the agent has a clear recommendation, and (c) the change
is reversible in one PR. The agent writes the ADR as `proposed-implemented`,
**implements its recommendation with tests**, and ships both in the PR. The
ADR still fails `scripts/adr.sh check`, so a human must still accept or reject
it before merge — the gate has moved to merge, not disappeared. If any of
(a)–(c) fails, the normal high-risk path applies: `proposed`, and stop.

Unsure whether a decision is forced? It is not. Stop.

## Lifecycle

- **Low:** `scripts/adr.sh new --risk low …` → file is born `accepted`, its
  record issue opens and closes immediately, the decision-log row ships with
  the work.
- **High:** `new --risk high …` → file is `proposed`, a blocking issue opens,
  the agent **stops that line of work**. A human approves (the `adr-approved`
  label) → `scripts/adr.sh accept NNNN` → `accepted` + log row; or rejects →
  close the issue saying what to do instead, delete the file.
- **High, forced:** as above but `--forced`, Status `proposed-implemented`,
  work ships in the PR, ruling happens at merge.

### Where a blocked ADR lives

A `proposed` ADR fails CI, so it cannot sit on the default branch and it
cannot ride a PR. Commit it to the issue's branch and push the branch
**without** opening a PR. Say so on the ADR issue, with a link to the file.
The branch is the ADR's home until a human rules.

## Superseding

Never edit an accepted ADR's decision. Write a new ADR and set the old file's
Status to `superseded by ADR NNNN`.
