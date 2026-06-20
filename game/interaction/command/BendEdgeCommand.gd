class_name BendEdgeCommand
extends Command

var _model: GraphModel = null
var _edge: GraphEdge = null
var _before_points: Array[CurvePoint] = []
var _after_points: Array[CurvePoint] = []

func configure(model: GraphModel, edge: GraphEdge, after_points: Array, before_points: Variant = null):
	label = &"bend_edge"
	_model = model
	_edge = edge
	_before_points = _duplicate_points(before_points if before_points is Array else edge.curve_points if edge != null else [])
	_after_points = _duplicate_points(after_points)
	return self


func do() -> bool:
	if _model == null or _edge == null:
		return false
	return _model.set_curve_points(_edge, _after_points)


func undo() -> bool:
	if _model == null or _edge == null:
		return false
	return _model.set_curve_points(_edge, _before_points)


static func _duplicate_points(points: Array) -> Array[CurvePoint]:
	var copied: Array[CurvePoint] = []
	for point in points:
		if point is CurvePoint:
			copied.append(point.duplicate_point())
		elif point is Dictionary:
			copied.append(CurvePoint.from_dict(point))
	return copied
