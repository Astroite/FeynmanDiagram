class_name QuantumHud
extends Control

enum Screen { MENU, LEVEL_SELECT, PUZZLE, VICTORY, SETTINGS, CODEX }

const REF_SIZE := Vector2(1280.0, 720.0)

const COLOR_TEXT := Color(0.88, 0.92, 1.0, 1.0)
const COLOR_MUTED := Color(0.56, 0.61, 0.75, 1.0)
const COLOR_DIM := Color(0.36, 0.41, 0.56, 1.0)
const COLOR_CYAN := Color(0.42, 0.84, 1.0, 1.0)
const COLOR_BLUE := Color(0.23, 0.47, 1.0, 1.0)
const COLOR_PURPLE := Color(0.60, 0.42, 1.0, 1.0)
const COLOR_GREEN := Color(0.37, 0.88, 0.63, 1.0)
const COLOR_GOLD := Color(1.0, 0.82, 0.38, 1.0)
const COLOR_WARNING := Color(1.0, 0.70, 0.40, 1.0)
const PANEL := Color(0.07, 0.09, 0.17, 0.76)
const PANEL_LIGHT := Color(0.12, 0.16, 0.30, 0.68)

var screen := Screen.MENU
var runtime: LevelRuntime = null

var _buttons: Dictionary = {}
var _hover_pos := Vector2(-1000.0, -1000.0)
var _time := 0.0
var _toast_flash := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_process(true)


func bind_level_runtime(value: LevelRuntime) -> void:
	runtime = value
	if runtime == null:
		return
	if not runtime.level_loaded.is_connected(_on_level_loaded):
		runtime.level_loaded.connect(_on_level_loaded)
	if not runtime.level_complete.is_connected(_on_level_complete):
		runtime.level_complete.connect(_on_level_complete)
	_sync_runtime_visibility()


func _process(delta: float) -> void:
	_time += delta
	_toast_flash = maxf(0.0, _toast_flash - delta)
	queue_redraw()


func _input(event: InputEvent) -> void:
	_handle_pointer_input(event, false)


func _gui_input(event: InputEvent) -> void:
	_handle_pointer_input(event, true)


func _handle_pointer_input(event: InputEvent, from_gui: bool) -> void:
	if event is InputEventMouseMotion:
		_hover_pos = _to_ref_position(event.position)
		queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
			return
		var ref_pos := _to_ref_position(event.position)
		for button_id in _buttons.keys():
			var rect: Rect2 = _buttons[button_id]
			if rect.has_point(ref_pos):
				if from_gui:
					accept_event()
				else:
					get_viewport().set_input_as_handled()
				_activate_button(String(button_id))
				return


func _draw() -> void:
	_buttons.clear()
	var transform := _ref_transform()
	draw_set_transform(transform.origin, 0.0, transform.get_scale())
	match screen:
		Screen.MENU:
			_draw_menu()
		Screen.LEVEL_SELECT:
			_draw_level_select()
		Screen.PUZZLE:
			_draw_puzzle_hud()
		Screen.VICTORY:
			_draw_victory()
		Screen.SETTINGS:
			_draw_settings()
		Screen.CODEX:
			_draw_codex()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _on_level_loaded(_spec: Resource) -> void:
	queue_redraw()


func _on_level_complete(_spec: Resource) -> void:
	screen = Screen.VICTORY
	_sync_runtime_visibility()
	queue_redraw()


func _activate_button(button_id: String) -> void:
	match button_id:
		"start", "enter_level", "resume":
			screen = Screen.PUZZLE
		"levels":
			screen = Screen.LEVEL_SELECT
		"settings":
			screen = Screen.SETTINGS
		"codex":
			screen = Screen.CODEX
		"back_menu", "close":
			screen = Screen.MENU
		"verify":
			_verify_level()
		"hint":
			_toast_flash = 1.3
		"replay":
			if runtime != null and runtime.level_spec != null:
				runtime.load_level(runtime.level_spec)
			screen = Screen.PUZZLE
		"next":
			screen = Screen.LEVEL_SELECT
	_sync_runtime_visibility()
	queue_redraw()


func _verify_level() -> void:
	if runtime == null:
		return
	if runtime.evaluate_completeness():
		screen = Screen.VICTORY
	else:
		_toast_flash = 1.3


