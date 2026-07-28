# INSTALL.md — the pair-init contract

This file is the installer's spec. The pair-init skill follows it; a human
could too. Order matters.

## 0. Doctor

`gh auth status` (+ `project` scope — probe `gh project list --owner @me`;
fix: `gh auth refresh -s project`) · `command -v jq git` · `command -v codex`
(warn-only) · `gh api user --jq .login`.

## 1. Interview

- **Humans** (1..N): login, display name, CLI (`claude`/`codex`/`other`).
  One human = solo mode, say so.
- **Project**: name; one-paragraph description; runtime requirement (e.g.
  "Node ≥ 22.12"); commands (setup/test/typecheck/lint); default branch.
- **PRD**: existing file, write one now, or placeholder.
- **Hard constraints** (3–4): the invariants whose violation is a leak, a
  corrupt persisted shape, or a broken domain rule. These feed the AGENTS.md
  constraints block, rubric lines 2/3/5/6, the PR-template checks, and the
  verify skill's attack list — one set of answers, five artifacts.
- **Core paths**: where the pure core / persistence / state machine live —
  feeds `verify.verdictRequired.paths`.
- **Area labels** (default: core ui infra polish docs).
- Verify defaults (model, mode, timeout) — accept kit defaults unless asked.

## 2. Acquire

- Fresh: `gh repo create <owner>/<name> --template <kit> --private --clone`.
- Existing: clone the kit to a temp dir; branch `pair-factory-init` in the
  target; overlay per `pair-factory.manifest.json` (`onConflict`: skip /
  merge / replace / writeBeside — NEVER overwrite an existing AGENTS.md,
  workflow, or template: write `<name>.pairfactory.<ext>` beside and put the
  merge on the checklist). Prefill the interview from package.json /
  pyproject.toml where possible.

## 3. Instantiate

Fill every `{{VAR}}`; author every `<!-- pf:begin … -->` block from the
interview; write `pairing.json` (board section zeroed for now); generate
`.github/workflows/ci.yml` from `kit-templates/ci.yml.tmpl` (SETUP_STEPS =
the stack's setup-node/setup-python/none block); generate
`docs/architecture.md` from its template; delete kit-only files (README.md →
replaced by a project README stub, INSTALL.md, manifest, examples, schemas/,
kit-templates/, kit/).

## 4. GitHub state

```bash
bash scripts/adr.sh labels
gh label create session-log     --color 5319E7 --description "Pinned cross-machine session log"
gh label create epic            --color 6E5494 --description "Tracking issue for one PRD's ladder"
gh label create ladder-approved --color D93F0B --description "Human approved the proposed ladder"
# + each area label

n=$(gh issue create --title "Session log" --label session-log --body "<format>" | grep -oE '[0-9]+$')
gh issue pin "$n"                          # -> pairing.json .sessionLogIssue

gh project create --owner "$OWNER" --title "$NAME — plan/build/verify" --format json   # -> projectNumber, projectId
gh project field-create "$PN" --owner "$OWNER" --name Stage --data-type SINGLE_SELECT \
  --single-select-options "Backlog,Planned,Building,Verifying,Human Review,Done"
gh project field-list "$PN" --owner "$OWNER" --format json \
  --jq '.fields[] | select(.name=="Stage")'                 # -> stageFieldId + option ids
gh project link "$PN" --owner "$OWNER" --repo "$OWNER/$NAME"
# write all ids into pairing.json .board

gh api -X PUT "repos/$OWNER/$NAME/collaborators/$LOGIN" -f permission=push   # each other human

git add -A && git commit && git push        # the one legal direct push, pre-ruleset

sed "s/~DEFAULT_BRANCH/refs\/heads\/$BRANCH/" .github/ruleset-main.json > /tmp/rs.json
gh api "repos/$OWNER/$NAME/rulesets" -X POST --input /tmp/rs.json
gh api "repos/$OWNER/$NAME" -X PATCH -f allow_merge_commit=false \
  -f allow_rebase_merge=false -f delete_branch_on_merge=true
# VERIFY enforcement: push a trivial commit to the default branch and expect
# REJECTION. Report enforced vs advisory (free-plan private repos: advisory!).
```

## 5. Init ADR

`bash scripts/adr.sh new --risk low --title "Adopt pair-factory process kit"
--no-issue` — records the bootstrap, seeds the decision log, and is the first
live test of adr.sh in the new repo. (Its decision-log row is pre-seeded by
the architecture template; reconcile numbering if needed.)

## 6. Onboarding issue (pinned)

One checklist section per human: accept the collaborator invite · gh auth +
project scope · install jq · install your CLI (codex trust note: verify.sh
needs none — it runs `--ephemeral`; interactive codex work needs
`trust_level` in `~/.codex/config.toml`) · clone · `bash scripts/assigned.sh`
must greet you by name · install the runtime · run setup + test once · read
AGENTS.md end to end.

## 7. Kick off

PRD ready → `bash scripts/decompose.sh <prd>` (pass 1) → a human edits/
approves the ladder (`ladder-approved`) → pass 2 → every human's agent:
**"complete assigned work"** (and optionally arms `scripts/watch.sh`).
