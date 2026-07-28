# Backlog — ladder index

Each epic's ladder lives here as an index once decompose pass 2 runs; the
GitHub issues are the source of truth and the spec files under
`docs/backlog/` are their birth records. Ladder position ≠ issue number
(issues and PRs share one sequence) — always use the real issue number.

| Pos | Issue # | Spec file | Title | Labels | Depends on | Assignee | Surface |
|---|---|---|---|---|---|---|---|
| 1 | [#4](https://github.com/KelliherL/pair-smoke-0729/issues/4) | `backlog/rung-01.md` | Foundation: scaffold + types + words | infra | — | Lachlan | (see issue) |
| 2 | [#5](https://github.com/KelliherL/pair-smoke-0729/issues/5) | `backlog/rung-02.md` | Engine: masking, guessing, win/lose | core | #4 | Lachlan | (see issue) |
| 3 | [#6](https://github.com/KelliherL/pair-smoke-0729/issues/6) | `backlog/rung-03.md` | Save: persistence | core | #4 | Lachlan | (see issue) |
| 4 | [#7](https://github.com/KelliherL/pair-smoke-0729/issues/7) | `backlog/rung-04.md` | CLI: play + resume | cli | #5, #6 | Lachlan | (see issue) |
| 5 | [#8](https://github.com/KelliherL/pair-smoke-0729/issues/8) | `backlog/rung-05.md` | Regression + polish | polish | #4–#7 | Lachlan | (see issue) |

## Labels runbook

Created by pair-init; re-run any line idempotently:

```bash
scripts/adr.sh labels        # adr, adr-low, adr-high, adr-approved
# area labels: core, cli, infra, polish, docs
# plus: epic, ladder-approved, session-log
```

Labels carry weight: the verdict-required table keys on them. A mislabelled
core PR is how a leak skips review — labelling accuracy is a verify check.