func _sync_runtime_visibility() -> void:
	if runtime == null:
		return
	var gameplay_visible := screen == Screen.PUZZLE
	runtime.set_visual_layer_visible(gameplay_visible)
	runtime.set_interaction_enabled(gameplay_visible)


func _draw_menu() -> void:
	_draw_logo(Vector2(123.0, 226.0), 40.0)
	_draw_text("量子对撞师", Vector2(184.0, 250.0), 60, Color.WHITE)
	_draw_text("QUANTUM RESONANCE", Vector2(190.0, 292.0), 16, Color(0.67, 0.71, 0.85, 1.0))
	_draw_text("在量子深处，因碰撞而生的秩序。", Vector2(92.0, 340.0), 17, COLOR_MUTED)
	_draw_icon_button("settings", Rect2(1050.0, 34.0, 42.0, 42.0), "gear")
	_draw_icon_button("codex", Rect2(1118.0, 34.0, 42.0, 42.0), "book")
	_draw_icon_button("levels", Rect2(1186.0, 34.0, 42.0, 42.0), "orbit")

	_draw_button("start", Rect2(90.0, 430.0, 300.0, 56.0), "开始游戏", COLOR_BLUE, true)
	_draw_button("resume", Rect2(90.0, 492.0, 300.0, 50.0), "继续游戏", Color.TRANSPARENT, false)
	_draw_button("levels", Rect2(90.0, 548.0, 300.0, 50.0), "关卡选择", Color.TRANSPARENT, false)
	_draw_button("codex", Rect2(90.0, 604.0, 300.0, 50.0), "图鉴", Color.TRANSPARENT, false)
	_draw_text("v1.0.0  BUILD 2026.06.21", Vector2(90.0, 688.0), 11, COLOR_DIM)
	_draw_text("按任意键开始", Vector2(1082.0, 688.0), 14, Color(0.63, 0.68, 0.82, 0.55 + sin(_time * 2.8) * 0.25))


func _draw_level_select() -> void:
	_draw_text("关卡选择", Vector2(54.0, 74.0), 30, Color.WHITE)
	_draw_text("轨道星系视图", Vector2(56.0, 98.0), 13, COLOR_MUTED)
	_draw_orbit_system()
	_draw_text("总体进度", Vector2(56.0, 614.0), 12, COLOR_MUTED)
	_draw_text("37%", Vector2(56.0, 646.0), 28, Color(0.81, 0.91, 1.0, 1.0))
	_draw_progress_bar(Rect2(56.0, 662.0, 200.0, 4.0), 0.37)

	var panel := Rect2(848.0, 130.0, 384.0, 456.0)
	_draw_panel(panel, PANEL, 14, Color(0.35, 0.47, 0.78, 0.30), 1)
	_draw_text("CHAPTER III · 量子相干", panel.position + Vector2(26.0, 34.0), 12, COLOR_CYAN)
	_draw_text("3-2", panel.position + Vector2(26.0, 78.0), 34, Color(0.81, 0.91, 1.0, 1.0))
	_draw_text("相干之桥", panel.position + Vector2(94.0, 76.0), 22, Color.WHITE)
	_draw_preview_diagram(Rect2(panel.position + Vector2(26.0, 98.0), Vector2(332.0, 150.0)))
	_draw_text_block("两条相干路径在此交汇，寻找让振幅相长的连法。", panel.position + Vector2(26.0, 284.0), 13, COLOR_MUTED, 320.0)
	_draw_text("完成度", panel.position + Vector2(26.0, 338.0), 13, COLOR_MUTED)
	_draw_text("★ ★ ☆", panel.position + Vector2(84.0, 339.0), 15, COLOR_GOLD)
	_draw_button("enter_level", Rect2(panel.position + Vector2(26.0, 376.0), Vector2(332.0, 50.0)), "进入关卡", COLOR_BLUE, true)
	_draw_button("back_menu", Rect2(54.0, 38.0, 120.0, 42.0), "返回", Color.TRANSPARENT, false)


