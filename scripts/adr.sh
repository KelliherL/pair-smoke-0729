#!/usr/bin/env bash
# adr.sh — record one architecture decision (docs/adr/README.md is the rubric).
#
# Usage:
#   scripts/adr.sh new --risk low|high --title "..." [--issue N] [--slug s]
#                      [--no-issue] [--forced] [--scope process]
#   scripts/adr.sh accept <NNNN> [--force]
#   scripts/adr.sh check                 # offline: fail while any high-risk ADR awaits a ruling
#   scripts/adr.sh pending [<issue>]     # open, unapproved high-risk ADR issues
#   scripts/adr.sh labels                # create the adr labels (idempotent)
#
# `new --risk low`     writes an accepted ADR, opens AND closes its record issue.
# `new --risk high`    writes a proposed ADR, opens a blocking issue, and tells
#                      the agent to STOP. `check` fails CI until it is resolved.
# `new --risk high --forced`  the ADR 0013 path: for a FORCED decision (status
#                      quo unavailable + clear recommendation + one-PR revert)
#                      the agent implements its recommendation and ships it in
#                      the PR with Status `proposed-implemented` — the gate
#                      moves to merge (check still fails) instead of stopping
#                      the work. Unsure whether it is forced? It is not. Stop.
# `--scope process`    marks a process ADR: acceptance requires the
#                      adr-approved label applied by a human other than the
#                      issue's author (multi-human repos).
# Global: --dry-run  print what would happen, touch nothing.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

ADR_DIR=docs/adr
TEMPLATE="$ADR_DIR/0000-template.md"
ARCH=docs/architecture.md
DRY=0

usage() { sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
die()   { echo "adr: $*" >&2; exit 1; }
run()   { if [ "$DRY" = 1 ]; then printf 'DRY RUN:'; printf ' %q' "$@"; echo; else "$@"; fi; }

slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/[^a-z0-9]\{1,\}/-/g' -e 's/^-//' -e 's/-$//' | cut -c1-60
}

