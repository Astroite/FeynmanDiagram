# Task 01 — Minimal GraphModel

> Iteration 0 · prompt 01 · depends on: 00-bootstrap
> Execute cold. Read the Context block first.

## Context

- Repo: `D:\Project\Astroite\FeynmanDiagram` · engine pinned at `engine/Godot_v4.6.2-stable_win64.exe`.
- Read first: `CLAUDE.md`, this iteration's `PLAN.md` and `DISCUSSION.md` (§Minimal GraphModel), and
  `prompts/00-bootstrap.md`.
- Reply to the user in Chinese; write code/comments/commits in English.
- Build on the skeleton from prompt 00. Run tests headlessly per `game/README.md`.

## Goal

Implement the authoritative graph data layer (I0 subset) with change signals, a clean mutation API,
and dict serialization. This is the single source of truth; nothing else owns geometry.

## Deliverables (under `game/core/graph/`)

- `GraphNode`, `Socket`, `HalfEdge`, `GraphEdge`, `CurvePoint` per DISCUSSION §Minimal GraphModel —
  including the `# I1` reserved fields (declared, unused).
- `NodeKind` enum (`ANCHOR`, `VERTEX`).
- `GraphModel` (a `RefCounted`/`Resource`, **not** an autoload):
  - Mutation API: `add_node`, `remove_node`, `add_edge`, `remove_edge`, `connect_half_edge`,
    `disconnect_half_edge`, `move_node`, `set_curve_points`.
  - Invariant: a connection is **two half-edges meeting at a node** — `connect_half_edge` must wire
    `HalfEdge.node/socket/edge` consistently and mark `Socket.occupied_by`.
  - Signals: `node_changed(node)`, `edge_changed(edge)`, `topology_changed()`.
  - `to_dict()` / `from_dict()` for save + machine-verifiable reference solutions.

## Tests (GdUnit4, under `game/tests/`)

- add/remove node & edge; connect/disconnect half-edges updates both endpoints + socket occupancy.
- `to_dict` → `from_dict` round-trips to an equivalent graph (ids, topology, curve points).
- `move_node` emits `node_changed`; `set_curve_points` emits `edge_changed`; add/remove emits
  `topology_changed`.
- No dangling half-edge after `remove_edge` (sockets freed).

## Done when

- All tests green headlessly (exit 0).
- Append a dated entry to `agents/dailyLog/` summarizing what landed.
- Report (in Chinese) the API surface and test result to the user.

## Out of scope

- Physics (particles/charge/flow), rendering, input, undo/redo (commands live in prompt 03).
