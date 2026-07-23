# Quantum Collider Project Audit

**Audit date:** 2026-07-15  
**Audited revision:** `14342bf58d4877d036368423387206acf8cd1e1c` (`main`, commit subject `UI`)  
**Repository update status:** `git fetch --prune` and `git pull --ff-only origin main` completed; the repository was already current.  
**Primary target:** the QED vertical slice defined by `designer/01_短期目标与核心框架_量子对撞师.md`. The full-product document is treated only as a future horizon.

## 1. Executive verdict

The repository contains a credible early gameplay prototype, not a vertical slice. The strongest work is the graph-first foundation, reversible interaction commands, procedural curve rendering, and an unusually healthy automated test baseline for this stage. The project boots reliably, the pinned engine is present, and all 84 existing tests pass.

The project is not ready to pass Gate A (feel prototype acceptance), because correctness defects currently let players bypass the intended puzzles and because the six tutorial levels have not been proven through human playtesting. It is also not ready to claim a QED gameplay prototype: one QED level and a local vertex checker exist, but the required validation pipeline, external-state checks, observation pulse, tiered hints, level authoring constraints, puzzle variety, and editor are missing.

Estimated status against the current short-term target:

| Measure | Estimate | Basis |
|---|---:|---|
| P0 implementation coverage | 65-75% | Most planned verbs and six tutorial resources exist, but completion correctness, staged actions, pulse behavior, touch completeness, and acceptance remain unresolved. |
| P0 acceptance | 0% | No documented stranger playtest, low-end performance pass, or Gate A decision. |
| P1 implementation coverage | 15-25% | Particle catalog, one hard-coded QED grammar, tray/draw verbs, and one QED level exist; most P1 systems and content do not. |
| P2 implementation coverage | 5-10% | A galaxy-map shell and visual direction exist; topology families, progression, save, settings, accessibility, final art/audio, and public-demo packaging do not. |
| Short-term slice feature coverage | approximately 25-30% | Rough weighted estimate across P0-P2 deliverables; not a schedule estimate. |
| Authored level count | 7 / approximately 36 (19%) | Six topology tutorials plus one QED completion level. Only one level exercises QED validation. |
| Automated checks | 84 / 84 passing | 17 GdUnit4 suites; important adversarial and end-to-end cases are absent. |

The recommended decision is to freeze further meta-UI expansion and complete a correctness-and-acceptance pass on P0 before adding more P1/P2 surface area.

## 2. Audit scope and evidence

The audit included:

- repository state, history, Git LFS, ignore rules, and working documents;
- the authoritative short-term design, iteration plans, and handoff roadmap;
- all first-party GDScript outside the vendored GdUnit4 add-on;
- all seven level resources and their reference solutions;
- architecture, validation, interaction, undo/redo, rendering, HUD, and level-selection code;
- automated tests, normal headless boot, and 1280x720 rendered captures of the menu, level map, tutorial, and QED puzzle;
- temporary adversarial runtime probes for cases not represented in the test suite.

Commands and outcomes:

| Check | Outcome |
|---|---|
| `git pull --ff-only origin main` | Already up to date; clean `main`. |
| Engine version | `4.6.2.stable.official.71f334935`, matching the pinned version. |
| `scripts/run_gdunit.ps1` | 84/84 cases passed across 17/17 suites in approximately 1.4 seconds. |
| Normal `--headless --quit-after 60` boot | Exit code 0; no script error in the boot log. |
| 1280x720 Vulkan render capture | Successful on an RTX 4070 Ti SUPER. This is a visual inspection, not a performance qualification. |
| Test-process shutdown | Repeated `ObjectDB instances leaked` and `5 resources still in use` diagnostics after GdUnit/adversarial runs. Normal game boot did not show them. |

Limitations:

- No human playtest was conducted, so feel, comprehension, and fun cannot be certified.
- No low-end target device, Steam Deck, 16:10, controller, or real touch device was tested.
- No audio could be evaluated because the project contains no game audio assets or audio implementation.
- No release export could be tested because no export preset or release pipeline is present.

## 3. Current implementation inventory

### Present