# Numbers come from the issue tracker first (ADR 0013: the working tree can't
# see ADRs parked on unmerged branches — that is how 0011 got issued twice),
# with the tree as the offline fallback. Take the max of both.
next_number() {
  local max=0 n
  for f in "$ADR_DIR"/[0-9][0-9][0-9][0-9]-*.md; do
    [ -e "$f" ] || continue
    n=$(basename "$f" | cut -c1-4)
    n=$((10#$n))
    [ "$n" -gt "$max" ] && max=$n
  done
  local from_issues
  from_issues=$(gh issue list --label adr --state all --limit 200 --json title \
    --jq '[.[].title | capture("^ADR (?<n>[0-9]+):").n | tonumber] | max // 0' \
    2>/dev/null) || from_issues=0
  [ "${from_issues:-0}" -gt "$max" ] && max=$from_issues
  printf '%04d' $((max + 1))
}

adr_file() { # $1 = NNNN
  local f
  f=$(ls "$ADR_DIR/$1"-*.md 2>/dev/null | head -1) || true
  [ -n "${f:-}" ] || die "no ADR file for $1 in $ADR_DIR"
  printf '%s' "$f"
}

field() { # $1 = file, $2 = field name -> value
  sed -n "s/^- \*\*$2:\*\* *//p" "$1" | head -1
}

set_field() { # $1 = file, $2 = field, $3 = value
  run perl -i -pe "s/^- \\*\\*\Q$2\E:\\*\\* .*/- **$2:** $3/ if \$. < 20" "$1"
}

# ---- labels ----------------------------------------------------------------
cmd_labels() {
  run gh label create adr          --color 0052CC --description "Architecture decision record" 2>/dev/null || true
  run gh label create adr-low      --color C2E0C6 --description "ADR: low risk — auto-approved, record only" 2>/dev/null || true
  run gh label create adr-high     --color B60205 --description "ADR: high risk — blocks until a human approves" 2>/dev/null || true
  run gh label create adr-approved --color 0E8A16 --description "A human has approved this ADR" 2>/dev/null || true
  echo "labels: ensured (adr, adr-low, adr-high, adr-approved)"
}

# ---- new -------------------------------------------------------------------
cmd_new() {
  local risk="" title="" slug="" blocks="" make_issue=1 forced=0 scope=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --risk)     risk="${2:?}"; shift 2 ;;
      --title)    title="${2:?}"; shift 2 ;;
      --slug)     slug="${2:?}"; shift 2 ;;
      --issue)    blocks="${2:?}"; shift 2 ;;
      --no-issue) make_issue=0; shift ;;
      --forced)   forced=1; shift ;;
      --scope)    scope="${2:?}"; shift 2 ;;
      *) die "unknown option for new: $1" ;;
    esac
  done
  [ -n "$title" ] || die "new needs --title"
  case "$risk" in low|high) ;; *) die "new needs --risk low|high (unsure => high, see $ADR_DIR/README.md)" ;; esac
  [ "$forced" = 1 ] && [ "$risk" != high ] && die "--forced only applies to high-risk ADRs (a forced low-risk decision is just... a decision)"
  [ -n "$scope" ] && [ "$scope" != process ] && die "--scope only accepts 'process'"
  [ -f "$TEMPLATE" ] || die "missing $TEMPLATE"

  local num slugged file status date blocks_md
  num=$(next_number)
  slugged=${slug:-$(slugify "$title")}
  file="$ADR_DIR/$num-$slugged.md"
  date=$(date -u +%F)
  if [ "$risk" = low ]; then status=accepted
  elif [ "$forced" = 1 ]; then status=proposed-implemented
  else status=proposed; fi
  if [ -n "$blocks" ]; then blocks_md="#$blocks"; else blocks_md="— (recorded after the fact)"; fi

  echo "adr: $file (risk=$risk, status=$status)"
  if [ "$DRY" = 1 ]; then
    echo "DRY RUN: would render $TEMPLATE -> $file"
  else
    ADR_NUM="$num" ADR_TITLE="$title" ADR_RISK="$risk" ADR_STATUS="$status" \
    ADR_DATE="$date" ADR_BLOCKS="$blocks_md" ADR_SCOPE="$scope" \
    perl -pe '
      s/^# ADR NNNN — TITLE$/# ADR $ENV{ADR_NUM} — $ENV{ADR_TITLE}/;
      s/^- \*\*Status:\*\* .*/- **Status:** $ENV{ADR_STATUS}/;
      s/^- \*\*Risk:\*\* .*/- **Risk:** $ENV{ADR_RISK}\n- **Scope:** $ENV{ADR_SCOPE}/ if $ENV{ADR_SCOPE};
      s/^- \*\*Risk:\*\* .*/- **Risk:** $ENV{ADR_RISK}/;
      s/^- \*\*Date:\*\* .*/- **Date:** $ENV{ADR_DATE}/;
      s/^- \*\*Issue:\*\* .*/- **Issue:** (pending)/;
      s/^- \*\*Blocks:\*\* .*/- **Blocks:** $ENV{ADR_BLOCKS}/;
    ' "$TEMPLATE" > "$file"
  fi

  if [ "$make_issue" = 1 ]; then
    local body issue_url issue_no gate risk_label_extra=()
    if [ "$risk" = high ] && [ "$forced" = 1 ]; then
      gate=$(cat <<EOF
## Human gate (at merge — forced decision, ADR 0013 path)

This was a **forced** decision: the status quo was not buildable, the agent had
a clear recommendation, and the change is reversible in one PR. The
recommendation is **implemented in the PR** with Status \`proposed-implemented\`,
which still fails CI — so nothing merges until you rule. Read \`$file\`, then:

- **approve** — add the \`adr-approved\` label to this issue, then:
  \`scripts/adr.sh accept $num\` (in the PR branch); CI goes green.
- **reject** — close this issue saying what to do instead; the revert is one PR
  by construction.
EOF
)
    elif [ "$risk" = high ]; then
      gate=$(cat <<EOF
## Human gate

Build is **stopped** on this decision. Read \`$file\`, then either:

- **approve** — add the \`adr-approved\` label to this issue, then on resume:
  \`scripts/adr.sh accept $num\`
- **reject** — close this issue with a comment saying what to do instead, and
  delete \`$file\`. A \`proposed\` high-risk ADR fails CI, so it cannot ride a merge.
EOF
)
    else
      gate=$(cat <<EOF
## Auto-approved

Low risk — recorded, not gated. This issue is closed on creation; the ADR file
and its \`$ARCH\` decision-log row ship in the work PR.
EOF
)
      risk_label_extra=(--label adr-approved)
    fi
    body=$(cat <<EOF
## ADR file

\`$file\`

## Decision

$title

## Risk

**$risk** — classified against the rubric in \`$ADR_DIR/README.md\`; the rubric
line is cited in the ADR file.

## What this blocks

- $blocks_md

$gate
EOF
)
    if [ "$DRY" = 1 ]; then
      echo "DRY RUN: would open issue 'ADR $num: $title' with labels adr, adr-$risk${risk_label_extra[*]:+, adr-approved}"
    else
      cmd_labels >/dev/null
      issue_url=$(gh issue create --title "ADR $num: $title" \
        --label adr --label "adr-$risk" ${risk_label_extra+"${risk_label_extra[@]}"} \
        --body "$body")
      issue_no=${issue_url##*/}
      echo "adr: issue $issue_url"
      set_field "$file" Issue "#$issue_no"
      if [ "$risk" = low ]; then
        gh issue close "$issue_no" --comment "Auto-approved (low risk). The ADR ships in the work PR." >/dev/null
        echo "adr: issue #$issue_no closed (record only)"
      fi
    fi
  elif [ "$DRY" != 1 ]; then
    set_field "$file" Issue "— (no issue: recorded in the work PR only)"
  fi

  if [ "$risk" = high ] && [ "$forced" = 1 ]; then
    cat <<EOF

FORCED DECISION — high-risk ADR $num, gate at merge (ADR 0013).
  1. Fill in $file — argue the recommendation; cite why all three forced
     conditions hold (status quo unbuildable, clear recommendation, one-PR revert).
  2. IMPLEMENT the recommendation, with its tests, in this PR.
  3. CI stays red until a human rules ('proposed-implemented' fails check).
     Say in the PR body which ADR gates the merge.
EOF
  elif [ "$risk" = high ]; then
    cat <<EOF

HUMAN GATE — high-risk ADR $num.
  1. Fill in $file (context, decision, alternatives, rubric line, consequences).
  2. STOP this line of work. Do not implement the decision.
  3. Flip the blocked issue's board card to Human Review, finish any independent
     work, and say plainly what you left undone.
EOF
  else
    cat <<EOF

Next: fill in $file, then add one row to the $ARCH decision log:
  scripts/adr.sh accept $num --force   # low risk: adds the row, nothing to approve
EOF
  fi
}

# ---- accept ----------------------------------------------------------------
cmd_accept() {
  local num="" force=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --force) force=1; shift ;;
      *) num="$1"; shift ;;
    esac
  done
  [ -n "$num" ] || die "accept needs an ADR number (e.g. 0003)"
  num=$(printf '%04d' "$((10#$num))")
  local file risk issue date title
  file=$(adr_file "$num")
  risk=$(field "$file" Risk)
  issue=$(field "$file" Issue)
  title=$(sed -n '1s/^# ADR [0-9]* — //p' "$file")
  date=$(date -u +%F)

  local issue_no=""
  case "$issue" in \#[0-9]*) issue_no=${issue#\#}; issue_no=${issue_no%%[^0-9]*} ;; esac

  if [ "$risk" = high ] && [ "$force" != 1 ]; then
    [ -n "$issue_no" ] || die "ADR $num has no linked issue — cannot check approval (use --force only if you are the human)"
    local approved
    approved=$(gh issue view "$issue_no" --json labels --jq '[.labels[].name] | contains(["adr-approved"])')
    [ "$approved" = true ] || die "ADR $num is not approved — issue $issue lacks the 'adr-approved' label. This is the human gate; do not --force it."
    # Process ADRs need a SECOND human: the approver must not be the proposer
    # (multi-human repos only — solo repos have no other human to ask).
    if [ "$(field "$file" Scope)" = process ] && [ -f pairing.json ] && command -v jq >/dev/null 2>&1 \
       && [ "$(jq -r '.humans | length' pairing.json)" -gt 1 ]; then
      local author approver
      author=$(gh issue view "$issue_no" --json author --jq .author.login)
      approver=$(gh api "repos/{owner}/{repo}/issues/$issue_no/events" \
        --jq '[.[] | select(.event == "labeled" and .label.name == "adr-approved")] | last | .actor.login' 2>/dev/null || echo "")
      if [ -n "$approver" ] && [ "$approver" = "$author" ]; then
        die "ADR $num is a process ADR: the adr-approved label must be applied by a human other than the proposer ($author). Ask the other human to rule."
      fi
    fi
  fi

  set_field "$file" Status accepted
  # one row in the decision log, inserted after the last dated row
  local row tmp last
  row="| $date | $title | ADR $num — \`$file\` |"
  if [ "$DRY" = 1 ]; then
    echo "DRY RUN: would insert into $ARCH: $row"
  else
    grep -q -F "ADR $num — " "$ARCH" && die "ADR $num already has a decision-log row in $ARCH"
    last=$(grep -n '^| 20[0-9][0-9]-' "$ARCH" | tail -1 | cut -d: -f1)
    [ -n "${last:-}" ] || die "no decision-log rows found in $ARCH — insert the row by hand"
    tmp=$(mktemp)
    awk -v n="$last" -v row="$row" 'NR==n {print; print row; next} {print}' "$ARCH" > "$tmp"
    mv "$tmp" "$ARCH"
  fi
  echo "adr: $num accepted; decision-log row added to $ARCH"

  if [ -n "$issue_no" ]; then
    run gh issue close "$issue_no" --comment "Approved and accepted. Decision recorded in \`$file\` and the $ARCH decision log." >/dev/null || true
    echo "adr: issue #$issue_no closed"
  fi
}

# ---- check (offline — this is the CI gate) ---------------------------------
cmd_check() {
  local bad=0 f status
  for f in "$ADR_DIR"/[0-9][0-9][0-9][0-9]-*.md; do
    [ -e "$f" ] || continue
    [ "$(field "$f" Risk)" = high ] || continue
    status=$(field "$f" Status)
    case "$status" in
      proposed)
        echo "BLOCKED: $f is a high-risk ADR still 'proposed' — a human must approve it before this line of work resumes (docs/adr/README.md)"
        bad=1 ;;
      proposed-implemented)
        echo "BLOCKED: $f is 'proposed-implemented' — the forced decision is built and riding this PR; a human must accept or reject it before merge (ADR 0013)"
        bad=1 ;;
    esac
  done
  [ "$bad" = 0 ] && echo "adr: no unapproved high-risk ADRs"
  return "$bad"
}

# ---- pending ---------------------------------------------------------------
cmd_pending() {
  local blocked="${1:-}" jq
  jq='[.[] | select(([.labels[].name] | contains(["adr-approved"])) == false)'
  [ -n "$blocked" ] && jq="$jq | select(.body | test(\"Blocks #$blocked\\\\b\"))"
  jq="$jq | \"#\\(.number) \\(.title)\"] | .[]"
  gh issue list --state open --label adr --label adr-high \
    --json number,title,labels,body --jq "$jq"
}

# ---- dispatch --------------------------------------------------------------
ARGS=()
for a in "$@"; do
  case "$a" in --dry-run) DRY=1 ;; *) ARGS+=("$a") ;; esac
done
set -- ${ARGS+"${ARGS[@]}"}
[ $# -gt 0 ] || usage
CMD="$1"; shift
case "$CMD" in
  new)     cmd_new "$@" ;;
  accept)  cmd_accept "$@" ;;
  check)   cmd_check ;;
  pending) cmd_pending "$@" ;;
  labels)  cmd_labels ;;
  -h|--help) usage ;;
  *) die "unknown command: $CMD" ;;
esac
