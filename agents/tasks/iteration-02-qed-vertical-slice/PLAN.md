# Iteration 2 — QED Vertical Slice

> Status: `not-started`
> Source: doc01 §14 P2 ("垂直切片") = doc02 §10 阶段0 exit; supported by §4.2 题型四, §8 audio, §10 progression
> Business gate: — (this is the slice exit that feeds Gate C in iteration 3)
> Depends on: iteration 1 `done`

## Goal

A stranger, with no developer present, **understands, enjoys, and remembers** the game. This is the
representative-quality QED slice used to judge the whole product direction.

## Scope

### In
- 30–40 finished levels (doc01 §9 全四章, ~36 levels), 45–90 min first clear.
- Fourth puzzle type: **family / 成组** + topology dedup (doc01 §4.2 题型四, §11.1).
- `TopologyCanonicalizer`: isomorphism normalization, duplicate-solution rejection (doc02 §8.3).
- Representative-quality final visuals + audio direction (doc01 §7, §8).
- Progression + save + settings + accessibility framework (doc01 §10; "量子星图").
- A 15–25 min public playtest cut; store-ready GIFs/screenshots.

### Out (deferred)
- Weak/QCD/loops/Higgs, free sandbox, Steam integration (→ later iterations).

## Phase 1 — Discussion (produces `prompts/`)

Decide and write agent-ready prompts for:
- `TopologyCanonicalizer`: labeled-graph canonical form + hash; the three result classes
  (geometry-different / label-swap / genuinely different channel) per doc02 §8.3.
- Full validation pipeline (doc01 §4.4 steps 1–6: endpoints → integrity → vertex template → flow →
  conservation → topology dedup). Geometry never participates in judging.
- Family processes: Bhabha, Møller, Compton lowest-order sets, with curated reference families.
- `Progression`: star-map, mastery objectives (doc01 §10.2), save format.
- Final-quality `CurveRenderer` + audio voices (doc01 §7.2, §8.2); reduced-motion + colorblind paths.
- Playtest-cut script + capture plan for store assets.

## Phase 2 — Implementation

- **Code:** `TopologyCanonicalizer`, `Progression`, full `CurveRenderer`,
  audio integration; harden `GraphModel`/`PhysicsGrammar`/`PulseSimulation`/`HintDirector`.
- **Art/human (manual):** final line styles, glow shaders, particle dust, per-chapter harmony layers,
  completion music sting; the ~36 levels' authored data + reference solutions.
- **Tests:** topology dedup correctness on the curated family sets; batch-run all levels to catch
  rules-update regressions (doc01 §12.5).

## Phase 3 — Acceptance

- Stranger playtest (the core validation of the whole project).
- Exit criteria (doc01 §15 + doc02 §10 阶段0 exit):
  - Curve feel passes stranger testing; all four puzzle types stand up.
  - Physics rules are not the main source of frustration.
  - The level editor lets a non-programmer build content.
  - Visual quality is good enough for store exposure.
  - Store video reads as "drag curve → particles flow → diagram closes" even muted.
- Feedback-driven fixes only. Passing unlocks iteration 3 (and sets up Gate C).