- Godot 4.6.2 project with a bootable main scene.
- Graph model with nodes, sockets, two half-edges per edge, curve points, serialization, and graph signals.
- Command-based undo/redo for moving, bending, connecting, creating, deleting, cutting, seeding, adding endpoints, and reversing edges.
- Mouse world interaction and a direct touch-routing layer.
- Procedural Bézier rendering, glow shader, photon wave, fermion arrow, selection handles, cut trail, charge ring, and completion pulses.
- QED particle registry for electron, positron, muon, anti-muon, and photon, including integer quantum-number fields.
- Hard-coded QED vertex validation for one photon plus two same-family fermion legs with one-in/one-out arrow continuity.
- Level runtime, catalog, seven data resources, and a reference solution per level.
- Menu, galaxy-style level map, puzzle HUD, victory screen, and shared procedural theme.
- Vendored GdUnit4 framework and 84 focused tests.
- Appropriate Git LFS tracking for large binaries and ignored Godot-generated data.

### Missing or only nominally referenced

- `VertexRule` as data rather than a hard-coded checker.
- Full endpoint/external-state and exact conservation validation stages.
- `TopologyCanonicalizer` and non-isomorphic family tracking.
- `PulseSimulation` that traverses the graph and stops at the first physical error.
- `HintDirector` and the four-tier hint chain.
- Level-specific accepted topologies, allowed actions/particles, required endpoints, required solution count, and completion sequence.
- `Progression`, save data, locks, mastery, discovery, and real galaxy state.
- `ContentTools` or any internal level editor/validator.
- Audio, settings, localization, reduced-motion, colorblind support, and accessibility settings.
- CI, export configuration, packaging, public-demo cut, and store capture pipeline.

## 4. Scorecard

Scores are against the requested QED vertical slice, not against a throwaway grey-box prototype.

| Area | Score | Assessment |
|---|---:|---|
| Bootstrapping and repository hygiene | 8/10 | Pinned engine, clean project, LFS, ignore rules, and a repeatable test script are in place. Documentation is stale and CI/export are absent. |
| Architecture | 6/10 | Graph/view separation and half-edge modeling are good. Direction semantics, level goals, and several planned module boundaries are incomplete. |
| Runtime correctness | 3/10 | Multiple verified completion and state-lifecycle defects can invalidate puzzle results. |
| Code maintainability | 6/10 | Naming and comments are generally clear, but two very large classes, duplicated geometry/style logic, and dictionary-heavy contracts raise change risk. |
| Automated quality | 7/10 | 84 fast tests cover many commands and happy paths. Critical negative cases, real input/UI tests, performance, and shutdown cleanliness are missing. |
| Gameplay and level design | 4/10 | The core manipulation vocabulary is visible, but onboarding is not staged, the tutorial objectives are not mechanically enforced, and QED reasoning depth is not yet demonstrated. |
| Visual/art presentation | 5/10 | Cohesive procedural prototype with a readable photon wave and restrained palette. It is far below the reference quality and lacks identity, labels, accessibility semantics, and production assets. |
| Audio | 0/10 | No game audio system or assets. |
| Accessibility and device coverage | 3/10 | Basic touch routing and keyboard shortcuts exist. Color-independent identity, reduced motion, controller navigation, responsive layout, and complete touch HUD interaction do not. |
| Content pipeline and release readiness | 2/10 | Levels are data and have references, but there is no editor, batch validator beyond tests, progression, export, CI, license file, or release pipeline. |

## 5. Priority findings

### P0-1: Deleting authored content can solve a level

**Severity:** Blocker  
**Evidence:** `GraphModel.is_complete()` only checks for dangling half-edges and graph connectivity (`game/core/graph/GraphModel.gd:164`). `is_graph_connected()` returns true for zero or one node (`game/core/graph/GraphModel.gd:177`). The puzzle HUD exposes deletion for any selected authored node or edge. A runtime probe removed the connected `left` anchor in level 001; the incident edge was removed, one node remained, and the level became complete.

**Impact:** The player can bypass the intended interaction. The same design permits deletion toward an empty graph, and the empty graph itself reports complete.

