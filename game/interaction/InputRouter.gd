extends Node

signal pointer_down(world_pos: Vector2)
signal pointer_moved(world_pos: Vector2)
signal pointer_up(world_pos: Vector2)
# Right-button "cut" stroke: drag across lines on empty canvas to slash them.
signal cut_down(world_pos: Vector2)
signal cut_moved(world_pos: Vector2)
signal cut_up(world_pos: Vector2)
signal undo()
signal redo()
signal cancel()
signal delete()

var _mouse_pressed := false
var _right_pressed := false
var _active_touch_index := -1


# Gameplay listens on the unhandled-input pass so GUI Controls (the HUD) consume
# clicks they own first; only events the UI ignored reach curve interaction.
func _unhandled_input(event: InputEvent) -> void:
	route_input(event)


func route_input(event: InputEvent) -> void:
	if _route_shortcut(event):
		return

	if event is InputEventMouseButton:
		_route_mouse_button(event)
	elif event is InputEventMouseMotion:
		_route_mouse_motion(event)
	elif event is InputEventScreenTouch:
		_route_screen_touch(event)
	elif event is InputEventScreenDrag:
		_route_screen_drag(event)


func screen_to_world(screen_pos: Vector2) -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return screen_pos
	return viewport.get_canvas_transform().affine_inverse() * screen_pos


func _route_shortcut(event: InputEvent) -> bool:
	if event is InputEventKey and event.echo:
		return false
	if event is InputEventKey and event.pressed and (event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE):
		delete.emit()
		return true
	if event.is_action_pressed("ui_undo"):
		undo.emit()
		return true
	if event.is_action_pressed("ui_redo"):
		redo.emit()
		return true
	if event.is_action_pressed("ui_cancel"):
		cancel.emit()
		return true
	return false


func _route_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_mouse_pressed = true
			pointer_down.emit(screen_to_world(event.position))
		elif _mouse_pressed:
			_mouse_pressed = false
			pointer_up.emit(screen_to_world(event.position))
		return

	if event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_right_pressed = true
			cut_down.emit(screen_to_world(event.position))
		elif _right_pressed:
			_right_pressed = false
			cut_up.emit(screen_to_world(event.position))


func _route_mouse_motion(event: InputEventMouseMotion) -> void:
	if _mouse_pressed:
		pointer_moved.emit(screen_to_world(event.position))
	elif _right_pressed:
		cut_moved.emit(screen_to_world(event.position))


func _route_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _active_touch_index == -1:
			_active_touch_index = event.index
			pointer_down.emit(screen_to_world(event.position))
	elif event.index == _active_touch_index:
		_active_touch_index = -1
		pointer_up.emit(screen_to_world(event.position))


func _route_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index != _active_touch_index:
		return
	pointer_moved.emit(screen_to_world(event.position))
