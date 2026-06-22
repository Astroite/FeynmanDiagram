class_name QuantumHud
extends Control

# Thin screen-stack coordinator. Each screen is a real Control built from native
# nodes (see ui/screens/*). This replaces the old single immediate-mode _draw()
# that hand-registered button rects — controls can no longer be silently dead.

enum Screen { MENU, LEVEL_SELECT, PUZZLE, VICTORY }

var runtime: LevelRuntime = null

var _catalog := LevelCatalog.new()
var _screen := Screen.MENU
var _last_played: Resource = null
var _transition: Tween = null

var _menu: MenuScreen
var _level_select: LevelSelectScreen
var _puzzle: PuzzleHud
var _victory: VictoryScreen


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiTheme.build_theme()
	_build_screens()
	_show(Screen.MENU)


# Wire the runtime once it exists (Main owns it). Keeps the old signal contract:
# completing a level shows Victory; the puzzle HUD mirrors live runtime state.
func bind_level_runtime(value: LevelRuntime) -> void:
	runtime = value
	if runtime == null:
		return
	if not runtime.level_loaded.is_connected(_on_level_loaded):
		runtime.level_loaded.connect(_on_level_loaded)
	if not runtime.level_complete.is_connected(_on_level_complete):
		runtime.level_complete.connect(_on_level_complete)
	_puzzle.bind_runtime(runtime)
	_sync_runtime_visibility()


func _build_screens() -> void:
	_menu = preload("res://ui/screens/MenuScreen.tscn").instantiate()
	_menu.enter_pressed.connect(func(): _show(Screen.LEVEL_SELECT))
	add_child(_menu)

	_level_select = LevelSelectScreen.new()
	_level_select.level_chosen.connect(_start_level)
	_level_select.back_pressed.connect(func(): _show(Screen.MENU))
	add_child(_level_select)
	_level_select.setup(_catalog)

	_puzzle = PuzzleHud.new()
	_puzzle.back_pressed.connect(func(): _show(Screen.MENU))
	add_child(_puzzle)

	_victory = VictoryScreen.new()
	_victory.replay_pressed.connect(_on_continue)
	_victory.next_pressed.connect(_on_next)
	_victory.back_pressed.connect(func(): _show(Screen.MENU))
	add_child(_victory)


func _on_start() -> void:
	_start_level(_catalog.spec_at(0))


func _on_continue() -> void:
	if _last_played != null:
		_start_level(_last_played)


func _on_next() -> void:
	if _last_played == null:
		return
	var next := _catalog.next_of(_last_played.level_id)
	if next != null:
		_start_level(next)


func _start_level(spec: Resource) -> void:
	if spec == null or runtime == null:
		return
	runtime.load_level(spec)
	_last_played = spec
	_show(Screen.PUZZLE)


func _on_level_loaded(_spec: Resource) -> void:
	pass


func _on_level_complete(spec: Resource) -> void:
	_victory.bind_result(spec, spec != null and _catalog.has_next(spec.level_id))
	_show(Screen.VICTORY)


# Screen changes cross-fade with a subtle camera-push (the new screen rises from
# slightly zoomed-out while the old one fades and pushes past) instead of a hard
# cut. State (_screen) and gameplay visibility update synchronously; only the
# visuals animate, so navigation logic and tests are unaffected.
func _show(screen: int) -> void:
	var previous := _screen_node(_screen)
	_screen = screen
	_sync_runtime_visibility()

	var target := _screen_node(screen)
	if _transition != null and _transition.is_valid():
		_transition.kill()
	if previous == target:
		_present_instant(target)
	else:
		_present_transition(previous, target)


func _screen_node(screen: int) -> Control:
	match screen:
		Screen.LEVEL_SELECT:
			return _level_select
		Screen.PUZZLE:
			return _puzzle
		Screen.VICTORY:
			return _victory
		_:
			return _menu


func _all_screens() -> Array:
	return [_menu, _level_select, _puzzle, _victory]


func _present_instant(target: Control) -> void:
	for s: Control in _all_screens():
		s.visible = s == target
		s.modulate.a = 1.0
		s.scale = Vector2.ONE


func _present_transition(previous: Control, target: Control) -> void:
	for s: Control in _all_screens():
		if s != previous and s != target:
			s.visible = false
			s.modulate.a = 1.0
			s.scale = Vector2.ONE

	var center := size * 0.5
	previous.pivot_offset = center
	target.pivot_offset = center
	previous.visible = true
	previous.modulate.a = 1.0
	previous.scale = Vector2.ONE
	target.visible = true
	target.modulate.a = 0.0
	target.scale = Vector2(0.94, 0.94)

	_transition = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_transition.tween_property(target, "modulate:a", 1.0, 0.32)
	_transition.tween_property(target, "scale", Vector2.ONE, 0.40)
	_transition.tween_property(previous, "modulate:a", 0.0, 0.26)
	_transition.tween_property(previous, "scale", Vector2(1.06, 1.06), 0.40)
	_transition.chain().tween_callback(func():
		previous.visible = false
		previous.modulate.a = 1.0
		previous.scale = Vector2.ONE
	)


# Gameplay rendering + interaction are live only on the puzzle screen.
func _sync_runtime_visibility() -> void:
	if runtime == null:
		return
	var gameplay_visible := _screen == Screen.PUZZLE
	runtime.set_visual_layer_visible(gameplay_visible)
	runtime.set_interaction_enabled(gameplay_visible)
