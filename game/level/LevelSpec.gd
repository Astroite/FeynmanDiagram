class_name LevelSpec
extends Resource

@export var level_id: StringName = &""
@export var title := ""
@export var givens: Dictionary = {}
@export var reference_solution: Dictionary = {}


func create_model_from_givens() -> GraphModel:
	return GraphModel.from_dict(givens)


func create_model_from_reference() -> GraphModel:
	if reference_solution.is_empty():
		return null
	return GraphModel.from_dict(reference_solution)


func to_dict() -> Dictionary:
	return {
		"level_id": String(level_id),
		"title": title,
		"givens": givens,
		"reference_solution": reference_solution,
	}
