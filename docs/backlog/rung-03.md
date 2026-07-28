Ladder position: 3 of epic #3. Depends on: 1.

## Goal

.hangman-save.json {schemaVersion,state}: round-trip every phase; corrupt/missing/wrong-version -> fresh, never throw

## File surface

- Creates/Modifies: src/lib/save.ts, src/lib/save.test.ts

## Out of scope

- Everything owned by the other rungs of epic #3 (see the ladder).

## Acceptance criteria

- [ ] .hangman-save.json {schemaVersion,state}: round-trip every phase; corrupt/missing/wrong-version -> fresh, never throw
- [ ] Suite + typecheck green with real output; adr.sh check clean

## Loop

- [ ] Planned  - [ ] Building  - [ ] Verifying  - [ ] Human Review