**Required fix:** Make completion level-aware. Validate required authored endpoints/nodes, immutable givens, minimum structure, allowed actions, external states, and level-specific goals before graph completeness. Do not expose deletion in levels that do not allow it.

### P0-2: Undo history leaks across level loads and restarts

**Severity:** Blocker  
**Evidence:** `CurveInteraction.set_graph_model()` replaces the graph and clears selection but does not clear or rebind the undo stack (`game/interaction/CurveInteraction.gd:112`). A runtime probe made one action in level 001, loaded level 002, and observed `can_undo == true` with an undo count of one.

**Impact:** Step counts are wrong, restart is not a clean restart, and undo can execute commands that still reference a previous graph. This is both a correctness and memory-lifetime risk.

**Required fix:** Cancel active gestures and clear the undo/redo stack whenever a model is installed or a level restarts. Add lifecycle tests across load, restart, victory, replay, and next-level transitions.

### P0-3: Completion state is latched even when the graph becomes invalid

**Severity:** Blocker  
**Evidence:** `LevelRuntime.evaluate_completeness()` sets `_is_complete` when a graph first passes but never resets it; it returns the latched value (`game/level/LevelRuntime.gd:61-71`). A probe loaded a reference solution, removed its edge, and obtained `is_level_complete == true` while `validation_status.ok == false`.

**Impact:** Runtime state, HUD feedback, and progression can disagree. Future replay, delayed victory, analytics, or save logic would record false completions.

**Required fix:** Separate `current_validity` from `completion_was_emitted`, recompute current validity on every model change, and ensure the transition signal fires only on false-to-true edges.

### P0-4: The QED validator accepts graphs with no interaction vertex

**Severity:** Blocker for P1  
**Evidence:** `PhysicsGrammar.validate()` skips every non-vertex node and succeeds after integrity if no interaction vertex exists (`game/core/physics/PhysicsGrammar.gd:30`). A probe connected two anchor nodes with a photon edge and received `ok == true` from the QED validator.

**Impact:** A topologically connected graph can be described as physically valid without containing a QED interaction. External particle requirements and the intended process are not enforced.

**Required fix:** Implement the documented pipeline: required endpoints, graph integrity, vertex templates, fermion flow and external states, exact integer conservation, allowed topology, and level goals. Validation must take both a graph and the active `LevelSpec`.

### P0-5: Every level exposes every particle and topology-editing verb

**Severity:** High  
**Evidence:** `LevelSpec` has no allowed-actions or allowed-particles fields (`game/level/LevelSpec.gd:4-14`). `PuzzleHud` always builds five QED particle tokens plus a new-endpoint token (`game/ui/screens/PuzzleHud.gd:135-150`) and always exposes hint, delete, cut, reverse, restart, and world manipulation when applicable.

**Impact:** The first tutorial contradicts the design rule of introducing at most two new actions. Players see unexplained particles and can alter topology outside the intended problem. It also creates most of the bypass surface.

**Required fix:** Add data-driven action and particle permissions to `LevelSpec`; configure each tutorial narrowly; enforce permissions in runtime/interaction, not only by hiding UI.

### P0-6: Fermion flow, geometric ordering, and time direction are not independent in behavior

**Severity:** High architectural debt  
**Evidence:** `GraphEdge.time_axis_dir` and `HalfEdge.fermion_flow` are serialized, but `PhysicsGrammar` does not read either. Arrow behavior is derived from particle sign and whether the half-edge is the edge's `a` or `b` end (`game/core/physics/PhysicsGrammar.gd:90`). Reversal swaps half-edge order and reverses curve-point order (`game/core/graph/GraphModel.gd:121`).

**Impact:** This violates a core architecture invariant. Future external-state, crossing, and antiparticle rules will be difficult to implement without changing saved data and interaction semantics.

**Required fix:** Introduce explicit enums/fields for geometric traversal, time-axis direction, and fermion flow. Rendering, validation, and reversal should consume the appropriate field independently.

### P0-7: Curve interaction hit-tests a different shape from the rendered curve

**Severity:** High feel risk  
**Evidence:** Renderer output is based on baked `Curve2D` points. Edge selection and nearest-segment logic measure straight segments between authored control points (`game/interaction/CurveInteraction.gd:554-570`, `906-914`). Cut logic pins endpoints but still uses a control-point polyline rather than the rendered Bézier/wave.

