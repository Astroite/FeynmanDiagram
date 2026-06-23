extends GdUnitTestSuite

# Phase 4: a right-button stroke that starts on empty canvas and slides across lines
# cuts (deletes) every line it crosses, as ONE undoable step. Starting on a node or a
# line does not begin a cut.


func test_cut_stroke_deletes_crossed_lines_in_one_undo() -> void:
	var model := GraphModel.new()
	model.add_edge(&"e1", [_point(Vector2(0.0, 0.0)), _point(Vector2(0.0, 100.0))])
	model.add_edge(&"e2", [_point(Vector2(50.0, 0.0)), _point(Vector2(50.0, 100.0))])
	var interaction := _interaction(model)

	# A horizontal slash across both vertical lines, beginning in empty space.
	interaction.handle_cut_down(Vector2(-20.0, 50.0))
	interaction.handle_cut_moved(Vector2(70.0, 50.0))
	interaction.handle_cut_up(Vector2(70.0, 50.0))

	assert_int(model.edges.size()).is_equal(0)
	assert_bool(interaction.undo()).is_true()
	assert_int(model.edges.size()).is_equal(2) # the whole slash undoes at once


func test_cut_starting_on_a_line_does_not_begin() -> void:
	var model := GraphModel.new()
	model.add_edge(&"e1", [_point(Vector2(0.0, 0.0)), _point(Vector2(0.0, 100.0))])
	var interaction := _interaction(model)

	interaction.handle_cut_down(Vector2(0.0, 50.0)) # on the line, not empty
	interaction.handle_cut_moved(Vector2(70.0, 50.0))
	interaction.handle_cut_up(Vector2(70.0, 50.0))

	assert_int(model.edges.size()).is_equal(1)
	assert_bool(interaction.undo()).is_false() # nothing was pushed


func test_cut_that_crosses_nothing_deletes_nothing() -> void:
	var model := GraphModel.new()
	model.add_edge(&"e1", [_point(Vector2(0.0, 0.0)), _point(Vector2(0.0, 100.0))])
	var interaction := _interaction(model)

	interaction.handle_cut_down(Vector2(-40.0, -40.0))
	interaction.handle_cut_moved(Vector2(-30.0, -40.0))
	interaction.handle_cut_up(Vector2(-30.0, -40.0))

	assert_int(model.edges.size()).is_equal(1)
	assert_bool(interaction.undo()).is_false()


func test_cutting_the_selected_line_clears_selection() -> void:
	var model := GraphModel.new()
	var edge := model.add_edge(&"e1", [_point(Vector2(0.0, 0.0)), _point(Vector2(0.0, 100.0))])
	var interaction := _interaction(model)
	interaction.select_edge(edge)

	interaction.handle_cut_down(Vector2(-20.0, 50.0))
	interaction.handle_cut_moved(Vector2(20.0, 50.0))
	interaction.handle_cut_up(Vector2(20.0, 50.0))

	assert_int(model.edges.size()).is_equal(0)
	assert_bool(interaction.has_selection()).is_false()


func _interaction(model: GraphModel) -> CurveInteraction:
	var interaction := CurveInteraction.new()
	auto_free(interaction)
	interaction.set_graph_model(model)
	return interaction


func _point(position: Vector2) -> CurvePoint:
	return CurvePoint.create(position)
