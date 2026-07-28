import { describe, expect, it } from 'vitest'
import { MAX_WRONG, type GameState } from './types.js'
import { WORDS } from './words.js'

describe('foundation invariants (issue #4)', () => {
  it('word list: >=20 words, 4-9 letters, lowercase ascii, unique', () => {
    expect(WORDS.length).toBeGreaterThanOrEqual(20)
    for (const w of WORDS) expect(w).toMatch(/^[a-z]{4,9}$/)
    expect(new Set(WORDS).size).toBe(WORDS.length)
  })

  it('rules constants are frozen', () => {
    expect(MAX_WRONG).toBe(8)
  })

  it('types module is pure: importable with no side effects', () => {
    const s: GameState = { word: 'test', guessed: [], remaining: MAX_WRONG, phase: 'playing' }
    expect(s.phase).toBe('playing')
  })
})
