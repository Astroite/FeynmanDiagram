class_name OrbitField
extends Control

# Decorative orbital-galaxy backdrop for the level-select screen (handoff "轨道星系
# 视图"): concentric orbit rings slowly counter-rotate around a softly breathing
# core. Purely cosmetic — never captures input, never participates in any logic.

var core_offset := Vector2(400.0, 380.0)

var _time := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	_draw_core_glow(core_offset, 72.0)
	_draw_ring(core_offset, 150.0, Color(0.47, 0.59, 0.86, 0.20), false, 0.0)
	_draw_ring(core_offset, 250.0, Color(0.47, 0.59, 0.86, 0.13), true, _time * 0.16)
	_draw_ring(core_offset, 340.0, Color(0.59, 0.47, 1.0, 0.16), false, 0.0)
	_draw_ring(core_offset, 452.0, Color(0.47, 0.59, 0.86, 0.10), true, -_time * 0.10)
	var breathe := 1.0 + sin(_time * 1.6) * 0.06
	draw_circle(core_offset, 8.0 * breathe, Color(0.85, 0.95, 1.0, 0.95))


func _draw_core_glow(center: Vector2, radius: float) -> void:
	for index in range(14, 0, -1):
		var t := float(index) / 14.0
		draw_circle(center, radius * t, Color(0.45, 0.70, 1.0, 0.06 * (1.0 - t)))


# Solid rings draw as a full arc; dashed rings draw alternating short arcs whose
# phase advances over time, giving the slow-spin effect.
func _draw_ring(center: Vector2, radius: float, color: Color, dashed: bool, phase: float) -> void:
	if not dashed:
		draw_arc(center, radius, 0.0, TAU, 96, color, 1.3, true)
		return
	var segments := 48
	for index in range(segments):
		if index % 2 == 1:
			continue
		var a0 := phase + TAU * float(index) / float(segments)
		var a1 := phase + TAU * float(index + 1) / float(segments)
		draw_arc(center, radius, a0, a1, 6, color, 1.3, true)
