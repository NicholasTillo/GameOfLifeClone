extends Button

@export var button: Button

func _ready(): 
	button.pressed.connect(_button_pressed)
	
func _button_pressed():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
