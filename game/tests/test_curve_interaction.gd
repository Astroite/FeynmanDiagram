extends GdUnitTestSuite

const BendEdgeCommandScript := preload("res://interaction/command/BendEdgeCommand.gd")
const ConnectHalfEdgeCommandScript := preload("res://interaction/command/ConnectHalfEdgeCommand.gd")
const MoveNodeCommandScript := preload("res://interaction/command/MoveNodeCommand.gd")


func test_move_node_command_do_undo_redo() -> void:
	var model := GraphModel.new()
	var node = model.add_node(&"node", NodeKind.VERTEX, Vector2.ZERO)
	var command = MoveNodeCommandScript.new().configure(model, node, Vector2(12.0, 4.0))

	assert_that(command.do()).is_true()
	assert_that(node.position).is_equal(Vector2(12.0, 4.0))
	assert_that(command.undo()).is_true()
	assert_that(node.position).is_equal(Vector2.ZERO)
	assert_that(command.do()).is_true()
	assert_that(node.position).is_equal(Vector2(12.0, 4.0))


func test_bend_edge_command_do_undo_redo() -> void:
	var model := GraphModel.new()
	var edge := model.add_edge(&"edge", [
		_point(Vector2.ZERO),
		_point(Vector2(100.0, 0.0)),
	])
	var initial_state := _snapshot(model)
	var bent_points := [
		_point(Vector2.ZERO),
		_point(Vector2(50.0, 18.0)),
		_point(Vector2(100.0, 0.0)),
	]
	var command = BendEdgeCommandScript.new().configure(model, edge, bent_points)

	assert_that(command.do()).is_true()
	assert_that(edge.curve_points.size()).is_equal(3)
	assert_that(edge.curve_points[1].position).is_equal(Vector2(50.0, 18.0))
	assert_that(command.undo()).is_true()
	assert_that(_snapshot(model)).is_equal(initial_state)
	assert_that(command.do()).is_true()
	assert_that(edge.curve_points[1].position).is_equal(Vector2(50.0, 18.0))


func test_connect_half_edge_command_do_undo_redo() -> void:
	var model := GraphModel.new()
	var node = model.add_node(&"anchor", NodeKind.ANCHOR, Vector2(20.0, 0.0))
	var edge := model.add_edge(&"edge", [
		_point(Vector2.ZERO),
		_point(Vector2(20.0, 0.0)),
	])
	var socket: Socket = node.get_socket(&"socket_0")
	var command = ConnectHalfEdgeCommandScript.new().configure(model, edge.half_edge_b, node, socket)

	assert_that(command.do()).is_true()
	assert_that(edge.half_edge_b.node == node).is_true()
	assert_that(socket.occupied_by == edge.half_edge_b).is_true()
	assert_that(command.undo()).is_true()
	assert_that(edge.half_edge_b.node).is_null()
	assert_that(socket.occupied_by).is_null()
	assert_that(command.do()).is_true()
	assert_that(edge.half_edge_b.socket == socket).is_true()


func test_undo_stack_restores_and_reproduces_mixed_sequence() -> void:
	var model := GraphModel.new()
	var node = model.add_node(&"node", NodeKind.VERTEX, Vector2.ZERO)
	var anchor = model.add_node(&"anchor", NodeKind.ANCHOR, Vector2(100.0, 0.0))
	var edge := model.add_edge(&"edge", [
		_point(Vector2.ZERO),
		_point(Vector2(100.0, 0.0)),
	])
	var stack := UndoStack.new()
	var initial_state := _snapshot(model)

	assert_that(stack.push(MoveNodeCommandScript.new().configure(model, node, Vector2(10.0, 8.0)))).is_true()
	assert_that(stack.push(BendEdgeCommandScript.new().configure(model, edge, [
		_point(Vector2.ZERO),
		_point(Vector2(45.0, 20.0)),
		_point(Vector2(100.0, 0.0)),
	]))).is_true()
	assert_that(stack.push(ConnectHalfEdgeCommandScript.new().configure(model, edge.half_edge_b, anchor, anchor.get_socket(&"socket_0")))).is_true()
	var final_state := _snapshot(model)

	assert_that(stack.undo()).is_true()
	assert_that(stack.undo()).is_true()
	assert_that(stack.undo()).is_true()
	assert_that(_snapshot(model)).is_equal(initial_state)

	assert_that(stack.redo()).is_true()
	assert_that(stack.redo()).is_true()
	assert_that(stack.redo()).is_true()
	assert_that(_snapshot(model)).is_equal(final_state)


func test_snap_connects_within_radius_and_not_outside() -> void:
	var inside_model := GraphModel.new()
	var inside_anchor = inside_model.add_node(&"anchor", NodeKind.ANCHOR, Vector2(100.0, 0.0))
	var inside_edge := inside_model.add_edge(&"edge", [
		_point(Vector2.ZERO),
		_point(Vector2(40.0, 0.0)),
	])
	var inside_interaction := _interaction(inside_model)
	inside_interaction.snap_radius = 16.0

	inside_interaction.handle_pointer_down(Vector2(40.0, 0.0))
	inside_interaction.handle_pointer_up(Vector2(109.0, 0.0))

	assert_that(inside_edge.half_edge_b.socket == inside_anchor.get_socket(&"socket_0")).is_true()
	assert_that(inside_anchor.get_socket(&"socket_0").occupied_by == inside_edge.half_edge_b).is_true()

	var outside_model := GraphModel.new()
	var outside_anchor = outside_model.add_node(&"anchor", NodeKind.ANCHOR, Vector2(100.0, 0.0))
	var outside_edge := outside_model.add_edge(&"edge", [
		_point(Vector2.ZERO),
		_point(Vector2(40.0, 0.0)),
	])
	var outside_interaction := _interaction(outside_model)
	outside_interaction.snap_radius = 16.0

	outside_interaction.handle_pointer_down(Vector2(40.0, 0.0))
	outside_interaction.handle_pointer_up(Vector2(140.0, 0.0))

	assert_that(outside_edge.half_edge_b.node).is_null()
	assert_that(outside_edge.half_edge_b.socket).is_null()
	assert_that(outside_anchor.get_socket(&"socket_0").occupied_by).is_null()


