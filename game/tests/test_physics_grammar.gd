extends GdUnitTestSuite

const PhysicsGrammarScript := preload("res://core/physics/PhysicsGrammar.gd")

const ANNIHILATION := "res://level/levels/007_annihilation_gate.tres"


# --- Real level data: the e+e- -> mu+mu- diagram ---

func test_annihilation_reference_is_valid() -> void:
	var spec: Resource = load(ANNIHILATION)
	var model: GraphModel = spec.create_model_from_reference()
	var result := PhysicsGrammarScript.new().validate(model)
	assert_bool(result["ok"]).is_true()
	assert_str(result["stage"]).is_equal("ok")


func test_annihilation_givens_fail_on_integrity() -> void:
	var spec: Resource = load(ANNIHILATION)
	var model: GraphModel = spec.create_model_from_givens()
	var result := PhysicsGrammarScript.new().validate(model)
	# The givens leave a positron half-edge dangling.
	assert_bool(result["ok"]).is_false()
	assert_str(result["stage"]).is_equal("integrity")


# --- Single-vertex unit cases ---

func test_valid_qed_vertex_electron_positron_photon() -> void:
	var model := _single_vertex_model([
		{"particle": "electron"}, {"particle": "positron"}, {"particle": "photon"},
	])
	var result := PhysicsGrammarScript.new().validate(model)
	assert_bool(result["ok"]).is_true()


func test_vertex_without_photon_is_rejected() -> void:
	var model := _single_vertex_model([
		{"particle": "electron"}, {"particle": "positron"}, {"particle": "electron"},
	])
	var result := PhysicsGrammarScript.new().validate(model)
	assert_bool(result["ok"]).is_false()
	assert_str(result["stage"]).is_equal("vertex")


func test_vertex_with_mismatched_families_is_rejected() -> void:
	var model := _single_vertex_model([
		{"particle": "electron"}, {"particle": "muon"}, {"particle": "photon"},
	])
	var result := PhysicsGrammarScript.new().validate(model)
	assert_bool(result["ok"]).is_false()
	assert_str(result["stage"]).is_equal("vertex")
	assert_str(result["message"]).contains("味道")


func test_vertex_with_broken_fermion_flow_is_rejected() -> void:
	# Two electrons (same family) both point their arrows into the vertex -> not continuous.
	var model := _single_vertex_model([
		{"particle": "electron"}, {"particle": "electron"}, {"particle": "photon"},
	])
	var result := PhysicsGrammarScript.new().validate(model)
	assert_bool(result["ok"]).is_false()
	assert_str(result["stage"]).is_equal("vertex")
	assert_str(result["message"]).contains("流向")


func test_wrong_leg_count_is_rejected() -> void:
	var model := _single_vertex_model([
		{"particle": "electron"}, {"particle": "photon"},
	])
	var result := PhysicsGrammarScript.new().validate(model)
	assert_bool(result["ok"]).is_false()
	assert_str(result["stage"]).is_equal("vertex")


# Builds a graph with one vertex "v" whose legs are the given particles, each the
# b-end of an edge anchored at its own external node (so each leg sits at the
# fermion arrow's head when the particle is matter).
func _single_vertex_model(legs: Array) -> GraphModel:
	var vertex_sockets: Array = []
	for index in range(legs.size()):
		vertex_sockets.append({"id": "socket_%d" % index, "local_offset": [0.0, 0.0]})
	var nodes: Array = [{"id": "v", "kind": 1, "position": [400.0, 300.0], "sockets": vertex_sockets}]
	var edges: Array = []
	for index in range(legs.size()):
		var particle: String = legs[index]["particle"]
		var sign := _fermion_sign(particle)
		nodes.append({
			"id": "a%d" % index,
			"kind": 0,
			"position": [100.0, 100.0 * index],
			"sockets": [{"id": "socket_0", "local_offset": [0.0, 0.0]}],
		})
		edges.append({
			"id": "e%d" % index,
			"particle_id": particle,
			"time_axis_dir": 1,
			"curve_points": [
				{"position": [100.0, 100.0 * index], "in_handle": [0.0, 0.0], "out_handle": [0.0, 0.0]},
				{"position": [400.0, 300.0], "in_handle": [0.0, 0.0], "out_handle": [0.0, 0.0]},
			],
			"half_edges": [
				{"id": "e%d:a" % index, "node_id": "a%d" % index, "socket_id": "socket_0", "particle_id": particle, "fermion_flow": sign},
				{"id": "e%d:b" % index, "node_id": "v", "socket_id": "socket_%d" % index, "particle_id": particle, "fermion_flow": sign},
			],
		})
	return GraphModel.from_dict({"nodes": nodes, "edges": edges})


func _fermion_sign(particle: String) -> int:
	var spec = ParticleSpec.get_spec(StringName(particle))
	return spec.fermion_sign if spec != null else 0
