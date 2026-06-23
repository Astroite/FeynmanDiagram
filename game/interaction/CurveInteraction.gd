class_name CurveInteraction
extends Node

const BendEdgeCommandScript := preload("res://interaction/command/BendEdgeCommand.gd")
const ConnectHalfEdgeCommandScript := preload("res://interaction/command/ConnectHalfEdgeCommand.gd")
const CreateEdgeCommandScript := preload("res://interaction/command/CreateEdgeCommand.gd")
const MoveNodeCommandScript := preload("res://interaction/command/MoveNodeCommand.gd")
const DeleteEdgeCommandScript := preload("res://interaction/command/DeleteEdgeCommand.gd")
const DeleteNodeCommandScript := preload("res://interaction/command/DeleteNodeCommand.gd")
const SeedParticleCommandScript := preload("res://interaction/command/SeedParticleCommand.gd")
const AddNodeCommandScript := preload("res://interaction/command/AddNodeCommand.gd")
const ReverseEdgeCommandScript := preload("res://interaction/command/ReverseEdgeCommand.gd")
const DeleteEdgesCommandScript := preload("res://interaction/command/DeleteEdgesCommand.gd")

# A press that releases within this distance of where it started is a tap (select),
# not a drag (move / bend / connect).
const TAP_DISTANCE := 6.0

# Hold this long on a seeded endpoint (without moving past TAP_DISTANCE) to charge
# the long-press and start pulling a new line out of it.
const CHARGE_TIME := 0.3

signal selection_changed(node: RefCounted, edge: GraphEdge)

# Long-press charge feedback: t in [0,1]; (null, 0.0) clears the ring.
signal charge_progress(node: RefCounted, t: float)

# Live draw-arc preview: the renderer draws a transient arc from source_pos to
# cursor_pos (snapped to a socket when `snapped`). `active` false clears it.
signal draw_arc_changed(active: bool, source_pos: Vector2, cursor_pos: Vector2, snapped: bool, particle_id: StringName)

# Live cut-stroke trail: the renderer draws the slash polyline while a right-button cut
# is in progress. `active` false clears it.
signal cut_stroke_changed(active: bool, points: PackedVector2Array)

enum GestureKind { NONE, NODE_DRAG, EDGE_BEND, HALF_EDGE_DRAG, LONG_PRESS_CHARGING, DRAW_ARC, EDGE_HANDLE_DRAG }

const GESTURE_NONE := GestureKind.NONE
const GESTURE_NODE_DRAG := GestureKind.NODE_DRAG
const GESTURE_EDGE_BEND := GestureKind.EDGE_BEND
const GESTURE_HALF_EDGE_DRAG := GestureKind.HALF_EDGE_DRAG
const GESTURE_LONG_PRESS_CHARGING := GestureKind.LONG_PRESS_CHARGING
const GESTURE_DRAW_ARC := GestureKind.DRAW_ARC
const GESTURE_EDGE_HANDLE_DRAG := GestureKind.EDGE_HANDLE_DRAG
const DEFAULT_NODE_HIT_RADIUS := 18.0
const DEFAULT_EDGE_HIT_RADIUS := 10.0
const DEFAULT_HALF_EDGE_HIT_RADIUS := 18.0
const DEFAULT_SNAP_RADIUS := 32.0

# A selected line shows two Bézier control handles (the start point's out-tangent and
# the end point's in-tangent). EDGE_HANDLE_LENGTH is the default display offset for a
# still-straight (zero) handle so it can be grabbed; the hit radius is how close the
# pointer must land on a handle dot to grab it. Kept in sync with CurveRenderer.
const EDGE_HANDLE_LENGTH := 48.0
const EDGE_HANDLE_HIT_RADIUS := 14.0

var graph_model: GraphModel = null
var undo_stack := UndoStack.new()
var selected_node: RefCounted = null
var selected_edge: GraphEdge = null
var node_hit_radius := DEFAULT_NODE_HIT_RADIUS
var edge_hit_radius := DEFAULT_EDGE_HIT_RADIUS
var half_edge_hit_radius := DEFAULT_HALF_EDGE_HIT_RADIUS
var snap_radius := DEFAULT_SNAP_RADIUS

