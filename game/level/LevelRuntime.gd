class_name LevelRuntime
extends Node

const CurveInteractionScript := preload("res://interaction/CurveInteraction.gd")
const CurveRendererScript := preload("res://render/CurveRenderer.gd")

signal level_loaded(spec: Resource)
signal level_complete(spec: Resource)

var level_spec: Resource = null
var graph_model: GraphModel = null
var curve_interaction: Node = null
var curve_renderer: Node = null

# The play area is the screen centre; the HUD lives in the corners. Every level's
# diagram is translated so its bounding box centres here on load, honouring the
# "middle is the play area" convention without hand-tuning each level's data.
const PLAY_CENTER := Vector2(640.0, 340.0)

var _is_complete := false
var _ruleset := "topology"
var _grammar := PhysicsGrammar.new()


func load_level(spec: Resource) -> bool:
	if spec == null or not spec.has_method("create_model_from_givens"):
		return false

	level_spec = spec
	_ruleset = String(spec.ruleset) if "ruleset" in spec else "topology"
	_install_model(spec.create_model_from_givens())
	_is_complete = false
	_ensure_children()
	_inject_model()
	level_loaded.emit(spec)
	evaluate_completeness()
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
	evaluate_completeness()
	return true


# A level is solved by physics rules only, never geometry (doc01 §4.4). Topology
# levels need a connected, dangling-free graph; QED levels additionally need every
# vertex to match the QED template with continuous fermion flow.
func evaluate_completeness() -> bool:
	if graph_model == null:
		return false

	var complete := _compute_complete()
	if complete and not _is_complete:
		_is_complete = true
		if curve_renderer != null and curve_renderer.has_method("play_completion"):
			curve_renderer.play_completion()
		level_complete.emit(level_spec)
	return _is_complete


func _compute_complete() -> bool:
	if _ruleset == "qed":
		return _grammar.validate(graph_model)["ok"]
	return graph_model.is_complete()


# Player-facing validation state for the HUD: { ok, stage, message, node_id }.
func validation_status() -> Dictionary:
	if graph_model == null:
		return {"ok": false, "stage": "integrity", "message": "尚未载入关卡", "node_id": &""}
	if _ruleset == "qed":
		return _grammar.validate(graph_model)
	if graph_model.is_complete():
		return {"ok": true, "stage": "ok", "message": "拓扑完整 · 图已连通，无悬挂半边", "node_id": &""}
	return {"ok": false, "stage": "integrity", "message": "把所有谱线连成一张连通的图", "node_id": &""}


func is_level_complete() -> bool:
	return _is_complete


# HUD-driven undo/redo (the same stack the keyboard shortcuts use).
func undo() -> bool:
	if curve_interaction != null and curve_interaction.has_method("undo"):
		return curve_interaction.undo()
	return false


func redo() -> bool:
	if curve_interaction != null and curve_interaction.has_method("redo"):
		return curve_interaction.redo()
	return false


func can_undo() -> bool:
	if curve_interaction != null and curve_interaction.get("undo_stack") != null:
		return curve_interaction.undo_stack.can_undo()
	return false


func can_redo() -> bool:
	if curve_interaction != null and curve_interaction.get("undo_stack") != null:
		return curve_interaction.undo_stack.can_redo()
	return false


func has_selection() -> bool:
	return curve_interaction != null and curve_interaction.has_method("has_selection") and curve_interaction.has_selection()


func delete_selected() -> bool:
	if curve_interaction != null and curve_interaction.has_method("delete_selected"):
		return curve_interaction.delete_selected()
	return false


# Tray verbs (Phase 2 interaction model): seed an endpoint with a particle swatch, or
# drop a fresh external endpoint onto the canvas. Both are undoable.
func seed_particle_at(world_pos: Vector2, particle_id: StringName) -> bool:
	if curve_interaction != null and curve_interaction.has_method("seed_particle_at"):
		return curve_interaction.seed_particle_at(world_pos, particle_id)
	return false


func add_endpoint_at(world_pos: Vector2) -> bool:
	if curve_interaction != null and curve_interaction.has_method("add_endpoint_at"):
		return curve_interaction.add_endpoint_at(world_pos)
	return false


func _on_selection_changed(node: RefCounted, edge: GraphEdge) -> void:
	if curve_renderer != null and curve_renderer.has_method("set_selection"):
		curve_renderer.set_selection(node, edge)


func _on_charge_progress(node: RefCounted, t: float) -> void:
	if curve_renderer != null and curve_renderer.has_method("set_charge"):
		curve_renderer.set_charge(node, t)