func _draw_puzzle_hud() -> void:
	_draw_text("QED · 02", Vector2(54.0, 54.0), 13, COLOR_CYAN)
	_draw_text("湮灭之门", Vector2(146.0, 58.0), 22, Color.WHITE)
	_draw_text("长按粒子拖到顶点，连成入射 / 出射完整的图。", Vector2(54.0, 82.0), 14, COLOR_MUTED)
	_draw_icon_button("settings", Rect2(1184.0, 34.0, 42.0, 42.0), "pause")
	_draw_icon_button("hint", Rect2(1128.0, 34.0, 42.0, 42.0), "hint", COLOR_GOLD)

	var complete := runtime != null and runtime.is_level_complete()
	if complete:
		_draw_toast("费曼图守恒成立 · 电荷与轻子数平衡", COLOR_GREEN)
	else:
		var pulse := 0.12 + _toast_flash * 0.18
		_draw_toast("顶点 V1 缺少一条入射线 · 还需放置 e⁺", Color(COLOR_WARNING.r, COLOR_WARNING.g, COLOR_WARNING.b, 0.78 + pulse))

	var tray := Rect2(54.0, 568.0, 1172.0, 118.0)
	_draw_panel(tray, PANEL, 16, Color(0.35, 0.47, 0.78, 0.25), 1)
	_draw_text("可用粒子 · 拖拽放置", tray.position + Vector2(26.0, 28.0), 11, COLOR_DIM)
	var x := tray.position.x + 26.0
	var y := tray.position.y + 42.0
	_draw_particle_card(Rect2(x, y, 54.0, 54.0), "e⁻", "电子", Color.WHITE, false)
	_draw_particle_card(Rect2(x + 70.0, y, 54.0, 54.0), "e⁺", "正电子", Color(0.78, 0.70, 1.0, 1.0), not complete)
	_draw_particle_card(Rect2(x + 140.0, y, 54.0, 54.0), "γ", "光子", Color(0.50, 0.90, 0.93, 1.0), false)
	_draw_particle_card(Rect2(x + 210.0, y, 54.0, 54.0), "μ⁻", "μ子", Color(0.50, 0.90, 0.93, 1.0), false)
	_draw_particle_card(Rect2(x + 280.0, y, 54.0, 54.0), "μ⁺", "反μ子", Color.WHITE, false)
	_draw_text("顶点 / 步数", Vector2(958.0, 614.0), 11, COLOR_DIM)
	_draw_text("2 · %s" % ("4" if complete else "3"), Vector2(960.0, 644.0), 20, Color(0.81, 0.91, 1.0, 1.0))
	_draw_button("verify", Rect2(1040.0, 599.0, 160.0, 56.0), "对撞验证", COLOR_GREEN if complete else Color(0.16, 0.18, 0.27, 0.85), complete)


func _draw_victory() -> void:
	_draw_particle_burst(Vector2(360.0, 360.0))
	_draw_text("QED · 02 — 湮灭之门", Vector2(108.0, 226.0), 13, COLOR_CYAN)
	_draw_text("对撞成功", Vector2(108.0, 288.0), 56, Color.WHITE)
	_draw_text("S", Vector2(108.0, 442.0), 130, COLOR_GREEN)
	_draw_text("★ ★ ★", Vector2(236.0, 418.0), 34, COLOR_GOLD)
	var panel := Rect2(752.0, 196.0, 420.0, 236.0)
	_draw_panel(panel, Color(0.08, 0.10, 0.18, 0.84), 14, Color(0.35, 0.47, 0.78, 0.25), 1)
	_draw_stat_row(panel.position + Vector2(22.0, 44.0), "步数", "4 / 最佳 4")
	_draw_stat_row(panel.position + Vector2(22.0, 92.0), "用时", "01:12")
	_draw_stat_row(panel.position + Vector2(22.0, 140.0), "守恒精度", "100%")
	_draw_stat_row(panel.position + Vector2(22.0, 188.0), "无提示通关", "完成")
	_draw_button("replay", Rect2(752.0, 492.0, 158.0, 54.0), "重玩", Color.TRANSPARENT, false)
	_draw_button("next", Rect2(928.0, 492.0, 244.0, 54.0), "下一关", COLOR_BLUE, true)


