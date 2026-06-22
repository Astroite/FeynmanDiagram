class_name LevelCatalog
extends RefCounted

# The ordered list of playable levels. Levels are data; this is the single
# authoritative play order (iteration-0 prologue 1-6 + the annihilation gate).
const ORDERED_PATHS: Array[String] = [
	"res://level/levels/001_connect_line.tres",
	"res://level/levels/002_bend_to_connect.tres",
	"res://level/levels/003_two_into_one.tres",
	"res://level/levels/004_undo_redo.tres",
	"res://level/levels/005_snap_to_socket.tres",
	"res://level/levels/006_three_line_convergence.tres",
	"res://level/levels/007_annihilation_gate.tres",
]

var _specs: Array[Resource] = []


func count() -> int:
	return ORDERED_PATHS.size()


# Path for the level at an ordinal position, or "" when out of range.
func path_at(index: int) -> String:
	if index < 0 or index >= ORDERED_PATHS.size():
		return ""
	return ORDERED_PATHS[index]


# Lazily-loaded spec at an ordinal position, or null when out of range.
func spec_at(index: int) -> Resource:
	if index < 0 or index >= ORDERED_PATHS.size():
		return null
	_ensure_loaded()
	return _specs[index]


# Ordinal position of a level by its id, or -1 when unknown.
func index_of(level_id: StringName) -> int:
	_ensure_loaded()
	for index in range(_specs.size()):
		if _specs[index] != null and _specs[index].level_id == level_id:
			return index
	return -1


# Spec following the given level in play order, or null when it is the last one.
func next_of(level_id: StringName) -> Resource:
	var index := index_of(level_id)
	if index < 0:
		return null
	return spec_at(index + 1)


func has_next(level_id: StringName) -> bool:
	return next_of(level_id) != null


func all_specs() -> Array[Resource]:
	_ensure_loaded()
	return _specs.duplicate()


func _ensure_loaded() -> void:
	if not _specs.is_empty():
		return
	for path in ORDERED_PATHS:
		_specs.append(load(path))
