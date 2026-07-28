#!/usr/bin/env bash
# verify.sh — asynchronous cross-vendor verification of one PR via codex
# (ADR 0010 + ADR 0014). The claim comment is the lock, the verdict comment is
# the contract, and the wrapper does ALL network I/O — codex runs sandboxed
# with no network and is never trusted to post anything itself.
#
# Usage:
#   scripts/verify.sh run <pr> [--mode diff|full] [--model M] [--timeout MIN]
#                              [--wait] [--allow-self] [--reclaim] [--dry-run]
#   scripts/verify.sh claim <pr>     # manual claim (interactive-skill fallback)
#   scripts/verify.sh release <pr>   # post '## Verify aborted' (stale-claim cleanup)
#   scripts/verify.sh status <pr>    # claim state + latest log tail
#
# run exits: 0 spawned (with --wait: verdict posted) · 2 precondition failed
#            3 codex missing (fall back to the interactive verify skill)
#            4 gh/auth failure
# Worker outcomes are NEVER encoded in exit codes — read the PR comments.
#
# Codex invocation facts this script is built on (live-verified previously):
# prompt on stdin THEN CLOSED (an open stdin pipe hangs codex forever; argv
# prompts are a shell-quoting injection risk); verdict = text of the last
# item.completed/agent_message before turn.completed; exit codes are
# untrustworthy; workspace-write sandbox has no network.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
# shellcheck source=lib.sh
. scripts/lib.sh

LOG_DIR=.pair/logs
mkdir -p "$LOG_DIR"