func _draw_settings() -> void:
	_draw_button("close", Rect2(1184.0, 50.0, 44.0, 44.0), "×", Color.TRANSPARENT, false)
	_draw_text("设置", Vector2(64.0, 78.0), 32, Color.WHITE)
	_draw_text("SETTINGS", Vector2(64.0, 100.0), 12, COLOR_CYAN)
	var tabs := ["音频", "画面", "操作", "辅助功能", "语言"]
	var tab_x := 64.0
	for index in range(tabs.size()):
		_draw_text(tabs[index], Vector2(tab_x, 148.0), 15, Color.WHITE if index == 0 else COLOR_MUTED)
		if index == 0:
			draw_line(Vector2(tab_x, 158.0), Vector2(tab_x + 32.0, 158.0), COLOR_CYAN, 2.0)
		tab_x += 78.0 if index < 2 else 112.0
	draw_line(Vector2(64.0, 165.0), Vector2(1216.0, 165.0), Color(0.35, 0.47, 0.78, 0.18), 1.0)
	_draw_slider(Vector2(64.0, 230.0), "主音量", 0.80)
	_draw_slider(Vector2(64.0, 310.0), "背景音乐", 0.62)
	_draw_slider(Vector2(64.0, 390.0), "音效", 0.90)
	_draw_toggle(Rect2(696.0, 206.0, 520.0, 74.0), "环境氛围音", "深空粒子的低频回响", true)
	_draw_toggle(Rect2(696.0, 300.0, 520.0, 74.0), "动态旁白", "解谜时朗读物理提示", false)
	_draw_select(Rect2(696.0, 394.0, 520.0, 66.0), "输出设备", "系统默认")
	_draw_button("back_menu", Rect2(946.0, 624.0, 120.0, 48.0), "恢复默认", Color.TRANSPARENT, false)
	_draw_button("close", Rect2(1080.0, 624.0, 136.0, 48.0), "应用并返回", COLOR_BLUE, true)


func _draw_codex() -> void:
	_draw_button("close", Rect2(1184.0, 50.0, 44.0, 44.0), "×", Color.TRANSPARENT, false)
	_draw_text("图鉴", Vector2(60.0, 74.0), 30, Color.WHITE)
	_draw_text("粒子百科 · 已发现 14 / 32", Vector2(60.0, 100.0), 13, COLOR_MUTED)
	var cats := ["轻子 6/6", "夸克 4/6", "规范玻色子 3/5", "复合粒子 1/15"]
	for index in range(cats.size()):
		var rect := Rect2(60.0, 128.0 + index * 51.0, 170.0, 44.0)
		_draw_panel(rect, Color(0.10, 0.16, 0.30, 0.70) if index == 0 else Color.TRANSPARENT, 11, Color(0.35, 0.70, 1.0, 0.32) if index == 0 else Color.TRANSPARENT, 1)
		_draw_text(cats[index], rect.position + Vector2(16.0, 28.0), 14, Color.WHITE if index == 0 else COLOR_MUTED)
	var particles := [
		["e⁻", "电子", "0.511 MeV", Color.WHITE],
		["e⁺", "正电子", "0.511 MeV", Color(0.78, 0.70, 1.0, 1.0)],
		["μ⁻", "μ 子", "105.7 MeV", Color(0.55, 0.94, 0.96, 1.0)],
		["μ⁺", "反 μ 子", "105.7 MeV", Color(0.78, 0.70, 1.0, 1.0)],
		["νₑ", "电子中微子", "~0 MeV", Color(0.74, 0.82, 1.0, 1.0)],
	]
	for index in range(9):
		var col := index % 3
		var row := index / 3
		var rect := Rect2(252.0 + col * 204.0, 128.0 + row * 126.0, 188.0, 112.0)
		if index < particles.size():
			var data: Array = particles[index]
			_draw_panel(rect, Color(0.10, 0.14, 0.27, 0.70), 14, Color(0.35, 0.70, 1.0, 0.26) if index == 0 else Color(0.42, 0.48, 0.72, 0.22), 1)
			_draw_text(str(data[0]), rect.position + Vector2(16.0, 40.0), 27, data[3])
			_draw_text(str(data[1]), rect.position + Vector2(16.0, 72.0), 14, COLOR_TEXT)
			_draw_text(str(data[2]), rect.position + Vector2(16.0, 94.0), 11, COLOR_DIM)
		else:
			_draw_panel(rect, Color(0.08, 0.10, 0.18, 0.50), 14, Color(0.40, 0.44, 0.58, 0.22), 1)
			_draw_text("未发现", rect.position + Vector2(68.0, 62.0), 11, COLOR_DIM)
	var detail := Rect2(908.0, 128.0, 312.0, 520.0)
	_draw_panel(detail, Color(0.08, 0.10, 0.18, 0.88), 18, Color(0.35, 0.70, 1.0, 0.26), 1)
	_draw_particle_orb(detail.position + Vector2(72.0, 72.0), 42.0, COLOR_CYAN)
	_draw_text("电子", detail.position + Vector2(132.0, 58.0), 24, Color.WHITE)
	_draw_text("ELECTRON · 轻子", detail.position + Vector2(132.0, 80.0), 12, COLOR_CYAN)
	_draw_stat_row(detail.position + Vector2(30.0, 154.0), "质量", "0.511 MeV/c²")
	_draw_stat_row(detail.position + Vector2(30.0, 202.0), "电荷", "−1 e")
	_draw_stat_row(detail.position + Vector2(30.0, 250.0), "自旋", "1/2")
	_draw_text_block("最轻的带电轻子，稳定且无内部结构。在 QED 中通过交换光子相互作用。", detail.position + Vector2(30.0, 330.0), 13, COLOR_MUTED, 250.0)


