extends Node2D


@export var Text_Maker: Scrolling_Text
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Text_Maker.list_of_text(["One, Two Three", "Four Five Six", "Seven Eight Nine"])
	Text_Maker.display_text("First Text")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
 
