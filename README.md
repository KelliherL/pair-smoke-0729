# pair-factory

A replicable pair/team-programming pipeline for humans working with AI agents
on one GitHub repo. Distilled from a real project that shipped two epics
through it in a day — including the process catching real defects in both
directions and amending its own rules through its own gates.

**The promise:** point an agent at a repo (fresh or existing), answer a short
interview, and every human on the team can then drive their own agent with
five words — *"complete assigned work"* — while the pipeline coordinates
everything through GitHub artifacts. No live channel between machines exists
or is needed.

## The shape of it

- **Ownership, not stages.** Every issue has exactly one assignee; the
  owner's agent plans and builds it. *No assignee, no work.*
- **The other human's side verifies — asynchronously, cross-vendor.**
  `scripts/verify.sh` claims the PR, spawns a sandboxed codex review in the
  background, and posts the verdict. The claim blocks merges; an abort
  releases it. Falsification (break the invariant, watch the suite go red)
  is a mandatory verify step.
- **Work is carved for simultaneity.** Decompose declares each rung's **file
  surface**; parallel groups must be disjoint; shared surface gets extracted
  into a small front-loaded foundation rung; the critical path is allocated
  and built first. Every human has non-conflicting work from t=0.
- **Decisions are ADRs with a risk gate.** Low risk records and rides; high
  risk stops for a human; *forced* decisions ship implemented behind a
  merge-blocking `proposed-implemented` ADR (CI stays red until a human
  rules). Process changes need a second human.
- **Humans hold exactly two levers:** merges and high-risk rulings.
  Everything else is agent-legal, logged on a pinned Session log issue, and
  visible on a project board whose Human Review column is a hard stop.
- **The process improves itself:** a retro skill turns each epic's history
  into a retro doc plus proposed process ADRs, through the same gates.

## Install

The intended path is the **pair-init** agent skill (see `INSTALL.md` — it
drives the interview, instantiates every `{{VAR}}` and stub block, creates
labels/board/ruleset/session-log via `gh`, and posts a per-human onboarding
issue). Manual installation is the same steps done by hand.

Fresh repo: `gh repo create you/project --template <this-repo> --private
--clone`, then run pair-init inside it. Existing repo: pair-init overlays via
`pair-factory.manifest.json` and never overwrites your files (conflicts are
written beside, for you to merge).

## Requirements

Per machine: `gh` (authed, `project` scope), `jq`, `git`, and your agent CLI
(Claude Code and/or Codex; `verify.sh` wants `codex` on the verifying
machine). Per repo: nothing beyond what the kit adds. Solo use is supported
(one human in `pairing.json` = declared solo mode; self-verify is allowed and
bannered).

## Phase 2 (not yet in the kit)

`verify.tool: "auto"` with a Claude-wrapper verifier (for PRs authored by
codex-CLI humans — restores cross-vendor at that edge) · a solo three-stage
pipeline driver · ladder-lint as a script · dashboard integration.
