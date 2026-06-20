# Iteration 1 — QED Gameplay Prototype

> Status: `not-started`
> Source: doc01 §14 P1 ("玩法原型"), supported by §4 puzzles, §6 feedback/hints, §11 science, §12
> Business gate: **Gate B — Gameplay** (doc02 §14). Continue only if QED yields ≥4 repeatable puzzle types.
> Depends on: iteration 0 `done`

## Goal

Prove the QED rules produce **reasoning, not blind guessing**. Players should derive structure from a
few readable rules, not brute-force vertices.

## Scope

### In
- QED vertex rule (one photon leg + two same-flavor fermion half-edges).
- Particles: electron, positron, muon, photon (doc01 §12.3 `ParticleSpec`, integer `charge3`).
- Three of four puzzle types: **shape / complete / repair** (doc01 §4.2 题型一~三).
- Local error feedback (observation pulse stops at first problem) + 4-tier hints (doc01 §6).
- 18 grey-box levels (roughly doc01 §9 第一章 7–14 + part of 第二章, grey-box).
- Internal level editor v1 (doc01 §12.5 minimum: place endpoints/vertices, save reference solution,
  auto-validate).

### Out (deferred)
- Topology canonicalization / "find a family" type (→ iteration 2).
- Final visuals/audio, progression/save, accessibility.

## Phase 1 — Discussion (produces `prompts/`)

Decide and write agent-ready prompts for:
- `GraphModel` authoritative data: nodes, **half-edges**, edges, external states (doc01 §12.3). Graph
  is truth, curve is view.
- `PhysicsGrammar`: vertex template match, fermion-flow continuity, exact integer conservation.
  Separate storage for geometric dir / time-axis dir / fermion flow.
- Validation pipeline order (doc01 §4.3 steps 1–4 for this iteration; topology comes in iter 2).
- `PulseSimulation`: traverse graph, stop at first illegal vertex / arrow / particle; feedback states
  from doc01 §6.1.
- `HintDirector`: 4 tiers (direction → rule → action → demo), no progress penalty.
- `ContentTools` editor v1 + level data shape (`LevelSpec`, doc01 §12.3).
- **Test list:** every physics rule needs a unit test (doc01 §12.4). Each level stores ≥1
  machine-verifiable reference solution.

## Phase 2 — Implementation

- **Code:** `GraphModel`, `PhysicsGrammar`, `PulseSimulation`, `HintDirector`, `ContentTools` v1.
- **Art/human:** still grey-box; particle line styles only as far as identity is readable
  (line style + arrows, not color-dependent — doc01 §7.2).
- **Tests:** full physics-rule unit suite; conservation uses integers, never float tolerance.

## Phase 3 — Acceptance

- Human playtest of the 18 levels.
- Exit criteria (doc01 §15 可玩性 + Gate B):
  - Players can describe at least one moment of deriving an answer from a rule.
  - Mid-game failure comes from puzzle reasoning, not "couldn't see / couldn't click / lost the button".
  - **Gate B question:** do the QED rules generate at least four repeatable puzzle types?
- Feedback-driven fixes only. Passing unlocks iteration 2.
