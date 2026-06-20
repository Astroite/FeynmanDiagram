# Iteration 7 — Beta & Release Preparation

> Status: `not-started`
> Source: doc02 §10 阶段5 ("Beta 与发行准备")
> Business gate: —
> Depends on: iteration 6 `done`

## Goal

Make it shippable: performance, stability, localization, accessibility, Steam features, and launch
materials. **No new core rules** (no QCD/loop additions at this stage).

## Scope

### In
- Performance, crash, save, and upgrade-path hardening.
- Localization, subtitles, colorblind, reduced-motion, input assistance.
- Steam features: achievements, Cloud saves, demo→full carryover.
- Trailer, store screenshots, media kit, creator/press build.

### Out (frozen)
- New QCD/loop content; Workshop (post-launch, Gate E).

## Phase 1 — Discussion (produces `prompts/`)
- Performance budget + crash/telemetry plan; save-version upgrade strategy.
- Localization + accessibility completion matrix.
- Steam integration checklist (achievements, Cloud, demo carryover).
- Launch-asset and press-kit plan.

## Phase 2 — Implementation
- **Code:** perf passes, crash fixes, save migration, Steam SDK integration, accessibility completion.
- **Art/human:** final trailer, screenshots, media kit, creator build; full localization QA.
- **Tests:** soak/perf on low-spec target; save-upgrade from older versions; achievement/Cloud round-trips.

## Phase 3 — Acceptance
- Release-candidate sign-off.
- Exit criteria (doc02 §10 阶段5):
  - Stable perf on target hardware; no known save-loss or upgrade breakage.
  - Localization/accessibility/Steam features all verified.
  - Launch materials ready.
- Feedback-driven fixes only. Passing means **ship**, then iteration 8.
