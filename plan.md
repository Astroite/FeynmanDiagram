# Plan: Rework Level Select into Pannable/Zoomable Galaxy View

## Context

The current LevelSelectScreen has a fixed 1280x720 layout with a right-side detail card. The user wants a galaxy-style level map that is pannable and zoomable, with levels clustered into galaxy groups, no right info card, click-to-focus, and default centering on current progress.

## Architecture

The canvas is a single child Control (`_canvas`) that owns all level nodes. A virtual camera (`zoom` + `camera_offset`) controls how world space maps to screen space. The canvas captures all input (`MOUSE_FILTER_STOP`), classifies gestures (click vs. drag vs. scroll), and forwards hits to nodes via world-coordinate checking.

**Coordinate system:**
- `screen_to_world(screen_pos) = (screen_pos - _camera_offset) / _zoom`
- Node positions stored in world coords; screen position = world × zoom + camera_offset
- Node sizes use `custom_minimum_size / zoom` so they appear constant on screen

**Rendering (all in `_canvas._draw()`):**
- OrbitField as background per galaxy (each has its own animated orbit rings)
- Orbit rings per galaxy (3–4 rings, varying sizes)
- Connecting line between galaxy centers
- Labels drawn in `_draw()` with size / zoom so they remain readable

**Input flow:**
1. `_canvas._gui_input()` receives raw mouse events
2. Right-click drag (or left-drag with threshold) → pan
3. Scroll wheel → zoom toward cursor
4. Click (displacement < 4px) → check world hit → select node
5. `MOUSE_FILTER_STOP` prevents events leaking to children; node Buttons removed (replaced with `_hit_test`)

## Files to modify

### 1. `game/ui/screens/LevelSelectScreen.gd` — full rewrite
- Remove: `_detail_code`, `_detail_name`, `_detail_preview`, `_enter_button`, `DiagramPreview`, right info card panel
- Add: `_canvas: Control`, `_zoom: float`, `_camera_offset: Vector2`, `_galaxies: Array[Dictionary]`
- Galaxy system:
  - Tutorial galaxy (001–006): center (400, 360), golden-angle radial distribution
  - Chapter 1 galaxy (007): center (900, 300), single node
  - Each galaxy: `{center, orbit_radius, orbit_color, orbit_speed}`
  - Structure for future chapters: `const GALAXIES = [...]`
- Input: `_gui_input()` for pan/zoom/click with gesture classification
- Focus: `_focus_world(world_pos)` — Tween zoom + camera to center node on screen
- Info badge: bottom-center floating label + play button (in HUD layer), shown/hidden on select
- `_select(index)` → store selection, update badge, animate focus
- API unchanged: `setup(catalog)`, signals `level_chosen(spec)`, `back_pressed`

### 2. `game/ui/screens/LevelSelectScreen.tscn` — DELETE (no longer used)
- The screen is now fully code-built (same as before — no tscn was used)

### 3. `game/ui/QuantumHud.gd` — no changes needed
- Interface is unchanged: `LevelSelectScreen.new()`, `.setup(_catalog)`, `.level_chosen`, `.back_pressed`

### 4. `game/ui/widgets/OrbitField.gd` — no changes
- Reused as background decoration per galaxy

### 5. `game/ui/widgets/DiagramPreview.gd` — can be deleted (orphaned after this change)
- Only consumer was LevelSelectScreen's right info card

### 6. `game/tests/test_quantum_hud.gd` — no changes
- Uses `_on_start()` which calls `_start_level(_catalog.spec_at(0))` directly

## Interaction details

- **Pan:** Left-drag with ≥ 4px threshold, or right-drag (no threshold). Updates `_camera_offset`.
- **Zoom:** Scroll wheel, 0.5–2.5 range, 1.1× per step, anchored at cursor position.
- **Click select:** Release with < 4px displacement → `_hit_test(world)` → `_select(index)` → Tween focus.
- **Click empty:** Hit-test miss → deselect, hide badge.
- **Badge:** Shows `_selected_node`'s name_label() + code_label() + "开始" button. Positioned at bottom-center of screen (HUD layer), updated via `_update_badge()` called on camera change.
- **Back button + title:** Remain in HUD layer (screen coords, unaffected by pan/zoom).

## Constants

```
const GALAXIES := [
    { center = Vector2(400, 360), orbit_radius = 180, orbit_color = Color(0.40, 0.62, 1.0, 0.18), orbit_speed = 0.12 },
    { center = Vector2(900, 300), orbit_radius = 80,  orbit_color = Color(0.85, 0.55, 1.0, 0.18), orbit_speed = 0.08 },
]
const GALAXY_ASSIGNMENT := [0, 0, 0, 0, 0, 0, 1]  # tutorial→galaxy 0, chapter1→galaxy 1
const GOLDEN_ANGLE := 2.399963  # radians
```

## Initial view

- `_zoom = 1.0`, `_camera_offset` = screen center − galaxy[0].center = `(640−400, 360−360) = (240, 0)`
- Selects level 0 by default (first level)
- Badge shown for level 001

## Badge layout

```
┌─────────────────────────┐
│  序章 · 01  (dim cyan)  │
│  连接谱线    (white 22px)│
│       [ 开始 ]           │
└─────────────────────────┘
```

Positioned at screen (430, 560), size (420, 130).

## Testing

The existing `test_quantum_hud.gd` calls `_on_start()` directly which bypasses LevelSelectScreen entirely — no breakage expected. No new test changes needed for this iteration since the level-select screen is a visual/interaction layer that doesn't affect gameplay logic.