var _input_router: Node = null
var _gesture_kind := GestureKind.NONE
var _active_node: RefCounted = null
var _active_edge: GraphEdge = null
var _active_half_edge: HalfEdge = null
var _draw_source: RefCounted = null
var _charge_elapsed := 0.0
var _charge_ready := false
var _press_pos := Vector2.ZERO
var _current_pos := Vector2.ZERO
var _node_start_pos := Vector2.ZERO
var _edge_start_points: Array[CurvePoint] = []
var _bend_point_index := -1
var _active_handle_which := -1
var _cutting := false
var _cut_points := PackedVector2Array()
var _cut_marked: Dictionary = {} # edge id -> GraphEdge crossed by the current stroke


func _ready() -> void:
	set_process(true)
	connect_input_router()


# Advance the long-press charge while the player holds still on a seeded endpoint.
func _process(delta: float) -> void:
	if _gesture_kind != GestureKind.LONG_PRESS_CHARGING:
		return
	_charge_elapsed += delta
	var t: float = clamp(_charge_elapsed / CHARGE_TIME, 0.0, 1.0)
	charge_progress.emit(_draw_source, t)
	if _charge_elapsed >= CHARGE_TIME:
		_begin_draw_arc()


func _exit_tree() -> void:
	disconnect_input_router()


func configure(model: GraphModel, router: Node = null) -> CurveInteraction:
	set_graph_model(model)
	if router != null:
		connect_input_router(router)
	return self


func set_graph_model(model: GraphModel) -> void:
	graph_model = model
	clear_selection()


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
	_connect_router_signal(&"cut_down", Callable(self, "handle_cut_down"))
	_connect_router_signal(&"cut_moved", Callable(self, "handle_cut_moved"))
	_connect_router_signal(&"cut_up", Callable(self, "handle_cut_up"))
	_connect_router_signal(&"undo", Callable(self, "undo"))
	_connect_router_signal(&"redo", Callable(self, "redo"))
	_connect_router_signal(&"cancel", Callable(self, "cancel_gesture"))
	_connect_router_signal(&"delete", Callable(self, "delete_selected"))


func disconnect_input_router() -> void:
	if _input_router == null:
		return

	_disconnect_router_signal(&"pointer_down", Callable(self, "handle_pointer_down"))
	_disconnect_router_signal(&"pointer_moved", Callable(self, "handle_pointer_moved"))
	_disconnect_router_signal(&"pointer_up", Callable(self, "handle_pointer_up"))
	_disconnect_router_signal(&"cut_down", Callable(self, "handle_cut_down"))
	_disconnect_router_signal(&"cut_moved", Callable(self, "handle_cut_moved"))
	_disconnect_router_signal(&"cut_up", Callable(self, "handle_cut_up"))
	_disconnect_router_signal(&"undo", Callable(self, "undo"))
	_disconnect_router_signal(&"redo", Callable(self, "redo"))
	_disconnect_router_signal(&"cancel", Callable(self, "cancel_gesture"))
	_disconnect_router_signal(&"delete", Callable(self, "delete_selected"))
	_input_router = null


# Start dragging a specific free half-edge programmatically (the tray placement
# verb): the HUD picks the half-edge, then drives the gesture with
# handle_pointer_moved / handle_pointer_up exactly like a world drag.
func begin_half_edge_placement(half_edge: HalfEdge, world_pos: Vector2) -> bool:
	_reset_gesture_state()
	if graph_model == null or half_edge == null or half_edge.edge == null:
		return false
	_press_pos = world_pos
	_current_pos = world_pos
	_active_half_edge = half_edge
	_active_edge = half_edge.edge
	_gesture_kind = GestureKind.HALF_EDGE_DRAG
	_edge_start_points = _duplicate_curve_points(_active_edge.curve_points)
	_apply_half_edge_preview(world_pos)
	return true


