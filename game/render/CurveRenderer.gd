class_name CurveRenderer
extends Node2D

const GlowLineShader := preload("res://render/shaders/glow_line.gdshader")

const DEFAULT_LINE_COLOR := Color(0.39, 0.96, 1.0, 0.92)
const DEFAULT_GLOW_COLOR := Color(0.70, 0.92, 1.0, 0.36)
const DEFAULT_PULSE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const DEFAULT_NODE_HANDLE_COLOR := Color(0.62, 0.90, 1.0, 0.95)
const DEFAULT_ANCHOR_HANDLE_COLOR := Color(0.55, 0.62, 0.72, 0.85)
const DEFAULT_LINE_WIDTH := 3.0
const DEFAULT_GLOW_WIDTH := 13.0
const DEFAULT_PULSE_RADIUS := 5.5
const DEFAULT_NODE_HANDLE_RADIUS := 9.0
const DEFAULT_ANCHOR_HANDLE_RADIUS := 6.5
const DEFAULT_PULSE_SPEED := 180.0
const DEFAULT_COMPLETION_DURATION := 3.0
const CURVE_BAKE_INTERVAL := 8.0
const PULSE_SEGMENTS := 18
const HANDLE_SEGMENTS := 20
const PHOTON_WAVE_AMPLITUDE := 10.0
const PHOTON_WAVE_LENGTH := 26.0

var graph_model: GraphModel = null
var line_color := DEFAULT_LINE_COLOR
var glow_color := DEFAULT_GLOW_COLOR
var pulse_color := DEFAULT_PULSE_COLOR
var node_handle_color := DEFAULT_NODE_HANDLE_COLOR
var anchor_handle_color := DEFAULT_ANCHOR_HANDLE_COLOR
var line_width := DEFAULT_LINE_WIDTH
var glow_width := DEFAULT_GLOW_WIDTH
var pulse_radius := DEFAULT_PULSE_RADIUS
var node_handle_radius := DEFAULT_NODE_HANDLE_RADIUS
var anchor_handle_radius := DEFAULT_ANCHOR_HANDLE_RADIUS
var pulse_speed_units_per_second := DEFAULT_PULSE_SPEED
var completion_duration_seconds := DEFAULT_COMPLETION_DURATION
var edge_views: Dictionary = {}
var node_views: Dictionary = {}
var render_revision := 0

var _active_pulses: Array[Dictionary] = []


func _process(delta: float) -> void:
	_update_pulses(delta)


func configure(model: GraphModel) -> CurveRenderer:
	set_graph_model(model)
	return self


func set_graph_model(model: GraphModel) -> void:
	if graph_model == model:
		return

	_disconnect_model()
	graph_model = model
	_connect_model()
	rebuild()


func rebuild() -> void:
	_clear_edge_views()
	_clear_node_views()
	if graph_model == null:
		return

	for node in graph_model.nodes.values():
		_update_node_view(node)
	for edge: GraphEdge in graph_model.edges.values():
		_update_edge_view(edge)
	render_revision += 1


# A connected endpoint follows its node/socket: the node position is the truth, the
# stored curve endpoint is only a fallback for a free (unconnected) end.
func build_curve(edge: GraphEdge) -> Curve2D:
	var curve := Curve2D.new()
	curve.bake_interval = CURVE_BAKE_INTERVAL
	if edge == null:
		return curve

	var last_index := edge.curve_points.size() - 1
	for index in range(edge.curve_points.size()):
		var point: CurvePoint = edge.curve_points[index]
		var position := point.position
		if index == 0 and edge.half_edge_a != null and edge.half_edge_a.socket != null:
			position = edge.half_edge_a.socket.world_position()
		elif index == last_index and edge.half_edge_b != null and edge.half_edge_b.socket != null:
			position = edge.half_edge_b.socket.world_position()
		curve.add_point(position, point.in_handle, point.out_handle)
	return curve


