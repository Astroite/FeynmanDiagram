class_name PuzzleHud
extends Control

# In-level HUD. Everything shown is read from the live LevelRuntime / GraphModel:
# title, status (real validator output), step/vertex counter, and the tray of
# placeable particle legs.
#
# Tray placement verb (handoff core loop): each token is a free (unplaced)
# half-edge. Pressing a token starts a half-edge drag via CurveInteraction; moving
# the pointer previews the line; releasing on a vertex socket connects it. This
# reuses the existing connect gesture — no new physics or commands.
#
# Chrome lives in the corners + bottom bar with mouse_filter IGNORE on the root, so
# pointer drags over the empty canvas reach gameplay via the unhandled-input pass.

signal back_pressed

const TRAY_RECT := Rect2(54.0, 568.0, 1172.0, 118.0)
const CHIP_SIZE := Vector2(56.0, 56.0)

var runtime: LevelRuntime = null

var _code_label: Label
var _name_label: Label
var _status_label: Label
var _counter_label: Label
var _undo_button: Button
var _redo_button: Button
var _verify_button: Button
var _token_box: HBoxContainer
var _tray_empty_label: Label
var _drag_chip: Panel
var _drag_chip_label: Label
var _snap_hint: Panel
var _snap_hint_label: Label

var _flash := 0.0
var _placing := false
var _placing_half_edge: HalfEdge = null
var _connected_model: GraphModel = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	_build()


func bind_runtime(value: LevelRuntime) -> void:
	runtime = value
	if runtime != null and not runtime.level_loaded.is_connected(_on_level_loaded):
		runtime.level_loaded.connect(_on_level_loaded)
	_on_level_loaded(null)


func _build() -> void:
	_code_label = UiFactory.label("", 13, UiTheme.CYAN)
	UiFactory.place(_code_label, Vector2(54.0, 40.0))
	add_child(_code_label)

	_name_label = UiFactory.label("", 22, Color.WHITE)
	UiFactory.place(_name_label, Vector2(54.0, 58.0))
	add_child(_name_label)

	add_child(UiFactory.place(UiFactory.label("从托盘拖出粒子，连到顶点，拼出守恒的费曼图。", 13, UiTheme.MUTED), Vector2(54.0, 92.0)))

	_status_label = UiFactory.label("", 14, UiTheme.MUTED)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFactory.place(_status_label, Vector2(340.0, 110.0), Vector2(600.0, 28.0))
	add_child(_status_label)

	# Top-right tool cluster.
	_undo_button = UiFactory.icon_button("↶")
	UiFactory.place(_undo_button, Vector2(904.0, 34.0))
	_undo_button.pressed.connect(_on_undo)
	add_child(_undo_button)

	_redo_button = UiFactory.icon_button("↷")
	UiFactory.place(_redo_button, Vector2(952.0, 34.0))
	_redo_button.pressed.connect(_on_redo)
	add_child(_redo_button)

	var restart_button := UiFactory.icon_button("⟲")
	UiFactory.place(restart_button, Vector2(1000.0, 34.0))
	restart_button.pressed.connect(_on_restart)
	add_child(restart_button)

	var hint_button := UiFactory.button("提示")
	UiFactory.place(hint_button, Vector2(1052.0, 34.0), Vector2(70.0, 42.0))
	hint_button.pressed.connect(_on_hint)
	add_child(hint_button)

	var back_button := UiFactory.button("返回")
	UiFactory.place(back_button, Vector2(1134.0, 34.0), Vector2(90.0, 42.0))
	back_button.pressed.connect(func(): back_pressed.emit())
	add_child(back_button)

	_build_tray()
	_build_overlays()


