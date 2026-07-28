# scripts/ — the pipeline's moving parts

Everything reads `pairing.json` (identity, board ids, commands) via `jq`.
Nothing here hardcodes a login or a project id; if you find one, that is a
bug.

| Script | What it does |
|---|---|
| `assigned.sh` | Prints your two queues: other humans' PRs awaiting verify (claims respected) and your issues in execution order (unblocking work first). The first thing "complete assigned work" runs. |
| `verify.sh` | Async cross-vendor verification: `run <pr>` claims, spawns codex in the background, and posts the verdict (or an abort that releases the claim) from a detached worker. Also `claim` / `release` / `status`. Modes: `diff` (proven, default) and `full` (disposable clone; codex runs the suite + falsification). |
| `watch.sh` | Agent-agnostic wake loop: blocks until there is work, prints one `WAKE: <reason>` line, exits. `--once` for cron; wrap in your agent's monitor for hands-free operation. |
| `adr.sh` | The decision recorder: `new` (low / high / high `--forced` → `proposed-implemented`) / `accept` / `check` (CI's offline gate) / `pending` / `labels`. Process ADRs (`--scope process`) require a second human's approval. |
| `decompose.sh` | Drives the two-pass PRD→ladder flow with the human `ladder-approved` gate in the middle. |
| `lib.sh` | Shared helpers (source it): identity, solo-mode detection, claim-state machine, best-effort board flips. |

## What is automated vs deliberately human

| Step | Who |
|---|---|
| Plan comment, build, PR | agent (issue owner's side) |
| Verify: claim + codex pass + verdict comment | agent (the *other* human's side), async |
| Ladder approval (`ladder-approved` label) | **human** |
| High-risk ADR ruling (`adr-approved` label) | **human** — a *second* human for process ADRs |
| Merge | **human, always** — and never with an open verify claim |

## Per-machine prerequisites

`gh` (authenticated; `project` scope for board flips: `gh auth refresh -s
project`) · `jq` · your agent CLI (`claude` and/or `codex`) · the project
runtime per AGENTS.md Commands. `verify.sh` needs `codex` on the verifying
machine; without it, it exits 3 and tells you the interactive fallback.

## Known uncertainties

- `verify.sh --mode full` (codex running the suite in a workspace-write
  sandbox) and codex `--output-schema` were first live-validated during the
  kit's dry run — check `kit/fixtures/notes.md` in the kit repo for the
  captures before leaning on them in anger.
- Background detachment (`nohup … & disown`) is proven on Git Bash/Windows by
  the dry run's kill-the-terminal test; on other setups, `verify.sh run
  --wait` is the inline fallback and `watch.sh` re-drives are idempotent.
