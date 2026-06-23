extends GdUnitTestSuite

# Phase 2 of the new interaction model: a long press on a *seeded* endpoint charges
# (~CHARGE_TIME), then a drag pulls out a new line of the source particle's type that
# snaps to a free socket on another node and commits as one undoable CreateEdgeCommand.
# Fermion direction is implicit: source -> half_edge_a, target -> half_edge_b, so the
# particle's sign (via PhysicsGrammar) produces the arrow with no special-casing here.

const CHARGE_TIME := 0.3


func test_long_press_then_drag_creates_seeded_line() -> void:
	var model := GraphModel.new()
	var source = _seeded_node(model, &"src", &"electron", Vector2.ZERO)
	var target = model.add_node(&"dst", NodeKind.VERTEX, Vector2(100.0, 0.0))
	var interaction := _interaction(model)

	_draw(interaction, Vector2.ZERO, Vector2(100.0, 0.0))

	assert_int(model.edges.size()).is_equal(1)
	var edge: GraphEdge = model.edges.values()[0]
	assert_str(String(edge.particle_id)).is_equal("electron")
	assert_str(String(edge.half_edge_a.particle_id)).is_equal("electron")
	assert_str(String(edge.half_edge_b.particle_id)).is_equal("electron")
	# source -> a, target -> b
	assert_bool(edge.half_edge_a.node == source).is_true()
	assert_bool(edge.half_edge_a.socket == source.get_socket(&"socket_0")).is_true()
	assert_bool(edge.half_edge_b.node == target).is_true()
	assert_bool(edge.half_edge_b.socket == target.get_socket(&"socket_0")).is_true()


func test_fermion_flow_stores_particle_sign() -> void:
	# electron sign = +1, positron sign = -1; both halves store the source's sign.
	var electron_model := GraphModel.new()
	_seeded_node(electron_model, &"src", &"electron", Vector2.ZERO)
	electron_model.add_node(&"dst", NodeKind.VERTEX, Vector2(100.0, 0.0))
	_draw(_interaction(electron_model), Vector2.ZERO, Vector2(100.0, 0.0))
	var electron_edge: GraphEdge = electron_model.edges.values()[0]
	assert_int(electron_edge.half_edge_a.fermion_flow).is_equal(1)
	assert_int(electron_edge.half_edge_b.fermion_flow).is_equal(1)

	var positron_model := GraphModel.new()
	_seeded_node(positron_model, &"src", &"positron", Vector2.ZERO)
	positron_model.add_node(&"dst", NodeKind.VERTEX, Vector2(100.0, 0.0))
	_draw(_interaction(positron_model), Vector2.ZERO, Vector2(100.0, 0.0))
	var positron_edge: GraphEdge = positron_model.edges.values()[0]
	assert_int(positron_edge.half_edge_a.fermion_flow).is_equal(-1)
	assert_int(positron_edge.half_edge_b.fermion_flow).is_equal(-1)


func test_drawn_line_can_be_undone() -> void:
	var model := GraphModel.new()
	_seeded_node(model, &"src", &"electron", Vector2.ZERO)
	model.add_node(&"dst", NodeKind.VERTEX, Vector2(100.0, 0.0))
	var interaction := _interaction(model)

	_draw(interaction, Vector2.ZERO, Vector2(100.0, 0.0))
	assert_int(model.edges.size()).is_equal(1)

	assert_bool(interaction.undo()).is_true()
	assert_int(model.edges.size()).is_equal(0)


func test_seeded_anchor_can_grow_a_line() -> void:
	# External endpoints are anchors (locked for dragging) but may still seed a line.
	var model := GraphModel.new()
	var anchor = _seeded_node(model, &"ext", &"electron", Vector2.ZERO, NodeKind.ANCHOR)
	var target = model.add_node(&"dst", NodeKind.VERTEX, Vector2(100.0, 0.0))
	var interaction := _interaction(model)

	_draw(interaction, Vector2.ZERO, Vector2(100.0, 0.0))

	assert_int(model.edges.size()).is_equal(1)
	var edge: GraphEdge = model.edges.values()[0]
	assert_bool(edge.half_edge_a.node == anchor).is_true()
	assert_bool(edge.half_edge_b.node == target).is_true()


func test_moving_before_charge_fills_does_not_draw() -> void:
	# A movable seeded node dragged before the charge completes demotes to a reposition;
	# no line is created and the node ends up moved.
	var model := GraphModel.new()
	var source = _seeded_node(model, &"src", &"electron", Vector2.ZERO)
	model.add_node(&"dst", NodeKind.VERTEX, Vector2(100.0, 0.0))
	var interaction := _interaction(model)

	interaction.handle_pointer_down(Vector2.ZERO)
	assert_int(interaction.active_gesture()).is_equal(CurveInteraction.GestureKind.LONG_PRESS_CHARGING)
	interaction.handle_pointer_moved(Vector2(40.0, 0.0)) # past TAP_DISTANCE before charge
	assert_int(interaction.active_gesture()).is_equal(CurveInteraction.GestureKind.NODE_DRAG)
	interaction.handle_pointer_up(Vector2(40.0, 0.0))

	assert_int(model.edges.size()).is_equal(0)
	assert_that(source.position).is_equal(Vector2(40.0, 0.0))


func test_release_off_target_does_not_draw() -> void:
	var model := GraphModel.new()
	_seeded_node(model, &"src", &"electron", Vector2.ZERO)
	model.add_node(&"dst", NodeKind.VERTEX, Vector2(400.0, 0.0)) # far outside snap radius
	var interaction := _interaction(model)

	interaction.handle_pointer_down(Vector2.ZERO)
	interaction._process(CHARGE_TIME + 0.1)
	assert_int(interaction.active_gesture()).is_equal(CurveInteraction.GestureKind.DRAW_ARC)
	interaction.handle_pointer_moved(Vector2(200.0, 0.0))
	interaction.handle_pointer_up(Vector2(200.0, 0.0)) # empty space, no socket nearby

	assert_int(model.edges.size()).is_equal(0)


func test_unseeded_node_does_not_charge() -> void:
	# A plain (unseeded) node keeps the old behaviour: a tap selects it, no charge.
	var model := GraphModel.new()
	var node = model.add_node(&"v", NodeKind.VERTEX, Vector2.ZERO)
	var interaction := _interaction(model)

	interaction.handle_pointer_down(Vector2.ZERO)
	assert_int(interaction.active_gesture()).is_equal(CurveInteraction.GestureKind.NODE_DRAG)
	interaction.handle_pointer_up(Vector2(1.0, 0.0)) # tap -> select

	assert_bool(interaction.selected_node == node).is_true()
	assert_int(model.edges.size()).is_equal(0)


# Drive the full long-press -> charge -> drag -> release-on-target gesture.
func _draw(interaction: CurveInteraction, source_pos: Vector2, target_pos: Vector2) -> void:
	interaction.handle_pointer_down(source_pos)
	interaction._process(CHARGE_TIME + 0.1) # fill the charge -> DRAW_ARC
	interaction.handle_pointer_moved(target_pos)
	interaction.handle_pointer_up(target_pos)


func _seeded_node(model: GraphModel, id: StringName, particle_id: StringName, position: Vector2, kind: int = NodeKind.VERTEX):
	var node = model.add_node(id, kind, position)
	node.particle_id = particle_id
	return node


func _interaction(model: GraphModel) -> CurveInteraction:
	var interaction := CurveInteraction.new()
	auto_free(interaction)
	interaction.set_graph_model(model)
	return interaction
