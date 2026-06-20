# Task 00 — Bootstrap the Godot project

> Iteration 0 · prompt 00 · depends on: nothing (this is the first code task)
> Execute this cold. Read the "Context" block before doing anything.

## Context (read first)

- Repo root: `D:\Project\Astroite\FeynmanDiagram`.
- Engine (pinned, do not use any other): `engine/Godot_v4.6.2-stable_win64.exe` (editor),
  `engine/Godot_v4.6.2-stable_win64_console.exe` (headless/CLI).
- No `game/` project exists yet — you are creating it.
- **Must read first:** `CLAUDE.md`, `agents/tasks/iteration-00-feel-prototype/PLAN.md`, and
  `agents/tasks/iteration-00-feel-prototype/DISCUSSION.md`.
- Language: reply to the user in Chinese; write all code, comments, commits in English.
- Scope rule: this task creates **skeleton only** — no module logic (that is prompts 01–05).

## Goal

Stand up `game/project.godot`, the module folder skeleton, GdUnit4 integration, and a verified
headless test run, so later prompts have a working project + test harness to build on.

## Deliverables

1. `game/project.godot` configured for Godot 4.6.2; a placeholder `Main` scene set as main scene.
2. Folder skeleton under `game/` matching DISCUSSION §Module contracts:
   ```
   game/
     core/graph/     # GraphModel, GraphNode, Socket, HalfEdge, GraphEdge, CurvePoint (empty stubs)
     interaction/    # InputRouter (autoload stub), CurveInteraction, command/ (UndoStack, Command)
     render/         # CurveRenderer stub, shaders/
     level/          # LevelRuntime stub, levels/
     ui/
     tests/          # GdUnit4 suites
   ```
   Stubs = `class_name` declared, minimal/empty bodies. No behavior yet.
3. `InputRouter` registered as an autoload in `project.godot` (empty stub is fine).
4. GdUnit4 installed under `game/addons/gdUnit4/` and enabled as a plugin in `project.godot`.
5. One trivial passing test in `game/tests/` (e.g. asserts `GraphModel.new() != null`) to prove the
   harness runs.
6. Verify `game/.godot/` and `game/.import/` are **not** staged (root `.gitignore` already covers them;
   confirm with `git status`).

## How to verify (must actually run)

- Editor opens cleanly: `engine/Godot_v4.6.2-stable_win64.exe --path game` → no script/parse errors.
- Headless test run is green and exits 0. Use the console build with GdUnit4's CLI runner; confirm the
  exact invocation against the installed GdUnit4 version's docs (do not guess the flags), then record
  the working command in `game/README.md`. Expected shape:
  ```
  engine/Godot_v4.6.2-stable_win64_console.exe --path game --headless \
    -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests
  ```

## Done when

- The smoke test passes headlessly and the command is documented in `game/README.md`.
- `git status` shows only intended files (no `.godot/`, no `.import/`).
- You report (in Chinese) the verified editor + headless commands back to the user.

## Out of scope

- GraphModel/InputRouter/renderer/interaction logic — later prompts. Skeletons only here.