func sample_by_arc_length(curve: Curve2D, t: float) -> Vector2:
	if curve == null or curve.point_count == 0:
		return Vector2.ZERO

	var clamped_t: float = clamp(t, 0.0, 1.0)
	if curve.point_count == 1:
		return curve.get_point_position(0)

	var length := curve.get_baked_length()
	if length <= 0.000001:
		return curve.get_point_position(0)
	return curve.sample_baked(length * clamped_t, true)


func play_pulse(edge_or_curve: Variant) -> bool:
	var curve := _resolve_curve(edge_or_curve)
	if curve == null or curve.point_count == 0:
		return false

	var dot := _create_pulse_dot()
	add_child(dot)
	var length: float = max(curve.get_baked_length(), 0.000001)
	_active_pulses.append({
		"curve": curve,
		"dot": dot,
		"elapsed": 0.0,
		"duration": length / pulse_speed_units_per_second,
	})
	dot.position = sample_by_arc_length(curve, 0.0)
	return true


func play_completion() -> bool:
	if graph_model == null or graph_model.edges.is_empty():
		return false

	cancel_pulses()
	for edge: GraphEdge in graph_model.edges.values():
		var curve := get_curve(edge.id)
		if curve == null or curve.point_count == 0:
			continue
		var dot := _create_pulse_dot()
		add_child(dot)
		_active_pulses.append({
			"curve": curve,
			"dot": dot,
			"elapsed": 0.0,
			"duration": clamp(completion_duration_seconds, 2.0, 5.0),
		})
		dot.position = sample_by_arc_length(curve, 0.0)
	return not _active_pulses.is_empty()


func skip_completion() -> void:
	cancel_pulses()


func cancel_pulses() -> void:
	for pulse in _active_pulses:
		var dot: Node = pulse.get("dot", null)
		if dot != null and is_instance_valid(dot):
			dot.queue_free()
	_active_pulses.clear()


func active_pulse_count() -> int:
	return _active_pulses.size()


func get_curve(edge_or_id: Variant) -> Curve2D:
	var edge_id := _edge_id_from_variant(edge_or_id)
	if String(edge_id).is_empty() or not edge_views.has(edge_id):
		return null
	return edge_views[edge_id]["curve"]


func get_line(edge_or_id: Variant) -> Line2D:
	var edge_id := _edge_id_from_variant(edge_or_id)
	if String(edge_id).is_empty() or not edge_views.has(edge_id):
		return null
	return edge_views[edge_id]["line"]


func get_edge_view(edge_or_id: Variant) -> Dictionary:
	var edge_id := _edge_id_from_variant(edge_or_id)
	return edge_views.get(edge_id, {})


func get_node_handle(node_or_id: Variant) -> Polygon2D:
	return node_views.get(_node_id_from_variant(node_or_id), null)


func _connect_model() -> void:
	if graph_model == null:
		return
	if not graph_model.edge_changed.is_connected(_on_edge_changed):
		graph_model.edge_changed.connect(_on_edge_changed)
	if not graph_model.node_changed.is_connected(_on_node_changed):
		graph_model.node_changed.connect(_on_node_changed)
	if not graph_model.topology_changed.is_connected(_on_topology_changed):
		graph_model.topology_changed.connect(_on_topology_changed)


func _disconnect_model() -> void:
	if graph_model == null:
		return
	if graph_model.edge_changed.is_connected(_on_edge_changed):
		graph_model.edge_changed.disconnect(_on_edge_changed)
	if graph_model.node_changed.is_connected(_on_node_changed):
		graph_model.node_changed.disconnect(_on_node_changed)
	if graph_model.topology_changed.is_connected(_on_topology_changed):
		graph_model.topology_changed.disconnect(_on_topology_changed)


func _on_edge_changed(edge: GraphEdge) -> void:
	_update_edge_view(edge)
	render_revision += 1


# Dragging a node moves its handle and drags along every edge endpoint wired to it.
func _on_node_changed(node) -> void:
	_update_node_view(node)
	for socket: Socket in node.sockets:
		if socket.occupied_by != null and socket.occupied_by.edge != null:
			_update_edge_view(socket.occupied_by.edge)
	render_revision += 1


