class_name LevelSpec
extends Resource

@export var level_id: StringName = &""
@export var title := ""
# Which validator judges this level: "topology" (iteration-0 connect-and-tidy) or
# "qed" (PhysicsGrammar: vertex template + fermion flow + conservation).
@export var ruleset := "topology"
# Player-facing, localized display strings (game language is Chinese). Internal
# level_id / title stay English. Both fall back gracefully when left empty.
@export var display_code := "" # short chapter/index label, e.g. "序章 · 07"
@export var display_name := "" # human title, e.g. "湮灭之门"
@export var givens: Dictionary = {}
@export var reference_solution: Dictionary = {}


# Player-facing chapter/index label, falling back to the raw level id.
func code_label() -> String:
	if not display_code.is_empty():
		return display_code
	return String(level_id)


# Player-facing title, falling back to the internal English title, then the id.
func name_label() -> String:
	if not display_name.is_empty():
		return display_name
	if not title.is_empty():
		return title
	return String(level_id)


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
		"display_code": display_code,
		"display_name": display_name,
		"givens": givens,
		"reference_solution": reference_solution,
	}
