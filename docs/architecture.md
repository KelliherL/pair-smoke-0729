# Architecture — hangman-cli

> **Living document.** It holds the overview and the decision log; the
> reasoning for each decision lives in its ADR (`docs/adr/`). Append, don't
> rewrite.

## Overview

Pure engine under src/lib/engine (word masking, guess resolution, win/lose —
no IO, no CLI imports); a single JSON save file managed by src/lib/save.ts
(validate-or-discard); a thin readline CLI in src/cli.ts that only calls the
engine API.

## Decision log

Each accepted ADR gets exactly one row (inserted by `scripts/adr.sh accept`).
The row is the index; the ADR is the record.

| Date | Decision | Why |
|---|---|---|
| 2026-07-29 | Adopt the pair-factory process kit | ADR 0001 — `docs/adr/0001-adopt-pair-factory-process-kit.md` |
| 2026-07-28 | Engine state shape frozen by the foundation rung | ADR 0002 — `docs/adr/0002-engine-state-shape-frozen-by-the-foundation-rung.md` |
| 2026-07-28 | Toolchain dependencies declared at init | ADR 0003 — `docs/adr/0003-toolchain-dependencies-declared-at-init.md` |
| 2026-07-28 | Full-mode verify is experimental until sandboxed execution works | ADR 0004 — `docs/adr/0004-full-mode-verify-is-experimental-until-sandboxed-execution.md` |
