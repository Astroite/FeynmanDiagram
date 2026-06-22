class_name MenuScreen
extends Control

# Main menu, intentionally bare: a TitleArt slot (reserved for the Standard-Model
# curve artwork) plus a single enter button. The layout lives in MenuScreen.tscn
# (open it in the Godot editor to move things around); this script only forwards
# the button press. Pressing enter opens level select, which the coordinator
# reveals with a fade / camera-push transition rather than a hard cut.

signal enter_pressed

@onready var _play_button: Button = $PlayButton


func _ready() -> void:
	_play_button.pressed.connect(func(): enter_pressed.emit())
