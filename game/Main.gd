extends Node2D

@export_file("*.tres") var debug_level_path := "res://level/levels/002_bend_fixed_ends.tres"

@onready var level_runtime: LevelRuntime = $LevelRuntime


func _ready() -> void:
	var spec := load(debug_level_path)
	if spec == null:
		push_error("Failed to load debug level: %s" % debug_level_path)
		return
	if not level_runtime.load_level(spec):
		push_error("Failed to start debug level: %s" % debug_level_path)
		return

	level_runtime.objective_met.connect(func(objective): print("Objective met: ", objective.objective_id))
	level_runtime.level_complete.connect(func(loaded_spec): print("Level complete: ", loaded_spec.level_id))
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.01, 0.02, 0.055, 1.0), true)
	if level_runtime == null or level_runtime.level_spec == null:
		return

	for objective: Resource in level_runtime.level_spec.spatial_objectives:
		_draw_objective(objective)


func _draw_objective(objective: Resource) -> void:
	if objective == null or objective.get_script() == null:
		return

	var script_path: String = objective.get_script().resource_path
	if script_path.ends_with("ObservationRing.gd"):
		var center: Vector2 = objective.get("center")
		var radius: float = objective.get("radius")
		var thickness: float = objective.get("thickness")
		draw_arc(center, radius, 0.0, TAU, 96, Color(0.35, 0.95, 1.0, 0.55), thickness, true)
		draw_arc(center, radius, 0.0, TAU, 96, Color(0.75, 1.0, 1.0, 0.65), 1.5, true)
	elif script_path.ends_with("ForbiddenZone.gd"):
		var center: Vector2 = objective.get("center")
		var radius: float = objective.get("radius")
		draw_circle(center, radius, Color(1.0, 0.20, 0.24, 0.20))
		draw_arc(center, radius, 0.0, TAU, 72, Color(1.0, 0.35, 0.45, 0.60), 2.0, true)
	elif script_path.ends_with("FixedAnchor.gd"):
		var position: Vector2 = objective.get("position")
		draw_circle(position, 8.0, Color(0.90, 0.92, 1.0, 0.85))
		draw_arc(position, 15.0, 0.0, TAU, 36, Color(0.70, 0.78, 1.0, 0.35), 2.0, true)
