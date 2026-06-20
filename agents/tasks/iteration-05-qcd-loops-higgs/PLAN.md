# Iteration 5 — Main Line Second Half: QCD, Families, Loops, Higgs

> Status: `not-started`
> Source: doc02 §10 阶段3 ("主线后半生产"), content §3.4–§3.8
> Business gate: **Gate D — Advanced** (doc02 §14). Build full advanced content only if QED+weak players
> still want more system depth.
> Depends on: iteration 4 `done`

## Goal

Complete the advanced acts — **QCD (color), diagram families & interference, loops, Higgs, endgame** —
plus the Free Lab v1. Keep advanced chapters from collapsing into menus and symbol soup.

## Scope (large — will be sub-phased in discussion)

### In
- **QCD (§3.4):** teaching quark subset, gluons, color/anti-color flow, q-g + 3-gluon + 4-gluon
  vertices; color sockets, weave lines, self-coupling nodes, color re-routing.
- **Families & interference (§3.5):** multi-diagram layers, topology ghosts, phase wheel (abstract,
  not real amplitudes), normalization challenges, perturbation-order budget by vertex count.
- **Loops (§3.6):** closed-loop tension, virtual-particle candidates, tree-vs-loop tiering, echo
  pulse; no loop integrals.
- **Higgs + review (§3.7):** Higgs boson, teaching Yukawa, qualitative coupling weights, cross-chapter
  composite puzzles, finale movement.
- **Endgame (§3.8)** + **Free Lab v1** (doc02 §4.3).

### Out (deferred)
- Real integrals/renormalization/cross-sections; full auto-enumeration of all SM diagrams.

## Phase 1 — Discussion (produces `prompts/`)
Sub-split by act. For each: extend `PhysicsGrammar` (color/loops/Higgs vertices), extend
`TopologyCanonicalizer` (color flow, loop order/closed-loop particle/direction labels — doc02 §8.3),
define new feedback language per chapter, and the Free Lab dual-view (game vs standard-diagram).

## Phase 2 — Implementation
- **Code:** color-flow layer, loop topology + echo pulse, Higgs coupling layer, multi-diagram family
  management, Free Lab v1 with live legality + export.
- **Art/human:** per-chapter environments + audio families (weave/echo/weight), authored advanced
  levels + curated families; ongoing science review + localization.
- **Tests:** color-flow closure, loop closure on curated sets, family-completeness checks.

## Phase 3 — Acceptance
- Playtest advanced chapters + Free Lab.
- Exit criteria / **Gate D**:
  - Color flow is readable; loop feedback is legible; families read as families, not noise.
  - Advanced chapters did not become menu/symbol soup (doc02 §16).
  - Free Lab v1 is usable without information overload.
- Feedback-driven fixes only. Passing unlocks Alpha (iteration 6).
