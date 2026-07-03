class_name LevelSelectScreen
extends Control

# Pannable/zoomable galaxy-style level map. Levels are clustered into "galaxies"
# (tutorial galaxy, chapter 1 galaxy, etc.) with orbital ring decorations.
#
# Pan: left-drag (≥ 4px threshold) or right-drag (no threshold).
# Zoom: scroll wheel, anchored at cursor position (0.5–2.5× range).
# Click: selects a level and focuses the camera on it; shows a badge with "开始".
# The right info card is gone; the badge is the sole enter mechanism.

signal level_chosen(spec: Resource)
signal back_pressed

# Galaxy cluster definitions. Each level in the catalog is assigned to a galaxy
# via GALAXY_ASSIGNMENT. New chapters add entries here.
const GALAXIES: Array[Dictionary] = [
	{"center": Vector2(400.0, 360.0), "orbit_radius": 180.0,
	 "orbit_color": Color(0.40, 0.62, 1.0, 0.18), "orbit_speed": 0.12,
	 "label": "序章"},
	{"center": Vector2(900.0, 300.0), "orbit_radius": 80.0,
	 "orbit_color": Color(0.85, 0.55, 1.0, 0.18), "orbit_speed": 0.08,
	 "label": "第一幕"},
]
# Per-catalog-index galaxy assignment: 0 = tutorial, 1 = chapter 1.
const GALAXY_ASSIGNMENT: Array[int] = [0, 0, 0, 0, 0, 0, 1]
const GOLDEN_ANGLE := 2.399963  # ~137.5° — spiral distribution

const DRAG_THRESHOLD := 4.0
const ZOOM_MIN := 0.5
const ZOOM_MAX := 2.5
const ZOOM_STEP := 1.1

const BADGE_WIDTH := 360.0
const BADGE_HEIGHT := 120.0
const BADGE_OFFSET_Y := 20.0

var _catalog: LevelCatalog = null
var _selected_index := -1
var _nodes: Array[Dictionary] = []   # [{index, world, galaxy}]

var _canvas: Control
var _zoom := 1.0
var _camera_offset := Vector2.ZERO

var _badge_panel: Panel
var _badge_code: Label
var _badge_name: Label
var _badge_play: Button

var _dragging := false
var _drag_start_screen := Vector2.ZERO
var _drag_camera_at_start := Vector2.ZERO
var _focus_tween: Tween = null
var _time := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	_update_transform()
	queue_redraw()


func setup(catalog: LevelCatalog) -> void:
	_catalog = catalog
	_populate_nodes()
	if _catalog != null and _catalog.count() > 0:
		_select(0)


# ── Build ──────────────────────────────────────────────────────────────────────

func _build() -> void:
	# Canvas: owns all level nodes and galaxy decorations. Captures all input.
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.gui_input.connect(_on_canvas_input)
	add_child(_canvas)

	# HUD layer (screen coords, unaffected by pan/zoom).
	var back_button := UiFactory.icon_button("‹")
	UiFactory.place(back_button, Vector2(36.0, 32.0))
	back_button.tooltip_text = "返回"
	back_button.pressed.connect(func(): back_pressed.emit())
	add_child(back_button)
	add_child(UiFactory.place(UiFactory.label("星系视图", 22, UiTheme.TEXT), Vector2(92.0, 36.0)))

	_build_badge()

	# Initial camera: center on galaxy 0.
	var g0_center: Vector2 = GALAXIES[0]["center"]
	_camera_offset = Vector2(640.0, 360.0) - g0_center
	_zoom = 1.0
	_update_transform()


func _build_badge() -> void:
	var bg := Color(0.08, 0.10, 0.20, 0.92)
	var border := Color(0.50, 0.66, 1.0, 0.35)
	_badge_panel = UiFactory.panel(bg, border, 14)
	UiFactory.place(_badge_panel, Vector2(640.0 - BADGE_WIDTH * 0.5, 580.0), Vector2(BADGE_WIDTH, BADGE_HEIGHT))
	_badge_panel.visible = false
	add_child(_badge_panel)

	_badge_code = UiFactory.label("", 12, UiTheme.CYAN)
	UiFactory.place(_badge_code, Vector2(640.0 - BADGE_WIDTH * 0.5 + 20.0, 592.0))
	_badge_code.visible = false
	add_child(_badge_code)

	_badge_name = UiFactory.label("", 22, Color.WHITE)
	UiFactory.place(_badge_name, Vector2(640.0 - BADGE_WIDTH * 0.5 + 20.0, 612.0))
	_badge_name.visible = false
	add_child(_badge_name)

	_badge_play = UiFactory.button("开始", true)
	UiFactory.place(_badge_play, Vector2(640.0 - 80.0, 648.0), Vector2(160.0, 40.0))
	_badge_play.visible = false
	_badge_play.pressed.connect(_on_badge_play)
	add_child(_badge_play)


