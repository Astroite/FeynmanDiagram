class_name LevelSelectScreen
extends Control

# A real list of the catalog's levels. Selecting a row updates the detail panel
# (with a live thumbnail of that level's actual graph); "进入关卡" loads it.

signal level_chosen(spec: Resource)
signal back_pressed

var _catalog: LevelCatalog = null
var _selected_index := -1

var _detail_code: Label
var _detail_name: Label
var _detail_preview: DiagramPreview
var _enter_button: Button
var _list_box: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func setup(catalog: LevelCatalog) -> void:
	_catalog = catalog
	_populate_list()
	if _catalog != null and _catalog.count() > 0:
		_select(0)


func _build() -> void:
	add_child(UiFactory.place(UiFactory.label("关卡选择", 30, Color.WHITE), Vector2(54.0, 48.0)))
	add_child(UiFactory.place(UiFactory.label("序章 · 连接与整理", 13, UiTheme.MUTED), Vector2(56.0, 92.0)))

	var back_button := UiFactory.button("返回")
	UiFactory.place(back_button, Vector2(1100.0, 38.0), Vector2(120.0, 42.0))
	back_button.pressed.connect(func(): back_pressed.emit())
	add_child(back_button)

	_list_box = VBoxContainer.new()
	UiFactory.place(_list_box, Vector2(54.0, 140.0), Vector2(380.0, 460.0))
	_list_box.add_theme_constant_override("separation", 8)
	add_child(_list_box)

	var detail := UiFactory.panel(UiTheme.PANEL, UiTheme.BORDER, 14)
	UiFactory.place(detail, Vector2(560.0, 140.0), Vector2(400.0, 460.0))
	add_child(detail)

	_detail_code = UiFactory.label("", 13, UiTheme.CYAN)
	UiFactory.place(_detail_code, Vector2(586.0, 168.0))
	add_child(_detail_code)

	_detail_name = UiFactory.label("", 26, Color.WHITE)
	UiFactory.place(_detail_name, Vector2(586.0, 188.0))
	add_child(_detail_name)

	_detail_preview = DiagramPreview.new()
	UiFactory.place(_detail_preview, Vector2(586.0, 240.0), Vector2(348.0, 220.0))
	add_child(_detail_preview)

	_enter_button = UiFactory.button("进入关卡", true)
	UiFactory.place(_enter_button, Vector2(586.0, 510.0), Vector2(348.0, 50.0))
	_enter_button.disabled = true
	_enter_button.pressed.connect(_on_enter_pressed)
	add_child(_enter_button)


func _populate_list() -> void:
	for child in _list_box.get_children():
		child.queue_free()
	if _catalog == null:
		return
	for index in range(_catalog.count()):
		var spec := _catalog.spec_at(index)
		var row := UiFactory.button("%s   %s" % [spec.code_label(), spec.name_label()])
		row.custom_minimum_size = Vector2(380.0, 48.0)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.pressed.connect(_select.bind(index))
		_list_box.add_child(row)


func _select(index: int) -> void:
	_selected_index = index
	var spec := _catalog.spec_at(index)
	if spec == null:
		return
	_detail_code.text = spec.code_label()
	_detail_name.text = spec.name_label()
	_detail_preview.show_spec(spec)
	_enter_button.disabled = false


func _on_enter_pressed() -> void:
	if _catalog == null or _selected_index < 0:
		return
	var spec := _catalog.spec_at(_selected_index)
	if spec != null:
		level_chosen.emit(spec)
