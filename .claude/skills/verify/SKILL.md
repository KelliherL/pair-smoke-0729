---
name: verify
description: Adversarial verification of another human's PR — plan vs tests vs code, with mandatory falsification. Default path is the async codex script; this skill is the checklist codex receives AND the interactive fallback.
---

# Verify one PR

**Default path:** `scripts/verify.sh run <pr>` — claims the PR, spawns codex
asynchronously (cross-vendor by construction), posts the verdict from a
background worker. You normally do NOT run this skill interactively; you fire
the script and keep working. Run it yourself only when the script exits 3
(codex missing) or a human asks for a hand-verify.

You did not write this code; your job is to find what is wrong with it, not
to approve it. Never verify your own human's PR (solo mode excepted, and it
is bannered).

0. **Claim it first:** `scripts/verify.sh claim <pr>`. Without a claim, a
   merge can race the pass — that has happened twice (ADR 0014). Do not merge
   a PR with an open claim.
1. Read the linked issue, its `## Plan` comment, the PR diff, and the tests.
2. Check, in order:
   - **Correct:** does the code do what the plan and the issue's acceptance
     criteria say? Check the issue's declared **File surface** — changes
     outside it are a finding.
          Walk the hangman rules against the diff: masking correctness, repeat
     and invalid guesses, guess-limit boundaries, win/lose timing, save-file
     corruption fallback, and engine purity (no IO inside `src/lib/engine/`).
   - **Tested:** do the tests pin the behaviour, or pass vacuously? Name
     missing adversarial cases and add or demand them.
   - **Falsifiable (highest-yield check on this list):** for each invariant
     the PR claims, break it, re-run the suite, and confirm it goes red. A
     green suite with the behaviour broken is a finding — report it and add
     the pinning test. Restore the code before reporting.
   - **Recorded:** hold the diff against `docs/adr/README.md`'s rubric. Every
     decision a stranger would ask "why?" about has an ADR; a decision the
     build classified low that the rubric puts high is a **fix-first
     finding** — that is the gate being routed around, whether or not the
     code is good.
3. Run everything yourself — typecheck, tests, `scripts/adr.sh check` — and
   show real output. Never take the build session's word for anything.
4. Verdict in a PR comment whose first line is `## Verify verdict`, with an
   explicit `VERDICT: merge` or `VERDICT: fix-first` call, findings ranked by
   severity with file/line. Nit-free approval is allowed to be short.

Fixes go back through build (trivial, test-covered ones may be done here —
note them). Merge is the human's call, and only after the verdict when the PR
touches anything in AGENTS.md's verdict-required table.

> Draft skill — every retro should improve it or extract a step into a script.
