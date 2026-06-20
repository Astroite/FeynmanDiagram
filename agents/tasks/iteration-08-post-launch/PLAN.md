# Iteration 8 — Post-Launch

> Status: `not-started`
> Source: doc02 §10 阶段6 ("首发后")
> Business gate: **Gate E — UGC** (doc02 §14). Invest in creation/Workshop only if tools are stable,
> players are asking for it, and the team can maintain/moderate it.
> Depends on: iteration 7 shipped

## Goal

Stabilize the launch, then evaluate community creation and an expansion — driven by reception and
real player demand, not a fixed plan.

## Scope (time-boxed windows from doc02 §10 阶段6)

### Launch + 0–3 months
- Fixes, performance, hint and accessibility improvements.
- Data-driven tuning of individual levels (no physics-system rewrites).
- Add a small amount of curated challenge content (free).

### Launch + 3–9 months
- Evaluate creation mode + Workshop (**Gate E** conditions).
- Improve Free Lab, export, and curated community sharing.
- Optional soundtrack / digital art-and-science book.

### Launch + 9–18 months
- Only if reception + demand hold: produce one substantial expansion (e.g. "neutrino observation",
  "famous collider processes", or higher-order families). Do not slice base SM content into DLC.

## Phase 1 — Discussion (produces `prompts/`)
- Live-ops triage process; criteria and data thresholds for the curated challenge drops.
- **Gate E** readiness check: tool stability, moderation capacity, demand evidence.
- If green: creation-mode + Workshop design (data-only sharing, auto solve-exists validation,
  reporting/version compat — doc02 §4.5); else: expansion scoping.

## Phase 2 — Implementation
- **Code:** patches/perf; (conditional) creation mode + Workshop pipeline or expansion content.
- **Art/human:** curated challenges; (conditional) soundtrack/art book; expansion assets.
- **Tests:** patch regression; (conditional) UGC validation (every shared level has ≥1 solution).

## Phase 3 — Acceptance
- Reception + live metrics review (doc02 §15 正式版).
- Exit criteria:
  - Launch issues resolved; player sentiment stable.
  - Gate E decision made on evidence (ship UGC or consciously defer).
  - If an expansion is greenlit, it has its own future iteration.
