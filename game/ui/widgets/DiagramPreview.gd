class_name DiagramPreview
extends Control

# Renders a real level graph (its given lines + vertices) as a small thumbnail,
# normalized to fit this control. Honest: it shows the actual level data, not a
# hardcoded mockup diagram.

const PADDING := 14.0

var _model: GraphModel = null


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_model(model: GraphModel) -> void:
	_model = model
	queue_redraw()


func show_spec(spec: Resource) -> void:
	if spec != null and spec.has_method("create_model_from_givens"):
		show_model(spec.create_model_from_givens())
	else:
		show_model(null)


func _draw() -> void:
	if _model == null:
		return

	var points := _collect_points()
	if points.is_empty():
		return

	var bounds := _bounds(points)
	var scale := _fit_scale(bounds.size)
	var offset := (size - bounds.size * scale) * 0.5 - bounds.position * scale

	# Edges as polylines through their curve points.
	for edge: GraphEdge in _model.edges.values():
		if edge.curve_points.size() < 2:
			continue
		var line := PackedVector2Array()
		for cp in edge.curve_points:
			line.append(cp.position * scale + offset)
		draw_polyline(line, Color(0.62, 0.78, 1.0, 0.85), 1.5, true)

	# Nodes: anchors as filled dots, vertices as small rings.
	for node in _model.nodes.values():
		var p: Vector2 = node.position * scale + offset
		if node.kind == NodeKind.VERTEX:
			draw_arc(p, 4.0, 0.0, TAU, 16, Color.WHITE, 1.4)
		else:
			draw_circle(p, 3.0, Color(0.80, 0.94, 1.0, 1.0))


func _collect_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	for node in _model.nodes.values():
		points.append(node.position)
	for edge: GraphEdge in _model.edges.values():
		for cp in edge.curve_points:
			points.append(cp.position)
	return points


func _bounds(points: PackedVector2Array) -> Rect2:
	var rect := Rect2(points[0], Vector2.ZERO)
	for p in points:
		rect = rect.expand(p)
	return rect


func _fit_scale(content: Vector2) -> float:
	var avail := size - Vector2(PADDING, PADDING) * 2.0
	var sx := avail.x / content.x if content.x > 0.001 else 1.0
	var sy := avail.y / content.y if content.y > 0.001 else 1.0
	return minf(minf(sx, sy), 1.0)
