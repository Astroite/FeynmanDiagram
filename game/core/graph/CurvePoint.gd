class_name CurvePoint
extends RefCounted

var position: Vector2
var in_handle: Vector2 = Vector2.ZERO
var out_handle: Vector2 = Vector2.ZERO


static func create(initial_position: Vector2 = Vector2.ZERO, initial_in_handle: Vector2 = Vector2.ZERO, initial_out_handle: Vector2 = Vector2.ZERO) -> CurvePoint:
	var point := CurvePoint.new()
	point.position = initial_position
	point.in_handle = initial_in_handle
	point.out_handle = initial_out_handle
	return point


func duplicate_point() -> CurvePoint:
	return CurvePoint.create(position, in_handle, out_handle)


func to_dict() -> Dictionary:
	return {
		"position": _vector_to_dict(position),
		"in_handle": _vector_to_dict(in_handle),
		"out_handle": _vector_to_dict(out_handle),
	}


static func from_dict(data: Dictionary) -> CurvePoint:
	return CurvePoint.create(
		_vector_from_dict(data.get("position", {})),
		_vector_from_dict(data.get("in_handle", {})),
		_vector_from_dict(data.get("out_handle", {}))
	)


static func _vector_to_dict(value: Vector2) -> Dictionary:
	return {
		"x": value.x,
		"y": value.y,
	}


static func _vector_from_dict(data: Variant) -> Vector2:
	if data is Vector2:
		return data
	if data is Array and data.size() >= 2:
		return Vector2(float(data[0]), float(data[1]))
	if data is Dictionary:
		return Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
	return Vector2.ZERO
