class_name ParticleOrb
extends Control

# A soft glowing particle orb. Extracted from the old HUD's _draw_particle_orb so
# the visual style survives the move to real Control nodes.

@export var tint: Color = UiTheme.CYAN:
	set(value):
		tint = value
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5
	for index in range(8, 0, -1):
		var t := float(index) / 8.0
		draw_circle(center, radius * t, Color(tint.r, tint.g, tint.b, 0.05 * (1.0 - t) + 0.10))
	draw_circle(center, radius * 0.45, Color(0.96, 0.99, 1.0, 1.0))
