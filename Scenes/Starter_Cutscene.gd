extends Node2D


@export var Text_Maker: Scrolling_Text
# Called when the node enters the scene tree for the first time.



func _ready() -> void:
	Text_Maker.list_of_text(["The fully automated Titan's Wake carries 32934 human explorers to the edge of the universe", 
							"Generations and generations pass as the human race fights against extinction, for one purpose: ", 
							"The search of the Meaning Of Life"])
	Text_Maker.display_text("2143CE - 359 Light years from Earth - Deep Space")

#The intro is the one cutscene a returning player has already seen, so it alone is
#skippable - same click-or-space gesture as the tutorial pages (Scenes/tutorial_scene.gd).
#It goes through Scrolling_Text.leave() rather than change_scene_to_file() so the typing
#tween's pending timers see _leaving and cannot change scene a second time. Chapters 1-5
#still play through to the end; do not copy this into them.
func _unhandled_input(event: InputEvent) -> void:
	var clicked = event is InputEventMouseButton and event.pressed
	var keyed = event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER]
	if not (clicked or keyed):
		return

	get_viewport().set_input_as_handled()
	Text_Maker.leave()
