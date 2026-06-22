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
	_menu = MenuScreen.new()
	_menu.start_pressed.connect(_on_start)
	_menu.continue_pressed.connect(_on_continue)
	_menu.levels_pressed.connect(func(): _show(Screen.LEVEL_SELECT))
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
	_menu.set_can_continue(true)
	_show(Screen.PUZZLE)


func _on_level_loaded(_spec: Resource) -> void:
	pass


func _on_level_complete(spec: Resource) -> void:
	_victory.bind_result(spec, spec != null and _catalog.has_next(spec.level_id))
	_show(Screen.VICTORY)


func _show(screen: int) -> void:
	_screen = screen
	_menu.visible = screen == Screen.MENU
	_level_select.visible = screen == Screen.LEVEL_SELECT
	_puzzle.visible = screen == Screen.PUZZLE
	_victory.visible = screen == Screen.VICTORY
	_sync_runtime_visibility()


# Gameplay rendering + interaction are live only on the puzzle screen.
func _sync_runtime_visibility() -> void:
	if runtime == null:
		return
	var gameplay_visible := _screen == Screen.PUZZLE
	runtime.set_visual_layer_visible(gameplay_visible)
	runtime.set_interaction_enabled(gameplay_visible)
