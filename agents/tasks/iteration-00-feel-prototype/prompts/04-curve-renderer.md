# Task 04 — CurveRenderer v0 + pulse

> Iteration 0 · prompt 04 · depends on: 01-graph-model-min
> Execute cold. Read the Context block first.

## Context

- Repo: `D:\Project\Astroite\FeynmanDiagram` · engine pinned at `engine/Godot_v4.6.2-stable_win64.exe`.
- Read first: `CLAUDE.md`, this iteration's `PLAN.md`, `DISCUSSION.md`, and `prompts/00,01`.
  For art direction (colors/width/bloom feel), follow `prompts/06-art-and-feel-direction.md`.
- Reply to the user in Chinese; write code/comments/commits in English.
- Run tests headlessly per `game/README.md`.

## Goal

Render graph edges as glowing curves (view only) and play a particle pulse that moves at **constant
arc-length speed**. The renderer reads the graph; it never owns or writes geometry.

## Deliverables (under `game/render/`)

- `CurveRenderer` (node) that:
  - Takes a `GraphModel` reference by injection; subscribes to `edge_changed` / `topology_changed`
    and rebuilds/updates its drawn curves accordingly.
  - Builds a `Curve2D` per `GraphEdge` from its `curve_points` (Bézier handles) and draws it
    (`Line2D` or custom `_draw`).
  - `glow_line.gdshader` (greybox v0) for the glowing line look — parameters art-directed by prompt 06.
  - `play_pulse(edge_or_path)`: a glowing point traverses the edge's `Curve2D` by **arc length** at
    constant speed (sample by arc length so it does not speed up near control points). Provide a pure
    `sample_by_arc_length(curve, t)` helper for testing.
  - Completion-show hook: `play_completion()` runs the pulse across the whole graph, 2–5 s, skippable.

## Tests (GdUnit4)

- `sample_by_arc_length`: successive samples are near-equal in arc length (constant speed) within a
  tolerance, including around control points.
- `edge_changed` triggers a redraw/update (render state follows the model).
- Curve built from `curve_points` matches expected length/endpoints.

## Done when

- Tests green headlessly. Append a dated entry to `agents/dailyLog/`.
- Report (in Chinese) the pulse-speed approach + shader params to the user.

## Out of scope

- Input, commands, level logic. Final art (greybox quality only — see prompt 06).
