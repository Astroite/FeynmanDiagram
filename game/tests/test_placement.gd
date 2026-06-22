extends GdUnitTestSuite

const LevelRuntimeScript := preload("res://level/LevelRuntime.gd")
const ANNIHILATION := "res://level/levels/007_annihilation_gate.tres"


# The tray placement verb: pressing a token starts a half-edge drag, releasing on a
# vertex socket connects it. Here we drive that gesture programmatically and verify
# the QED graph completes.
func test_placing_free_leg_on_vertex_completes_level() -> void:
	var runtime = _runtime()
	assert_that(runtime.load_level(load(ANNIHILATION))).is_true()
	assert_bool(runtime.is_level_complete()).is_false()

	var free = runtime.free_half_edges()
	assert_int(free.size()).is_equal(1) # only the positron leg is unplaced
	assert_int(runtime.vertex_count()).is_equal(2)

	var interaction = runtime.curve_interaction
	# V1's open socket is at (470, 372) in the level data.
	var v1_socket := Vector2(470.0, 372.0)
	assert_bool(interaction.begin_half_edge_placement(free[0], Vector2(300.0, 500.0))).is_true()
	interaction.handle_pointer_moved(v1_socket + Vector2(2.0, 1.0))
	interaction.handle_pointer_up(v1_socket + Vector2(2.0, 1.0))

	assert_bool(runtime.is_level_complete()).is_true()
	assert_int(runtime.free_half_edges().size()).is_equal(0)
	assert_int(runtime.step_count()).is_equal(1)


func test_releasing_away_from_a_socket_does_not_complete() -> void:
	var runtime = _runtime()
	runtime.load_level(load(ANNIHILATION))

	var free = runtime.free_half_edges()
	var interaction = runtime.curve_interaction
	interaction.begin_half_edge_placement(free[0], Vector2(300.0, 500.0))
	interaction.handle_pointer_moved(Vector2(640.0, 650.0))
	interaction.handle_pointer_up(Vector2(640.0, 650.0)) # empty space, no socket

	assert_bool(runtime.is_level_complete()).is_false()
	assert_int(runtime.free_half_edges().size()).is_equal(1) # still unplaced


func _runtime():
	var runtime = LevelRuntimeScript.new()
	add_child(runtime)
	auto_free(runtime)
	return runtime
