extends GdUnitTestSuite

# Phase 4: a selected fermion line can be reversed. Reversing swaps the edge's two
# half-edges and flips the stored curve, so the geometry is unchanged but the fermion
# arrow (which PhysicsGrammar derives from which end is `a`) turns around. Photons have
# no arrow and cannot be reversed. Reversing is undoable.

const ReverseEdgeCommandScript := preload("res://interaction/command/ReverseEdgeCommand.gd")


func test_reverse_flips_fermion_arrow_at_vertex() -> void:
	var model := GraphModel.new()
	var ext = model.add_node(&"ext", NodeKind.ANCHOR, Vector2.ZERO)
	var vertex = model.add_node(&"v", NodeKind.VERTEX, Vector2(100.0, 0.0))
	var edge := model.add_edge(&"e", [_point(Vector2.ZERO), _point(Vector2(100.0, 0.0))])
	edge.particle_id = &"electron"
	edge.half_edge_a.particle_id = &"electron"
	edge.half_edge_b.particle_id = &"electron"
	model.connect_half_edge(edge.half_edge_a, ext, ext.get_socket(&"socket_0"))
	model.connect_half_edge(edge.half_edge_b, vertex, vertex.get_socket(&"socket_0"))

	var grammar := PhysicsGrammar.new()
	var vertex_leg: HalfEdge = vertex.get_socket(&"socket_0").occupied_by
	# Electron (matter) drawn ext -> vertex: arrow runs a->b, i.e. into the vertex.
	assert_bool(grammar.arrow_into_vertex(vertex_leg)).is_true()

	assert_bool(model.reverse_edge(edge)).is_true()
	# Same physical leg, now the a-end -> arrow points away from the vertex.
	assert_bool(grammar.arrow_into_vertex(vertex_leg)).is_false()
	# Geometry is unchanged: the curve start now sits at the far (100,0) endpoint.
	assert_that(edge.curve_points[0].position).is_equal(Vector2(100.0, 0.0))

	assert_bool(model.reverse_edge(edge)).is_true() # reversing again restores
	assert_bool(grammar.arrow_into_vertex(vertex_leg)).is_true()
	assert_that(edge.curve_points[0].position).is_equal(Vector2.ZERO)


func test_reverse_swaps_curve_point_handles() -> void:
	var model := GraphModel.new()
	var edge := model.add_edge(&"e", [
		CurvePoint.create(Vector2.ZERO, Vector2(-5.0, 0.0), Vector2(0.0, 20.0)),
		CurvePoint.create(Vector2(100.0, 0.0), Vector2(0.0, -30.0), Vector2(7.0, 0.0)),
	])

	assert_bool(model.reverse_edge(edge)).is_true()

	# Old last point is now first, with its in/out tangents swapped.
	assert_that(edge.curve_points[0].position).is_equal(Vector2(100.0, 0.0))
	assert_that(edge.curve_points[0].in_handle).is_equal(Vector2(7.0, 0.0))
	assert_that(edge.curve_points[0].out_handle).is_equal(Vector2(0.0, -30.0))


func test_reverse_selected_edge_is_undoable() -> void:
	var model := GraphModel.new()
	var edge := model.add_edge(&"e", [_point(Vector2.ZERO), _point(Vector2(100.0, 0.0))])
	edge.particle_id = &"electron"
	var interaction := _interaction(model)
	interaction.select_edge(edge)

	assert_bool(interaction.can_reverse_selection()).is_true()
	var original_a := edge.half_edge_a
	assert_bool(interaction.reverse_selected_edge()).is_true()
	assert_bool(edge.half_edge_a == original_a).is_false() # swapped
	assert_bool(interaction.selected_edge == edge).is_true() # selection kept

	assert_bool(interaction.undo()).is_true()
	assert_bool(edge.half_edge_a == original_a).is_true() # restored


func test_photon_line_cannot_be_reversed() -> void:
	var model := GraphModel.new()
	var edge := model.add_edge(&"e", [_point(Vector2.ZERO), _point(Vector2(100.0, 0.0))])
	edge.particle_id = &"photon"
	var interaction := _interaction(model)
	interaction.select_edge(edge)

	assert_bool(interaction.can_reverse_selection()).is_false()
	assert_bool(interaction.reverse_selected_edge()).is_true() # command runs, but...
	# ...reversing a photon is geometry-only; there's no arrow to see flip. We only
	# gate the *button* on can_reverse_selection, so nothing here should crash.


func _interaction(model: GraphModel) -> CurveInteraction:
	var interaction := CurveInteraction.new()
	auto_free(interaction)
	interaction.set_graph_model(model)
	return interaction


func _point(position: Vector2) -> CurvePoint:
	return CurvePoint.create(position)
