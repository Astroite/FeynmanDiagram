class_name GraphModel
extends RefCounted

const GraphNodeScript := preload("res://core/graph/GraphNode.gd")

signal node_changed(node)
signal edge_changed(edge)
signal topology_changed()

var nodes: Dictionary = {}
var edges: Dictionary = {}


func add_node(node_id: StringName, kind: int = NodeKind.VERTEX, position: Vector2 = Vector2.ZERO, socket_offsets: Array[Vector2] = [Vector2.ZERO]):
	if nodes.has(node_id):
		push_error("Graph node '%s' already exists." % String(node_id))
		return null

	var node = GraphNodeScript.new()
	node.configure(node_id, kind, position)
	for index in range(socket_offsets.size()):
		node.add_socket(_default_socket_id(index), socket_offsets[index])
	nodes[node_id] = node
	topology_changed.emit()
	return node


func remove_node(node_id: StringName) -> bool:
	var node = get_node(node_id)
	if node == null:
		return false

	var edge_ids_to_remove: Array[StringName] = []
	for socket in node.sockets:
		if socket.occupied_by != null and socket.occupied_by.edge != null:
			var edge_id: StringName = socket.occupied_by.edge.id
			if not edge_ids_to_remove.has(edge_id):
				edge_ids_to_remove.append(edge_id)

	for edge_id in edge_ids_to_remove:
		remove_edge(edge_id)

	nodes.erase(node_id)
	topology_changed.emit()
	return true


func add_edge(edge_id: StringName, curve_points: Array[CurvePoint] = []) -> GraphEdge:
	if edges.has(edge_id):
		push_error("Graph edge '%s' already exists." % String(edge_id))
		return null

	var edge := GraphEdge.new()
	edge.configure(edge_id)
	edge.curve_points = _duplicate_curve_points(curve_points)
	edges[edge_id] = edge
	topology_changed.emit()
	return edge


func remove_edge(edge_id: StringName) -> bool:
	var edge := get_edge(edge_id)
	if edge == null:
		return false

	_disconnect_half_edge(edge.half_edge_a, false)
	_disconnect_half_edge(edge.half_edge_b, false)
	edges.erase(edge_id)
	topology_changed.emit()
	return true


func connect_half_edge(half_edge: HalfEdge, node: RefCounted, socket: Socket) -> bool:
	if half_edge == null or node == null or socket == null:
		return false
	if half_edge.edge == null or not edges.has(half_edge.edge.id):
		return false
	if not nodes.has(node.id):
		return false
	if socket.owner_node != node:
		return false
	if socket.occupied_by != null and socket.occupied_by != half_edge:
		return false

	_disconnect_half_edge(half_edge, false)
	half_edge.node = node
	half_edge.socket = socket
	socket.occupied_by = half_edge
	edge_changed.emit(half_edge.edge)
	topology_changed.emit()
	return true


func disconnect_half_edge(half_edge: HalfEdge) -> bool:
	return _disconnect_half_edge(half_edge, true)


func move_node(node_or_id: Variant, position: Vector2) -> bool:
	var node = _resolve_node(node_or_id)
	if node == null:
		return false
	node.position = position
	node_changed.emit(node)
	return true


func set_curve_points(edge_or_id: Variant, curve_points: Array[CurvePoint]) -> bool:
	var edge := _resolve_edge(edge_or_id)
	if edge == null:
		return false
	edge.curve_points = _duplicate_curve_points(curve_points)
	edge_changed.emit(edge)
	return true


func get_node(node_id: StringName):
	return nodes.get(node_id, null)


func get_edge(edge_id: StringName) -> GraphEdge:
	return edges.get(edge_id, null)


# A graph is complete when it is connected and has no dangling half-edges — the real
# Feynman-graph requirement (doc01 §4.4). This is I0's only win condition; geometry never judges.
func is_complete() -> bool:
	return not has_dangling_half_edges() and is_graph_connected()


func has_dangling_half_edges() -> bool:
	for edge: GraphEdge in edges.values():
		for half_edge: HalfEdge in edge.half_edges():
			if not half_edge.has_endpoint():
				return true
	return false


func is_graph_connected() -> bool:
	if nodes.size() <= 1:
		return true

	var visited := {}
	var start: StringName = nodes.keys()[0]
	var stack: Array[StringName] = [start]
	visited[start] = true
	while not stack.is_empty():
		var current_node = nodes[stack.pop_back()]
		for edge: GraphEdge in edges.values():
			var a = edge.half_edge_a.node
			var b = edge.half_edge_b.node
			if a == null or b == null:
				continue
			var other = null
			if a == current_node:
				other = b
			elif b == current_node:
				other = a
			if other != null and not visited.has(other.id):
				visited[other.id] = true
				stack.append(other.id)
	return visited.size() == nodes.size()


