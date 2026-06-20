class_name ConnectHalfEdgeCommand
extends Command

var _model: GraphModel = null
var _half_edge: HalfEdge = null
var _target_node: RefCounted = null
var _target_socket: Socket = null
var _previous_node: RefCounted = null
var _previous_socket: Socket = null
var _before_points: Array[CurvePoint] = []
var _after_points: Array[CurvePoint] = []

func configure(model: GraphModel, half_edge: HalfEdge, target_node: RefCounted, target_socket: Socket):
	label = &"connect_half_edge"
	_model = model
	_half_edge = half_edge
	_target_node = target_node
	_target_socket = target_socket
	if half_edge != null:
		_previous_node = half_edge.node
		_previous_socket = half_edge.socket
		var edge := half_edge.edge
		if edge != null:
			# On connect, the dragged endpoint snaps onto the socket so the curve
			# meets the vertex. Snapshot before/after so undo restores both the
			# connection and the endpoint geometry as one step.
			_before_points = _duplicate_points(edge.curve_points)
			_after_points = _duplicate_points(edge.curve_points)
			if target_socket != null and not _after_points.is_empty():
				var endpoint_index := 0 if half_edge == edge.half_edge_a else _after_points.size() - 1
				_after_points[endpoint_index].position = target_socket.world_position()
	return self


func do() -> bool:
	if _model == null or _half_edge == null or _target_node == null or _target_socket == null:
		return false

	var connected := true
	if not (_half_edge.node == _target_node and _half_edge.socket == _target_socket):
		connected = _model.connect_half_edge(_half_edge, _target_node, _target_socket)
	if connected and _half_edge.edge != null and not _after_points.is_empty():
		_model.set_curve_points(_half_edge.edge, _after_points)
	return connected


func undo() -> bool:
	if _model == null or _half_edge == null:
		return false

	_model.disconnect_half_edge(_half_edge)
	if _previous_node != null and _previous_socket != null:
		_model.connect_half_edge(_half_edge, _previous_node, _previous_socket)
	if _half_edge.edge != null and not _before_points.is_empty():
		_model.set_curve_points(_half_edge.edge, _before_points)
	return true


static func _duplicate_points(points: Array) -> Array[CurvePoint]:
	var copied: Array[CurvePoint] = []
	for point in points:
		if point is CurvePoint:
			copied.append(point.duplicate_point())
		elif point is Dictionary:
			copied.append(CurvePoint.from_dict(point))
	return copied
