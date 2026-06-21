# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Language convention

- **Reply to the user in Chinese.** All chat/conversation output is Chinese.
- **Write every repository artifact in English** — code, identifiers, comments, commit messages, PR
  descriptions, and all new docs (including this file and anything under `agents/`).
- Exception: the existing `designer/*.md` are legacy Chinese design docs; do not force-translate them.
  New design/spec docs should be written in English.

## Repository status

This is an **early-stage repository: design is written, implementation has not started.** There is no
Godot project yet, therefore **no build/test/run command exists** — do not invent one. The product is
*量子对撞师 / Quantum Collider* (tentative public name *量子共振 / Quantum Resonance*), a Feynman-diagram
puzzle game.

## Repository layout

| Path         | Purpose |
|--------------|---------|
| `engine/`    | Godot engine **binary** (`Godot_v4.6.2-stable_win64.exe`). This is the editor/runtime, **not** the game project. Committed via Git LFS. |
| `game/`      | The Godot project (`project.godot`, scripts, scenes, imported assets) lives here. Not created yet — this is where implementation starts. |
| `arts/`      | Raw art source. `arts/style/` holds visual-style reference; future raw assets go in subfolders by category under `arts/`. |
| `designer/`  | Authoritative design docs (Chinese, see below). |
| `agents/`    | Working area that agents read/write — see "Agents working area". |

## Authoritative design

The design lives in two documents under `designer/` (Chinese):

- [designer/01_短期目标与核心框架_量子对撞师.md](designer/01_短期目标与核心框架_量子对撞师.md) —
  short-term scope: the **QED vertical slice** (~36 levels), core gameplay loop, puzzle types,
  interaction/feedback design, and proposed technical architecture (§12).
- [designer/02_完整开发目标与商业形态_量子对撞师.md](designer/02_完整开发目标与商业形态_量子对撞师.md) —
  full product: six-act main line (QED → weak → QCD → diagram families → loops → Higgs), game modes,
  long-term architecture (§8), business model, platform strategy.

Treat doc 01 as the current target and doc 02 as the longer horizon — do not pull doc-02 systems
(weak/QCD/loops) into slice work.

## The game in one line

Players connect, bend, and reconnect glowing particle lines into a microscopic interaction that is
*physically valid* — vertex templates, fermion flow, particle identity, and graph topology all check
out. Curves are an expressive view of the graph; their shape never decides the puzzle.

## Engine & running

- Engine: **Godot 4.6.2 stable** at `engine/Godot_v4.6.2-stable_win64.exe` (pin this version).
- Once `game/project.godot` exists, run the editor with `engine/Godot_v4.6.2-stable_win64.exe --path game`
  and headless/CI checks with the `_console` build. Until then there is nothing to run.
- Stack is **Godot + GDScript, desktop-first (Windows/Steam)**, chosen for 2D Bézier curves
  (`Curve2D`/`Path2D`), custom canvas drawing, and `CanvasItem` shaders. Web export is an optional
  demo target only — do **not** add a parallel React/web codebase; any web playable exports from the
  same Godot project.

## Git & assets policy

- **Large binaries go through Git LFS** (configured in `.gitattributes`): engine `*.exe`, and raw
  art/audio/font/3D source (`*.png`, `*.psd`, `*.wav`, `*.ttf`, `*.fbx`, …). Ensure `git lfs` is
  installed before cloning or committing such files.
- `.gitignore` excludes Godot-generated data — `.godot/`, `.import/`, export artifacts,
  `export_presets.cfg` (may hold credentials). Never commit the import cache.
- Commit only when the user asks. Commit messages in English.

## Agents working area (`agents/`)

Shared scratch/coordination space that agents are expected to read and write:

- `agents/dailyLog/` — diary / work logs of what was done each session.
- `agents/tasks/` — per-phase task lists and breakdowns.

Check the relevant `agents/` subfolder for current context before starting work, and append a log
entry when finishing meaningful work. Files here are English.

## Architecture invariants (these constrain any future code)

Deliberate decisions from doc 01 §12.4 and doc 02 §8.2. Respect them when writing code:

- **The graph is the source of truth; the rendered curve is only a view.** Validation and game logic
  operate on the graph model, never on pixel geometry.
- **Connections are two half-edges meeting at a vertex** — not a simple `from/to` edge. Physics is
  expressed through half-edge patterns at vertices, not edge direction.
- **Three directions are stored separately:** geometric line direction, time-axis direction, and
  fermion flow. Never conflate them.
- **Conserved quantities use exact integer units, never floating-point tolerance.** Charge is in
  thirds of *e* (`charge3`; electron = `-3`). Lepton/baryon numbers are integers.
- **Physics layer and level-presentation layer are decoupled.** A science-rule change must not break
  curve feel; level-art tweaks must not change the physics solution.
- **Solutions are judged by physics rules, never by geometry.** Validation pipeline: endpoints →
  graph integrity (no dangling half-edges / isolated subgraphs) → vertex-template match → fermion
  flow & external states → exact conservation → topology canonicalization (isomorphism dedup) →
  level-specific goals. Curve shape and position never participate in judging — there are **no**
  geometric win conditions (no observation rings, forbidden zones, or other spatial objectives).
- **Every physics rule must have automated unit tests, and every level stores at least one
  machine-verifiable reference solution** (without requiring the player to reproduce its geometry).
- **Levels are data, not code.** Level constraints (givens, allowed actions/particles, accepted
  topologies, required solution count, hint chains, completion sequence) are configured as data; an
  internal level editor/validator is a slice-priority deliverable, not a later add-on.

See doc 01 §12.2 for the planned module breakdown (`GraphModel`, `PhysicsGrammar`,
`TopologyCanonicalizer`, `PulseSimulation`, `HintDirector`, `LevelRuntime`,
etc.) and §12.3 for the `ParticleSpec` / `VertexRule` / `GraphNode` / `GraphEdge` / `LevelSpec` data
shapes — match those names when implementing.

## Scope discipline

The short-term slice is **QED only** (electron, positron, muon, anti-muon, photon). Weak interaction,
QCD, loop diagrams, amplitude/cross-section calculation, and free sandbox are explicitly frozen until
the slice proves the core "tune line → understand → resonate" loop (doc 01 §16–17). When adding
features, leave interfaces for later theories but do not implement them.

**Scientific honesty constraint:** the curves are an artistic projection of graph structure, not real
particle trajectories. The game claims real physics only for vertex grammar, particle identity, and
graph topology — never for curve geometry, amplitudes, or kinematics. Keep teaching text tagged as
real rule / teaching simplification / visual metaphor.
