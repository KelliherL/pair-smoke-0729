# Testing notes — traps that have already cost us time

Not a style guide. Every entry here is a mistake that actually happened in
this repo (or was inherited from the kit's source project), with the cost
named. Add entries via the retro skill; delete nothing.

## 1. Prove a test can fail before trusting it

A suite that stays green with the behaviour broken is pinning nothing. For
every invariant worth having, break it once, watch the suite go red, restore.
(Inherited: the kit's source project shipped two correct-but-unpinned
invariants in one PR; the whole 190-test suite passed with either reverted.
Only mutation testing caught it.)

## 2. Fake timers: walk the clock one interval at a time

Advancing a large jump in one call silently runs only the first scheduled
timer when each next timer is only scheduled after a commit. Step the clock
interval-by-interval and assert between steps. (Inherited: cost a debug
detour on a paced-playback feature.)