**Impact:** A visibly curved line can be hard to select or cut, while an invisible chord may capture input. This directly threatens the Gate A requirement that mis-input not dominate feedback.

**Required fix:** Share a cached baked-curve geometry service between renderer and interaction. Hit-test the visible core curve with a forgiving radius and add strongly curved regression cases.

## 6. Code and architecture review

### Strengths

- The graph, rather than pixels, is the source of truth for current completion checks.
- Connections are modeled as two half-edges occupying sockets, which is the correct base abstraction.
- Curve geometry is kept out of physics validation.
- Integer fields exist for charge and lepton numbers; no floating-point tolerance is used for those values.
- `GraphModel` emits focused change signals and serializes graph snapshots deterministically.
- Commands make the major state-changing verbs reversible and are tested in mixed sequences.
- Levels are resource data rather than bespoke scripts, and every existing level has a reference snapshot.
- First-party code is generally readable and heavily commented.
- LFS correctly contains the engine and binary art; generated `.godot/` data is ignored.

### Maintainability risks

- `CurveInteraction.gd` is approximately 971 lines and `CurveRenderer.gd` approximately 801 lines. They contain multiple independent responsibilities and duplicate endpoint/handle geometry.
- Particle colors/styles are separately encoded in the renderer and puzzle HUD; they can drift.
- Signal payloads and validation results use loosely typed dictionaries, making schema changes easy to miss.
- `LevelSpec.to_dict()` omits `ruleset`, so any future tool using that serializer can silently turn QED content into topology content.
- `GraphModel.from_dict()` trusts authored dictionaries and does not return structured authoring errors. Malformed or duplicate content is likely to fail late.
- Multi-step command undo methods do not consistently propagate partial restoration failures. This can leave stack state and graph state inconsistent after an error.
- Topology changes often cause a complete renderer rebuild. This is acceptable for seven small graphs but should be measured before larger family puzzles.
- There is no explicit content schema version or save version.

### First-party code size

| Area | GDScript files | Approximate lines |
|---|---:|---:|
| Core graph | 7 | 535 |
| Physics | 2 | 200 |
| Interaction and commands | 14 | 1,706 |
| Level runtime/catalog/spec | 3 | 436 |
| Renderer | 1 | 801 |
| UI | 11 | 1,283 |
| Main | 1 | 90 |
| Tests | 17 | 1,615 |

The test-to-runtime line ratio is healthy for an early prototype. The problem is test selection, not test volume.

## 7. Test-quality review

### What is covered well

- Graph add/remove/connect/disconnect and snapshot round trips.
- Command do/undo/redo behavior for the primary interactions.
- Snap radius, gesture classification, live preview rewind, and anchor immobility.
- Bézier construction, arc-length sampling, renderer signal updates, arrows, handles, and trails.
- Particle registry values and several valid/invalid local QED vertex patterns.
- Catalog ordering, level references, runtime completion happy paths, and basic HUD transitions.

### Critical missing tests

- Empty graph, one-node graph, and deletion-to-trivial-graph completion.
- Required endpoint preservation and immutable givens.
- Undo/redo reset on load, restart, replay, and next-level navigation.
- Completion validity reverting from true to false.
- QED graphs without vertices, with wrong external states, or with the wrong process/topology.
- Explicit integer conservation stages and use of `charge3`, `lepton_e`, and `lepton_mu`.
- Separation of geometric direction, time direction, and fermion flow.
- Level-specific allowed actions and particles.
- `LevelSpec` custom serialization of `ruleset` and future goal fields.
- Strongly curved edge selection/cut behavior against the actual rendered path.
- Real GUI input. The runner itself warns that UI interaction is unreliable in headless mode; most UI tests call methods directly.
- Level-select pan/zoom/click, focus transitions, keyboard/controller navigation, and zoomed label readability.
- Touch interaction for tray tokens and endpoint placement.
- 16:10, small-screen, high-DPI, and reduced-motion layouts.
- Low-end rendering/per-frame allocation benchmarks and visual regression captures.

