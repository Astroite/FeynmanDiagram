# Iteration 0 — Connect & Tidy (Feel Prototype)

> Status: `implementation` (reframed from "pure geometric feel" — see DISCUSSION + dailyLog 2026-06-21)
> Source: doc01 §14 P0, reframed — §9 prologue is now connect-and-tidy, §4.1/§4.4 topology completeness
> Business gate: **Gate A — Feel** (doc02 §14). Continue only if connecting + tidying a graph feels good.
> Depends on: project bootstrap (`game/project.godot` exists)

## Goal

Prove that **connecting given particle lines into a complete graph, and tidying it by hand, feels
good** — with the lightest real physics (graph completeness only, no QED rules yet). The win
condition is genuine physics: a Feynman graph must be **connected with no dangling half-edges**
(doc01 §4.4 steps 1–2). Dragging and bending only tidy the picture; **geometry never decides the
puzzle**, and there are no observation rings / forbidden zones.

## Scope

### In
- One flexible curve type (Bézier on `Curve2D`/`Path2D`) as the *view* of an edge.
- Verbs: connect (snap a half-edge to a vertex socket), drag vertex, bend curve, undo/redo.
- A particle pulse moving at near-constant arc-length speed along each edge.
- **Topology-completeness judging only**: a level is solved when the graph is connected, has no
  dangling half-edges / isolated subgraphs, and every required external endpoint is wired. No vertex
  rules, no conservation.
- 6 grey-box levels (doc01 §9 序章 1–6): connect a line to a vertex, bend/tidy with fixed ends,
  connect two lines to one vertex, undo/redo, snap a half-edge to a glowing socket, complete a
  three-line convergence.
- Mouse + basic touch input.

### Out (deferred)
- Particle identity, vertex grammar, arrows, fermion flow, conservation (→ iteration 1).
- **No geometric win conditions** — observation rings / forbidden zones are removed by design.
- Hints, audio identity, save system, accessibility polish.

## Phase 1 — Discussion (produces `prompts/`)

Decide and write agent-ready prompts for:
- Bootstrap: `game/project.godot`, folder skeleton matching doc01 §12.2 module names.
- `InputRouter` semantic input contract (pointer/touch → drag/bend/snap intents).
- `CurveInteraction`: handle generation, hit-testing, magnetic snap radius, undo/redo stack.
- `CurveRenderer` v0: glowing line via `CanvasItem` shader, node handles, pulse-along-curve animation.
- `LevelRuntime` v0 + level data shape; judging = graph completeness (connected + no dangling).
- Test list: arc-length parameterization, undo/redo covers every state-changing action, completeness
  check (connected + no dangling half-edges).
- Manual deliverables: grey-box visual target, one reference pulse timing.

## Phase 2 — Implementation

- **Code:** `InputRouter`, `CurveInteraction`, `CurveRenderer` (v0), `LevelRuntime` (v0) +
  `GraphModel` completeness helpers (`is_connected`, `has_dangling_half_edges`).
- **Art/human:** grey-box look only — no final art. Tune snap radius and pulse speed by feel.
- **Tests:** pulse moves at near-constant arc-length speed; undo/redo round-trips every action;
  completeness judging accepts a connected/dangling-free graph and rejects an incomplete one.

## Phase 3 — Acceptance

- Human playtest of the 6 levels with no instructions.
- Exit criteria (doc01 §15 操作 + Gate A):
  - A first-time player completes the first three levels with no text.
  - Players clearly distinguish "drag vertex" vs "bend curve"; mis-input is not the main complaint.
  - Players understand the goal is "connect the lines into one complete graph".
  - Stable framerate while dragging on the low-spec target; no hitching.
  - **Gate A question:** is connecting + tidying a graph satisfying enough to keep going?
- Only feel-tuning fixes here. Passing unlocks iteration 1.