func test_gesture_classification_prefers_node_then_free_half_edge_then_edge() -> void:
	var model := GraphModel.new()
	model.add_node(&"node", NodeKind.VERTEX, Vector2(10.0, 10.0))
	model.add_edge(&"bendable", [
		_point(Vector2(0.0, 50.0)),
		_point(Vector2(100.0, 50.0)),
	])
	model.add_edge(&"loose", [
		_point(Vector2(0.0, 100.0)),
		_point(Vector2(100.0, 100.0)),
	])
	var interaction := _interaction(model)

	assert_that(interaction.classify_gesture_at(Vector2(10.0, 10.0))).is_equal(CurveInteraction.GESTURE_NODE_DRAG)
	assert_that(interaction.classify_gesture_at(Vector2(100.0, 100.0))).is_equal(CurveInteraction.GESTURE_HALF_EDGE_DRAG)
	assert_that(interaction.classify_gesture_at(Vector2(50.0, 50.0))).is_equal(CurveInteraction.GESTURE_EDGE_BEND)
	assert_that(interaction.classify_gesture_at(Vector2(300.0, 300.0))).is_equal(CurveInteraction.GESTURE_NONE)


func test_node_drag_is_live_and_single_undo() -> void:
	var model := GraphModel.new()
	var node = model.add_node(&"node", NodeKind.VERTEX, Vector2.ZERO)
	var interaction := _interaction(model)

	interaction.handle_pointer_down(Vector2.ZERO)
	interaction.handle_pointer_moved(Vector2(10.0, 0.0))
	assert_that(node.position).is_equal(Vector2(10.0, 0.0)) # live 1:1 follow mid-drag
	interaction.handle_pointer_moved(Vector2(30.0, 6.0))
	assert_that(node.position).is_equal(Vector2(30.0, 6.0))
	interaction.handle_pointer_up(Vector2(30.0, 6.0))

	assert_that(node.position).is_equal(Vector2(30.0, 6.0))
	assert_that(interaction.undo_stack.undo_count()).is_equal(1) # whole drag = one undo entry
	assert_that(interaction.undo()).is_true()
	assert_that(node.position).is_equal(Vector2.ZERO)


func test_bend_creates_smooth_curve_not_kink() -> void:
	var model := GraphModel.new()
	var edge := model.add_edge(&"edge", [
		_point(Vector2.ZERO),
		_point(Vector2(100.0, 0.0)),
	])
	var interaction := _interaction(model)

	interaction.handle_pointer_down(Vector2(50.0, 0.0)) # grab the straight segment
	interaction.handle_pointer_moved(Vector2(50.0, 40.0))

	assert_that(edge.curve_points.size()).is_equal(3) # one interior point, inserted once
	assert_that(edge.curve_points[1].position).is_equal(Vector2(50.0, 40.0)) # live follow
	assert_bool(edge.curve_points[1].out_handle != Vector2.ZERO).is_true() # smooth tangent, not a kink

	interaction.handle_pointer_up(Vector2(50.0, 40.0))
	assert_that(interaction.undo_stack.undo_count()).is_equal(1)
	assert_that(interaction.undo()).is_true()
	assert_that(edge.curve_points.size()).is_equal(2) # back to a straight line


func test_anchor_node_is_not_draggable() -> void:
	var model := GraphModel.new()
	var anchor = model.add_node(&"anchor", NodeKind.ANCHOR, Vector2(50.0, 50.0))
	var interaction := _interaction(model)

	interaction.handle_pointer_down(Vector2(50.0, 50.0))
	assert_that(interaction.active_gesture()).is_equal(CurveInteraction.GESTURE_NONE)
	interaction.handle_pointer_moved(Vector2(90.0, 90.0))
	interaction.handle_pointer_up(Vector2(90.0, 90.0))

	assert_that(anchor.position).is_equal(Vector2(50.0, 50.0)) # locked endpoint never moved
	assert_that(interaction.undo_stack.undo_count()).is_equal(0)


func test_cancel_rewinds_live_preview() -> void:
	var model := GraphModel.new()
	var node = model.add_node(&"node", NodeKind.VERTEX, Vector2.ZERO)
	var interaction := _interaction(model)

	interaction.handle_pointer_down(Vector2.ZERO)
	interaction.handle_pointer_moved(Vector2(25.0, 0.0))
	assert_that(node.position).is_equal(Vector2(25.0, 0.0))
	interaction.cancel_gesture()

	assert_that(node.position).is_equal(Vector2.ZERO) # preview rewound
	assert_that(interaction.undo_stack.undo_count()).is_equal(0) # nothing committed


func _interaction(model: GraphModel) -> CurveInteraction:
	var interaction := CurveInteraction.new()
	auto_free(interaction)
	interaction.set_graph_model(model)
	return interaction


func _snapshot(model: GraphModel) -> String:
	return JSON.stringify(model.to_dict())


func _point(position: Vector2) -> CurvePoint:
	return CurvePoint.create(position)
