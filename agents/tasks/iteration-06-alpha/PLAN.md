# Iteration 6 — Alpha (Content Complete)

> Status: `not-started`
> Source: doc02 §10 阶段4 ("Alpha")
> Business gate: —
> Depends on: iteration 5 `done`

## Goal

Content is complete. **Stop adding systems**; unify, cut, and balance. This is a consolidation
iteration, not a feature iteration.

## Scope

### In
- All ~120–160 levels completable end to end.
- Unify hints, terminology, visual semantics, and the difficulty curve across all chapters.
- Automated regression, gamepad, Steam Deck class, multi-resolution coverage.
- Full science-advisor review pass.

### Out (frozen)
- Any new mechanic or theory; no QCD/loop rule changes (doc02 §10 阶段5 note). UGC/Workshop.

## Phase 1 — Discussion (produces `prompts/`)
- Consistency audit checklist (hint wording, term glossary, line semantics, difficulty bands).
- Regression-suite coverage targets and the cut list (which levels get removed).
- Multi-input / multi-resolution test matrix.

## Phase 2 — Implementation
- **Code:** unification refactors, regression harness completion, input/resolution hardening.
- **Art/human:** consistency polish; science advisor full review; difficulty-curve tuning from data.
- **Tests:** full automated regression green; every level passes batch validation.

## Phase 3 — Acceptance
- Internal full playthrough.
- Exit criteria (doc02 §10 阶段4):
  - Every level clears; no system is still in flux.
  - Hints/terms/visual semantics/difficulty are consistent across chapters.
  - Regression + multi-input + multi-resolution pass; science review signed off.
- Feedback-driven fixes only. Passing unlocks Beta (iteration 7).
