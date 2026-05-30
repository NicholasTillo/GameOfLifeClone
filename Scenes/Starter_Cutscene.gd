extends Node2D


@export var Text_Maker: Scrolling_Text
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Text_Maker.list_of_text(["The fully automated Titan's Wake carries 32934 human exploreres to the edge of the universe", 
							"Generations and generations pass as the human race fights against extinsion, for one purpose: ", 
							"The search of the Meaning Of Life"])
	Text_Maker.display_text("2143CE - 359 Light years from Earth - Deep Space")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
 