The GdUnit process also emits object/resource leak diagnostics at shutdown. Because a normal 60-frame game boot exits cleanly, this may be test-fixture or add-on cleanup rather than a shipped runtime leak, but it should not be ignored.

## 8. Gameplay and level-design audit

### Core loop status

| Loop step | Status |
|---|---|
| Observe fixed endpoints and partial graph | Present. |
| Drag nodes, bend curves, connect half-edges, reverse arrows | Present in broad prototype form. |
| Sense proximity through local glow/audio/pulse | Partial visual feedback; no audio and no physics-aware pulse. |
| Trigger an observation pulse | Missing. The HUD has a reference-solution hint instead. |
| Correct the first local error | Only a one-line validator message; no traversal or localized error animation. |
| Automatic resonance completion | Present as immediate completion signal plus decorative per-edge pulses. |
| Optional science lens | Missing. |

The implementation correctly avoids geometric win conditions. That is a major design success. However, the present loop is closer to “edit until a status string turns valid” than “observe a pulse, locate the first physical failure, understand, and resonate.”

### Tutorial sequence

- Levels 001, 002, 004, and 005 are mechanically very similar: drag a free endpoint to the only available socket.
- Level 002 is named as a bend lesson, but geometry cannot and should not decide success. The current mechanics do not ensure the player learns curve bending.
- Level 004 cannot teach undo/redo as authored. The first successful connection immediately emits completion and changes to the victory screen, disabling puzzle interaction before the player can practice undo and redo.
- The full particle tray and endpoint creation are visible from level 001, before particle identity is taught.
- Deletion, cutting, endpoint creation, seeding, and reference-solution replacement are available without level permissions.
- The hint button installs the full reference graph and therefore completes the level. This is acceptable only as a temporary debug escape, not as the intended hint experience.

### QED depth

Level 007 is a useful visual and data integration smoke test. It contains the complete annihilation diagram with one dangling positron leg. The required action is obvious: connect the only loose end to the only open vertex socket. This does not yet prove that QED rules generate reasoning rather than blind placement.

The level is also categorized inconsistently: the galaxy map places it in the first act, while its player-facing code is still `Prologue 07`. The authoritative design defines the prologue as levels 1-6 and chapter one as levels 7-14.

### Gate assessment

**Gate A: not ready for acceptance.** Before playtesting, fix result integrity, restrict level actions, make every tutorial objective mechanically demonstrable, and align hit-testing with rendered curves. Then run a documented stranger playtest against the design metrics.

**Gate B: not ready.** One completion puzzle and one hard-coded vertex grammar do not demonstrate three repeatable QED puzzle types, much less four. Do not advance the roadmap status to P1 acceptance.

## 9. Visual, art, and UI audit

### What already works

- The dark blue/purple palette is coherent with the “quiet quantum instrument” direction.
- The play area remains visually dominant, with limited chrome around the edges.
- Fermions and photons are immediately distinguishable at a basic level; the photon wave reads particularly well.
- Fermion arrows, glow, selection rings, handles, snap feedback, and cut trail communicate interaction state.
- The galaxy view is a better structural direction than a conventional list and already supports pan/zoom.
- The visual implementation is procedural and lightweight in asset dependencies, which is useful during prototyping.

### Main gaps against the reference and target

- The menu has only a large `Start Game` button. It has no product title, logo, subtitle, or focal artwork, so the game has almost no identity on first launch.
- The runtime does not use the supplied style images or equivalent production assets. Backgrounds are repeated concentric radial bands, stars, and four streams; they read as a procedural placeholder rather than a deep, precise instrument.
- External particle symbols are absent from the QED canvas. Players must infer identity from color and arrows alone.
- Electron and muon lines share the same solid-line grammar and are primarily separated by color. This does not meet the color-independent identification requirement.
- Real and virtual photons have no distinct data or visual state.
- Interaction vertices are simple filled circles; the richer socket, phase, validity, and local-error states in the references are absent.
- The level map has no locked/available/completed states, progress path, or real progression data. Every level is selectable.
- `LevelSelectScreen` manually converts world to screen but also scales labels by inverse zoom (`game/ui/screens/LevelSelectScreen.gd:213-214`), causing labels to shrink when zooming in and grow when zooming out instead of remaining constant.
- Most UI positions are absolute in a 1280x720 design space. The project requests a 2560x1440 window and uses `canvas_items` with `expand`; no responsive pass has proven 16:10, Steam Deck, small windows, or safe areas.
- Completion pulses use one fixed duration for all edges (`game/render/CurveRenderer.gd:415`), so different-length edges move at different speeds during completion despite the near-constant-speed visual rule.
- There is no reduced-motion mode. The starfield, background streams, galaxy nodes, transitions, and pulses all animate continuously.