func _draw_button(id: String, rect: Rect2, label: String, color: Color, primary: bool) -> void:
	_buttons[id] = rect
	var hovered := rect.has_point(_hover_pos)
	var bg := color
	if color == Color.TRANSPARENT:
		bg = Color(0.10, 0.13, 0.23, 0.26 if hovered else 0.0)
	elif hovered:
		bg = color.lightened(0.12)
	_draw_panel(rect, bg, rect.size.y * 0.5, Color(0.55, 0.66, 0.92, 0.50 if hovered or primary else 0.28), 1)
	var font_size := 17 if rect.size.y >= 52.0 else 15
	var text_color := Color.WHITE if primary or hovered else Color(0.72, 0.77, 0.90, 1.0)
	var text_size := _text_size(label, font_size)
	_draw_text(label, rect.position + Vector2((rect.size.x - text_size.x) * 0.5, rect.size.y * 0.5 + font_size * 0.36), font_size, text_color)


func _draw_icon_button(id: String, rect: Rect2, icon: String, tint: Color = COLOR_TEXT) -> void:
	_buttons[id] = rect
	var hovered := rect.has_point(_hover_pos)
	_draw_panel(rect, Color(0.08, 0.10, 0.18, 0.38), 21, Color(tint.r, tint.g, tint.b, 0.58 if hovered else 0.35), 1)
	var center := rect.get_center()
	match icon:
		"pause":
			draw_rect(Rect2(center + Vector2(-5.0, -8.0), Vector2(3.0, 16.0)), tint)
			draw_rect(Rect2(center + Vector2(3.0, -8.0), Vector2(3.0, 16.0)), tint)
		"hint":
			draw_circle(center + Vector2(0.0, -3.0), 7.0, Color(tint.r, tint.g, tint.b, 0.16))
			draw_arc(center + Vector2(0.0, -4.0), 7.0, -0.2, TAU - 0.2, 28, tint, 1.3)
			draw_line(center + Vector2(-5.0, 8.0), center + Vector2(5.0, 8.0), tint, 1.8)
		"book":
			draw_rect(Rect2(center + Vector2(-8.0, -9.0), Vector2(16.0, 18.0)), Color.TRANSPARENT, false, 1.4)
			draw_line(center + Vector2(-2.0, -9.0), center + Vector2(-2.0, 9.0), tint, 1.2)
		"orbit":
			draw_arc(center, 10.0, 0.0, TAU, 40, tint, 1.2)
			draw_arc(center, 5.0, 0.0, TAU, 32, tint, 1.2)
			draw_circle(center, 2.2, tint)
		"gear":
			draw_arc(center, 9.0, 0.0, TAU, 36, tint, 1.4)
			draw_circle(center, 3.0, Color.TRANSPARENT, false, 1.4)


func _draw_panel(rect: Rect2, bg: Color, radius: float, border: Color = Color.TRANSPARENT, border_width: int = 0) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	var r := int(radius)
	style.corner_radius_top_left = r
	style.corner_radius_top_right = r
	style.corner_radius_bottom_left = r
	style.corner_radius_bottom_right = r
	if border_width > 0:
		style.border_color = border
		style.border_width_left = border_width
		style.border_width_right = border_width
		style.border_width_top = border_width
		style.border_width_bottom = border_width
	draw_style_box(style, rect)


func _draw_text(text: String, position: Vector2, size: int, color: Color) -> void:
	var font := get_theme_font("font", "Label")
	draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, color)


