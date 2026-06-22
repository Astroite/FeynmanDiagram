class_name PuzzleHud
extends Control

# In-level HUD, kept deliberately minimal: the centre is the play area, chrome lives
# in the corners. Everything shown is read live from LevelRuntime / GraphModel.
#
#   top-left     back + level identity
#   top-centre   one-line validator status (real rule/topology feedback)
#   top-right    hint
#   bottom-right undo / redo / restart
#   bottom-centre tray of placeable particle legs (only when some are unplaced)
#
# Tray placement verb: each token is a free (unplaced) half-edge. Pressing a token
# starts a half-edge drag via CurveInteraction; moving previews the line; releasing
# on a vertex socket connects it. This reuses the existing connect gesture — no new
# physics or commands. Completion is detected automatically, so there is no manual
# verify button.
#
# The root has mouse_filter IGNORE and chrome sits only in the corners + bottom, so
# pointer drags across the empty centre reach gameplay via the unhandled-input pass.

signal back_pressed

const CHIP := 46.0
const TRAY_SEP := 12.0
const TRAY_PAD := 14.0
const TRAY_Y := 624.0

var runtime: LevelRuntime = null

var _code_label: Label
var _name_label: Label
var _status_label: Label
var _undo_button: Button
var _redo_button: Button
var _delete_button: Button
var _tray_pill: Panel
var _token_box: HBoxContainer
var _drag_chip: Panel
var _drag_chip_label: Label
var _snap_hint: Panel
var _snap_hint_label: Label

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
	# Top-left: back + level identity.
	var back_button := UiFactory.icon_button("‹")
	UiFactory.place(back_button, Vector2(32.0, 28.0))
	back_button.tooltip_text = "返回 (Esc)"
	back_button.pressed.connect(func(): back_pressed.emit())
	add_child(back_button)

	_code_label = UiFactory.label("", 11, UiTheme.CYAN)
	UiFactory.place(_code_label, Vector2(90.0, 30.0))
	add_child(_code_label)

	_name_label = UiFactory.label("", 18, Color.WHITE)
	UiFactory.place(_name_label, Vector2(90.0, 44.0))
	add_child(_name_label)

	# Top-centre: one-line validator status.
	_status_label = UiFactory.label("", 13, UiTheme.MUTED)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFactory.place(_status_label, Vector2(390.0, 34.0), Vector2(500.0, 24.0))
	add_child(_status_label)

	# Top-right: hint.
	var hint_button := UiFactory.icon_button("?")
	UiFactory.place(hint_button, Vector2(1206.0, 28.0))
	hint_button.tooltip_text = "提示：显示参考解"
	hint_button.pressed.connect(_on_hint)
	add_child(hint_button)

	# Bottom-right: undo / redo / restart.
	_undo_button = UiFactory.icon_button("↶")
	UiFactory.place(_undo_button, Vector2(1110.0, 636.0))
	_undo_button.tooltip_text = "撤销 (Ctrl+Z)"
	_undo_button.pressed.connect(_on_undo)
	add_child(_undo_button)

	_redo_button = UiFactory.icon_button("↷")
	UiFactory.place(_redo_button, Vector2(1158.0, 636.0))
	_redo_button.tooltip_text = "重做 (Ctrl+Y)"
	_redo_button.pressed.connect(_on_redo)
	add_child(_redo_button)

	var restart_button := UiFactory.icon_button("⟲")
	UiFactory.place(restart_button, Vector2(1206.0, 636.0))
	restart_button.tooltip_text = "重置关卡"
	restart_button.pressed.connect(_on_restart)
	add_child(restart_button)

	# Appears only when something is selected (an endpoint or a line).
	_delete_button = UiFactory.icon_button("删")
	UiFactory.place(_delete_button, Vector2(1062.0, 636.0))
	_delete_button.tooltip_text = "删除选中 (Delete)"
	_delete_button.visible = false
	_delete_button.pressed.connect(_on_delete)
	add_child(_delete_button)

	_build_tray()
	_build_overlays()


func _build_tray() -> void:
	_tray_pill = UiFactory.panel(UiTheme.PANEL, UiTheme.BORDER, 18)
	_tray_pill.visible = false
	add_child(_tray_pill)

	_token_box = HBoxContainer.new()
	_token_box.add_theme_constant_override("separation", int(TRAY_SEP))
	_token_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_token_box)