# Begin a gesture: classify what was grabbed and snapshot the pre-drag state.
func handle_pointer_down(world_pos: Vector2) -> void:
	_reset_gesture_state()
	if graph_model == null:
		return
	_press_pos = world_pos
	_current_pos = world_pos

	# A selected line's two Bézier handles take priority over everything: grabbing one
	# reshapes that end's tangent. Only the currently selected edge shows handles.
	if selected_edge != null:
		var which := _hit_test_edge_handle(selected_edge, world_pos)
		if which != -1:
			_active_edge = selected_edge
			_active_handle_which = which
			_gesture_kind = GestureKind.EDGE_HANDLE_DRAG
			_edge_start_points = _duplicate_curve_points(_active_edge.curve_points)
			return

	# A seeded endpoint can grow a new line: start charging a long-press. If the node
	# is also movable and the pointer moves past TAP_DISTANCE before the charge fills,
	# the gesture demotes to a reposition drag (see handle_pointer_moved).
	var seeded = _hit_test_seeded_node(world_pos)
	if seeded != null:
		_draw_source = seeded
		_active_node = seeded
		_node_start_pos = seeded.position
		_gesture_kind = GestureKind.LONG_PRESS_CHARGING
		_charge_elapsed = 0.0
		_charge_ready = false
		charge_progress.emit(seeded, 0.0)
		return

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
		_bend_point_index = _pick_or_insert_bend_point(_active_edge, world_pos)
		_apply_bend_preview(world_pos)


# Live 1:1 preview: mutate the model every move so the renderer follows the cursor.
# These intermediate states are NOT pushed to the undo stack.
func handle_pointer_moved(world_pos: Vector2) -> void:
	_current_pos = world_pos
	if graph_model == null:
		return

	match _gesture_kind:
		GestureKind.NODE_DRAG:
			_apply_node_preview(world_pos)
		GestureKind.EDGE_BEND:
			_apply_bend_preview(world_pos)
		GestureKind.EDGE_HANDLE_DRAG:
			_apply_handle_preview(world_pos)
		GestureKind.HALF_EDGE_DRAG:
			_apply_half_edge_preview(world_pos)
		GestureKind.LONG_PRESS_CHARGING:
			if world_pos.distance_to(_press_pos) > TAP_DISTANCE:
				_demote_charge(world_pos)
		GestureKind.DRAW_ARC:
			_apply_draw_preview(world_pos)


# End a gesture. A near-zero move is a tap → select what's under the cursor and
# discard any live preview; a real move commits the net change as ONE command.
func handle_pointer_up(world_pos: Vector2) -> void:
	_current_pos = world_pos

	if _gesture_kind == GestureKind.DRAW_ARC:
		charge_progress.emit(null, 0.0)
		_commit_draw_arc(world_pos)
		draw_arc_changed.emit(false, Vector2.ZERO, Vector2.ZERO, false, &"")
		_reset_gesture_state()
		return

	if world_pos.distance_to(_press_pos) < TAP_DISTANCE:
		charge_progress.emit(null, 0.0)
		# A tap that started on a handle keeps the line selected (the handle dot sits
		# off the line, so re-running _select_at would wrongly clear the selection).
		var was_handle := _gesture_kind == GestureKind.EDGE_HANDLE_DRAG
		_rewind_preview()
		_reset_gesture_state()
		if not was_handle:
			_select_at(world_pos)
		return

	match _gesture_kind:
		GestureKind.NODE_DRAG:
			_commit_node_drag(world_pos)
		GestureKind.EDGE_BEND:
			_commit_edge_bend()
		GestureKind.EDGE_HANDLE_DRAG:
			_commit_handle_drag()
		GestureKind.HALF_EDGE_DRAG:
			_commit_half_edge_drag(world_pos)

	charge_progress.emit(null, 0.0)
	_reset_gesture_state()


# Selection: a single click highlights the node/endpoint or line under the cursor;
# clicking empty space clears it. Nodes win over edges; anchors are selectable
# (unlike for dragging) so endpoints can be highlighted and deleted.
func _select_at(world_pos: Vector2) -> void:
	var node = _hit_test_any_node(world_pos)
	if node != null:
		select_node(node)
		return
	var edge := hit_test_edge(world_pos)
	if edge != null:
		select_edge(edge)
		return
	clear_selection()


