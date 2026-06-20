class_name UndoStack
extends RefCounted

signal changed()

var _undo_stack: Array[Command] = []
var _redo_stack: Array[Command] = []


func push(command: Command) -> bool:
	if command == null:
		return false
	if not command.do():
		return false

	_undo_stack.append(command)
	_redo_stack.clear()
	changed.emit()
	return true


func undo() -> bool:
	if _undo_stack.is_empty():
		return false

	var command: Command = _undo_stack.pop_back()
	if not command.undo():
		_undo_stack.append(command)
		return false

	_redo_stack.append(command)
	changed.emit()
	return true


func redo() -> bool:
	if _redo_stack.is_empty():
		return false

	var command: Command = _redo_stack.pop_back()
	if not command.do():
		_redo_stack.append(command)
		return false

	_undo_stack.append(command)
	changed.emit()
	return true


func clear() -> void:
	_undo_stack.clear()
	_redo_stack.clear()
	changed.emit()


func can_undo() -> bool:
	return not _undo_stack.is_empty()


func can_redo() -> bool:
	return not _redo_stack.is_empty()


func undo_count() -> int:
	return _undo_stack.size()


func redo_count() -> int:
	return _redo_stack.size()
