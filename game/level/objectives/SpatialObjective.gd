class_name SpatialObjective
extends Resource

const DEFAULT_BAKE_INTERVAL := 8.0

@export var objective_id: StringName = &""


func is_met(_model: GraphModel) -> bool:
	return false


func to_dict() -> Dictionary:
	return {
		"type": get_script().resource_path.get_file().get_basename(),
		"objective_id": String(objective_id),
	}


static func edge_polylines(model: GraphModel, edge_ids: Array[StringName]) -> Array[PackedVector2Array]:
	var polylines: Array[PackedVector2Array] = []
	if model == null:
		return polylines

	var ids := edge_ids
	if ids.is_empty():
		ids = []
		for edge_id in model.edges.keys():
			ids.append(edge_id)

	for edge_id: StringName in ids:
		var edge := model.get_edge(edge_id)
		if edge == null:
			continue
		polylines.append(curve_points_to_polyline(edge.curve_points))
	return polylines


static func curve_points_to_polyline(points: Array) -> PackedVector2Array:
	if points.is_empty():
		return PackedVector2Array()
	if points.size() == 1:
		return PackedVector2Array([points[0].position])

	var curve := Curve2D.new()
	curve.bake_interval = DEFAULT_BAKE_INTERVAL
	for point: CurvePoint in points:
		curve.add_point(point.position, point.in_handle, point.out_handle)
	return curve.get_baked_points()


static func distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	var segment_length_squared := segment.length_squared()
	if segment_length_squared <= 0.000001:
		return point.distance_to(start)

	var t: float = clamp((point - start).dot(segment) / segment_length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * t)


static func is_point_in_ring(point: Vector2, center: Vector2, radius: float, thickness: float) -> bool:
	var half_thickness := thickness * 0.5
	var distance := point.distance_to(center)
	return distance >= max(radius - half_thickness, 0.0) and distance <= radius + half_thickness


static func segment_intersects_ring(start: Vector2, end: Vector2, center: Vector2, radius: float, thickness: float) -> bool:
	var half_thickness := thickness * 0.5
	var inner_radius: float = max(radius - half_thickness, 0.0)
	var outer_radius := radius + half_thickness
	var closest_distance := distance_to_segment(center, start, end)
	var farthest_endpoint_distance: float = max(center.distance_to(start), center.distance_to(end))
	return closest_distance <= outer_radius and farthest_endpoint_distance >= inner_radius


static func segment_intersects_circle(start: Vector2, end: Vector2, center: Vector2, radius: float) -> bool:
	return distance_to_segment(center, start, end) <= radius
