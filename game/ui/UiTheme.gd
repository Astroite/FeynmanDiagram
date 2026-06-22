class_name UiTheme
extends RefCounted

# Shared palette + Theme builder for the HUD. Built once in code and assigned on
# the HUD root so every native Control (Button/Panel/Label) inherits the look.
# Replaces the per-draw color constants the old immediate-mode HUD carried.

const TEXT := Color(0.88, 0.92, 1.0, 1.0)
const MUTED := Color(0.56, 0.61, 0.75, 1.0)
const DIM := Color(0.36, 0.41, 0.56, 1.0)
const CYAN := Color(0.42, 0.84, 1.0, 1.0)
const BLUE := Color(0.23, 0.47, 1.0, 1.0)
const PURPLE := Color(0.60, 0.42, 1.0, 1.0)
const GREEN := Color(0.37, 0.88, 0.63, 1.0)
const GOLD := Color(1.0, 0.82, 0.38, 1.0)
const WARNING := Color(1.0, 0.70, 0.40, 1.0)
const PANEL := Color(0.07, 0.09, 0.17, 0.76)
const PANEL_LIGHT := Color(0.12, 0.16, 0.30, 0.68)
const BORDER := Color(0.35, 0.47, 0.78, 0.30)

# Theme type variations applied via Control.theme_type_variation.
const PRIMARY_BUTTON := &"PrimaryButton"
const ICON_BUTTON := &"IconButton"


static func build_theme() -> Theme:
	var theme := Theme.new()

	# Default ("ghost") button: transparent fill, soft border, brightens on hover.
	theme.set_stylebox("normal", "Button", _button_box(Color(0.10, 0.13, 0.23, 0.0), Color(0.55, 0.66, 0.92, 0.28)))
	theme.set_stylebox("hover", "Button", _button_box(Color(0.10, 0.13, 0.23, 0.26), Color(0.55, 0.66, 0.92, 0.50)))
	theme.set_stylebox("pressed", "Button", _button_box(Color(0.10, 0.13, 0.23, 0.34), Color(0.55, 0.66, 0.92, 0.60)))
	theme.set_stylebox("disabled", "Button", _button_box(Color(0.10, 0.13, 0.23, 0.0), Color(0.40, 0.44, 0.58, 0.14)))
	theme.set_stylebox("focus", "Button", _button_box(Color(0.10, 0.13, 0.23, 0.0), Color(0.55, 0.66, 0.92, 0.55)))
	theme.set_color("font_color", "Button", Color(0.72, 0.77, 0.90, 1.0))
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", DIM)
	theme.set_font_size("font_size", "Button", 17)

	# Primary button: filled blue.
	theme.set_stylebox("normal", PRIMARY_BUTTON, _button_box(BLUE, Color(0.55, 0.66, 0.92, 0.50)))
	theme.set_stylebox("hover", PRIMARY_BUTTON, _button_box(BLUE.lightened(0.12), Color(0.70, 0.80, 1.0, 0.65)))
	theme.set_stylebox("pressed", PRIMARY_BUTTON, _button_box(BLUE.darkened(0.08), Color(0.70, 0.80, 1.0, 0.7)))
	theme.set_stylebox("disabled", PRIMARY_BUTTON, _button_box(Color(0.16, 0.18, 0.27, 0.85), Color(0.40, 0.44, 0.58, 0.20)))
	theme.set_stylebox("focus", PRIMARY_BUTTON, _button_box(Color.TRANSPARENT, Color(0.70, 0.80, 1.0, 0.6)))
	theme.set_color("font_color", PRIMARY_BUTTON, Color.WHITE)
	theme.set_color("font_hover_color", PRIMARY_BUTTON, Color.WHITE)
	theme.set_color("font_pressed_color", PRIMARY_BUTTON, Color.WHITE)
	theme.set_color("font_disabled_color", PRIMARY_BUTTON, MUTED)
	theme.set_font_size("font_size", PRIMARY_BUTTON, 17)

	# Icon button: small round-ish, used for gear/pause/hint affordances.
	theme.set_stylebox("normal", ICON_BUTTON, _round_box(Color(0.08, 0.10, 0.18, 0.38), Color(TEXT.r, TEXT.g, TEXT.b, 0.35)))
	theme.set_stylebox("hover", ICON_BUTTON, _round_box(Color(0.10, 0.13, 0.23, 0.55), Color(TEXT.r, TEXT.g, TEXT.b, 0.58)))
	theme.set_stylebox("pressed", ICON_BUTTON, _round_box(Color(0.12, 0.16, 0.30, 0.6), Color(TEXT.r, TEXT.g, TEXT.b, 0.7)))
	theme.set_stylebox("focus", ICON_BUTTON, _round_box(Color.TRANSPARENT, Color(TEXT.r, TEXT.g, TEXT.b, 0.6)))
	theme.set_color("font_color", ICON_BUTTON, TEXT)
	theme.set_font_size("font_size", ICON_BUTTON, 18)

	# Panel.
	theme.set_stylebox("panel", "Panel", _panel_box(PANEL, BORDER))

	# Labels default to the body text color.
	theme.set_color("font_color", "Label", TEXT)
	theme.set_font_size("font_size", "Label", 14)

	# Sliders / progress (used if a minimal settings screen is added later).
	theme.set_color("font_color", "ProgressBar", TEXT)

	return theme


# A filled panel StyleBox tuned for menus/cards.
static func panel_style(bg: Color = PANEL, border: Color = BORDER, radius: int = 14) -> StyleBoxFlat:
	return _panel_box(bg, border, radius)


static func _button_box(bg: Color, border: Color) -> StyleBoxFlat:
	var box := _panel_box(bg, border, 25)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box


static func _round_box(bg: Color, border: Color) -> StyleBoxFlat:
	return _panel_box(bg, border, 21)


static func _panel_box(bg: Color, border: Color, radius: int = 14) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	if border.a > 0.0:
		box.border_color = border
		box.set_border_width_all(1)
	return box
