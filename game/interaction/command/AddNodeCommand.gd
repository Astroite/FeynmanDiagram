class_name AddNodeCommand
extends Command

# Add an external endpoint (the tray's endpoint-token verb): a single-socket node the
# player drops onto the canvas, which can then be seeded and grown into a line. Undo
# removes it (and, since remove_node clears incident edges, any line drawn from it).
# Endpoints are ANCHOR kind: external legs, not interaction vertices, so QED's
# vertex-template check skips them — matching how levels author their given endpoints.

var _model: GraphModel = null
var _node_id: StringName = &""
var _position := Vector2.ZERO
var _kind := NodeKind.ANCHOR


func configure(model: GraphModel, position: Vector2, kind: int = NodeKind.ANCHOR) -> AddNodeCommand:
	label = &"add_node"
	_model = model
	_position = position
	_kind = kind
	if model != null:
		_node_id = _unique_node_id(model)
	return self


func do() -> bool:
	if _model == null:
		return false
	var offsets: Array[Vector2] = [Vector2.ZERO]
	var node = _model.add_node(_node_id, _kind, _position, offsets)
	return node != null


func undo() -> bool:
	if _model == null:
		return false
	return _model.remove_node(_node_id)


func node_id() -> StringName:
	return _node_id


static func _unique_node_id(model: GraphModel) -> StringName:
	var index := model.nodes.size()
	while true:
		var candidate := StringName("endpoint_%d" % index)
		if not model.nodes.has(candidate):
			return candidate
		index += 1
	return &"endpoint"
