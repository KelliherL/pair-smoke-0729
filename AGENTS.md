# AGENTS.md

Standing instructions for any agent working in this repo — Claude Code, Codex,
or anything else. This is the single source of truth; `CLAUDE.md` just points
here. Identity, board ids, and commands live in **`pairing.json`** — nothing
identity- or board-shaped may be hardcoded anywhere else.

## What this is

{{PROJECT_NAME}} — {{PROJECT_DESCRIPTION}}

## Read these first

Authoritative input to every task; do not infer design from the code alone.

- The PRD the current epic cites (`{{PRD_PATTERN}}` — a sequence; old ones are
  never rewritten).
- `docs/architecture.md` — **living document**: overview + the decision log.
  The reasoning behind each decision lives in its ADR. Do not rewrite it.
- `docs/adr/README.md` — how decisions get recorded and the risk rubric that
  decides whether one needs a human. Read it before making a call the code
  doesn't force.
- `docs/backlog.md` — the current ladder index.
- The pinned **Session log** issue (`pairing.json` → `sessionLogIssue`) — each
  agent session ends by commenting three lines (landed / in flight / blocked)
  and starts by reading the newest comments. An issue, not a file: comments
  need no PR. This is the only cross-machine context channel.

## Hard constraints

These hold in every session, whether or not a skill was invoked.

<!-- pf:begin constraints -->
1. **[Project constraint 1 — pair-init fills these from the interview: the
   invariants whose violation is a data leak, a corrupted persisted shape, or
   a broken domain rule. Three or four, concrete, testable.]**
2. **[Project constraint 2]**
3. **[Project constraint 3]**
4. **[Project constraint 4]**
<!-- pf:end constraints -->
5. **Green or no merge.** Every PR runs typecheck and the full test suite,
   with real output shown. Never report a suite as passing without running it.
6. **No unrequested dependencies.** Adding a library is an architectural
   decision: it needs a reason recorded via an ADR.
7. **Decisions get recorded, and the risky ones wait.** Any architectural call
   becomes an ADR in the same PR. Low risk is auto-approved; high risk stops
   the work — or, if **forced** (ADR-0013 path), ships implemented behind a
   merge-blocking `proposed-implemented` ADR. The rubric decides; unsure is
   high.

## Commands

{{RUNTIME_REQUIREMENT}}

```bash
{{SETUP_CMD}}        # install dependencies
{{TEST_CMD}}         # full test suite — CI and every skill call it this way
{{TYPECHECK_CMD}}    # typecheck
{{LINT_CMD}}         # lint
```

## The flow

Work is divided by **ownership, not by stage**. Per epic:

1. **PRD** — humans + agent write the next `{{PRD_PATTERN}}` file.
2. **Decompose** — `.claude/skills/decompose/SKILL.md` turns it into a
   reviewed ladder: rungs with **assignees, declared file surfaces, parallel
   groups (disjoint surfaces only), and the critical path front-loaded** so
   every human has non-conflicting work from t=0.
3. **Allocate** — every issue has exactly one assignee before work starts.
   **No assignee, no work.**
4. **Async completion** — each human tells their own agent **"complete
   assigned work"**, as often as needed (or arms `scripts/watch.sh` to be
   woken). GitHub is the message bus; there is no live channel.

**Who am I?** `gh api user --jq .login`, resolved against `pairing.json`
`humans[]`:

{{HUMANS_TABLE}}

A login not in that table stops and asks. One human in the table = **solo
mode**: self-verify is allowed and loudly bannered.

## "Complete assigned work"

The primary agent entrypoint — `.claude/skills/complete-assigned-work/SKILL.md`
(read it in full). In outline: sync; read the Session log; **fire async
verifies at other humans' unclaimed PRs and continue** (never block on a
verify); build your own issues in unblocking order (out-degree first — the
critical path surfaces itself), inside each issue's declared file surface;
wrap up with a Session log comment and a report of what needs a human.

## Verification (ADR 0010 + 0014, async form)

- **The other human's side verifies, via `scripts/verify.sh run <pr>`** — an
  asynchronous codex invocation (cross-vendor by construction). The wrapper
  posts `## Verify in progress` (the claim), runs codex sandboxed and
  networkless, and posts `## Verify verdict` (or `## Verify aborted`, which
  releases the claim). **Do not merge a PR with an open claim.** A stale
  claim is released deliberately (`scripts/verify.sh release <pr>`), never
  ignored.
