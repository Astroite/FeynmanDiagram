class_name GraphEdge
extends RefCounted

var id: StringName
var half_edge_a: HalfEdge
var half_edge_b: HalfEdge
var curve_points: Array[CurvePoint] = []
var particle_id: StringName = &"" # I1
var time_axis_dir: int = 0 # I1


func configure(initial_id: StringName) -> GraphEdge:
	id = initial_id
	half_edge_a = HalfEdge.new()
	half_edge_a.configure(StringName("%s:a" % String(id)), self)
	half_edge_b = HalfEdge.new()
	half_edge_b.configure(StringName("%s:b" % String(id)), self)
	return self


func half_edges() -> Array[HalfEdge]:
	return [half_edge_a, half_edge_b]
