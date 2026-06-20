class_name ObservationRing
extends "res://level/objectives/SpatialObjective.gd"

const SpatialObjectiveScript := preload("res://level/objectives/SpatialObjective.gd")

@export var edge_ids: Array[StringName] = []
@export var center := Vector2.ZERO
@export var radius := 48.0
@export var thickness := 18.0


func is_met(model: GraphModel) -> bool:
	for polyline in SpatialObjectiveScript.edge_polylines(model, edge_ids):
		if _polyline_intersects_ring(polyline):
			return true
	return false


func point_in_ring(point: Vector2) -> bool:
	return SpatialObjectiveScript.is_point_in_ring(point, center, radius, thickness)


func to_dict() -> Dictionary:
	var data := super.to_dict()
	data.merge({
		"edge_ids": _edge_ids_to_strings(),
		"center": CurvePoint._vector_to_dict(center),
		"radius": radius,
		"thickness": thickness,
	}, true)
	return data


func _polyline_intersects_ring(polyline: PackedVector2Array) -> bool:
	if polyline.is_empty():
		return false
	if polyline.size() == 1:
		return point_in_ring(polyline[0])

	for index in range(polyline.size() - 1):
		if SpatialObjectiveScript.segment_intersects_ring(polyline[index], polyline[index + 1], center, radius, thickness):
			return true
	return false


func _edge_ids_to_strings() -> Array[String]:
	var result: Array[String] = []
	for edge_id in edge_ids:
		result.append(String(edge_id))
	return result