func select_node(node: RefCounted) -> void:
	selected_node = node
	selected_edge = null
	selection_changed.emit(selected_node, selected_edge)


func select_edge(edge: GraphEdge) -> void:
	selected_node = null
	selected_edge = edge
	selection_changed.emit(selected_node, selected_edge)


func clear_selection() -> void:
	if selected_node == null and selected_edge == null:
		return
	selected_node = null
	selected_edge = null
	selection_changed.emit(null, null)


func has_selection() -> bool:
	return selected_node != null or selected_edge != null


# Delete the current selection (a line, or an endpoint plus its incident lines) as
# one undoable step, then clear the selection.
func delete_selected() -> bool:
	if graph_model == null:
		return false
	var command: Command = null
	if selected_edge != null:
		command = DeleteEdgeCommandScript.new().configure(graph_model, selected_edge)
	elif selected_node != null:
		command = DeleteNodeCommandScript.new().configure(graph_model, selected_node)
	if command == null:
		return false
	if not undo_stack.push(command):
		return false
	clear_selection()
	return true


# Reverse the selected fermion line's direction (one undoable step). The selection is
# kept — the same line stays highlighted with its arrow flipped.
func reverse_selected_edge() -> bool:
	if graph_model == null or selected_edge == null:
		return false
	return undo_stack.push(ReverseEdgeCommandScript.new().configure(graph_model, selected_edge))


# Only fermion lines carry an arrow, so only they can be reversed (photons have none).
func can_reverse_selection() -> bool:
	if selected_edge == null:
		return false
	var spec := ParticleSpec.get_spec(selected_edge.particle_id)
	return spec != null and spec.fermion_sign != 0


# Right-button cut stroke: begins on empty canvas (not on a node or line), then any line
# the stroke crosses is marked; release deletes them all as one undoable step.
func handle_cut_down(world_pos: Vector2) -> void:
	_cutting = false
	_cut_marked.clear()
	if graph_model == null:
		return
	if _hit_test_any_node(world_pos) != null or hit_test_edge(world_pos) != null:
		return
	_cutting = true
	_cut_points = PackedVector2Array([world_pos])
	cut_stroke_changed.emit(true, _cut_points)


func handle_cut_moved(world_pos: Vector2) -> void:
	if not _cutting:
		return
	_accumulate_cut(_cut_points[_cut_points.size() - 1], world_pos)
	_cut_points.append(world_pos)
	cut_stroke_changed.emit(true, _cut_points)


func handle_cut_up(world_pos: Vector2) -> void:
	if not _cutting:
		return
	_accumulate_cut(_cut_points[_cut_points.size() - 1], world_pos)
	_cutting = false
	cut_stroke_changed.emit(false, PackedVector2Array())
	if _cut_marked.is_empty():
		return
	var cut_selected: bool = selected_edge != null and _cut_marked.has(selected_edge.id)
	if undo_stack.push(DeleteEdgesCommandScript.new().configure(graph_model, _cut_marked.values())) and cut_selected:
		clear_selection()
	_cut_marked.clear()


# Mark every line whose polyline the stroke segment from->to crosses.
func _accumulate_cut(from: Vector2, to: Vector2) -> void:
	if graph_model == null:
		return
	for edge: GraphEdge in graph_model.edges.values():
		if _cut_marked.has(edge.id):
			continue
		var polyline := _edge_polyline(edge)
		for index in range(polyline.size() - 1):
			if Geometry2D.segment_intersects_segment(from, to, polyline[index], polyline[index + 1]) != null:
				_cut_marked[edge.id] = edge
				break


