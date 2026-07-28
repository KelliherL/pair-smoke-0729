#!/usr/bin/env bash
# decompose.sh — turn one PRD into a reviewed ladder of GitHub issues.
#
# The stage before pipeline.sh. pipeline.sh drives ONE issue through
# plan → build → verify; this drives ONE PRD into the issues it drives.
# Same shape as the rest of the loop: a headless agent proposes, a human
# labels, a rerun executes. This script NEVER merges.
#
# Usage:
#   scripts/decompose.sh <prd-file> [options]
#
# Options:
#   --vendor codex|claude   who runs the stage (default: claude — a bad split
#                           is the most expensive mistake in the loop)
#   --dry-run               print the agent commands instead of running
#
# Env overrides:
#   DECOMPOSE_MODEL         model for a claude run (default: CLI default)
#   DECOMPOSE_CODEX_MODEL   -m value for a codex run (default: CLI default)
#   DECOMPOSE_CODEX_SANDBOX codex --sandbox value (default: workspace-write)
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

usage() { sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
die()   { echo "decompose: $*" >&2; exit 1; }
say()   { printf '\n== %s\n' "$*"; }

PRD="" VENDOR="claude" DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --vendor)  VENDOR="${2:?}"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) usage ;;
    *)         PRD="$1"; shift ;;
  esac
done
[ -n "$PRD" ] || usage
[ -f "$PRD" ] || die "no such PRD file: $PRD"
case "$VENDOR" in codex|claude) ;; *) die "--vendor must be codex or claude" ;; esac

# The epic issue is found by a marker in its body, not by title — titles get
# edited, markers don't.
MARKER="<!-- decompose:prd $PRD -->"

run_agent() { # $1 = description, rest = the command
  local desc="$1"; shift
  say "$desc"
  if [ "$DRY" = 1 ]; then printf 'DRY RUN:'; printf ' %q' "$@"; echo; return 0; fi
  "$@"
}

agent() { # $1 = description, $2 = prompt
  if [ "$VENDOR" = claude ]; then
    run_agent "$1 — claude, fresh context" \
      claude -p "$2" ${DECOMPOSE_MODEL:+--model "$DECOMPOSE_MODEL"} \
        --permission-mode acceptEdits
  else
    run_agent "$1 — codex, fresh context" \
      codex exec --sandbox "${DECOMPOSE_CODEX_SANDBOX:-workspace-write}" \
        ${DECOMPOSE_CODEX_MODEL:+-m "$DECOMPOSE_CODEX_MODEL"} "$2"
  fi
}

# ---- gates (all read GitHub, the source of truth) --------------------------
epic_issue() {
  gh issue list --state all --label epic --limit 100 --json number,body \
    --jq "first(.[] | select(.body | contains(\"$MARKER\")) | .number)"
}
ladder_comments() { # $1 = epic issue number
  gh issue view "$1" --json comments \
    --jq '[.comments[].body | select(startswith("## Ladder"))] | length'
}
ladder_approved() { # $1 = epic issue number
  gh issue view "$1" --json labels \
    --jq '[.labels[].name] | contains(["ladder-approved"])'
}
open_pr() {
  gh pr list --state open --json number,headRefName \
    --jq "first(.[] | select(.headRefName | startswith(\"backlog-$PRD_SLUG\")) | .number)"
}
adr_pending() { scripts/adr.sh pending 2>/dev/null || true; }

PRD_SLUG=$(basename "$PRD" .md)

ensure_labels() {
  [ "$DRY" = 1 ] && return 0
  gh label create epic --color 6E5494 \
    --description "Tracking issue for one PRD's ladder" 2>/dev/null || true
  gh label create ladder-approved --color D93F0B \
    --description "A human has read and approved the proposed ladder" 2>/dev/null || true
}

ensure_epic() { # prints the epic issue number
  local n
  n="$(epic_issue)"
  if [ -n "${n:-}" ]; then printf '%s' "$n"; return 0; fi
  if [ "$DRY" = 1 ]; then printf '<EPIC>'; return 0; fi
  gh issue create --label epic \
    --title "Epic: $PRD_SLUG — decompose into the issue ladder" \
    --body "$MARKER

Tracking issue for \`$PRD\`. The proposed ladder lands here as a \`## Ladder\`
comment (\`scripts/decompose.sh\`). A human reviews it and applies
\`ladder-approved\`; a rerun then writes the spec files and creates the issues.

Closed when every rung exists as an issue and is on the project board (see pairing.json .board)." >/dev/null
  epic_issue
}

# ---- the two passes ---------------------------------------------------------
ensure_labels
EPIC="$(ensure_epic)"
[ -n "$EPIC" ] || die "could not find or create the epic issue for $PRD"
say "epic issue for $PRD is #$EPIC"

if [ "$DRY" != 1 ] && [ "$(ladder_comments "$EPIC")" -gt 0 ] \
   && [ "$(ladder_approved "$EPIC")" != "true" ]; then
  say "HUMAN GATE — a ladder is already proposed on #$EPIC and not yet approved."
  echo "Read it, then: gh issue edit $EPIC --add-label ladder-approved"
  exit 0
fi

if [ "$DRY" = 1 ] || [ "$(ladder_approved "$EPIC")" != "true" ]; then
  # ---- pass 1: propose --------------------------------------------------
  agent "DECOMPOSE pass 1 (propose the ladder)" \
    "Read .claude/skills/decompose/SKILL.md in full and follow its 'Pass 1' section for the PRD at $PRD. The epic tracking issue is #$EPIC. You are running headless: do not ask questions."
  [ "$DRY" = 1 ] && exit 0
  [ "$(ladder_comments "$EPIC")" -gt 0 ] \
    || die "GATE FAILED: no '## Ladder' comment landed on epic issue #$EPIC"
  PENDING_ADR="$(adr_pending)"
  if [ -n "$PENDING_ADR" ]; then
    say "HUMAN GATE — the split raised a high-risk ADR:"
    printf '%s\n' "$PENDING_ADR"
  fi
  say "HUMAN GATE — read the ladder on #$EPIC, then: gh issue edit $EPIC --add-label ladder-approved"
  exit 0
fi

# ---- pass 2: materialise ------------------------------------------------
PENDING_ADR="$(adr_pending)"
if [ -n "$PENDING_ADR" ]; then
  say "HUMAN GATE — blocked on an unapproved high-risk ADR:"
  printf '%s\n' "$PENDING_ADR"
  echo "Approve it (--add-label adr-approved, then scripts/adr.sh accept NNNN) or close it as rejected, then rerun."
  exit 0
fi

agent "DECOMPOSE pass 2 (write specs, create issues)" \
  "Read .claude/skills/decompose/SKILL.md in full and follow its 'Pass 2' section for the PRD at $PRD. The approved ladder is the '## Ladder' comment on issue #$EPIC — treat that comment as the spec, a human may have edited it. You are running headless: do not ask questions."

PR="$(open_pr)"
[ -n "$PR" ] || die "GATE FAILED: no open PR from a branch named backlog-$PRD_SLUG*"
say "ladder materialised — PR #$PR is open. CI:"
gh pr checks "$PR" || true
say "HUMAN GATE — review and merge PR #$PR, then drive each issue with: scripts/pipeline.sh <n>"