# ── Nodes ──────────────────────────────────────────────────────────────────────

func _populate_nodes() -> void:
	for node_info in _nodes:
		if node_info.has("label_node") and node_info["label_node"] != null:
			node_info["label_node"].queue_free()
	_nodes.clear()
	if _catalog == null:
		return

	for index in range(_catalog.count()):
		var spec := _catalog.spec_at(index)
		var galaxy_index: int = GALAXY_ASSIGNMENT[index] if index < GALAXY_ASSIGNMENT.size() else 0
		var galaxy: Dictionary = GALAXIES[galaxy_index]
		var world := _node_world_position(index, galaxy)
		var label_node := _make_node_label(spec.name_label(), world, galaxy)
		_canvas.add_child(label_node)
		_nodes.append({"index": index, "world": world, "galaxy": galaxy_index, "label_node": label_node})


func _node_world_position(index: int, galaxy: Dictionary) -> Vector2:
	var local_index := index
	for i in range(min(index, GALAXY_ASSIGNMENT.size())):
		if GALAXY_ASSIGNMENT[i] != GALAXY_ASSIGNMENT[index]:
			local_index -= 1
	var angle := GOLDEN_ANGLE * float(local_index)
	var radius := 55.0 + float(local_index) * 30.0
	return galaxy["center"] + Vector2(cos(angle), sin(angle)) * radius


