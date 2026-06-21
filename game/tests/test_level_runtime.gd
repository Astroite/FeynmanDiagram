extends GdUnitTestSuite

const LevelRuntimeScript := preload("res://level/LevelRuntime.gd")

const LEVEL_PATHS := [
	"res://level/levels/001_connect_line.tres",
	"res://level/levels/002_bend_to_connect.tres",
	"res://level/levels/003_two_into_one.tres",
	"res://level/levels/004_undo_redo.tres",
	"res://level/levels/005_snap_to_socket.tres",
	"res://level/levels/006_three_line_convergence.tres",
]


func test_complete_when_connected_and_no_dangling() -> void:
	var model := GraphModel.new()
	var a = model.add_node(&"a", NodeKind.ANCHOR, Vector2.ZERO)
	var b = model.add_node(&"b", NodeKind.VERTEX, Vector2(100.0, 0.0))
	var edge := model.add_edge(&"e", [_point(Vector2.ZERO), _point(Vector2(100.0, 0.0))])

	# Both half-edges free → dangling, not complete.
	assert_bool(model.has_dangling_half_edges()).is_true()
	assert_bool(model.is_complete()).is_false()

	model.connect_half_edge(edge.half_edge_a, a, a.get_socket(&"socket_0"))
	model.connect_half_edge(edge.half_edge_b, b, b.get_socket(&"socket_0"))

	assert_bool(model.has_dangling_half_edges()).is_false()
	assert_bool(model.is_graph_connected()).is_true()
	assert_bool(model.is_complete()).is_true()


func test_disconnected_graph_is_not_complete() -> void:
	var model := GraphModel.new()
	var a = model.add_node(&"a", NodeKind.ANCHOR, Vector2.ZERO)
	model.add_node(&"island", NodeKind.VERTEX, Vector2(200.0, 0.0))
	var edge := model.add_edge(&"e", [_point(Vector2.ZERO), _point(Vector2(50.0, 0.0))])
	model.connect_half_edge(edge.half_edge_a, a, a.get_socket(&"socket_0"))

	# edge:b dangling and "island" has no edge → not complete on two counts.
	assert_bool(model.is_complete()).is_false()


func test_all_levels_givens_incomplete_reference_complete() -> void:
	for path in LEVEL_PATHS:
		var spec: Resource = load(path)
		assert_that(spec).is_not_null()

		var runtime = LevelRuntimeScript.new()
		auto_free(runtime)
		var completions: Array[StringName] = []
		runtime.level_complete.connect(func(completed_spec): completions.append(completed_spec.level_id))

		assert_that(runtime.load_level(spec)).is_true()
		assert_that(runtime.is_level_complete()).is_false() # givens are incomplete by design
		assert_that(runtime.apply_reference_solution()).is_true()
		assert_that(runtime.is_level_complete()).is_true() # reference is a connected, dangling-free graph
		assert_that(completions.has(spec.level_id)).is_true()


func test_level_spec_tres_round_trip() -> void:
	var original: Resource = load(LEVEL_PATHS[0])
	var temp_path := "user://level_round_trip.tres"

	assert_int(ResourceSaver.save(original, temp_path)).is_equal(OK)
	var copy: Resource = load(temp_path)

	assert_that(copy).is_not_null()
	assert_that(copy.level_id).is_equal(original.level_id)
	assert_that(copy.title).is_equal(original.title)
	assert_that(JSON.stringify(copy.givens)).is_equal(JSON.stringify(original.givens))
	assert_that(JSON.stringify(copy.reference_solution)).is_equal(JSON.stringify(original.reference_solution))


func _point(position: Vector2) -> CurvePoint:
	return CurvePoint.create(position)
