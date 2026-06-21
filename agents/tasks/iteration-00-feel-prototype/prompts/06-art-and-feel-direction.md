# Task 06 — Art & feel direction (human-led)

> Iteration 0 · prompt 06 · runs in parallel · **human deliverable** (agent assists with shader params)
> This is direction, not code. It feeds prompts 04 (shader) and 05 (level layouts).

## Context

- Repo: `D:\Project\Astroite\FeynmanDiagram`. Visual reference: `arts/style/00.png`.
- Read first: `CLAUDE.md`, this iteration's `PLAN.md` and `DISCUSSION.md`, and doc01 §5.3 (feedback
  states), §7 (visual direction).
- Reply to the user in Chinese; any written artifacts in English.

## Goal

Define the greybox look and the feel parameters so prompts 04 and 05 have concrete targets. Quality
bar is **greybox**, not final art — but it must already read as doc01 §7.1: "quiet, deep, precise
quantum instrument".

## Deliverables (human-authored; record under `agents/` or `arts/` as appropriate)

- **Greybox palette**: dark (not pure-black) background value, glowing-line color/width, bloom
  intensity — anchored to `arts/style/00.png`. Hand these to prompt 04 as `glow_line.gdshader` params.
- **Pulse & completion timing**: pulse speed (constant arc-length), completion show 2–5 s, skippable;
  the basic snap / legal-attach audio-visual feedback sketch (doc01 §5.3) — feeds prompt 04.
- **6 greybox level layouts**: given lines, vertices, and the target connected graph for prologue 1–6
  — feeds prompt 05's `.tres` data.

## Done when

- Prompts 04 and 05 have unambiguous numbers/layouts to implement against.
- Append a dated entry to `agents/dailyLog/` noting decisions.

## Out of scope

- Final art assets (I2), audio identity (I1+), per-particle line semantics (I1 — no particles yet).