# An edge's polyline with connected endpoints pinned to their live socket positions
# (the stored curve point can be stale after a node move).
func _edge_polyline(edge: GraphEdge) -> PackedVector2Array:
	var result := PackedVector2Array()
	var points := edge.curve_points
	var last := points.size() - 1
	for index in range(points.size()):
		var position := points[index].position
		if index == 0 and edge.half_edge_a != null and edge.half_edge_a.socket != null:
			position = edge.half_edge_a.socket.world_position()
		elif index == last and edge.half_edge_b != null and edge.half_edge_b.socket != null:
			position = edge.half_edge_b.socket.world_position()
		result.append(position)
	return result


# Tray verb: drop a particle swatch onto an endpoint to station its seed there (the
# source identity a long-press line will inherit). Targets the nearest node — anchors
# included — within node_hit_radius; returns false if none is under the cursor.
func seed_particle_at(world_pos: Vector2, particle_id: StringName) -> bool:
	if graph_model == null:
		return false
	var node = _hit_test_any_node(world_pos)
	if node == null:
		return false
	return undo_stack.push(SeedParticleCommandScript.new().configure(graph_model, node, particle_id))


# Tray verb: drop the endpoint token onto empty canvas to add an external endpoint
# (an ANCHOR with one free socket) that can then be seeded and grown into a line.
func add_endpoint_at(world_pos: Vector2) -> bool:
	if graph_model == null:
		return false
	return undo_stack.push(AddNodeCommandScript.new().configure(graph_model, world_pos))


# Undo any live preview started on press (a nudged node, an inserted bend point)
# without committing it — used when a press turns out to be a tap.
func _rewind_preview() -> void:
	if graph_model == null:
		return
	match _gesture_kind:
		GestureKind.NODE_DRAG:
			if _active_node != null:
				graph_model.move_node(_active_node, _node_start_pos)
		GestureKind.EDGE_BEND, GestureKind.HALF_EDGE_DRAG, GestureKind.EDGE_HANDLE_DRAG:
			if _active_edge != null:
				graph_model.set_curve_points(_active_edge, _edge_start_points)


# Like hit_test_node but includes anchors (locked nodes), since selection — unlike
# dragging — may target a fixed endpoint.
func _hit_test_any_node(world_pos: Vector2):
	if graph_model == null:
		return null
	var best = null
	var best_distance := node_hit_radius
	for node in graph_model.nodes.values():
		var distance := world_pos.distance_to(node.position)
		if distance <= best_distance:
			best = node
			best_distance = distance
	return best


# Public node pick (anchors included) so the HUD's tray snap-hint targets exactly the
# node a seed/select would land on.
func pick_any_node(world_pos: Vector2):
	return _hit_test_any_node(world_pos)


func undo() -> bool:
	return undo_stack.undo()


func redo() -> bool:
	return undo_stack.redo()


# User-initiated cancel: rewind any live preview back to the pre-drag state.
func cancel_gesture() -> void:
	if graph_model != null:
		match _gesture_kind:
			GestureKind.NODE_DRAG:
				if _active_node != null:
					graph_model.move_node(_active_node, _node_start_pos)
			GestureKind.EDGE_BEND, GestureKind.HALF_EDGE_DRAG, GestureKind.EDGE_HANDLE_DRAG:
				if _active_edge != null:
					graph_model.set_curve_points(_active_edge, _edge_start_points)
	if _gesture_kind == GestureKind.LONG_PRESS_CHARGING or _gesture_kind == GestureKind.DRAW_ARC:
		charge_progress.emit(null, 0.0)
		draw_arc_changed.emit(false, Vector2.ZERO, Vector2.ZERO, false, &"")
	_reset_gesture_state()


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


# Anchors (and constrained nodes) are locked: they never win a node hit-test.
func hit_test_node(world_pos: Vector2, radius: float = -1.0):
	if graph_model == null:
		return null

	var max_radius := node_hit_radius if radius < 0.0 else radius
	var best_node = null
	var best_distance := max_radius
	for node in graph_model.nodes.values():
		if not _is_node_movable(node):
			continue
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


