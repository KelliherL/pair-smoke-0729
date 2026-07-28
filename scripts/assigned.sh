#!/usr/bin/env bash
# assigned.sh — print this machine's two work queues (AGENTS.md "The flow"):
# PRs by other humans awaiting your verify (claims respected, ADR 0014), and
# your assigned open issues in execution order (unblocking work first).
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
# shellcheck source=lib.sh
. scripts/lib.sh

pf_require_identity
echo "You are $PF_LOGIN ($(pf_me_name))."

echo
echo "== Verify queue — other humans' PRs =="
found=0
if pf_solo; then
  echo "  (solo mode: your own PRs appear here; verify.sh will banner self-verify)"
  PR_AUTHORS="$PF_LOGIN"
else
  PR_AUTHORS=$(pf_other_logins)
fi
for author in $PR_AUTHORS; do
  for pr in $(gh pr list --author "$author" --state open --json number --jq '.[].number'); do
    state=$(pf_claim_state "$pr")
    title=$(gh pr view "$pr" --json title --jq .title)
    case "$state" in
      none)    echo "  #$pr  $title  — needs verify: scripts/verify.sh run $pr"; found=1 ;;
      claimed) echo "  #$pr  $title  — claimed, in progress (do not merge; scripts/verify.sh status $pr)"; found=1 ;;
      verdict) ;; # verified — awaiting a human merge, not our queue
    esac
  done
done
[ "$found" = 0 ] && echo "  (empty)"

echo
echo "== Build queue — open issues assigned to you, execution order =="
# Order: out-degree (how many open issues this one unblocks) descending, then
# issue number ascending. Dependencies are read from the machine line every
# ladder issue carries: "Depends on: #A, #B." — unmerged deps are flagged.
issues_json=$(gh issue list --assignee "$PF_LOGIN" --state open --limit 100 \
  --json number,title,labels,body)
all_open=$(gh issue list --state open --limit 200 --json number,body)

echo "$issues_json" | jq -r '.[] | select([.labels[].name] | index("adr") | not) | .number' | while read -r n; do
  title=$(echo "$issues_json" | jq -r --argjson n "$n" '.[] | select(.number == $n) | .title')
  deps=$(echo "$issues_json" | jq -r --argjson n "$n" '.[] | select(.number == $n) | .body' \
    | grep -oiE 'depends on: [^.]*' | grep -oE '#[0-9]+' | tr -d '#' | tr '\n' ' ') || deps=""
  outdeg=$(echo "$all_open" | jq -r --arg n "#$n" '[.[] | select(.body | test("[Dd]epends on:[^.\n]*" + $n + "\\b"))] | length')
  blocked=""
  for d in $deps; do
    dstate=$(gh issue view "$d" --json state --jq .state 2>/dev/null || echo OPEN)
    [ "$dstate" = "CLOSED" ] || blocked="$blocked #$d"
  done
  if [ -n "$blocked" ]; then
    echo "SORT:0:$n  #$n  $title  — BLOCKED on:$blocked"
  else
    pr_open=$(gh pr list --state open --json headRefName --jq "[.[] | select(.headRefName | startswith(\"issue-$n-\"))] | length")
    if [ "$pr_open" -gt 0 ]; then
      echo "SORT:0:$n  #$n  $title  — PR open, awaiting verify/merge"
    else
      echo "SORT:$((outdeg + 1)):$n  #$n  $title  — workable (unblocks $outdeg)"
    fi
  fi
done | sort -t: -k2,2nr -k3,3n | sed 's/^SORT:[0-9]*:[0-9]*//' | {
  any=0
  while IFS= read -r line; do echo "$line"; any=1; done
  [ "$any" = 0 ] && echo "  (empty)"
}