func _draw_text_block(text: String, position: Vector2, size: int, color: Color, width: float) -> void:
	var words := text.split("，", false)
	var line := ""
	var y := position.y
	for word in words:
		var candidate := word if line.is_empty() else line + "，" + word
		if _text_size(candidate, size).x > width and not line.is_empty():
			_draw_text(line, Vector2(position.x, y), size, color)
			y += size * 1.7
			line = word
		else:
			line = candidate
	if not line.is_empty():
		_draw_text(line, Vector2(position.x, y), size, color)


func _text_size(text: String, size: int) -> Vector2:
	var font := get_theme_font("font", "Label")
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size)


func _draw_logo(center: Vector2, radius: float) -> void:
	draw_arc(center, radius, 0.0, TAU, 64, Color(0.56, 0.69, 1.0, 0.62), 1.0)
	draw_arc(center, radius * 0.68, 0.0, TAU, 64, Color(0.56, 0.69, 1.0, 0.30), 1.0)
	for dir in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]:
		draw_line(center + dir * radius * 0.80, center + dir * radius * 0.25, Color(0.74, 0.82, 1.0, 0.82), 1.3)
	draw_circle(center, 5.0, Color(0.80, 0.94, 1.0, 1.0))


func _draw_orbit_system() -> void:
	var center := Vector2(380.0, 380.0)
	for radius in [340.0, 260.0, 170.0]:
		draw_arc(center, radius, 0.0, TAU, 120, Color(0.48, 0.56, 0.78, 0.18), 1.0)
	_draw_particle_orb(center, 40.0, COLOR_CYAN)
	var nodes := [
		[Vector2(370.0, 170.0), "I 初始粒子", COLOR_PURPLE],
		[Vector2(160.0, 440.0), "II 对撞初现", COLOR_CYAN],
		[Vector2(570.0, 490.0), "III 量子相干", COLOR_CYAN],
		[Vector2(620.0, 120.0), "IV 纠缠延展", COLOR_MUTED],
	]
	for node_data in nodes:
		var pos: Vector2 = node_data[0]
		_draw_particle_orb(pos, 11.0, node_data[2])
		_draw_text(str(node_data[1]), pos + Vector2(-36.0, 30.0), 12, COLOR_TEXT if node_data[2] != COLOR_MUTED else COLOR_MUTED)


func _draw_preview_diagram(rect: Rect2) -> void:
	_draw_panel(rect, Color(0.05, 0.07, 0.14, 0.92), 10, Color(0.35, 0.47, 0.78, 0.20), 1)
	var origin := rect.position
	var pts := [
		[Vector2(30.0, 40.0), Vector2(170.0, 75.0), Color.WHITE],
		[Vector2(30.0, 110.0), Vector2(170.0, 75.0), COLOR_PURPLE],
		[Vector2(290.0, 75.0), Vector2(200.0, 38.0), COLOR_CYAN],
	]
	for entry in pts:
		draw_line(origin + entry[0], origin + entry[1], entry[2], 1.5)
	_draw_wave(origin + Vector2(170.0, 75.0), origin + Vector2(290.0, 75.0), 8.0, 8, COLOR_CYAN, 1.5)
	draw_circle(origin + Vector2(170.0, 75.0), 4.0, Color.WHITE)
	draw_circle(origin + Vector2(290.0, 75.0), 4.0, Color.WHITE)


func _draw_particle_card(rect: Rect2, symbol: String, label: String, tint: Color, active: bool) -> void:
	var bg := Color(0.13, 0.17, 0.32, 0.76) if active else Color(0.08, 0.10, 0.18, 0.50)
	var border := tint if active else Color(0.35, 0.47, 0.78, 0.24)
	_draw_panel(rect, bg, 13, border, 1)
	_draw_text(symbol, rect.position + Vector2(12.0, 34.0), 19, tint)
	_draw_text(label, rect.position + Vector2(2.0, 76.0), 10, tint if active else COLOR_DIM)


func _draw_toast(text: String, tint: Color) -> void:
	var width := _text_size(text, 14).x + 64.0
	var rect := Rect2(640.0 - width * 0.5, 118.0, width, 36.0)
	_draw_panel(rect, Color(tint.r, tint.g, tint.b, 0.13), 18, Color(tint.r, tint.g, tint.b, 0.50), 1)
	draw_circle(rect.position + Vector2(21.0, 18.0), 4.0, tint)
	_draw_text(text, rect.position + Vector2(38.0, 23.0), 14, Color(tint.r, tint.g, tint.b, 0.95))