# A seeded endpoint (one carrying a particle_id) is the source a new line is pulled
# from. Includes anchors: external endpoints are locked against dragging but can
# still grow a line. Returns the nearest seeded node within node_hit_radius, else null.
func _hit_test_seeded_node(world_pos: Vector2):
	if graph_model == null:
		return null
	var best = null
	var best_distance := node_hit_radius
	for node in graph_model.nodes.values():
		if String(node.particle_id).is_empty():
			continue
		if _first_free_socket(node) == null:
			continue
		var distance := world_pos.distance_to(node.position)
		if distance <= best_distance:
			best = node
			best_distance = distance
	return best


# Charge filled: switch from holding still to actively dragging the new line out.
func _begin_draw_arc() -> void:
	_gesture_kind = GestureKind.DRAW_ARC
	_charge_ready = true
	charge_progress.emit(_draw_source, 1.0)
	_apply_draw_preview(_current_pos)


# The pointer moved before the charge filled: abandon the long-press. If the seeded
# node is also movable, fall through to a reposition drag; otherwise the gesture ends.
func _demote_charge(world_pos: Vector2) -> void:
	charge_progress.emit(null, 0.0)
	var node = _draw_source
	_draw_source = null
	_charge_elapsed = 0.0
	_charge_ready = false
	if _is_node_movable(node):
		_active_node = node
		_gesture_kind = GestureKind.NODE_DRAG
		_apply_node_preview(world_pos)
	else:
		_active_node = null
		_gesture_kind = GestureKind.NONE


# Renderer-only preview of the line being pulled: from the source socket to the
# cursor, snapping to the nearest free socket on another node. The model is NOT
# mutated here — no temp edge exists until release commits one.
func _apply_draw_preview(world_pos: Vector2) -> void:
	if _draw_source == null:
		return
	var source_socket := _first_free_socket(_draw_source)
	var source_pos: Vector2 = source_socket.world_position() if source_socket != null else _draw_source.position
	var snap := find_snap_socket(world_pos, snap_radius)
	var snapped: bool = not snap.is_empty() and snap["node"] != _draw_source
	var cursor: Vector2 = snap["socket"].world_position() if snapped else world_pos
	draw_arc_changed.emit(true, source_pos, cursor, snapped, _draw_source.particle_id)


# Release: if the cursor is snapped to a free socket on another node, create the new
# line (source -> target) as one undoable CreateEdgeCommand. Otherwise do nothing.
func _commit_draw_arc(world_pos: Vector2) -> void:
	if graph_model == null or _draw_source == null:
		return
	var source_socket := _first_free_socket(_draw_source)
	if source_socket == null:
		return
	var snap := find_snap_socket(world_pos, snap_radius)
	if snap.is_empty() or snap["node"] == _draw_source:
		return
	undo_stack.push(CreateEdgeCommandScript.new().configure(
		graph_model,
		_draw_source.particle_id,
		_draw_source,
		source_socket,
		snap["node"],
		snap["socket"]
	))


# First socket on this node with no half-edge attached, else null.
func _first_free_socket(node) -> Socket:
	if node == null:
		return null
	for socket: Socket in node.sockets:
		if socket.occupied_by == null:
			return socket
	return null


func _apply_node_preview(world_pos: Vector2) -> void:
	if _active_node == null:
		return
	graph_model.move_node(_active_node, _node_start_pos + world_pos - _press_pos)


func _apply_bend_preview(world_pos: Vector2) -> void:
	if _active_edge == null or _bend_point_index < 0:
		return
	var points := _duplicate_curve_points(_active_edge.curve_points)
	if _bend_point_index >= points.size():
		return
	points[_bend_point_index].position = world_pos
	_smooth_point_handles(points, _bend_point_index)
	graph_model.set_curve_points(_active_edge, points)


func _apply_half_edge_preview(world_pos: Vector2) -> void:
	if _active_half_edge == null or _active_edge == null:
		return
	graph_model.set_curve_points(_active_edge, _half_edge_points(world_pos))


func _commit_node_drag(world_pos: Vector2) -> void:
	if graph_model == null or _active_node == null:
		return
	var final_position := _node_start_pos + world_pos - _press_pos
	graph_model.move_node(_active_node, _node_start_pos) # rewind live preview
	if final_position.is_equal_approx(_node_start_pos):
		return
	undo_stack.push(MoveNodeCommandScript.new().configure(graph_model, _active_node, final_position, _node_start_pos))


