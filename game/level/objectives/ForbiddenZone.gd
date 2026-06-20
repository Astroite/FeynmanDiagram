class_name ForbiddenZone
extends "res://level/objectives/SpatialObjective.gd"

const SpatialObjectiveScript := preload("res://level/objectives/SpatialObjective.gd")

@export var edge_ids: Array[StringName] = []
@export var center := Vector2.ZERO
@export var radius := 36.0


func is_met(model: GraphModel) -> bool:
	for polyline in SpatialObjectiveScript.edge_polylines(model, edge_ids):
		if _polyline_intersects_zone(polyline):
			return false
	return true


func segment_intersects_zone(start: Vector2, end: Vector2) -> bool:
	return SpatialObjectiveScript.segment_intersects_circle(start, end, center, radius)


func to_dict() -> Dictionary:
	var data := super.to_dict()
	data.merge({
		"edge_ids": _edge_ids_to_strings(),
		"center": CurvePoint._vector_to_dict(center),
		"radius": radius,
	}, true)
	return data


func _polyline_intersects_zone(polyline: PackedVector2Array) -> bool:
	if polyline.is_empty():
		return false
	if polyline.size() == 1:
		return polyline[0].distance_to(center) <= radius

	for index in range(polyline.size() - 1):
		if segment_intersects_zone(polyline[index], polyline[index + 1]):
			return true
	return false


func _edge_ids_to_strings() -> Array[String]:
	var result: Array[String] = []
	for edge_id in edge_ids:
		result.append(String(edge_id))
	return result
