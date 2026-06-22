class_name MenuScreen
extends Control

# Main menu. Honest entries only: Codex and full Settings were removed because no
# system backs them yet (deferred to a later iteration). "Continue" is disabled
# until a level has actually been played this session.

signal start_pressed
signal continue_pressed
signal levels_pressed

var _continue_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func set_can_continue(can_continue: bool) -> void:
	if _continue_button != null:
		_continue_button.disabled = not can_continue


func _build() -> void:
	var logo := LogoMark.new()
	UiFactory.place(logo, Vector2(83.0, 186.0), Vector2(80.0, 80.0))
	add_child(logo)

	add_child(UiFactory.place(UiFactory.label("量子对撞师", 56, Color.WHITE), Vector2(184.0, 198.0)))
	add_child(UiFactory.place(UiFactory.label("QUANTUM RESONANCE", 16, Color(0.67, 0.71, 0.85, 1.0)), Vector2(190.0, 276.0)))
	add_child(UiFactory.place(UiFactory.label("在量子深处，因碰撞而生的秩序。", 17, UiTheme.MUTED), Vector2(92.0, 320.0)))

	var start_button := UiFactory.button("开始游戏", true)
	UiFactory.place(start_button, Vector2(90.0, 430.0), Vector2(300.0, 56.0))
	start_button.pressed.connect(func(): start_pressed.emit())
	add_child(start_button)

	_continue_button = UiFactory.button("继续游戏")
	UiFactory.place(_continue_button, Vector2(90.0, 498.0), Vector2(300.0, 50.0))
	_continue_button.disabled = true
	_continue_button.pressed.connect(func(): continue_pressed.emit())
	add_child(_continue_button)

	var levels_button := UiFactory.button("关卡选择")
	UiFactory.place(levels_button, Vector2(90.0, 558.0), Vector2(300.0, 50.0))
	levels_button.pressed.connect(func(): levels_pressed.emit())
	add_child(levels_button)

	add_child(UiFactory.place(UiFactory.label("v0.1.0  ITERATION 0", 11, UiTheme.DIM), Vector2(90.0, 686.0)))