func _commit_edge_bend() -> void:
	if graph_model == null or _active_edge == null:
		return
	var final_points := _duplicate_curve_points(_active_edge.curve_points)
	graph_model.set_curve_points(_active_edge, _edge_start_points) # rewind (removes inserted point)
	if _curve_points_equal(final_points, _edge_start_points):
		return
	undo_stack.push(BendEdgeCommandScript.new().configure(graph_model, _active_edge, final_points, _edge_start_points))


# The two Bézier control handles of a selected line: which 0 = the start point's
# out-tangent, which 1 = the end point's in-tangent. The handle's anchor is the line's
# endpoint position (socket-aware); its display tip is anchor + handle, or — when the
# handle is still zero — a default offset along the chord so it can be grabbed.
func edge_handle_anchor(edge: GraphEdge, which: int) -> Vector2:
	var points := edge.curve_points
	if points.size() < 2:
		return Vector2.ZERO
	if which == 0:
		var start: CurvePoint = points[0]
		if edge.half_edge_a != null and edge.half_edge_a.socket != null:
			return edge.half_edge_a.socket.world_position()
		return start.position
	var last: CurvePoint = points[points.size() - 1]
	if edge.half_edge_b != null and edge.half_edge_b.socket != null:
		return edge.half_edge_b.socket.world_position()
	return last.position


func edge_handle_tip(edge: GraphEdge, which: int) -> Vector2:
	var points := edge.curve_points
	if points.size() < 2:
		return Vector2.ZERO
	var anchor := edge_handle_anchor(edge, which)
	var handle: Vector2 = points[0].out_handle if which == 0 else points[points.size() - 1].in_handle
	if handle.length() > 0.001:
		return anchor + handle
	# A straight (zero) handle gets a default tip pointing along the chord toward the
	# other end, so the player has something to grab. Length is a third of the chord,
	# capped, so the two handles never cross on a short line.
	var other := edge_handle_anchor(edge, 1 - which)
	var direction := (other - anchor)
	if direction.length() <= 0.001:
		return anchor
	var length: float = min(direction.length() / 3.0, EDGE_HANDLE_LENGTH)
	return anchor + direction.normalized() * length


# Which handle (0 or 1) the pointer grabbed on the selected edge, or -1 if neither.
func _hit_test_edge_handle(edge: GraphEdge, world_pos: Vector2) -> int:
	if edge == null or edge.curve_points.size() < 2:
		return -1
	var best := -1
	var best_distance := EDGE_HANDLE_HIT_RADIUS
	for which in range(2):
		var distance := world_pos.distance_to(edge_handle_tip(edge, which))
		if distance <= best_distance:
			best = which
			best_distance = distance
	return best


# Live preview: set the dragged handle so its tip follows the cursor. Handle 0 is the
# start out-tangent (anchor -> cursor); handle 1 the end in-tangent (anchor -> cursor).
func _apply_handle_preview(world_pos: Vector2) -> void:
	if _active_edge == null or _active_handle_which < 0:
		return
	graph_model.set_curve_points(_active_edge, _handle_points(world_pos))


func _commit_handle_drag() -> void:
	if graph_model == null or _active_edge == null or _active_handle_which < 0:
		return
	var final_points := _duplicate_curve_points(_active_edge.curve_points)
	graph_model.set_curve_points(_active_edge, _edge_start_points) # rewind live preview
	if _curve_points_equal(final_points, _edge_start_points):
		return
	undo_stack.push(BendEdgeCommandScript.new().configure(graph_model, _active_edge, final_points, _edge_start_points))


# The edge's points with the active handle's tangent set so its tip sits at world_pos.
func _handle_points(world_pos: Vector2) -> Array[CurvePoint]:
	var points := _duplicate_curve_points(_edge_start_points)
	if points.size() < 2:
		return points
	var index := 0 if _active_handle_which == 0 else points.size() - 1
	var anchor := edge_handle_anchor(_active_edge, _active_handle_which)
	var handle := world_pos - anchor
	if _active_handle_which == 0:
		points[index].out_handle = handle
	else:
		points[index].in_handle = handle
	return points