func _build_tray() -> void:
	var tray := UiFactory.panel(UiTheme.PANEL, UiTheme.BORDER, 16)
	UiFactory.place(tray, TRAY_RECT.position, TRAY_RECT.size)
	add_child(tray)

	add_child(UiFactory.place(UiFactory.label("可用粒子 · 拖拽放置", 11, UiTheme.DIM), TRAY_RECT.position + Vector2(26.0, 18.0)))

	_token_box = HBoxContainer.new()
	_token_box.add_theme_constant_override("separation", 14)
	_token_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFactory.place(_token_box, TRAY_RECT.position + Vector2(26.0, 40.0))
	add_child(_token_box)

	_tray_empty_label = UiFactory.label("所有粒子已放置 · 点击对撞验证", 13, UiTheme.MUTED)
	UiFactory.place(_tray_empty_label, TRAY_RECT.position + Vector2(26.0, 56.0))
	add_child(_tray_empty_label)

	_counter_label = UiFactory.label("", 20, Color(0.81, 0.91, 1.0, 1.0))
	UiFactory.place(_counter_label, Vector2(948.0, TRAY_RECT.position.y + 46.0))
	add_child(_counter_label)
	add_child(UiFactory.place(UiFactory.label("顶点 / 步数", 11, UiTheme.DIM), Vector2(948.0, TRAY_RECT.position.y + 26.0)))

	_verify_button = UiFactory.button("对撞验证", true)
	UiFactory.place(_verify_button, Vector2(1040.0, TRAY_RECT.position.y + 32.0), Vector2(160.0, 54.0))
	_verify_button.pressed.connect(_on_verify)
	add_child(_verify_button)


func _build_overlays() -> void:
	_snap_hint = UiFactory.panel(Color(0.06, 0.20, 0.14, 0.85), UiTheme.GREEN, 14)
	_snap_hint.custom_minimum_size = Vector2(140.0, 30.0)
	_snap_hint.size = Vector2(140.0, 30.0)
	_snap_hint.visible = false
	add_child(_snap_hint)
	_snap_hint_label = UiFactory.label("", 12, UiTheme.GREEN)
	_snap_hint_label.position = Vector2(12.0, 7.0)
	_snap_hint.add_child(_snap_hint_label)

	_drag_chip = Panel.new()
	_drag_chip.add_theme_stylebox_override("panel", UiTheme.panel_style(Color(0.16, 0.12, 0.30, 0.85), UiTheme.PURPLE, 13))
	_drag_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_chip.size = CHIP_SIZE
	_drag_chip.visible = false
	add_child(_drag_chip)
	_drag_chip_label = UiFactory.label("", 20, Color.WHITE)
	_drag_chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_drag_chip_label.size = CHIP_SIZE
	_drag_chip_label.position = Vector2(0.0, 14.0)
	_drag_chip.add_child(_drag_chip_label)


func _process(delta: float) -> void:
	if not visible or runtime == null:
		return
	_flash = maxf(0.0, _flash - delta)
	_undo_button.disabled = not runtime.can_undo()
	_redo_button.disabled = not runtime.can_redo()
	_counter_label.text = "%d · %d" % [runtime.vertex_count(), runtime.step_count()]
	_update_status()


# Tray placement drag is driven here so the gesture continues after the pointer
# leaves the token; events are consumed so gameplay/world input ignores them.
func _input(event: InputEvent) -> void:
	if not _placing or runtime == null:
		return
	var interaction = runtime.curve_interaction
	if interaction == null:
		return
	if event is InputEventMouseMotion:
		var world := _to_world(event.position)
		interaction.handle_pointer_moved(world)
		_drag_chip.position = event.position - CHIP_SIZE * 0.5
		_update_snap_hint(interaction, world)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		interaction.handle_pointer_up(_to_world(event.position))
		_end_placement()
		accept_event()


func _update_status() -> void:
	# Real validator output (topology or QED); on failure it names the offending
	# rule/vertex, e.g. "顶点 V1 费米子流向不连续".
	var status := runtime.validation_status()
	_status_label.text = String(status["message"])
	var color := UiTheme.MUTED
	if status["ok"]:
		color = UiTheme.GREEN
	elif _flash > 0.0:
		color = UiTheme.WARNING
	_status_label.add_theme_color_override("font_color", color)


func _refresh_tray() -> void:
	if runtime == null or _token_box == null:
		return
	for child in _token_box.get_children():
		child.queue_free()
	var free_legs := runtime.free_half_edges()
	_tray_empty_label.visible = free_legs.is_empty()
	for half_edge in free_legs:
		_token_box.add_child(_make_token(half_edge))