### Art-production risks

- No game fonts, textures, VFX textures, or final UI assets are integrated outside the vendored test add-on.
- No asset naming/import convention, source-to-runtime pipeline, or art budget is documented.
- Reference-image provenance and permitted production usage are not documented. Treat the current images as reference-only until ownership/license status is recorded.
- There is no screenshot comparison or visual regression baseline.

The current look is appropriate for a grey-box/feel prototype, but not representative enough for P2, a public demo, or store exposure.

## 10. Audio, accessibility, and platform audit

### Audio

There are no game audio files, audio buses, playback systems, adaptive layers, particle voices, interaction sounds, or completion sting. Audio cannot contribute to feel or validation yet. The game remains playable silently, but that currently reflects absence rather than completed multimodal accessibility.

### Accessibility

- Photon versus fermion has a shape distinction; electron versus muon does not.
- External-state labels and symbols are missing from the gameplay canvas.
- No reduced-motion, flashing reduction, font scaling, high-contrast, colorblind palette, rebinding, narration, or subtitle settings exist.
- Focusable native buttons are a good base, but the custom level-map nodes do not expose keyboard/controller focus semantics.

### Input and layout

- Mouse manipulation and keyboard undo/redo/delete/cancel are present.
- Direct screen-touch routing exists for world gestures.
- Tray drag code explicitly handles mouse events; complete touch behavior is not proven.
- Controller navigation is absent.
- The initial requested window is 2560x1440, which is inappropriate as an unqualified default for many desktop and handheld displays.
- 16:10 and small-screen behavior remain unverified despite being first-priority targets in the design.

## 11. Content, tooling, and release-readiness audit

### Content/data

It is good that levels are `.tres` data and each contains a reference solution. The current `LevelSpec`, however, is too small to support the design. It needs at least:

- required/fixed external endpoints and external particle states;
- allowed actions and allowed particles;
- accepted topology rules and required solution count;
- hint chain and completion sequence;
- chapter/progression metadata;
- schema version and validation diagnostics.

The catalog is a hard-coded path array, and galaxy membership is a separate hard-coded index array. Adding/reordering levels can silently misclassify content.

### Internal tools

No `ContentTools` implementation exists. There is no non-programmer level editor, topology hash, action/particle configuration UI, automated reference validation on save, multi-resolution preview, or batch content report. This is a major production bottleneck, not a cosmetic omission.

### Release engineering

- No `.github/` CI workflow.
- No export preset or documented export-validation job.
- No project-level license file.
- Root `README.md` contains only the repository name.
- No crash reporting, structured logging, analytics/playtest logging, or versioned save format.
- No localization source files, even though player-facing strings are embedded directly in scripts/resources.

Git LFS and generated-file hygiene are good. The immediate need is CI for import, headless boot, and tests, not a full release pipeline.

## 12. Project-management and documentation health

Several working documents no longer describe the repository accurately:

- `AGENTS.md` says implementation has not started and no Godot project exists, but the project now contains thousands of lines of runtime code and 84 tests.
- `agents/tasks/README.md` says iteration 0 is ready to enter implementation, while most P0 code and several P1 experiments are already present.
- `agents/tasks/handoff-completion-roadmap.md` says the tray, particle data, and QED validation do not exist; all now exist in partial form.
- The last daily log predates several June 23 interaction commits and the July 3 UI commit.
- Root `plan.md` documents the galaxy-map rewrite but does not state whether it is complete, accepted, or superseded.
- At least one recent commit subject is written in Chinese, contrary to the repository's English-artifact convention.

