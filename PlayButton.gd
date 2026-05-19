extends Button



@export var button: Button

func _ready(): 
	button.pressed.connect(_button_pressed)
	
func _button_pressed():
	GameManager.reset()
	GameManager.in_gameplay = true
	get_tree().change_scene_to_file("res://GameState.tscn")
	