func _make_token(half_edge: HalfEdge) -> Control:
	var spec := _spec_of(half_edge)
	var tint := UiTheme.TEXT
	if spec != null:
		tint = _particle_color(spec.id)
	var token := Panel.new()
	token.add_theme_stylebox_override("panel", UiTheme.panel_style(Color(0.13, 0.17, 0.32, 0.80), tint, 13))
	token.custom_minimum_size = Vector2(66.0, 70.0)
	token.mouse_filter = Control.MOUSE_FILTER_STOP
	token.mouse_default_cursor_shape = Control.CURSOR_DRAG
	token.gui_input.connect(_on_token_input.bind(half_edge))

	var symbol := UiFactory.label(spec.symbol if spec != null else "线", 20, tint)
	symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol.size = Vector2(66.0, 26.0)
	symbol.position = Vector2(0.0, 10.0)
	token.add_child(symbol)

	var name_label := UiFactory.label(spec.display_name if spec != null else "连线", 10, UiTheme.MUTED)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.size = Vector2(66.0, 16.0)
	name_label.position = Vector2(0.0, 44.0)
	token.add_child(name_label)
	return token


func _on_token_input(event: InputEvent, half_edge: HalfEdge) -> void:
	if _placing or runtime == null:
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	var interaction = runtime.curve_interaction
	if interaction == null or not interaction.has_method("begin_half_edge_placement"):
		return
	var world := _to_world(get_viewport().get_mouse_position())
	if not interaction.begin_half_edge_placement(half_edge, world):
		return
	_placing = true
	_placing_half_edge = half_edge
	var spec := _spec_of(half_edge)
	_drag_chip_label.text = spec.symbol if spec != null else "?"
	_drag_chip.position = get_viewport().get_mouse_position() - CHIP_SIZE * 0.5
	_drag_chip.visible = true
	accept_event()


func _end_placement() -> void:
	_placing = false
	_placing_half_edge = null
	_drag_chip.visible = false
	_snap_hint.visible = false
	_refresh_tray()


func _update_snap_hint(interaction, world: Vector2) -> void:
	var snap: Dictionary = interaction.find_snap_socket(world, -1.0, _placing_half_edge)
	if snap.is_empty():
		_snap_hint.visible = false
		return
	_snap_hint.visible = true
	_snap_hint_label.text = "吸附到顶点 %s" % String(snap["node"].id).to_upper()
	_snap_hint.position = _to_screen(snap["socket"].world_position()) + Vector2(18.0, -34.0)


func _refresh_header() -> void:
	if runtime == null or runtime.level_spec == null:
		return
	_code_label.text = runtime.level_spec.code_label()
	_name_label.text = runtime.level_spec.name_label()


func _on_level_loaded(_spec: Resource) -> void:
	_flash = 0.0
	_placing = false
	_refresh_header()
	if runtime != null and runtime.graph_model != null and runtime.graph_model != _connected_model:
		_connected_model = runtime.graph_model
		if not _connected_model.topology_changed.is_connected(_refresh_tray):
			_connected_model.topology_changed.connect(_refresh_tray)
	_refresh_tray()


func _on_undo() -> void:
	if runtime != null:
		runtime.undo()


func _on_redo() -> void:
	if runtime != null:
		runtime.redo()


func _on_restart() -> void:
	if runtime != null and runtime.level_spec != null:
		runtime.load_level(runtime.level_spec)


# Honest hint for iteration 0: reveal the stored reference solution.
func _on_hint() -> void:
	if runtime != null:
		runtime.apply_reference_solution()


func _on_verify() -> void:
	if runtime == null:
		return
	if not runtime.evaluate_completeness():
		_flash = 1.3


func _spec_of(half_edge: HalfEdge) -> ParticleSpec:
	var particle_id := half_edge.particle_id
	if String(particle_id).is_empty() and half_edge.edge != null:
		particle_id = half_edge.edge.particle_id
	return ParticleSpec.get_spec(particle_id)


func _particle_color(particle_id: StringName) -> Color:
	match String(particle_id):
		"electron", "anti_muon":
			return Color(0.92, 0.96, 1.0, 1.0)
		"positron", "muon":
			return Color(0.78, 0.70, 1.0, 1.0)
		"photon":
			return Color(0.50, 0.90, 0.93, 1.0)
		_:
			return UiTheme.TEXT


func _to_world(screen_pos: Vector2) -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return screen_pos
	return vp.get_canvas_transform().affine_inverse() * screen_pos


func _to_screen(world_pos: Vector2) -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return world_pos
	return vp.get_canvas_transform() * world_pos
