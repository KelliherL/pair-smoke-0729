#!/usr/bin/env bash
# watch.sh — agent-agnostic wake loop. Blocks until there is work for THIS
# machine's human, then exits 0 printing one machine-parseable WAKE line:
#
#   WAKE: verify-available  PR#12   (<author>'s PR lacks claim and verdict)
#   WAKE: own-pr-verdict    PR#9    (verdict posted)
#   WAKE: own-pr-aborted    PR#9    (verify aborted — re-run scripts/verify.sh)
#   WAKE: issue-unblocked   #14     (dependency #11 closed)
#   WAKE: new-assignment    #17
#
# Usage: scripts/watch.sh [--interval 60] [--once] [--max-minutes M]
#   --once         single poll (cron / Task Scheduler); exit 1 = nothing yet
#   --max-minutes  give up after M minutes (exit 2)
# Claude Code agents can wrap this in a Monitor; any agent (or a human) can
# loop:  ./scripts/watch.sh && <agent> "complete assigned work"
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
# shellcheck source=lib.sh
. scripts/lib.sh
pf_require_identity

INTERVAL=60 ONCE=0 MAX_MIN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --interval)    INTERVAL="${2:?}"; shift 2 ;;
    --once)        ONCE=1; shift ;;
    --max-minutes) MAX_MIN="${2:?}"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 64 ;;
  esac
done

# Baseline: verdict/abort counts on my open PRs, my assigned issue set, and
# per-issue blocked state — wakes fire on TRANSITIONS from this snapshot.
snapshot_prs() { # -> lines "pr verdicts aborts"
  gh pr list --author "$PF_LOGIN" --state open --json number --jq '.[].number' | while read -r p; do
    gh pr view "$p" --json comments --jq '
      [.comments[].body] as $b
      | "'"$p"' \([$b[] | select(startswith("## Verify verdict"))] | length) \([$b[] | select(startswith("## Verify aborted"))] | length)"'
  done
}
my_issues()   { gh issue list --assignee "$PF_LOGIN" --state open --limit 100 --json number --jq '.[].number' | sort -n; }
issue_blocked() { # $1=issue -> 0 if blocked
  local deps d
  deps=$(gh issue view "$1" --json body --jq .body | grep -oiE 'depends on: [^.]*' | grep -oE '#[0-9]+' | tr -d '#') || return 1
  [ -n "$deps" ] || return 1
  for d in $deps; do
    [ "$(gh issue view "$d" --json state --jq .state 2>/dev/null || echo OPEN)" = "CLOSED" ] || return 0
  done
  return 1
}

BASE_PRS=$(snapshot_prs || true)
BASE_ISSUES=$(my_issues || true)
BASE_BLOCKED=""
for i in $BASE_ISSUES; do issue_blocked "$i" && BASE_BLOCKED="$BASE_BLOCKED $i"; done
START=$(date +%s)

poll() {
  # 1. Other humans' PRs needing verify (unclaimed, verdict-less).
  local authors author p state
  if pf_solo; then authors="$PF_LOGIN"; else authors=$(pf_other_logins); fi
  for author in $authors; do
    for p in $(gh pr list --author "$author" --state open --json number --jq '.[].number'); do
      state=$(pf_claim_state "$p")
      if [ "$state" = none ]; then
        echo "WAKE: verify-available  PR#$p   ($author's PR lacks claim and verdict)"
        return 0
      fi
    done
  done
  # 2. Movement on my own PRs vs baseline.
  local now_line pr v a base_line bv ba
  while read -r pr v a; do
    [ -n "${pr:-}" ] || continue
    base_line=$(echo "$BASE_PRS" | awk -v p="$pr" '$1 == p {print; exit}')
    bv=$(echo "${base_line:-"$pr 0 0"}" | awk '{print $2}')
    ba=$(echo "${base_line:-"$pr 0 0"}" | awk '{print $3}')
    if [ "$v" -gt "${bv:-0}" ]; then echo "WAKE: own-pr-verdict    PR#$pr    (verdict posted)"; return 0; fi
    if [ "$a" -gt "${ba:-0}" ]; then echo "WAKE: own-pr-aborted    PR#$pr    (verify aborted — re-run scripts/verify.sh)"; return 0; fi
  done < <(snapshot_prs || true)
  # 3. Newly assigned issues.
  local i
  for i in $(my_issues || true); do
    echo "$BASE_ISSUES" | grep -qx "$i" || { echo "WAKE: new-assignment    #$i"; return 0; }
  done
  # 4. Previously blocked issues now unblocked.
  for i in $BASE_BLOCKED; do
    if ! issue_blocked "$i"; then
      echo "WAKE: issue-unblocked   #$i     (its dependencies closed)"
      return 0
    fi
  done
  return 1
}

while true; do
  if poll; then exit 0; fi
  [ "$ONCE" = 1 ] && exit 1
  if [ "$MAX_MIN" -gt 0 ] && [ $(( $(date +%s) - START )) -ge $((MAX_MIN * 60)) ]; then
    echo "watch: no events after ${MAX_MIN}m" >&2
    exit 2
  fi
  sleep "$INTERVAL"
done