func _build_overlays() -> void:
	_snap_hint = UiFactory.panel(Color(0.06, 0.20, 0.14, 0.88), UiTheme.GREEN, 12)
	_snap_hint.custom_minimum_size = Vector2(96.0, 28.0)
	_snap_hint.size = Vector2(96.0, 28.0)
	_snap_hint.visible = false
	add_child(_snap_hint)
	_snap_hint_label = UiFactory.label("", 12, UiTheme.GREEN)
	_snap_hint_label.position = Vector2(12.0, 6.0)
	_snap_hint.add_child(_snap_hint_label)

	_drag_chip = Panel.new()
	_drag_chip.add_theme_stylebox_override("panel", UiTheme.panel_style(Color(0.16, 0.12, 0.30, 0.88), UiTheme.PURPLE, 12))
	_drag_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_chip.size = Vector2(CHIP, CHIP)
	_drag_chip.visible = false
	add_child(_drag_chip)
	_drag_chip_label = UiFactory.label("", 20, Color.WHITE)
	_drag_chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_drag_chip_label.size = Vector2(CHIP, CHIP)
	_drag_chip_label.position = Vector2(0.0, 11.0)
	_drag_chip.add_child(_drag_chip_label)


func _process(_delta: float) -> void:
	if not visible or runtime == null:
		return
	_undo_button.disabled = not runtime.can_undo()
	_redo_button.disabled = not runtime.can_redo()
	_delete_button.visible = runtime.has_selection()
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
		_drag_chip.position = event.position - Vector2(CHIP, CHIP) * 0.5
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
	_status_label.add_theme_color_override("font_color", UiTheme.GREEN if status["ok"] else UiTheme.MUTED)


func _refresh_tray() -> void:
	if runtime == null or _token_box == null:
		return
	for child in _token_box.get_children():
		child.queue_free()
	var free_legs := runtime.free_half_edges()
	for half_edge in free_legs:
		_token_box.add_child(_make_token(half_edge))
	_layout_tray(free_legs.size())


# Centre the tray pill at the bottom and size it to hug the chips.
func _layout_tray(count: int) -> void:
	_tray_pill.visible = count > 0
	if count == 0:
		return
	var width := count * CHIP + (count - 1) * TRAY_SEP + TRAY_PAD * 2.0
	var height := CHIP + TRAY_PAD * 2.0
	_tray_pill.size = Vector2(width, height)
	_tray_pill.position = Vector2(640.0 - width * 0.5, TRAY_Y)
	_token_box.position = _tray_pill.position + Vector2(TRAY_PAD, TRAY_PAD)


func _make_token(half_edge: HalfEdge) -> Control:
	var spec := _spec_of(half_edge)
	var tint := UiTheme.TEXT
	if spec != null:
		tint = _particle_color(spec.id)
	var token := Panel.new()
	token.add_theme_stylebox_override("panel", UiTheme.panel_style(Color(0.13, 0.17, 0.32, 0.85), tint, 12))
	token.custom_minimum_size = Vector2(CHIP, CHIP)
	token.mouse_filter = Control.MOUSE_FILTER_STOP
	token.mouse_default_cursor_shape = Control.CURSOR_DRAG
	token.tooltip_text = spec.display_name if spec != null else "连线"
	token.gui_input.connect(_on_token_input.bind(half_edge))

	var symbol := UiFactory.label(spec.symbol if spec != null else "线", 20, tint)
	symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	symbol.size = Vector2(CHIP, CHIP)
	symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	token.add_child(symbol)
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
	_drag_chip.position = get_viewport().get_mouse_position() - Vector2(CHIP, CHIP) * 0.5
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
	_snap_hint_label.text = "→ %s" % String(snap["node"].id).to_upper()
	_snap_hint.position = _to_screen(snap["socket"].world_position()) + Vector2(16.0, -32.0)


func _refresh_header() -> void:
	if runtime == null or runtime.level_spec == null:
		return
	_code_label.text = runtime.level_spec.code_label()
	_name_label.text = runtime.level_spec.name_label()


func _on_level_loaded(_spec: Resource) -> void:
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


func _on_delete() -> void:
	if runtime != null:
		runtime.delete_selected()


# Honest hint for iteration 0: reveal the stored reference solution.
func _on_hint() -> void:
	if runtime != null:
		runtime.apply_reference_solution()


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
