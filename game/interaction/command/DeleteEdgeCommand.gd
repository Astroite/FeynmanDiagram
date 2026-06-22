class_name DeleteEdgeCommand
extends Command

# Remove an edge (a line) from the graph; undo restores it with the same id,
# particle identity, curve geometry, and half-edge connections. The snapshot
# helpers are static so DeleteNodeCommand can reuse them for incident edges.

var _model: GraphModel = null
var _edge_data: Dictionary = {}


func configure(model: GraphModel, edge: GraphEdge) -> DeleteEdgeCommand:
	label = &"delete_edge"
	_model = model
	if edge != null:
		_edge_data = serialize_edge(edge)
	return self


func do() -> bool:
	if _model == null or _edge_data.is_empty():
		return false
	return _model.remove_edge(StringName(_edge_data["id"]))


func undo() -> bool:
	if _model == null or _edge_data.is_empty():
		return false
	return restore_edge(_model, _edge_data)


static func serialize_edge(edge: GraphEdge) -> Dictionary:
	return {
		"id": String(edge.id),
		"particle_id": String(edge.particle_id),
		"time_axis_dir": edge.time_axis_dir,
		"curve_points": _points_to_dicts(edge.curve_points),
		"half_edges": [_half_edge_to_dict(edge.half_edge_a), _half_edge_to_dict(edge.half_edge_b)],
	}


static func restore_edge(model: GraphModel, data: Dictionary) -> bool:
	var points: Array[CurvePoint] = []
	for point_data in data["curve_points"]:
		points.append(CurvePoint.from_dict(point_data))
	var edge := model.add_edge(StringName(data["id"]), points)
	if edge == null:
		return false
	edge.particle_id = StringName(data["particle_id"])
	edge.time_axis_dir = int(data["time_axis_dir"])
	var half_edges: Array = data["half_edges"]
	_apply_half_edge(model, edge.half_edge_a, half_edges[0])
	_apply_half_edge(model, edge.half_edge_b, half_edges[1])
	return true


static func _apply_half_edge(model: GraphModel, half_edge: HalfEdge, data: Dictionary) -> void:
	half_edge.particle_id = StringName(data["particle_id"])
	half_edge.fermion_flow = int(data["fermion_flow"])
	var node_id := StringName(data["node_id"])
	var socket_id := StringName(data["socket_id"])
	if String(node_id).is_empty() or String(socket_id).is_empty():
		return
	var node = model.get_node(node_id)
	if node == null:
		return
	var socket: Socket = node.get_socket(socket_id)
	if socket != null:
		model.connect_half_edge(half_edge, node, socket)


static func _half_edge_to_dict(half_edge: HalfEdge) -> Dictionary:
	return {
		"node_id": String(half_edge.node.id) if half_edge.node != null else "",
		"socket_id": String(half_edge.socket.id) if half_edge.socket != null else "",
		"particle_id": String(half_edge.particle_id),
		"fermion_flow": half_edge.fermion_flow,
	}


static func _points_to_dicts(points: Array) -> Array:
	var result: Array = []
	for point in points:
		result.append(point.to_dict())
	return result
