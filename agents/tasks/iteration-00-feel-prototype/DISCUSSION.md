# Iteration 0 — Discussion / Technical Plan

> Phase: **Discussion**. This turns `PLAN.md` into agent-ready prompts under `prompts/`.
> Read alongside `PLAN.md`. Once this is approved, `prompts/*.md` are the executable hand-off.

## Locked decisions (2026-06-20)

- **D1 — Pre-seed a minimal GraphModel now.** Even though I0 has no physics, the curve is the *view*
  of a graph edge. We build the `GraphNode / HalfEdge / GraphEdge` skeleton in I0 so I1 (QED physics)
  bolts on without reworking the interaction layer. Honors CLAUDE.md "graph is truth, curve is view".
- **D2 — Unit test framework: GdUnit4.** Native Godot 4 support, scene tests, rich assertions.
- **D3 (default) — Godot organization.** Autoload only for truly global services (e.g. `InputRouter`).
  A `GraphModel` instance is **owned by `LevelRuntime`**, not a global singleton — one graph per level.
  Modules live as `class_name` scripts / scenes under `game/`.
- **D4 (default) — Undo/redo = command pattern.** Every state-changing action is a reversible
  `Command` (`do()` / `undo()`), pushed on an `UndoStack`. Covers all solution-changing ops (Gate A).
- **D5 (default) — Input scope = mouse + basic touch.** Gamepad deferred (later iteration).

## Minimal GraphModel — I0 subset

Authoritative data. Fields reserved for I1+ are present but unused in I0 (marked `# I1`). The renderer
reads this; it never owns geometry truth.

```gdscript
class_name GraphNode
var id: StringName
var kind: int          # NodeKind.ANCHOR (fixed external endpoint) | NodeKind.VERTEX (movable)
var position: Vector2  # geometric position — a layout/view property, never a win condition
var sockets: Array[Socket] = []

class_name Socket
var id: StringName
var owner_node: GraphNode
var local_offset: Vector2          # attach point relative to node
var occupied_by: HalfEdge = null   # snap target; null = free

class_name HalfEdge                 # a connection is TWO half-edges meeting at a node (CLAUDE.md)
var id: StringName
var node: GraphNode
var socket: Socket
var edge: GraphEdge
# var particle_id: StringName      # I1
# var fermion_flow: int            # I1 — stored separately from geometry & time axis

class_name GraphEdge
var id: StringName
var half_edge_a: HalfEdge
var half_edge_b: HalfEdge
var curve_points: Array[CurvePoint] = []   # VIEW data: Bezier control points along the edge
# var particle_id: StringName      # I1
# var time_axis_dir: int           # I1 — stored separately from geometry & fermion flow

class_name CurvePoint
var position: Vector2
var in_handle: Vector2 = Vector2.ZERO    # relative Bezier handle
var out_handle: Vector2 = Vector2.ZERO

class_name GraphModel                # owned by LevelRuntime; emits change signals
signal node_changed(node)
signal edge_changed(edge)
signal topology_changed()
# add/remove/connect/disconnect API; to_dict()/from_dict() for save + reference solutions
```

Note: I0 deliberately does **not** add `ParticleSpec` / `VertexRule` / charge / lepton numbers — those
arrive in I1. I0 keeps the topology vocabulary (node/socket/half-edge/edge) only.

## Module contracts — I0

| Module | Type | Responsibility | Key signals / API |
|--------|------|----------------|-------------------|
| `InputRouter` | autoload | Device-agnostic raw pointer + keyboard intents. **No hit-testing, no game logic.** | `pointer_down(world_pos)`, `pointer_moved(world_pos)`, `pointer_up(world_pos)`, `undo`, `redo`, `cancel` |
| `GraphModel` | class (owned by level) | Authoritative graph; the only writer of truth. | signals above; `move_node`, `set_curve_points`, `connect_half_edge`, … |
| `CurveInteraction` | node | Hit-test + classify gesture (drag node / bend edge / snap half-edge) → build reversible `Command`s → mutate `GraphModel`; magnetic snap (no pixel-exact hit); own `UndoStack`. | consumes `InputRouter` signals; `Command.do/undo`, `UndoStack.push/undo/redo` |
| `CurveRenderer` | node | Render edges from `GraphModel` (view only); glow shader; pulse at constant arc-length speed. | reads `edge_changed`; `play_pulse()` |
| `LevelRuntime` | node/scene | Load level data (givens + reference solution); own the `GraphModel`; judge **graph completeness** (connected + no dangling half-edges); trigger completion show. | `level_loaded`, `objective_met`, `level_complete` |

Data flow (one direction): `InputRouter → CurveInteraction → GraphModel → (signals) → CurveRenderer`.
`LevelRuntime` judges completeness off `GraphModel`, never off pixels.

## Greybox level data — I0 (connect & tidy)

6 levels = doc01 §9 序章 1–6. The goal is **graph completeness**, judged purely on topology — there
are no geometric objectives:

- A level is solved when the graph is connected, has no dangling half-edges / isolated subgraphs, and
  every required external endpoint is wired (doc01 §4.4 steps 1–2). Levels progress from connecting one
  line, to bending/tidying, to a three-line convergence.
- Stored as data (`res://level/levels/00x.tres`), not code (CLAUDE.md "levels are data").
- Each level stores a machine-verifiable reference solution (a connected, dangling-free graph).

## Test list — GdUnit4

- `GraphModel`: add/remove/connect/disconnect; `to_dict`/`from_dict` round-trip.
- `UndoStack`: any op sequence `do → undo` returns to initial state; `redo` reproduces (covers **every**
  state-changing action — Gate A requirement).
- Arc-length: pulse sampler advances near-constant arc length per step (no speedup near control points).
- `LevelRuntime`: `is_connected` / `has_dangling_half_edges` checks; an incomplete graph is rejected;
  the reference solution of each of the 6 levels validates as complete.

## Manual / art deliverables (human, not agent)

- Greybox visual target: dark space bg, glowing line, sparse particle dust (ref `arts/style/00.png`).
- Glow-line shader v0 art direction (color/width/bloom feel) — agent implements, human art-directs.
- The 6 greybox level layouts (given lines, vertices, and the target connected graph).
- Reference pulse timing: 2–5 s completion show, constant speed, skippable.

## Prompt breakdown & dependency order

```
00-bootstrap                    (no deps)        — project + GdUnit4 + skeleton
├─ 01-graph-model-min           (00)             — data classes + signals + tests
├─ 02-input-router              (00)             — semantic input autoload
03-curve-interaction            (01, 02)         — intents → commands → graph; undo/redo; snap
04-curve-renderer               (01)             — glow edges + constant arc-length pulse
05-level-runtime-and-greybox    (03, 04)         — level data, completeness judging, 6 levels, show
06-art-and-feel-direction       (parallel/human) — greybox look, shader direction, pulse timing
```

## Acceptance mapping → Gate A (from PLAN.md §Phase 3)

- First-time player clears levels 1–3 with no text.
- "Drag vertex" vs "bend curve" clearly distinct; mis-input is not the main complaint.
- Stable framerate while dragging on the low-spec target.
- Undo/redo covers every solution-changing action (enforced by the `UndoStack` test).
- **Gate A question:** is connecting + tidying a graph satisfying enough to keep going?
