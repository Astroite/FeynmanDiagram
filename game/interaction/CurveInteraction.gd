class_name CurveInteraction
extends Node

const BendEdgeCommandScript := preload("res://interaction/command/BendEdgeCommand.gd")
const ConnectHalfEdgeCommandScript := preload("res://interaction/command/ConnectHalfEdgeCommand.gd")
const MoveNodeCommandScript := preload("res://interaction/command/MoveNodeCommand.gd")

enum GestureKind { NONE, NODE_DRAG, EDGE_BEND, HALF_EDGE_DRAG }

const GESTURE_NONE := GestureKind.NONE
const GESTURE_NODE_DRAG := GestureKind.NODE_DRAG
const GESTURE_EDGE_BEND := GestureKind.EDGE_BEND
const GESTURE_HALF_EDGE_DRAG := GestureKind.HALF_EDGE_DRAG
const DEFAULT_NODE_HIT_RADIUS := 18.0
const DEFAULT_EDGE_HIT_RADIUS := 10.0
const DEFAULT_HALF_EDGE_HIT_RADIUS := 18.0
const DEFAULT_SNAP_RADIUS := 32.0

var graph_model: GraphModel = null
var undo_stack := UndoStack.new()
var node_hit_radius := DEFAULT_NODE_HIT_RADIUS
var edge_hit_radius := DEFAULT_EDGE_HIT_RADIUS
var half_edge_hit_radius := DEFAULT_HALF_EDGE_HIT_RADIUS
var snap_radius := DEFAULT_SNAP_RADIUS

var _input_router: Node = null
var _gesture_kind := GestureKind.NONE
var _active_node: RefCounted = null
var _active_edge: GraphEdge = null
var _active_half_edge: HalfEdge = null
var _press_pos := Vector2.ZERO
var _current_pos := Vector2.ZERO
var _node_start_pos := Vector2.ZERO
var _edge_start_points: Array[CurvePoint] = []


func _ready() -> void:
	connect_input_router()


func _exit_tree() -> void:
	disconnect_input_router()


func configure(model: GraphModel, router: Node = null) -> CurveInteraction:
	set_graph_model(model)
	if router != null:
		connect_input_router(router)
	return self


func set_graph_model(model: GraphModel) -> void:
	graph_model = model


func connect_input_router(router: Node = null) -> void:
	if router == null:
		router = get_node_or_null("/root/InputRouter")
	if router == null or router == _input_router:
		return

	disconnect_input_router()
	_input_router = router
	_connect_router_signal(&"pointer_down", Callable(self, "handle_pointer_down"))
	_connect_router_signal(&"pointer_moved", Callable(self, "handle_pointer_moved"))
	_connect_router_signal(&"pointer_up", Callable(self, "handle_pointer_up"))
	_connect_router_signal(&"undo", Callable(self, "undo"))
	_connect_router_signal(&"redo", Callable(self, "redo"))
	_connect_router_signal(&"cancel", Callable(self, "cancel_gesture"))


func disconnect_input_router() -> void:
	if _input_router == null:
		return

	_disconnect_router_signal(&"pointer_down", Callable(self, "handle_pointer_down"))
	_disconnect_router_signal(&"pointer_moved", Callable(self, "handle_pointer_moved"))
	_disconnect_router_signal(&"pointer_up", Callable(self, "handle_pointer_up"))
	_disconnect_router_signal(&"undo", Callable(self, "undo"))
	_disconnect_router_signal(&"redo", Callable(self, "redo"))
	_disconnect_router_signal(&"cancel", Callable(self, "cancel_gesture"))
	_input_router = null


func handle_pointer_down(world_pos: Vector2) -> void:
	cancel_gesture()
	_press_pos = world_pos
	_current_pos = world_pos

	_active_node = hit_test_node(world_pos)
	if _active_node != null:
		_gesture_kind = GestureKind.NODE_DRAG
		_node_start_pos = _active_node.position
		return

	_active_half_edge = hit_test_free_half_edge(world_pos)
	if _active_half_edge != null:
		_gesture_kind = GestureKind.HALF_EDGE_DRAG
		_active_edge = _active_half_edge.edge
		_edge_start_points = _duplicate_curve_points(_active_edge.curve_points)
		return

	_active_edge = hit_test_edge(world_pos)
	if _active_edge != null:
		_gesture_kind = GestureKind.EDGE_BEND
		_edge_start_points = _duplicate_curve_points(_active_edge.curve_points)


