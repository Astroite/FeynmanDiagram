# Loaded by path because Godot already has a native GraphNode class.
extends RefCounted

var id: StringName
var kind: int = NodeKind.VERTEX
var position: Vector2 = Vector2.ZERO
var movement_constraint: Variant = null
var sockets: Array[Socket] = []


func configure(initial_id: StringName, initial_kind: int, initial_position: Vector2):
	id = initial_id
	kind = initial_kind
	position = initial_position
	return self


func add_socket(socket_id: StringName, local_offset: Vector2 = Vector2.ZERO) -> Socket:
	var socket := Socket.new()
	socket.configure(socket_id, self, local_offset)
	sockets.append(socket)
	return socket


func get_socket(socket_id: StringName) -> Socket:
	for socket in sockets:
		if socket.id == socket_id:
			return socket
	return null


func socket_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for socket in sockets:
		ids.append(socket.id)
	return ids
