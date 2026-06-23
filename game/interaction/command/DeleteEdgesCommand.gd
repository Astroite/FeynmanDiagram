class_name DeleteEdgesCommand
extends Command

# Batch-delete the lines a single cut stroke crossed, as ONE undoable step (so the whole
# slash undoes at once). Reuses DeleteEdgeCommand's snapshot/restore, so each line comes
# back with its id, particle identity, geometry, and half-edge connections intact.

var _model: GraphModel = null
var _edges_data: Array[Dictionary] = []


func configure(model: GraphModel, edges: Array) -> DeleteEdgesCommand:
	label = &"cut_edges"
	_model = model
	for edge in edges:
		if edge != null:
			_edges_data.append(DeleteEdgeCommand.serialize_edge(edge))
	return self


func do() -> bool:
	if _model == null or _edges_data.is_empty():
		return false
	var ok := true
	for data in _edges_data:
		if not _model.remove_edge(StringName(data["id"])):
			ok = false
	return ok


func undo() -> bool:
	if _model == null or _edges_data.is_empty():
		return false
	var ok := true
	for data in _edges_data:
		if not DeleteEdgeCommand.restore_edge(_model, data):
			ok = false
	return ok
