extends GdUnitTestSuite


func test_add_remove_node_and_edge() -> void:
	var model := GraphModel.new()

	var anchor = model.add_node(&"anchor", NodeKind.ANCHOR, Vector2(10.0, 20.0), [Vector2.ZERO, Vector2(4.0, 0.0)])
	var vertex = model.add_node(&"vertex", NodeKind.VERTEX, Vector2(30.0, 40.0))
	var edge := model.add_edge(&"edge", [_point(Vector2(10.0, 20.0)), _point(Vector2(30.0, 40.0))])

	assert_that(model.get_node(&"anchor") == anchor).is_true()
	assert_that(model.get_node(&"vertex") == vertex).is_true()
	assert_that(model.get_edge(&"edge") == edge).is_true()
	assert_that(anchor.sockets.size()).is_equal(2)
	assert_that(edge.half_edge_a.edge == edge).is_true()
	assert_that(edge.half_edge_b.edge == edge).is_true()

	assert_that(model.remove_edge(&"edge")).is_true()
	assert_that(model.get_edge(&"edge")).is_null()
	assert_that(model.remove_node(&"anchor")).is_true()
	assert_that(model.get_node(&"anchor")).is_null()


func test_connect_and_disconnect_half_edges_update_sockets() -> void:
	var model := GraphModel.new()
	var node_a = model.add_node(&"a", NodeKind.ANCHOR, Vector2.ZERO)
	var node_b = model.add_node(&"b", NodeKind.VERTEX, Vector2(100.0, 0.0))
	var edge := model.add_edge(&"edge")

	var socket_a = node_a.get_socket(&"socket_0")
	var socket_b = node_b.get_socket(&"socket_0")

	assert_that(model.connect_half_edge(edge.half_edge_a, node_a, socket_a)).is_true()
	assert_that(model.connect_half_edge(edge.half_edge_b, node_b, socket_b)).is_true()
	assert_that(edge.half_edge_a.node == node_a).is_true()
	assert_that(edge.half_edge_a.socket == socket_a).is_true()
	assert_that(socket_a.occupied_by == edge.half_edge_a).is_true()
	assert_that(edge.half_edge_b.node == node_b).is_true()
	assert_that(socket_b.occupied_by == edge.half_edge_b).is_true()

	assert_that(model.disconnect_half_edge(edge.half_edge_a)).is_true()
	assert_that(edge.half_edge_a.node).is_null()
	assert_that(edge.half_edge_a.socket).is_null()
	assert_that(socket_a.occupied_by).is_null()


func test_to_dict_from_dict_round_trips_equivalent_graph() -> void:
	var model := GraphModel.new()
	var node_a = model.add_node(&"a", NodeKind.ANCHOR, Vector2(1.0, 2.0), [Vector2.ZERO])
	var node_b = model.add_node(&"b", NodeKind.VERTEX, Vector2(9.0, 8.0), [Vector2(2.0, 3.0)])
	var edge := model.add_edge(&"edge", [
		_point(Vector2(1.0, 2.0), Vector2(-1.0, 0.0), Vector2(5.0, 0.0)),
		_point(Vector2(9.0, 8.0), Vector2(-3.0, 1.0), Vector2.ZERO),
	])
	edge.particle_id = &"reserved_particle"
	edge.time_axis_dir = 1
	edge.half_edge_a.particle_id = &"reserved_half_edge"
	edge.half_edge_a.fermion_flow = -1
	model.connect_half_edge(edge.half_edge_a, node_a, node_a.get_socket(&"socket_0"))
	model.connect_half_edge(edge.half_edge_b, node_b, node_b.get_socket(&"socket_0"))

	var copy: GraphModel = GraphModel.from_dict(model.to_dict())

	assert_that(JSON.stringify(copy.to_dict())).is_equal(JSON.stringify(model.to_dict()))


func test_mutations_emit_expected_signals() -> void:
	var model := GraphModel.new()
	var node_events: Array = []
	var edge_events: Array = []
	var topology_events: Array = []
	model.node_changed.connect(func(node): node_events.append(node.id))
	model.edge_changed.connect(func(edge): edge_events.append(edge.id))
	model.topology_changed.connect(func(): topology_events.append("topology"))

	var node = model.add_node(&"node", NodeKind.VERTEX, Vector2.ZERO)
	var edge := model.add_edge(&"edge")
	model.move_node(node, Vector2(5.0, 6.0))
	model.set_curve_points(edge, [_point(Vector2(1.0, 1.0))])
	model.remove_edge(&"edge")
	model.remove_node(&"node")

	assert_that(node_events).is_equal([&"node"])
	assert_that(edge_events).is_equal([&"edge"])
	assert_that(topology_events.size()).is_equal(4)


func test_remove_edge_frees_sockets_and_half_edges() -> void:
	var model := GraphModel.new()
	var node_a = model.add_node(&"a", NodeKind.ANCHOR, Vector2.ZERO)
	var node_b = model.add_node(&"b", NodeKind.VERTEX, Vector2(10.0, 0.0))
	var edge := model.add_edge(&"edge")
	var socket_a = node_a.get_socket(&"socket_0")
	var socket_b = node_b.get_socket(&"socket_0")
	model.connect_half_edge(edge.half_edge_a, node_a, socket_a)
	model.connect_half_edge(edge.half_edge_b, node_b, socket_b)

	assert_that(model.remove_edge(&"edge")).is_true()

	assert_that(socket_a.occupied_by).is_null()
	assert_that(socket_b.occupied_by).is_null()
	assert_that(edge.half_edge_a.node).is_null()
	assert_that(edge.half_edge_a.socket).is_null()
	assert_that(edge.half_edge_b.node).is_null()
	assert_that(edge.half_edge_b.socket).is_null()


func _point(position: Vector2, in_handle: Vector2 = Vector2.ZERO, out_handle: Vector2 = Vector2.ZERO) -> CurvePoint:
	return CurvePoint.create(position, in_handle, out_handle)
