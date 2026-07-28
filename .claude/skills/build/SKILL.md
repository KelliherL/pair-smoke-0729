---
name: build
description: Execute the posted plan for one backlog issue — code and tests. Use after a plan exists on the issue.
---

# Build one issue

Input: one GitHub issue number (ask if not given). The plan should make this
mechanical.

1. Read the issue **and the `## Plan` comment on it**, plus the PRD it cites
   and `docs/architecture.md`. If there is no plan comment, stop and say so —
   do not improvise one.
2. Work on a branch named for the issue (`issue-N-<slug>`).
3. Implement exactly the plan: the code **and** the tests it names. **Stay
   inside the issue's declared File surface.** Needing a file outside it is a
   coordination event: comment on the issue naming the file, check the other
   rungs in your parallel group, and prefer extending the surface over
   silently editing.
4. Deviating from the plan is allowed only if the plan is wrong in a way the
   code proves; record the deviation in an issue comment.
5. **Record architecture decisions as you make them** — classify with the
   rubric in `docs/adr/README.md`, not from feel. Unsure is high, always.

   ```bash
   scripts/adr.sh new --risk low  --issue <n> --title "..."   # record, keep going
   scripts/adr.sh new --risk high --issue <n> --title "..."   # record, then STOP
   scripts/adr.sh new --risk high --forced --issue <n> --title "..."  # ADR 0013
   ```

   - **Low risk:** fill the file, `scripts/adr.sh accept NNNN --force` for
     the decision-log row, ship both in this PR. Nothing blocks.
   - **High risk:** fill the file, leave it `proposed`, **stop that line of
     work** — do not implement the decision, do not pick "the safe option and
     carry on". Finish what is genuinely independent, flip the card to Human
     Review, and say plainly what you left undone.
   - **High risk, FORCED** (all three: the status quo is unbuildable, you
     have a clear recommendation, one-PR revert): implement the
     recommendation with its tests and ship it — the ADR rides the PR as
     `proposed-implemented`, CI stays red, and the human rules at merge.
     Unsure whether it is forced? It is not. Stop.
6. Green before done: typecheck + full test run, real output shown, plus
   `scripts/adr.sh check`.
7. Commit; open a PR referencing the issue via the template, and list any
   ADRs it carries. Do not merge.

After this, verify belongs to the **other human's side**: their agent (or
their `scripts/verify.sh`) picks the PR up asynchronously. Never verify your
own build.

> Draft skill — every retro should improve it or extract a step into a script.
