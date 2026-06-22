# Handoff Completion Roadmap

> Goal: realize the full `arts/ref/handoff/` design (the *selected* screens in
> `量子对撞师.dc.html`: MENU A, LEVEL SELECT B, PUZZLE A+C, VICTORY B, SETTINGS B, CODEX A).
> Status anchor: iteration 0 shell is done and honest; this roadmap is what remains.

## What the handoff actually specifies (and why it is bigger than I0)

The handoff depicts the **finished QED product**, not the connect-and-tidy feel prototype. Its core
loop is *"pick a particle from the bottom tray, long-press a vertex and drag to connect a line, build
a Feynman diagram with correct in/out states"* — a **placement verb that does not exist yet** (I0
only drags/bends pre-existing legs). It also assumes QED physics, progression/save, a codex, scoring,
and real settings. In roadmap terms it spans existing **iteration 1 (QED gameplay)** and **iteration 2
(vertical slice)**; see `agents/tasks/iteration-01-*` and `-02-*`.

This must respect the architecture invariants in `CLAUDE.md`: the graph is the source of truth,
connections are half-edges at vertices, three directions stored separately, conservation in exact
integers, physics/presentation decoupled, judging by physics rules (never geometry).

## Gap analysis — handoff element → backing system → current state

| Handoff element | Backing system needed | Now |
|---|---|---|
| Bottom tray tokens, drag-token-onto-vertex | `ParticleSpec` catalog + new placement verb in `CurveInteraction` | ❌ none (I0 has no tray, no placement) |
| Success banner "守恒成立", warning "顶点 V1 缺少入射线" | `PhysicsGrammar` + validation pipeline | ❌ I0 judges topology only |
| 对撞验证 enabled/disabled by validity | validity result from pipeline | ⚠️ button exists, topology-only |
| 顶点 / 步数 "2 · 4" | step counter from command stack; vertex count from graph | ❌ removed as fake in I0 |
| Hint 💡, snap hint "吸附到顶点 V1" | `HintDirector` (4-tier) + snap feedback | ⚠️ I0 hint = reveal reference |
| Observation pulse stops at first error | `PulseSimulation` | ❌ renderer has cosmetic pulses only |
| Level codes "QED·02 / 3-2", chapters I–IV | chapter/code model in catalog | ⚠️ flat catalog + display fields |
| done/avail/locked nodes, ★, 最佳步数, 总体进度 37% | `Progression` + save | ❌ none |
| Victory 步数/用时/守恒精度/无提示, "μ子已加入图鉴" | scoring + unlock events | ⚠️ victory shows name only |
| Codex 32 particles, 4 categories, detail, 出现于 | particle DB + discovery tracking | ❌ screen removed in I0 |
| Settings 音频/画面/操作/辅助/语言, sliders, toggles | audio buses, graphics, rebind, a11y, i18n, save | ❌ screen removed in I0 |
| Menu 帮助 / 公告 icons | Help + Announcements screens | ❌ none |
| Final glow/photon-wave/burst, completion sting | final `CurveRenderer` + audio | ⚠️ greybox shader + cosmetic |
| ×1.5 to 1920×1080 | resolution scaling pass | ⚠️ canvas_items stretch at 1280×720 |

Legend: ❌ missing · ⚠️ partial/placeholder · ✅ done.

## Phased plan

### Phase A — QED puzzle core (the heart of the handoff; ≈ iteration 1)
The screen that makes it a game. Nothing else matters if this verb does not feel right.
- A1 `ParticleSpec` data: electron, positron, muon, anti_muon, photon — integer `charge3`, lepton
  numbers, line style, color. Drives both tray and codex.
- A2 `VertexRule` + `PhysicsGrammar`: QED vertex template (one photon leg + two same-flavor fermion
  half-edges), fermion-flow continuity, exact integer conservation. Unit-tested per rule.
- A3 **Placement verb**: bottom tray of available particles; long-press/drag a token to spawn a
  half-edge and snap it to a vertex socket (reuse `ConnectHalfEdgeCommand`, snap from
  `find_snap_socket`). Mid-drag ghost line + "吸附到顶点 Vx" hint (handoff PUZZLE C).
- A4 Validation pipeline (endpoints → integrity → vertex template → flow → conservation); replace
  I0's topology-only `is_complete`. Drives the real success banner and warning toast.
- A5 `PulseSimulation`: observation pulse traverses the graph and stops at the first illegal
  vertex/flow; wire to the 💡/verify feedback states.
- A6 `HintDirector` 4-tier (direction → rule → action → demo).
- A7 Re-author levels as real QED puzzles (annihilation type A + complete/repair); restore the real
  vertex/step counter from the command stack.
- Tests: every physics rule; each level stores ≥1 machine-verifiable reference solution.

### Phase B — Progression, scoring & meta shell (≈ iteration 2 progression)
- B1 `Progression` + save (`user://`): per-level state (locked/avail/done), stars, best-steps,
  overall %, discovered particles, settings.
- B2 Chapter/code model in `LevelCatalog` (chapters I–IV, codes like "QED·02 / 3-2").
- B3 Level Select galaxy (orbital) view driven by real progress (handoff LEVEL SELECT B) — upgrade the
  current list; node states from B1.
- B4 Victory scoring: steps, time, conservation accuracy, no-hint flag; "新粒子解锁" → codex unlock.

### Phase C — Codex / discovery
- C1 Extend `ParticleSpec` with codex fields (mass, charge, spin, antiparticle, description,
  appears-in level refs).
- C2 Discovery tracking (unlock on first use/clear), persisted via B1.
- C3 Codex screen (handoff CODEX A): category rail (轻子/夸克/规范玻色子/复合粒子), card grid with
  locked cards, detail panel. Quark/boson/composite categories are **shell-only** (QED slice has no
  such content yet — show as locked/empty, do not author doc-02 particles).

### Phase D — Settings (real systems only)
- D1 Audio buses Master/BGM/SFX → `AudioServer`; 环境氛围音 toggle; 输出设备; persisted via B1.
- D2 Tabs 画面/操作/辅助功能/语言: graphics (fullscreen/resolution/reduced-motion), control rebinding,
  accessibility (colorblind, reduced-motion, 动态旁白/TTS), language (i18n scaffolding via Godot
  `TranslationServer`). Wire 恢复默认 + 应用并返回.

### Phase E — Polish, second puzzle type, secondary screens
- E1 Final art/audio: glow line, particle dust, animated photon wave, victory burst, completion sting.
- E2 Puzzle type B (Compton) + rule quick-reference sidebar (handoff variant PUZZLE B).
- E3 Help + Announcements screens (menu icons).
- E4 ×1.5 / 1920×1080 verification across screens; safe-area/scaling pass.

## Dependencies & order

A → B → (C ∥ D) → E. A is the gate: do not build meta systems until the placement verb + physics +
validation feel right (Gate B in doc02). C and D are independent once B's save exists.

## Open decisions (resolve before starting a phase)

1. **Scope of "complete"**: full QED slice (A+B+C+D+E, weeks of work) vs. just the handoff's *visual*
   shell wired to existing I0 physics (much smaller, but the puzzle stays connect-and-tidy, not the
   handoff's tray-placement loop). Recommend the former, phase by phase.
2. **Placement verb vs. I0 connect-and-tidy**: the handoff replaces I0's "tidy pre-placed legs" with
   "place particles from a tray." Confirm we are moving to the tray verb (doc01 §4 intent).
3. **doc-02 content shown in the shell** (ν/quark tray tokens, quark/boson codex categories): keep as
   locked/disabled shell only — do not author the physics — to stay within QED scope discipline.
