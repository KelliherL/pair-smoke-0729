---
name: retro
description: Run a retrospective over the work since the last retro and land the findings as repo artifacts — a retro doc, proposed process ADRs, and issues. Use at epic boundaries or whenever the loop felt slow or broke.
---

# Retro

The loop throws away context on purpose, so a retro that lives only in a
session is a retro you lose. Everything this skill produces is a **repo
artifact**.

1. **Gather the record** since the last `docs/retros/*.md` (or the repo's
   start): merged and closed PRs (`gh pr list --state merged`), their verify
   verdicts and aborts, issues opened/closed, ADRs raised (and how long the
   gated ones waited), Session log comments, CI failures.
2. **Write `docs/retros/YYYY-MM-DD-<epic-or-period>.md`** with exactly these
   sections (the shape is the tool — do not improvise a new one):
   - *What the work was* — one paragraph, with the artifact counts.
   - *What went wrong* — numbered, each one concrete and evidenced (link the
     PR/issue/comment). No vibes.
   - *Root causes* — lettered; a wrong-ness is a symptom, a root cause is a
     property of the process that produced it.
   - *What worked well — do not break these* — named explicitly, so a future
     "improvement" doesn't delete a load-bearing habit.
   - *Decisions taken from this retro* — a table: decision | mechanism
     (ADR / issue / doc edit) | status.
3. **Land the decisions by kind:**
   - Process changes (AGENTS.md, skills, scripts, CI, templates) →
     `scripts/adr.sh new --risk high --scope process --title "..."` — one ADR
     per decision, each carrying its **intended diff** in a fenced block.
     Process ADRs need approval from a human other than the proposer; you
     write them and stop.
   - Mechanical fixes (a missing check, a wrong doc line) → issues, or land
     them with the retro PR if they are low-risk and tested.
   - Trap knowledge → append to `docs/testing-notes.md` (every entry must be
     a mistake that actually happened, with the cost named).
4. Open one PR carrying the retro doc + any low-risk fixes; the process ADRs
   ride it as `proposed` (CI stays red until the humans rule — that is the
   gate working, and the PR body must say so).
5. Never land a process change directly, however obvious. The retro proposes;
   humans dispose.

> This skill retros itself: if running it felt wrong, that goes in the doc.
