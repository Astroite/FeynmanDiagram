class_name DeleteNodeCommand
extends Command

# Remove a node (an endpoint/vertex) and every edge attached to it; undo restores
# the node, then re-creates and reconnects those incident edges. Edge snapshot /
# restore is delegated to DeleteEdgeCommand so the two stay in sync.

const DeleteEdgeCommandScript := preload("res://interaction/command/DeleteEdgeCommand.gd")

var _model: GraphModel = null
var _node_data: Dictionary = {}
var _edges_data: Array = []


func configure(model: GraphModel, node: RefCounted) -> DeleteNodeCommand:
	label = &"delete_node"
	_model = model
	if node != null:
		_node_data = _serialize_node(node)
		_edges_data = _serialize_incident_edges(model, node)
	return self


func do() -> bool:
	if _model == null or _node_data.is_empty():
		return false
	# remove_node also removes every incident edge.
	return _model.remove_node(StringName(_node_data["id"]))


func undo() -> bool:
	if _model == null or _node_data.is_empty():
		return false
	_restore_node(_model, _node_data)
	for edge_data in _edges_data:
		DeleteEdgeCommandScript.restore_edge(_model, edge_data)
	return true


static func _serialize_node(node: RefCounted) -> Dictionary:
	var sockets: Array = []
	for socket in node.sockets:
		sockets.append({"id": String(socket.id), "offset": [socket.local_offset.x, socket.local_offset.y]})
	return {
		"id": String(node.id),
		"kind": node.kind,
		"position": [node.position.x, node.position.y],
		"particle_id": String(node.particle_id),
		"sockets": sockets,
	}


static func _serialize_incident_edges(model: GraphModel, node: RefCounted) -> Array:
	var result: Array = []
	for edge: GraphEdge in model.edges.values():
		if edge.half_edge_a.node == node or edge.half_edge_b.node == node:
			result.append(DeleteEdgeCommandScript.serialize_edge(edge))
	return result


static func _restore_node(model: GraphModel, data: Dictionary) -> void:
	var offsets: Array[Vector2] = []
	for socket_data in data["sockets"]:
		var offset: Array = socket_data["offset"]
		offsets.append(Vector2(float(offset[0]), float(offset[1])))
	var node = model.add_node(
		StringName(data["id"]),
		int(data["kind"]),
		Vector2(float(data["position"][0]), float(data["position"][1])),
		offsets
	)
	if node == null:
		return
	node.particle_id = StringName(str(data.get("particle_id", "")))
	var sockets: Array = data["sockets"]
	for index in range(sockets.size()):
		node.sockets[index].id = StringName(sockets[index]["id"])