func _on_draw_arc_changed(active: bool, source_pos: Vector2, cursor_pos: Vector2, snapped: bool, particle_id: StringName) -> void:
	if curve_renderer != null and curve_renderer.has_method("set_draw_arc"):
		curve_renderer.set_draw_arc(active, source_pos, cursor_pos, snapped, particle_id)


# Number of committed player actions (for the HUD's step counter).
func step_count() -> int:
	if curve_interaction != null and curve_interaction.get("undo_stack") != null:
		return curve_interaction.undo_stack.undo_count()
	return 0


# Free (unplaced) half-edges, in stable edge order — the tray's placeable legs.
func free_half_edges() -> Array:
	var result: Array = []
	if graph_model == null:
		return result
	for edge_id in graph_model.edges:
		var edge: GraphEdge = graph_model.edges[edge_id]
		for half_edge in edge.half_edges():
			if not half_edge.has_endpoint():
				result.append(half_edge)
	return result


func vertex_count() -> int:
	var count := 0
	if graph_model == null:
		return count
	for node in graph_model.nodes.values():
		if node.kind == NodeKind.VERTEX:
			count += 1
	return count


func set_visual_layer_visible(is_visible: bool) -> void:
	_ensure_children()
	if curve_renderer is CanvasItem:
		curve_renderer.visible = is_visible


func set_interaction_enabled(is_enabled: bool) -> void:
	_ensure_children()
	if curve_interaction == null:
		return
	if is_enabled and curve_interaction.has_method("connect_input_router"):
		curve_interaction.connect_input_router()
	elif not is_enabled and curve_interaction.has_method("disconnect_input_router"):
		curve_interaction.disconnect_input_router()


func _install_model(model: GraphModel) -> void:
	_disconnect_graph_model()
	graph_model = model
	_recenter(graph_model)
	_connect_graph_model()


# Translate the whole graph so its node bounding box centres on PLAY_CENTER. This
# is a pure view-framing move done once on install: positions shift uniformly, so
# topology, fermion flow and conservation (which never read geometry) are untouched.
# Done by direct field writes, so no node_changed/edge_changed signals fire here.
func _recenter(model: GraphModel) -> void:
	if model == null or model.nodes.is_empty():
		return

	var min_p := Vector2.INF
	var max_p := -Vector2.INF
	for node in model.nodes.values():
		min_p = min_p.min(node.position)
		max_p = max_p.max(node.position)

	var offset := PLAY_CENTER - (min_p + max_p) * 0.5
	if offset.is_zero_approx():
		return

	for node in model.nodes.values():
		node.position += offset
	for edge: GraphEdge in model.edges.values():
		for point: CurvePoint in edge.curve_points:
			point.position += offset


func _connect_graph_model() -> void:
	if graph_model == null:
		return
	if not graph_model.node_changed.is_connected(_on_graph_changed):
		graph_model.node_changed.connect(_on_graph_changed)
	if not graph_model.edge_changed.is_connected(_on_graph_changed):
		graph_model.edge_changed.connect(_on_graph_changed)
	if not graph_model.topology_changed.is_connected(_on_graph_changed):
		graph_model.topology_changed.connect(_on_graph_changed)


func _disconnect_graph_model() -> void:
	if graph_model == null:
		return
	if graph_model.node_changed.is_connected(_on_graph_changed):
		graph_model.node_changed.disconnect(_on_graph_changed)
	if graph_model.edge_changed.is_connected(_on_graph_changed):
		graph_model.edge_changed.disconnect(_on_graph_changed)
	if graph_model.topology_changed.is_connected(_on_graph_changed):
		graph_model.topology_changed.disconnect(_on_graph_changed)


func _on_graph_changed(_arg = null) -> void:
	evaluate_completeness()


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

	if curve_interaction != null and curve_interaction.has_signal("selection_changed"):
		if not curve_interaction.selection_changed.is_connected(_on_selection_changed):
			curve_interaction.selection_changed.connect(_on_selection_changed)
	if curve_interaction != null and curve_interaction.has_signal("charge_progress"):
		if not curve_interaction.charge_progress.is_connected(_on_charge_progress):
			curve_interaction.charge_progress.connect(_on_charge_progress)
	if curve_interaction != null and curve_interaction.has_signal("draw_arc_changed"):
		if not curve_interaction.draw_arc_changed.is_connected(_on_draw_arc_changed):
			curve_interaction.draw_arc_changed.connect(_on_draw_arc_changed)


func _inject_model() -> void:
	_ensure_children()
	if curve_interaction != null and curve_interaction.has_method("set_graph_model"):
		curve_interaction.set_graph_model(graph_model)
	if curve_renderer != null and curve_renderer.has_method("set_graph_model"):
		curve_renderer.set_graph_model(graph_model)
