extends Node2D

@onready var level_runtime: LevelRuntime = $LevelRuntime
@onready var quantum_hud: QuantumHud = $QuantumHud

var _stars: Array[Dictionary] = []
var _time := 0.0


func _ready() -> void:
	_stars = _build_starfield(110, 1280.0, 720.0, 314159)
	set_process(true)
	# The HUD opens on the menu and loads levels on demand from the catalog.
	quantum_hud.bind_level_runtime(level_runtime)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var rect := get_viewport_rect()
	draw_rect(Rect2(Vector2.ZERO, rect.size), Color(0.025, 0.028, 0.055, 1.0), true)
	_draw_radial(Vector2(rect.size.x * 0.50, rect.size.y * 0.42), 520.0, Color(0.18, 0.34, 0.86, 0.15))
	_draw_radial(Vector2(rect.size.x * 0.72, rect.size.y * 0.22), 380.0, Color(0.55, 0.30, 0.92, 0.11))
	_draw_radial(Vector2(rect.size.x * 0.18, rect.size.y * 0.95), 340.0, Color(0.15, 0.26, 0.72, 0.10))
	_draw_stars()
	_draw_quantum_streams()


func _draw_radial(center: Vector2, radius: float, color: Color) -> void:
	for index in range(16, 0, -1):
		var t := float(index) / 16.0
		draw_circle(center, radius * t, Color(color.r, color.g, color.b, color.a * (1.0 - t) * 0.72))


func _draw_stars() -> void:
	for star in _stars:
		var alpha := float(star["alpha"]) * (0.72 + sin(_time * float(star["twinkle"]) + float(star["phase"])) * 0.22)
		draw_circle(star["position"], float(star["radius"]), Color(0.82, 0.90, 1.0, clampf(alpha, 0.12, 0.96)))


func _draw_quantum_streams() -> void:
	var paths := [
		[Vector2(470.0, -20.0), Vector2(560.0, 160.0), Vector2(600.0, 360.0), Vector2(770.0, 480.0)],
		[Vector2(470.0, -20.0), Vector2(610.0, 180.0), Vector2(780.0, 320.0), Vector2(1000.0, 540.0)],
		[Vector2(470.0, -20.0), Vector2(660.0, 140.0), Vector2(940.0, 250.0), Vector2(1170.0, 430.0)],
		[Vector2(470.0, -20.0), Vector2(560.0, 230.0), Vector2(740.0, 540.0), Vector2(1040.0, 660.0)],
	]
	for index in range(paths.size()):
		var points := _sample_cubic(paths[index], 42)
		draw_polyline(points, Color(0.46, 0.68, 1.0, 0.18 + 0.04 * index), 1.0, true)
		var pulse_t := fmod(_time * (0.09 + index * 0.014) + index * 0.17, 1.0)
		var pulse := _cubic_at(paths[index], pulse_t)
		draw_circle(pulse, 2.8, Color(0.75, 0.90, 1.0, 0.72))


func _build_starfield(count: int, width: float, height: float, seed: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var state := seed
	for _index in range(count):
		state = int((state * 1664525 + 1013904223) & 0x7fffffff)
		var rx := float(state) / float(0x7fffffff)
		state = int((state * 1664525 + 1013904223) & 0x7fffffff)
		var ry := float(state) / float(0x7fffffff)
		state = int((state * 1664525 + 1013904223) & 0x7fffffff)
		var rr := float(state) / float(0x7fffffff)
		result.append({
			"position": Vector2(rx * width, ry * height),
			"radius": 0.7 + rr * 1.4,
			"alpha": 0.24 + rr * 0.62,
			"twinkle": 1.2 + rr * 2.1,
			"phase": rr * TAU,
		})
	return result


func _sample_cubic(points: Array, steps: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	for index in range(steps + 1):
		result.append(_cubic_at(points, float(index) / float(steps)))
	return result


func _cubic_at(points: Array, t: float) -> Vector2:
	var u := 1.0 - t
	return points[0] * u * u * u + points[1] * 3.0 * u * u * t + points[2] * 3.0 * u * t * t + points[3] * t * t * t
