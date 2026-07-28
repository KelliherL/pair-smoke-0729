# Backlog — ladder index

Each epic's ladder lives here as an index once decompose pass 2 runs; the
GitHub issues are the source of truth and the spec files under
`docs/backlog/` are their birth records. Ladder position ≠ issue number
(issues and PRs share one sequence) — always use the real issue number.

| Pos | Issue # | Spec file | Title | Labels | Depends on | Assignee | Surface |
|---|---|---|---|---|---|---|---|

## Labels runbook

Created by pair-init; re-run any line idempotently:

```bash
scripts/adr.sh labels        # adr, adr-low, adr-high, adr-approved
# area labels: core, cli, infra, polish, docs
# plus: epic, ladder-approved, session-log
```

Labels carry weight: the verdict-required table keys on them. A mislabelled
core PR is how a leak skips review — labelling accuracy is a verify check.
