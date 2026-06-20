extends GdUnitTestSuite

const InputRouterScript := preload("res://interaction/InputRouter.gd")


func test_mouse_events_emit_pointer_signals_in_world_coordinates() -> void:
	var router := _add_router()
	var viewport := get_viewport()
	var original_transform := viewport.canvas_transform
	viewport.canvas_transform = Transform2D(0.0, Vector2(40.0, -10.0))

	var events: Array = []
	router.pointer_down.connect(func(world_pos: Vector2): events.append(["down", world_pos]))
	router.pointer_moved.connect(func(world_pos: Vector2): events.append(["moved", world_pos]))
	router.pointer_up.connect(func(world_pos: Vector2): events.append(["up", world_pos]))

	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = Vector2(75.0, 15.0)
	router.route_input(down)

	var moved := InputEventMouseMotion.new()
	moved.position = Vector2(80.0, 25.0)
	router.route_input(moved)

	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = Vector2(90.0, 35.0)
	router.route_input(up)

	viewport.canvas_transform = original_transform
	router.free()

	assert_that(events).is_equal([
		["down", Vector2(35.0, 25.0)],
		["moved", Vector2(40.0, 35.0)],
		["up", Vector2(50.0, 45.0)],
	])


func test_touch_events_emit_same_pointer_sequence_as_mouse() -> void:
	var router := _add_router()
	var events: Array = []
	router.pointer_down.connect(func(world_pos: Vector2): events.append(["down", world_pos]))
	router.pointer_moved.connect(func(world_pos: Vector2): events.append(["moved", world_pos]))
	router.pointer_up.connect(func(world_pos: Vector2): events.append(["up", world_pos]))

	var down := InputEventScreenTouch.new()
	down.index = 0
	down.pressed = true
	down.position = Vector2(10.0, 20.0)
	router.route_input(down)

	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(15.0, 25.0)
	router.route_input(drag)

	var up := InputEventScreenTouch.new()
	up.index = 0
	up.pressed = false
	up.position = Vector2(20.0, 30.0)
	router.route_input(up)

	router.free()

	assert_that(events).is_equal([
		["down", Vector2(10.0, 20.0)],
		["moved", Vector2(15.0, 25.0)],
		["up", Vector2(20.0, 30.0)],
	])


func test_shortcut_actions_emit_undo_redo_cancel() -> void:
	var router := _add_router()
	var events: Array[String] = []
	router.undo.connect(func(): events.append("undo"))
	router.redo.connect(func(): events.append("redo"))
	router.cancel.connect(func(): events.append("cancel"))

	router.route_input(_action_event(&"ui_undo"))
	router.route_input(_action_event(&"ui_redo"))
	router.route_input(_action_event(&"ui_cancel"))

	router.free()

	assert_that(events).is_equal(["undo", "redo", "cancel"])


func _add_router() -> Node:
	var router := InputRouterScript.new()
	add_child(router)
	return router


func _action_event(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event
