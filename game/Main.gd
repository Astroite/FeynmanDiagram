extends Node2D

@export_file("*.tres") var debug_level_path := "res://level/levels/001_connect_line.tres"

@onready var level_runtime: LevelRuntime = $LevelRuntime


func _ready() -> void:
	var spec := load(debug_level_path)
	if spec == null:
		push_error("Failed to load debug level: %s" % debug_level_path)
		return
	if not level_runtime.load_level(spec):
		push_error("Failed to start debug level: %s" % debug_level_path)
		return

	level_runtime.level_complete.connect(func(loaded_spec): print("Level complete: ", loaded_spec.level_id))
	queue_redraw()


func _draw() -> void:
	# Background only. The graph (lines, node handles, pulse) is drawn by the
	# CurveRenderer that LevelRuntime owns. There are no spatial objectives to draw.
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.01, 0.02, 0.055, 1.0), true)