func _on_topology_changed() -> void:
	rebuild()


func _update_edge_view(edge: GraphEdge) -> void:
	if edge == null:
		return

	var curve := build_curve(edge)
	var baked_points := curve.get_baked_points()
	if baked_points.is_empty() and edge.curve_points.size() == 1:
		baked_points = PackedVector2Array([edge.curve_points[0].position])
	var style := _edge_style(edge)
	var draw_points := _wave_points(baked_points, PHOTON_WAVE_AMPLITUDE, PHOTON_WAVE_LENGTH) if style["is_wave"] else baked_points

	var view: Dictionary = edge_views.get(edge.id, {})
	var container: Node2D = view.get("container", null)
	var glow_line: Line2D = view.get("glow_line", null)
	var line: Line2D = view.get("line", null)
	if container == null:
		container = Node2D.new()
		container.name = "Edge_%s" % String(edge.id)
		add_child(container)
		glow_line = _create_line(style["glow_width"], style["glow_color"], style["glow_color"], true)
		line = _create_line(style["line_width"], style["line_color"], style["glow_color"], false)
		container.add_child(glow_line)
		container.add_child(line)

	_apply_line_style(glow_line, style["glow_width"], style["glow_color"], style["glow_color"], true)
	_apply_line_style(line, style["line_width"], style["line_color"], style["glow_color"], false)
	glow_line.points = draw_points
	line.points = draw_points
	edge_views[edge.id] = {
		"edge": edge,
		"curve": curve,
		"container": container,
		"glow_line": glow_line,
		"line": line,
	}


func _clear_edge_views() -> void:
	for view in edge_views.values():
		var container: Node = view.get("container", null)
		if container != null and is_instance_valid(container):
			container.queue_free()
	edge_views.clear()


func _update_node_view(node) -> void:
	if node == null:
		return

	var handle: Polygon2D = node_views.get(node.id, null)
	if handle == null or not is_instance_valid(handle):
		handle = _create_node_handle(node)
		add_child(handle)
		node_views[node.id] = handle
	handle.position = node.position


func _create_node_handle(node) -> Polygon2D:
	var is_anchor: bool = node.kind == NodeKind.ANCHOR
	var radius := anchor_handle_radius if is_anchor else node_handle_radius
	var handle := Polygon2D.new()
	handle.name = "Node_%s" % String(node.id)
	handle.z_index = 10
	var points := PackedVector2Array()
	for index in range(HANDLE_SEGMENTS):
		var angle := TAU * float(index) / float(HANDLE_SEGMENTS)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	handle.polygon = points
	handle.color = anchor_handle_color if is_anchor else node_handle_color
	return handle


func _clear_node_views() -> void:
	for handle in node_views.values():
		if handle != null and is_instance_valid(handle):
			handle.queue_free()
	node_views.clear()


func _create_line(width: float, color: Color, glow: Color, is_glow: bool) -> Line2D:
	var line := Line2D.new()
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.antialiased = true
	_apply_line_style(line, width, color, glow, is_glow)
	return line


func _apply_line_style(line: Line2D, width: float, color: Color, glow: Color, is_glow: bool) -> void:
	line.width = width
	line.default_color = color
	line.material = _create_line_material(color, glow, is_glow)


func _create_line_material(color: Color, glow: Color, is_glow: bool) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = GlowLineShader
	material.set_shader_parameter("line_color", color)
	material.set_shader_parameter("glow_color", glow)
	material.set_shader_parameter("glow_strength", 1.45 if is_glow else 0.25)
	material.set_shader_parameter("core_alpha", 0.38 if is_glow else 0.96)
	return material


func _create_pulse_dot() -> Polygon2D:
	var dot := Polygon2D.new()
	dot.z_index = 20
	var points := PackedVector2Array()
	for index in range(PULSE_SEGMENTS):
		var angle := TAU * float(index) / float(PULSE_SEGMENTS)
		points.append(Vector2(cos(angle), sin(angle)) * pulse_radius)
	dot.polygon = points
	dot.color = pulse_color
	dot.material = _create_pulse_material()
	return dot