func to_dict() -> Dictionary:
	var node_entries: Array[Dictionary] = []
	for node_id in _sorted_keys(nodes):
		var node = nodes[node_id]
		var socket_entries: Array[Dictionary] = []
		for socket in node.sockets:
			socket_entries.append({
				"id": String(socket.id),
				"local_offset": CurvePoint._vector_to_dict(socket.local_offset),
			})
		node_entries.append({
			"id": String(node.id),
			"kind": node.kind,
			"position": CurvePoint._vector_to_dict(node.position),
			"particle_id": String(node.particle_id),
			"sockets": socket_entries,
		})

	var edge_entries: Array[Dictionary] = []
	for edge_id in _sorted_keys(edges):
		var edge: GraphEdge = edges[edge_id]
		edge_entries.append({
			"id": String(edge.id),
			"particle_id": String(edge.particle_id),
			"time_axis_dir": edge.time_axis_dir,
			"curve_points": _curve_points_to_dicts(edge.curve_points),
			"half_edges": [
				_half_edge_to_dict(edge.half_edge_a),
				_half_edge_to_dict(edge.half_edge_b),
			],
		})

	return {
		"nodes": node_entries,
		"edges": edge_entries,
	}


static func from_dict(data: Dictionary) -> GraphModel:
	var model := GraphModel.new()

	for node_data in data.get("nodes", []):
		var socket_offsets: Array[Vector2] = []
		var socket_ids: Array[StringName] = []
		for socket_data in node_data.get("sockets", []):
			socket_ids.append(StringName(str(socket_data.get("id", ""))))
			socket_offsets.append(CurvePoint._vector_from_dict(socket_data.get("local_offset", {})))

		var node = model.add_node(
			StringName(str(node_data.get("id", ""))),
			int(node_data.get("kind", NodeKind.VERTEX)),
			CurvePoint._vector_from_dict(node_data.get("position", {})),
			socket_offsets
		)
		node.particle_id = StringName(str(node_data.get("particle_id", "")))
		for index in range(socket_ids.size()):
			node.sockets[index].id = socket_ids[index]

	for edge_data in data.get("edges", []):
		var edge := model.add_edge(
			StringName(str(edge_data.get("id", ""))),
			_curve_points_from_dicts(edge_data.get("curve_points", []))
		)
		edge.particle_id = StringName(str(edge_data.get("particle_id", "")))
		edge.time_axis_dir = int(edge_data.get("time_axis_dir", 0))

		var half_edge_data: Array = edge_data.get("half_edges", [])
		if half_edge_data.size() > 0:
			_apply_half_edge_data(model, edge.half_edge_a, half_edge_data[0])
		if half_edge_data.size() > 1:
			_apply_half_edge_data(model, edge.half_edge_b, half_edge_data[1])

	return model


func _disconnect_half_edge(half_edge: HalfEdge, emit_changes: bool) -> bool:
	if half_edge == null:
		return false

	var edge := half_edge.edge
	var changed := half_edge.node != null or half_edge.socket != null
	if half_edge.socket != null and half_edge.socket.occupied_by == half_edge:
		half_edge.socket.occupied_by = null
	half_edge.node = null
	half_edge.socket = null

	if emit_changes and changed:
		if edge != null:
			edge_changed.emit(edge)
		topology_changed.emit()
	return changed


func _resolve_node(node_or_id: Variant):
	if node_or_id is RefCounted and node_or_id.has_method("get_socket"):
		return node_or_id
	return get_node(StringName(str(node_or_id)))


func _resolve_edge(edge_or_id: Variant) -> GraphEdge:
	if edge_or_id is GraphEdge:
		return edge_or_id
	return get_edge(StringName(str(edge_or_id)))


func _duplicate_curve_points(curve_points: Array) -> Array[CurvePoint]:
	var copied: Array[CurvePoint] = []
	for point in curve_points:
		if point is CurvePoint:
			copied.append(point.duplicate_point())
		elif point is Dictionary:
			copied.append(CurvePoint.from_dict(point))
	return copied


func _curve_points_to_dicts(curve_points: Array[CurvePoint]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for point in curve_points:
		result.append(point.to_dict())
	return result


static func _curve_points_from_dicts(curve_points: Array) -> Array[CurvePoint]:
	var result: Array[CurvePoint] = []
	for point_data in curve_points:
		if point_data is CurvePoint:
			result.append(point_data.duplicate_point())
		elif point_data is Dictionary:
			result.append(CurvePoint.from_dict(point_data))
	return result


func _half_edge_to_dict(half_edge: HalfEdge) -> Dictionary:
	return {
		"id": String(half_edge.id),
		"node_id": String(half_edge.node.id) if half_edge.node != null else "",
		"socket_id": String(half_edge.socket.id) if half_edge.socket != null else "",
		"particle_id": String(half_edge.particle_id),
		"fermion_flow": half_edge.fermion_flow,
	}


static func _apply_half_edge_data(model: GraphModel, half_edge: HalfEdge, half_edge_data: Dictionary) -> void:
	half_edge.id = StringName(str(half_edge_data.get("id", half_edge.id)))
	half_edge.particle_id = StringName(str(half_edge_data.get("particle_id", "")))
	half_edge.fermion_flow = int(half_edge_data.get("fermion_flow", 0))

	var node_id := StringName(str(half_edge_data.get("node_id", "")))
	var socket_id := StringName(str(half_edge_data.get("socket_id", "")))
	if String(node_id).is_empty() or String(socket_id).is_empty():
		return

	var node = model.get_node(node_id)
	if node == null:
		return
	var socket: Socket = node.get_socket(socket_id)
	if socket == null:
		return
	model.connect_half_edge(half_edge, node, socket)


func _sorted_keys(source: Dictionary) -> Array:
	var keys := source.keys()
	keys.sort_custom(func(a, b): return String(a) < String(b))
	return keys


func _default_socket_id(index: int) -> StringName:
	return StringName("socket_%d" % index)
