class_name ConnectHalfEdgeCommand
extends Command

var _model: GraphModel = null
var _half_edge: HalfEdge = null
var _target_node: RefCounted = null
var _target_socket: Socket = null
var _previous_node: RefCounted = null
var _previous_socket: Socket = null

func configure(model: GraphModel, half_edge: HalfEdge, target_node: RefCounted, target_socket: Socket):
	label = &"connect_half_edge"
	_model = model
	_half_edge = half_edge
	_target_node = target_node
	_target_socket = target_socket
	if half_edge != null:
		_previous_node = half_edge.node
		_previous_socket = half_edge.socket
	return self


func do() -> bool:
	if _model == null or _half_edge == null or _target_node == null or _target_socket == null:
		return false
	if _half_edge.node == _target_node and _half_edge.socket == _target_socket:
		return true
	return _model.connect_half_edge(_half_edge, _target_node, _target_socket)


func undo() -> bool:
	if _model == null or _half_edge == null:
		return false
	if _previous_node == _target_node and _previous_socket == _target_socket:
		return true

	_model.disconnect_half_edge(_half_edge)
	if _previous_node != null and _previous_socket != null:
		return _model.connect_half_edge(_half_edge, _previous_node, _previous_socket)
	return true
