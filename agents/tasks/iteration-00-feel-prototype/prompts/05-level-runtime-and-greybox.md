# Task 05 — LevelRuntime + 6 connect-and-tidy levels

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
`CurveRenderer`, judge **graph completeness** off the graph, and trigger the completion show. Ship the
6 prologue grey-box levels as data with reference solutions. There are **no geometric objectives** —
judging is pure topology (this is real Feynman-graph physics: a graph must be connected with no
dangling half-edges).

## Deliverables (under `game/level/`)

- `LevelSpec` (`Resource`): `givens` (initial half-built graph snapshot) and `reference_solution` (a
  completed graph snapshot). Saved as `.tres`. **No `spatial_objectives` field.**
- `GraphModel` completeness helpers: `is_connected()` and `has_dangling_half_edges()`. A level is
  solved when the graph is connected **and** has no dangling half-edges **and** every required
  external endpoint is wired.
- `LevelRuntime` (node/scene): `load_level(spec)` instantiates a `GraphModel` from `givens`, injects
  it into `CurveInteraction` + `CurveRenderer`, evaluates completeness off `GraphModel` signals (never
  off pixels), emits `objective_met` / `level_complete`, and calls `CurveRenderer.play_completion()`.
- 6 grey-box levels (`level/levels/00x.tres`), doc01 §9 序章 1–6:
  1) connect a line to a vertex; 2) bend/tidy with two fixed ends; 3) connect two lines to one vertex;
  4) undo/redo teaching; 5) snap a half-edge to a glowing socket; 6) complete a three-line
  convergence. Each stores a machine-verifiable `reference_solution` (a connected, dangling-free graph).

## Tests (GdUnit4)

- `is_connected` / `has_dangling_half_edges` are correct on representative graphs.
- Loading each of the 6 `.tres` and applying its `reference_solution` validates as `level_complete`.
- An incomplete graph (a dangling half-edge, or a disconnected piece) is **not** complete.
- Level data round-trips through `.tres` load/save.

## Done when

- Tests green headlessly; the 6 levels are launchable in the editor and completable by hand.
- Append a dated entry to `agents/dailyLog/`.
- Report (in Chinese) the completeness rule + level list to the user.

## Out of scope

- Physics rules / conservation (I1), hint system, final art/audio. **No geometric win conditions.**