This drift makes progress estimates unreliable and increases the chance of implementing later-stage systems before earlier gates pass. Update the roadmap only after the correctness pass, then record Gate A evidence explicitly.

## 13. Recommended remediation plan

### Phase 0: Restore result integrity

1. Define level-aware validation inputs and a structured `ValidationResult`.
2. Add required endpoints/givens, allowed actions, allowed particles, and minimum graph constraints to `LevelSpec`.
3. Reject empty/trivial graphs and enforce external-state/level goals.
4. Clear undo/redo and cancel gestures on every model installation.
5. Split current validity from one-shot completion emission.
6. Add adversarial regression tests for every reproduced defect.
7. Restrict delete/cut/add/seed/reverse/hint per level in both UI and runtime.

**Exit condition:** no authored level can be solved by deleting required content, changing forbidden content, loading a prior command, or producing a graph outside its explicit goal.

### Phase 1: Finish the actual P0 tutorial and Gate A

1. Re-author the six tutorial levels so each has a distinct, mechanically observable learning objective.
2. Redesign level 004 so undo/redo is performed before completion, or remove it as a level objective.
3. Hide the QED tray and advanced verbs until the level data enables them.
4. Hit-test baked Bézier geometry and tune snap/hit radii with strongly curved cases.
5. Provide a real near-constant-speed pulse and a skip path for completion.
6. Test mouse and touch on real devices, plus 16:9, 16:10, and a small display.
7. Run a documented stranger playtest against the published Gate A metrics.

**Exit condition:** the first three levels are understandable without developer explanation, intended actions cannot be bypassed, drag versus bend is clear, undo covers every state change, and feel passes human review.

### Phase 2: Build P1 on stable semantics

1. Separate geometric, time-axis, and fermion-flow directions in the model and tests.
2. Implement data-driven `VertexRule` and the complete validation stages through external states and exact conservation.
3. Implement physics-aware `PulseSimulation` and four-tier `HintDirector`.
4. Author three genuinely different QED puzzle types and validate that they create reasoning.
5. Build `ContentTools` before scaling beyond a small set of levels.
6. Add level schema validation and CI batch checks.

**Exit condition:** at least three P1 puzzle types survive stranger testing, and the editor can author/validate content without code changes.

### Phase 3: Only then expand toward P2

Progression/save, topology families, final art/audio, settings, accessibility, public-demo packaging, and store assets should remain behind Gate A and Gate B. The current galaxy map can stay as a shell but should not receive more polish until it is driven by real progress data.

## 14. Suggested acceptance checklist for the next audit

- [ ] Empty and one-node graphs are rejected unless a level explicitly defines such a goal.
- [ ] Required authored endpoints and external states cannot be deleted or changed illegally.
- [ ] Undo/redo is empty after load/restart and never references a prior graph.
- [ ] Current validity becomes false when a completed graph is broken.
- [ ] QED validation rejects anchor-only and wrong-external-state graphs.
- [ ] `charge3` and lepton integers participate in an explicit conservation stage.
- [ ] All three direction concepts have independent stored semantics and tests.
- [ ] Every level declares and enforces allowed actions and particles.
- [ ] Tutorial levels 1-6 each demonstrate their stated objective.
- [ ] Selection and cutting follow the rendered Bézier curve.
- [ ] Observation pulse and local error stop are playable.
- [ ] Level 007 is classified consistently with the chapter structure.
- [ ] Touch tray, controller focus, 16:10, small-screen, and reduced-motion paths are tested.
- [ ] Test runs exit without unexplained resource-leak diagnostics.
- [ ] CI performs import, headless boot, and all tests.
- [ ] Roadmap, AGENTS guidance, root README, and daily logs match the current repository.

## 15. Final recommendation

Continue the project, but treat the current build as an engineering prototype. Its foundation is promising enough to justify a focused stabilization sprint. The highest-value work is not more screens or more visual polish; it is making level results trustworthy, narrowing tutorial verbs, aligning interaction hitboxes with visible curves, and obtaining the first real Gate A playtest evidence. Once those are complete, the existing graph/command/rendering base can support a cleaner P1 implementation without compounding semantic debt.