func _commit_half_edge_drag(world_pos: Vector2) -> void:
	if graph_model == null or _active_half_edge == null or _active_edge == null:
		return

	var snap := find_snap_socket(world_pos, snap_radius, _active_half_edge)
	graph_model.set_curve_points(_active_edge, _edge_start_points) # rewind live preview
	if not snap.is_empty():
		undo_stack.push(ConnectHalfEdgeCommandScript.new().configure(graph_model, _active_half_edge, snap["node"], snap["socket"]))
		return

	var final_points := _half_edge_points(world_pos)
	if _curve_points_equal(final_points, _edge_start_points):
		return
	undo_stack.push(BendEdgeCommandScript.new().configure(graph_model, _active_edge, final_points, _edge_start_points))


# Build the edge's points with the dragged free endpoint moved to world_pos.
func _half_edge_points(world_pos: Vector2) -> Array[CurvePoint]:
	var points := _duplicate_curve_points(_edge_start_points)
	if points.is_empty():
		points.append(CurvePoint.create(world_pos))
	elif _active_half_edge == _active_edge.half_edge_a:
		points[0].position = world_pos
	else:
		points[points.size() - 1].position = world_pos
	return points


# Reuse an existing interior control point under the cursor, else insert one in the
# nearest segment. Returns the index of the point this gesture will move.
func _pick_or_insert_bend_point(edge: GraphEdge, world_pos: Vector2) -> int:
	var points := edge.curve_points
	var best_index := -1
	var best_distance := node_hit_radius
	for index in range(1, max(points.size() - 1, 1)):
		var distance := world_pos.distance_to(points[index].position)
		if distance <= best_distance:
			best_index = index
			best_distance = distance
	if best_index != -1:
		return best_index

	if points.size() < 2:
		var appended := _duplicate_curve_points(points)
		appended.append(CurvePoint.create(world_pos))
		graph_model.set_curve_points(edge, appended)
		return appended.size() - 1

	var segment_index := _nearest_segment_index(points, world_pos)
	var inserted := _duplicate_curve_points(points)
	inserted.insert(segment_index + 1, CurvePoint.create(world_pos))
	graph_model.set_curve_points(edge, inserted)
	return segment_index + 1


# Give an interior point a smooth Catmull-Rom-style tangent so the curve bends, not kinks.
func _smooth_point_handles(points: Array[CurvePoint], index: int) -> void:
	if index <= 0 or index >= points.size() - 1:
		return
	var prev := points[index - 1].position
	var next := points[index + 1].position
	var here := points[index].position
	var tangent := next - prev
	if tangent.length() <= 0.0001:
		points[index].in_handle = Vector2.ZERO
		points[index].out_handle = Vector2.ZERO
		return
	var direction := tangent.normalized()
	var handle_length: float = min(here.distance_to(prev), here.distance_to(next)) / 3.0
	points[index].in_handle = -direction * handle_length
	points[index].out_handle = direction * handle_length


func _is_node_movable(node) -> bool:
	if node == null:
		return false
	return node.kind != NodeKind.ANCHOR


func _nearest_segment_index(points: Array[CurvePoint], world_pos: Vector2) -> int:
	var best_index := 0
	var best_distance := INF
	for index in range(max(points.size() - 1, 0)):
		var distance := _distance_to_segment(world_pos, points[index].position, points[index + 1].position)
		if distance < best_distance:
			best_index = index
			best_distance = distance
	return best_index


func _reset_gesture_state() -> void:
	_gesture_kind = GestureKind.NONE
	_active_node = null
	_active_edge = null
	_active_half_edge = null
	_draw_source = null
	_charge_elapsed = 0.0
	_charge_ready = false
	_bend_point_index = -1
	_active_handle_which = -1
	_edge_start_points.clear()


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
