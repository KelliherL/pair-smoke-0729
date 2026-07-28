import { readFileSync } from 'node:fs'
import { describe, expect, it } from 'vitest'
import { MAX_WRONG, type GameState, type GuessResult, type Phase } from './types.js'
import { WORDS } from './words.js'

describe('foundation invariants (issue #4, pinned per PR #10 verdict)', () => {
  it('word list: >=20 words, 4-9 letters, lowercase ascii, unique', () => {
    expect(WORDS.length).toBeGreaterThanOrEqual(20)
    for (const w of WORDS) expect(w).toMatch(/^[a-z]{4,9}$/)
    expect(new Set(WORDS).size).toBe(WORDS.length)
  })

  it('rules constants are frozen', () => {
    expect(MAX_WRONG).toBe(8)
  })

  it('types module is pure: zero imports, zero side effects (ADR 0002)', () => {
    const src = readFileSync(new URL('./types.ts', import.meta.url), 'utf8')
    const code = src.replace(/\/\/[^\n]*/g, '').replace(/\/\*[\s\S]*?\*\//g, '')
    expect(code).not.toMatch(/\bimport\b|\brequire\b|\bfs\b|\breadline\b/)
  })

  it('the frozen shapes are exactly as declared (ADR 0002)', () => {
    const s: GameState = { word: 'test', guessed: ['t'], remaining: MAX_WRONG, phase: 'playing' }
    const r: GuessResult = { state: s, outcome: 'hit' }
    expect(r.outcome).toBe('hit')
    // Phase is the closed union, not string — widening breaks this line:
    // @ts-expect-error — 'flying' is not a Phase
    const bad: Phase = 'flying'
    expect(bad).toBe('flying')
    // guessed is readonly — mutation breaks this line:
    // @ts-expect-error — readonly array has no push
    s.guessed.push('x')
  })

  it('strict compiler settings are pinned', () => {
    const tsconfig = JSON.parse(readFileSync(new URL('../../../tsconfig.json', import.meta.url), 'utf8'))
    expect(tsconfig.compilerOptions.strict).toBe(true)
  })
})
