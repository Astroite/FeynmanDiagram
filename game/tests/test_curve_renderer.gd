extends GdUnitTestSuite


func test_sample_by_arc_length_has_near_even_steps_around_handles() -> void:
	var renderer := _renderer()
	var curve := Curve2D.new()
	curve.bake_interval = 4.0
	curve.add_point(Vector2.ZERO, Vector2.ZERO, Vector2(0.0, 140.0))
	curve.add_point(Vector2(220.0, 0.0), Vector2(0.0, -140.0), Vector2.ZERO)

	var distances: Array[float] = []
	var previous := renderer.sample_by_arc_length(curve, 0.0)
	for index in range(1, 13):
		var point := renderer.sample_by_arc_length(curve, float(index) / 12.0)
		distances.append(previous.distance_to(point))
		previous = point

	var average := _average(distances)
	for distance in distances:
		assert_float(distance).is_between(average * 0.82, average * 1.18)


func test_edge_changed_updates_render_state() -> void:
	var model := GraphModel.new()
	var edge := model.add_edge(&"edge", [
		_point(Vector2.ZERO),
		_point(Vector2(100.0, 0.0)),
	])
	var renderer := _renderer()
	renderer.set_graph_model(model)
	var revision_before: int = renderer.render_revision

	var initial_line_points := renderer.get_line(edge).points
	assert_that(initial_line_points[initial_line_points.size() - 1]).is_equal(Vector2(100.0, 0.0))

	model.set_curve_points(edge, [
		_point(Vector2.ZERO),
		_point(Vector2(140.0, 20.0)),
	])

	assert_that(renderer.render_revision).is_greater(revision_before)
	var updated_line_points := renderer.get_line(edge).points
	assert_that(updated_line_points[updated_line_points.size() - 1]).is_equal(Vector2(140.0, 20.0))
	assert_that(renderer.get_curve(edge).get_point_position(1)).is_equal(Vector2(140.0, 20.0))


func test_curve_built_from_curve_points_matches_endpoints_and_length() -> void:
	var model := GraphModel.new()
	var edge := model.add_edge(&"edge", [
		_point(Vector2(10.0, 20.0), Vector2.ZERO, Vector2(20.0, -60.0)),
		_point(Vector2(160.0, 40.0), Vector2(-30.0, 70.0), Vector2.ZERO),
	])
	var renderer := _renderer()
	var curve := renderer.build_curve(edge)

	assert_that(renderer.sample_by_arc_length(curve, 0.0)).is_equal(Vector2(10.0, 20.0))
	assert_that(renderer.sample_by_arc_length(curve, 1.0)).is_equal(Vector2(160.0, 40.0))
	assert_float(curve.get_baked_length()).is_greater(151.0)
	assert_float(curve.get_baked_length()).is_less(260.0)


func test_renders_a_handle_for_each_node() -> void:
	var model := GraphModel.new()
	var vertex = model.add_node(&"v", NodeKind.VERTEX, Vector2(30.0, 10.0))
	var anchor = model.add_node(&"a", NodeKind.ANCHOR, Vector2(120.0, 10.0))
	var renderer := _renderer()
	renderer.set_graph_model(model)

	assert_that(renderer.get_node_handle(vertex)).is_not_null()
	assert_that(renderer.get_node_handle(vertex).position).is_equal(Vector2(30.0, 10.0))
	assert_that(renderer.get_node_handle(anchor).position).is_equal(Vector2(120.0, 10.0))


func test_node_move_drags_handle_and_connected_edge_endpoint() -> void:
	var model := GraphModel.new()
	var anchor = model.add_node(&"a", NodeKind.ANCHOR, Vector2(100.0, 0.0))
	var edge := model.add_edge(&"e", [
		_point(Vector2.ZERO),
		_point(Vector2(100.0, 0.0)),
	])
	model.connect_half_edge(edge.half_edge_b, anchor, anchor.get_socket(&"socket_0"))
	var renderer := _renderer()
	renderer.set_graph_model(model)

	model.move_node(anchor, Vector2(140.0, 30.0))

	assert_that(renderer.get_node_handle(anchor).position).is_equal(Vector2(140.0, 30.0))
	# the connected endpoint follows the node, not the stale stored curve point
	assert_that(renderer.sample_by_arc_length(renderer.get_curve(edge), 1.0)).is_equal(Vector2(140.0, 30.0))


func _renderer() -> CurveRenderer:
	var renderer := CurveRenderer.new()
	auto_free(renderer)
	return renderer


func _point(position: Vector2, in_handle: Vector2 = Vector2.ZERO, out_handle: Vector2 = Vector2.ZERO) -> CurvePoint:
	return CurvePoint.create(position, in_handle, out_handle)


func _average(values: Array[float]) -> float:
	var sum := 0.0
	for value in values:
		sum += value
	return sum / float(values.size())
