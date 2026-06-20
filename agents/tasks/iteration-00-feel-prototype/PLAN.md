# Iteration 0 — Feel Prototype

> Status: `not-started` (ready for discussion phase)
> Source: doc01 §14 P0 ("手感原型"), supported by §5 interaction, §7 visual, §12 architecture
> Business gate: **Gate A — Feel** (doc02 §14). Only continue to rules if the no-physics curve toy is fun.
> Depends on: project bootstrap (`game/project.godot` must exist)

## Goal

Prove the bare act of dragging, bending and watching a glowing line flow is satisfying **with zero
physics**. If players won't tune a line just to watch it flow, nothing built on top matters.

## Scope

### In
- One flexible curve type (Bézier on `Curve2D`/`Path2D`).
- Verbs: drag vertex, bend curve, snap half-edge to socket, undo/redo.
- A particle pulse moving at near-constant arc-length speed along the curve.
- 6 grey-box levels with **no physics terms** (doc01 §9 序章 1–6: ring pass, bend with fixed ends,
  weave between forbidden zones, undo/redo, snap to glowing socket, first three-line convergence).
- Mouse + basic touch input.

### Out (deferred)
- Any particle identity, vertex grammar, arrows, fermion flow (→ iteration 1).
- Topology, hints, audio identity, save system, accessibility polish.

## Phase 1 — Discussion (produces `prompts/`)

Decide and write agent-ready prompts for:
- Bootstrap: `game/project.godot`, folder skeleton matching doc01 §12.2 module names.
- `InputRouter` semantic input contract (pointer/touch → drag/bend/snap intents).
- `CurveInteraction`: handle generation, hit-testing, magnetic snap radius, undo/redo stack.
- `CurveRenderer` v0: glowing line via `CanvasItem` shader, pulse-along-curve animation.
- `LevelRuntime` v0 + a data shape for the 6 grey-box levels (geometry-only objectives).
- Test list: arc-length parameterization, undo/redo covers every state-changing action.
- Manual deliverables: grey-box visual target, one reference pulse timing.

## Phase 2 — Implementation

- **Code:** `InputRouter`, `CurveInteraction`, `CurveRenderer` (v0), `LevelRuntime` (v0).
- **Art/human:** grey-box look only — no final art. Tune snap radius and pulse speed by feel.
- **Tests:** pulse moves at near-constant arc-length speed (no speedup near control points);
  undo/redo round-trips every action.

## Phase 3 — Acceptance

- Human playtest of the 6 levels with no instructions.
- Exit criteria (doc01 §15 操作 + Gate A):
  - A first-time player completes the first three levels with no text.
  - Players clearly distinguish "drag vertex" vs "bend curve"; mis-input is not the main complaint.
  - Stable framerate while dragging on the low-spec target; no hitching.
  - **Gate A question:** would a player keep going *just* to make the line smooth and watch it flow?
- Only feel-tuning fixes here. Passing unlocks iteration 1.
