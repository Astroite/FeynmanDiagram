extends GdUnitTestSuite

# Integration smoke test for the screen-stack HUD: starting a level loads it into
# the runtime and switches to the puzzle; completing the graph shows victory.


func test_start_loads_first_level_and_shows_puzzle() -> void:
	var runtime := LevelRuntime.new()
	add_child(runtime)
	auto_free(runtime)

	var hud := QuantumHud.new()
	add_child(hud)
	auto_free(hud)
	hud.bind_level_runtime(runtime)

	hud._on_start()

	assert_that(runtime.level_spec).is_not_null()
	assert_that(runtime.level_spec.level_id).is_equal(&"001")
	assert_int(hud._screen).is_equal(QuantumHud.Screen.PUZZLE)


func test_completing_graph_shows_victory() -> void:
	var runtime := LevelRuntime.new()
	add_child(runtime)
	auto_free(runtime)

	var hud := QuantumHud.new()
	add_child(hud)
	auto_free(hud)
	hud.bind_level_runtime(runtime)

	hud._on_start()
	# Reference solution is a connected, dangling-free graph → triggers completion.
	assert_that(runtime.apply_reference_solution()).is_true()
	assert_int(hud._screen).is_equal(QuantumHud.Screen.VICTORY)