func handle_pointer_moved(world_pos: Vector2) -> void:
	_current_pos = world_pos


func handle_pointer_up(world_pos: Vector2) -> void:
	_current_pos = world_pos

	match _gesture_kind:
		GestureKind.NODE_DRAG:
			_finish_node_drag(world_pos)
		GestureKind.EDGE_BEND:
			_finish_edge_bend(world_pos)
		GestureKind.HALF_EDGE_DRAG:
			_finish_half_edge_drag(world_pos)

	cancel_gesture()


func undo() -> bool:
	return undo_stack.undo()


func redo() -> bool:
	return undo_stack.redo()


func cancel_gesture() -> void:
	_gesture_kind = GestureKind.NONE
	_active_node = null
	_active_edge = null
	_active_half_edge = null
	_edge_start_points.clear()


func active_gesture() -> int:
	return _gesture_kind


func classify_gesture_at(world_pos: Vector2) -> int:
	if hit_test_node(world_pos) != null:
		return GestureKind.NODE_DRAG
	if hit_test_free_half_edge(world_pos) != null:
		return GestureKind.HALF_EDGE_DRAG
	if hit_test_edge(world_pos) != null:
		return GestureKind.EDGE_BEND
	return GestureKind.NONE


func hit_test_node(world_pos: Vector2, radius: float = -1.0):
	if graph_model == null:
		return null

	var max_radius := node_hit_radius if radius < 0.0 else radius
	var best_node = null
	var best_distance := max_radius
	for node in graph_model.nodes.values():
		var distance := world_pos.distance_to(node.position)
		if distance <= best_distance:
			best_node = node
			best_distance = distance
	return best_node


func hit_test_free_half_edge(world_pos: Vector2, radius: float = -1.0) -> HalfEdge:
	if graph_model == null:
		return null

	var max_radius := half_edge_hit_radius if radius < 0.0 else radius
	var best_half_edge: HalfEdge = null
	var best_distance := max_radius
	for edge: GraphEdge in graph_model.edges.values():
		for half_edge: HalfEdge in edge.half_edges():
			if half_edge.has_endpoint():
				continue
			var endpoint_position := half_edge_endpoint_position(half_edge)
			var distance := world_pos.distance_to(endpoint_position)
			if distance <= best_distance:
				best_half_edge = half_edge
				best_distance = distance
	return best_half_edge


func hit_test_edge(world_pos: Vector2, radius: float = -1.0) -> GraphEdge:
	if graph_model == null:
		return null

	var max_radius := edge_hit_radius if radius < 0.0 else radius
	var best_edge: GraphEdge = null
	var best_distance := max_radius
	for edge: GraphEdge in graph_model.edges.values():
		var points := edge.curve_points
		if points.size() < 2:
			continue
		for index in range(points.size() - 1):
			var distance := _distance_to_segment(world_pos, points[index].position, points[index + 1].position)
			if distance <= best_distance:
				best_edge = edge
				best_distance = distance
	return best_edge


func find_snap_socket(world_pos: Vector2, radius: float = -1.0, moving_half_edge: HalfEdge = null) -> Dictionary:
	if graph_model == null:
		return {}

	var max_radius := snap_radius if radius < 0.0 else radius
	var best := {}
	var best_distance := max_radius
	for node in graph_model.nodes.values():
		for socket: Socket in node.sockets:
			if socket.occupied_by != null and socket.occupied_by != moving_half_edge:
				continue
			var distance := world_pos.distance_to(socket.world_position())
			if distance <= best_distance:
				best = {
					"node": node,
					"socket": socket,
					"distance": distance,
				}
				best_distance = distance
	return best


func half_edge_endpoint_position(half_edge: HalfEdge) -> Vector2:
	if half_edge == null:
		return Vector2.ZERO
	if half_edge.socket != null:
		return half_edge.socket.world_position()

	var edge := half_edge.edge
	if edge == null or edge.curve_points.is_empty():
		return Vector2.ZERO
	if half_edge == edge.half_edge_a:
		return edge.curve_points[0].position
	return edge.curve_points[edge.curve_points.size() - 1].position


