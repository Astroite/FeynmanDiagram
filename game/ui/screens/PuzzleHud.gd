class_name PuzzleHud
extends Control

# In-level HUD. Everything shown is read from the live LevelRuntime / GraphModel:
# the title is the loaded level's, and the status line reflects real graph
# completeness. The old fake warning hint, step counter and decorative particle
# tray are gone (there is no particle-placement verb in iteration 0).
#
# Chrome lives in the corners with mouse_filter IGNORE on the root, so pointer
# drags over the empty canvas reach gameplay via the unhandled-input pass.

signal back_pressed

var runtime: LevelRuntime = null

var _code_label: Label
var _name_label: Label
var _status_label: Label
var _undo_button: Button
var _redo_button: Button
var _flash := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	_build()


func bind_runtime(value: LevelRuntime) -> void:
	runtime = value
	if runtime != null and not runtime.level_loaded.is_connected(_on_level_loaded):
		runtime.level_loaded.connect(_on_level_loaded)
	_refresh_header()


func _build() -> void:
	_code_label = UiFactory.label("", 13, UiTheme.CYAN)
	UiFactory.place(_code_label, Vector2(54.0, 40.0))
	add_child(_code_label)

	_name_label = UiFactory.label("", 22, Color.WHITE)
	UiFactory.place(_name_label, Vector2(54.0, 58.0))
	add_child(_name_label)

	add_child(UiFactory.place(UiFactory.label("拖动顶点、弯折谱线、把自由端吸附到接点。", 13, UiTheme.MUTED), Vector2(54.0, 92.0)))

	_status_label = UiFactory.label("", 14, UiTheme.MUTED)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFactory.place(_status_label, Vector2(340.0, 110.0), Vector2(600.0, 28.0))
	add_child(_status_label)

	var back_button := UiFactory.button("返回")
	UiFactory.place(back_button, Vector2(1140.0, 34.0), Vector2(90.0, 40.0))
	back_button.pressed.connect(func(): back_pressed.emit())
	add_child(back_button)

	# Bottom-left tool cluster.
	_undo_button = UiFactory.icon_button("↶")
	UiFactory.place(_undo_button, Vector2(54.0, 624.0))
	_undo_button.pressed.connect(_on_undo)
	add_child(_undo_button)

	_redo_button = UiFactory.icon_button("↷")
	UiFactory.place(_redo_button, Vector2(104.0, 624.0))
	_redo_button.pressed.connect(_on_redo)
	add_child(_redo_button)

	var restart_button := UiFactory.icon_button("⟲")
	UiFactory.place(restart_button, Vector2(154.0, 624.0))
	restart_button.pressed.connect(_on_restart)
	add_child(restart_button)

	var hint_button := UiFactory.button("提示")
	UiFactory.place(hint_button, Vector2(204.0, 624.0), Vector2(80.0, 42.0))
	hint_button.pressed.connect(_on_hint)
	add_child(hint_button)

	# Bottom-right verify.
	var verify_button := UiFactory.button("对撞验证", true)
	UiFactory.place(verify_button, Vector2(1040.0, 612.0), Vector2(160.0, 54.0))
	verify_button.pressed.connect(_on_verify)
	add_child(verify_button)


func _process(delta: float) -> void:
	if not visible or runtime == null:
		return
	_flash = maxf(0.0, _flash - delta)
	_undo_button.disabled = not runtime.can_undo()
	_redo_button.disabled = not runtime.can_redo()
	_update_status()


func _update_status() -> void:
	if _flash > 0.0:
		_status_label.text = "还不完整 · 仍有未连接的端点"
		_status_label.add_theme_color_override("font_color", UiTheme.WARNING)
	elif runtime.is_level_complete():
		_status_label.text = "拓扑完整 · 图已连通，无悬挂半边"
		_status_label.add_theme_color_override("font_color", UiTheme.GREEN)
	else:
		_status_label.text = "把所有谱线连成一张连通的图"
		_status_label.add_theme_color_override("font_color", UiTheme.MUTED)


func _refresh_header() -> void:
	if runtime == null or runtime.level_spec == null:
		return
	_code_label.text = runtime.level_spec.code_label()
	_name_label.text = runtime.level_spec.name_label()


func _on_level_loaded(_spec: Resource) -> void:
	_flash = 0.0
	_refresh_header()


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