- **Falsification is part of every verify**: break each claimed invariant,
  watch the suite go red, restore. A green suite with the behaviour broken is
  a finding.
- **When is a verdict required before merge?**

  | PR carries | Verdict required? |
  |---|---|
  | <!-- pf:begin verdict-required -->`core`, `infra`, or any change to the pure core, persistence, or the state machine (paths in `pairing.json` → `verify.verdictRequired`)<!-- pf:end verdict-required --> | **Yes** — merge only after a `## Verify verdict` |
  | Any PR that **deletes or modifies an existing test assertion** | **Yes**, whatever its label — weakening the suite is the change least able to afford skipping review |
  | `docs`, `polish`, or purely **additive** test-only PRs | No — verify if convenient, do not block |

## Recording decisions (ADRs)

The loop discards context on purpose, so an unwritten decision is invisible to
the next stage. Full rules and rubric: `docs/adr/README.md`. Short version:

```bash
scripts/adr.sh new --risk low  --issue N --title "..."            # record, keep going
scripts/adr.sh new --risk high --issue N --title "..."            # record, then STOP
scripts/adr.sh new --risk high --forced --issue N --title "..."   # forced: implement, gate at merge
scripts/adr.sh accept NNNN     # after a human approves (label first)
scripts/adr.sh check           # CI's gate; offline
```

A `proposed` or `proposed-implemented` high-risk ADR **fails CI**, so an
unruled decision cannot ride a merge. Only a human approves a high-risk ADR —
and a **process** ADR (`--scope process`) needs the approving human to be
someone other than the proposer.

## The board

{{BOARD_URL}} — a custom **Stage** single-select field (Backlog / Planned /
Building / Verifying / Human Review / Done). All ids live in `pairing.json`
`.board`; scripts flip stages via `pf_board_flip`, best-effort. **Human Review
is a hard stop:** an agent may move a card *into* it and never out of it.
Only a human moves a card to Done, because only a human merges.

## Writing issues

Backlog issues use `.github/ISSUE_TEMPLATE/backlog-issue.md` (including its
**File surface** section); ADR issues are normally created by `scripts/adr.sh
new`. `gh` does not apply templates to `--body` — read the template and fill
it. Do not invent a different shape.

## Repo conventions

- Branch per issue, named for it: `issue-14-engine-firing`.
- One PR per issue, referencing it (`Closes #N`), via the PR template.
- Labels per the runbook in `docs/backlog.md`: {{AREA_LABELS}}, plus the epic
  label. ADR issues carry `adr` + `adr-low`/`adr-high` (+ `adr-approved`).
- Merge is the human's call, after verify where required.

### Ownership

- **Assignee = owner.** Only the owner's agent plans or builds an issue; an
  unassigned issue is untouchable until a human assigns it.
- **The other human's side verifies.** Never verify a PR authored by your own
  human (solo mode excepted).
- **Stay inside the declared file surface.** Needing a file outside it is a
  coordination event: comment on the issue first. Parallel groups are only
  safe because surfaces are disjoint.
- **Batches are declared** on the issues before starting.
- **Process changes need a second human.** Anything touching `AGENTS.md`,
  `.claude/`, `scripts/`, `.github/`, or the templates is a `--scope process`
  ADR, approved by a human other than the proposer.

### `{{DEFAULT_BRANCH}}` is protected

A ruleset enforces this — not a convention you can talk your way past: no
direct pushes (every change via PR), CI's `check` job required, squash merge
only with branch deletion, no force-push. Admin bypass is an escape hatch for
a broken day, not a workflow.

## Per-agent notes

- **Claude Code** — skills in `.claude/skills/`; shared allowlist in
  `.claude/settings.json`; personal overrides in `.claude/settings.local.json`
  (gitignored). `scripts/watch.sh` can be wrapped in a Monitor for hands-free
  waking.
- **Codex** — read the same skills **by path** (`.claude/skills/<name>/
  SKILL.md`); there is deliberately no `.codex/skills` symlink (broken on
  Windows checkouts). Trust is per-machine (`trust_level` in
  `~/.codex/config.toml`) — not needed for `verify.sh`, which runs codex
  `--ephemeral`.
- **Everything** needs `gh` (authenticated, `project` scope for board flips)
  and `jq`. Per-machine setup lives in the pinned Onboarding issue.
