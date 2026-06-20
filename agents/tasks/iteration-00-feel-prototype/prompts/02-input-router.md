# Task 02 — InputRouter (semantic input)

> Iteration 0 · prompt 02 · depends on: 00-bootstrap
> Execute cold. Read the Context block first.

## Context

- Repo: `D:\Project\Astroite\FeynmanDiagram` · engine pinned at `engine/Godot_v4.6.2-stable_win64.exe`.
- Read first: `CLAUDE.md`, this iteration's `PLAN.md` and `DISCUSSION.md` (§Module contracts), and
  `prompts/00-bootstrap.md`.
- Reply to the user in Chinese; write code/comments/commits in English.
- Build on the skeleton from prompt 00. Run tests headlessly per `game/README.md`.

## Goal

Turn raw mouse/touch/keyboard into **device-agnostic semantic intents**. This module does **no
hit-testing and no game logic** — it only normalizes input and emits signals. Gesture classification
(drag vs bend vs snap) belongs to `CurveInteraction` (prompt 03).

## Deliverables (under `game/interaction/`)

- `InputRouter` (autoload, already registered in prompt 00) emitting:
  - `pointer_down(world_pos: Vector2)`, `pointer_moved(world_pos: Vector2)`, `pointer_up(world_pos: Vector2)`
  - `undo`, `redo`, `cancel`
- Mouse and single-touch both map to the same pointer signals (basic touch; no multi-touch gestures).
- Screen→world conversion via the active `Camera2D`/canvas transform, so consumers get world coords.
- Keyboard/shortcut bindings for undo/redo/cancel defined as input actions in `project.godot`
  (e.g. `ui_undo`, `ui_redo`, `ui_cancel`).

## Tests (GdUnit4)

- Synthesized `InputEventMouseButton`/`MouseMotion` produce the matching `pointer_*` signals with
  correct world coordinates (use a known camera transform).
- A touch press/drag/release yields the same `pointer_down/moved/up` sequence as the mouse.
- Undo/redo/cancel actions emit the corresponding signals.

## Done when

- Tests green headlessly. Append a dated entry to `agents/dailyLog/`.
- Report (in Chinese) the signal contract to the user.

## Out of scope

- Hit-testing, gesture classification, snapping, any graph mutation (all in prompt 03). Gamepad.