func _make_node_label(text: String, world: Vector2, _galaxy: Dictionary) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", UiTheme.MUTED)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(140.0, 18.0)
	label.position = world + Vector2(-70.0, 18.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


# ── Select ─────────────────────────────────────────────────────────────────────

func _select(index: int) -> void:
	_selected_index = index
	var spec := _catalog.spec_at(index)
	_badge_code.text = spec.code_label()
	_badge_name.text = spec.name_label()
	_show_badge(true)
	queue_redraw()


func _show_badge(make_visible: bool) -> void:
	_badge_panel.visible = make_visible
	_badge_code.visible = make_visible
	_badge_name.visible = make_visible
	_badge_play.visible = make_visible


func _on_badge_play() -> void:
	if _catalog == null or _selected_index < 0:
		return
	var spec := _catalog.spec_at(_selected_index)
	if spec != null:
		level_chosen.emit(spec)


# ── Camera ─────────────────────────────────────────────────────────────────────

func _update_transform() -> void:
	# Canvas stays at (0,0) with scale (1,1) so it covers the full screen and
	# captures all input. The camera transform is applied to content only:
	# labels get repositioned/scaled; _draw() uses _world_to_screen().
	_canvas.position = Vector2.ZERO
	_canvas.scale = Vector2.ONE
	# Re-position labels at screen coords (inverse-scaled so they stay readable).
	for node_info in _nodes:
		var label: Label = node_info["label_node"]
		var world: Vector2 = node_info["world"]
		var screen: Vector2 = _world_to_screen(world)
		label.position = screen + Vector2(-70.0, 18.0)
		var inv_z := 1.0 / maxf(_zoom, 0.01)
		label.scale = Vector2(inv_z, inv_z)


func _focus_world(world: Vector2, target_zoom: float) -> void:
	if _focus_tween != null and _focus_tween.is_valid():
		_focus_tween.kill()

	var target_offset := Vector2(640.0, 360.0) - world * target_zoom

	_focus_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_focus_tween.set_parallel(true)
	_focus_tween.tween_property(self, "_zoom", target_zoom, 0.35)
	_focus_tween.tween_property(self, "_camera_offset", target_offset, 0.35)


func _world_to_screen(world: Vector2) -> Vector2:
	return world * _zoom + _camera_offset


# ── Input ──────────────────────────────────────────────────────────────────────

func _on_canvas_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var delta := ZOOM_STEP if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / ZOOM_STEP
			var new_zoom := clampf(_zoom * delta, ZOOM_MIN, ZOOM_MAX)
			if not is_equal_approx(new_zoom, _zoom):
				var mouse_before := _screen_to_world(mb.position)
				_zoom = new_zoom
				var mouse_after := _screen_to_world(mb.position)
				_camera_offset += (mouse_after - mouse_before) * _zoom
				_update_transform()
			return

		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
				_dragging = false
				_drag_start_screen = mb.position
				_drag_camera_at_start = _camera_offset
		else:
			# Release.
			if mb.button_index == MOUSE_BUTTON_LEFT:
				var disp := mb.position - _drag_start_screen
				if disp.length() < DRAG_THRESHOLD:
					_try_click(mb.position)
				_dragging = false
			elif mb.button_index == MOUSE_BUTTON_RIGHT:
				_dragging = false

	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			var delta_screen: Vector2 = (event as InputEventMouseMotion).position - _drag_start_screen
			if delta_screen.length() >= DRAG_THRESHOLD:
				_dragging = true
			if _dragging:
				_camera_offset = _drag_camera_at_start + delta_screen
				_update_transform()


func _screen_to_world(screen: Vector2) -> Vector2:
	return (screen - _camera_offset) / maxf(_zoom, 0.001)


func _try_click(screen: Vector2) -> void:
	var world := _screen_to_world(screen)
	var hit_radius := 22.0 / maxf(_zoom, 0.001)
	for node_info in _nodes:
		var dist: float = (node_info["world"] - world).length()
		if dist < hit_radius:
			_select(node_info["index"])
			var target_zoom := clampf(_zoom * 1.25, 1.0, ZOOM_MAX)
			_focus_world(node_info["world"], target_zoom)
			return
	# Clicked empty space → deselect.
	_selected_index = -1
	_show_badge(false)
	queue_redraw()


# ── Draw ───────────────────────────────────────────────────────────────────────

func _draw() -> void:
	_draw_connecting_line()
	_draw_orbit_rings()
	_draw_node_circles()
	_draw_galaxy_labels()


func _draw_connecting_line() -> void:
	if GALAXIES.size() < 2:
		return
	var s0 := _world_to_screen(GALAXIES[0]["center"])
	var s1 := _world_to_screen(GALAXIES[1]["center"])
	draw_line(s0, s1, Color(0.40, 0.56, 1.0, 0.10), 1.5, true)


func _draw_orbit_rings() -> void:
	for galaxy in GALAXIES:
		var center_screen: Vector2 = _world_to_screen(galaxy["center"])
		var r1: float = galaxy["orbit_radius"] * _zoom
		var r2: float = r1 * 0.55
		draw_arc(center_screen, r1, 0.0, TAU, 64, galaxy["orbit_color"], 1.2, true)
		draw_arc(center_screen, r2, 0.0, TAU, 48, galaxy["orbit_color"] * Color(1, 1, 1, 0.6), 1.0, true)
		# Core glow.
		for i in range(8, 0, -1):
			var t := float(i) / 8.0
			draw_circle(center_screen, 28.0 * t * _zoom, Color(0.50, 0.72, 1.0, 0.04 * (1.0 - t)))


func _draw_node_circles() -> void:
	var base_radius := 14.0  # screen pixels — constant regardless of zoom
	for node_info in _nodes:
		var screen := _world_to_screen(node_info["world"])
		var is_selected: bool = node_info["index"] == _selected_index
		var galaxy_idx: int = node_info["galaxy"]
		var base_color: Color = GALAXIES[galaxy_idx]["orbit_color"] * Color(1.8, 1.8, 1.8, 5.0)
		# Subtle breathing pulse — each node has its own phase offset.
		var breathe: float = 1.0 + sin(_time * 1.4 + float(node_info["index"]) * 1.1) * 0.08
		var radius: float = base_radius * breathe
		if is_selected:
			draw_circle(screen, radius + 5.0, Color(1.0, 0.82, 0.38, 0.45))
			draw_circle(screen, radius, Color(1.0, 0.86, 0.46, 1.0))
		else:
			draw_circle(screen, radius, base_color)


func _draw_galaxy_labels() -> void:
	for i in range(GALAXIES.size()):
		var galaxy: Dictionary = GALAXIES[i]
		var galaxy_label_screen: Vector2 = _world_to_screen(galaxy["center"] + Vector2(0.0, galaxy["orbit_radius"] + 40.0))
		var font_size := maxi(11, int(13.0 / maxf(_zoom, 0.01)))
		draw_string(ThemeDB.fallback_font, galaxy_label_screen, galaxy["label"],
			HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.50, 0.60, 0.82, 0.55))