func _draw_progress_bar(rect: Rect2, value: float) -> void:
	_draw_panel(rect, Color(0.30, 0.36, 0.52, 0.28), 3)
	_draw_panel(Rect2(rect.position, Vector2(rect.size.x * clampf(value, 0.0, 1.0), rect.size.y)), Color(0.23, 0.55, 1.0, 1.0), 3)


func _draw_stat_row(pos: Vector2, label: String, value: String) -> void:
	_draw_text(label, pos, 14, COLOR_MUTED)
	_draw_text(value, pos + Vector2(210.0, 0.0), 18, COLOR_TEXT)


func _draw_particle_burst(center: Vector2) -> void:
	for angle_index in range(16):
		var angle := TAU * float(angle_index) / 16.0 + _time * 0.06
		var end := center + Vector2(cos(angle), sin(angle)) * (150.0 + 90.0 * sin(angle_index))
		draw_line(center, end, Color(0.58, 0.81, 1.0, 0.20), 1.0)
	_draw_particle_orb(center, 60.0, COLOR_CYAN)


func _draw_slider(pos: Vector2, label: String, value: float) -> void:
	_draw_text(label, pos, 16, COLOR_TEXT)
	_draw_text(str(roundi(value * 100.0)), pos + Vector2(476.0, 0.0), 15, COLOR_CYAN)
	var track := Rect2(pos + Vector2(0.0, 22.0), Vector2(520.0, 6.0))
	_draw_progress_bar(track, value)
	draw_circle(track.position + Vector2(track.size.x * value, track.size.y * 0.5), 9.0, Color.WHITE)


func _draw_toggle(rect: Rect2, label: String, hint: String, enabled: bool) -> void:
	_draw_panel(rect, PANEL_LIGHT, 13, Color(0.35, 0.47, 0.78, 0.18), 1)
	_draw_text(label, rect.position + Vector2(22.0, 29.0), 16, COLOR_TEXT)
	_draw_text(hint, rect.position + Vector2(22.0, 50.0), 12, COLOR_DIM)
	var toggle := Rect2(rect.end - Vector2(72.0, 50.0), Vector2(50.0, 27.0))
	_draw_panel(toggle, Color(0.23, 0.47, 1.0, 1.0) if enabled else Color(0.30, 0.34, 0.46, 0.65), 14)
	draw_circle(toggle.position + Vector2(36.5 if enabled else 13.5, 13.5), 10.5, Color.WHITE if enabled else COLOR_MUTED)


func _draw_select(rect: Rect2, label: String, value: String) -> void:
	_draw_panel(rect, PANEL_LIGHT, 13, Color(0.35, 0.47, 0.78, 0.18), 1)
	_draw_text(label, rect.position + Vector2(22.0, 38.0), 16, COLOR_TEXT)
	_draw_text(value + "  ˅", rect.position + Vector2(390.0, 38.0), 14, COLOR_TEXT)


func _draw_particle_orb(center: Vector2, radius: float, tint: Color) -> void:
	for index in range(8, 0, -1):
		var t := float(index) / 8.0
		draw_circle(center, radius * t, Color(tint.r, tint.g, tint.b, 0.05 * (1.0 - t) + 0.10))
	draw_circle(center, radius * 0.45, Color(0.96, 0.99, 1.0, 1.0))


func _draw_wave(start: Vector2, end: Vector2, amp: float, waves: int, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	var delta := end - start
	var length := maxf(delta.length(), 0.001)
	var normal := Vector2(-delta.y, delta.x) / length
	var steps := waves * 14
	for index in range(steps + 1):
		var t := float(index) / float(steps)
		points.append(start.lerp(end, t) + normal * sin(t * TAU * waves) * amp)
	draw_polyline(points, color, width, true)


func _ref_transform() -> Transform2D:
	var current_size := get_viewport_rect().size
	if current_size.x <= 0.0 or current_size.y <= 0.0:
		return Transform2D.IDENTITY
	var scale_value := minf(current_size.x / REF_SIZE.x, current_size.y / REF_SIZE.y)
	var origin := (current_size - REF_SIZE * scale_value) * 0.5
	return Transform2D(0.0, Vector2(scale_value, scale_value), 0.0, origin)


func _to_ref_position(position: Vector2) -> Vector2:
	var transform := _ref_transform()
	var scale_value := transform.get_scale().x
	if scale_value <= 0.0:
		return position
	return (position - transform.origin) / scale_value
