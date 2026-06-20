class_name FixedAnchor
extends "res://level/objectives/SpatialObjective.gd"

@export var node_id: StringName = &""
@export var position := Vector2.ZERO
@export var tolerance := 0.5
@export var edge_id: StringName = &""
@export_range(-1, 1, 1) var half_edge_index := -1
@export var socket_id: StringName = &""


func is_met(model: GraphModel) -> bool:
	if model == null:
		return false

	var node = model.get_node(node_id)
	if node == null or node.position.distance_to(position) > tolerance:
		return false
	if String(edge_id).is_empty():
		return true

	var edge := model.get_edge(edge_id)
	if edge == null:
		return false

	var half_edge := _half_edge_for(edge)
	if half_edge == null or half_edge.node != node:
		return false
	if not String(socket_id).is_empty() and (half_edge.socket == null or half_edge.socket.id != socket_id):
		return false
	return true


func to_dict() -> Dictionary:
	var data := super.to_dict()
	data.merge({
		"node_id": String(node_id),
		"position": CurvePoint._vector_to_dict(position),
		"tolerance": tolerance,
		"edge_id": String(edge_id),
		"half_edge_index": half_edge_index,
		"socket_id": String(socket_id),
	}, true)
	return data


func _half_edge_for(edge: GraphEdge) -> HalfEdge:
	if half_edge_index == 0:
		return edge.half_edge_a
	if half_edge_index == 1:
		return edge.half_edge_b
	return null
