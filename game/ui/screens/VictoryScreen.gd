class_name VictoryScreen
extends Control

# Shown when a level's graph becomes complete. Only real facts: which level was
# solved and whether a next level exists. Step/time/star scoring is intentionally
# absent until those are actually tracked.

signal replay_pressed
signal next_pressed
signal back_pressed

var _code_label: Label
var _name_label: Label
var _next_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func bind_result(spec: Resource, has_next: bool) -> void:
	if spec != null:
		_code_label.text = spec.code_label()
		_name_label.text = spec.name_label()
	_next_button.disabled = not has_next


func _build() -> void:
	var orb := ParticleOrb.new()
	orb.tint = UiTheme.GREEN
	UiFactory.place(orb, Vector2(240.0, 240.0), Vector2(180.0, 180.0))
	add_child(orb)

	_code_label = UiFactory.label("", 13, UiTheme.CYAN)
	UiFactory.place(_code_label, Vector2(560.0, 212.0))
	add_child(_code_label)

	add_child(UiFactory.place(UiFactory.label("对撞成功", 56, Color.WHITE), Vector2(560.0, 240.0)))

	_name_label = UiFactory.label("", 24, UiTheme.TEXT)
	UiFactory.place(_name_label, Vector2(560.0, 312.0))
	add_child(_name_label)

	add_child(UiFactory.place(UiFactory.label("拓扑完整 · 图已连通，无悬挂半边。", 15, UiTheme.GREEN), Vector2(560.0, 356.0)))

	var replay_button := UiFactory.button("重玩")
	UiFactory.place(replay_button, Vector2(560.0, 470.0), Vector2(150.0, 54.0))
	replay_button.pressed.connect(func(): replay_pressed.emit())
	add_child(replay_button)

	_next_button = UiFactory.button("下一关", true)
	UiFactory.place(_next_button, Vector2(726.0, 470.0), Vector2(220.0, 54.0))
	_next_button.pressed.connect(func(): next_pressed.emit())
	add_child(_next_button)

	var back_button := UiFactory.button("返回菜单")
	UiFactory.place(back_button, Vector2(962.0, 470.0), Vector2(150.0, 54.0))
	back_button.pressed.connect(func(): back_pressed.emit())
	add_child(back_button)
