class_name CreateEdgeCommand
extends Command

# Create a new line between two endpoints by pulling it from a seeded source.
# The line inherits the source particle's identity, and the fermion arrow falls out
# of that identity's sign via the source->target end assignment (see below). Undo
# removes the whole edge; redo re-creates it with the same id, so it round-trips.
#
# End assignment: the source half-edge is always `a`, the target is `b`. Combined
# with PhysicsGrammar's sign rule (arrow runs a->b for matter, b->a for antimatter),
# this realises the approved "source->target x particle sign" direction with no
# special-casing here — a positron drawn source->target gets the correct reversed
# arrow purely from its negative sign.

var _model: GraphModel = null
var _edge_id: StringName = &""
var _particle_id: StringName = &""
var _source_node: RefCounted = null
var _source_socket: Socket = null
var _target_node: RefCounted = null
var _target_socket: Socket = null
var _curve_points: Array[CurvePoint] = []


func configure(model: GraphModel, particle_id: StringName, source_node: RefCounted, source_socket: Socket, target_node: RefCounted, target_socket: Socket, curve_points: Array[CurvePoint] = []) -> CreateEdgeCommand:
	label = &"create_edge"
	_model = model
	_particle_id = particle_id
	_source_node = source_node
	_source_socket = source_socket
	_target_node = target_node
	_target_socket = target_socket
	_curve_points = _duplicate_points(curve_points)
	if _curve_points.is_empty() and source_socket != null and target_socket != null:
		_curve_points = [CurvePoint.create(source_socket.world_position()), CurvePoint.create(target_socket.world_position())]
	if model != null:
		_edge_id = _unique_edge_id(model)
	return self


func do() -> bool:
	if _model == null or _source_node == null or _source_socket == null or _target_node == null or _target_socket == null:
		return false
	if _source_node == _target_node:
		return false

	var edge := _model.add_edge(_edge_id, _curve_points)
	if edge == null:
		return false

	var sign := _fermion_sign(_particle_id)
	edge.particle_id = _particle_id
	edge.half_edge_a.particle_id = _particle_id
	edge.half_edge_a.fermion_flow = sign
	edge.half_edge_b.particle_id = _particle_id
	edge.half_edge_b.fermion_flow = sign

	var connected_source := _model.connect_half_edge(edge.half_edge_a, _source_node, _source_socket)
	var connected_target := _model.connect_half_edge(edge.half_edge_b, _target_node, _target_socket)
	if not (connected_source and connected_target):
		_model.remove_edge(_edge_id)
		return false
	return true


func undo() -> bool:
	if _model == null:
		return false
	return _model.remove_edge(_edge_id)


func edge_id() -> StringName:
	return _edge_id


static func _fermion_sign(particle_id: StringName) -> int:
	var spec := ParticleSpec.get_spec(particle_id)
	return spec.fermion_sign if spec != null else 0


static func _unique_edge_id(model: GraphModel) -> StringName:
	var index := model.edges.size()
	while true:
		var candidate := StringName("drawn_edge_%d" % index)
		if not model.edges.has(candidate):
			return candidate
		index += 1
	return &"drawn_edge"


static func _duplicate_points(points: Array) -> Array[CurvePoint]:
	var copied: Array[CurvePoint] = []
	for point in points:
		if point is CurvePoint:
			copied.append(point.duplicate_point())
		elif point is Dictionary:
			copied.append(CurvePoint.from_dict(point))
	return copied