func _finish_node_drag(world_pos: Vector2) -> void:
	if graph_model == null or _active_node == null:
		return

	var target_position := _node_start_pos + world_pos - _press_pos
	if target_position.is_equal_approx(_node_start_pos):
		return
	undo_stack.push(MoveNodeCommandScript.new().configure(graph_model, _active_node, target_position, _node_start_pos))


func _finish_edge_bend(world_pos: Vector2) -> void:
	if graph_model == null or _active_edge == null:
		return

	var after_points := _points_with_bend(_edge_start_points, world_pos)
	if _curve_points_equal(after_points, _edge_start_points):
		return
	undo_stack.push(BendEdgeCommandScript.new().configure(graph_model, _active_edge, after_points, _edge_start_points))


func _finish_half_edge_drag(world_pos: Vector2) -> void:
	if graph_model == null or _active_half_edge == null or _active_edge == null:
		return

	var snap := find_snap_socket(world_pos, snap_radius, _active_half_edge)
	if not snap.is_empty():
		undo_stack.push(ConnectHalfEdgeCommandScript.new().configure(graph_model, _active_half_edge, snap["node"], snap["socket"]))
		return

	var after_points := _points_with_half_edge_endpoint(_active_half_edge, _edge_start_points, world_pos)
	if _curve_points_equal(after_points, _edge_start_points):
		return
	undo_stack.push(BendEdgeCommandScript.new().configure(graph_model, _active_edge, after_points, _edge_start_points))


func _points_with_bend(points: Array[CurvePoint], bend_position: Vector2) -> Array[CurvePoint]:
	var copied := _duplicate_curve_points(points)
	if copied.is_empty():
		copied.append(CurvePoint.create(bend_position))
		return copied
	if copied.size() == 1:
		copied.append(CurvePoint.create(bend_position))
		return copied

	var segment_index := _nearest_segment_index(copied, _press_pos)
	copied.insert(segment_index + 1, CurvePoint.create(bend_position))
	return copied


func _points_with_half_edge_endpoint(half_edge: HalfEdge, points: Array[CurvePoint], endpoint_position: Vector2) -> Array[CurvePoint]:
	var copied := _duplicate_curve_points(points)
	if copied.is_empty():
		copied.append(CurvePoint.create(endpoint_position))
		return copied

	if half_edge == half_edge.edge.half_edge_a:
		copied[0].position = endpoint_position
	elif copied.size() == 1:
		copied.append(CurvePoint.create(endpoint_position))
	else:
		copied[copied.size() - 1].position = endpoint_position
	return copied


func _nearest_segment_index(points: Array[CurvePoint], world_pos: Vector2) -> int:
	var best_index := 0
	var best_distance := INF
	for index in range(max(points.size() - 1, 0)):
		var distance := _distance_to_segment(world_pos, points[index].position, points[index + 1].position)
		if distance < best_distance:
			best_index = index
			best_distance = distance
	return best_index


func _duplicate_curve_points(points: Array) -> Array[CurvePoint]:
	var copied: Array[CurvePoint] = []
	for point in points:
		if point is CurvePoint:
			copied.append(point.duplicate_point())
		elif point is Dictionary:
			copied.append(CurvePoint.from_dict(point))
	return copied


func _curve_points_equal(left: Array[CurvePoint], right: Array[CurvePoint]) -> bool:
	if left.size() != right.size():
		return false
	for index in range(left.size()):
		if not left[index].position.is_equal_approx(right[index].position):
			return false
		if not left[index].in_handle.is_equal_approx(right[index].in_handle):
			return false
		if not left[index].out_handle.is_equal_approx(right[index].out_handle):
			return false
	return true


func _distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	var segment_length_squared := segment.length_squared()
	if segment_length_squared <= 0.000001:
		return point.distance_to(start)

	var t: float = clamp((point - start).dot(segment) / segment_length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * t)


func _connect_router_signal(signal_name: StringName, callable: Callable) -> void:
	if _input_router.has_signal(signal_name) and not _input_router.is_connected(signal_name, callable):
		_input_router.connect(signal_name, callable)


func _disconnect_router_signal(signal_name: StringName, callable: Callable) -> void:
	if _input_router.has_signal(signal_name) and _input_router.is_connected(signal_name, callable):
		_input_router.disconnect(signal_name, callable)
