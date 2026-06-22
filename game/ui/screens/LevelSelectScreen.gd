class_name LevelSelectScreen
extends Control

# Level select, built to the handoff "orbital galaxy" view: the catalog's levels
# sit as glowing nodes on the orbit field around the core; selecting one updates
# the right info card (real code/name + a live diagram preview) and "进入关卡"
# loads it.
#
# Honest-data note: the handoff mockup also showed an overall-progress %, star
# ratings and best-step counts. Those have no backing system yet (no save /
# scoring), so they are intentionally left out rather than faked.

signal level_chosen(spec: Resource)
signal back_pressed

# Hand-placed node anchors around the core, kept clear of the right info card.
const NODE_POSITIONS := [
	Vector2(360.0, 188.0),
	Vector2(205.0, 432.0),
	Vector2(548.0, 470.0),
	Vector2(620.0, 152.0),
	Vector2(300.0, 308.0),
	Vector2(470.0, 250.0),
	Vector2(252.0, 560.0),
]

var _catalog: LevelCatalog = null
var _selected_index := -1

var _detail_code: Label
var _detail_name: Label
var _detail_preview: DiagramPreview
var _enter_button: Button
var _count_label: Label
var _nodes: Array[Button] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func setup(catalog: LevelCatalog) -> void:
	_catalog = catalog
	_populate_nodes()
	if _count_label != null:
		_count_label.text = "序章 · 共 %d 关" % _catalog.count() if _catalog != null else ""
	if _catalog != null and _catalog.count() > 0:
		_select(0)


func _build() -> void:
	var orbit := OrbitField.new()
	orbit.set_anchors_preset(Control.PRESET_FULL_RECT)
	orbit.core_offset = Vector2(400.0, 380.0)
	add_child(orbit)

	var back_button := UiFactory.icon_button("‹")
	UiFactory.place(back_button, Vector2(36.0, 32.0))
	back_button.tooltip_text = "返回"
	back_button.pressed.connect(func(): back_pressed.emit())
	add_child(back_button)

	add_child(UiFactory.place(UiFactory.label("关卡选择", 30, Color.WHITE), Vector2(92.0, 34.0)))
	add_child(UiFactory.place(UiFactory.label("轨道星系视图", 13, UiTheme.MUTED), Vector2(94.0, 76.0)))

	_count_label = UiFactory.label("", 13, UiTheme.MUTED)
	UiFactory.place(_count_label, Vector2(56.0, 638.0))
	add_child(_count_label)

	# Right info card.
	var card := UiFactory.panel(Color(0.10, 0.13, 0.24, 0.82), Color(0.51, 0.63, 0.90, 0.26), 14)
	UiFactory.place(card, Vector2(848.0, 130.0), Vector2(384.0, 470.0))
	add_child(card)

	_detail_code = UiFactory.label("", 12, UiTheme.CYAN)
	UiFactory.place(_detail_code, Vector2(876.0, 156.0))
	add_child(_detail_code)

	_detail_name = UiFactory.label("", 28, Color.WHITE)
	UiFactory.place(_detail_name, Vector2(876.0, 178.0))
	add_child(_detail_name)

	var preview_frame := UiFactory.panel(Color(0.05, 0.07, 0.14, 0.9), Color(0.47, 0.59, 0.86, 0.18), 10)
	UiFactory.place(preview_frame, Vector2(876.0, 232.0), Vector2(328.0, 150.0))
	add_child(preview_frame)

	_detail_preview = DiagramPreview.new()
	UiFactory.place(_detail_preview, Vector2(876.0, 232.0), Vector2(328.0, 150.0))
	add_child(_detail_preview)

	_enter_button = UiFactory.button("进入关卡", true)
	UiFactory.place(_enter_button, Vector2(876.0, 410.0), Vector2(328.0, 50.0))
	_enter_button.disabled = true
	_enter_button.pressed.connect(_on_enter_pressed)
	add_child(_enter_button)


func _populate_nodes() -> void:
	for node in _nodes:
		node.queue_free()
	_nodes.clear()
	if _catalog == null:
		return
	for index in range(_catalog.count()):
		var spec := _catalog.spec_at(index)
		var center: Vector2 = NODE_POSITIONS[index % NODE_POSITIONS.size()]
		var button := _make_node(index)
		UiFactory.place(button, center - Vector2(17.0, 17.0), Vector2(34.0, 34.0))
		add_child(button)
		_nodes.append(button)

		var label := UiFactory.label(spec.name_label(), 12, UiTheme.MUTED)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiFactory.place(label, center + Vector2(-70.0, 22.0), Vector2(140.0, 18.0))
		add_child(label)


func _make_node(index: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(34.0, 34.0)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_select.bind(index))
	_apply_node_style(button, false)
	return button


func _apply_node_style(button: Button, selected: bool) -> void:
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, _node_style(selected))


func _node_style(selected: bool) -> StyleBoxFlat:
	if selected:
		return UiTheme.panel_style(Color(1.0, 0.83, 0.42, 0.95), Color(1.0, 0.86, 0.46, 1.0), 17)
	return UiTheme.panel_style(Color(0.62, 0.82, 1.0, 0.85), Color(0.40, 0.66, 1.0, 0.85), 17)


func _select(index: int) -> void:
	_selected_index = index
	var spec := _catalog.spec_at(index)
	if spec == null:
		return
	_detail_code.text = spec.code_label()
	_detail_name.text = spec.name_label()
	_detail_preview.show_spec(spec)
	_enter_button.disabled = false
	for node_index in range(_nodes.size()):
		_apply_node_style(_nodes[node_index], node_index == index)


func _on_enter_pressed() -> void:
	if _catalog == null or _selected_index < 0:
		return
	var spec := _catalog.spec_at(_selected_index)
	if spec != null:
		level_chosen.emit(spec)