usage() { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

marker_claim="## Verify in progress"
marker_verdict="## Verify verdict"
marker_abort="## Verify aborted"

post_claim() { # $1=pr $2=mode $3=model
  gh pr comment "$1" --body "$marker_claim

- Verifier: \`$PF_LOGIN\` on \`$(hostname)\`
- Mode: $2 · Model: $3 · Codex: $(codex --version 2>/dev/null | head -1 || echo 'n/a')
- Started: $(date -u +%FT%TZ)
- Do not merge while this claim is open (AGENTS.md / ADR 0014). Stale? \`scripts/verify.sh release $1\`.

<!-- pf:verify-claim -->" >/dev/null
}

post_abort() { # $1=pr $2=reason $3=log
  gh pr comment "$1" --body "$marker_abort

$2

Log: \`$3\` on \`$(hostname)\`. The claim is released — this PR re-queues for verify.
No verdict was synthesized: a failed pass is a failed pass." >/dev/null || true
}

# ---- subcommand: claim / release / status -----------------------------------
cmd_claim() { post_claim "$1" manual "-"; echo "claimed PR #$1 (manual)"; }

cmd_release() {
  post_abort "$1" "Claim released manually (\`verify.sh release\`)." "-"
  echo "released PR #$1"
}

cmd_status() {
  echo "PR #$1 claim state: $(pf_claim_state "$1")"
  local log
  log=$(ls -t "$LOG_DIR"/verify-pr"$1"-*.log 2>/dev/null | head -1) || true
  if [ -n "${log:-}" ]; then
    echo "latest log: $log"
    tail -5 "$log" | sed 's/^/  | /'
  else
    echo "no local logs for this PR"
  fi
}

# ---- subcommand: run ---------------------------------------------------------
cmd_run() {
  local pr="" mode model timeout wait=0 allow_self=0 reclaim=0 dry=0
  mode=$(pf_cfg '.verify.mode // "diff"')
  model=$(pf_cfg '.verify.model // "gpt-5.6-terra"')
  timeout=$(pf_cfg '.verify.timeoutMinutes // 15')
  while [ $# -gt 0 ]; do
    case "$1" in
      --mode)       mode="${2:?}"; shift 2 ;;
      --model)      model="${2:?}"; shift 2 ;;
      --timeout)    timeout="${2:?}"; shift 2 ;;
      --wait)       wait=1; shift ;;
      --allow-self) allow_self=1; shift ;;
      --reclaim)    reclaim=1; shift ;;
      --dry-run)    dry=1; shift ;;
      *)            pr="$1"; shift ;;
    esac
  done
  [ -n "$pr" ] || usage
  case "$mode" in diff|full) ;; *) pf_die "mode must be diff or full" ;; esac

  # Preconditions
  local author state
  read -r author state < <(gh pr view "$pr" --json author,state \
    --jq '"\(.author.login) \(.state)"') || exit 4
  [ "$state" = "OPEN" ] || { echo "PR #$pr is $state — nothing to verify"; exit 2; }
  if [ "$author" = "$PF_LOGIN" ] && [ "$allow_self" != 1 ]; then
    if pf_solo; then
      echo "SOLO MODE: self-verifying own PR #$pr (cross-vendor only — a different"
      echo "model reviews it, but the same human drives. Bannered in the verdict.)"
    else
      pf_die "PR #$pr is your own — the other pair verifies (ADR 0010). Use --allow-self only if a human said so."
    fi
  fi
  local claim_state
  claim_state=$(pf_claim_state "$pr")
  if [ "$claim_state" = claimed ] && [ "$reclaim" != 1 ]; then
    echo "PR #$pr is already claimed (scripts/verify.sh status $pr). Use --reclaim to take over a stale claim."
    exit 2
  fi
  if [ "$claim_state" = verdict ]; then
    echo "PR #$pr already has a verdict."
    exit 2
  fi
  if ! command -v codex >/dev/null 2>&1; then
    echo "codex not found — fall back to the interactive verify skill:"
    echo "  1) scripts/verify.sh claim $pr"
    echo "  2) follow .claude/skills/verify/SKILL.md yourself"
    exit 3
  fi

  if [ "$dry" = 1 ]; then
    echo "DRY RUN: would claim PR #$pr and spawn codex ($mode, $model, ${timeout}m)"
    exit 0
  fi

  post_claim "$pr" "$mode" "$model"
  local log="$LOG_DIR/verify-pr$pr-$(date +%s).log"
  if [ "$wait" = 1 ]; then
    worker "$pr" "$mode" "$model" "$timeout" "$log"
  else
    # Detach fully: all three fds redirected, disowned — the verdict must land
    # even if the launching shell (or the agent session that ran it) dies.
    nohup bash "$0" --worker "$pr" "$mode" "$model" "$timeout" "$log" \
      </dev/null >>"$log" 2>&1 &
    disown
    echo "verify spawned for PR #$pr (pid $!, mode $mode) — log: $log"
    echo "verdict will be posted to the PR; check: scripts/verify.sh status $pr"
  fi
}

# ---- the worker ---------------------------------------------------------------
worker() { # $1=pr $2=mode $3=model $4=timeout-min $5=log
  local pr="$1" mode="$2" model="$3" timeout_min="$4" log="$5"
  local effort workdir prompt_file ndjson diff_file
  effort=$(pf_cfg '.verify.reasoningEffort // "high"')
  workdir="$LOG_DIR/pr$pr-work"
  mkdir -p "$workdir"
  prompt_file="$workdir/prompt.md"
  ndjson="$workdir/codex.ndjson"
  diff_file="$workdir/pr.diff"

  echo "[worker] PR #$pr mode=$mode model=$model effort=$effort timeout=${timeout_min}m"

  # 1. Gather context — all network here, none inside codex.
  local pr_json title body issue_no issue_ctx plan
  pr_json=$(gh pr view "$pr" --json title,body,headRefName) || { post_abort "$pr" "Failed to read the PR via gh." "$log"; return; }
  title=$(echo "$pr_json" | jq -r .title)
  body=$(echo "$pr_json" | jq -r .body)
  issue_no=$(echo "$body" | grep -oiE 'closes #[0-9]+' | head -1 | grep -oE '[0-9]+') || issue_no=""
  issue_ctx="(no linked issue found in the PR body)"
  plan="(no plan comment found)"
  if [ -n "$issue_no" ]; then
    issue_ctx=$(gh issue view "$issue_no" --json title,body --jq '"# Issue #\(.title)\n\n\(.body)"' 2>/dev/null) || issue_ctx="(issue #$issue_no unreadable)"
    plan=$(gh issue view "$issue_no" --json comments \
      --jq '[.comments[].body | select(startswith("## Plan"))] | last // "(no plan comment found)"' 2>/dev/null) || true
  fi
  gh pr diff "$pr" > "$diff_file" || { post_abort "$pr" "Failed to fetch the PR diff via gh." "$log"; return; }

  # 2. Full mode: self-contained local clone (NOT a git worktree — a worktree's
  #    .git pointer escapes the sandbox root) with setup run OUT here.
  local clone="" sandbox="read-only" cd_flag=()
  if [ "$mode" = full ]; then
    clone="$PF_ROOT/.pair/clones/pr$pr"
    rm -rf "$clone"
    git clone --local --no-hardlinks . "$clone" >/dev/null 2>&1 || { post_abort "$pr" "Local clone failed." "$log"; return; }
    git -C "$clone" fetch -q origin "pull/$pr/head" && git -C "$clone" checkout -q FETCH_HEAD \
      || { post_abort "$pr" "Could not check out PR #$pr head in the clone." "$log"; rm -rf "$clone"; return; }
    local setup_cmd
    setup_cmd=$(pf_cfg '.commands.setup // empty')
    if [ -n "$setup_cmd" ]; then
      echo "[worker] running setup in clone: $setup_cmd"
      (cd "$clone" && eval "$setup_cmd") >>"$log" 2>&1 || { post_abort "$pr" "Setup command failed in the verification clone (\`$setup_cmd\`)." "$log"; rm -rf "$clone"; return; }
    fi
    sandbox="workspace-write"
    cd_flag=(-C "$clone")
  fi

  # 3. Compose the prompt: static instruction template + dynamic context.
  {
    sed -e "s|{{TEST_CMD}}|$(pf_cfg '.commands.test // "npm test"')|g" \
        -e "s|{{TYPECHECK_CMD}}|$(pf_cfg '.commands.typecheck // "true"')|g" \
        "scripts/verify-prompt-$mode.md"
    echo
    echo "--- PR #$pr: $title ---"
    echo "$body"
    echo
    echo "--- Linked issue ---"
    echo "$issue_ctx"
    echo
    echo "--- Plan comment ---"
    echo "$plan"
    if [ "$mode" = diff ]; then
      echo
      echo "--- DIFF ---"
      cat "$diff_file"
    else
      echo
      echo "--- Changed files (the diff is applied in your working directory) ---"
      gh pr diff "$pr" --name-only
    fi
  } > "$prompt_file"

  # 4. Spawn codex: stdin from FILE (then naturally closed), NDJSON to file.
  local start deadline codex_pid
  start=$(date +%s)
  deadline=$((start + timeout_min * 60))
  codex exec --json --ephemeral --skip-git-repo-check \
    -s "$sandbox" ${cd_flag+"${cd_flag[@]}"} \
    -m "$model" -c "model_reasoning_effort=\"$effort\"" - \
    < "$prompt_file" > "$ndjson" 2>>"$log" &
  codex_pid=$!
  echo "[worker] codex pid $codex_pid"

  while kill -0 "$codex_pid" 2>/dev/null; do
    if [ "$(date +%s)" -ge "$deadline" ]; then
      echo "[worker] TIMEOUT after ${timeout_min}m — killing tree"
      case "$OSTYPE" in
        msys*|cygwin*) taskkill //pid "$codex_pid" //T //F >/dev/null 2>&1 || true ;;
        *)             kill -TERM -- -"$codex_pid" 2>/dev/null || kill -TERM "$codex_pid" 2>/dev/null || true ;;
      esac
      post_abort "$pr" "Verification timed out after ${timeout_min} minutes and the codex process tree was killed." "$log"
      [ -n "$clone" ] && rm -rf "$clone"
      return
    fi
    sleep 5
  done
  wait "$codex_pid" 2>/dev/null || true   # exit code is untrustworthy — ignore it

  # 5. Parse fail-closed: verdict only if a clean terminal event exists.
  local terminal verdict_text duration
  terminal=$(jq -rs '
    [.[] | select(.type == "turn.failed")] as $f
    | [.[] | select(.type == "turn.completed")] as $c
    | if ($f | length) > 0 then "failed"
      elif ($c | length) > 0 and (($c | last | has("error")) | not) then "completed"
      else "none" end' "$ndjson" 2>/dev/null) || terminal=none
  verdict_text=$(jq -rs '
    [.[] | select(.type == "item.completed" and .item.type == "agent_message") | .item.text]
    | last // ""' "$ndjson" 2>/dev/null) || verdict_text=""
  duration=$(( $(date +%s) - start ))

  [ -n "$clone" ] && rm -rf "$clone"

  if [ "$terminal" != completed ] || [ -z "$verdict_text" ]; then
    post_abort "$pr" "Codex run did not produce a clean verdict (terminal state: $terminal). NDJSON kept at \`$ndjson\`." "$log"
    return
  fi

  # 6. Post the verdict — wrapper's gh, codex never touches the network.
  local self_note=""
  [ "$(gh pr view "$pr" --json author --jq .author.login)" = "$PF_LOGIN" ] \
    && self_note="
> ⚠ SOLO/SELF-VERIFY: same human, different model. Cross-vendor holds; cross-human does not."
  gh pr comment "$pr" --body "$marker_verdict
$self_note
_${mode} mode · $model ($effort) · $((duration / 60))m$((duration % 60))s · verifier \`$PF_LOGIN\` · via scripts/verify.sh_

$verdict_text" >/dev/null \
    && echo "[worker] verdict posted to PR #$pr (${duration}s)" \
    || post_abort "$pr" "Codex produced a verdict but posting it failed; text is in \`$ndjson\`." "$log"
}

# ---- dispatch -----------------------------------------------------------------
[ $# -gt 0 ] || usage
case "$1" in
  run)      shift; cmd_run "$@" ;;
  claim)    shift; cmd_claim "${1:?claim needs a PR number}" ;;
  release)  shift; cmd_release "${1:?release needs a PR number}" ;;
  status)   shift; cmd_status "${1:?status needs a PR number}" ;;
  --worker) shift; worker "$@" ;;
  -h|--help) usage ;;
  *) usage ;;
esac
