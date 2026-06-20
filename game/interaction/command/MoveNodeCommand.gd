class_name MoveNodeCommand
extends Command

var _model: GraphModel = null
var _node: RefCounted = null
var _from_position := Vector2.ZERO
var _to_position := Vector2.ZERO

func configure(model: GraphModel, node: RefCounted, to_position: Vector2, from_position: Variant = null):
	label = &"move_node"
	_model = model
	_node = node
	_from_position = from_position if from_position is Vector2 else node.position if node != null else Vector2.ZERO
	_to_position = to_position
	return self


func do() -> bool:
	if _model == null or _node == null:
		return false
	return _model.move_node(_node, _to_position)


func undo() -> bool:
	if _model == null or _node == null:
		return false
	return _model.move_node(_node, _from_position)
