# Task 05 — LevelRuntime + 6 greybox levels

> Iteration 0 · prompt 05 · depends on: 03-curve-interaction, 04-curve-renderer
> Execute cold. Read the Context block first.

## Context

- Repo: `D:\Project\Astroite\FeynmanDiagram` · engine pinned at `engine/Godot_v4.6.2-stable_win64.exe`.
- Read first: `CLAUDE.md`, this iteration's `PLAN.md`, `DISCUSSION.md`, and `prompts/00,01,03,04`.
  Level layouts come from `prompts/06-art-and-feel-direction.md`.
- Reply to the user in Chinese; write code/comments/commits in English.
- Run tests headlessly per `game/README.md`.

## Goal

Assemble a playable level: load level data, own the `GraphModel`, wire up `CurveInteraction` and
`CurveRenderer`, check **geometry-only** objectives off the graph, and trigger the completion show.
Ship the 6 prologue greybox levels as data with reference solutions.

## Deliverables (under `game/level/`)

- `LevelSpec` (`Resource`): `givens` (initial graph snapshot), `spatial_objectives`,
  `reference_solution` (curve points that satisfy the objectives). Saved as `.tres`.
- Spatial objective types (precursor to `SpatialConstraintSystem`): `ObservationRing` (curve must
  pass through), `ForbiddenZone` (curve must avoid), `FixedAnchor` (locked endpoint).
- `LevelRuntime` (node/scene): `load_level(spec)` instantiates a `GraphModel` from `givens`, injects
  it into `CurveInteraction` + `CurveRenderer`, evaluates objectives off `GraphModel` signals (never
  off pixels), emits `objective_met` / `level_complete`, and calls `CurveRenderer.play_completion()`.
- 6 greybox levels (`level/levels/00x.tres`), doc01 §9 序章 1–6:
  1) drag a node so the line passes a ring; 2) bend with two fixed ends; 3) weave between forbidden
  zones; 4) undo/redo teaching; 5) snap a half-edge to a glowing socket; 6) first three-line
  convergence. Each stores a machine-verifiable `reference_solution`.

## Tests (GdUnit4)

- `point-in-ring` and `segment-vs-forbidden-zone` objective checks are correct.
- Loading each of the 6 `.tres` and applying its `reference_solution` validates as `level_complete`.
- Level data round-trips through `.tres` load/save.

## Done when

- Tests green headlessly; the 6 levels are launchable in the editor and completable by hand.
- Append a dated entry to `agents/dailyLog/`.
- Report (in Chinese) the objective types + level list to the user.

## Out of scope

- Physics, hint system (I1), final art/audio. Objectives are geometric only.
