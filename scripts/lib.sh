#!/usr/bin/env bash
# lib.sh — shared helpers for pair-factory scripts. Source it; don't run it.
# Everything identity- or board-shaped reads pairing.json via jq: no logins,
# project numbers, or field/option ids may be hardcoded anywhere else.

PF_ROOT=$(git rev-parse --show-toplevel)
PF_CONFIG="$PF_ROOT/pairing.json"

pf_die() { echo "pair-factory: $*" >&2; exit 1; }
pf_say() { printf '== %s\n' "$*"; }

command -v jq >/dev/null 2>&1 || pf_die "jq is required (per-machine setup — see AGENTS.md)"
[ -f "$PF_CONFIG" ] || pf_die "pairing.json not found at repo root (run pair-init, or copy pairing.example.json)"
jq -e '.version == 1 and (.humans | length >= 1)' "$PF_CONFIG" >/dev/null 2>&1 \
  || pf_die "pairing.json failed the shape check (needs version: 1 and >=1 human)"

pf_cfg() { jq -r "$1" "$PF_CONFIG"; }

# ---- identity ---------------------------------------------------------------
PF_LOGIN=$(gh api user --jq .login 2>/dev/null) || pf_die "gh is not authenticated (gh auth login)"

pf_me_name() {
  jq -r --arg l "$PF_LOGIN" '.humans[] | select(.login == $l) | .name' "$PF_CONFIG"
}

pf_known() { [ -n "$(pf_me_name)" ]; }

pf_other_logins() {
  jq -r --arg l "$PF_LOGIN" '.humans[] | select(.login != $l) | .login' "$PF_CONFIG"
}

pf_solo() { [ "$(pf_cfg '.humans | length')" -eq 1 ]; }

pf_require_identity() {
  pf_known || pf_die "login '$PF_LOGIN' is not in pairing.json humans[] — add yourself (via PR) before working"
  if pf_solo; then
    pf_say "SOLO MODE: one human in pairing.json — self-verify is allowed and will be bannered as such"
  fi
}

# ---- verify claim state -----------------------------------------------------
# A PR is: 'verdict' if the latest marker is a verdict; 'claimed' if the latest
# marker is an in-progress claim; 'none' otherwise (no markers, or the latest
# is an abort — aborts release the claim so the PR re-queues).
pf_claim_state() { # $1 = pr number -> prints none|claimed|verdict
  gh pr view "$1" --json comments --jq '
    [.comments[].body] as $b
    | ([$b | to_entries[] | select(.value | startswith("## Verify in progress")) | .key] | max // -1) as $c
    | ([$b | to_entries[] | select(.value | startswith("## Verify verdict"))     | .key] | max // -1) as $v
    | ([$b | to_entries[] | select(.value | startswith("## Verify aborted"))     | .key] | max // -1) as $a
    | if $c > $v and $c > $a then "claimed"
      elif $v > -1 and $v > $a then "verdict"
      else "none" end'
}

# ---- board (best effort — a failed flip never fails the caller) -------------
pf_board_flip() { # $1 = issue number, $2 = stage name (e.g. Building)
  local pn owner pid fid oid item
  pn=$(pf_cfg '.board.projectNumber // 0')
  [ "$pn" != 0 ] && [ "$pn" != null ] || return 0
  owner=$(pf_cfg '.board.owner')
  pid=$(pf_cfg '.board.projectId')
  fid=$(pf_cfg '.board.stageFieldId')
  oid=$(jq -r --arg s "$2" '.board.stageOptionIds[$s] // empty' "$PF_CONFIG")
  [ -n "$oid" ] || { echo "board: no option id for stage '$2' (skipping)"; return 0; }
  item=$(gh project item-list "$pn" --owner "$owner" --format json --limit 200 \
    --jq "first(.items[] | select(.content.number == $1) | .id)" 2>/dev/null) || true
  [ -n "${item:-}" ] || { echo "board: issue #$1 not on the project (skipping flip)"; return 0; }
  if gh project item-edit --project-id "$pid" --id "$item" \
       --field-id "$fid" --single-select-option-id "$oid" >/dev/null 2>&1; then
    echo "board: #$1 -> $2"
  else
    echo "board: flip #$1 -> $2 failed (missing project scope? gh auth refresh -s project)"
  fi
}

# ---- misc -------------------------------------------------------------------
pf_session_log_issue() { pf_cfg '.sessionLogIssue // 0'; }

pf_default_branch() { pf_cfg '.project.defaultBranch // "main"'; }
