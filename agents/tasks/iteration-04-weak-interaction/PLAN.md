# Iteration 4 — Main Line First Half: Weak Interaction

> Status: `not-started`
> Source: doc02 §10 阶段2 ("主线前半生产"), content §3.3 第二幕
> Business gate: —
> Depends on: iteration 3 `done` (Gate C passed)

## Goal

Complete Prologue + QED + **Weak interaction** acts and the basic star-map progression. Validate that
"identity change" and "invisible neutrino" mechanics create genuinely new play, not reskins.

## Scope

### In
- Particles: e/μ neutrinos + antiparticles, W±, Z⁰, a teaching subset of up/down quarks (doc02 §3.3).
- New mechanics: **transmuting vertex** (identity changes through a W vertex), **invisible channels**
  (neutrino lines only appear under pulse), **decay chains**, **charge sockets** on W.
- Representative processes: muon decay, quark-level beta decay (as a sub-process), neutral-current
  scattering, simplified W/Z production+decay.
- Per-chapter visual switch (doc02 §6.2); systematic science review + localization pipeline begins.

### Out (deferred)
- Neutrino mixing / CKM numbers / higher-order suppression → science lens or late challenges only.

## Phase 1 — Discussion (produces `prompts/`)
- Extend `PhysicsGrammar` with weak vertex templates + flavor/generation teaching rules.
- `GraphModel`/`PulseSimulation` support for transmuting vertices and pulse-revealed hidden lines.
- Decay-chain sequencing and charge-socket connection rules.
- Chapter visual/audio modulation spec; science-review + localization workflow.

## Phase 2 — Implementation
- **Code:** weak grammar layer, transmuting-vertex + invisible-channel handling, decay chains,
  star-map progression.
- **Art/human:** weak-chapter environment + "modulator" audio family; authored levels + references;
  science-advisor review pass; first localization pass.
- **Tests:** weak conservation rules; invisible-channel inference correctness; decay-chain activation.

## Phase 3 — Acceptance
- Playtest weak chapter for new-mechanic value (doc02 §16 risk: "章节只是换皮").
- Exit criteria:
  - Each new chapter adds one operation mechanic + one feedback language (not just new particle names).
  - Identity-change and invisible-neutrino puzzles are understood and enjoyed.
  - Science review signs off on the teaching simplifications.
- Feedback-driven fixes only. Passing unlocks iteration 5.
