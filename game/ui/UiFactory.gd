class_name UiFactory
extends RefCounted

# Tiny constructors for the code-built screens, so each screen reads as layout
# rather than boilerplate. All produce real, focusable Control nodes.


static func label(text: String, font_size: int = 14, color: Color = UiTheme.TEXT) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func button(text: String, primary: bool = false) -> Button:
	var node := Button.new()
	node.text = text
	if primary:
		node.theme_type_variation = UiTheme.PRIMARY_BUTTON
	return node


static func icon_button(glyph: String) -> Button:
	var node := Button.new()
	node.text = glyph
	node.theme_type_variation = UiTheme.ICON_BUTTON
	node.custom_minimum_size = Vector2(42.0, 42.0)
	return node


static func panel(bg: Color = UiTheme.PANEL, border: Color = UiTheme.BORDER, radius: int = 14) -> Panel:
	var node := Panel.new()
	node.add_theme_stylebox_override("panel", UiTheme.panel_style(bg, border, radius))
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


# Place a control at an absolute position/size in the 1280x720 design space.
static func place(node: Control, pos: Vector2, node_size: Vector2 = Vector2.ZERO) -> Control:
	node.position = pos
	if node_size != Vector2.ZERO:
		node.size = node_size
		node.custom_minimum_size = node_size
	return node
