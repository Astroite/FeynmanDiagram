extends GdUnitTestSuite

# Phase 1 of the new interaction model: a tap selects the node/endpoint or line
# under the cursor (a drag still moves/bends); the selection can be deleted as one
# undoable step. Selection is geometry-only and never affects judging.

const DeleteEdgeCommandScript := preload("res://interaction/command/DeleteEdgeCommand.gd")
const DeleteNodeCommandScript := preload("res://interaction/command/DeleteNodeCommand.gd")


func test_tap_selects_node() -> void:
	var model := GraphModel.new()
	var node = model.add_node(&"v", NodeKind.VERTEX, Vector2(50.0, 50.0))
	var interaction := _interaction(model)

	interaction.handle_pointer_down(Vector2(50.0, 50.0))
	interaction.handle_pointer_up(Vector2(51.0, 50.0)) # within TAP_DISTANCE

	assert_bool(interaction.selected_node == node).is_true()
	assert_that(interaction.selected_edge).is_null()
	assert_bool(interaction.has_selection()).is_true()


func test_tap_on_empty_space_clears_selection() -> void:
	var model := GraphModel.new()
	var node = model.add_node(&"v", NodeKind.VERTEX, Vector2(50.0, 50.0))
	var interaction := _interaction(model)
	interaction.select_node(node)

	interaction.handle_pointer_down(Vector2(400.0, 400.0))
	interaction.handle_pointer_up(Vector2(400.0, 400.0))

	assert_bool(interaction.has_selection()).is_false()


func test_tap_selects_edge_without_inserting_a_bend() -> void:
	var model := GraphModel.new()
	var edge := model.add_edge(&"e", [_point(Vector2.ZERO), _point(Vector2(100.0, 0.0))])
	var interaction := _interaction(model)

	interaction.handle_pointer_down(Vector2(50.0, 0.0)) # press on the segment
	interaction.handle_pointer_up(Vector2(50.0, 0.0)) # released in place -> tap

	assert_bool(interaction.selected_edge == edge).is_true()
	assert_int(edge.curve_points.size()).is_equal(2) # the press-time bend point was rewound


func test_delete_selected_edge_and_undo_restores_connection() -> void:
	var model := GraphModel.new()
	var anchor = model.add_node(&"anchor", NodeKind.ANCHOR, Vector2(100.0, 0.0))
	var edge := model.add_edge(&"e", [_point(Vector2.ZERO), _point(Vector2(100.0, 0.0))])
	var socket: Socket = anchor.get_socket(&"socket_0")
	model.connect_half_edge(edge.half_edge_b, anchor, socket)
	edge.particle_id = &"electron"
	var interaction := _interaction(model)

	interaction.select_edge(edge)
	assert_bool(interaction.delete_selected()).is_true()
	assert_that(model.get_edge(&"e")).is_null()
	assert_that(socket.occupied_by).is_null()
	assert_bool(interaction.has_selection()).is_false()

	assert_bool(interaction.undo()).is_true()
	var restored := model.get_edge(&"e")
	assert_that(restored).is_not_null()
	assert_str(String(restored.particle_id)).is_equal("electron")
	assert_bool(restored.half_edge_b.socket == anchor.get_socket(&"socket_0")).is_true()


func test_delete_selected_node_removes_incident_edges_and_undo_restores() -> void:
	var model := GraphModel.new()
	var vertex = model.add_node(&"v", NodeKind.VERTEX, Vector2.ZERO)
	var anchor = model.add_node(&"anchor", NodeKind.ANCHOR, Vector2(100.0, 0.0))
	var edge := model.add_edge(&"e", [_point(Vector2.ZERO), _point(Vector2(100.0, 0.0))])
	model.connect_half_edge(edge.half_edge_a, vertex, vertex.get_socket(&"socket_0"))
	model.connect_half_edge(edge.half_edge_b, anchor, anchor.get_socket(&"socket_0"))
	var interaction := _interaction(model)

	interaction.select_node(vertex)
	assert_bool(interaction.delete_selected()).is_true()
	assert_that(model.get_node(&"v")).is_null()
	assert_that(model.get_edge(&"e")).is_null() # incident edge removed with the node

	assert_bool(interaction.undo()).is_true()
	var restored_node = model.get_node(&"v")
	var restored_edge := model.get_edge(&"e")
	assert_that(restored_node).is_not_null()
	assert_that(restored_edge).is_not_null()
	assert_bool(restored_edge.half_edge_a.node == restored_node).is_true()
	assert_bool(restored_edge.half_edge_b.node == anchor).is_true()


func _interaction(model: GraphModel) -> CurveInteraction:
	var interaction := CurveInteraction.new()
	auto_free(interaction)
	interaction.set_graph_model(model)
	return interaction


func _point(position: Vector2) -> CurvePoint:
	return CurvePoint.create(position)
