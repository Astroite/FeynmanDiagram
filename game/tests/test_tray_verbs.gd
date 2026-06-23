extends GdUnitTestSuite

# Phase 2b tray verbs: drop a particle swatch onto an endpoint to seed its identity
# (SeedParticleCommand), or drop the endpoint token onto empty canvas to add an
# external endpoint (AddNodeCommand). Both go through CurveInteraction and are
# undoable. Seeds are presentation/authoring hints — judging never reads them.

const SeedParticleCommandScript := preload("res://interaction/command/SeedParticleCommand.gd")
const AddNodeCommandScript := preload("res://interaction/command/AddNodeCommand.gd")


func test_seed_particle_at_assigns_identity_and_undo_restores() -> void:
	var model := GraphModel.new()
	var node = model.add_node(&"ext", NodeKind.ANCHOR, Vector2(50.0, 50.0))
	var interaction := _interaction(model)

	assert_bool(interaction.seed_particle_at(Vector2(52.0, 50.0), &"electron")).is_true()
	assert_str(String(node.particle_id)).is_equal("electron")

	assert_bool(interaction.undo()).is_true()
	assert_str(String(node.particle_id)).is_equal("")


func test_seed_particle_overwrites_then_undo_restores_prior_seed() -> void:
	var model := GraphModel.new()
	var node = model.add_node(&"ext", NodeKind.ANCHOR, Vector2.ZERO)
	node.particle_id = &"electron"
	var interaction := _interaction(model)

	assert_bool(interaction.seed_particle_at(Vector2.ZERO, &"positron")).is_true()
	assert_str(String(node.particle_id)).is_equal("positron")

	assert_bool(interaction.undo()).is_true()
	assert_str(String(node.particle_id)).is_equal("electron")


func test_seed_particle_off_any_node_does_nothing() -> void:
	var model := GraphModel.new()
	model.add_node(&"ext", NodeKind.ANCHOR, Vector2.ZERO)
	var interaction := _interaction(model)

	assert_bool(interaction.seed_particle_at(Vector2(400.0, 400.0), &"electron")).is_false()
	assert_bool(interaction.undo()).is_false() # nothing was pushed


func test_add_endpoint_at_creates_anchor_with_free_socket_and_undo_removes() -> void:
	var model := GraphModel.new()
	var interaction := _interaction(model)

	assert_bool(interaction.add_endpoint_at(Vector2(120.0, 80.0))).is_true()
	assert_int(model.nodes.size()).is_equal(1)
	var node = model.nodes.values()[0]
	assert_int(node.kind).is_equal(NodeKind.ANCHOR)
	assert_int(node.sockets.size()).is_equal(1)
	assert_that(node.sockets[0].occupied_by).is_null()
	assert_that(node.position).is_equal(Vector2(120.0, 80.0))

	assert_bool(interaction.undo()).is_true()
	assert_int(model.nodes.size()).is_equal(0)


func test_added_endpoint_can_be_seeded_and_grown_into_a_line() -> void:
	# End-to-end: token -> endpoint, swatch -> seed, then the long-press draw gesture
	# pulls a line into a vertex. Exercises the whole Phase 2 verb chain.
	var model := GraphModel.new()
	var vertex = model.add_node(&"v", NodeKind.VERTEX, Vector2(100.0, 0.0))
	var interaction := _interaction(model)

	assert_bool(interaction.add_endpoint_at(Vector2.ZERO)).is_true()
	var endpoint = model.get_node(&"endpoint_1")
	assert_that(endpoint).is_not_null()
	assert_bool(interaction.seed_particle_at(Vector2.ZERO, &"electron")).is_true()

	interaction.handle_pointer_down(Vector2.ZERO)
	interaction._process(0.4)
	interaction.handle_pointer_moved(Vector2(100.0, 0.0))
	interaction.handle_pointer_up(Vector2(100.0, 0.0))

	assert_int(model.edges.size()).is_equal(1)
	var edge: GraphEdge = model.edges.values()[0]
	assert_str(String(edge.particle_id)).is_equal("electron")
	assert_bool(edge.half_edge_a.node == endpoint).is_true()
	assert_bool(edge.half_edge_b.node == vertex).is_true()


func _interaction(model: GraphModel) -> CurveInteraction:
	var interaction := CurveInteraction.new()
	auto_free(interaction)
	interaction.set_graph_model(model)
	return interaction
