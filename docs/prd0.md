# PRD 0 — hangman-cli core loop

> The pair-factory kit's proving ground: deliberately small, deliberately
> shaped like a real project (pure core, persisted state, a state machine).

## One-liner

Terminal hangman: guess a word letter by letter before the gallows completes;
quit any time and resume exactly where you left off.

## Core loop

1. `hangman` with no save → a random word is chosen from a built-in list; the
   mask (`_ _ _ _`) and remaining-guess count (8) are shown.
2. The player types a single letter: correct → revealed everywhere it
   appears; wrong → remaining guesses decrement; repeat or non-letter input →
   rejected with a message, no penalty.
3. Win: full word revealed. Lose: guesses exhausted (word shown). Either way
   the save is cleared and the game exits with a result line.
4. `Ctrl+C`/quit mid-game → state persists to `.hangman-save.json`; next run
   resumes it. Corrupt or unrecognised save → fresh game, never a crash.

## Rules

8 wrong guesses; case-insensitive; ASCII letters only; the word list ships in
the engine (≥ 20 words, 4–9 letters).

## Non-goals

Multiplayer, difficulty levels, dictionaries, colours/juice, scores.

## Acceptance checklist

- [ ] Full game playable to win and to lose in a real terminal.
- [ ] Repeat and invalid guesses rejected without penalty.
- [ ] Quit mid-game, rerun, resume with identical mask/guesses.
- [ ] Corrupt save falls back to a fresh game without crashing.
- [ ] Engine fully unit-tested incl. boundaries (last guess, last letter).
