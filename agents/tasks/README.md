# Task roadmap — `agents/tasks/`

Iteration roadmap for *量子对撞师 / Quantum Collider*, derived from the two design docs in
`designer/`. **Read this before starting any work in this folder.**

## How iterations work

Iterations are **strictly serial**: an iteration may not start until the previous one has passed its
acceptance gate. Each iteration is a folder `iteration-NN-<slug>/` containing:

- `PLAN.md` — the iteration-level outline (goal, scope, three-phase breakdown, exit criteria). Stable.
- `prompts/` — agent-ready task documents, **produced during this iteration's discussion phase**
  (does not exist until then).

## The three phases of every iteration

1. **Discussion** — turn this iteration's `PLAN.md` outline into concrete, agent-executable task
   prompts. Decide module boundaries, data shapes, the test list, and which deliverables are manual
   (art / audio / level data). Output: `iteration-NN/prompts/*.md`, each self-contained enough for any
   agent to execute cold (no prior conversation context required).
2. **Implementation** — agents pick up the prompt docs and write + debug code; humans produce the
   flagged manual deliverables. No scope is re-decided here; if a prompt is wrong, bounce it back to
   discussion.
3. **Acceptance** — a human playtests against the exit criteria and files feedback. Only small,
   feedback-driven fixes happen here — no new scope. Passing the exit criteria (and the business gate,
   if the iteration has one) unlocks the next iteration.

## Status legend

`not-started` → `discussion` → `implementation` → `acceptance` → `done`

One iteration is `discussion`/`implementation`/`acceptance` at a time; everything after it stays
`not-started` until it is `done`.

## Iteration index

| # | Folder | Goal (one line) | Source | Business gate |
|---|--------|-----------------|--------|---------------|
| 0 | `iteration-00-feel-prototype` | Prove the bare curve feel is fun with zero physics | doc01 §14 P0 | Gate A — Feel |
| 1 | `iteration-01-qed-gameplay-prototype` | QED rules create reasoning, not blind guessing | doc01 §14 P1 | Gate B — Gameplay |
| 2 | `iteration-02-qed-vertical-slice` | A stranger understands, enjoys & remembers the slice | doc01 §14 P2 / doc02 §10 阶段0 | — (slice exit) |
| 3 | `iteration-03-pipeline-and-demo` | Ship a 20–30 min free public demo + store page | doc02 §10 阶段1 | Gate C — Commercial |
| 4 | `iteration-04-weak-interaction` | Prologue + QED + weak interaction + star-map progress | doc02 §10 阶段2 | — |
| 5 | `iteration-05-qcd-loops-higgs` | QCD, diagram families, loops, Higgs, endgame, free lab v1 | doc02 §10 阶段3 | Gate D — Advanced |
| 6 | `iteration-06-alpha` | Content-complete; unify & cut, no new systems | doc02 §10 阶段4 | — |
| 7 | `iteration-07-beta-release` | Perf, localization, Steam features, release prep | doc02 §10 阶段5 | — |
| 8 | `iteration-08-post-launch` | Post-launch fixes, then evaluate UGC/Workshop & expansion | doc02 §10 阶段6 | Gate E — UGC |

Current iteration: **0** (ready to enter its discussion phase). All others: `not-started`.

## Mapping to the design docs

- doc 01 ("短期目标与核心框架") is the QED vertical slice, split into P0/P1/P2 → **iterations 0–2**.
  Those three together equal doc 02's "阶段 0 / 前期验证".
- doc 02 ("完整开发目标与商业形态") 阶段 1–6 → **iterations 3–8**.
- Business gates A–E come from doc 02 §14; honor them as hard stops between iterations.

## Conventions

- All files here are in **English** (see `CLAUDE.md` → Language convention).
- Iterations 0–2 are detailed because they are imminent; 3–8 are intentionally coarser and will be
  sharpened in their own discussion phase as we learn from earlier iterations.
- Keep `PLAN.md` scope honest with `CLAUDE.md` → Scope discipline: the slice is **QED only**; later
  theories stay behind interfaces until their iteration.
