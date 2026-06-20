# Iteration 3 — Production Pipeline & Public Demo

> Status: `not-started`
> Source: doc02 §10 阶段1 ("制作管线与公开试玩")
> Business gate: **Gate C — Commercial** (doc02 §14). Continue to 120-level production only if the demo
> clearly conveys the loop, builds wishlists, and gets positive feedback.
> Depends on: iteration 2 `done`

## Goal

Turn the vertical slice into a polished **20–30 minute free public demo** with a real store presence.

## Scope

### In
- Prologue + first half of QED as a self-contained demo.
- Settings, save, gamepad, small-screen (Steam Deck class), basic accessibility.
- Store page, trailer, GIFs, a feedback channel.
- Demo save carries over to the full game (doc02 §10 阶段1).

### Out (deferred)
- Weak/QCD/loops/Higgs content; Workshop; mobile.

## Phase 1 — Discussion (produces `prompts/`)
- Cut/curation of which slice levels become the demo arc.
- Save-carryover format and settings/accessibility matrix.
- Gamepad + small-screen input mapping and safe-area rules.
- Store-asset production plan (trailer beats, muted-readable GIFs) and feedback funnel.

## Phase 2 — Implementation
- **Code:** settings/save hardening, gamepad + Steam Deck input, accessibility options, demo build config.
- **Art/human:** trailer, store screenshots/GIFs, demo onboarding polish.
- **Tests:** save-carryover round-trip; input parity across mouse/gamepad/touch; multi-resolution.

## Phase 3 — Acceptance
- Public demo metrics review (doc02 §15 试玩期).
- Exit criteria / **Gate C**:
  - Demo completion rate, satisfaction, and wishlist conversion hit internal targets.
  - Store media communicates "drag curve → particles flow → diagram closes".
  - Players don't broadly mistake it for professional software or pure edutainment.
- Feedback-driven fixes only. Passing unlocks full-content production (iteration 4).
