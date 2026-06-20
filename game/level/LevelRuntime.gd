class_name LevelRuntime
extends Node

const CurveInteractionScript := preload("res://interaction/CurveInteraction.gd")
const CurveRendererScript := preload("res://render/CurveRenderer.gd")

signal level_loaded(spec: Resource)
signal objective_met(objective: Resource)
signal level_complete(spec: Resource)

var level_spec: Resource = null
var graph_model: GraphModel = null
var curve_interaction: Node = null
var curve_renderer: Node = null

var _objective_states: Dictionary = {}
var _is_complete := false


func load_level(spec: Resource) -> bool:
	if spec == null or not spec.has_method("create_model_from_givens"):
		return false

	level_spec = spec
	_install_model(spec.create_model_from_givens())
	_objective_states.clear()
	_is_complete = false
	_ensure_children()
	_inject_model()
	level_loaded.emit(spec)
	evaluate_objectives()
	return true


func load_level_path(path: String) -> bool:
	var spec := load(path)
	return load_level(spec)


func apply_reference_solution() -> bool:
	if level_spec == null or not level_spec.has_method("create_model_from_reference"):
		return false
	var reference_model: GraphModel = level_spec.create_model_from_reference()
	if reference_model == null:
		return false

	_install_model(reference_model)
	_inject_model()
	evaluate_objectives()
	return true


func evaluate_objectives() -> bool:
	if level_spec == null or graph_model == null:
		return false

	var all_met := true
	for objective: Resource in level_spec.spatial_objectives:
		if objective == null or not objective.has_method("is_met"):
			all_met = false
			continue

		var met := bool(objective.is_met(graph_model))
		var objective_id := _objective_id(objective)
		if met and not bool(_objective_states.get(objective_id, false)):
			objective_met.emit(objective)
		_objective_states[objective_id] = met
		all_met = all_met and met

	if all_met and not _is_complete and not level_spec.spatial_objectives.is_empty():
		_is_complete = true
		if curve_renderer != null and curve_renderer.has_method("play_completion"):
			curve_renderer.play_completion()
		level_complete.emit(level_spec)
	return _is_complete


func is_level_complete() -> bool:
	return _is_complete


func _install_model(model: GraphModel) -> void:
	_disconnect_graph_model()
	graph_model = model
	_connect_graph_model()


func _connect_graph_model() -> void:
	if graph_model == null:
		return
	if not graph_model.node_changed.is_connected(_on_graph_node_changed):
		graph_model.node_changed.connect(_on_graph_node_changed)
	if not graph_model.edge_changed.is_connected(_on_graph_edge_changed):
		graph_model.edge_changed.connect(_on_graph_edge_changed)
	if not graph_model.topology_changed.is_connected(_on_graph_changed):
		graph_model.topology_changed.connect(_on_graph_changed)


func _disconnect_graph_model() -> void:
	if graph_model == null:
		return
	if graph_model.node_changed.is_connected(_on_graph_node_changed):
		graph_model.node_changed.disconnect(_on_graph_node_changed)
	if graph_model.edge_changed.is_connected(_on_graph_edge_changed):
		graph_model.edge_changed.disconnect(_on_graph_edge_changed)
	if graph_model.topology_changed.is_connected(_on_graph_changed):
		graph_model.topology_changed.disconnect(_on_graph_changed)


func _on_graph_node_changed(_node) -> void:
	_on_graph_changed()


func _on_graph_edge_changed(_edge: GraphEdge) -> void:
	_on_graph_changed()


func _on_graph_changed() -> void:
	evaluate_objectives()


func _ensure_children() -> void:
	if curve_interaction == null:
		curve_interaction = get_node_or_null("CurveInteraction")
	if curve_interaction == null:
		curve_interaction = CurveInteractionScript.new()
		curve_interaction.name = "CurveInteraction"
		add_child(curve_interaction)

	if curve_renderer == null:
		curve_renderer = get_node_or_null("CurveRenderer")
	if curve_renderer == null:
		curve_renderer = CurveRendererScript.new()
		curve_renderer.name = "CurveRenderer"
		add_child(curve_renderer)


func _inject_model() -> void:
	_ensure_children()
	if curve_interaction != null and curve_interaction.has_method("set_graph_model"):
		curve_interaction.set_graph_model(graph_model)
	if curve_renderer != null and curve_renderer.has_method("set_graph_model"):
		curve_renderer.set_graph_model(graph_model)


func _objective_id(objective: Resource) -> StringName:
	if objective == null:
		return &""
	var value = objective.get("objective_id")
	if value != null:
		return StringName(str(value))
	return StringName(str(objective))
