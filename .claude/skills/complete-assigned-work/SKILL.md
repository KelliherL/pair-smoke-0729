---
name: complete-assigned-work
description: Work through everything assigned to this machine's human — fire async verifies at other humans' waiting PRs, then plan+build your own assigned issues in unblocking order. Use when asked to "complete assigned work" or at the start of any work session.
---

# Complete assigned work

The primary work-session entrypoint (AGENTS.md "The flow"). You act for
exactly one human — the one `pairing.json` maps your `gh` login to — and you
never touch another human's work except to verify it.

## 0. Orient

- `git switch <defaultBranch> && git pull --ff-only`.
- Read the newest comments on the pinned **Session log** issue
  (`.sessionLogIssue` in `pairing.json`).
- `scripts/assigned.sh` — prints both queues, identity-checked and already in
  execution order. If it says your login is unknown, stop.

## 1. Verify queue — fire and CONTINUE (never block on it)

For each PR `assigned.sh` marks "needs verify":

```bash
scripts/verify.sh run <pr>        # claims, spawns codex, returns immediately
```

The verdict posts to the PR from a background worker even if this session
ends. Do **not** wait for it — move straight on. If `verify.sh` exits 3
(codex missing), fall back to the interactive path: `scripts/verify.sh claim
<pr>`, then follow `.claude/skills/verify/SKILL.md` yourself. Never verify
your own human's PR (solo mode excepted — the script banners it).

## 2. Build queue — unblocking work first

`assigned.sh` orders your issues by **out-degree** (how many other open
issues each unblocks), then position — the critical path surfaces first, and
verification you fired in step 1 overlaps this entire phase. Skip anything it
marks BLOCKED or "PR open".

For each workable issue, on a fresh branch `issue-N-<slug>` off the default
branch:

1. `.claude/skills/plan/SKILL.md` — the plan lands as a `## Plan` comment on
   the issue. Plans never live only in a conversation.
2. `.claude/skills/build/SKILL.md` — code and tests, **staying inside the
   issue's declared File surface** (needing a file outside it is a
   coordination event: comment on the issue first). Green typecheck + full
   suite with real output; PR via the template. Plan→build in one session is
   fine: the adversarial pass is the other human's async verify.
3. Do not merge. Next issue.

## 3. Wrap up

- `scripts/verify.sh status <pr>` for anything you fired in step 1; report
  outcomes or in-flight state.
- Comment on the Session log issue: date, your human, three lines —
  **landed / in flight / blocked**.
- `pf_board_flip` happens inside the scripts; flip anything you touched
  manually only if a script could not.
- Report: verifies fired (and their state), PRs opened, both queues'
  remaining depth, and everything that now needs a human (merges, high-risk
  ADR rulings, aborted verifies).

To keep working hands-free, arm `scripts/watch.sh` (or wrap it in your
agent's monitor facility) and re-run this skill on each WAKE line.

## Never

- Merge anything, or approve a high-risk ADR — humans only.
- Verify your own human's PR (outside bannered solo mode).
- Work an unassigned issue or another human's issue, even if it looks quick.
- Edit files outside your issue's declared File surface without commenting
  first.
- Push to the default branch or bypass the ruleset, even where permissions
  allow it.
