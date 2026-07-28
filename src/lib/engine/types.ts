// Frozen by the foundation rung (issue #4): later rungs FILL these shapes,
// they never widen them (the foundation-rung rule — this file is the shared
// surface every parallel rung reads).
export type Phase = 'playing' | 'won' | 'lost'

export interface GameState {
  readonly word: string            // the secret, lowercase
  readonly guessed: readonly string[] // lowercase letters, in guess order
  readonly remaining: number       // wrong guesses left (starts at 8)
  readonly phase: Phase
}

export type GuessOutcome = 'hit' | 'miss' | 'repeat' | 'invalid'

export interface GuessResult {
  readonly state: GameState
  readonly outcome: GuessOutcome
}

export const MAX_WRONG = 8
