class_name HalfEdge
extends RefCounted

var id: StringName
var node: RefCounted = null
var socket: Socket = null
var edge: GraphEdge = null
var particle_id: StringName = &"" # I1
var fermion_flow: int = 0 # I1


func configure(initial_id: StringName, initial_edge: GraphEdge) -> HalfEdge:
	id = initial_id
	edge = initial_edge
	return self


func has_endpoint() -> bool:
	return node != null and socket != null