func _create_pulse_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = GlowLineShader
	material.set_shader_parameter("line_color", pulse_color)
	material.set_shader_parameter("glow_color", glow_color)
	material.set_shader_parameter("glow_strength", 1.8)
	material.set_shader_parameter("core_alpha", 1.0)
	return material


func _edge_style(edge: GraphEdge) -> Dictionary:
	var particle := String(edge.particle_id)
	match particle:
		"electron":
			return _style(Color(0.92, 0.96, 1.0, 0.96), Color(0.70, 0.86, 1.0, 0.40), false, line_width, glow_width)
		"positron":
			return _style(Color(0.78, 0.70, 1.0, 0.96), Color(0.62, 0.42, 1.0, 0.42), false, line_width, glow_width)
		"muon":
			return _style(Color(0.44, 0.88, 0.90, 0.96), Color(0.35, 0.92, 0.95, 0.38), false, line_width, glow_width)
		"anti_muon":
			return _style(Color(0.92, 0.96, 1.0, 0.96), Color(0.70, 0.86, 1.0, 0.38), false, line_width, glow_width)
		"photon":
			return _style(Color(0.66, 0.96, 1.0, 0.95), Color(0.30, 0.84, 1.0, 0.44), true, 2.4, glow_width + 2.0)
		_:
			return _style(line_color, glow_color, false, line_width, glow_width)


func _style(core: Color, glow: Color, is_wave: bool, core_width: float, halo_width: float) -> Dictionary:
	return {
		"line_color": core,
		"glow_color": glow,
		"is_wave": is_wave,
		"line_width": core_width,
		"glow_width": halo_width,
	}


func _wave_points(points: PackedVector2Array, amplitude: float, wavelength: float) -> PackedVector2Array:
	if points.size() < 2:
		return points

	var result := PackedVector2Array()
	var phase_distance := 0.0
	for index in range(points.size() - 1):
		var start := points[index]
		var finish := points[index + 1]
		var segment := finish - start
		var length := segment.length()
		if length <= 0.001:
			continue
		var normal := Vector2(-segment.y, segment.x) / length
		var steps: int = max(2, ceili(length / 6.0))
		for step in range(steps):
			if index > 0 and step == 0:
				continue
			var t := float(step) / float(steps)
			var distance := phase_distance + length * t
			var offset := sin(distance / wavelength * TAU) * amplitude
			result.append(start.lerp(finish, t) + normal * offset)
		phase_distance += length
	result.append(points[points.size() - 1])
	return result


func _update_pulses(delta: float) -> void:
	for index in range(_active_pulses.size() - 1, -1, -1):
		var pulse := _active_pulses[index]
		var dot: Node2D = pulse["dot"]
		if dot == null or not is_instance_valid(dot):
			_active_pulses.remove_at(index)
			continue

		pulse["elapsed"] = float(pulse["elapsed"]) + delta
		var duration: float = max(float(pulse["duration"]), 0.000001)
		var t: float = float(pulse["elapsed"]) / duration
		if t >= 1.0:
			dot.position = sample_by_arc_length(pulse["curve"], 1.0)
			dot.queue_free()
			_active_pulses.remove_at(index)
			continue

		dot.position = sample_by_arc_length(pulse["curve"], t)
		_active_pulses[index] = pulse


func _resolve_curve(edge_or_curve: Variant) -> Curve2D:
	if edge_or_curve is Curve2D:
		return edge_or_curve
	if edge_or_curve is GraphEdge:
		return get_curve(edge_or_curve.id)
	return get_curve(edge_or_curve)


func _edge_id_from_variant(edge_or_id: Variant) -> StringName:
	if edge_or_id is GraphEdge:
		return edge_or_id.id
	return StringName(str(edge_or_id))


func _node_id_from_variant(node_or_id: Variant) -> StringName:
	if node_or_id is RefCounted and node_or_id.has_method("get_socket"):
		return node_or_id.id
	return StringName(str(node_or_id))
