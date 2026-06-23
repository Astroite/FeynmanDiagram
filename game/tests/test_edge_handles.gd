extends GdUnitTestSuite

# Phase 3 of the new interaction model: a selected line exposes two Bézier control
# handles (the start point's out-tangent and the end point's in-tangent). Dragging a
# handle reshapes that end and commits as ONE undoable BendEdgeCommand. Handles are a
# presentation/authoring affordance — curve shape never participates in judging.


func test_dragging_start_handle_sets_out_tangent_and_single_undo() -> void:
	var model := GraphModel.new()
	var edge := model.add_edge(&"e", [_point(Vector2.ZERO), _point(Vector2(100.0, 0.0))])
	var interaction := _interaction(model)
	interaction.select_edge(edge)

	var tip := interaction.edge_handle_tip(edge, 0)
	interaction.handle_pointer_down(tip)
	assert_int(interaction.active_gesture()).is_equal(CurveInteraction.GESTURE_EDGE_HANDLE_DRAG)
	interaction.handle_pointer_moved(tip + Vector2(0.0, 40.0))
	interaction.handle_pointer_up(tip + Vector2(0.0, 40.0))

	assert_int(edge.curve_points.size()).is_equal(2) # no bend point inserted
	assert_that(edge.curve_points[0].out_handle).is_equal(tip + Vector2(0.0, 40.0) - Vector2.ZERO)
	assert_int(interaction.undo_stack.undo_count()).is_equal(1)

	assert_bool(interaction.undo()).is_true()
	assert_that(edge.curve_points[0].out_handle).is_equal(Vector2.ZERO)


func test_dragging_end_handle_sets_in_tangent() -> void:
	var model := GraphModel.new()
	var edge := model.add_edge(&"e", [_point(Vector2.ZERO), _point(Vector2(100.0, 0.0))])
	var interaction := _interaction(model)
	interaction.select_edge(edge)

	var anchor := interaction.edge_handle_anchor(edge, 1)
	assert_that(anchor).is_equal(Vector2(100.0, 0.0))
	var tip := interaction.edge_handle_tip(edge, 1)
	interaction.handle_pointer_down(tip)
	interaction.handle_pointer_moved(Vector2(70.0, -30.0))
	interaction.handle_pointer_up(Vector2(70.0, -30.0))

	# in_handle is stored relative to the end anchor (100, 0).
	assert_that(edge.curve_points[1].in_handle).is_equal(Vector2(70.0, -30.0) - Vector2(100.0, 0.0))


func test_handle_tap_keeps_selection() -> void:
	var model := GraphModel.new()
	var edge := model.add_edge(&"e", [_point(Vector2.ZERO), _point(Vector2(100.0, 0.0))])
	var interaction := _interaction(model)
	interaction.select_edge(edge)

	var tip := interaction.edge_handle_tip(edge, 0)
	interaction.handle_pointer_down(tip)
	interaction.handle_pointer_up(tip) # no move -> tap on the handle

	assert_bool(interaction.selected_edge == edge).is_true() # selection preserved
	assert_int(interaction.undo_stack.undo_count()).is_equal(0) # nothing committed


func test_handles_only_grab_when_their_edge_is_selected() -> void:
	# With no selection, pressing where a handle tip would be falls through to a bend.
	var model := GraphModel.new()
	var edge := model.add_edge(&"e", [_point(Vector2.ZERO), _point(Vector2(100.0, 0.0))])
	var interaction := _interaction(model)

	var tip := interaction.edge_handle_tip(edge, 0) # on the line, near the start
	interaction.handle_pointer_down(tip)
	assert_int(interaction.active_gesture()).is_equal(CurveInteraction.GESTURE_EDGE_BEND)
	interaction.cancel_gesture()


func test_handle_cancel_rewinds_preview() -> void:
	var model := GraphModel.new()
	var edge := model.add_edge(&"e", [_point(Vector2.ZERO), _point(Vector2(100.0, 0.0))])
	var interaction := _interaction(model)
	interaction.select_edge(edge)

	var tip := interaction.edge_handle_tip(edge, 0)
	interaction.handle_pointer_down(tip)
	interaction.handle_pointer_moved(tip + Vector2(0.0, 40.0))
	assert_bool(edge.curve_points[0].out_handle != Vector2.ZERO).is_true() # live preview
	interaction.cancel_gesture()

	assert_that(edge.curve_points[0].out_handle).is_equal(Vector2.ZERO) # rewound
	assert_int(interaction.undo_stack.undo_count()).is_equal(0)


func _interaction(model: GraphModel) -> CurveInteraction:
	var interaction := CurveInteraction.new()
	auto_free(interaction)
	interaction.set_graph_model(model)
	return interaction


func _point(position: Vector2) -> CurvePoint:
	return CurvePoint.create(position)
