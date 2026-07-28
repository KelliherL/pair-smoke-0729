---
name: plan
description: Plan one backlog issue before any code is written. Use when starting a new issue from the backlog.
---

# Plan one issue

Input: one GitHub issue number (ask if not given).

1. Read the issue (including its **File surface** and dependency line), the
   PRD it cites, `docs/architecture.md`, and whatever existing code the
   change touches.
2. Produce a plan: what exists now, what will change (files, functions,
   components — staying inside the declared File surface), the tests that
   will prove it, and anything out of scope. If the plan genuinely needs a
   file outside the surface, say so in the plan — that is a coordination
   event the human should see at approval, not a surprise mid-build.
3. **Write the plan into the GitHub issue as a comment** whose first line is
   `## Plan` — automation gates on that marker. The plan must survive context
   loss; it may not live only in this conversation.
4. **Name the decisions the build will have to make.** Run the rubric in
   `docs/adr/README.md` over your own plan and add a `### Decisions` section
   listing each, marked low or high risk. A high-risk decision you can see
   now should be raised as an ADR *now*, while a human is already reading —
   a gate hit during planning costs nothing; one hit mid-build stops the
   build (unless it is a **forced** decision, ADR-0013 path — say so).
5. Do not write any application code in this session.

Rules of the loop: the owner's agent may proceed straight to the build skill
in the same session — the adversarial fresh-context pass is the *other
human's* async verify of the PR, not a context clear on this machine.

> Draft skill — every retro should improve it or extract a step into a script.
