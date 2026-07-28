# hangman-cli

Terminal hangman with save/resume — and the proving ground for the
[pair-factory](https://github.com/KelliherL/pair-factory) process kit (solo
mode). See `AGENTS.md` for how work happens here; `docs/prd0.md` for what is
being built.

```bash
npm ci
npm test           # Vitest — engine suite
npx tsc --noEmit   # typecheck
node dist/cli.js   # play (after build)
```

Node ≥ 22.12.
