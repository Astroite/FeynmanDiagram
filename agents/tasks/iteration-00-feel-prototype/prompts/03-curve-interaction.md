# Task 03 — CurveInteraction + undo/redo

> Iteration 0 · prompt 03 · depends on: 01-graph-model-min, 02-input-router
> Execute cold. Read the Context block first.

## Context

- Repo: `D:\Project\Astroite\FeynmanDiagram` · engine pinned at `engine/Godot_v4.6.2-stable_win64.exe`.
- Read first: `CLAUDE.md`, this iteration's `PLAN.md` and `DISCUSSION.md`, and `prompts/00,01,02`.
- Reply to the user in Chinese; write code/comments/commits in English.
- Run tests headlessly per `game/README.md`.

## Goal

Consume `InputRouter` pointer signals, hit-test against a **injected** `GraphModel`, classify the
gesture, and apply changes through reversible commands. All solution-changing actions are undoable
(Gate A requirement).

## Deliverables (under `game/interaction/`)

- `command/Command.gd` — base class with `do()` / `undo()`.
- `command/UndoStack.gd` — `push(cmd)` (runs `do`, clears the redo branch), `undo()`, `redo()`.
- Concrete commands: `MoveNodeCommand`, `BendEdgeCommand` (edits `curve_points`),
  `ConnectHalfEdgeCommand` (snap to socket).
- `CurveInteraction` (node) that:
  - Takes a `GraphModel` reference by injection (owner sets it; do **not** autoload the model).
  - Hit-tests with tolerance and **classifies gesture**: press on node core → drag node; press on an
    edge segment → bend; drag a free half-edge end near a socket → snap.
  - **Magnetic snap**: on `pointer_up`, if a half-edge end is within snap radius of a socket, connect
    (no pixel-exact hit required).
  - Routes `InputRouter.undo/redo` to the `UndoStack`; mutates the graph **only** via commands.

## Tests (GdUnit4)

- Each command `do → undo` returns the model to its prior state; `redo` reproduces.
- `UndoStack` over an arbitrary op sequence (move/bend/connect) restores the initial graph after full
  undo, and reproduces after full redo — i.e. **every** state-changing action is covered.
- Snap connects when an endpoint is within radius, and does not when outside.
- Gesture classification picks node-drag vs edge-bend vs snap for representative pointer inputs.

## Done when

- Tests green headlessly. Append a dated entry to `agents/dailyLog/`.
- Report (in Chinese) the command set + snap radius default to the user.

## Out of scope

- Rendering (only mutate `GraphModel`), physics validation, level objectives.
