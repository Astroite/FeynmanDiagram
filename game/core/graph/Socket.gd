class_name Socket
extends RefCounted

var id: StringName
var owner_node: RefCounted = null
var local_offset: Vector2 = Vector2.ZERO
var occupied_by: HalfEdge = null


func configure(initial_id: StringName, initial_owner_node: RefCounted, initial_local_offset: Vector2) -> Socket:
	id = initial_id
	owner_node = initial_owner_node
	local_offset = initial_local_offset
	return self


func world_position() -> Vector2:
	if owner_node == null:
		return local_offset
	return owner_node.position + local_offset
