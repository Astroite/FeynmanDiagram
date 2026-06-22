class_name LogoMark
extends Control

# The orbiting-particle logo mark. Extracted from the old HUD's _draw_logo.


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5
	draw_arc(center, radius, 0.0, TAU, 64, Color(0.56, 0.69, 1.0, 0.62), 1.0)
	draw_arc(center, radius * 0.68, 0.0, TAU, 64, Color(0.56, 0.69, 1.0, 0.30), 1.0)
	for dir in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]:
		draw_line(center + dir * radius * 0.80, center + dir * radius * 0.25, Color(0.74, 0.82, 1.0, 0.82), 1.3)
	draw_circle(center, radius * 0.12 + 2.0, Color(0.80, 0.94, 1.0, 1.0))
