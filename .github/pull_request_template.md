<!--
One PR = one issue = one pass of the loop. Delete comment blocks before
posting. If this PR carries a `proposed-implemented` ADR, say so up top: CI
is red on purpose until a human rules.
-->

Closes #

## What changed

<!-- What a reviewer needs to know before reading the diff. Not a file list. -->

## Against the plan

- [ ] Built what the `## Plan` comment said, including the tests it named
- [ ] Stayed inside the issue's declared File surface (or the coordination
      comment exists on the issue)
- [ ] Deviations (if any) recorded as an issue comment, with evidence

## Checks

- [ ] `npx tsc --noEmit` clean
- [ ] `npm test` green — full suite, run locally, not assumed
- [ ] `scripts/adr.sh check` clean (or red only by a declared
      `proposed-implemented` ADR)
- [ ] Engine code imports no IO and no CLI modules
- [ ] Game state changes only via the engine API
- [ ] `.hangman-save.json` shape still matches `docs/architecture.md`

<!-- Paste the real test output. "Tests pass" is not evidence. -->

```

```

## Architecture decisions

<!-- ADRs this PR carries, or "none". A forced decision rides here as
     proposed-implemented and gates the merge. -->

## For verify

<!-- Written by the build side, for the adversarial async pass that follows.
     Where is this weakest? What did you rush? What invariants should the
     verifier try to falsify first? A blank here wastes the cross-vendor read. -->
